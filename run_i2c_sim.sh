#!/usr/bin/env bash
# Build and run I2C Simulator
# Simple wrapper around the C++ simulator

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SIMULATOR_SRC="$SCRIPT_DIR/i2c_simulator.cpp"
SIMULATOR_BIN="$SCRIPT_DIR/i2c_simulator"

# Check if source exists
if [[ ! -f "$SIMULATOR_SRC" ]]; then
    echo "Error: i2c_simulator.cpp not found in $SCRIPT_DIR"
    exit 1
fi

# Compile if needed
if [[ ! -f "$SIMULATOR_BIN" ]] || [[ "$SIMULATOR_SRC" -nt "$SIMULATOR_BIN" ]]; then
    echo "Compiling I2C Simulator..."
    clang++ -std=c++11 -Wall -O2 -o "$SIMULATOR_BIN" "$SIMULATOR_SRC" 2>&1 | grep -v "warning:" || true
    echo "✓ Compilation complete"
fi

# Run simulator
echo ""
echo "Running I2C Master Simulator..."
echo ""
"$SIMULATOR_BIN"
