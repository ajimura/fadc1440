library ieee,work;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use work.AddressMap.all;
use work.BusSignalTypes.all;
use work.AddressBook.all;

entity TriggerController is
  port(
    Clock : in std_logic;
    BusClk : in std_logic;
    CntClk : in std_logic;
    ResetIn : in std_logic;
    ResetTGC : out std_logic;
    RstBCTS : in std_logic;
    RstBCTH : in std_logic;
    BufferFree : in std_logic_vector(NumEvtBuffer-1 downto 0);
    BufferStart : out std_logic_vector(NumEvtBuffer-1 downto 0) := (others => '0');
    ReadReady : in std_logic_vector(NumEvtBuffer-1 downto 0);
    ToLED : out std_logic;
    TrigIn : in std_logic_vector(3 downto 0);
    TrigOut : out std_logic_vector(1 downto 0);
    LocalTrigger : in std_logic;
    LocalBusAddress : in std_logic_vector(31 downto 0);
    LocalBusDataIn : in std_logic_vector(31 downto 0);
    LocalBusDataOut : out std_logic_vector(31 downto 0);
    LocalBusRS : in std_logic;
    LocalBusWS : in std_logic;
    LocalBusRDY : out std_logic
  );
end TriggerController;

architecture TriggerController of TriggerController is

  component ClkCnt PORT (
    aclr: in std_logic;
    clock: in std_logic;
    q: out std_logic_vector(31 downto 0)
  );
  end component;

  -- Signal Declarations -----------------------------------------------------
  signal trigger, trigreg : std_logic;
--  signal synced_trig : std_logic := '0';
  signal latched, latched_prev, latched_curr : std_logic_vector(1 downto 0);
  signal LatchedClk: std_logic_vector(47 downto 0);
  signal clktrig :  std_logic;
  signal busyout : std_logic := '0';
  signal ClkCounter : std_logic_vector(31 downto 0);  --(47 downto 0);
  signal Reset, ResetL : std_logic;
  signal Start : std_logic_vector(NumEvtBuffer-1 downto 0) := (others=>'0');

  signal bufferid : BuffID;
  signal freereg : std_logic_vector(NumEvtBuffer-1 downto 0);
--  signal BufEnab : std_logic_vector(NumEvtBuffer-1 downto 0):=(others=>'1');
--  signal ClkTrigHZ : std_logic_vector(31 downto 0) := x"001E8480"; -- 20Hz(25 x 2 million)
  signal ClkTrigHZ : std_logic_vector(31 downto 0) := x"02625A00"; -- 1Hz(25 x 40 million)
  signal ClkTrigCnt : std_logic_vector(31 downto 0) := x"00000000";
  signal Count : std_logic_vector(31 downto 0) := x"00000000";
  type counttype is array (NumEvtBuffer-1 downto 0) of std_logic_vector(31 downto 0);
  signal CountEach : counttype := (others => x"00000000");
  type timetype is array (NumEvtBuffer-1 downto 0) of std_logic_vector(47 downto 0);
  signal TimeStamp : timetype;
  type tidtype is array (NumEvtBuffer-1 downto 0) of std_logic_vector(31 downto 0);
  signal TrigID : tidtype;
  signal TrigEnab : std_logic_vector(3 downto 0) := "0000";
  signal TrigInOut : std_logic_vector(7 downto 0) := "00001100";
  signal CntRst : std_logic := '0';
  signal TrigInReg : std_logic_vector(3 downto 0);
  signal TrigOutReg : std_logic_vector(1 downto 0);
  signal TrigOutPre : std_logic_vector(1 downto 0);
  signal TrigInLatched : std_logic_vector(3 downto 0);

  type ss_type is ( ss_init, ss_idle, ss_wait, ss_free, ss_start, ss_done);
--  type ss_type is ( ss_init, ss_wait, ss_free, ss_start, ss_done);
  signal ss : ss_type;
  signal ss_bus : BusProcessType;
  
  type ss_tr is (ss_out, ss_on, ss_off);
  signal trig_ss : ss_tr := ss_out;

  constant AllZero : std_logic_vector(NumEvtBuffer-1 downto 0) := (others=>'0');
  ----------------------------------------------------- Signal Declarations --
  
begin

-- Ext Trigger
  TrigInReg(0) <= not(TrigIn(0)) and TrigInOut(4);
-- Ext Reset
  TrigInReg(1) <= not(TrigIn(1)) and TrigInOut(5);
-- local trigger from DownStream -> NoEmpty -> to be and'ed
  TrigInReg(2) <= not(TrigIn(2)) when TrigInOut(6)='1' else '1';
-- busy from DownStream
  TrigInReg(3) <= not(TrigIn(3)) when TrigInOut(7)='1' else '0';

-- Local Trigger Out
--  TrigOutReg(0) <= LocalTrigger;
-- Buffer Free
--  TrigOutReg(0) <= '0' when ReadReady="0000" else '1';
  TrigOutReg(0) <= '0' when ReadReady=AllZero else '1';

-- Local Busy Out -- when Trig diabled, always busy
  TrigOutReg(1) <= '1' when TrigEnab(2 downto 0)="000" else busyout;

-- Trig I/O (out)
  TrigOutPre(0) <= (TrigOutReg(0) and TrigInReg(2)) and TrigInOut(2);  --local trigger
  TrigOutPre(1) <= (TrigOutReg(1) or TrigInReg(3)) and TrigInOut(3);  --busy
  TrigOut(0) <= not(TrigOutPre(0));  --local trigger
  TrigOut(1) <= not(TrigOutPre(1));  --busy

-- Trigger selection
--  trigger <= (LocalTrigger and TrigEnab(0)) or
--             (clktrig and TrigEnab(1)) or
--             (TrigInReg(0) and TrigEnab(2));
  trigger <= (clktrig and TrigEnab(1)) or
             (TrigInReg(0) and TrigEnab(2));

-- to LED
  ToLED <= TrigOutReg(0);

-- Local Reset
  ResetL <= (TrigInReg(1) and TrigEnab(3));
  ResetTGC <= ResetL;
  Reset <= ResetIn;
  
  BufferStart <= Start;
    
  -- Sync Process ------------------------------------------------------------
  process (Clock)
  begin
    if ( Clock'event and Clock = '1' ) then
      freereg <= BufferFree;
      trigreg <= trigger;
      TrigInLatched <= TrigIn;
    end if;
  end process Sync;
    
  process (CntClk)
  begin
    if (CntClk'event and CntClk='1') then
      latched <= latched_prev;
      latched_prev(0)<=trigger;
    elsif (CntClk'event and CntClk='0') then
      latched_prev(1)<=trigger;
    end if;
  end process;
  process (CntClk)
  begin
    if (CntClk'event and CntClk='1') then
      latched_curr <= latched;
      if (busyout='0') then
        if (latched_curr="00") then
          case latched is
            when "11" =>
--              TimeStamp(bufferid) <= ClkCounter(46 downto 0) & '0';
              TimeStamp(bufferid) <= x"0000" & ClkCounter(30 downto 0) & '0';
--              synced_trig <= '1';
            when "10" => -- for safety: latched must not be "10"
              TimeStamp(bufferid) <= x"0000" & ClkCounter(30 downto 0) & '1';
--              synced_trig <= '1';
            when "01" =>
              TimeStamp(bufferid) <= x"0000" & ClkCounter(30 downto 0) & '1';
--              synced_trig <= '1';
            when "00" => NULL;
--              synced_trig <= '0';
          end case;
        end if;
      end if;
    end if;
  end process;

  -- ClockCount and latch for time stamp
  ClockCounter : ClkCnt port map (
    aclr => Reset,
    clock => CntClk,
    q => ClkCounter
  );
  
  -- TriggerControl Process --------------------------------------------------
  TriggerControl : process ( Clock, Reset, CntRst, RstBCTS, RstBCTH )
  begin
    if ( Reset = '1' or RstBCTH='1') then
      ss <= ss_init;
      bufferid <= 0;
      Start <= (others => '0');
      Count <= x"00000000";
      CountEach <= (others => x"00000000");
      TrigID <= (others => x"00000000");
      busyout <= '0';
    elsif ( CntRst = '1' ) then
      ss <= ss_init;
      Count <= x"00000000";
      CountEach <= (others => x"00000000");
      TrigID <= (others => x"00000000");
    elsif ( RstBCTS='1' ) then
      ss <= ss_init;
    elsif ( Clock'event and Clock = '1' ) then
      case ss is
        when ss_init =>
--          if (BufEnab(bufferid)='0') then
--            if ( bufferid = NumEvtBuffer-1 ) then
--              bufferid <= 0;
--            else
--              bufferid <= bufferid + 1;
--            end if;
--          else
          ss <= ss_idle;
--          end if;
        when ss_idle =>
          if (freereg(bufferid)='1') then
            busyout <= '0';
            ss <= ss_free;
          else
            busyout <= '1';
            ss <= ss_wait;
          end if;
        when ss_wait =>
          if (freereg(bufferid)='1') then
            busyout <= '0';
            ss <= ss_free;
          end if;
        when ss_free =>
--          if (synced_trig='1') then
          if (trigreg='1') then
            Start(bufferid) <= '1';
            TrigID(bufferid) <= Count;
--            TimeStamp(bufferid) <= LClkCnt;
            Count <= Count + 1;
            CountEach(bufferid) <= CountEach(bufferid) + 1;
            ss <= ss_start;
          end if;
        when ss_start =>
          if (freereg(bufferid)='0') then
            ss <= ss_done;
          end if;
        when ss_done =>
          Start(bufferid) <= '0';
--          if (synced_trig='0') then
          if (trigreg='0') then
            if ( bufferid = NumEvtBuffer-1 ) then
              bufferid <= 0;
            else
              bufferid <= bufferid + 1;
            end if;
            ss <= ss_init; 
          end if;
      end case;
    end if;
  end process TriggerControl;

  -- Bus Process -------------------------------------------------------------
  BusProcess : process ( BusClk, Reset, RstBCTS, RstBCTH )
    variable id : BuffID;
  begin
    if ( Reset = '1' or RstBCTH='1') then
      ClkTrigHZ <= x"02625A00"; -- 1Hz(25 x 40 million)
      TrigInOut <= "00001100";
      TrigEnab <= "0000";
      ss_bus <= Initialize;
    elsif ( RstBCTS='1') then
      ss_bus <= Initialize;
    elsif ( BusClk'event and BusClk='1' ) then
      id := CONV_INTEGER(LocalBusAddress(22 downto 20));
      case ss_bus is
        when Initialize =>
          CntRst <= '0';
          LocalBusDataOut <= x"00000000";
          LocalBusRDY <= '0';
          ss_bus <= Idle;

        when Idle =>
          if ( LocalBusWS = '1' ) then
            ss_bus <= Write;
          elsif ( LocalBusRS = '1' ) then
            ss_bus <= Read;
          end if;
        
        when Write =>
--          if (LocalBusAddress(5)='0') then
--            if (LocalBusAddress(4 downto 2)=TGC_TrigEnab(4 downto 2)) then
--              TrigEnab <= LocalBusDataIn(3 downto 0);
--            elsif (LocalBusAddress(4 downto 2)=TGC_TrigInOut(4 downto 2)) then
--              TrigInOut <= LocalBusDataIn(7 downto 0);
--            elsif (LocalBusAddress(4 downto 2)=TGC_ClkTrig(4 downto 2)) then
--              ClkTrigHZ <= LocalBusDataIn;
--            end if;
--          else
--            if (LocalBusAddress(4 downto 2)=TGC_CntRst(4 downto 2)) then
--              CntRst <= '1';
--            end if;
--          end if;
          if LocalBusAddress(5 downto 2) = TGC_TrigInOut(5 downto 2) then
            TrigInOut <= LocalBusDataIn(7 downto 0);
          elsif LocalBusAddress(5 downto 2) = TGC_TrigEnab(5 downto 2) then
            TrigEnab <= LocalBusDataIn(3 downto 0);
--          elsif LocalBusAddress(5 downto 2) = TGC_BufEnab(5 downto 2) then
--            BufEnab <= LocalBusDataIn(NumEvtBuffer-1 downto 0);
          elsif LocalBusAddress(5 downto 2) = TGC_ClkTrig(5 downto 2) then
            ClkTrigHZ <= LocalBusDataIn;
          elsif LocalBusAddress(5 downto 2) = TGC_CntRst(5 downto 2) then
            CntRst <= '1';
          end if;
          ss_bus <= Done;

        when Read =>
          case LocalBusAddress(5 downto 2) is
            when TGC_FreeBuf(5 downto 2)    => LocalBusDataOut(NumEvtBuffer-1 downto 0) <= freereg;
            when TGC_NextBuf(5 downto 2)    => LocalBusDataOut(4 downto 0) <= CONV_std_logic_vector(bufferid,5);
            when TGC_Count(5 downto 2)      => LocalBusDataOut <= Count;
            when TGC_TrigInOut(5 downto 2)  => LocalBusDataOut(7 downto 0) <= TrigInOut;
            when TGC_TrigEnab(5 downto 2)   => LocalBusDataOut(3 downto 0) <= TrigEnab;
            when TGC_CountEach(5 downto 2)  => LocalBusDataOut <= CountEach(id);
            when TGC_BufEnab(5 downto 2)    => NULL; --LocalBusDataOut(NumEvtBuffer-1 downto 0) <= (others => '1'); --BufEnab;
            when TGC_ClkTrig(5 downto 2)    => LocalBusDataOut <= ClkTrigHZ;
            when TGC_CntRst(5 downto 2)     => NULL;  --LocalBusDataOut(0) <= '0'; --CntRst;
            when TGC_TrigID(5 downto 2)     => LocalBusDataOut <= TrigID(id);
            when TGC_FClk(5 downto 2)       => LocalBusDataOut <= TimeStamp(id)(31 downto 0);
--            when TGC_CClk(5 downto 2)       => LocalBusDataOut(15 downto 0) <= x"0000"; -- TimeStamp(id)(47 downto 32);
            when TGC_CClk(5 downto 2)       => NULL; --LocalBusDataOut(0) <= '0';
--            when TGC_IOstat(5 downto 2)     => LocalBusDataOut(19 downto 0) <=
--                                               TrigInLatched &
--                                               "000" & TrigOutPre(1) & -- Busy(OR'ed)
--                                               "000" & TrigOutReg(1) & -- Busy
--                                               "000" & TrigOutPre(0) & -- DataReady(And'd)
--                                               "000" & TrigOutReg(0);  -- DataReady
            when TGC_IOstat(5 downto 2)     => LocalBusDataOut(19 downto 16) <= TrigInLatched;
                                               LocalBusDataOut(12) <= TrigOutPre(1); -- Busy(OR'ed)
                                               LocalBusDataOut( 8) <= TrigOutReg(1); -- Busy
                                               LocalBusDataOut( 4) <= TrigOutPre(0); -- DataReady(And'd)
                                               LocalBusDataOut( 0) <= TrigOutReg(0); -- DataReady
            when TGC_NoEmpty(5 downto 2)    => LocalBusDataOut( 4) <= TrigOutPre(0);
                                               LocalBusDataOut( 0) <= TrigOutReg(0);
            when TGC_Busy(5 downto 2)       => LocalBusDataOut( 4) <= TrigOutPre(1);
                                               LocalBusDataOut( 0) <= TrigOutReg(1);
--            when TGC_In(5 downto 2)         => NULL; --LocalBusDataOut(3 downto 0) <= TrigInLatched;
            when others =>
              LocalBusDataOut <= x"FFFFFFFF";
          end case;
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

  process(Clock, Reset, RstBCTS, RstBCTH)
  begin
    if ( Reset = '1' or RstBCTS='1' or RstBCTH='1') then
      ClkTrigCnt<=x"00000000";
    elsif Clock'event and Clock='1' then
      ClkTrigCnt<=ClkTrigCnt+1;
      if (ClkTrigCnt(31 downto 1)=ClkTrigHz(31 downto 1)) then
        ClkTrigCnt<=x"00000000";
        ClkTrig <= '1';
      else
        ClkTrig <= '0';
      end if;
    end if;
  end process;

end TriggerController;

