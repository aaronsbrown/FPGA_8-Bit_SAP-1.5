#!/bin/bash
set -e
set -o pipefail

# simulate.sh - Run simulation for project-specific sources.
#
# Usage:
#   ./simulate.sh [--verbose|-v] [--tb testbench_file.v] [--no-viz] path/to/verilog_file.v ...

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
    echo "Usage: $0 [--verbose|-v] [--tb testbench_file.v] [--no-viz] path/to/verilog_file.v ..."
    exit 1
}

# --- Helper function to run commands ---
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
NO_VIZ=false
TB_FILE=""
VERILOG_FILES=()

if [[ $# -eq 0 ]]; then
    usage
fi

while [[ $# -gt 0 ]]; do
    case "$1" in
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        --no-viz)
            NO_VIZ=true
            shift
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

# --- Helper: Resolve Absolute Path ---
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
SRC_DIR=$(dirname "${ABS_VERILOG_FILES[0]}")
PROJECT_DIR=$(dirname "$SRC_DIR")
[ "$VERBOSE" = true ] && log_debug "Project directory determined as: $PROJECT_DIR"

# --- Setup Build and Log Directories ---
BUILD_DIR="$PROJECT_DIR/build"
LOG_DIR="$BUILD_DIR/logs"
mkdir -p "$LOG_DIR"

# --- Determine Testbench File ---
if [ -n "$TB_FILE" ]; then
    if [[ "$TB_FILE" != *"/"* ]]; then
        TB_FILE="$PROJECT_DIR/test/$TB_FILE"
    fi
    TESTBENCH_FILE="$(cd "$(dirname "$TB_FILE")" && pwd)/$(basename "$TB_FILE")"
    if [ ! -f "$TESTBENCH_FILE" ]; then
        log_error "Specified testbench file $TESTBENCH_FILE does not exist."
        exit 1
    fi
    log_info "Using specified testbench file: $TESTBENCH_FILE"
    ABS_VERILOG_FILES+=("$TESTBENCH_FILE")
else
    TEST_DIR="$PROJECT_DIR/test"
    if [ -d "$TEST_DIR" ]; then
        log_info "Searching for testbench files in $TEST_DIR..."
        TEST_FILES=( $(find "$TEST_DIR" -maxdepth 1 -type f \( -name "*_tb.v" -o -name "*_tb.sv" \) 2>/dev/null) )
        if [ ${#TEST_FILES[@]} -eq 0 ]; then
            log_error "No testbench files found in $TEST_DIR. Please add a testbench file ending with _tb.v."
            exit 1
        elif [ ${#TEST_FILES[@]} -gt 1 ]; then
            log_error "Multiple testbench files found in $TEST_DIR. Use the --tb flag to specify one."
            exit 1
        else
            TESTBENCH_FILE="$(cd "$(dirname "${TEST_FILES[0]}")" && pwd)/$(basename "${TEST_FILES[0]}")"
            log_info "Using testbench file: $TESTBENCH_FILE"
            ABS_VERILOG_FILES+=("$TESTBENCH_FILE")
        fi
    else
        log_error "Test directory $TEST_DIR not found."
        exit 1
    fi
fi

# --- Compile Simulation Sources with Icarus Verilog ---
SIM_VVP="$BUILD_DIR/sim.vvp"
log_info "Compiling simulation sources..."
IVERILOG_CMD=(iverilog -g2012 -o "$SIM_VVP" "${ABS_VERILOG_FILES[@]}")
[ "$VERBOSE" = true ] && log_debug "Iverilog command: ${IVERILOG_CMD[*]}"
if run_cmd "$LOG_DIR/iverilog.log" "${IVERILOG_CMD[@]}"; then
    log_success "Iverilog compilation completed."
else
    log_error "Iverilog compilation failed. Check $LOG_DIR/iverilog.log."
    exit 1
fi

# --- Run Simulation with vvp ---
pushd "$BUILD_DIR" > /dev/null
log_info "Running simulation with vvp..."
if run_cmd "$LOG_DIR/vvp.log" vvp "sim.vvp"; then
    log_success "vvp simulation completed."
else
    log_error "vvp simulation failed. Check $LOG_DIR/vvp.log."
    popd > /dev/null
    exit 1
fi
popd > /dev/null

# --- Optionally Open Waveform in gtkwave ---
WAVEFORM="$BUILD_DIR/waveform.vcd"
if [ -f "$WAVEFORM" ]; then
    if [ "$NO_VIZ" = false ]; then
        log_info "Opening waveform in gtkwave..."
        gtkwave "$WAVEFORM" &
    else
        log_info "Waveform generated, skipping visualization (--no-viz)."
    fi
else
    log_error "Waveform file $WAVEFORM not found. Ensure your testbench generates a VCD file."
fi

log_success "Simulation complete!"