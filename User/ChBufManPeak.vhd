library ieee,work;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use work.AddressMap.all;
use work.BusSignalTypes.all;
use work.AddressBook.all;

entity ChBufManPeak is
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
end ChBufManPeak;

architecture ChBufManPeak of ChBufManPeak is

  -- Signal Declarations -----------------------------------------------------
  signal wrpointer : std_logic_vector(10 downto 0);
  signal outdata : std_logic_vector(15 downto 0);
  signal timestamp : std_logic_vector(15 downto 0);

  signal up,  dn,  eq : std_logic;
  signal up0, dn0, eq0 : std_logic;

  signal keepP : std_logic_vector(2 downto 0) := "000";

  signal datain0, datain1, datain2, datain3 : std_logic_vector(13 downto 0);

  type ss_type is (ss_init, ss_record, ss_wait);
  signal ss : ss_type;
  ----------------------------------------------------- Signal Declarations --

begin

  address <= wrpointer(10 downto 1);
  byteena <= "0011" when wrpointer(0)='0' else "1100";
  dataout <= outdata & outdata;
  
  -- data pipeline
  process (Clock)
  begin
    if (Clock'event and Clock='1') then
      datain0 <= datain;
      datain1 <= datain0;
      datain2 <= datain1;
      datain3 <= datain2;
    end if;
  end process;
  
  -- up, dn and eq - compare with next data
  process (Clock)
  begin
    if (Clock'event and Clock='1') then
      if (datain0 < datain) then
        up<='1'; dn<='0'; eq<='0';
      elsif (datain0=datain) then
        up<='0'; dn<='0'; eq<='1';
      else
        up<='0'; dn<='1'; eq<='0';
      end if;
      up0 <= up;
      dn0 <= dn;
      eq0 <= eq;
    end if;
  end process;

  -- check peak
  process (Clock)
  begin
    if (Clock'event and Clock='1') then
      if (datain2>threshold(13 downto 0)) then
        if ((up0='1' and dn='1') or (eq0='1' and dn='1') or (up0='1' and eq='1')) then
          keepP <= "100";
        else
          if (keepP > 0) then keepP <= keepP - 1; end if;
        end if;
      else
        if (keepP > 0) then keepP <= keepP - 1; end if;
      end if;
    end if;
  end process;

  -- Write Process
  process ( Clock, Reset )
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
            outdata <= x"4000";
          end if;

        when ss_record =>
          timestamp <= timestamp + 1;
          if (wrpointer = "00111111110" or timestamp = fullrange) then
            wrpointer <= wrpointer + 1;
            wren <= '1';
            outdata <= x"FFFF";
            ss <= ss_wait;
          else
            if (keepP="001") then         -- put timestamp
              wren <= '1';
              wrpointer <= wrpointer + 1;
              outdata <= "10" & timestamp(13 downto 0);
            elsif (keepP>0) then          -- put data
              wren <= '1';
              wrpointer <= wrpointer + 1;
              outdata <= "00" & datain3;
            else
              wren <= '0';
            end if;
          end if;

        when ss_wait =>
          if (req='0') then
            ack <= '0';
            ss <= ss_init;
          else
            datasize <= wrpointer;
            ack <= '1';
          end if;
      end case;        
    end if;
  end process;
  ------------------------------------------------------- ReadWrite Process --

end ChBufManPeak;
