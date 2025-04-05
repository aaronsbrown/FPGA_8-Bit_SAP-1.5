#!/bin/bash
set -e
set -o pipefail

# simulate.sh - Run simulation for project-specific sources.
#
# Usage:
#   ./simulate.sh [--verbose|-v] [--tb testbench_file.v] [--no-viz] [path/to/verilog_file.v ...]

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
    echo "Usage: $0 [--verbose|-v] [--tb testbench_file.v] [--no-viz] [path/to/verilog_file.v ...]"
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
USE_SV2V=false
VERILOG_FILES=()

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

# --- Determine Project Directory ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
[ "$VERBOSE" = true ] && log_debug "Project directory determined as: $PROJECT_DIR"

# --- Load Verilog Files from _files.f if none provided ---
if [[ ${#VERILOG_FILES[@]} -eq 0 ]]; then
    FILE_LIST="$PROJECT_DIR/src/_files_sim.f"
    if [[ -f "$FILE_LIST" ]]; then
        log_info "Loading Verilog sources from: $FILE_LIST"
        while IFS= read -r line || [ -n "$line" ]; do
            # Trim leading/trailing whitespace.
            line="$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
            [[ "$line" =~ ^#.*$ || -z "$line" ]] && continue
            VERILOG_FILES+=("$PROJECT_DIR/$line")
        done < "$FILE_LIST"
    else
        log_error "No Verilog files provided and $FILE_LIST not found."
        usage
    fi
fi

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
    VERILOG_FILES+=("$TESTBENCH_FILE")
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
            VERILOG_FILES+=("$TESTBENCH_FILE")
        fi
    else
        log_error "Test directory $TEST_DIR not found."
        exit 1
    fi
fi

# --- Resolve Absolute Paths for all Verilog Files ---
ABS_VERILOG_FILES=()
for file in "${VERILOG_FILES[@]}"; do
    abs_file=$(cd "$(dirname "$file")" && echo "$(pwd)/$(basename "$file")")
    ABS_VERILOG_FILES+=("$abs_file")
    [ "$VERBOSE" = true ] && log_debug "Resolved: $file -> $abs_file"
done

# --- Setup Build and Log Directories ---
BUILD_DIR="$PROJECT_DIR/build"
LOG_DIR="$BUILD_DIR/logs"
mkdir -p "$LOG_DIR"

# --- Optional sv2v Conversion ---
FINAL_VERILOG_FILES=()
if [ "$USE_SV2V" = true ]; then
    log_info "sv2v conversion enabled. Converting all SystemVerilog files in one invocation..."
    # Collect all .sv files into an array.
    SV_FILES=()
    for file in "${ABS_VERILOG_FILES[@]}"; do
        if [[ "$file" == *.sv ]]; then
            SV_FILES+=("$file")
        else
            FINAL_VERILOG_FILES+=("$file")
        fi
    done

    # Echo all files that will be converted by sv2v.
    for file in "${SV_FILES[@]}"; do
        log_info "sv2v will convert: $file"
    done

    # Convert all SystemVerilog files together to support packages.
    combined_sv2v_file="$BUILD_DIR/combined.v"
    log_info "Converting ${#SV_FILES[@]} SystemVerilog files to $combined_sv2v_file"
    sv2v "${SV_FILES[@]}" > "$combined_sv2v_file"
    FINAL_VERILOG_FILES+=("$combined_sv2v_file")
else
    FINAL_VERILOG_FILES=("${ABS_VERILOG_FILES[@]}")
fi

# --- Compile Simulation Sources with Icarus Verilog ---
SIM_VVP="$BUILD_DIR/sim.vvp"
log_info "Compiling simulation sources..."
# Add the test directory to the include path (-I option) so that test_utilities.sv can be found.
IVERILOG_CMD=(iverilog -DSIMULATION -g2012 -I "$PROJECT_DIR/test" -o "$SIM_VVP" "${FINAL_VERILOG_FILES[@]}")

cp "$PROJECT_DIR/fixture/program.hex" "$BUILD_DIR/program.hex"

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
SESSION_FILE="sim/8-bit-baseline.gtkw"
if [ -f "$WAVEFORM" ]; then
    if [ "$NO_VIZ" = false ]; then
        log_info "Opening waveform in gtkwave..."
        gtkwave "$WAVEFORM" "$SESSION_FILE" &
    else
        log_info "Waveform generated, skipping visualization (--no-viz)."
    fi
else
    log_error "Waveform file $WAVEFORM not found. Ensure your testbench generates a VCD file."
fi

log_success "Simulation complete!"