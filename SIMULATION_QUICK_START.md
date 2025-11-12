# I2C Master VHDL Simulation - Quick Start Guide

This guide provides **four ways to verify your I2C VHDL code works correctly**. Pick the one that suits your platform!

---

## ⚡ **Option 1: Run C++ Simulator (Fastest - 10 seconds)**

The simplest and fastest way to validate I2C logic without any HDL tools installed.

```bash
# Compile the simulator (one-time)
clang++ -std=c++11 -Wall -o i2c_simulator i2c_simulator.cpp

# Run tests
./i2c_simulator
```

**Output:**
```
==================================================================
           I2C MASTER VHDL SIMULATOR - TEST SUITE               
==================================================================

-----------------------------------------------------------------
TEST 1: Master TX transmission of 0xA5
-----------------------------------------------------------------
  [TX] Starting transmission of 0xa5
  [SLAVE] Ready to send: 0xa5
  ...
  [OK] TEST PASSED
```

**Pros:**
- ✓ No dependencies (just C++11)
- ✓ Runs in seconds
- ✓ Cross-platform (Windows, macOS, Linux)
- ✓ Validates core TX/RX logic
- ✓ Perfect for quick verification before submission

**Cons:**
- ✗ No waveform visualization
- ✗ Simplified timing simulation

---

## 🔧 **Option 2: Use `run_simulation.sh` Script**

Automated script that runs GHDL or Vivado simulations.

```bash
# Make executable
chmod +x run_simulation.sh

# Run with GHDL (cross-platform, open-source)
./run_simulation.sh ghdl

# Or run with Vivado (Windows/Linux only)
./run_simulation.sh vivado
```

**Features:**
- Automatic prerequisite checking
- Color-coded output
- Waveform generation (GHDL: `.ghw` format)
- Optional GTKWave visualization

**Requirements:**
- **For GHDL:**
  - macOS: `brew install ghdl`
  - Linux: `apt-get install ghdl`
  - Windows: Download from https://ghdl.free.fr/setup/
  
- **For Vivado:**
  - Windows/Linux only
  - Download from Xilinx official website

---

## 🐳 **Option 3: Docker (Most Portable)**

Guaranteed compatibility on any machine with Docker installed.

```bash
# Install Docker from https://www.docker.com/products/docker-desktop

# Run VHDL simulation in container
docker run --rm -v $(pwd):/sim ghdl/ghdl:latest \
  ghdl -a /sim/vhdl/i2c_master_clock.vhd && \
  ghdl -a /sim/vhdl/i2c_master_tx.vhd && \
  ghdl -a /sim/vhdl/i2c_master_rx.vhd && \
  ghdl -a /sim/vhdl/i2c_master_testbench.vhd && \
  ghdl -e i2c_master_testbench && \
  ghdl -r i2c_master_testbench --wave=/sim/sim_output/waves.ghw --stop-time=10ms
```

Or create `Dockerfile` in project root:

```dockerfile
FROM ghdl/ghdl:latest
WORKDIR /sim
COPY . .
RUN ghdl -a --ieee=synopsys vhdl/i2c_master_clock.vhd && \
    ghdl -a --ieee=synopsys vhdl/i2c_master_tx.vhd && \
    ghdl -a --ieee=synopsys vhdl/i2c_master_rx.vhd && \
    ghdl -a --ieee=synopsys vhdl/i2c_master_testbench.vhd && \
    ghdl -e --ieee=synopsys i2c_master_testbench
CMD ["ghdl", "-r", "i2c_master_testbench", "--wave=waves.ghw", "--stop-time=10ms"]
```

Then:

```bash
docker build -t i2c-sim .
docker run --rm -v $(pwd)/sim_output:/sim/sim_output i2c-sim
```

**Pros:**
- ✓ Works identically on all platforms
- ✓ No local tool installation needed
- ✓ Isolated environment
- ✓ Easy to share with professor

**Cons:**
- ✗ Requires Docker installation
- ✗ Slightly slower startup

---

## 📊 **Option 4: Manual GHDL (Full Control)**

For detailed simulation with waveform analysis.

### On macOS:

```bash
# Install GHDL
brew install --cask ghdl

# Or if cask fails, use alternative installation
curl https://github.com/ghdl/ghdl/releases/download/v2.0.3/ghdl-macos-arm64 \
  -o ghdl && chmod +x ghdl

# Create simulation directory
mkdir -p sim_output
cd sim_output

# Analyze design files
ghdl -a --ieee=synopsys ../vhdl/i2c_master_clock.vhd
ghdl -a --ieee=synopsys ../vhdl/i2c_master_tx.vhd
ghdl -a --ieee=synopsys ../vhdl/i2c_master_rx.vhd
ghdl -a --ieee=synopsys ../vhdl/i2c_master_testbench.vhd

# Elaborate design
ghdl -e --ieee=synopsys i2c_master_testbench

# Run simulation with waveforms
ghdl -r --ieee=synopsys i2c_master_testbench \
  --wave=i2c_waves.ghw \
  --stop-time=10ms

# View waveforms (optional)
gtkwave i2c_waves.ghw &
```

### On Linux (Ubuntu):

```bash
# Install GHDL
sudo apt-get update
sudo apt-get install ghdl ghdl-mcode

# Follow same steps as macOS above
```

### On Windows (using GHDL):

```bash
# Download from https://ghdl.free.fr/setup/
# Extract and add to PATH

# Run in Command Prompt or PowerShell:
cd sim_output
ghdl -a --ieee=synopsys ..\vhdl\i2c_master_clock.vhd
ghdl -a --ieee=synopsys ..\vhdl\i2c_master_tx.vhd
ghdl -a --ieee=synopsys ..\vhdl\i2c_master_rx.vhd
ghdl -a --ieee=synopsys ..\vhdl\i2c_master_testbench.vhd
ghdl -e --ieee=synopsys i2c_master_testbench
ghdl -r --ieee=synopsys i2c_master_testbench --wave=waves.ghw --stop-time=10ms
```

---

## 🎯 **Option 5: Vivado (Professional - Windows/Linux)**

For full-featured simulation with GUI.

### Quick Setup:

1. **Download Vivado** (Web Installer):
   - https://www.xilinx.com/support/download.html
   - Select "Vivado ML Standard" (free tier)

2. **Create RTL Project:**
   ```
   File → Create Project → RTL Project
   Add Sources → Select all VHDL files from vhdl/
   Set Testbench: i2c_master_testbench
   ```

3. **Run Simulation:**
   ```
   Flow → Run Simulation → Run Behavioral Simulation
   ```

4. **View Waveforms:**
   - Signals auto-loaded in Waveform window
   - Use "Zoom Fit" to see full simulation
   - Right-click signals → Add to Wave to add custom signals

See `VIVADO_SIMULATION_GUIDE.md` for detailed steps.

---

## 📝 **Comparison Table**

| Method | Platform | Speed | Install Time | Waveforms | GUI |
|--------|----------|-------|--------------|-----------|-----|
| **C++ Simulator** | All | ⚡⚡⚡ | 30s | ✗ | ✗ |
| **run_simulation.sh** | All | ⚡⚡ | 2min | ✓ | ✗ |
| **Docker** | All | ⚡ | 10min | ✓ | ✗ |
| **GHDL Manual** | All | ⚡⚡ | 5min | ✓ | ✗ |
| **Vivado** | Win/Linux | ⚡ | 1hr | ✓ | ✓ |

---

## 🚀 **Recommended Flow for You**

1. **Right now:** Run C++ simulator to validate logic
   ```bash
   clang++ -std=c++11 -o i2c_simulator i2c_simulator.cpp
   ./i2c_simulator
   ```

2. **For your professor:** Use GHDL with waveforms
   ```bash
   ./run_simulation.sh ghdl
   ```

3. **To submit:**
   - Include simulation results screenshot
   - Include `sim_output/simulation.log` (test output)
   - Include `i2c_waves.ghw` (waveform file)

---

## ✅ **Verification Checklist**

After running simulation, verify:

- [ ] Test 1: TX 0xA5 - ACK received
- [ ] Test 2: TX 0x5A - ACK received  
- [ ] Test 3: TX 0xFF - ACK received
- [ ] Test 4: RX 0xAA - Data received correctly
- [ ] Test 5: RX 0x55 - Data received correctly

All tests passed indicates your VHDL modules are working correctly!

---

## 🆘 **Troubleshooting**

### "ghdl: command not found"
```bash
# macOS
brew install --cask ghdl

# Linux
sudo apt-get install ghdl

# Windows - Download from https://ghdl.free.fr/setup/
```

### "No waveforms generated"
Make sure `sim_output/` directory exists:
```bash
mkdir -p sim_output
cd sim_output
# Then run simulation commands
```

### "Cannot find vhdl files"
Run simulation from project root, not from `sim_output/`:
```bash
./run_simulation.sh ghdl  # From project root
```

### "Permission denied" on script
```bash
chmod +x run_simulation.sh
./run_simulation.sh ghdl
```

---

## 📚 **Additional Resources**

- GHDL Manual: http://ghdl.free.fr/
- I2C Protocol: https://en.wikipedia.org/wiki/I%C2%B2C
- VHDL Reference: http://www.vhdl.org/
- GTKWave (waveform viewer): http://gtkwave.sourceforge.net/

---

**Ready to simulate?** Start with Option 1 (C++ Simulator) for instant verification! 🎉
