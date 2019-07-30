library ieee,work;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use work.AddressMap.all;
use work.BusSignalTypes.all;
use work.AddressBook.all;

entity EventBuffer is
  port(
    Clock : in std_logic;
    BusClk : in std_logic; -- 100MHz
    Reset : in std_logic;
    RstSoftS : in std_logic;
    RstSoftH : in std_logic;
    DataIn : in std_logic_vector(223 downto 0);
    BufferStart : in std_logic_vector(NumEvtBuffer-1 downto 0);
    BufferFree : out std_logic_vector(NumEvtBuffer-1 downto 0);
    ReadDone : in std_logic_vector(NumEvtBuffer-1 downto 0);
    ReadReady : out std_logic_vector(NumEvtBuffer-1 downto 0);
    LocalBusAddress : in std_logic_vector(31 downto 0);
    LocalBusDataIn : in std_logic_vector(31 downto 0);
    LocalBusdataout : out std_logic_vector(31 downto 0);
    LocalBusRS : in std_logic;
    LocalBusWS : in std_logic;
    LocalBusRDY : out std_logic
    );
end EventBuffer;

architecture EventBuffer of EventBuffer is

  -- Component Declaration ---------------------------------------------------
  component EventBufferManager
    port(
      Clock : in std_logic;
      BusClk : in std_logic; -- 100MHz
      Reset : in std_logic;
      RstSoftS : in std_logic;
      RstSoftH : in std_logic;
      DataIn : in std_logic_vector(223 downto 0);
      BufferStart : in std_logic;
      BufferFree : out std_logic;
      ReadDone : in std_logic;
      ReadReady : out std_logic;
      FullRange : in std_logic_vector(15 downto 0);
      CmpType : in std_logic_vector(8 downto 0);
      Thres : in ChArray16;
      excessp : in std_logic_vector(7 downto 0);
      excessd : in std_logic_vector(7 downto 0);
      LocalBusAddress : in std_logic_vector(31 downto 0);
      LocalBusDataIn : in std_logic_vector(31 downto 0);
      LocalBusDataOut : out std_logic_vector(31 downto 0);
      LocalBusRS : in std_logic;
      LocalBusWS : in std_logic;
      LocalBusRDY : out std_logic
      );
  end component;

  -- Signal Declarations -----------------------------------------------------
--	type DatArr is array ( integer range NumEvtBuffer-1 downto 0 )
--		of std_logic_vector(31 downto 0);
  signal BusAddress, BusDataIn, BusDataOut : BufArray32; --DatArr;
  signal BusRS : std_logic_vector(NumEvtBuffer-1 downto 0);
  signal BusWS : std_logic_vector(NumEvtBuffer-1 downto 0);
  signal BusRDY : std_logic_vector(NumEvtBuffer-1 downto 0);
  signal CurBuf : integer;
  signal TmpDataOut : std_logic_vector(31 downto 0);
  signal TmpBusRDY : std_logic;

  -- register
--        signal fullrange : std_logic_vector(15 downto 0):=x"0800";
  signal fullrange : std_logic_vector(15 downto 0):=x"0320";  -- 20 usec
--  signal cmptype : std_logic_vector(9 downto 0) := "1000010000";
  signal cmptype : std_logic_vector(8 downto 0) := "0010000";
  signal thres : ChArray16 := (x"0000", x"0000", x"0000", x"0000", 
                               x"0000", x"0000", x"0000", x"0000",
                               x"0000", x"0000", x"0000", x"0000", 
                               x"0000", x"0000", x"0000", x"0000");
  signal excessp : std_logic_vector(7 downto 0) := "00001010";
  signal excessd : std_logic_vector(7 downto 0) := "00001010";

  type EBBusType is (
    Initialize,
    Idle,
    SetBus,
    Write,
    Read,
    RdyWait,
    Done );
  signal ss_bus : EBBusType;

begin

  EBMgen : for i in 0 to NumEvtBuffer-1 generate 
    comEBM : EventBufferManager
      port map(
        Clock => Clock,
        BusClk => BusClk,
        Reset => Reset,
        RstSoftS => RstSoftS,
        RstSoftH => RstSoftH,
        DataIn => DataIn,
        BufferStart => BufferStart(i),
        BufferFree => BufferFree(i),
        ReadDone => ReadDone(i),
        ReadReady => ReadReady(i),
        FullRange => fullrange,
        CmpType => cmptype,
        Thres => thres,
        excessp => excessp,
        excessd => excessd,
        LocalBusAddress => LocalBusAddress,
        LocalBusDataIn => LocalBusDataIn,
        LocalBusDataOut => BusDataOut(i),
        LocalBusRS => BusRS(i),
        LocalBusWS => BusWS(i),
        LocalBusRDY => BusRDY(i) 
        );
  end generate EBMgen;
	
  cmptype(4) <= '1' when cmptype(3 downto 0)="0000" and cmptype(8 downto 5)="0000" else '0';
--  cmptype(9) <= '1' when cmptype(8 downto 5)="0000" else '0';

  CurBuf <= CONV_INTEGER(LocalBusAddress(21 downto 20));
		
  LocalBusDataOut <= TmpDataOut; -- when LocalBusAddress(7)='1' else
--                     BusDataOut(0) when LocalBusAddress(17 downto 16)="00" else
--                     BusDataOut(1) when LocalBusAddress(17 downto 16)="01" else
--                     BusDataOut(2) when LocalBusAddress(17 downto 16)="10" else
--                     BusDataOut(3) when LocalBusAddress(17 downto 16)="11";

  LocalBusRDY <= TmpBusRDY; -- when LocalBusAddress(7)='0' else
--                 BusRDY(0) when LocalBusAddress(17 downto 16)="00" else
--                 BusRDY(1) when LocalBusAddress(17 downto 16)="01" else
--                 BusRDY(2) when LocalBusAddress(17 downto 16)="10" else
--                 BusRDY(3) when LocalBusAddress(17 downto 16)="11";
                 
--  BusRS(0) <= LocalBusRS when LocalBusAddress(17 downto 16)="00" and LocalBusAddress(7)='0' else '0';
--  BusRS(1) <= LocalBusRS when LocalBusAddress(17 downto 16)="01" and LocalBusAddress(7)='0' else '0';
--  BusRS(2) <= LocalBusRS when LocalBusAddress(17 downto 16)="10" and LocalBusAddress(7)='0' else '0';
--  BusRS(3) <= LocalBusRS when LocalBusAddress(17 downto 16)="11" and LocalBusAddress(7)='0' else '0';

--  BusWS(0) <= LocalBusWS when LocalBusAddress(17 downto 16)="00" and LocalBusAddress(7)='0' else '0';
--  BusWS(1) <= LocalBusWS when LocalBusAddress(17 downto 16)="01" and LocalBusAddress(7)='0' else '0';
--  BusWS(2) <= LocalBusWS when LocalBusAddress(17 downto 16)="10" and LocalBusAddress(7)='0' else '0';
--  BusWS(3) <= LocalBusWS when LocalBusAddress(17 downto 16)="11" and LocalBusAddress(7)='0' else '0';

  BusProcess : process ( BusClk, Reset, RstSoftS, RstSoftH )
    variable id : ChanID;
  begin
    if ( Reset = '1' or RstSoftH='1') then
      fullrange <= x"0320";
      thres <= (others=>x"0000");
      ss_bus <= Initialize;
    elsif (RstSoftS='1') then
      ss_bus <= Initialize;
    elsif ( BusClk'event and BusClk='1' ) then
      id := CONV_INTEGER(LocalBusAddress(27 downto 24));
      case ss_bus is
        when Initialize =>
          TmpDataOut <= x"00000000";
          TmpBusRDY <= '0';
          ss_bus <= Idle;

        when Idle =>
          if (LocalBusWS='1' or LocalBusRS='1') then
            ss_bus <= SetBus;
          end if;

        when SetBus =>
          if (LocalBusAddress(7)='1' and LocalBusAddress(15)='0' and LocalBusAddress(31)='0') then
            if (LocalBusWS='1') then
              if ( LocalBusAddress(7 downto 2) = EBM_Range(7 downto 2) ) then
                fullrange <= LocalBusDataIn(15 downto 0);
              elsif ( LocalBusAddress(7 downto 2) = EBM_Thres(7 downto 2) ) then
                thres(id) <= LocalBusDataIn(15 downto 0);
              elsif ( LocalBusAddress(7 downto 2) = EBM_CmpType(7 downto 2) ) then
                cmptype(3 downto 0) <= LocalBusDataIn( 3 downto 0);
                cmptype(8 downto 5) <= LocalBusDataIn( 6 downto 5);
--                cmptype(8 downto 5) <= LocalBusDataIn(11 downto 8);
              elsif ( LocalBusAddress(7 downto 2) = EBM_ExcessP(7 downto 2) ) then
                excessp(7 downto 0) <= LocalBusDataIn( 7 downto 0);
              elsif ( LocalBusAddress(7 downto 2) = EBM_ExcessD(7 downto 2) ) then
                excessd(7 downto 0) <= LocalBusDataIn( 7 downto 0);
              end if;
            else
              if (LocalBusAddress(7 downto 2) = EBM_Range(7 downto 2)) then
                TmpDataOut(15 downto 0) <= fullrange;
              elsif (LocalBusAddress(7 downto 2) = EBM_Thres(7 downto 2)) then
                TmpDataOut(15 downto 0) <= thres(id);
              elsif (LocalBusAddress(7 downto 2) = EBM_CmpType(7 downto 2)) then
                TmpDataOut(6 downto 0) <= cmptype(8 downto 0);
--                TmpDataOut(12 downto 8) <= cmptype(9 downto 5);
              elsif (LocalBusAddress(7 downto 2) = EBM_ExcessP(7 downto 2)) then
                TmpDataOut(7 downto 0) <= excessp(7 downto 0);
              elsif (LocalBusAddress(7 downto 2) = EBM_ExcessD(7 downto 2)) then
                TmpDataOut(7 downto 0) <= excessd(7 downto 0);
              end if;
            end if;
            ss_bus <= Done;
          else
            if (LocalBusWS='1') then
              ss_bus <= write;
            else
              ss_bus <= read;
            end if;
          end if;

        when write =>
          BusWS(CurBuf) <= '1';
          ss_bus <= RdyWait;

        when read =>
          BusRS(CurBuf) <= '1';
          ss_bus <= RdyWait;

        when RdyWait =>
          if (BusRDY(CurBuf)='1') then
            BusWS(CurBuf) <= '0'; BusRS(CurBuf) <= '0';
            TmpDataOut <= BusDataOut(CurBuf);
            ss_bus <= Done;
          end if;

        when Done =>
          TmpBusRDY <= '1';
          if ( LocalBusWS='0' and LocalBusRS='0' ) then
            ss_bus <= Initialize;
          end if;
          
      end case;
    end if;
  end process BusProcess;

end EventBuffer;
