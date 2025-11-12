library ieee;--------------------------------------------------------------------------------

use ieee.std_logic_1164.all;-- I2C Master Clock Generator

use ieee.numeric_std.all;--

-- This module generates all timing signals needed for I2C master operation:

entity i2c_master_clock is-- - SCL clock signal at the specified I2C frequency

  generic (-- - Edge detection strobes for synchronizing state machines

    PRESCALER : natural := 250-- - Half-period ticks for precise timing control

  );--

  port (-- Key Features:

    clk      : in  std_logic;-- - Configurable system clock and target I2C clock frequencies

    rst_n    : in  std_logic;-- - Clean edge detection for FSM synchronization

    enable   : in  std_logic := '1';-- - Automatic period calculation based on frequency parameters

    scl      : out std_logic;--

    scl_rise : out std_logic;-- Usage:

    scl_fall : out std_logic-- 1. Configure CLK_FREQ and I2C_FREQ generics for your system

  );-- 2. Connect system clock and reset

end entity;-- 3. Use scl_rising/scl_falling for FSM state transitions

-- 4. Use half_tick for timing intermediate operations

architecture rtl of i2c_master_clock is--------------------------------------------------------------------------------

  signal cnt    : unsigned(31 downto 0) := (others => '0');library ieee;

  signal scl_reg: std_logic := '1';use ieee.std_logic_1164.all;

beginuse ieee.numeric_std.all;

  process(clk, rst_n)

  beginentity i2c_master_clock is

    if rst_n = '0' then  ----------------------------------------------------------------

      cnt <= (others => '0');  -- Configuration Generics

      scl_reg <= '1';  ----------------------------------------------------------------

      scl_rise <= '0';  generic (

      scl_fall <= '0';    -- System clock frequency in Hz (default: 50 MHz)

    elsif rising_edge(clk) then    -- Used to calculate division ratio for I2C clock generation

      scl_rise <= '0';    CLK_FREQ : integer := 50_000_000;

      scl_fall <= '0';

      if enable = '1' then    -- Target I2C SCL frequency in Hz (default: 100 kHz)

        if cnt = PRESCALER - 1 then    -- Standard I2C speeds: 100kHz (standard), 400kHz (fast), 1MHz+ (fast+)

          cnt <= (others => '0');    I2C_FREQ : integer := 100_000

          scl_reg <= not scl_reg;  );

          if scl_reg = '0' then

            scl_rise <= '1';  ----------------------------------------------------------------

          else  -- Interface Ports

            scl_fall <= '1';  ----------------------------------------------------------------

          end if;  port (

        else    -- System clock input

          cnt <= cnt + 1;    -- All internal logic is synchronized to this clock

        end if;    clk    : in  std_logic;

      end if;

    end if;    -- Active-low asynchronous reset

  end process;    -- Resets all counters and brings SCL to idle state (high)

    rst_n  : in  std_logic;

  scl <= scl_reg;

end architecture;    -- Internal SCL level output

    -- Represents the logical level of SCL:
    -- '1' = SCL should be released (pulled high by external pull-up)
    -- '0' = SCL should be driven low
    scl_int    : out std_logic;

    -- Edge detection strobes
    -- One-clock-wide pulses that occur on SCL transitions:
    scl_rising  : out std_logic;  -- Pulses when SCL goes from low to high
    scl_falling : out std_logic;  -- Pulses when SCL goes from high to low

    -- Half-period timing strobe
    -- Pulses once every half SCL period
    -- Use this for timing operations that need to happen mid-bit
    half_tick   : out std_logic
  );
end entity;

architecture rtl of i2c_master_clock is
  ----------------------------------------------------------------
  -- Constants and Internal Signals
  ----------------------------------------------------------------
  -- Number of system clock cycles for half an SCL period
  -- This sets the actual SCL frequency: f_SCL = CLK_FREQ / (2 * HALF_PERIOD)
  constant HALF_PERIOD : integer := integer(CLK_FREQ / (2 * I2C_FREQ));

  -- Clock divider counter
  -- Counts from 0 to HALF_PERIOD-1 repeatedly
  signal div_cnt : integer range 0 to (2**31-1) := 0;

  -- Internal SCL register
  -- Toggles every HALF_PERIOD cycles to generate SCL
  signal scl_reg : std_logic := '1';

  -- Internal tick signal
  -- Pulses for one clock cycle at each half-period boundary
  signal tick    : std_logic := '0';

  -- Previous SCL value for edge detection
  -- Used to detect rising and falling edges of SCL
  signal prev_scl : std_logic := '1';

begin

  ----------------------------------------------------------------
  -- Clock Divider Process
  --
  -- This process divides the system clock to generate tick pulses
  -- at twice the desired SCL frequency (two ticks per SCL period).
  -- The tick signal is used to:
  -- 1. Toggle SCL level (in the SCL generator process)
  -- 2. Drive the half_tick output for external timing
  -- 3. Synchronize edge detection
  ----------------------------------------------------------------
  process(clk)
  begin
    if rising_edge(clk) then
      if rst_n = '0' then
        -- Reset: clear counter and tick
        div_cnt <= 0;
        tick <= '0';
      else
        if div_cnt >= HALF_PERIOD-1 then
          -- End of half-period reached:
          -- - Reset counter for next half-period
          -- - Generate tick pulse for one clock cycle
          div_cnt <= 0;
          tick <= '1';
        else
          -- Counting: increment counter, clear tick
          div_cnt <= div_cnt + 1;
          tick <= '0';
        end if;
      end if;
    end if;
  end process;

  ----------------------------------------------------------------
  -- SCL Generator Process
  --
  -- Generates the actual SCL signal by toggling on each tick.
  -- SCL starts and resets to '1' (idle/released state).
  -- Each tick causes SCL to toggle, creating a 50% duty cycle:
  -- - Period = 2 * HALF_PERIOD system clock cycles
  -- - Frequency = CLK_FREQ / (2 * HALF_PERIOD) = I2C_FREQ
  ----------------------------------------------------------------
  process(clk)
  begin
    if rising_edge(clk) then
      if rst_n = '0' then
        -- Reset: set SCL high (idle state)
        scl_reg <= '1';
      else
        if tick = '1' then
          -- Toggle SCL on each tick
          scl_reg <= not scl_reg;
        end if;
      end if;
    end if;
  end process;

  ----------------------------------------------------------------
  -- Edge Detection and Strobe Generation Process
  --
  -- This process generates three key timing signals:
  -- 1. half_tick: direct passthrough of internal tick
  -- 2. scl_rising: one-clock pulse when SCL goes from 0 to 1
  -- 3. scl_falling: one-clock pulse when SCL goes from 1 to 0
  --
  -- These strobes are used by the I2C master state machines to:
  -- - Time data changes (on SCL falling edge)
  -- - Sample data (on SCL rising edge)
  -- - Perform mid-bit operations (on half_tick)
  ----------------------------------------------------------------
  process(clk)
  begin
    if rising_edge(clk) then
      if rst_n = '0' then
        -- Reset: clear all strobes and previous SCL value
        prev_scl <= '1';
        scl_rising <= '0';
        scl_falling <= '0';
        half_tick <= '0';
      else
        -- Default: clear all strobes (they are active for one clock only)
        scl_rising <= '0';
        scl_falling <= '0';
        half_tick <= '0';

        if tick = '1' then
          -- On tick: generate appropriate strobes
          half_tick <= '1';  -- always pulse half_tick

          -- Edge detection using previous and current SCL
          if prev_scl = '0' and scl_reg = '1' then
            scl_rising <= '1';   -- 0->1 transition
          elsif prev_scl = '1' and scl_reg = '0' then
            scl_falling <= '1';  -- 1->0 transition
          end if;

          -- Store current SCL for next edge detection
          prev_scl <= scl_reg;
        end if;
      end if;
    end if;
  end process;

  scl_int <= scl_reg;

end architecture;
