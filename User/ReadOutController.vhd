library ieee,work;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use work.AddressMap.all;
use work.BusSignalTypes.all;
use work.AddressBook.all;

entity ReadOutController is
  port(
     Clock : in std_logic;
     BusClk : in std_logic;
     Reset : in std_logic;
     RstSoftS : in std_logic;
     RstSoftH : in std_logic;
     ReadReady : in std_logic_vector(NumEvtBuffer-1 downto 0);
     ReadDone : out std_logic_vector(NumEvtBuffer-1 downto 0);
     LocalBusAddress : in std_logic_vector(31 downto 0);
     LocalBusDataIn : in std_logic_vector(31 downto 0);
     LocalBusDataOut : out std_logic_vector(31 downto 0);
     LocalBusRS : in std_logic;
     LocalBusWS : in std_logic;
     LocalBusRDY : out std_logic
   );
end ReadOutController;

architecture ReadOutController of ReadOutController is

  signal donereg : std_logic_vector(NumEvtBuffer-1 downto 0);

  type bustype is (Initialize, Idle, Write, Read, Wait0, Wait1, Done);
  signal ss_bus : bustype; --BusProcessType;

begin

-- uncomment 2018/12/7: Done used in 80MHz process in EBM
--  Sync : process ( Clock )
--  begin
--    if ( Clock'event and Clock='1' ) then
  ReadDone <= donereg;
--    end if;
--  end process Sync;

  BusProcess : process ( BusClk, Reset, RstSoftS, RstSoftH )
  begin
    if ( Reset = '1' or RstSoftH='1') then
      donereg <= (others=>'0');
      ss_bus <= Initialize;
    elsif ( RstSoftS='1') then
      ss_bus <= Initialize;
    elsif ( BusClk'event and BusClk='1' ) then
      case ss_bus is
        when Initialize =>
          LocalBusDataOut <= x"00000000";
          LocalBusRDY <= '0';
          donereg <= (others=>'0');
          ss_bus <= Idle;

        when Idle =>
          if ( LocalBusWS = '1' ) then
            ss_bus <= Write;
          elsif ( LocalBusRS = '1' ) then
            ss_bus <= Read;
          end if;
        
        when Write =>
          if ( LocalBusAddress(2) = ROC_Done(2) ) then --ROC_Done
            donereg <= LocalBusDataIn(NumEvtBuffer-1 downto 0);
          end if;
          ss_bus <= Wait0;

        when Read =>
          case LocalBusAddress(2) is
            when ROC_Ready(2) => LocalBusDataOut(NumEvtBuffer-1 downto 0) <= ReadReady;
            when ROC_Done(2)  => LocalBusDataOut(NumEvtBuffer-1 downto 0) <= donereg;
          end case;
          ss_bus <= Done;

        when Wait0 =>
          ss_bus <= Wait1;

        when Wait1 =>
          ss_bus <= Done;

        when Done =>
          LocalBusRDY <= '1';
          if ( LocalBusWS='0' and LocalBusRS='0' ) then
            ss_bus <= Initialize;
          end if;
          
      end case;
    end if;
  end process BusProcess;
  ------------------------------------------------------------- Bus Process --

end ReadOutController;
