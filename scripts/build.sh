#!/bin/bash
set -e
set -o pipefail

# --- Configuration & Logging ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info()    { echo -e "${CYAN}[$(date +"%T")] INFO:${NC} $1"; }
log_debug()   { [ "$VERBOSE" = true ] && echo -e "${YELLOW}[$(date +"%T")] DEBUG:${NC} $1"; }
log_success() { echo -e "${GREEN}[$(date +"%T")] SUCCESS:${NC} $1"; }
log_error()   { echo -e "${RED}[$(date +"%T")] ERROR:${NC} $1" >&2; }

usage() {
    echo "Usage: $0 [--verbose|-v] path/to/verilog_file.v ... --top top_module_name"
    exit 1
}

# --- Command Runner ---
run_cmd() {
    local log_file="$1"
    shift
    if [ "$VERBOSE" = true ]; then
        "$@" 2>&1 | tee "$log_file"
    else
        "$@" > "$log_file" 2>&1
    fi
}

# --- Argument Parsing ---
VERBOSE=false
VERILOG_FILES=()
USE_SV2V=false
TOP_MODULE=""

if [[ $# -eq 0 ]]; then usage; fi

while [[ $# -gt 0 ]]; do
    case "$1" in
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        --sv2v)
            USE_SV2V=true
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

# --- Determine Project Directory ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
[ "$VERBOSE" = true ] && log_debug "Project directory: $PROJECT_DIR"

# --- Load Verilog Files ---
if [[ ${#VERILOG_FILES[@]} -eq 0 ]]; then
    FILE_LIST="$PROJECT_DIR/src/_files.f"
    if [[ -f "$FILE_LIST" ]]; then
        log_info "Loading Verilog sources from: $FILE_LIST"
        # Read each line, trim whitespace, and add if not empty/comment.
        while IFS= read -r line || [ -n "$line" ]; do
            # Remove leading and trailing whitespace
            line="$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
            [[ "$line" =~ ^#.*$ || -z "$line" ]] && continue
            VERILOG_FILES+=("$PROJECT_DIR/$line")
        done < "$FILE_LIST"
    else
        log_error "No Verilog files provided and $FILE_LIST not found."
        usage
    fi
fi

if [[ -z "$TOP_MODULE" ]]; then
    log_error "Top module not specified. Use --top <module_name>"
    usage
fi

# --- Resolve Absolute Paths ---
get_abs() {
    (cd "$(dirname "$1")" && echo "$(pwd)/$(basename "$1")")
}

ABS_VERILOG_FILES=()
for file in "${VERILOG_FILES[@]}"; do
    abs_file=$(get_abs "$file")
    ABS_VERILOG_FILES+=("$abs_file")
    [ "$VERBOSE" = true ] && log_debug "Resolved: $file -> $abs_file"
done

BUILD_DIR="$PROJECT_DIR/build"
LOG_DIR="$BUILD_DIR/logs"
mkdir -p "$LOG_DIR"

# --- Optional sv2v Conversion ---
FINAL_VERILOG_FILES=()
if [ "$USE_SV2V" = true ]; then
    log_info "sv2v conversion enabled. Converting SystemVerilog files..."
    for file in "${ABS_VERILOG_FILES[@]}"; do
        if [[ "$file" == *.sv ]]; then
            base=$(basename "$file" .sv)
            converted_file="$BUILD_DIR/${base}.v"
            log_info "Converting $file to $converted_file"
            sv2v "$file" > "$converted_file"
            FINAL_VERILOG_FILES+=("$converted_file")
        else
            FINAL_VERILOG_FILES+=("$file")
        fi
    done
else
    FINAL_VERILOG_FILES=("${ABS_VERILOG_FILES[@]}")
fi

# --- Constraints ---
PROJECT_CONSTRAINT_DIR="$PROJECT_DIR/constraints"
MERGED_PCF="$BUILD_DIR/merged_constraints.pcf"
PROJECT_PCF_FILES=( $(find "$PROJECT_CONSTRAINT_DIR" -maxdepth 1 -type f -name "*.pcf" 2>/dev/null) )

if [[ ${#PROJECT_PCF_FILES[@]} -eq 0 ]]; then
    log_error "No constraint files found in $PROJECT_CONSTRAINT_DIR"
    exit 1
fi

log_info "Merging constraint files..."
> "$MERGED_PCF"
for file in "${PROJECT_PCF_FILES[@]}"; do
    cat "$file" >> "$MERGED_PCF"
    echo "" >> "$MERGED_PCF"
done
log_info "Merged constraints saved to: $MERGED_PCF"

# --- Optional SDC Conversion ---
MERGED_SDC="$BUILD_DIR/merged_constraints.sdc"
PROJECT_SDC_FILES=( $(find "$PROJECT_CONSTRAINT_DIR" -maxdepth 1 -type f -name "*.sdc" 2>/dev/null) )
if [[ ${#PROJECT_SDC_FILES[@]} -gt 0 ]]; then
    log_info "Merging SDC constraint files..."
    > "$MERGED_SDC"
    for file in "${PROJECT_SDC_FILES[@]}"; do
        cat "$file" >> "$MERGED_SDC"
        echo "" >> "$MERGED_SDC"
    done
    log_info "Merged SDC constraints saved to: $MERGED_SDC"
else
    log_info "No SDC constraint files found in $PROJECT_CONSTRAINT_DIR"
fi

# --- Output Files ---
YOSYS_JSON="$BUILD_DIR/hardware.json"
NEXTPNR_ASC="$BUILD_DIR/hardware.asc"
ICEPACK_BIN="$BUILD_DIR/hardware.bin"

# --- Yosys ---
log_info "Running Yosys synthesis..."

YOSYS_CMD=(yosys -q -p "synth_ice40 -top $TOP_MODULE -json $YOSYS_JSON" "${FINAL_VERILOG_FILES[@]}")

[ "$VERBOSE" = true ] && log_debug "Yosys command: ${YOSYS_CMD[*]}"
run_cmd "$LOG_DIR/yosys.log" "${YOSYS_CMD[@]}"
log_success "Yosys synthesis completed."

# --- nextpnr ---
log_info "Running nextpnr-ice40..."
if [[ -f "$MERGED_SDC" ]]; then
    NEXTPNR_CMD=(nextpnr-ice40 --hx8k --package cb132 --json "$YOSYS_JSON" --asc "$NEXTPNR_ASC" --pcf "$MERGED_PCF" --sdc "$MERGED_SDC")
else
    NEXTPNR_CMD=(nextpnr-ice40 --hx8k --package cb132 --json "$YOSYS_JSON" --asc "$NEXTPNR_ASC" --pcf "$MERGED_PCF")
fi
[ "$VERBOSE" = true ] && log_debug "nextpnr-ice40 command: ${NEXTPNR_CMD[*]}"
run_cmd "$LOG_DIR/nextpnr.log" "${NEXTPNR_CMD[@]}"
log_success "nextpnr-ice40 completed."

# --- icepack ---
log_info "Packing bitstream with icepack..."
run_cmd "$LOG_DIR/icepack.log" icepack "$NEXTPNR_ASC" "$ICEPACK_BIN"
log_success "Bitstream packed successfully."

# --- Upload ---
log_info "Uploading bitstream to FPGA with iceprog..."
run_cmd "$LOG_DIR/iceprog.log" iceprog "$ICEPACK_BIN"
log_success "Bitstream uploaded successfully."

log_success "Build & upload complete!"