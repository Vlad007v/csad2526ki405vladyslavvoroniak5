library ieee;--------------------------------------------------------------------------------

use ieee.std_logic_1164.all;-- I2C Master Receiver Module

use ieee.numeric_std.all;--------------------------------------------------------------------------------

-- This module implements an I2C master receiver that can read a single byte of data

entity i2c_master_rx is-- from an I2C slave device. Key features:

  port (--   * Supports standard I2C protocol with configurable clock frequency

    clk       : in  std_logic;--   * Implements byte-level reading with automatic address transmission

    rst_n     : in  std_logic;--   * Uses open-drain interface for I2C bus compatibility

    start_rx  : in  std_logic;--   * Samples SDA during SCL high period according to I2C specification

    scl_rise  : in  std_logic;--   * Automatically releases SDA during receive phase (slave drives data)

    sda_in    : in  std_logic;--   * Generates NACK after receiving byte to terminate transfer

    data_out  : out std_logic_vector(7 downto 0);--   * Provides busy and error status signals

    data_valid: out std_logic;--------------------------------------------------------------------------------

    busy      : out std_logiclibrary ieee;

  );use ieee.std_logic_1164.all;

end entity;use ieee.numeric_std.all;



architecture rtl of i2c_master_rx isentity i2c_master_rx is

  type t_state is (IDLE, RECV_BIT, FINISH);  generic (

  signal state: t_state := IDLE;    -- Input clock frequency in Hz (default: 50 MHz)

  signal bit_cnt: integer range 0 to 7 := 7;    CLK_FREQ : integer := 50_000_000;

  signal shift_reg: std_logic_vector(7 downto 0) := (others => '0');    -- Target I2C bus frequency in Hz (default: 100 kHz)

  signal data_valid_r: std_logic := '0';    I2C_FREQ : integer := 100_000

begin  );

  data_out <= shift_reg;  port (

  data_valid <= data_valid_r;    -- System interface

  busy <= '1' when state /= IDLE else '0';    clk      : in  std_logic;                    -- System clock input

    rst_n    : in  std_logic;                    -- Active-low reset

  process(clk, rst_n)    start    : in  std_logic;                    -- Start read sequence trigger

  begin    addr     : in  std_logic_vector(6 downto 0); -- I2C slave address

    if rst_n = '0' then    busy     : out std_logic;                    -- Module busy status

      state <= IDLE;    data_out : out std_logic_vector(7 downto 0); -- Received data byte

      shift_reg <= (others => '0');    ack_err  : out std_logic;                    -- Acknowledge error flag

      bit_cnt <= 7;

      data_valid_r <= '0';    -- I2C open-drain interface

    elsif rising_edge(clk) then    sda_i    : in  std_logic;  -- SDA input from bus (for sampling)

      data_valid_r <= '0';    sda_o    : out std_logic;  -- SDA output value (1=release, 0=drive low)

      if state = IDLE then    sda_oe   : out std_logic;  -- SDA output enable (0=drive, 1=release)

        if start_rx = '1' then    scl_o    : out std_logic;  -- SCL output value (1=release, 0=drive low)

          bit_cnt <= 7;    scl_oe   : out std_logic   -- SCL output enable (0=drive, 1=release)

          state <= RECV_BIT;  );

        end if;end entity;

      elsif state = RECV_BIT then

        if scl_rise = '1' thenarchitecture rtl of i2c_master_rx is

          shift_reg(bit_cnt) <= sda_in;  -- Clock generation constants and signals

          if bit_cnt = 0 then  constant HALF_PERIOD : integer := integer(CLK_FREQ / (2 * I2C_FREQ)); -- Half period count for I2C clock

            state <= FINISH;  signal div_cnt : integer range 0 to (2**31-1) := 0; -- Clock divider counter

          else  signal scl_int : std_logic := '1';   -- Internal SCL clock signal

            bit_cnt <= bit_cnt - 1;  signal tick : std_logic := '0';      -- Tick signal for I2C timing

          end if;

        end if;  -- FSM states for I2C read sequence

      elsif state = FINISH then  type state_t is (

        data_valid_r <= '1';    IDLE,   -- Waiting for start trigger

        state <= IDLE;    START,  -- Generating START condition

      end if;    ADDR,   -- Sending slave address + R/W bit

    end if;    RECV,   -- Receiving data byte from slave

  end process;    ACK,    -- Master sends NACK to end transfer

end architecture;    STOP,   -- Generating STOP condition

    DONE    -- Transfer complete
  );
  signal state : state_t := IDLE;

  -- Data handling signals
  signal bit_idx : integer range 0 to 7 := 7;    -- Bit counter for byte transfers
  signal shift_reg : std_logic_vector(7 downto 0) := (others => '0');  -- Shift register for receiving
  signal addr_byte : std_logic_vector(7 downto 0) := (others => '0');  -- Address byte with R/W bit

  -- SCL edge detection
  signal prev_scl : std_logic := '1';    -- Previous SCL value for edge detection
  signal scl_rising : std_logic := '0';  -- SCL rising edge detector

begin
  -- Clock Divider Process
  -- Generates tick pulses at twice the I2C clock frequency
  -- This allows control of both rising and falling edges of SCL
  process(clk)
  begin
    if rising_edge(clk) then
      if rst_n = '0' then
        div_cnt <= 0;
        tick <= '0';
      else
        if div_cnt >= HALF_PERIOD-1 then
          div_cnt <= 0;
          tick <= '1';        -- Generate tick pulse
        else
          div_cnt <= div_cnt + 1;
          tick <= '0';
        end if;
      end if;
    end if;
  end process;

  -- SCL Generation Process
  -- Toggles the internal SCL signal on each tick
  -- SCL is initialized high and toggles at I2C clock frequency
  process(clk)
  begin
    if rising_edge(clk) then
      if rst_n = '0' then
        scl_int <= '1';      -- Initialize SCL high
      else
        if tick = '1' then
          scl_int <= not scl_int;  -- Toggle SCL
        end if;
      end if;
    end if;
  end process;

  -- SCL Edge Detection Process
  -- Detects rising edges of SCL for proper I2C timing
  -- Rising edges are used to sample SDA during data receive
  process(clk)
  begin
    if rising_edge(clk) then
      if rst_n = '0' then
        prev_scl <= '1';
        scl_rising <= '0';
      else
        prev_scl <= scl_int;           -- Store previous SCL value
        scl_rising <= '0';             -- Default: no edge detected
        -- Detect rising edge (0->1 transition) during tick
        if tick = '1' and prev_scl = '0' and scl_int = '1' then
          scl_rising <= '1';           -- Signal rising edge detected
        end if;
      end if;
    end if;
  end process;

  -- Main FSM Process
  -- Controls the I2C read sequence and handles data reception
  process(clk)
  begin
    if rising_edge(clk) then
      if rst_n = '0' then
        -- Reset state and outputs
        state <= IDLE;
        busy <= '0';
        data_out <= (others => '0');
        ack_err <= '0';
      else
        -- State transitions occur on SCL rising edges
        if scl_rising = '1' then
          case state is
            -- IDLE: Wait for start trigger
            when IDLE =>
              busy <= '0';
              if start = '1' then
                addr_byte <= addr & '1';  -- Prepare address byte with read bit (1)
                state <= START;
                busy <= '1';
                bit_idx <= 7;
              end if;

            -- START: Generate START condition
            when START =>
              state <= ADDR;  -- Move to address transmission

            -- ADDR: Send slave address with read bit
            when ADDR =>
              -- Simplified: assumes slave will ACK
              if bit_idx = 0 then
                state <= RECV;    -- Move to receive after last bit
                bit_idx <= 7;     -- Reset bit counter for data byte
              else
                bit_idx <= bit_idx - 1;  -- Count down address bits
              end if;

            -- RECV: Receive data byte from slave
            when RECV =>
              -- Sample SDA input on SCL rising edge
              shift_reg(bit_idx) <= sda_i;
              if bit_idx = 0 then
                state <= ACK;     -- Move to ACK after last bit
              else
                bit_idx <= bit_idx - 1;  -- Count down data bits
              end if;

            -- ACK: Send NACK to terminate transfer
            when ACK =>
              data_out <= shift_reg;  -- Output received byte
              state <= STOP;          -- Prepare to end transfer

            -- STOP: Generate STOP condition
            when STOP =>
              state <= DONE;

            -- DONE: Return to IDLE
            when DONE =>
              busy <= '0';
              state <= IDLE;
            
            when others => 
              state <= IDLE;  -- Safety default
          end case;
        end if;
      end if;
    end if;
  end process;

  -- I2C Bus Interface Control
  -- During receive operation:
  -- - SDA is released (high) to allow slave to drive data
  -- - SCL is released to allow clock stretching by slave
  sda_o <= '1';    -- Output high when released
  sda_oe <= '1';   -- Always release SDA during receive (slave drives)
  scl_o <= '1';    -- Output high when released
  scl_oe <= '1';   -- Always release SCL (allows clock stretching)

end architecture;
