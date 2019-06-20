library ieee,work;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.AddressMap.all;
use work.BusSignalTypes.all;
use work.AddressBook.all;
use work.SpaceWireCODECIPPackage.all;
use work.RMAPTargetIPPackage.all;

entity BusController is
  port(
    Clock : in std_logic;
    Reset : in std_logic;
    ResetOutS : out std_logic;
    ResetOutH : out std_logic;
    RstTGC : in std_logic;
    -- Local Bus
    LocalBusAddress : out std_logic_vector(31 downto 0);
    LocalBusDataFromUserModules : in DataArray;
    LocalBusDataToUserModules : out std_logic_vector(31 downto 0);
    LocalBusRS : out std_logic_vector(NumUserModules-1 downto 0);
    LocalBusWS : out std_logic_vector(NumUserModules-1 downto 0);
    LocalBusRDY : in std_logic_vector(NumUserModules-1 downto 0);
    -- SpW I/O --
    port0logicaladdress : in std_logic_vector(7 downto 0);
    SpW_D_in: in std_logic;
    SpW_S_in: in std_logic;
    SpW_D_out: out std_logic;
    SpW_S_out: out std_logic;
    -- Clocks for SpW --
    SWRxClk: in std_logic;
    SWTxClk: in std_logic;
    SWClk: in std_logic
  );
end BusController;  

architecture BusController of BusController is

component RMAPTargetIP
    generic (
        gBusWidth : integer range 8 to 32);  -- 8 = 8bit, 16 = 16bit, 32 = 32bit,
    port (
        clock : in std_logic;
        reset : in std_logic;

        transmitClock      : in  std_logic;
        receiveClock       : in  std_logic;
        --SpaceWire signals
        spaceWireDataIn    : in  std_logic;
        spaceWireStrobeIn  : in  std_logic;
        spaceWireDataOut   : out std_logic;
        spaceWireStrobeOut : out std_logic;

        --Internal BUS 
        busMasterCycleOut       : out std_logic;
        busMasterStrobeOut      : out std_logic;
        busMasterAddressOut     : out std_logic_vector (31 downto 0);
        busMasterByteEnableOut  : out std_logic_vector ((gBusWidth/8)-1 downto 0);
        busMasterDataIn         : in  std_logic_vector (gBusWidth-1 downto 0);
        busMasterDataOut        : out std_logic_vector (gBusWidth-1 downto 0);
        busMasterWriteEnableOut : out std_logic;
        busMasterReadEnableOut  : out std_logic;
        busMasterAcknowledgeIn  : in  std_logic;
        busMasterTimeOutErrorIn : in  std_logic;

        -- time code
        tickIn          : in  std_logic;
        timeIn          : in  std_logic_vector(5 downto 0);
        controlFlagsIn  : in  std_logic_vector(1 downto 0);
        tickOut         : out std_logic;
        timeOut         : out std_logic_vector (5 downto 0);
        controlFlagsOut : out std_logic_vector (1 downto 0);

        -- spw control                                  
        linkStart                : in  std_logic;
        linkDisable              : in  std_logic;
        autoStart                : in  std_logic;
        linkStatus               : out std_logic_vector (15 downto 0);
        errorStatus              : out std_logic_vector (7 downto 0);
        transmitClockDivideValue : in  std_logic_vector (5 downto 0);

        -- RMAP Statemachine state                                     
        commandStateOut : out commandStateMachine;
        replyStateOut   : out replyStateMachine;

        -- RMAP_User_Decode
        rmapLogicalAddressOut : out std_logic_vector(7 downto 0);
        rmapCommandOut        : out std_logic_vector(3 downto 0);
        rmapKeyOut            : out std_logic_vector(7 downto 0);
        rmapAddressOut        : out std_logic_vector(31 downto 0);
        rmapDataLengthOut     : out std_logic_vector(23 downto 0);
        requestAuthorization  : out std_logic;
        authorizeIn           : in  std_logic;
        rejectIn              : in  std_logic;
        replyStatusIn         : in  std_logic_vector(7 downto 0);

        -- RMAP Error Code and Status
        rmapErrorCode       : out std_logic_vector(7 downto 0);
        errorIndication     : out std_logic;
        writeDataIndication : out std_logic;
        readDataIndication  : out std_logic;
        rmwDataIndication   : out std_logic;

        -- statistics                                    
        statisticalInformationClear : in  std_logic;
        statisticalInformation      : out bit32X8Array
        );
end component;

        -- SpW time conndes
  constant SWtickIn : std_logic := '0';
  constant SWtimeIn : std_logic_vector(5 downto 0) := "000000";
  constant SWcontrolFlagsIn : std_logic_vector(1 downto 0) := "00";
  signal SWtickOut : std_logic;
  signal SWtimeOut : std_logic_vector(5 downto 0);
  signal SWcontrolFlagsOut : std_logic_vector(1 downto 0);

        -- SpW control
  constant SWlinkStart : std_logic := '1';
  constant SWlinkDisable : std_logic := '0';
  constant SWautoStart : std_logic := '1';
  constant SWtransmitClockDivideValue : std_logic_vector(5 downto 0) := "000000";
  constant SWstatInfoClear : std_logic := '0';
  signal SWlinkStatus : std_logic_vector(15 downto 0);
  signal SWerrorStatus : std_logic_vector(7 downto 0);
  signal SWstatInfo : bit32X8Array;

        -- RMAP bus
  signal busMasterCycleOut : std_logic;
  signal busMasterStrobeOut : std_logic;
  signal busMasterAddressOut : std_logic_vector(31 downto 0);
  signal busMasterByteEnableOut : std_logic_vector((cBusWidth/8)-1 downto 0);
  signal busMasterDataIn : std_logic_vector(cBusWidth-1 downto 0);
  signal busMasterDataOut : std_logic_vector(cBusWidth-1 downto 0);
  signal busMasterWriteEnableOut : std_logic;
  signal busMasterReadEnableOut : std_logic;
  signal busMasterAcknowledgeIn : std_logic;
  constant busMasterTimeOutErrorIn : std_logic := '0';

        -- RMAP Statemachine state
  signal commandStateOut : commandStateMachine;
  signal replyStateOut : replyStateMachine;

  -- RMAP_User_Decode
  signal rmapLogicalAddressOut : std_logic_vector(7 downto 0);
  signal rmapCommandOut        : std_logic_vector(3 downto 0);
  signal rmapKeyOut            : std_logic_vector(7 downto 0);
  signal rmapAddressOut        : std_logic_vector(31 downto 0);
  signal rmapDataLengthOut     : std_logic_vector(23 downto 0);
  signal requestAuthorization  : std_logic;
  signal authorizeIn           : std_logic;
  signal rejectIn              : std_logic;
  signal replyStatusIn         : std_logic_vector(7 downto 0);

  -- RMAP Error Code and Status
  signal rmapErrorCode       : std_logic_vector(7 downto 0);
  signal errorIndication     : std_logic;
  signal writeDataIndication : std_logic;
  signal readDataIndication  : std_logic;
  signal rmwDataIndication   : std_logic;

  -- local bus
  signal ss_bus : BusControlProcessType;
  signal DestModuleID : ModuleID := -1;
--  signal L_BusDataIn : DataArray;
--  signal L_BusRDY : ControlRegArray;

        -- external bus
  signal SW_address: std_logic_vector(31 downto 0);
  signal SW_DataOut: std_logic_vector(31 downto 0);
  signal SW_DataIn: std_logic_vector(31 downto 0);
  signal SW_rs: std_logic;
  signal SW_ws: std_logic;
  signal SW_req: std_logic;
  signal SW_ack: std_logic;

  -- External Bus
  signal ExtBusAddress : std_logic_vector(31 downto 0);
  signal ExtBusDataIn : std_logic_vector(31 downto 0);
  signal ExtBusDataOut : std_logic_vector(31 downto 0);
  signal ExtBusRS : std_logic;
  signal ExtBusWS : std_logic;
  signal ExtBusRDY : std_logic;
  signal RstSoftS : std_logic := '0';
  signal RstSoftH : std_logic := '0';
--  signal LogAddr   : std_logic_vector(7 downto 0) := x"FD";
  signal LogAddr   : std_logic_vector(7 downto 0);
  
  type ssdump_type is (Init, Connect, GetData, Send, Wait232, Done);
  signal ss_dump : ssdump_type;

begin

  RMAPIP : RMAPTargetIP
  generic map (gBusWidth => cBusWidth)
  port map(
    clock => SWClk,
    reset => Reset,

    transmitClock => SWTxClk,
    receiveClock => SWRxClk,
    spaceWireDataIn => SpW_D_in,
    spaceWireStrobeIn => SpW_S_in,
    spaceWireDataOut => SpW_D_out,
    spaceWireStrobeOut => SpW_S_out,

    busMasterCycleOut => busMasterCycleOut,
    busMasterStrobeOut => busMasterStrobeOut,
    busMasterAddressOut => busMasterAddressOut,
    busMasterByteEnableOut => busMasterByteEnableOut,
    busMasterDataIn => busMasterDataIn,
    busMasterDataOut => busMasterDataOut,
    busMasterWriteEnableOut => busMasterWriteEnableOut,
    busMasterReadEnableOut => busMasterReadEnableOut,
    busMasterAcknowledgeIn => busMasterAcknowledgeIn,
    busMasterTimeOutErrorIn => busMasterTimeOutErrorIn,

    tickIn => SWtickIn,
    timeIn => SWtimeIn,
    controlFlagsIn => SWcontrolFlagsIn,
    tickOut => SWtickOut,
    timeOut => SWtimeOut,
    controlFlagsOut => SWcontrolFlagsOut,

    linkStart => SWlinkStart,
    linkDisable => SWlinkDisable,
    autoStart => SWautoStart,
    linkStatus => SWlinkStatus,
    errorStatus => SWerrorStatus,
    transmitClockDivideValue => SWtransmitClockDivideValue,

    commandStateOut => commandStateOut,
    replyStateOut => replyStateOut,

    rmapLogicalAddressOut => rmapLogicalAddressOut,
    rmapCommandOut => rmapCommandOut,
    rmapKeyOut => rmapKeyOut,
    rmapAddressOut => rmapAddressOut,
    rmapDataLengthOut => rmapDataLengthOut,
    requestAuthorization => requestAuthorization,
    authorizeIn => authorizeIn,
    rejectIn => rejectIn,
    replyStatusIn => replyStatusIn,

    rmapErrorCode => rmapErrorCode,
    errorIndication => errorIndication,
    writeDataIndication => writeDataIndication,
    readDataIndication => readDataIndication,
    rmwDataIndication => rmwDataIndication,

    statisticalInformationClear => SWstatInfoClear,
    statisticalInformation => SWstatInfo
  );
  AuthProc: process (Clock)
  begin
    if (Clock'event and Clock='1') then
      if (requestAuthorization = '1') then
--      if (rmapLogicalAddressOut = x"FE" and rmapKeyOut = x"CC") then
        if (rmapLogicalAddressOut /= LogAddr) then
          authorizeIn <= '0';
          rejectIn <= '1';
          replyStatusIn <= x"0c";
        elsif (rmapKeyOut /= x"CC") then
          authorizeIn <= '0';
          rejectIn <= '1';
          replyStatusIn <= x"03";
        else
          authorizeIn <= '1';
          rejectIn <= '0';
          replyStatusIn <= x"00";
        end if;
      else
        authorizeIn <= '0';
        rejectIn <= '0';
        replyStatusIn <= x"00";
      end if;
    end if;
  end process AuthProc;

  -- Bus Latch --
--  BusLatchProcess : process (Clock)
--  begin
--    if (Clock'event and Clock='1') then
--      for i in 0 to NumUserModules-1 loop
--        L_BusDataIn(i) <= LocalBusDataFromUserModules(i);
--        L_BusRDY(i) <= LocalBusRDY(i);
--      end loop;
--    end if;
--  end process BusLatchProcess;

  -- Bus Switch
  SW_req <= busMasterStrobeOut;
  SW_rs <= busMasterReadEnableOut;
  SW_ws <= busMasterWriteEnableOut;
  SW_address <= busMasterAddressOut;
  SW_DataIn <= busMasterDataOut;

  busMasterDataIn <= SW_DataOut;
  busMasterAcknowledgeIn <= SW_ack;
  
--  busMasterTimeOutErrorIn <= '0';
  
--  SWlinkStart <= '1';
--  SWlinkDisable <= '0';
--  SWautoStart <= '1';
--  SWtransmitClockDivideValue <= "000000";

  ResetOutS <= RstSoftS;
  ResetOutH <= RstSoftH;

  LogAddr <= port0logicaladdress + x"80";

  -- Bus Control Process -----------------------------------------------------
  BusControlProcess : process ( Clock, Reset )
  begin
    if ( Reset='1' ) then
      ss_bus <= Initialize;
    elsif ( Clock'event and Clock='1' ) then
      case ss_bus is
        when Initialize =>
          for i in 0 to NumUserModules-1 loop
            LocalBusRS(i) <= '0';
            LocalBusWS(i) <= '0';
          end loop;
          SW_DataOut <= x"00000000";
          SW_ack <= '0';
          RstSoftS <= '0';
          RstSoftH <= '0';
          ss_bus <= Idle;

        when Idle =>
          if (SW_req='1') then
            ss_bus <= GetDest;
          end if;
  
        when GetDest =>
          if (SW_address(19) = '1') then -- general register
            if (SW_rs='1') then
              if (SW_address(11 downto 0) = CMN_Version) then -- version info.
                SW_DataOut( 7 downto  0) <= CurVersion(31 downto 24);
                SW_DataOut(15 downto  8) <= CurVersion(23 downto 16);
                SW_DataOut(23 downto 16) <= CurVersion(15 downto  8);
                SW_DataOut(31 downto 24) <= CurVersion( 7 downto  0);
              elsif (SW_address(11 downto 0) = CMN_LogAddr) then
--                SW_DataOut( 7 downto  0) <= x"00";
--                SW_DataOut(15 downto  8) <= x"00";
--                SW_DataOut(23 downto 16) <= x"00";
                SW_DataOut(31 downto 24) <= LogAddr;
              elsif (SW_address(11 downto 0) = CMN_SpWStatus0) then
--                SW_DataOut( 7 downto  0) <= x"00";
--                SW_DataOut(15 downto  8) <= x"00";
                SW_DataOut(23 downto 16) <= SWlinkStatus(15 downto 8);
                SW_DataOut(31 downto 24) <= SWlinkStatus( 7 downto 0);
              elsif (SW_address(11 downto 0) = CMN_SpWStatus1) then
                SW_DataOut( 7 downto  0) <= SWstatInfo(6)(31 downto 24);
                SW_DataOut(15 downto  8) <= SWstatInfo(6)(23 downto 16);
                SW_DataOut(23 downto 16) <= SWstatInfo(6)(15 downto  8);
                SW_DataOut(31 downto 24) <= SWstatInfo(6)( 7 downto  0);
              elsif (SW_address(11 downto 0) = CMN_SpWStatus2) then
                SW_DataOut( 7 downto  0) <= SWstatInfo(7)(31 downto 24);
                SW_DataOut(15 downto  8) <= SWstatInfo(7)(23 downto 16);
                SW_DataOut(23 downto 16) <= SWstatInfo(7)(15 downto  8);
                SW_DataOut(31 downto 24) <= SWstatInfo(7)( 7 downto  0);
              else
                SW_DataOut( 7 downto  0) <= SW_address(15 downto 8);
                SW_DataOut(15 downto  8) <= SW_address( 7 downto 0);
                SW_DataOut(23 downto 16) <= x"BA";
                SW_DataOut(31 downto 24) <= x"D0";
              end if;
            elsif (SW_ws='1') then
              if (SW_address(11 downto 0) = CMN_Reset) then
                RstSoftS <= '1';
              elsif (SW_address(11 downto 0) = CMN_HardRst) then
                RstSoftH <= '1';
--              elsif (SW_address(11 downto 0) = CMN_LogAddr) then
--                LogAddr <= SW_DataIn(31 downto 24);
              end if;
            end if;
            ss_bus <= Done;
          else
            case SW_address(18 downto 16) is
              when "000" => DestModuleID <= 0; -- L1D
              when "001" => DestModuleID <= -1; -- LTC
              when "010" => DestModuleID <= 2; -- TGC
              when "011" => DestModuleID <= 3; -- ROC
              when "100" => DestModuleID <= 4; -- EBM
              when "101" => DestModuleID <= 5; -- ASC
              when "110" => DestModuleID <= 6; -- TMP
              when others => DestModuleID <= -1;
            end case;
            ss_bus <= SetBus;
          end if;

        when SetBus =>
          if (DestModuleID = -1) then
            SW_DataOut <= x"AD0BAD0B";  -- "0bad0bad" byte swapped
            ss_bus <= Done;
          else
            LocalBusAddress <= SW_address;
            LocalBusDataToUserModules(31 downto 24) <= SW_DataIn( 7 downto  0);
            LocalBusDataToUserModules(23 downto 16) <= SW_DataIn(15 downto  8);
            LocalBusDataToUserModules(15 downto  8) <= SW_DataIn(23 downto 16);
            LocalBusDataToUserModules( 7 downto  0) <= SW_DataIn(31 downto 24);            
            ss_bus <= Connect;
          end if;
        
        when Connect =>
          if ( SW_ws = '1' ) then
            LocalBusWS ( DestModuleID ) <= '1';
          else
            LocalBusRS ( DestModuleID ) <= '1';
          end if;
--          if ( L_BusRDY( DestModuleID ) = '1' ) then
          if ( LocalBusRDY( DestModuleID ) = '1' ) then
            ss_bus <= WaitLocalDone;
          end if;

        when WaitLocalDone =>
          LocalBusWS( DestModuleID ) <= '0';
          LocalBusRS( DestModuleID ) <= '0';
--          SW_DataOut(31 downto 24) <= L_BusDataIn( DestModuleID )( 7 downto  0);
--          SW_DataOut(23 downto 16) <= L_BusDataIn( DestModuleID )(15 downto  8);
--          SW_DataOut(15 downto  8) <= L_BusDataIn( DestModuleID )(23 downto 16);
--          SW_DataOut( 7 downto  0) <= L_BusDataIn( DestModuleID )(31 downto 24);
          SW_DataOut(31 downto 24) <= LocalBusDataFromUserModules( DestModuleID )( 7 downto  0);
          SW_DataOut(23 downto 16) <= LocalBusDataFromUserModules( DestModuleID )(15 downto  8);
          SW_DataOut(15 downto  8) <= LocalBusDataFromUserModules( DestModuleID )(23 downto 16);
          SW_DataOut( 7 downto  0) <= LocalBusDataFromUserModules( DestModuleID )(31 downto 24);
          ss_bus <= Done;

        when Done =>
            SW_ack <= '1';
            ss_bus <= AckDone;

        when AckDone =>
          if ( SW_req='1') then
            SW_ack <= '1';
          else
            SW_ack <= '0';
            ss_bus <= Initialize;
          end if;
      end case;

    end if;
  end process BusControlProcess;

end BusController;
