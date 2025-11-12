library ieee;--------------------------------------------------------------------------------

use ieee.std_logic_1164.all;-- I2C Master Test Bench

use ieee.numeric_std.all;--------------------------------------------------------------------------------

-- This testbench verifies the functionality of both I2C master TX and RX modules

-- Тестбенч для i2c_master-- Test scenarios include:

----   * Clock and reset generation

-- Призначення:--   * Writing data to a slave device (TX)

--   Генерує тактовий сигнал і скидання, подає тестові дані на передавач (Tx)--   * Reading data from a slave device (RX)

--   і імітує простий slave для перевірки поведінки приймача (Rx).--   * Verifying proper I2C protocol timing

----   * Simulating slave responses

-- Зауваження:--------------------------------------------------------------------------------

--   Це демонстраційний тестбенч; для повного тестування I2C (таймаути,library ieee;

--   багатобайтові передачі, коректні ACK/NACK) потрібна детальніша модель slave.use ieee.std_logic_1164.all;

use ieee.numeric_std.all;

entity tb_i2c_master is

end entity;entity i2c_master_tb is

end entity;

architecture sim of tb_i2c_master is

  -- Тактові та контрольні сигнали тестбенчуarchitecture sim of i2c_master_tb is

  signal clk    : std_logic := '0';    -- Component declarations

  signal rst_n  : std_logic := '0';    component i2c_master_tx is

        generic (

  -- Інтерфейс до DUT (Device Under Test)            CLK_FREQ : integer := 50_000_000;

  signal start   : std_logic := '0';            I2C_FREQ : integer := 100_000

  signal addr    : std_logic_vector(6 downto 0) := (others => '0');        );

  signal rw      : std_logic := '0';        port (

  signal data_in : std_logic_vector(7 downto 0) := (others => '0');            clk      : in  std_logic;

  signal data_out: std_logic_vector(7 downto 0);            rst_n    : in  std_logic;

  signal busy    : std_logic;            start    : in  std_logic;

            addr     : in  std_logic_vector(6 downto 0);

  -- Фізичні лінії I2C (тестова шина)            data_in  : in  std_logic_vector(7 downto 0);

  signal sda_tb : std_logic := 'Z'; -- сигнал, підключений до порту inout DUT            busy     : out std_logic;

  signal scl    : std_logic;            ack_err  : out std_logic;

            sda_i    : in  std_logic;

  -- Параметри симуляції            sda_o    : out std_logic;

  constant CLK_PERIOD_NS : time := 20 ns; -- приблизно 50 MHz            sda_oe   : out std_logic;

            scl_o    : out std_logic;

  -- Сигнали для простого slave-емулятора            scl_oe   : out std_logic

  signal slave_active : std_logic := '0';        );

  signal slave_byte   : std_logic_vector(7 downto 0) := x"A5"; -- байт, який надсилає slave під час читання    end component;

  signal slave_bit_idx: integer range 0 to 7 := 7;

  signal tb_done      : std_logic := '0';    component i2c_master_rx is

        generic (

begin            CLK_FREQ : integer := 50_000_000;

  ------------------------------------------------------------------            I2C_FREQ : integer := 100_000

  -- Інстанція DUT        );

  ------------------------------------------------------------------        port (

  UUT: entity work.i2c_master            clk      : in  std_logic;

    generic map (PRESCALER => 50) -- занижено для швидшої симуляції            rst_n    : in  std_logic;

    port map (            start    : in  std_logic;

      clk => clk,            addr     : in  std_logic_vector(6 downto 0);

      rst_n => rst_n,            busy     : out std_logic;

      start => start,            data_out : out std_logic_vector(7 downto 0);

      addr => addr,            ack_err  : out std_logic;

      rw => rw,            sda_i    : in  std_logic;

      data_in => data_in,            sda_o    : out std_logic;

      data_out => data_out,            sda_oe   : out std_logic;

      busy => busy,            scl_o    : out std_logic;

      sda => sda_tb,            scl_oe   : out std_logic

      scl => scl        );

    );    end component;



  ------------------------------------------------------------------    -- Constants

  -- Генератор тактового сигналу    constant CLK_PERIOD  : time := 20 ns;     -- 50 MHz clock

  ------------------------------------------------------------------    constant SLAVE_ADDR  : std_logic_vector(6 downto 0) := "1010101"; -- Example slave address

  clk_gen: process

  begin    -- Test signals

    while now < 200 ms loop    signal clk          : std_logic := '0';

      clk <= '0';    signal rst_n        : std_logic := '0';

      wait for CLK_PERIOD_NS/2;    signal sda_line     : std_logic := '1';   -- I2C bus lines (pulled up by default)

      clk <= '1';    signal scl_line     : std_logic := '1';

      wait for CLK_PERIOD_NS/2;

    end loop;    -- TX module signals

    wait;    signal tx_start     : std_logic := '0';

  end process;    signal tx_data_in   : std_logic_vector(7 downto 0) := (others => '0');

    signal tx_busy      : std_logic;

  ------------------------------------------------------------------    signal tx_ack_err   : std_logic;

  -- Скидання та стимули    signal tx_sda_i     : std_logic;

  ------------------------------------------------------------------    signal tx_sda_o     : std_logic;

  stim_proc: process    signal tx_sda_oe    : std_logic;

  begin    signal tx_scl_o     : std_logic;

  -- початкове скидання    signal tx_scl_oe    : std_logic;

  rst_n <= '0';

    wait for 200 ns;    -- RX module signals

    rst_n <= '1';    signal rx_start     : std_logic := '0';

    wait for 200 ns;    signal rx_data_out  : std_logic_vector(7 downto 0);

    signal rx_busy      : std_logic;

  -- Тест 1: запис одного байта (запис)    signal rx_ack_err   : std_logic;

  addr <= "0101010"; -- приклад 7-бітної адреси    signal rx_sda_i     : std_logic;

  rw <= '0'; -- запис    signal rx_sda_o     : std_logic;

    data_in <= x"5A";    signal rx_sda_oe    : std_logic;

  wait for CLK_PERIOD_NS; -- вирівняти з тактом    signal rx_scl_o     : std_logic;

  -- сигнал початку — однотактовий імпульс    signal rx_scl_oe    : std_logic;

    start <= '1';

    wait for CLK_PERIOD_NS;begin

    start <= '0';    -- Clock generation

    process

  -- чекати на завершення транзакції    begin

  wait until busy = '1';        wait for CLK_PERIOD/2;

  wait until busy = '0';        clk <= not clk;

  report "Запис завершено, переходжу до тесту читання";    end process;

    wait for 1 us;

    -- Reset generation

  -- Тест 2: читання одного байта (читання)    process

  addr <= "0101010";    begin

  rw <= '1'; -- читання        rst_n <= '0';

    data_in <= (others => '0');        wait for CLK_PERIOD * 5;  -- Hold reset for 5 clock cycles

        rst_n <= '1';

  -- Підготувати slave-емулятор: активувати через невеликий запас, щоб        wait;

  -- master встиг пройти фазу адреси.    end process;

  slave_byte <= x"A5";

  wait for 200 ns;    -- Instantiate TX module

  slave_active <= '1';    i2c_master_tx_inst : i2c_master_tx

        generic map (

    wait for CLK_PERIOD_NS;            CLK_FREQ => 50_000_000,

    start <= '1';            I2C_FREQ => 100_000

    wait for CLK_PERIOD_NS;        )

    start <= '0';        port map (

            clk     => clk,

  -- дочекатись завершення операції            rst_n   => rst_n,

  wait until busy = '1';            start   => tx_start,

  wait until busy = '0';            addr    => SLAVE_ADDR,

  wait for 500 ns; -- невелика пауза для стабілізації            data_in => tx_data_in,

            busy    => tx_busy,

  report "Читання завершено, data_out = " & to_hstring(data_out);            ack_err => tx_ack_err,

  tb_done <= '1';            sda_i   => tx_sda_i,

            sda_o   => tx_sda_o,

    wait;            sda_oe  => tx_sda_oe,

  end process;            scl_o   => tx_scl_o,

            scl_oe  => tx_scl_oe

  ------------------------------------------------------------------        );

  -- Простий slave-емулятор для перевірки Rx

  -- Логіка: коли active, на падінні SCL виставляє відповідний біт байта на SDA    -- Instantiate RX module

  ------------------------------------------------------------------    i2c_master_rx_inst : i2c_master_rx

  slave_proc: process        generic map (

  begin            CLK_FREQ => 50_000_000,

    wait until slave_active = '1';            I2C_FREQ => 100_000

        )

    -- Ініціалізуємо індекс біта перед передачею        port map (

    slave_bit_idx <= 7;            clk      => clk,

            rst_n    => rst_n,

    -- Чекати початку роботи SCL            start    => rx_start,

    wait until scl = '0';            addr     => SLAVE_ADDR,

    wait for 1 ns;            busy     => rx_busy,

            data_out => rx_data_out,

    -- Передаватимемо біти при кожному падінні SCL (щоб вони були стабільні до наступного підйому)            ack_err  => rx_ack_err,

    while slave_active = '1' loop            sda_i    => rx_sda_i,

      wait until scl = '0';            sda_o    => rx_sda_o,

      -- Встановити біт для майбутнього зчитування при наступному підйомі SCL            sda_oe   => rx_sda_oe,

      sda_tb <= slave_byte(slave_bit_idx);            scl_o    => rx_scl_o,

      wait until scl = '1'; -- master зчитає на підйомі            scl_oe   => rx_scl_oe

      -- Після підйому відпустити або підготувати наступний біт на падінні        );

      if slave_bit_idx = 0 then

        -- Завершили передачу 8 бітів    -- I2C bus emulation (wired-AND of all outputs)

        slave_active <= '0';    sda_line <= '0' when (tx_sda_oe = '0' and tx_sda_o = '0') or 

        sda_tb <= 'Z';                         (rx_sda_oe = '0' and rx_sda_o = '0') else '1';

        exit;    scl_line <= '0' when (tx_scl_oe = '0' and tx_scl_o = '0') or 

      else                         (rx_scl_oe = '0' and rx_scl_o = '0') else '1';

        slave_bit_idx <= slave_bit_idx - 1;

        -- На падінні налаштуємо наступний біт    -- Connect I2C bus lines to modules

        wait until scl = '0';    tx_sda_i <= sda_line;

      end if;    rx_sda_i <= sda_line;

    end loop;

    wait;    -- Test stimulus process

  end process;    process

        variable test_data : std_logic_vector(7 downto 0);

  ------------------------------------------------------------------        variable expected_data : std_logic_vector(7 downto 0);

  -- Завершення симуляції    begin

  ------------------------------------------------------------------        -- Wait for reset to complete

  finish_proc: process        wait until rst_n = '1';

  begin        wait for CLK_PERIOD * 10;

    wait until tb_done = '1';        report "Reset completed, starting tests";

    wait for 1 us;

    report "Testbench finished";        -- Test Case 1: Write data pattern 0xA5 to slave

    wait;        report "TEST CASE 1: Writing 0xA5 to slave";

  end process;        test_data := x"A5";

        tx_data_in <= test_data;

end architecture;        tx_start <= '1';

        wait for CLK_PERIOD;
        tx_start <= '0';
        
        -- Monitor TX progress
        wait until tx_busy = '1';
        report "TX started, monitoring I2C bus signals";
        
        -- Wait for TX to complete
        wait until tx_busy = '0';
        if tx_ack_err = '1' then
            report "ERROR: TX ACK error detected" severity error;
        else
            report "TX completed successfully";
        end if;
        wait for CLK_PERIOD * 10;

        -- Test Case 2: Write data pattern 0x5A to slave
        report "TEST CASE 2: Writing 0x5A to slave";
        test_data := x"5A";
        tx_data_in <= test_data;
        tx_start <= '1';
        wait for CLK_PERIOD;
        tx_start <= '0';
        
        wait until tx_busy = '0';
        if tx_ack_err = '1' then
            report "ERROR: TX ACK error detected" severity error;
        else
            report "TX completed successfully";
        end if;
        wait for CLK_PERIOD * 10;

        -- Test Case 3: Read data from slave
        report "TEST CASE 3: Reading data from slave";
        expected_data := x"55"; -- Expected response from slave
        rx_start <= '1';
        wait for CLK_PERIOD;
        rx_start <= '0';
        
        -- Monitor RX progress
        wait until rx_busy = '1';
        report "RX started, monitoring I2C bus signals";
        
        -- Wait for RX to complete
        wait until rx_busy = '0';
        wait for CLK_PERIOD;
        
        -- Verify received data
        if rx_data_out = expected_data then
            report "RX TEST PASSED: Received correct data " & 
                  to_hstring(rx_data_out);
        else
            report "RX TEST FAILED: Expected " & to_hstring(expected_data) & 
                  " but got " & to_hstring(rx_data_out) severity error;
        end if;
        wait for CLK_PERIOD * 10;

        -- End simulation
        report "Test completed successfully";
        wait;
    end process;

    -- Slave response simulation process
    process
        variable bit_count : integer;
        variable slave_data : std_logic_vector(7 downto 0);
    begin
        wait until rst_n = '1';
        slave_data := x"55"; -- Test pattern for slave response
        
        loop
            -- Wait for START condition (SDA going low while SCL high)
            wait until falling_edge(sda_line) and scl_line = '1';
            report "START condition detected";
            
            -- Wait for address byte
            bit_count := 8;  -- 7 address bits + R/W
            while bit_count > 0 loop
                wait until rising_edge(scl_line);
                bit_count := bit_count - 1;
            end loop;
            
            -- Generate ACK (pull SDA low)
            wait until falling_edge(scl_line);
            if rx_sda_oe = '1' then  -- Master is reading
                report "Slave acknowledging read request";
                -- Drive ACK
                sda_line <= '0';
                wait until rising_edge(scl_line);
                wait until falling_edge(scl_line);
                
                -- Send slave data
                for i in 7 downto 0 loop
                    sda_line <= slave_data(i);
                    wait until rising_edge(scl_line);
                    wait until falling_edge(scl_line);
                end loop;
                
                -- Release SDA for master ACK/NACK
                sda_line <= '1';
            else  -- Master is writing
                report "Slave acknowledging write request";
                -- Just ACK the address and data
                sda_line <= '0';
                wait until rising_edge(scl_line);
                wait until falling_edge(scl_line);
                
                -- Wait for data byte and ACK it
                bit_count := 8;
                while bit_count > 0 loop
                    wait until rising_edge(scl_line);
                    bit_count := bit_count - 1;
                end loop;
                
                -- Generate ACK for data
                sda_line <= '0';
                wait until rising_edge(scl_line);
                wait until falling_edge(scl_line);
                sda_line <= '1';
            end if;
        end loop;
    end process;

end architecture;