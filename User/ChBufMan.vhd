library ieee,work;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use work.AddressMap.all;
use work.BusSignalTypes.all;
use work.AddressBook.all;

entity ChBufMan is
	generic( ChID : std_logic_vector(3 downto 0) );
	port(
		Clock : in std_logic;
		Reset : in std_logic;
		datain : in std_logic_vector(13 downto 0);
		dataout : out std_logic_vector(31 downto 0);
		address : out std_logic_vector(9 downto 0);
		datasize : out std_logic_vector(10 downto 0);
		fullrange : in std_logic_vector(15 downto 0);
		threshold : in std_logic_vector(15 downto 0);
		wren : out std_logic;
		byteena : out std_logic_vector(3 downto 0);
		req : in std_logic;
		ack : out std_logic
);
end ChBufMan;

architecture ChBufMan of ChBufMan is

  -- Signal Declarations -----------------------------------------------------
  signal wrpointer : std_logic_vector(10 downto 0);
  signal outdata : std_logic_vector(15 downto 0);
  signal timestamp : std_logic_vector(15 downto 0);
  -- "00": normal data
  -- "01": buffer start
  -- "10": time stamp
  -- "11": buffer end

  type ss_type is (ss_init, ss_record, ss_wait);
  signal ss : ss_type;
  ----------------------------------------------------- Signal Declarations --

begin

  address <= wrpointer(10 downto 1);
  byteena <= "0011" when wrpointer(0)='0' else "1100";
  dataout <= outdata & outdata;

--	dataout <= x"FFFFFFFF" when end_mark='1' else
--					"00" & datain & "00" & datain;
	
  -- ReadWrite Process -------------------------------------------------------
  ReadWrite : process ( Clock, Reset )
  begin
    if( Reset='1' ) then
      ss <= ss_init;
    elsif ( Clock'event and Clock = '1' ) then
      case ss is
        when ss_init =>
          timestamp <= (others=>'0');
          wrpointer <= (others=>'0');
          if (req='1') then
            ss<=ss_record;
            wren <= '1';
            outdata <= x"400" & ChID;
          end if;
        when ss_record =>
          wrpointer <= wrpointer + 1;
          if (wrpointer = "00111111110") then
            wrpointer <= wrpointer + 1;
            wren <= '1';
            outdata <= x"FFFF";
            ss <= ss_wait;
          else
            wren <= '1';
            outdata <= "00" & datain;
          end if;
        when ss_wait =>
          wren <= '0';
          if (req='0') then
            ack <= '0';
            ss <= ss_init;
          else
            datasize <= wrpointer;
            ack <= '1';
          end if;
      end case;				
    end if;
  end process ReadWrite;	
  ------------------------------------------------------- ReadWrite Process --

end ChBufMan;
