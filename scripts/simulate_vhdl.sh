#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
SIM_DIR="$ROOT_DIR/sim"
VHDL_DIR="$ROOT_DIR/vhdl"

# Create simulation directory if it doesn't exist
mkdir -p "$SIM_DIR"

# Check if running on Apple Silicon
if [[ $(uname -m) == "arm64" ]]; then
    echo "Running on Apple Silicon..."
    # Set environment variables for GHDL on Apple Silicon
    export DYLD_LIBRARY_PATH="/opt/homebrew/lib/ghdl"
    GHDL_CMD="arch -x86_64 /opt/homebrew/bin/ghdl"
else
    GHDL_CMD="ghdl"
fi

# Check for GHDL installation
if ! command -v ghdl &> /dev/null; then
    echo "GHDL is not installed. Please install GHDL to run VHDL simulations."
    echo "On macOS, you can install it using: brew install ghdl"
    exit 1
fi

echo "Starting VHDL simulation..."
cd "$SIM_DIR"  # Change to simulation directory to avoid path issues

# Clean previous simulation files
rm -f *.o *.cf *.ghw work-obj93.cf

# Analyze VHDL files with increased stack size
echo "Analyzing VHDL files..."
ulimit -s 16384  # Increase stack size for GHDL

$GHDL_CMD -a --ieee=synopsys --workdir=. "$VHDL_DIR/i2c_master_clock.vhd" || echo "Warning: Clock module analysis failed"
$GHDL_CMD -a --ieee=synopsys --workdir=. "$VHDL_DIR/i2c_master_tx.vhd" || echo "Warning: TX module analysis failed"
$GHDL_CMD -a --ieee=synopsys --workdir=. "$VHDL_DIR/i2c_master_rx.vhd" || echo "Warning: RX module analysis failed"
$GHDL_CMD -a --ieee=synopsys --workdir=. "$VHDL_DIR/i2c_master_tb.vhd" || echo "Warning: Testbench analysis failed"

# Elaborate testbench
echo "Elaborating testbench..."
$GHDL_CMD -e --ieee=synopsys --workdir=. i2c_master_tb || {
    echo "Error: Elaboration failed"
    exit 1
}

# Run simulation with waveform output
echo "Running simulation..."
$GHDL_CMD -r --ieee=synopsys --workdir=. i2c_master_tb --wave="i2c_master_waves.ghw" --stop-time=100us || {
    echo "Error: Simulation failed"
    exit 1
}

echo "Simulation completed. Waveform file generated at: $SIM_DIR/i2c_master_waves.ghw"
echo "You can view the waveforms using GTKWave: gtkwave $SIM_DIR/i2c_master_waves.ghw"