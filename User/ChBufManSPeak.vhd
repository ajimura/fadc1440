library ieee,work;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use work.AddressMap.all;
use work.BusSignalTypes.all;
use work.AddressBook.all;

entity ChBufManSPeak is
  generic( ChID : std_logic_vector(3 downto 0) );
  port(
    Clock : in std_logic;
    Reset : in std_logic;
    RstSoft : in std_logic;
--    datain : in std_logic_vector(13 downto 0);
    datainH : in std_logic_vector(13 downto 0);
    dataout : out std_logic_vector(31 downto 0);
    address : out std_logic_vector(9 downto 0);
    datasize : out std_logic_vector(10 downto 0);
    fullrange : in std_logic_vector(15 downto 0);
    threshold : in std_logic_vector(15 downto 0);
    cmptype : in std_logic_vector(8 downto 0);
    excessp : in std_logic_vector(7 downto 0);
    excessd : in std_logic_vector(7 downto 0);
    wren : out std_logic;
    byteena : out std_logic_vector(3 downto 0);
    start : in std_logic;
    req : in std_logic;
    ack : out std_logic
);
end ChBufManSPeak;

-- cmptype
--  8: dip & sum8
--  7: dip & pre2/pos2 or pre3/port3
--  6: peak & sum8
--  5: peak & pre2/pos2 or pre3/port3
--  4: simple SUP
--  3: peak
--  2: dip
-- * 1: mark
-- * 0: zero

architecture ChBufManSPeak of ChBufManSPeak is

  -- Signal Declarations -----------------------------------------------------
  signal wrpointer : std_logic_vector(10 downto 0);
  signal outdata : std_logic_vector(15 downto 0);
  signal timestamp : std_logic_vector(15 downto 0);
  signal size4header : std_logic_vector(15 downto 0);
  -- "00": normal data
  -- "01": buffer start
  -- "10": time stamp
  -- "11": buffer end

  signal up,  dn,  eq  : std_logic;
  signal up0, dn0, eq0 : std_logic;

  signal preUDiff1, posUDiff1 : std_logic;
  signal preUDiff2, posUDiff2 : std_logic;

  signal preDDiff1, posDDiff1 : std_logic;
  signal preDDiff2, posDDiff2 : std_logic;

  signal keepP : std_logic_vector(2 downto 0) := "000";
  signal keepQ : std_logic_vector(2 downto 0) := "000";
  signal keepR : std_logic_vector(2 downto 0) := "000";
--  signal keepM : std_logic_vector(2 downto 0) := "000";
  signal keepD : std_logic_vector(2 downto 0) := "000";
  signal keepE : std_logic_vector(2 downto 0) := "000";
  signal keepF : std_logic_vector(2 downto 0) := "000";
--  signal keepZ : std_logic_vector(2 downto 0) := "000";
  signal keepS : std_logic_vector(2 downto 0) := "000";

  signal datainG : std_logic_vector(13 downto 0);
  signal datainF : std_logic_vector(13 downto 0);
  signal datainE : std_logic_vector(13 downto 0);
  signal datainD : std_logic_vector(13 downto 0);
  signal datainC : std_logic_vector(13 downto 0);
  signal datainB : std_logic_vector(13 downto 0);
  signal datainA : std_logic_vector(13 downto 0);
  signal datain0P, datain0M : std_logic_vector(13 downto 0);
  signal datain, datain0, datain1, datain2, datain3 : std_logic_vector(13 downto 0);

  signal Sum4_0 : std_logic_vector(15 downto 0);
  signal Sum4_1 : std_logic_vector(15 downto 0);
  signal Sum4_2 : std_logic_vector(15 downto 0);
  signal Sum4_3 : std_logic_vector(15 downto 0);
  signal Sum4_4 : std_logic_vector(15 downto 0);

  signal Sum8_0 : std_logic_vector(16 downto 0);
--  signal Sum8_1 : std_logic_vector(14 downto 0);
  signal Sum8_1M : std_logic_vector(13 downto 0);
  signal Sum8_1P : std_logic_vector(13 downto 0);
  signal Sum8_2M : std_logic_vector(13 downto 0);
  signal Sum8_2P : std_logic_vector(13 downto 0);
  signal Sum8_3 : std_logic_vector(13 downto 0);

  signal SPeak8 : std_logic_vector(2 downto 0) := "000";
  signal SDip8 : std_logic_vector(2 downto 0) :="000";

--  type ss_type is (ss_init, ss_idle, ss_header, ss_record, ss_header2, ss_header3, ss_wait);
  type ss_type is (ss_init, ss_header, ss_record, ss_header2, ss_header3, ss_wait);
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
      datainG <= datainH;
      datainF <= datainG;
      datainE <= datainF;
      datainD <= datainE;
      datainC <= datainD;
      datainB <= datainC;
      datainA <= datainB;
      datain  <= datainA;
      datain0 <= datain;
      datain0M <= datain - excessp;
      datain0P <= datain + excessd;
      datain1 <= datain0;
      datain2 <= datain1;
      datain3 <= datain2;

      Sum4_0 <= ("00" & datainE) + ("00" & datainF) + ("00" & datainG) + ("00" & datainH);
--      Sum4_1 <= Sum4_0;
--      Sum4_2 <= Sum4_1;
--      Sum4_3 <= Sum4_2;
--      Sum4_4 <= Sum4_3;
      Sum4_4 <= ("00" & datainA) + ("00" & datainB) + ("00" & datainC) + ("00" & datainD);

      Sum8_0 <= ("0" & Sum4_0(15 downto 0)) + ("0" & Sum4_4(15 downto 0));
--      Sum8_1 <= Sum8_0;
      Sum8_1M <= Sum8_0(16 downto 3) - (excessp);
      Sum8_1P <= Sum8_0(16 downto 3) + (excessd);
      Sum8_2M <= Sum8_1M;
      Sum8_2P <= Sum8_1P;
      Sum8_3 <= Sum8_2M + (excessp);
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

      if (datainB < datain0M) then posUDiff2 <= '1'; else posUDiff2 <= '0'; end if;
      if (datainA < datain0M) then posUDiff1 <= '1'; else posUDiff1 <= '0'; end if;
      if (datain2 < datain0M) then preUDiff1 <= '1'; else preUDiff1 <= '0'; end if;
      if (datain3 < datain0M) then preUDiff2 <= '1'; else preUDiff2 <= '0'; end if;

      if (datainB > datain0P) then posDDiff2 <= '1'; else posDDiff2 <= '0'; end if;
      if (datainA > datain0P) then posDDiff1 <= '1'; else posDDiff1 <= '0'; end if;
      if (datain2 > datain0P) then preDDiff1 <= '1'; else preDDiff1 <= '0'; end if;
      if (datain3 > datain0P) then preDDiff2 <= '1'; else preDDiff2 <= '0'; end if;

      if ((Sum8_0(16 downto 3)<Sum8_1M(13 downto 0)) and
          (Sum8_2M(13 downto 0)>Sum8_3(13 downto 0))) then
        SPeak8<="111";
      else
        if (SPeak8/="000") then
          SPeak8<=Speak8 - 1;
        end if;
--        SPeak8<='0';
      end if;
      if ((Sum8_0(16 downto 3)>Sum8_1P(13 downto 0)) and
          (Sum8_2P(13 downto 0)<Sum8_3(13 downto 0))) then
        SDip8<="111";
      else
        if (SDip8/="000") then
          SDip8<=SDip8-1;
        end if;
--        SDip8<='0';
      end if;
    end if;
  end process;

  -- check peak
  process (Clock)
  begin
    if (Clock'event and Clock='1') then
      if (datain2>threshold(13 downto 0)) then
        if ((up0='1' and dn='1') or (eq0='1' and dn='1') or (up0='1' and eq='1')) then
          if (cmptype(3)='1') then
            keepP <= "100";
          end if;
        else
          if (keepP > 0) then keepP <= keepP - 1; end if;
        end if;
      else
        if (keepP > 0) then keepP <= keepP - 1; end if;
      end if;
    end if;
  end process;

  -- check peak (&pre2/pos2)
  process (Clock)
  begin
    if (Clock'event and Clock='1') then
      if (datain2>threshold(13 downto 0)) then
        if ((up0='1' and dn='1') or (eq0='1' and dn='1') or (up0='1' and eq='1')) then
          if (preUDiff1='1' and posUDiff1='1') then
--          if (preUDiff1='1' and posUDiff1='1' and preUDiff2='1' and posUDiff2='1') then
            if (cmptype(5)='1') then
              keepQ <= "100";
            end if;
          else
            if (keepQ > 0) then keepQ <= keepQ - 1; end if;
          end if;
        else
          if (keepQ > 0) then keepQ <= keepQ - 1; end if;
        end if;
      else
        if (keepQ > 0) then keepQ <= keepQ - 1; end if;
      end if;
    end if;
  end process;

  -- check peak and smooth
  process (Clock)
  begin
    if (Clock'event and Clock='1') then
      if (datain2>threshold(13 downto 0) and SPeak8/="000") then
        if ((up0='1' and dn='1') or (eq0='1' and dn='1') or (up0='1' and eq='1')) then
          if (cmptype(6)='1') then
            keepR <= "100";
          end if;
        else
          if (keepR > 0) then keepR <= keepR - 1; end if;
        end if;
      else
        if (keepR > 0) then keepR <= keepR - 1; end if;
      end if;
    end if;
  end process;

  -- check dip
  process (Clock)
  begin
    if (Clock'event and Clock='1') then
      if (datain2>threshold(13 downto 0)) then
        if ((dn0='1' and up='1') or (dn0='1' and eq='1') or (eq0='1' and up='1')) then
          if (cmptype(2)='1') then
            keepD <= "100";
          end if;
        else
          if (keepD > 0) then keepD <= keepD - 1; end if;
        end if;
      else
        if (keepD > 0) then keepD <= keepD - 1; end if;
      end if;
    end if;
  end process;

  -- check dip (&pre2/pos2)
  process (Clock)
  begin
    if (Clock'event and Clock='1') then
      if (datain2>threshold(13 downto 0)) then
        if ((dn0='1' and up='1') or (dn0='1' and eq='1') or (eq0='1' and up='1')) then
          if (preDDiff1='1' and posDDiff1='1') then
--          if (preDDiff1='1' and posDDiff1='1' and preDDiff2='1' and posDDiff2='1') then
            if (cmptype(7)='1') then
              keepE <= "100";
            end if;
          else
            if (keepE > 0) then keepE <= keepE - 1; end if;
          end if;
        else
          if (keepE > 0) then keepE <= keepE - 1; end if;
        end if;
      else
        if (keepE > 0) then keepE <= keepE - 1; end if;
      end if;
    end if;
  end process;

  -- check dip and smooth
  process (Clock)
  begin
    if (Clock'event and Clock='1') then
      if (datain2>threshold(13 downto 0) and SDip8/="000") then
        if ((dn0='1' and up='1') or (dn0='1' and eq='1') or (eq0='1' and up='1')) then
          if (cmptype(8)='1') then
            keepF <= "100";
          end if;
        else
          if (keepF > 0) then keepF <= keepF - 1; end if;
        end if;
      else
        if (keepF > 0) then keepF <= keepF - 1; end if;
      end if;
    end if;
  end process;

  -- check sup
  process (Clock)
  begin
    if (Clock'event and Clock='1') then
      if ( datain0>threshold and cmptype(4)='1' ) then
        keepS <= "110";
      else
        if (keepS > 0) then keepS <= keepS - 1; end if;
      end if;
    end if;
  end process;

  -- Write Process
  process ( Clock, Reset, RstSoft )
  begin
    if( Reset='1' or RstSoft='1') then
      ack<='0';
      ss <= ss_init;
    elsif ( Clock'event and Clock = '1' ) then
      case ss is
        when ss_init =>
          if (start='1') then
            ss<=ss_header;
            wren <= '1';
            outdata <= x"40" & "000" & cmptype(4 downto 0);
          else
            timestamp <= (others=>'0');
            wrpointer <= "00000000100"; --(others=>'0');
            size4header <= (others => '0');
          end if;

        when ss_header =>
          wrpointer <= wrpointer + 1;
          timestamp <= timestamp + 1;
          size4header <= size4header + 1;
          wren <= '1';
          outdata <= "01" & threshold(13 downto 0);
          ss <= ss_record;

        when ss_record =>
          timestamp <= timestamp + 1;
--          if (wrpointer = "00111111110" or timestamp = fullrange) then
          if (wrpointer = "00111110010" or timestamp = fullrange) then
            wrpointer <= wrpointer + 1;
            size4header <= size4header + 1;
            wren <= '1';
--            outdata <= "11" & "000" & wrpointer;
            outdata <= "11" & timestamp(13 downto 0);
            ss <= ss_header2;
          else
            if (keepP(2 downto 1)/="00" or
                keepQ(2 downto 1)/="00" or
                keepR(2 downto 1)/="00" or
                keepD(2 downto 1)/="00" or
                keepE(2 downto 1)/="00" or
                keepF(2 downto 1)/="00" or
                keepS(2 downto 1)/="00") then         -- put data
              wren <= '1';
              wrpointer <= wrpointer + 1;
              size4header <= size4header + 1;
              outdata <= "00" & datain3;
            elsif (keepP(0)='1' or
                   keepQ(0)='1' or
                   keepR(0)='1' or
                   keepD(0)='1' or
                   keepE(0)='1' or
                   keepF(0)='1' or
                   keepS(0)='1') then      -- put timestamp
              wren <= '1';
              wrpointer <= wrpointer + 1;
              size4header <= size4header + 1;
              outdata <= "10" & timestamp(13 downto 0);
            else
              wren <= '0';
            end if;
          end if;

        when ss_header2 =>
          datasize <= wrpointer+1;
          size4header <= size4header + 1;
          wrpointer <= "00000000001";
          outdata <= "000000000000" & ChID;
          wren<='1';
          ss <= ss_header3;

        when ss_header3 =>
          wrpointer <= "00000000000";
          outdata <= size4header;
          wren <= '1';
          ss <= ss_wait;

        when ss_wait =>
          wren <= '0';
          if (req='0') then
            ack <= '0';
            ss <= ss_init;
          else
--            datasize <= wrpointer+1;
            ack <= '1';
          end if;
      end case;        
    end if;
  end process;

end ChBufManSPeak;
