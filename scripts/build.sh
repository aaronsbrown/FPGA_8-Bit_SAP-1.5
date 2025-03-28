#!/bin/bash
set -e  # Exit on any error
set -o pipefail

# --- Configuration & Logging ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'  # No Color

log_info()    { echo -e "${CYAN}[$(date +"%T")] INFO:${NC} $1"; }
log_debug()   { [ "$VERBOSE" = true ] && echo -e "${YELLOW}[$(date +"%T")] DEBUG:${NC} $1"; }
log_success() { echo -e "${GREEN}[$(date +"%T")] SUCCESS:${NC} $1"; }
log_error()   { echo -e "${RED}[$(date +"%T")] ERROR:${NC} $1" >&2; }

usage() {
    echo "Usage: $0 [--verbose|-v] [--with-common] path/to/verilog_file.v ... --top top_module_name [--tb testbench_file.v]"
    exit 1
}

# --- Helper function to run commands with optional verbose logging ---
run_cmd() {
    local log_file="$1"
    shift
    if [ "$VERBOSE" = true ]; then
        "$@" 2>&1 | tee "$log_file"
    else
        "$@" > "$log_file" 2>&1
    fi
}

# --- Parse Arguments ---
VERBOSE=false
WITH_COMMON=false
TB_FILE=""   # Testbench file (optional, for simulation only)
VERILOG_FILES=()
TOP_MODULE=""

if [[ $# -eq 0 ]]; then
    usage
fi

while [[ $# -gt 0 ]]; do
    case "$1" in
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        --with-common)
            WITH_COMMON=true
            shift
            ;;
        --top)
            if [[ -z "$2" ]]; then
                log_error "--top flag requires a module name."
                usage
            fi
            TOP_MODULE="$2"
            shift 2
            ;;
        --tb)
            if [[ -z "$2" ]]; then
                log_error "--tb flag requires a testbench file."
                usage
            fi
            TB_FILE="$2"
            shift 2
            ;;
        -*)
            log_error "Unknown option: $1"
            usage
            ;;
        *)
            VERILOG_FILES+=("$1")
            shift
            ;;
    esac
done

if [[ ${#VERILOG_FILES[@]} -eq 0 ]]; then
    log_error "No Verilog files provided."
    usage
fi

if [[ -z "$TOP_MODULE" ]]; then
    log_error "Top module not specified. Use --top <module_name>"
    usage
fi

# --- Helper Function: Resolve Absolute Paths ---
get_abs() {
    (cd "$(dirname "$1")" && echo "$(pwd)/$(basename "$1")")
}

# --- Convert Provided Verilog Files to Absolute Paths ---
ABS_VERILOG_FILES=()
for file in "${VERILOG_FILES[@]}"; do
    abs_file=$(get_abs "$file")
    ABS_VERILOG_FILES+=("$abs_file")
    [ "$VERBOSE" = true ] && log_debug "Resolved: $file -> $abs_file"
done

# --- Determine Project Directory ---
# We assume the provided Verilog file is in the project's "src" directory.
# Therefore, the project directory is one level up from the src folder.
SRC_DIR=$(dirname "${ABS_VERILOG_FILES[0]}")
PROJECT_DIR=$(dirname "$SRC_DIR")
[ "$VERBOSE" = true ] && log_debug "Project directory determined as: $PROJECT_DIR"

# --- Setup Build and Log Directories ---
BUILD_DIR="$PROJECT_DIR/build"
LOG_DIR="$BUILD_DIR/logs"
mkdir -p "$LOG_DIR"

# --- Optionally Include Common Modules ---
if [ "$WITH_COMMON" = true ]; then
    COMMON_MODULES_DIR="$(cd "$PROJECT_DIR/../../../common/modules" && pwd)"
    if [ -d "$COMMON_MODULES_DIR" ]; then
        log_info "Searching for common modules in $COMMON_MODULES_DIR..."
        COMMON_MODULE_FILES=($(find "$COMMON_MODULES_DIR" -maxdepth 1 \( -type f -o -type l \) -name "*.v" 2>/dev/null))
        if [ ${#COMMON_MODULE_FILES[@]} -gt 0 ]; then
            for file in "${COMMON_MODULE_FILES[@]}"; do
                abs_file="$(get_abs "$file")"
                ABS_VERILOG_FILES+=("$abs_file")
                [ "$VERBOSE" = true ] && log_debug "Added common module: $abs_file"
            done
        else
            log_info "No common module files found in $COMMON_MODULES_DIR."
        fi
    else
        log_error "Common modules directory $COMMON_MODULES_DIR does not exist."
    fi
else
    log_info "Skipping inclusion of common modules (use --with-common to include them)."
fi

# --- Merge Constraint Files ---
# Project-specific constraints are in PROJECT_DIR/constraints.
# Common constraints are located at ../../common/constraints relative to the project directory.
PROJECT_CONSTRAINT_DIR="$PROJECT_DIR/constraints"
COMMON_CONSTRAINT_DIR="$(cd "$PROJECT_DIR/../../../common/constraints" && pwd)"
MERGED_PCF="$BUILD_DIR/merged_constraints.pcf"

COMMON_PCF_FILES=( $(find "$COMMON_CONSTRAINT_DIR" -maxdepth 1 -type f -name "*.pcf" 2>/dev/null) )
PROJECT_PCF_FILES=( $(find "$PROJECT_CONSTRAINT_DIR" -maxdepth 1 -type f -name "*.pcf" 2>/dev/null) )

if [[ ${#COMMON_PCF_FILES[@]} -eq 0 && ${#PROJECT_PCF_FILES[@]} -eq 0 ]]; then
    log_error "No constraint files found in either common or project directories."
    exit 1
fi

log_info "Merging constraint files..."
> "$MERGED_PCF"  # Create or empty the merged file
# Append common constraints first.
for file in "${COMMON_PCF_FILES[@]}"; do
    cat "$file" >> "$MERGED_PCF"
    echo "" >> "$MERGED_PCF"
done
# Append project-specific constraints.
for file in "${PROJECT_PCF_FILES[@]}"; do
    cat "$file" >> "$MERGED_PCF"
    echo "" >> "$MERGED_PCF"
done
log_info "Merged constraints saved to: $MERGED_PCF"

# --- FPGA Build Flow ---
# Define Output Files
YOSYS_JSON="$BUILD_DIR/hardware.json"
NEXTPNR_ASC="$BUILD_DIR/hardware.asc"
ICEPACK_BIN="$BUILD_DIR/hardware.bin"

# --- Step 1: Synthesis with Yosys ---
log_info "Running Yosys synthesis..."
YOSYS_CMD=(yosys -q -p "synth_ice40 -top $TOP_MODULE -json $YOSYS_JSON" "${ABS_VERILOG_FILES[@]}")
[ "$VERBOSE" = true ] && log_debug "Yosys command: ${YOSYS_CMD[*]}"
if run_cmd "$LOG_DIR/yosys.log" "${YOSYS_CMD[@]}"; then
    log_success "Yosys synthesis completed."
else
    log_error "Yosys synthesis failed. Check $LOG_DIR/yosys.log for details."
    exit 1
fi

# --- Step 2: Place & Route with nextpnr-ice40 ---
log_info "Running nextpnr-ice40..."
NEXTPNR_CMD=(nextpnr-ice40 --hx8k --package cb132 --json "$YOSYS_JSON" --asc "$NEXTPNR_ASC" --pcf "$MERGED_PCF")
[ "$VERBOSE" = true ] && log_debug "nextpnr-ice40 command: ${NEXTPNR_CMD[*]}"
if run_cmd "$LOG_DIR/nextpnr.log" "${NEXTPNR_CMD[@]}"; then
    log_success "nextpnr-ice40 completed."
else
    log_error "nextpnr-ice40 failed. Check $LOG_DIR/nextpnr.log for details."
    exit 1
fi

# --- Step 3: Bitstream Packing ---
log_info "Packing bitstream with icepack..."
if run_cmd "$LOG_DIR/icepack.log" icepack "$NEXTPNR_ASC" "$ICEPACK_BIN"; then
    log_success "Bitstream packed successfully."
else
    log_error "icepack failed. Check $LOG_DIR/icepack.log for details."
    exit 1
fi

# --- Step 4: Upload to FPGA ---
log_info "Uploading bitstream to FPGA with iceprog..."
if run_cmd "$LOG_DIR/iceprog.log" iceprog "$ICEPACK_BIN"; then
    log_success "Bitstream uploaded successfully."
else
    log_error "iceprog failed. Check $LOG_DIR/iceprog.log for details."
    exit 1
fi

log_success "Build & upload complete!"