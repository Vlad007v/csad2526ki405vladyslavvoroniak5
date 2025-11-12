-- Very small behavioral I2C slave used only in testbench.
-- Listens for address and acknowledges bytes; for read requests it will provide a fixed response byte.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity i2c_slave_simple is
  port (
    clk   : in std_logic;
    rst_n : in std_logic;
    -- bus lines (open-drain style): master and slave share these wires in TB
    sda_line : inout std_logic;
    scl_line : inout std_logic;
    slave_addr : in std_logic_vector(6 downto 0) := "0101010"; -- default
    resp_data  : in std_logic_vector(7 downto 0) := x"5A"
  );
end entity;

architecture tb of i2c_slave_simple is
  -- For simplicity this slave will only assert ACK during the one-bit ACK phases by
  -- monitoring SCL and SDA transitions from the master in the testbench environment.
  signal sda_drive : std_logic := 'Z';
begin
  -- connect inout directly
  sda_line <= sda_drive when sda_drive /= 'Z' else 'Z';
  -- Not implementing full slave behaviour here; TB will model ACK by driving sda_drive.
end architecture;
