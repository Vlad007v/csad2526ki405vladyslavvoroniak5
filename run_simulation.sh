#!/usr/bin/env bash
# I2C Master VHDL Simulation Script
# Supports: GHDL (macOS, Linux, Windows) and Vivado (Linux, Windows)
# Usage: ./run_simulation.sh [ghdl|vivado]

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"
VHDL_DIR="$PROJECT_ROOT/vhdl"
SIM_DIR="$PROJECT_ROOT/sim_output"
SIM_TIME="10ms"

# Default simulator
SIMULATOR="${1:-ghdl}"

# ============================================================================
# Helper Functions
# ============================================================================

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# ============================================================================
# Check Prerequisites
# ============================================================================

check_simulator() {
    case "$SIMULATOR" in
        ghdl)
            if ! command -v ghdl &> /dev/null; then
                print_error "GHDL not found"
                echo "Install with: brew install ghdl (macOS) or apt-get install ghdl (Linux)"
                exit 1
            fi
            print_success "GHDL found: $(ghdl --version)"
            ;;
        vivado)
            if ! command -v vivado &> /dev/null; then
                print_error "Vivado not found"
                echo "Install from: https://www.xilinx.com/support/download.html"
                exit 1
            fi
            print_success "Vivado found"
            ;;
        *)
            print_error "Unknown simulator: $SIMULATOR"
            echo "Usage: $0 [ghdl|vivado]"
            exit 1
            ;;
    esac
}

check_vhdl_files() {
    print_info "Checking VHDL files..."
    
    required_files=(
        "$VHDL_DIR/i2c_master_clock.vhd"
        "$VHDL_DIR/i2c_master_tx.vhd"
        "$VHDL_DIR/i2c_master_rx.vhd"
        "$VHDL_DIR/i2c_master_testbench.vhd"
    )
    
    for file in "${required_files[@]}"; do
        if [[ ! -f "$file" ]]; then
            print_error "Missing: $file"
            exit 1
        fi
        print_success "Found: $(basename "$file")"
    done
}

# ============================================================================
# GHDL Simulation
# ============================================================================

run_ghdl_simulation() {
    print_header "I2C Master VHDL Simulation (GHDL)"
    
    # Create simulation directory
    mkdir -p "$SIM_DIR"
    cd "$SIM_DIR"
    
    print_info "Analyzing VHDL files..."
    ghdl -a --ieee=synopsys "$VHDL_DIR/i2c_master_clock.vhd"
    print_success "Analyzed i2c_master_clock.vhd"
    
    ghdl -a --ieee=synopsys "$VHDL_DIR/i2c_master_tx.vhd"
    print_success "Analyzed i2c_master_tx.vhd"
    
    ghdl -a --ieee=synopsys "$VHDL_DIR/i2c_master_rx.vhd"
    print_success "Analyzed i2c_master_rx.vhd"
    
    ghdl -a --ieee=synopsys "$VHDL_DIR/i2c_master_testbench.vhd"
    print_success "Analyzed i2c_master_testbench.vhd"
    
    print_info "Elaborating design..."
    ghdl -e --ieee=synopsys i2c_master_testbench
    print_success "Elaboration complete"
    
    print_info "Running simulation for $SIM_TIME..."
    ghdl -r --ieee=synopsys i2c_master_testbench \
        --wave=i2c_master_waves.ghw \
        --stop-time="$SIM_TIME" \
        2>&1 | tee simulation.log
    
    print_success "Simulation complete!"
    print_info "Waveform file: $SIM_DIR/i2c_master_waves.ghw"
    print_info "Simulation log: $SIM_DIR/simulation.log"
    
    # Check for test results
    if grep -q "TEST.*PASSED" simulation.log; then
        print_success "Test output detected in log"
        echo ""
        echo "Test Results:"
        grep "TEST" simulation.log || true
    fi
    
    # Suggest viewing waveforms
    if command -v gtkwave &> /dev/null; then
        print_info ""
        read -p "View waveforms in GTKWave? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            gtkwave i2c_master_waves.ghw &
        fi
    else
        print_warning "GTKWave not installed. Install with: brew install gtkwave"
        print_info "To view waveforms later, run: gtkwave $SIM_DIR/i2c_master_waves.ghw"
    fi
}

# ============================================================================
# Vivado Simulation
# ============================================================================

run_vivado_simulation() {
    print_header "I2C Master VHDL Simulation (Vivado)"
    
    print_warning "Vivado GUI is required for this option"
    print_info "Launching Vivado..."
    
    # Create Vivado TCL script
    TCL_SCRIPT="$PROJECT_ROOT/vivado_sim.tcl"
    cat > "$TCL_SCRIPT" << 'VIVADO_TCL'
# Create project
create_project i2c_master_sim -force

# Add design files
add_files {
    vhdl/i2c_master_clock.vhd
    vhdl/i2c_master_tx.vhd
    vhdl/i2c_master_rx.vhd
    vhdl/i2c_master_testbench.vhd
}

# Set testbench as top
set_property top i2c_master_testbench [get_filesets sim_1]

# Run simulation
launch_simulation

puts "Simulation launched. Check waveforms in the Waveform window."
VIVADO_TCL
    
    print_info "Running: vivado -mode batch -source $TCL_SCRIPT"
    vivado -mode batch -source "$TCL_SCRIPT" || true
    
    print_info "For full GUI simulation:"
    print_info "  1. Run: vivado"
    print_info "  2. Create new RTL project"
    print_info "  3. Add files from vhdl/ directory"
    print_info "  4. Set i2c_master_testbench as top"
    print_info "  5. Flow → Run Simulation → Run Behavioral Simulation"
}

# ============================================================================
# Main Script
# ============================================================================

main() {
    print_header "I2C Master VHDL Simulation Setup"
    
    print_info "Platform: $(uname -s)"
    print_info "Simulator: $SIMULATOR"
    print_info "Project root: $PROJECT_ROOT"
    print_info ""
    
    # Check prerequisites
    check_simulator
    check_vhdl_files
    
    echo ""
    
    # Run appropriate simulator
    case "$SIMULATOR" in
        ghdl)
            run_ghdl_simulation
            ;;
        vivado)
            run_vivado_simulation
            ;;
    esac
    
    echo ""
    print_header "Simulation Complete"
    print_success "All tests finished"
}

# Run main script
main
