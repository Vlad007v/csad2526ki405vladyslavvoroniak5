library ieee;use ieee.numeric_std.all;

use ieee.std_logic_1164.all;

use ieee.numeric_std.all;

library ieee;

entity i2c_master_tx isuse ieee.std_logic_1164.all;

  port (use ieee.numeric_std.all;

    clk         : in  std_logic;

    rst_n       : in  std_logic;entity i2c_master_tx is

    start_tx    : in  std_logic;  port (

    data_in     : in  std_logic_vector(7 downto 0);    clk         : in  std_logic;

    scl_rise    : in  std_logic;    rst_n       : in  std_logic;

    scl_fall    : in  std_logic;    start_tx    : in  std_logic;

    sda_in      : in  std_logic;    data_in     : in  std_logic_vector(7 downto 0);

    sda_out     : out std_logic;    scl_rise    : in  std_logic;

    busy        : out std_logic;    scl_fall    : in  std_logic;

    ack_received: out std_logic;    sda_in      : in  std_logic;

    done        : out std_logic    sda_out     : out std_logic;

  );    busy        : out std_logic;

end entity;    ack_received: out std_logic;

    done        : out std_logic

architecture rtl of i2c_master_tx is  );

  type t_state is (IDLE, START, SEND_BIT, RECV_ACK, FINISH);end entity;

  signal state : t_state := IDLE;

  signal bit_cnt : integer range 0 to 7 := 0;architecture rtl of i2c_master_tx is

  signal shift_reg : std_logic_vector(7 downto 0) := (others => '0');  type t_state is (IDLE, START, SEND_BIT, RECV_ACK, FINISH);

  signal sda_drive : std_logic := 'Z';  signal state : t_state := IDLE;

  signal ack_r : std_logic := '1';  signal bit_cnt : integer range 0 to 7 := 0;

  signal done_r: std_logic := '0';  signal shift_reg : std_logic_vector(7 downto 0) := (others => '0');

begin  signal sda_drive : std_logic := 'Z';

  sda_out <= sda_drive;  signal ack_r : std_logic := '1';

  busy <= '1' when state /= IDLE else '0';  signal done_r: std_logic := '0';

  ack_received <= ack_r;begin

  done <= done_r;  sda_out <= sda_drive;

  busy <= '1' when state /= IDLE else '0';

  process(clk, rst_n)  ack_received <= ack_r;

  begin  done <= done_r;

    if rst_n = '0' then

      state <= IDLE;  process(clk, rst_n)

      shift_reg <= (others => '0');  begin

      bit_cnt <= 0;    if rst_n = '0' then

      sda_drive <= 'Z';      state <= IDLE;

      ack_r <= '1';      shift_reg <= (others => '0');

      done_r <= '0';      bit_cnt <= 0;

    elsif rising_edge(clk) then      sda_drive <= 'Z';

      done_r <= '0';      ack_r <= '1';

      if state = IDLE then      done_r <= '0';

        if start_tx = '1' then    elsif rising_edge(clk) then

          shift_reg <= data_in;      done_r <= '0';

          bit_cnt <= 7;      if state = IDLE then

          state <= START;        if start_tx = '1' then

        end if;          shift_reg <= data_in;

      elsif state = START then          bit_cnt <= 7;

        if scl_fall = '1' then          state <= START;

          sda_drive <= shift_reg(bit_cnt);        end if;

          state <= SEND_BIT;      elsif state = START then

        end if;        if scl_fall = '1' then

      elsif state = SEND_BIT then          sda_drive <= shift_reg(bit_cnt);

        if scl_fall = '1' then          state <= SEND_BIT;

          if bit_cnt = 0 then        end if;

            sda_drive <= 'Z';      elsif state = SEND_BIT then

            state <= RECV_ACK;        if scl_fall = '1' then

          else          if bit_cnt = 0 then

            bit_cnt <= bit_cnt - 1;            sda_drive <= 'Z';

            sda_drive <= shift_reg(bit_cnt - 1);            state <= RECV_ACK;

          end if;          else

        end if;            bit_cnt <= bit_cnt - 1;

      elsif state = RECV_ACK then            sda_drive <= shift_reg(bit_cnt - 1);

        if scl_rise = '1' then          end if;

          ack_r <= sda_in;        end if;

          state <= FINISH;      elsif state = RECV_ACK then

        end if;        if scl_rise = '1' then

      elsif state = FINISH then          ack_r <= sda_in;

        done_r <= '1';          state <= FINISH;

        state <= IDLE;        end if;

      end if;      elsif state = FINISH then

    end if;        done_r <= '1';

  end process;        state <= IDLE;

end architecture;      end if;

    end if;
  end process;
end architecture;
architecture rtl of i2c_master_tx is
  ----------------------------------------------------------------
  -- Clock Generation Constants and Signals
  ----------------------------------------------------------------
  -- Number of system clocks per SCL half-period
  constant HALF_PERIOD : integer := integer(CLK_FREQ / (2 * I2C_FREQ));

  -- Clock divider counter (0 to HALF_PERIOD-1)
  signal div_cnt : integer range 0 to (2**31-1) := 0;

  -- Internal SCL tracking
  signal scl_int : std_logic := '1';  -- Current SCL level
  signal tick    : std_logic := '0';  -- Half-period strobe

  ----------------------------------------------------------------
  -- FSM State Definition
  ----------------------------------------------------------------
  type state_t is (
    IDLE,   -- Waiting for start command
    START,  -- Generating START condition (SDA high->low while SCL high)
    ADDR,   -- Transmitting 7-bit address + R/W bit
    DATA,   -- Transmitting 8-bit data byte
    ACK,    -- Waiting for slave acknowledgment
    STOP,   -- Generating STOP condition (SDA low->high while SCL high)
    DONE    -- Transfer complete, returning to IDLE
  );
  signal state : state_t := IDLE;

  ----------------------------------------------------------------
  -- Data Path Signals
  ----------------------------------------------------------------
  -- Bit counter (MSB first transmission)
  signal bit_idx : integer range 0 to 7 := 7;

  library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

  entity i2c_master_tx is
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
  end entity;

  architecture rtl of i2c_master_tx is
    type t_state is (IDLE, START, SEND_BIT, RECV_ACK, FINISH);
    signal state : t_state := IDLE;
    signal bit_cnt : integer range 0 to 7 := 0;
    signal shift_reg : std_logic_vector(7 downto 0) := (others => '0');
    signal sda_drive : std_logic := 'Z';
    signal ack_r : std_logic := '1';
    signal done_r: std_logic := '0';
  begin
    sda_out <= sda_drive;
    busy <= '1' when state /= IDLE else '0';
    ack_received <= ack_r;
    done <= done_r;

    process(clk, rst_n)
    begin
      if rst_n = '0' then
        state <= IDLE;
        shift_reg <= (others => '0');
        bit_cnt <= 0;
        sda_drive <= 'Z';
        ack_r <= '1';
        done_r <= '0';
      elsif rising_edge(clk) then
        done_r <= '0';
        if state = IDLE then
          if start_tx = '1' then
            shift_reg <= data_in;
            bit_cnt <= 7;
            state <= START;
          end if;
        elsif state = START then
          if scl_fall = '1' then
            sda_drive <= shift_reg(bit_cnt);
            state <= SEND_BIT;
          end if;
        elsif state = SEND_BIT then
          if scl_fall = '1' then
            if bit_cnt = 0 then
              sda_drive <= 'Z';
              state <= RECV_ACK;
            else
              bit_cnt <= bit_cnt - 1;
              sda_drive <= shift_reg(bit_cnt - 1);
            end if;
          end if;
        elsif state = RECV_ACK then
          if scl_rise = '1' then
            ack_r <= sda_in;
            state <= FINISH;
          end if;
        elsif state = FINISH then
          done_r <= '1';
          state <= IDLE;
        end if;
      end if;
    end process;
  end architecture;
  -- Shift register for outgoing data
  signal shift_reg : std_logic_vector(7 downto 0) := (others => '0');

  -- Address byte register (includes R/W bit)
  signal addr_byte : std_logic_vector(7 downto 0) := (others => '0');

  -- Acknowledgment bit from slave
  signal ack_bit : std_logic := '1';  -- '0' = ACK, '1' = NACK

begin
  ----------------------------------------------------------------
  -- Clock Divider Process
  --
  -- Generates a tick signal every HALF_PERIOD system clock cycles.
  -- This establishes the basic timing for the I2C SCL signal:
  -- - One complete SCL cycle = 2 * HALF_PERIOD system clocks
  -- - The tick signal marks the boundaries of SCL half-periods
  -- - Used to time all I2C bus operations
  ----------------------------------------------------------------
  process(clk)
  begin
    if rising_edge(clk) then
      if rst_n = '0' then
        -- Reset state
        div_cnt <= 0;
        tick <= '0';
      else
        if div_cnt >= HALF_PERIOD-1 then
          -- End of half-period reached
          div_cnt <= 0;      -- Reset counter
          tick <= '1';       -- Generate tick pulse
        else
          -- Continue counting
          div_cnt <= div_cnt + 1;
          tick <= '0';
        end if;
      end if;
    end if;
  end process;

  ----------------------------------------------------------------
  -- SCL Generator Process
  --
  -- Generates the internal SCL clock signal by toggling on each tick.
  -- Properties:
  -- - SCL starts and resets to '1' (bus idle state)
  -- - Toggles on each tick for 50% duty cycle
  -- - One complete SCL cycle takes 2 * HALF_PERIOD system clocks
  -- - Frequency = system_clock / (2 * HALF_PERIOD) = I2C_FREQ
  ----------------------------------------------------------------
  process(clk)
  begin
    if rising_edge(clk) then
      if rst_n = '0' then
        -- Reset: set SCL high (idle state)
        scl_int <= '1';
      else
        if tick = '1' then
          -- Toggle SCL on each tick
          scl_int <= not scl_int;
        end if;
      end if;
    end if;
  end process;

  ----------------------------------------------------------------
  -- SCL Edge Detection
  --
  -- Generates one-clock-wide strobes for SCL edges, particularly
  -- the falling edge which is used to time FSM state transitions.
  -- 
  -- I2C requires:
  -- - Data changes occur while SCL is low
  -- - Data is stable and valid while SCL is high
  -- Thus, we use SCL falling edge to trigger state changes and
  -- data updates, ensuring proper setup time before SCL rises.
  ----------------------------------------------------------------
  signal prev_scl : std_logic := '1';      -- Previous SCL value
  signal scl_falling : std_logic := '0';   -- SCL falling edge strobe

  process(clk)
  begin
    if rising_edge(clk) then
      if rst_n = '0' then
        -- Reset edge detection
        prev_scl <= '1';
        scl_falling <= '0';
      else
        -- Store previous SCL for edge detection
        prev_scl <= scl_int;
        -- Default: no edge
        scl_falling <= '0';

        -- Detect falling edge (1->0 transition) during tick
        if tick = '1' and prev_scl = '1' and scl_int = '0' then
          scl_falling <= '1';  -- Generate falling edge strobe
        end if;
      end if;
    end if;
  end process;

  ----------------------------------------------------------------
  -- Address Preparation Process
  --
  -- Assembles the I2C address byte when a new transfer starts:
  -- - Bits 7-1: 7-bit slave address from 'addr' input
  -- - Bit 0: R/W bit from 'rw' input ('0' = write, '1' = read)
  --
  -- The assembled byte will be transmitted MSB-first during the
  -- ADDR state, followed by an ACK bit from the addressed slave.
  ----------------------------------------------------------------
  process(clk)
  begin
    if rising_edge(clk) then
      if rst_n = '0' then
        -- Reset: clear address byte
        addr_byte <= (others => '0');
      else
        -- On transfer start (in IDLE), assemble address byte
        if start = '1' and state = IDLE then
          addr_byte <= addr & rw;  -- Concatenate address and R/W
        end if;
      end if;
    end if;
  end process;

  ----------------------------------------------------------------
  -- Main FSM Process
  --
  -- Implements the I2C master transmitter state machine:
  -- 1. IDLE    -> Wait for start command
  -- 2. START   -> Generate START condition
  -- 3. ADDR    -> Send slave address + R/W
  -- 4. ACK     -> Get acknowledge from slave
  -- 5. DATA    -> Send data byte (if write)
  -- 6. ACK     -> Get acknowledge from slave
  -- 7. STOP    -> Generate STOP condition
  -- 8. DONE    -> Complete transfer
  --
  -- State transitions occur on SCL falling edges to ensure:
  -- - Data changes while SCL is low
  -- - Proper setup time before SCL rises
  -- - Clean sampling of ACK bits
  ----------------------------------------------------------------
  process(clk)
  begin
    if rising_edge(clk) then
      if rst_n = '0' then
        -- Reset state
        state <= IDLE;
        shift_reg <= (others => '0');
        bit_idx <= 7;               -- Start from MSB
        busy <= '0';               -- Not busy
        ack_err <= '0';           -- Clear errors
        ack_bit <= '1';           -- Default to NACK
      else
        -- State machine advances on SCL falling edge
        if scl_falling = '1' then
          case state is
            when IDLE =>
              busy <= '0';
              ack_err <= '0';
              if start = '1' then
                state <= START;
                busy <= '1';
              end if;

            when START =>
              -- START: SDA goes low while SCL high
              shift_reg <= addr_byte;
              bit_idx <= 7;
              state <= ADDR;

            when ADDR =>
              -- shift out address bits MSB first
              if bit_idx >= 0 then
                shift_reg <= shift_reg;
                if bit_idx = 0 then
                  state <= ACK;
                else
                  bit_idx <= bit_idx - 1;
                end if;
              end if;

            when DATA =>
              if bit_idx >= 0 then
                if bit_idx = 0 then
                  state <= ACK;
                else
                  bit_idx <= bit_idx - 1;
                end if;
              end if;

            when ACK =>
              -- read ack bit provided by slave (sampled elsewhere via sda_line)
              if ack_bit = '1' then
                ack_err <= '1'; -- NACK
                state <= STOP;
              else
                -- ACK received; if we were sending address, move to DATA
                if shift_reg = addr_byte then
                  -- prepare data byte for transmission
                  shift_reg <= data_in;
                  bit_idx <= 7;
                  state <= DATA;
                else
                  state <= STOP;
                end if;
              end if;

            when STOP =>
              state <= DONE;

            when DONE =>
              busy <= '0';
              state <= IDLE;

            when others => state <= IDLE;
          end case;
        end if;
      end if;
    end if;
  end process;

  ----------------------------------------------------------------
  -- I2C Bus Control Process
  --
  -- Manages the SDA and SCL lines according to I2C protocol:
  -- - Uses open-drain signaling (*_oe controls when to drive)
  -- - Changes SDA only when SCL is low (except START/STOP)
  -- - Implements special timing for START (SDA↓ while SCL=1)
  -- - Implements special timing for STOP (SDA↑ while SCL=1)
  -- - Releases SDA during ACK to let slave drive
  --
  -- Timing is controlled by scl_int:
  -- - SDA changes occur during SCL low period
  -- - SDA remains stable during SCL high period
  -- - Special cases for START/STOP conditions
  ----------------------------------------------------------------
  process(scl_int, state, shift_reg, bit_idx)
  begin
    -- Default: release both lines (high-impedance)
    sda_o <= '1';   -- Output value (irrelevant when released)
    sda_oe <= '1';  -- Release SDA (high-Z)
    scl_o <= '1';   -- Output value (irrelevant when released)
    scl_oe <= '1';  -- Release SCL (high-Z)

    if state = START then
      -- ensure SDA low while SCL high
      sda_o <= '0';
      sda_oe <= '0';
      scl_oe <= '1'; -- release SCL
    elsif state = ADDR then
      -- during SCL low, drive next bit
      if scl_int = '0' then
        sda_o <= shift_reg(bit_idx);
        sda_oe <= '0';
      else
        sda_oe <= '1';
      end if;
      scl_oe <= '1';
    elsif state = DATA then
      if scl_int = '0' then
        sda_o <= shift_reg(bit_idx);
        sda_oe <= '0';
      else
        sda_oe <= '1';
      end if;
      scl_oe <= '1';
    elsif state = ACK then
      -- release SDA so slave can drive ack during ACK phase
      sda_oe <= '1';
      scl_oe <= '1';
    elsif state = STOP then
      -- STOP: SDA goes high while SCL high (release SDA)
      sda_o <= '1';
      sda_oe <= '1';
      scl_oe <= '1';
    else
      -- IDLE / DONE
      sda_oe <= '1';
      scl_oe <= '1';
    end if;
  end process;

end architecture;
