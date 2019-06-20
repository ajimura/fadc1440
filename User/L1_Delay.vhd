library ieee,work;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use work.AddressMap.all;
use work.BusSignalTypes.all;
use work.AddressBook.all;

entity L1_Delay is
  port(
    Clock : in std_logic;
    BusClk : in std_logic;
    Reset : in std_logic;
    RstSoftS : in std_logic;
    RstSoftH : in std_logic;
    DataIn: in std_logic_vector(223 downto 0);
    DelayOut: out std_logic_vector(223 downto 0);
    LocalBusAddress : in std_logic_vector(31 downto 0);
    LocalBusDataIn : in std_logic_vector(31 downto 0);
    LocalBusDataOut : out std_logic_vector(31 downto 0);
    LocalBusRS : in std_logic;
    LocalBusWS : in std_logic;
    LocalBusRDY : out std_logic
  );
end L1_delay;

architecture L1_delay of L1_delay is

  -- Component Declaration ---------------------------------------------------
  component l1_buffer
    port (
      wrclock    : IN STD_LOGIC ;
      rdclock : in std_logic;
      data    : IN STD_LOGIC_VECTOR (111 DOWNTO 0);
      rdaddress    : IN STD_LOGIC_VECTOR (7 DOWNTO 0);
      wraddress    : IN STD_LOGIC_VECTOR (7 DOWNTO 0);
      wren    : IN STD_LOGIC  := '1';
      q    : OUT STD_LOGIC_VECTOR (111 DOWNTO 0)
    );
  end component;
  component mux14_16
    PORT (
      data0x    : IN STD_LOGIC_VECTOR (13 DOWNTO 0);
      data10x    : IN STD_LOGIC_VECTOR (13 DOWNTO 0);
      data11x    : IN STD_LOGIC_VECTOR (13 DOWNTO 0);
      data12x    : IN STD_LOGIC_VECTOR (13 DOWNTO 0);
      data13x    : IN STD_LOGIC_VECTOR (13 DOWNTO 0);
      data14x    : IN STD_LOGIC_VECTOR (13 DOWNTO 0);
      data15x    : IN STD_LOGIC_VECTOR (13 DOWNTO 0);
      data1x    : IN STD_LOGIC_VECTOR (13 DOWNTO 0);
      data2x    : IN STD_LOGIC_VECTOR (13 DOWNTO 0);
      data3x    : IN STD_LOGIC_VECTOR (13 DOWNTO 0);
      data4x    : IN STD_LOGIC_VECTOR (13 DOWNTO 0);
      data5x    : IN STD_LOGIC_VECTOR (13 DOWNTO 0);
      data6x    : IN STD_LOGIC_VECTOR (13 DOWNTO 0);
      data7x    : IN STD_LOGIC_VECTOR (13 DOWNTO 0);
      data8x    : IN STD_LOGIC_VECTOR (13 DOWNTO 0);
      data9x    : IN STD_LOGIC_VECTOR (13 DOWNTO 0);
      sel    : IN STD_LOGIC_VECTOR (3 DOWNTO 0);
      result    : OUT STD_LOGIC_VECTOR (13 DOWNTO 0)
    );
  end component;

  --------------------------------------------------- Component Declaration --

  -- Signal Declarations -----------------------------------------------------
  signal rd_pointer : std_logic_vector(7 downto 0) := "11000000";
  signal wr_pointer : std_logic_vector(7 downto 0) := "00010000";
  signal wr_pointerA : std_logic_vector(7 downto 0) := "00010000";
  signal wr_pointerB : std_logic_vector(7 downto 0) := "00010000";
  signal lv1_datain : std_logic_vector(223 downto 0);
  signal lv1_dataout : std_logic_vector(223 downto 0);
  signal Prompt : std_logic_vector(223 downto 0);
--  signal Delay : std_logic_vector(7 downto 0) := "11111100"; --fc
  signal Delay : std_logic_vector(7 downto 0) := "10110000"; --b0
  signal PromptCh, DelayCh : std_logic_vector(13 downto 0);
  signal ss_bus : BusProcessTypeL1;
  ----------------------------------------------------- Signal Declarations --

begin

  -- Instantiation -----------------------------------------------------------
  L1A_Buffer: l1_buffer
    port map(
      wrclock => Clock,
      rdclock => Clock,
      data => DataIn(111 downto 0),
      rdaddress => rd_pointer,
      wraddress => wr_pointer,
      wren => '1',
      q => lv1_dataout(111 downto 0)
    );
  L1B_Buffer: l1_buffer
    port map(
      wrclock => Clock,
      rdclock => Clock,
      data => DataIn(223 downto 112),
      rdaddress => rd_pointer,
      wraddress => wr_pointer,
      wren => '1',
      q => lv1_dataout(223 downto 112)
    );
  DelayMux: mux14_16
    port map(
      data0x => lv1_dataout( 13 downto   0),
      data1x => lv1_dataout( 27 downto  14),
      data2x => lv1_dataout( 41 downto  28),
      data3x => lv1_dataout( 55 downto  42),
      data4x => lv1_dataout( 69 downto  56),
      data5x => lv1_dataout( 83 downto  70),
      data6x => lv1_dataout( 97 downto  84),
      data7x => lv1_dataout(111 downto  98),
      data8x => lv1_dataout(125 downto 112),
      data9x => lv1_dataout(139 downto 126),
      data10x => lv1_dataout(153 downto 140),
      data11x => lv1_dataout(167 downto 154),
      data12x => lv1_dataout(181 downto 168),
      data13x => lv1_dataout(195 downto 182),
      data14x => lv1_dataout(209 downto 196),
      data15x => lv1_dataout(223 downto 210),
      sel => LocalBusAddress(27 downto 24),
      result => DelayCh
    );
  ----------------------------------------------------------- Instantiation --
  
  DelayOut <= lv1_dataout;

  Buffering : process (Clock, Reset, RstSoftS, RstSoftH)
  begin
    if (Reset='1' or RstSoftH='1' or RstSoftS='1') then
      wr_pointer <=  "00010000";
      wr_pointerA <= "00010000";
      wr_pointerB <= "00010000";
      rd_pointer <=  "11000000";
    else
      if (Clock'event and Clock='1') then
        wr_pointerA <= wr_pointerA + 1;
      end if;
      if (Clock'event and Clock='1') then
        wr_pointerB <= wr_pointerB + 1;
      end if;
      if (Clock'event and Clock = '1') then
        wr_pointer <= wr_pointer + 1;
        rd_pointer <= wr_pointer + Delay;
      end if;
    end if;
  end process Buffering;  

  -- Bus Process -------------------------------------------------------------
  BusProcess : process ( BusClk, Reset, RstSoftS, RstSoftH )
  variable id : BuffID;
  begin
    if ( Reset = '1' or RstSoftH='1') then
      Delay <= "10110000";
      ss_bus <= Initialize;
    elsif (RstSoftS='1') then
      ss_bus <= Initialize;
    elsif ( BusClk'event and BusClk='1' ) then
      id := CONV_INTEGER(LocalBusAddress(27 downto 24));
      case ss_bus is
        when Initialize =>
          LocalBusDataOut <= x"00000000";
          LocalBusRDY <= '0';
          ss_bus <= Idle;

        when Idle =>
          if ( LocalBusWS = '1' or LocalBusRS = '1' ) then
            ss_bus <= Wait1;
          end if;
          
        when Wait1 =>
          ss_bus <= Wait2;
          
        when Wait2 =>
          if (LocalBusWS = '1' ) then
            ss_bus <= Write;
          elsif ( LocalBusRS = '1' ) then
            ss_bus <= Read;
          end if;
        
        when Write =>
          if (LocalBusAddress(2) = L1D_Delay(2)) then
            if (LocalBusDataIn(7 downto 2) = "111111") then
              Delay <= "11111100";
            elsif (LocalBusDataIn(7 downto 2) = "000000") then
              Delay <= "00000011";
            else
              Delay <= LocalBusDataIn(7 downto 0);
            end if;
          end if;
          ss_bus <= Done;

        when Read =>
          if (LocalBusAddress(2) = L1D_Delay(2)) then
            LocalBusDataOut(7 downto 0) <= Delay;
          elsif (LocalBusAddress(2) = L1D_Delayed(2)) then
            LocalBusDataOut(13 downto 0) <= DelayCh;
          end if;
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

end L1_delay;
