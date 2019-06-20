library ieee,work;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use work.AddressMap.all;
use work.BusSignalTypes.all;
use work.AddressBook.all;

entity ADCReceiver is
  port(
    Clock : in std_logic;
    nClk : in std_logic;
    Reset : in std_logic;
    DataInA: in std_logic_vector(7 downto 0);
    DataInB: in std_logic_vector(7 downto 0);
    FCOA : in std_logic;
    FCOB : in std_logic;
    DCOA : in std_logic;
    DCOB : in std_logic;
    DataOut: out std_logic_vector(223 downto 0)
    );
end ADCReceiver;

architecture ADCReceiver of ADCReceiver is

-- DRS --
  component desconv PORT (
    pll_areset: in std_logic  := '0';
    rx_in: in std_logic_vector (7 downto 0);
    rx_inclock: in std_logic  := '0';
    rx_out: out std_logic_vector (111 downto 0);
    rx_outclock: out std_logic 
    );
  end component;

--Signal Difinitions--
  signal PreData : std_logic_vector(223 downto 0);
  signal Pre2Data : std_logic_vector(223 downto 0);
  signal SerDesOClkA, SerDesOClkB : std_logic;

begin

  DRSA: desconv PORT MAP (
    pll_areset => Reset,
    rx_in => DataInA(7 downto 0),
    rx_inclock => FCOA,
    rx_out => PreData(111 downto 0),
    rx_outclock => SerDesOClkA
    );
  DRSB: desconv PORT MAP (
    pll_areset => Reset,
    rx_in => DataInB(7 downto 0),
    rx_inclock => FCOB,
    rx_out => PreData(223 downto 112),
    rx_outclock => SerDesOClkB
    );
	
  process(SerDesOClkA)
  begin
    if (SerDesOClkA'event and SerDesOClkA='1') then
      Pre2Data(111 downto 0) <= PreData(111 downto 0);
    end if;
  end process;
  process(SerDesOClkB)
  begin
    if (SerDesOClkB'event and SerDesOClkB='1') then
      Pre2Data(223 downto 112) <= PreData(223 downto 112);
    end if;
  end process;
	
  process(Clock)
  begin
    if (Clock'event and Clock='0') then
      DataOut <= Pre2Data;
    end if;
  end process;
  
end;
