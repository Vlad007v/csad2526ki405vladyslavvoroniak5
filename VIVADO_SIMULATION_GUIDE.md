# I2C Master — Vivado Simulation Guide

## Overview

This guide explains how to set up and run I2C master module simulations in Vivado.

## Files Required

Place these files in your Vivado project:

```
vhdl/
├── i2c_master_clock.vhd       (Clock generator)
├── i2c_master_tx.vhd          (Transmitter module)
├── i2c_master_rx.vhd          (Receiver module)
└── i2c_master_testbench.vhd   (Comprehensive testbench)
```

## Vivado Setup Steps

### 1. Create a New Project

```bash
# Option A: Using Vivado GUI
1. File → Create Project
2. Choose project name and location
3. Select "RTL Project"
4. Set device to your FPGA/simulator target
```

### 2. Add Design Sources

In Vivado:

```
1. Project Manager → Add Sources (or +Add Files)
2. Select all VHDL files from vhdl/ directory:
   - i2c_master_clock.vhd
   - i2c_master_tx.vhd
   - i2c_master_rx.vhd
   - i2c_master_testbench.vhd
3. Click Next, then Finish
```

**Order matters:** Add clock first, then TX/RX, then testbench.

### 3. Set Testbench as Simulation Top

```
1. Right-click on i2c_master_testbench.vhd in Sources panel
2. Select "Set as Top" (for simulation)
3. Or: Flow → Run Simulation
```

### 4. Run Simulation

```
1. In Vivado menu: Flow → Run Simulation → Run Behavioral Simulation
   (or click the green play button)
2. Simulation will launch with Vivado Simulator (xsim)
3. Wait for testbench to complete (~10 ms simulation time)
```

## Vivado Simulator (xsim) Controls

### After simulation starts:

```
• Waveforms window: Shows all signals
• Objects window: Lists signals/modules in hierarchy
• Tcl Console: Execute custom commands
```

### View Waveforms:

```
1. In Objects panel, select signals to monitor:
   - clk, rst_n
   - scl, scl_rise, scl_fall (I2C clock)
   - sda_i2c_bus (I2C data line)
   - tx_busy, tx_done, tx_ack_received
   - rx_busy, rx_data_valid, rx_data_out
   - slave_sda_drive (for slave simulation)
2. Right-click → Add to Waveform
3. Waveform window will update in real-time
```

### Control Simulation:

```tcl
# In Tcl Console:
run 1us      # Run 1 microsecond
run all      # Run until done
restart      # Restart simulation
```

## Expected Waveform Behavior

### TEST 1: TX Transmission (0xA5)

**Signal sequence:**
1. `tx_start` pulses for 1 clock cycle
2. `tx_busy` goes high
3. SCL toggles at ~100 kHz (based on prescaler)
4. SDA transitions during SCL low periods
5. After 8 bits: ACK phase (slave pulls SDA low)
6. `tx_done` pulses, `tx_busy` goes low

**Expected SDA bits:** 1, 0, 1, 0, 0, 1, 0, 1 (MSB first)

### TEST 2: TX with 0x5A

**Expected SDA bits:** 0, 1, 0, 1, 1, 0, 1, 0 (MSB first)

### TEST 3: RX Reception (0xAA)

**Signal sequence:**
1. `rx_start` pulses
2. `rx_busy` goes high
3. Slave drives SDA with each bit on SCL high
4. Master samples on SCL rising edge
5. After 8 bits: `rx_data_valid` pulses
6. `rx_data_out` contains received byte (0xAA)

**Slave drives:** 1, 0, 1, 0, 1, 0, 1, 0

### TEST 4: RX with 0x55

**Slave drives:** 0, 1, 0, 1, 0, 1, 0, 1

### TEST 5: TX with 0xFF

**Expected SDA bits:** 1, 1, 1, 1, 1, 1, 1, 1 (all ones)

## Simulation Timeline

```
Time (ms)  Event
========== ======================================================
0.0        Simulation starts
0.0-0.2 μs Reset active (rst_n = '0')
0.2 μs     Reset released (rst_n = '1')
0.5 μs     Tests begin
0.5-2.0 μs TEST 1: TX(0xA5) transmission
2.0-3.5 μs TEST 2: TX(0x5A) transmission
3.5-5.5 μs TEST 3: RX(0xAA) reception
5.5-7.5 μs TEST 4: RX(0x55) reception
7.5-9.0 μs TEST 5: TX(0xFF) transmission
9.0-10 ms  All tests complete, simulation ends
```

## Verification Checklist

### For each test, verify:

- [ ] `busy` signal goes high when transmission starts
- [ ] SCL toggles at regular intervals
- [ ] SDA changes only during SCL low periods
- [ ] Data bits appear in correct order (MSB first)
- [ ] ACK phase shows slave pulling SDA low
- [ ] `done` or `data_valid` pulse at completion
- [ ] No bus conflicts (SDA/SCL lines are '0' or '1', never 'X')
- [ ] No metastability or glitches

## Simulation Output (Transcript)

Vivado Simulator will print test messages like:

```
TEST 1: TX transmission of 0xA5
TEST 1 PASSED: ACK received for 0xA5
TEST 2: TX transmission of 0x5A
TEST 2 PASSED: ACK received for 0x5A
TEST 3: RX reception - expecting slave data 0xAA
TEST 3 PASSED: Received correct data 0xAA
...
All 5 tests completed
```

Check the Tcl Console (or "Simulation" tab) for these messages.

## Debugging Tips

### If tests fail:

1. **Check clock timing:**
   - Verify SCL period = 2 × PRESCALER × CLK_PERIOD
   - With PRESCALER=50 and CLK_PERIOD=20ns: SCL_period ≈ 2 μs (500 kHz)
   - Adjust PRESCALER if needed

2. **Check data order:**
   - Use Waveform zoom to see SDA transitions
   - Verify bits are transmitted MSB first

3. **Check ACK timing:**
   - After 8 data bits, check for 9th clock cycle
   - Slave should drive SDA low during this cycle

4. **Check bus contention:**
   - Ensure TX and slave never drive SDA high while trying to drive low
   - In waveform, SDA should be clean '0' or '1' (no 'X')

## Extending the Simulation

To add more tests:

1. Add test cases before the `test_complete <= '1';` line
2. Change `PRESCALER_VAL` for different I2C frequencies
3. Modify `SIM_TIME_LIMIT` if tests run too long
4. Change `slave_data` to test different bit patterns

## Common Issues

### Simulation takes too long to compile
- Reduce `SIM_TIME_LIMIT` from 10 ms to 1 ms
- Use `run 5ms` instead of `run all`

### No waveform data appears
- Ensure testbench is set as "Top" for Simulation
- Click "Run Simulation" not "Run Synthesis"

### Testbench errors during elaboration
- Check all VHDL files are in project
- Verify entity names match (especially if you renamed files)
- Check for syntax errors: Flow → Check Syntax

## Export Waveforms

To save simulation waveforms for documentation:

```tcl
# In Tcl Console:
write_vcd i2c_simulation.vcd

# Then open in GTKWave (if installed):
# $ gtkwave i2c_simulation.vcd
```

## Next Steps

After successful simulation:

1. Review waveforms for correctness
2. Adjust module parameters if needed
3. Create synthesis constraints for your FPGA
4. Implement design on hardware (if required)

For questions about specific signals or timing, refer to module documentation in the source files.
