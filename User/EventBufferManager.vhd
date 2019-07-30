library ieee,work;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use work.AddressMap.all;
use work.BusSignalTypes.all;
use work.AddressBook.all;

entity EventBufferManager is
  port(
    Clock : in std_logic; -- 40MHz
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
    excessp : in std_logic_vector(7 donwto 0);
    excessd : in std_logic_vector(7 donwto 0);
    LocalBusAddress : in std_logic_vector(31 downto 0);
    LocalBusDataIn : in std_logic_vector(31 downto 0);
    LocalBusdataout : out std_logic_vector(31 downto 0);
    LocalBusRS : in std_logic;
    LocalBusWS : in std_logic;
    LocalBusRDY : out std_logic
  );
end EventBufferManager;

architecture EventBufferManager of EventBufferManager is

  -- Component Declaration ---------------------------------------------------
  component ChBufManPeakMark
  generic( ChID : std_logic_vector(3 downto 0) );
  port(
    Clock : in std_logic;
    Reset : in std_logic;
    RstSoft : in std_logic;
    datainB : in std_logic_vector(13 downto 0);
    dataout : out std_logic_vector(31 downto 0);
    address : out std_logic_vector(9 downto 0);
    datasize : out std_logic_vector(10 downto 0);
    threshold : in std_logic_vector(15 downto 0);
    fullrange : in std_logic_vector(15 downto 0);
    cmptype : in std_logic_vector(8 downto 0);
    excessp : in std_logic_vector(7 downto 0);
    excessd : in std_logic_vector(7 downto 0);
    wren : out std_logic;
    byteena : out std_logic_vector(3 downto 0);
    start : in std_logic;
    req : in std_logic;
    ack : out std_logic
  );
  end component;
  component ChBuf port (
    wrclock : in std_logic;
    rdclock : in std_logic;
    data : in std_logic_vector(31 downto 0);
    wraddress : in std_logic_vector(7 downto 0);
    wren : in std_logic;
    byteena_a : in std_logic_vector(3 DOWNTO 0) :=  (OTHERS => '1');
    q : out std_logic_vector(31 downto 0);
    rdaddress : in std_logic_vector(7 downto 0)
  );
  end component;
  component mux32_16
  PORT
  (
    data0x,  data1x,  data2x,  data3x   : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
    data4x,  data5x,  data6x,  data7x   : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
    data8x,  data9x,  data10x, data11x  : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
    data12x, data13x, data14x, data15x  : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
    sel    : IN STD_LOGIC_VECTOR (3 DOWNTO 0);
    result    : OUT STD_LOGIC_VECTOR (31 DOWNTO 0)
  );
  end component;

  signal wren : std_logic_vector(15 downto 0);
  signal free : std_logic_vector(15 downto 0);
  signal req : std_logic;
  signal ack : std_logic_vector(15 downto 0);
  signal ackreg : std_logic_vector(15 downto 0);
  
  signal wrpointer: ChArray10;
  signal datasize: ChArray11;
  signal datasize_pad: ChArray11;
  signal totsize: std_logic_vector(15 downto 0);
  signal temp00, temp01, temp02, temp03, temp04, temp05, temp06, temp07: std_logic_vector(15 downto 0);
  signal temp10, temp11, temp12, temp13: std_logic_vector(15 downto 0);
  signal temp20, temp21: std_logic_vector(15 downto 0);
  signal selID, curID: std_logic_vector(3 downto 0);
--  signal rdpointer: std_logic_vector(9 downto 0);
  signal rdpointer: ChArray8;
  signal fifocount: ChArray11;
  signal MemOut: ChArray32;
  signal MemIn : ChArray32;
  signal byteena : ChArray4;
--  signal ss_status : std_logic_vector(31 downto 0);

  signal flush : std_logic := '0';
  signal count_reset : std_logic := '0';
  
  -- Bus
  signal OutputData: std_logic_vector(31 downto 0);
  signal LatchedData: std_logic_vector(31 downto 0);

  -- ROC/LTG I/O --
  signal donereg : std_logic;
  signal startreg : std_logic;
  signal freereg : std_logic;
  
  -- Register --
  signal status : std_logic_vector(3 downto 0):=x"0";
  signal count : std_logic_vector(31 downto 0) := (others=>'0');
  
  type ss_type is (ss_ini, ss_free, ss_count, ss_record, ss_ready, ss_wait,
    ss_padding, ss_calctot0, ss_calctot1, ss_calctot2, ss_calctot3);
  signal ss : ss_type;
  
  type BusProcType is ( Initialize, Idle, Write, Read, FRead, Done );
  signal ss_bus : BusProcType;

begin

  BufferFree <= '1' when ss=ss_free else '0';
  ReadReady <= '1' when ss=ss_ready else '0';

  ChBufGen0: for i in 0 to 15 generate
    CM0: ChBufManPeakMark
    generic map (ChID => Conv_std_logic_vector(i,4))
    port map (
      Clock => Clock,
      Reset => Reset,
      RstSoft => (RstSoftS or RstSoftH),
      datainB => DataIn((i)*14+13 downto (i)*14),
      dataout => MemIn(i),
      address => wrpointer(i),
      datasize => datasize(i),
      fullrange => FullRange,
      threshold => Thres(i),
      cmptype => CmpType(8 downto 0),
      excessp => excessp,
      excessd => excessd,
      wren => wren(i),
      byteena => byteena(i),
      start => BufferStart,
      req => req,
      ack => ack(i)
    );
    CB0: ChBuf port map (
      wrclock => Clock,
      rdclock => BusClk,
      data => MemIn(i),
      wraddress => wrpointer(i)(7 downto 0),
      wren => wren(i),
      byteena_a => byteena(i),
      q => MemOut(i),
--      rdaddress => LocalBusAddress(9 downto 2)
      rdaddress => rdpointer(i)(7 downto 0)
    );
  end generate ChBufGen0;

  -- Sync Process ------------------------------------------------------------
  Sync : process (BusClk)
  begin
    if ( BusClk'event and BusClk = '1' ) then
      startreg <= BufferStart;
--      donereg  <= ReadDone; -- already latched by 80MHz
      ackreg <= ack;
    end if;
  end process Sync;
  donereg <= ReadDone;

  ReadWrite : process ( BusClk, Reset, count_reset, RstSoftS, RstSoftH )
    variable id : ChanID;
    variable cid : ChanID;
  begin
    if( Reset='1' or RstSoftH='1') then
      count<=(others=>'0');
      ss <= ss_ini;
    elsif ( count_reset = '1' ) then
      count <= (others=>'0');
    elsif ( RstSoftS = '1' ) then
      ss <= ss_ini;
    elsif ( BusClk'event and BusClk = '1' ) then
      id := CONV_INTEGER(LocalBusAddress(27 downto 24));
      cid := CONV_INTEGER(curID);
      case ss is
        when ss_ini =>
          ss <= ss_free;
          fifocount <= (others => "00000000000");
          curID <= "0000";
        when ss_free =>
          if ( startreg='1' ) then
            req <= '1';
            ss <= ss_count;
          end if;
        when ss_count =>
          count <= count + 1;
          ss <= ss_record;
        when ss_record =>
          if (ackreg=x"FFFF") then
            req <= '0';
            ss<=ss_padding;
          end if;
-- padding datasize --
        when ss_padding =>
          if (datasize( 0)(0)='1') then datasize_pad(0) <= datasize(0) + 1; else
                                        datasize_pad(0) <= datasize(0); end if;
          if (datasize( 1)(0)='1') then datasize_pad(1) <= datasize(1) + 1; else
                                        datasize_pad(1) <= datasize(1); end if;
          if (datasize( 2)(0)='1') then datasize_pad(2) <= datasize(2) + 1; else
                                        datasize_pad(2) <= datasize(2); end if;
          if (datasize( 3)(0)='1') then datasize_pad(3) <= datasize(3) + 1; else
                                        datasize_pad(3) <= datasize(3); end if;
          if (datasize( 4)(0)='1') then datasize_pad(4) <= datasize(4) + 1; else
                                        datasize_pad(4) <= datasize(4); end if;
          if (datasize( 5)(0)='1') then datasize_pad(5) <= datasize(5) + 1; else
                                        datasize_pad(5) <= datasize(5); end if;
          if (datasize( 6)(0)='1') then datasize_pad(6) <= datasize(6) + 1; else
                                        datasize_pad(6) <= datasize(6); end if;
          if (datasize( 7)(0)='1') then datasize_pad(7) <= datasize(7) + 1; else
                                        datasize_pad(7) <= datasize(7); end if;
          if (datasize( 8)(0)='1') then datasize_pad(8) <= datasize(8) + 1; else
                                        datasize_pad(8) <= datasize(8); end if;
          if (datasize( 9)(0)='1') then datasize_pad(9) <= datasize(9) + 1; else
                                        datasize_pad(9) <= datasize(9); end if;
          if (datasize(10)(0)='1') then datasize_pad(10) <= datasize(10) + 1; else
                                        datasize_pad(10) <= datasize(10); end if;
          if (datasize(11)(0)='1') then datasize_pad(11) <= datasize(11) + 1; else
                                        datasize_pad(11) <= datasize(11); end if;
          if (datasize(12)(0)='1') then datasize_pad(12) <= datasize(12) + 1; else
                                        datasize_pad(12) <= datasize(12); end if;
          if (datasize(13)(0)='1') then datasize_pad(13) <= datasize(13) + 1; else
                                        datasize_pad(13) <= datasize(13); end if;
          if (datasize(14)(0)='1') then datasize_pad(14) <= datasize(14) + 1; else
                                        datasize_pad(14) <= datasize(14); end if;
          if (datasize(15)(0)='1') then datasize_pad(15) <= datasize(15) + 1; else
                                        datasize_pad(15) <= datasize(15); end if;
          ss <= ss_calctot0;
-- calc totsize --
        when ss_calctot0 =>
          temp00 <= ("00000" & datasize_pad( 0)) + ("00000" & datasize_pad( 1));
          temp01 <= ("00000" & datasize_pad( 2)) + ("00000" & datasize_pad( 3));
          temp02 <= ("00000" & datasize_pad( 4)) + ("00000" & datasize_pad( 5));
          temp03 <= ("00000" & datasize_pad( 6)) + ("00000" & datasize_pad( 7));
          temp04 <= ("00000" & datasize_pad( 8)) + ("00000" & datasize_pad( 9));
          temp05 <= ("00000" & datasize_pad(10)) + ("00000" & datasize_pad(11));
          temp06 <= ("00000" & datasize_pad(12)) + ("00000" & datasize_pad(13));
          temp07 <= ("00000" & datasize_pad(14)) + ("00000" & datasize_pad(15));
          ss <= ss_calctot1;
        when ss_calctot1 =>
          temp10 <= temp00 + temp01;
          temp11 <= temp02 + temp03;
          temp12 <= temp04 + temp05;
          temp13 <= temp06 + temp07;
          ss <= ss_calctot2;
        when ss_calctot2 =>
          temp20 <= temp10 + temp11;
          temp21 <= temp12 + temp13;
          ss <= ss_calctot3;
        when ss_calctot3 =>
          totsize <= temp20 + temp21;
          ss <= ss_ready;
        when ss_ready =>
          if (donereg='1') then
--            ss <= ss_wait;
            ss <= ss_ini;
          end if;
--
          if (flush='1') then
            ss <= ss_ini;
          end if;

-- check ch end!! fifocount <= 0, curid++
-- cirID++=0 goto ss_ini
          if (ss_bus=FRead) then
            if (fifocount(cid)(8 downto 0)=datasize_pad(cid)(9 downto 1)-1) then
              if (curID="1111") then
                ss <= ss_ini;
              else
                curID <= curID + 1;
                fifocount(cid) <= (others => '0');
              end if;
            else
              fifocount(cid) <= fifocount(cid) + 1;
            end if;
          end if;
        when ss_wait =>
--          ReadReady <= '0';
          if (donereg='0') then
            ss <= ss_ini;
          end if;
        when others =>
          ss<=ss_ini;
      end case;
    end if;
  end process ReadWrite;  
  ------------------------------------------------------- ReadWrite Process --
--  process ( BusClk )
--  begin
--    if ( BusClk'event and BusClk = '1' ) then
--      case ss is
--        when ss_free =>   ss_status <= ackreg & x"0000";
--        when ss_record => ss_status <= ackreg & x"0001";
--        when ss_ready =>  ss_status <= ackreg & x"0002";
--        when ss_wait =>   ss_status <= ackreg & x"0003";
--        when others =>    ss_status <= ackreg & x"0000";
--      end case;
--    end if;
--  end process;
                              
  -- Bus Process -------------------------------------------------------------
  OutMux : mux32_16 port map (
    data0x  => MemOut(0),    data1x  => MemOut(1),    data2x  => MemOut(2),    data3x  => MemOut(3),
    data4x  => MemOut(4),    data5x  => MemOut(5),    data6x  => MemOut(6),    data7x  => MemOut(7),
    data8x  => MemOut(8),    data9x  => MemOut(9),    data10x => MemOut(10),   data11x => MemOut(11),
    data12x => MemOut(12),   data13x => MemOut(13),   data14x => MemOut(14),   data15x => MemOut(15),
--    sel => LocalBusAddress(27 downto 24),  -- should be changed to curID
    sel => selID,
    result => OutputData
  );

  PtrGen: for i in 0 to 15 generate
    rdpointer(i) <= LocalBusAddress(9 downto 2) when LocalBusAddress(31)='0' else fifocount(i)(7 downto 0);
  end generate PtrGen;
  selID <= LocalBusAddress(27 downto 24) when LocalBusAddress(31)='0' else curID;

  BusProcess : process ( BusClk, Reset, RstSoftS, RstSoftH )
  variable id : ChanID;
  begin
    if ( Reset = '1' or RstSoftS='1' or RstSoftH='1') then
      ss_bus <= Initialize;
    elsif ( BusClk'event and BusClk='1' ) then
      id := CONV_INTEGER(LocalBusAddress(27 downto 24));
      case ss_bus is
        when Initialize =>
          LocalBusDataOut <= x"00000000";
          LocalBusRDY <= '0';
          flush <= '0';
          count_reset <= '0';
          ss_bus <= Idle;

        when Idle =>
          if ( LocalBusWS = '1' ) then
            ss_bus <= Write;
          elsif ( LocalBusRS = '1' ) then
            if (LocalBusAddress(31)='1') then
              ss_bus <= FRead;
            else
              ss_bus <= Read;
            end if;
          end if;
        
        when Write =>
          if ( LocalBusAddress(3 downto 2) = EBM_CntRst(3 downto 2) ) then
            count_reset <= '1';
          end if;
          ss_bus <= Done;
          
        when Read =>
          if ( LocalBusAddress(15) = '1' ) then
            LocalBusDataOut <= OutputData;
            ss_bus <= Done;
          else
            if (LocalBusAddress(3 downto 2) = EBM_Count(3 downto 2)) then
              LocalBusDataOut <= count;
              ss_bus <= Done;
            elsif (LocalBusAddress(3 downto 2) = EBM_DataSize(3 downto 2)) then
              LocalBusDataOut(10 downto 0) <= datasize(id);
              ss_bus <= Done;
            elsif (LocalBusAddress(3 downto 2) = EBM_TotSize(3 downto 2)) then
              LocalBusDataOut(15 downto 0) <= totsize;
              if (totsize=x"0080") then
                flush<= '1';
              end if;
              ss_bus <= Done;
--            elsif (LocalBusAddress(4 downto 2) = EBM_Status(4 downto 2)) then
--              LocalBusDataOut(31 downto 0) <= ss_status;
--              ss_bus <= Done;
            else
              ss_bus <= Done;
            end if;
          end if;

        when FRead =>
          LocalBusDataOut <= OutputData;
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

end EventBufferManager;
