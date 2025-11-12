I2C master VHDL — Simulation instructions

Overview

This repository now contains the VHDL sources you provided (exact contents preserved under `vhdl/`). The files restored from your attachments are:

- vhdl/i2c_master_tx.vhd  — transmitter unit (as provided)
- vhdl/i2c_master_rx.vhd  — receiver unit (as provided)
- vhdl/i2c_master_clock.vhd — clock generator (as provided)
- vhdl/i2c_master_tb.vhd  — testbench (as provided)

Goal

Make it straightforward for another developer (Windows, Linux, or macOS) to run the supplied testbench and verify the TX and RX behavior.

Notes / Important

- I preserved the files exactly as you sent them. If your testbench references a top-level entity named `i2c_master` (or other monolithic file), make sure that file is present in the simulation sources — your attached `tb_i2c_master.vhd` instantiates `entity work.i2c_master` in one variant; double-check which TB you will run.
- The testbench and driver-models assume open-drain SDA/SCL behavior implemented in the TB (wired-AND). The simulation works when all required components are included.

Recommended ways to simulate

Option A — GHDL (command-line, cross-platform)

1. Install GHDL:
   - On Windows: use MSYS2 / Scoop / GHDL Windows binaries.
   - On Linux/macOS: use your package manager (on mac: `brew install ghdl` — on Apple Silicon you may need Rosetta and an x86_64 GHDL or use Docker).

2. From repository root, analyze the files (example):

```bash
mkdir -p sim_work
cd sim_work
# Analyze sources (adjust paths if you keep vhdl/ in root)
ghdl -a --ieee=synopsys ../vhdl/i2c_master_clock.vhd
ghdl -a --ieee=synopsys ../vhdl/i2c_master_tx.vhd
ghdl -a --ieee=synopsys ../vhdl/i2c_master_rx.vhd
ghdl -a --ieee=synopsys ../vhdl/i2c_master_tb.vhd

# Elaborate and run (produces waveform i2c_master_waves.ghw)
ghdl -e --ieee=synopsys i2c_master_tb
ghdl -r --ieee=synopsys i2c_master_tb --wave=i2c_master_waves.ghw --stop-time=100us
```

3. Open the waveform in GTKWave:

```bash
gtkwave i2c_master_waves.ghw
```

Option B — ModelSim / Questa (Windows)

1. Start ModelSim and create a new project, add the VHDL files in this order to avoid unresolved references:
   - `i2c_master_clock.vhd`
   - `i2c_master_tx.vhd`
   - `i2c_master_rx.vhd`
   - `i2c_master_tb.vhd`

2. Compile all files (vcom). Example (ModelSim CLI):

```tcl
vlib work
vcom ../vhdl/i2c_master_clock.vhd
vcom ../vhdl/i2c_master_tx.vhd
vcom ../vhdl/i2c_master_rx.vhd
vcom ../vhdl/i2c_master_tb.vhd
vsim work.i2c_master_tb
run 100us
view wave
```

3. Inspect signals `sda`, `scl`, `tx_*`, `rx_*`, and the testbench reports in transcript.

Option C — Docker (recommended for macOS Apple Silicon to avoid Rosetta/GHDL issues)

Use a Linux container with GHDL installed. Example Dockerfile (quick start):

```Dockerfile
FROM ubuntu:22.04
RUN apt-get update && apt-get install -y ghdl gtkwave
WORKDIR /work
COPY . /work
CMD ["/bin/bash"]
```

Build and run:

```bash
docker build -t vhdl-sim .
docker run --rm -it -v "$PWD":/work vhdl-sim
# then in container
ghdl -a --ieee=synopsys vhdl/i2c_master_clock.vhd vhdl/i2c_master_tx.vhd vhdl/i2c_master_rx.vhd vhdl/i2c_master_tb.vhd
ghdl -e --ieee=synopsys i2c_master_tb
ghdl -r --ieee=synopsys i2c_master_tb --wave=i2c_master_waves.ghw --stop-time=100us
```

Troubleshooting

- If GHDL analysis is killed (exit code 137) on macOS Apple Silicon, try running GHDL under Rosetta (x86_64) or use Docker. Homebrew GHDL bottles are often x86_64 and require Rosetta.
- If the testbench instantiates an entity that is not present, add the missing VHDL file(s) to the simulation command.
- If the testbench expects different port names, ensure you use the TB that matches the DUT files (I preserved your attached files exactly).

What I changed in the repo

- Restored the VHDL files under `vhdl/` to match the exact contents you provided via attachments.
- Added this README_SIMULATION.md to explain how a colleague can run the tests on Windows or using Docker.

If you'd like

- I can prepare a small Visual Studio Code / .vscode launch tasks snippet for GHDL or ModelSim to make it one-click to run.
- I can prepare a Docker Compose setup to make running the simulation easier on macOS.

Tell me how I should proceed.