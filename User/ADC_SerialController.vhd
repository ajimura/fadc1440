library ieee,work;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use work.AddressMap.all;
use work.BusSignalTypes.all;
use work.AddressBook.all;

entity ADCController is
  port(
    Clock : in std_logic; -- SysClock(40MHz)
    BusClk : in std_logic;
    Reset : in std_logic;
    PDWN : out std_logic_vector(1 downto 0);
    CSB : out std_logic_vector(1 downto 0); -- active low
    SDIO : inout std_logic_vector(1 downto 0);
    SCLK : out std_logic_vector(1 downto 0);
    SYNC : out std_logic_vector(1 downto 0);
    ClkEnab : out std_logic;
    LocalBusAddress : in std_logic_vector(31 downto 0);
    LocalBusDataIn : in std_logic_vector(31 downto 0);
    LocalBusDataOut : out std_logic_vector(31 downto 0);
    LocalBusRS : in  std_logic;
    LocalBusWS : in  std_logic;
    LocalBusRDY : out std_logic
    );
end ADCController;

architecture ADCController of ADCController is

  component ASC_Command PORT (
    Clock : in std_logic;
    RW : in std_logic;
    Command : in std_logic;
    ACK : out std_logic;
    RegData : in std_logic_vector(23 downto 0);
    RetData : out std_logic_vector(15 downto 0);
    CSB : out  std_logic_vector(1 downto 0);
    SDIO : inout std_logic_vector(1 downto 0);
    SCLK : out std_logic_vector(1 downto 0)
    );
  end component;

  -- Signal Declarations -----
  signal ASC_RW : std_logic := '0'; -- '0': Write, '1': Read
  signal ASC_Address : std_logic_vector(12 downto 0);
  signal ASC_Data : std_logic_vector(7 downto 0);
  signal ASC_ComData : std_logic_vector(23 downto 0);
  signal ASC_RetData : std_logic_vector(15 downto 0);
  signal Execute : std_logic;
  constant ASC_Length : std_logic_vector(1 downto 0) := "00";
--
  type ss_type is (ss_init, ss_idle, ss_wait, ss_chsel1, ss_chsel2, ss_chsel3,
                   ss_chsel4,ss_command,ss_comwait,ss_update,ss_waitupdate,ss_done);
  signal ss : ss_type;
  type LBusType is (
    Initialize,
    Idle,
    Write,
    WaitASC,
    SyncGo,
    Read,
    Done );
  signal ss_bus : LBusType;
  signal send_pointer : natural range 0 to 31;
  signal Go : std_logic := '0';
  signal ASC_ACK : std_logic;
  signal PDWN_reg : std_logic_vector(1 downto 0) := "00";
  signal ClkEnab_reg : std_logic := '0';

begin

  ComIssue: ASC_Command PORT MAP (
    Clock => Clock,
    RW => ASC_RW,
    Command => Go,
    ACK => ASC_ACK,
    RegData => ASC_ComData,
    RetData => ASC_RetData,
    CSB => CSB,
    SDIO => SDIO,
    SCLK => SCLK
    );
	
  PDWN <= PDWN_reg;
  ClkEnab <= ClkEnab_reg;
	
  Control : process ( Clock, Reset )
    variable write_data: std_logic_vector(15 downto 0);
    variable count: natural;
  begin
    if (Reset = '1' ) then
      ss <= ss_init;
    elsif (Clock'event and Clock='1') then
      case ss is
        when ss_init =>
          Go <= '0';
          if (Execute='1') then
            ss<=ss_command;
          end if;
        when ss_command =>
          ASC_ComData <= ASC_RW & ASC_Length &
                         ASC_Address & ASC_Data;
          Go <= '1';
          ss <= ss_comwait;
        when ss_comwait =>
          if (ASC_ACK='1') then
            Go <= '0';
            ss <= ss_done;
          end if;
        when ss_done =>
          if (ss_bus = Done or ss_bus = Initialize) then
            ss <= ss_init;
          end if;
        when others =>
          ss <= ss_init;
      end case;
    end if;
  end process Control;
	
  -- Bus Process -------------------------------------------------------------
--  BusProcess : process ( Clock, Reset )
  BusProcess : process ( BusClk, Reset )
  begin
    if ( Reset = '1' ) then
      PDWN_reg <= "00";
      ss_bus <= Initialize;
--    elsif ( Clock'event and Clock='1' ) then
    elsif ( BusClk'event and BusClk='1' ) then
      case ss_bus is
        when Initialize =>
          LocalBusDataOut <= x"00000000";
          LocalBusRDY <= '0';
          ss_bus <= Idle;
          ASC_Address<= (others => '0');
          ASC_Data<=x"18";
          Execute <= '0';
          Sync <= "00";
          ASC_RW <= '0';

        when Idle =>
          if ( LocalBusWS = '1') then
            ss_bus <= Write;
          elsif ( LocalBusRS = '1' ) then
            ss_bus <= Read;
          end if;
				
        when Write =>
          if (LocalBusAddress(11)='1') then
            if (LocalBusAddress(3 downto 2)="00") then
              PDWN_reg <= LocalBusDataIn(1 downto 0);
            elsif (LocalBusAddress(3 downto 2)="01") then
              ClkEnab_reg <= LocalBusDataIn(0);
            elsif (LocalBusAddress(3 downto 2)="10") then -- Issue SYNC
              ss_bus <= SyncGo;
            end if;
            ss_bus <= Done;
          else
            ASC_RW <= '0';
--            ASC_Length <= "00";
            ASC_Address <= "0000" & LocalBusAddress(10 downto 2);
            ASC_DATA <= LocalBusDataIn(7 downto 0);
            ss_bus <= WaitASC;
          end if;
					
        when SyncGo =>
          SYNC <= "11";
          ss_bus <= Done;

        when Read =>
          if (LocalBusAddress(11)='1') then
            if (LocalBusAddress(3 downto 2)="00") then
              LocalBusDataOut(1 downto 0) <= PDWN_reg;
            elsif (LocalBusAddress(3 downto 2)="01") then
              LocalBusDataOut(0) <= ClkEnab_reg;
            end if;
            ss_bus <= Done;
          else
            ASC_RW <= '1';
--            ASC_Length <= "00";
            ASC_Address <= "0000" & LocalBusAddress(10 downto 2);
            ss_bus <= WaitASC;
          end if;
					
        when WaitASC =>
          Execute <= '1';
          if (ss = ss_done) then
            Execute <= '0';
            if (LocalBusRS='1') then
              LocalBusDataOut <= LocalBusAddress(15 downto 0) & ASC_RetData;
            end if;
            ss_bus <= Done;
          end if;

        when Done =>
          LocalBusRDY <= '1';
          if ( LocalBusWS='0' and LocalBusRS='0' ) then
            ss_bus <= Initialize;
          end if;
					
      end case;
    end if;
  end process BusProcess;
  ------------------------------------------------------------- Bus Process --

end ADCController;
