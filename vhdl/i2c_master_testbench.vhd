library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- I2C Master Complete Testbench
-- ==============================
-- This testbench provides comprehensive testing of I2C master TX and RX modules
-- Features:
--   * Clock and reset generation
--   * Multiple test scenarios for TX (transmit to slave)
--   * Slave device simulation for RX testing
--   * I2C bus emulation with wired-AND behavior
--   * Test reports and waveform generation

entity i2c_master_testbench is
end entity;

architecture sim of i2c_master_testbench is

  -- ============================================================================
  -- COMPONENT DECLARATIONS
  -- ============================================================================

  component i2c_master_clock is
    generic (
      PRESCALER : natural := 250
    );
    port (
      clk      : in  std_logic;
      rst_n    : in  std_logic;
      enable   : in  std_logic := '1';
      scl      : out std_logic;
      scl_rise : out std_logic;
      scl_fall : out std_logic
    );
  end component;

  component i2c_master_tx is
    port (
      clk         : in  std_logic;
      rst_n       : in  std_logic;
      start_tx    : in  std_logic;
      data_in     : in  std_logic_vector(7 downto 0);
      scl_rise    : in  std_logic;
      scl_fall    : in  std_logic;
      sda_in      : in  std_logic;
      sda_out     : out std_logic;
      busy        : out std_logic;
      ack_received: out std_logic;
      done        : out std_logic
    );
  end component;

  component i2c_master_rx is
    port (
      clk       : in  std_logic;
      rst_n     : in  std_logic;
      start_rx  : in  std_logic;
      scl_rise  : in  std_logic;
      sda_in    : in  std_logic;
      data_out  : out std_logic_vector(7 downto 0);
      data_valid: out std_logic;
      busy      : out std_logic
    );
  end component;

  -- ============================================================================
  -- TIMING CONSTANTS
  -- ============================================================================

  constant CLK_PERIOD     : time := 20 ns;   -- 50 MHz system clock
  constant SIM_TIME_LIMIT : time := 10 ms;   -- Total simulation time
  constant PRESCALER_VAL  : natural := 50;   -- I2C clock generation prescaler

  -- ============================================================================
  -- TEST SIGNALS - CLOCK AND RESET
  -- ============================================================================

  signal clk     : std_logic := '0';
  signal rst_n   : std_logic := '0';

  -- ============================================================================
  -- I2C BUS SIGNALS
  -- ============================================================================

  signal scl          : std_logic := '1';
  signal scl_rise     : std_logic := '0';
  signal scl_fall     : std_logic := '0';
  signal sda_i2c_bus  : std_logic := '1';  -- Wired-AND of all SDA drivers

  -- ============================================================================
  -- TX MODULE SIGNALS
  -- ============================================================================

  signal tx_start        : std_logic := '0';
  signal tx_data_in      : std_logic_vector(7 downto 0) := (others => '0');
  signal tx_busy         : std_logic;
  signal tx_ack_received : std_logic;
  signal tx_done         : std_logic;
  signal tx_sda_out      : std_logic;

  -- ============================================================================
  -- RX MODULE SIGNALS
  -- ============================================================================

  signal rx_start      : std_logic := '0';
  signal rx_data_out   : std_logic_vector(7 downto 0);
  signal rx_data_valid : std_logic;
  signal rx_busy       : std_logic;

  -- ============================================================================
  -- SLAVE SIMULATION SIGNALS
  -- ============================================================================

  signal slave_enabled    : std_logic := '0';
  signal slave_data       : std_logic_vector(7 downto 0) := x"AA";
  signal slave_bit_index  : integer range 0 to 7 := 7;
  signal slave_sda_drive  : std_logic := '1';

  -- ============================================================================
  -- TEST STATE AND COUNTERS
  -- ============================================================================

  signal test_number    : integer := 0;
  signal test_complete  : std_logic := '0';

begin

  -- ============================================================================
  -- SYSTEM CLOCK GENERATION (50 MHz)
  -- ============================================================================
  -- Generates the system clock at 50 MHz (20 ns period)
  -- This clock drives all synchronous logic

  clk_gen: process
  begin
    while test_complete = '0' loop
      clk <= '0';
      wait for CLK_PERIOD / 2;
      clk <= '1';
      wait for CLK_PERIOD / 2;
    end loop;
    wait;
  end process;

  -- ============================================================================
  -- RESET GENERATION
  -- ============================================================================
  -- Generates active-low reset signal
  -- rst_n = '0' for first 200 ns, then normal operation

  reset_gen: process
  begin
    rst_n <= '0';  -- Assert reset
    wait for 200 ns;
    rst_n <= '1';  -- Release reset
    wait;
  end process;

  -- ============================================================================
  -- INSTANTIATE I2C CLOCK GENERATOR
  -- ============================================================================

  i2c_clk_gen : i2c_master_clock
    generic map (
      PRESCALER => PRESCALER_VAL
    )
    port map (
      clk      => clk,
      rst_n    => rst_n,
      enable   => '1',
      scl      => scl,
      scl_rise => scl_rise,
      scl_fall => scl_fall
    );

  -- ============================================================================
  -- INSTANTIATE I2C MASTER TX MODULE
  -- ============================================================================

  tx_module : i2c_master_tx
    port map (
      clk         => clk,
      rst_n       => rst_n,
      start_tx    => tx_start,
      data_in     => tx_data_in,
      scl_rise    => scl_rise,
      scl_fall    => scl_fall,
      sda_in      => sda_i2c_bus,
      sda_out     => tx_sda_out,
      busy        => tx_busy,
      ack_received=> tx_ack_received,
      done        => tx_done
    );

  -- ============================================================================
  -- INSTANTIATE I2C MASTER RX MODULE
  -- ============================================================================

  rx_module : i2c_master_rx
    port map (
      clk       => clk,
      rst_n     => rst_n,
      start_rx  => rx_start,
      scl_rise  => scl_rise,
      sda_in    => sda_i2c_bus,
      data_out  => rx_data_out,
      data_valid=> rx_data_valid,
      busy      => rx_busy
    );

  -- ============================================================================
  -- I2C BUS EMULATION (Wired-AND for Open-Drain)
  -- ============================================================================
  -- In I2C, multiple devices can drive the bus low
  -- This implements the wired-AND behavior:
  -- - If TX drives low (sda_out='0') OR slave drives low, bus is low
  -- - Otherwise bus is pulled high (by external pull-up resistor)

  sda_i2c_bus <= '0' when (tx_sda_out = '0' or slave_sda_drive = '0') else '1';

  -- ============================================================================
  -- SLAVE DEVICE SIMULATOR
  -- ============================================================================
  -- Simulates a simple I2C slave that:
  -- 1. Recognizes ACK requests (SDA low during SCL high after address)
  -- 2. Drives data on SDA during READ operations
  -- 3. Releases SDA for NACK response

  slave_simulator: process
  begin
    wait until rst_n = '1';
    
    main_loop: loop
      -- Wait for TX module to start transmission
      wait until scl = '0' or tx_busy = '1';
      
      report "Slave: Detected TX activity, waiting for address phase";
      
      -- Wait for address byte (8 bits = 8 SCL cycles)
      for i in 0 to 8 loop
        wait until scl_rise = '1';
        report "Slave: Address bit " & integer'image(i);
      end loop;
      
      -- Simulate slave ACK for address (drive SDA low)
      report "Slave: Sending ACK for address";
      slave_sda_drive <= '0';
      wait until scl_fall = '1';
      slave_sda_drive <= '1';  -- Release SDA
      
      -- Wait for data byte if TX is still active
      if tx_busy = '1' then
        report "Slave: Waiting for data byte";
        for i in 0 to 8 loop
          wait until scl_rise = '1';
          report "Slave: Data bit " & integer'image(i);
        end loop;
        
        -- Simulate slave ACK for data
        report "Slave: Sending ACK for data byte";
        slave_sda_drive <= '0';
        wait until scl_fall = '1';
        slave_sda_drive <= '1';
      end if;
      
      -- If RX is active, simulate slave transmitting data
      if rx_busy = '1' then
        report "Slave: RX mode - transmitting test data " & to_hstring(slave_data);
        slave_bit_index <= 7;
        
        for bit_idx in 7 downto 0 loop
          slave_bit_index <= bit_idx;
          -- Drive bit on SDA
          if slave_data(bit_idx) = '1' then
            slave_sda_drive <= '1';  -- Release for '1'
          else
            slave_sda_drive <= '0';  -- Drive for '0'
          end if;
          
          wait until scl_rise = '1';
          report "Slave: Transmitted bit " & integer'image(bit_idx) & " = " & 
                  std_logic'image(slave_data(bit_idx));
          wait until scl_fall = '1';
        end loop;
        
        slave_sda_drive <= '1';  -- Release SDA for master ACK/NACK
        report "Slave: Data transmission complete";
      end if;
      
      wait for 1 us;  -- Wait before next transaction
    end loop;
  end process;

  -- ============================================================================
  -- MAIN TEST STIMULUS PROCESS
  -- ============================================================================
  -- Executes comprehensive test scenarios

  test_stimulus: process
    variable test_count : integer := 0;
  begin
    report "========================================";
    report "I2C Master Testbench Starting";
    report "========================================";
    
    -- Wait for reset to complete
    wait until rst_n = '1';
    wait for 500 ns;
    
    report "Reset complete, beginning tests";
    
    -- ========================================================================
    -- TEST 1: TX with test data 0xA5 (10100101)
    -- ========================================================================
    test_number <= 1;
    test_count := test_count + 1;
    
    report "TEST 1: TX transmission of 0xA5";
    tx_data_in <= x"A5";
    slave_enabled <= '1';
    slave_data <= x"AA";
    
    tx_start <= '1';
    wait for CLK_PERIOD;
    tx_start <= '0';
    
    -- Wait for transmission to complete
    wait until tx_busy = '0';
    wait for CLK_PERIOD * 10;
    
    if tx_ack_received = '0' then
      report "TEST 1 PASSED: ACK received for 0xA5" severity note;
    else
      report "TEST 1 FAILED: No ACK received" severity error;
    end if;
    
    if tx_done = '1' then
      report "TEST 1 PASSED: TX completed" severity note;
    end if;
    
    wait for 1 us;
    
    -- ========================================================================
    -- TEST 2: TX with test data 0x5A (01011010)
    -- ========================================================================
    test_number <= 2;
    test_count := test_count + 1;
    
    report "TEST 2: TX transmission of 0x5A";
    tx_data_in <= x"5A";
    
    tx_start <= '1';
    wait for CLK_PERIOD;
    tx_start <= '0';
    
    wait until tx_busy = '0';
    wait for CLK_PERIOD * 10;
    
    if tx_ack_received = '0' then
      report "TEST 2 PASSED: ACK received for 0x5A" severity note;
    else
      report "TEST 2 FAILED: No ACK received" severity error;
    end if;
    
    wait for 1 us;
    
    -- ========================================================================
    -- TEST 3: RX reception of data from slave
    -- ========================================================================
    test_number <= 3;
    test_count := test_count + 1;
    
    report "TEST 3: RX reception - expecting slave data 0xAA";
    slave_data <= x"AA";
    
    rx_start <= '1';
    wait for CLK_PERIOD;
    rx_start <= '0';
    
    wait until rx_busy = '0';
    wait for CLK_PERIOD * 10;
    
    if rx_data_valid = '1' then
      if rx_data_out = x"AA" then
        report "TEST 3 PASSED: Received correct data 0xAA" severity note;
      else
        report "TEST 3 FAILED: Expected 0xAA but received " & to_hstring(rx_data_out) severity error;
      end if;
    else
      report "TEST 3 FAILED: Data not valid" severity error;
    end if;
    
    wait for 1 us;
    
    -- ========================================================================
    -- TEST 4: RX reception of different pattern 0x55
    -- ========================================================================
    test_number <= 4;
    test_count := test_count + 1;
    
    report "TEST 4: RX reception - expecting slave data 0x55";
    slave_data <= x"55";
    
    rx_start <= '1';
    wait for CLK_PERIOD;
    rx_start <= '0';
    
    wait until rx_busy = '0';
    wait for CLK_PERIOD * 10;
    
    if rx_data_valid = '1' then
      if rx_data_out = x"55" then
        report "TEST 4 PASSED: Received correct data 0x55" severity note;
      else
        report "TEST 4 FAILED: Expected 0x55 but received " & to_hstring(rx_data_out) severity error;
      end if;
    else
      report "TEST 4 FAILED: Data not valid" severity error;
    end if;
    
    wait for 1 us;
    
    -- ========================================================================
    -- TEST 5: TX with maximum value 0xFF
    -- ========================================================================
    test_number <= 5;
    test_count := test_count + 1;
    
    report "TEST 5: TX transmission of 0xFF";
    tx_data_in <= x"FF";
    
    tx_start <= '1';
    wait for CLK_PERIOD;
    tx_start <= '0';
    
    wait until tx_busy = '0';
    wait for CLK_PERIOD * 10;
    
    if tx_ack_received = '0' then
      report "TEST 5 PASSED: ACK received for 0xFF" severity note;
    else
      report "TEST 5 FAILED: No ACK received" severity error;
    end if;
    
    wait for 1 us;
    
    -- ========================================================================
    -- TEST COMPLETE
    -- ========================================================================
    
    report "========================================";
    report "All " & integer'image(test_count) & " tests completed";
    report "========================================";
    
    test_complete <= '1';
    wait;
    
  end process;

end architecture sim;
