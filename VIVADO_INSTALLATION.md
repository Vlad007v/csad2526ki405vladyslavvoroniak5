# Vivado Installation & Simulation Setup Guide

## Important: Vivado on macOS

**Note:** Xilinx Vivado official support for macOS ended with Vivado 2017. The latest versions (2022-2024) officially support only:
- Linux (CentOS, Ubuntu)
- Windows

**For macOS users, options:**

### Option 1: Use Docker (Recommended for macOS)
Run Vivado in a containerized Linux environment.

### Option 2: Use Linux VM
- VMware Fusion
- VirtualBox
- Parallels Desktop

### Option 3: Use Free GHDL Instead
GHDL is cross-platform and works natively on macOS.

---

## Installation Methods

### Method A: Vivado on Windows or Linux

#### Prerequisites
- **Disk space:** 50-100 GB (full install)
- **RAM:** Minimum 8 GB (16 GB recommended)
- **Network:** 50+ Gbps for download
- **Xilinx account:** Free registration required

#### Windows Installation

1. **Download Vivado:**
   - Visit: https://www.xilinx.com/support/download.html
   - Select Vivado 2024.1 (or latest)
   - Choose "Vivado Design Suite"
   - Download the Windows installer

2. **Install:**
   ```bash
   # Run the installer
   Vivado_2024.1_1028_0213_Win64.exe
   ```
   - Choose "Install"
   - Accept license terms
   - Select design tools: Vivado + SDK
   - Installation takes 30-60 minutes

3. **Configure license:**
   - Xilinx provides 30-day eval license automatically
   - Or use free WebPACK license (limited device support)

4. **Launch Vivado:**
   ```cmd
   # From Start Menu or Command Prompt
   vivado
   ```

#### Linux Installation (Ubuntu 20.04/22.04)

```bash
# 1. Download Vivado Linux installer
# Visit https://www.xilinx.com/support/download.html
# Select Vivado 2024.1 for Linux

# 2. Extract and run installer
tar -xzf Vivado_2024.1_1028_0213_Lin64.tar.gz
cd Vivado_2024.1_1028_0213_Lin64
./xsetup

# 3. Follow GUI installer
# Choose installation directory (default: /opt/Xilinx/Vivado/2024.1)

# 4. Add to PATH
# Add to ~/.bashrc:
export PATH="/opt/Xilinx/Vivado/2024.1/bin:$PATH"

# 5. Verify installation
vivado -version
```

---

### Method B: Docker (Recommended for macOS)

#### Quick Start with Docker

1. **Install Docker Desktop:**
   - https://www.docker.com/products/docker-desktop

2. **Create Vivado Docker image:**

```dockerfile
# Create file: Dockerfile
FROM ubuntu:20.04

# Set timezone (required for Vivado)
ENV TZ=UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Install dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    curl \
    wget \
    libtinfo5 \
    libxrender1 \
    libxrandr2 \
    libxtst6 \
    && rm -rf /var/lib/apt/lists/*

# Download and install Vivado (requires registration)
# Alternative: Use pre-built image from Xilinx or community
# For now, use GHDL instead (simpler)

RUN apt-get update && apt-get install -y \
    ghdl \
    gtkwave \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /work
CMD ["/bin/bash"]
```

Build and run:

```bash
# Build image
docker build -t vivado-sim .

# Run container with volume mount
docker run -it --rm -v "$PWD":/work vivado-sim

# Inside container, run simulation
cd /work
ghdl -a vhdl/i2c_master_clock.vhd
ghdl -a vhdl/i2c_master_tx.vhd
ghdl -a vhdl/i2c_master_rx.vhd
ghdl -a vhdl/i2c_master_testbench.vhd
ghdl -e i2c_master_testbench
ghdl -r i2c_master_testbench --wave=i2c_sim.ghw --stop-time=10ms
```

---

### Method C: Use GHDL Directly (Easiest on macOS)

GHDL is a free, open-source VHDL simulator that works natively on macOS.

#### Install GHDL on macOS

```bash
# Using Homebrew
brew install ghdl

# Verify installation
ghdl --version
```

#### Run I2C Simulation with GHDL

```bash
# Navigate to project root
cd /path/to/csad2526ki405vladyslavvoroniak5/

# Create simulation directory
mkdir -p sim_output
cd sim_output

# Analyze VHDL files
ghdl -a --ieee=synopsys ../vhdl/i2c_master_clock.vhd
ghdl -a --ieee=synopsys ../vhdl/i2c_master_tx.vhd
ghdl -a --ieee=synopsys ../vhdl/i2c_master_rx.vhd
ghdl -a --ieee=synopsys ../vhdl/i2c_master_testbench.vhd

# Elaborate
ghdl -e --ieee=synopsys i2c_master_testbench

# Run simulation and generate waveform
ghdl -r --ieee=synopsys i2c_master_testbench \
  --wave=i2c_master_waves.ghw \
  --stop-time=10ms

# View waveforms with GTKWave
gtkwave i2c_master_waves.ghw
```

---

## Running Simulation in Vivado GUI

### Step-by-Step (After Vivado Installation)

1. **Launch Vivado:**
   ```bash
   vivado
   ```

2. **Create New Project:**
   - File → New Project
   - Name: `i2c_master_sim`
   - Location: `/path/to/project`
   - Project type: "RTL Project"
   - Device: Select any Xilinx device (or just leave default)

3. **Add Design Files:**
   - Project Manager → Add Sources → Add Files
   - Browse to `vhdl/` directory
   - Select (in order):
     - `i2c_master_clock.vhd`
     - `i2c_master_tx.vhd`
     - `i2c_master_rx.vhd`
     - `i2c_master_testbench.vhd`
   - Click Add → Finish

4. **Set Testbench as Top:**
   - In Sources panel, right-click `i2c_master_testbench.vhd`
   - Select "Set as Top"

5. **Run Simulation:**
   - Flow → Run Simulation → Run Behavioral Simulation
   - Or: Click the green play button in toolbar
   - Wait for compilation (~1-5 minutes first time)

6. **View Waveforms:**
   - After simulation starts, Waveform window opens
   - In Objects panel (left), select signals to monitor
   - Right-click → Add to Waveform
   - Watch signals update in real-time

7. **Control Simulation:**
   - Use Tcl console at bottom:
     ```tcl
     run 1ms
     run all
     restart
     ```

---

## Recommended Setup for Each Platform

### macOS
```
Option 1 (Easiest): GHDL
├─ Install: brew install ghdl gtkwave
├─ Run: ./scripts/simulate_vhdl.sh
└─ View: gtkwave sim_output/i2c_master_waves.ghw

Option 2 (More features): Docker + Linux
├─ Install: Docker Desktop
├─ Run: docker run ... (see Docker section)
└─ View: gtkwave inside container

Option 3 (Most features): Parallels/VMware + Vivado
├─ Install: Parallels Desktop or VMware
├─ Install Linux VM
├─ Install Vivado on Linux
└─ Run: See Windows/Linux instructions
```

### Windows
```
Option 1 (Recommended): Vivado GUI
├─ Download: https://www.xilinx.com/support/download.html
├─ Install: Run .exe installer
├─ Launch: vivado
└─ Create project: See "Step-by-Step" section

Option 2 (Alternative): GHDL
├─ Download: https://github.com/ghdl/ghdl/releases
├─ Install: Run installer
└─ Run: ghdl commands (see GHDL section)
```

### Linux
```
Option 1 (Recommended): Vivado GUI
├─ Download: https://www.xilinx.com/support/download.html
├─ Install: ./xsetup
└─ Launch: vivado

Option 2 (Alternative): GHDL
├─ Install: sudo apt-get install ghdl gtkwave
└─ Run: ghdl commands (see GHDL section)
```

---

## Quick Comparison: Vivado vs GHDL

| Feature | Vivado | GHDL |
|---------|--------|------|
| **Cost** | Free (eval) | Free & Open Source |
| **macOS Support** | No (official) | Yes |
| **Installation** | Large (50-100 GB) | Small (100 MB) |
| **GUI** | Yes (xsim) | No (CLI only) |
| **Waveform Viewer** | Built-in | GTKWave (separate) |
| **Synthesis** | Yes | No |
| **Simulation Speed** | Fast | Slower |
| **Learning Curve** | Steep | Gentle |

---

## Troubleshooting

### "Vivado not found" on macOS
- Vivado is not officially supported on recent macOS
- Use GHDL or Docker instead

### "License error" on Windows/Linux
- Ensure internet connection for license verification
- Use WebPACK license (free, limited)
- Or use eval license (30 days)

### "Port '...' already connected" error
- Check module port declarations match in testbench
- Verify all VHDL files are in correct order

### Simulation runs very slowly
- Reduce simulation time: `--stop-time=5ms` instead of `10ms`
- Check for infinite loops in slave simulator
- Use GHDL instead of Vivado for faster compilation

### Waveform shows 'X' everywhere
- Testbench entity not set as "Top"
- Reset not released before tests start
- Check `rst_n` is '1' at 0.2 μs

---

## Next Steps

1. **Choose installation method** (GHDL recommended for macOS)
2. **Install simulator**
3. **Run simulation**:
   ```bash
   # If using GHDL:
   cd sim_output
   ghdl -r i2c_master_testbench --wave=i2c_sim.ghw --stop-time=10ms
   
   # If using Vivado:
   vivado → Create Project → Add Files → Run Simulation
   ```
4. **Check waveforms** for correctness
5. **Submit to professor** with simulation report

---

## Further Help

- **Vivado Documentation:** https://docs.xilinx.com/
- **GHDL Documentation:** https://ghdl.readthedocs.io/
- **GTKWave Documentation:** http://gtkwave.sourceforge.net/

