library ieee,work;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use work.AddressMap.all;
use work.BusSignalTypes.all;
use work.AddressBook.all;

entity ChBufManPeakMark2 is
  generic( ChID : std_logic_vector(3 downto 0) );
  port(
    Clock : in std_logic;
    Reset : in std_logic;
    RstSoft : in std_logic;
--    datain : in std_logic_vector(13 downto 0);
    datainB : in std_logic_vector(13 downto 0);
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
end ChBufManPeakMark2;

-- cmptype
--  8: dip (& pre2/pos2 & pre3/port3)
--  7: dip (& pre2/pos2)
--  6: peak (& pre2/pos2 & pre3/port3)
--  5: peak (& pre2/pos2)
--  4: simple SUP
--  3: peak
--  2: dip
--  1: mark
--  0: zero

architecture ChBufManPeakMark2 of ChBufManPeakMark2 is

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

  signal peak_cand, dip_cand : std_logic;

  signal preUDiff1, posUDiff1 : std_logic;
  signal preUDiff2, posUDiff2 : std_logic;
  signal excessP5, excessP7 : std_logic;

  signal preDDiff1, posDDiff1 : std_logic;
  signal preDDiff2, posDDiff2 : std_logic;
  signal excessD5, excessD7 : std_logic;

  signal keepP : std_logic_vector(2 downto 0) := "000";
  signal keepQ : std_logic_vector(2 downto 0) := "000";
  signal keepR : std_logic_vector(2 downto 0) := "000";
  signal keepM : std_logic_vector(2 downto 0) := "000";
  signal keepD : std_logic_vector(2 downto 0) := "000";
  signal keepE : std_logic_vector(2 downto 0) := "000";
  signal keepF : std_logic_vector(2 downto 0) := "000";
  signal keepZ : std_logic_vector(2 downto 0) := "000";
  signal keepS : std_logic_vector(2 downto 0) := "000";

  signal datain, datain0, datain1, datain2, datain3 : std_logic_vector(13 downto 0);
  signal datain0P, datain0M : std_logic_vector(13 downto 0);
  signal datainA : std_logic_vector(13 downto 0);

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
      datainA <= datainB;
      datain  <= datainA;
      datain0 <= datain;
      datain0P <= datain - excessp;
      datain0M <= datain + excessd;
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

      peak_cand <= ((up0 and dn) or (eq0 and dn) or (up0 and eq));
      dip_cand  <= ((dn0 and up) or (dn0 and eq) or (eq0 and up));
--      peak_cand <= ((up0='1' and dn='1') or (eq0='1' and dn='1') or (up0='1' and eq='1'));
--      dip_cand  <= ((dn0='1' and up='1') or (dn0='1' and eq='1') or (eq0='1' and up='1'));

      if (datainB < datain0P) then posUDiff2 <= '1'; else posUDiff2 <= '0'; end if;
      if (datainA < datain0P) then posUDiff1 <= '1'; else posUDiff1 <= '0'; end if;
      if (datain2 < datain0P) then preUDiff1 <= '1'; else preUDiff1 <= '0'; end if;
      if (datain3 < datain0P) then preUDiff2 <= '1'; else preUDiff2 <= '0'; end if;
      excessP5 <= posUDiff1 and preUDiff1;
      excessP7 <= posUDiff1 and preUDiff1 and posUDiff2 and preUDiff2;

      if (datainB > datain0M) then posDDiff2 <= '1'; else posDDiff2 <= '0'; end if;
      if (datainA > datain0M) then posDDiff1 <= '1'; else posDDiff1 <= '0'; end if;
      if (datain2 > datain0M) then preDDiff1 <= '1'; else preDDiff1 <= '0'; end if;
      if (datain3 > datain0M) then preDDiff2 <= '1'; else preDDiff2 <= '0'; end if;
      excessD5 <= posDDiff1 and preDDiff1;
      excessD7 <= posDDiff1 and preDDiff1 and posDDiff2 and preDDiff2;

    end if;
  end process;

  -- check peak
  process (Clock)
  begin
    if (Clock'event and Clock='1') then
      if (datain2>threshold(13 downto 0)) then
        if (peak_cand='1') then
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
        if (peak_cand='1' and excessP5='1') then
          if (cmptype(5)='1') then
            keepQ <= "100";
          end if;
        else
          if (keepQ > 0) then keepQ <= keepQ - 1; end if;
        end if;
      else
        if (keepQ > 0) then keepQ <= keepQ - 1; end if;
      end if;
    end if;
  end process;

  -- check peak (&pre2/pos2 &pre3/pos3)
  process (Clock)
  begin
    if (Clock'event and Clock='1') then
      if (datain2>threshold(13 downto 0)) then
        if (peak_cand='1' and excessP7='1') then
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
        if (dip_cand='1') then
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
        if (dip_cand='1' and excessD5='1') then
          if (cmptype(7)='1') then
            keepE <= "100";
          end if;
        else
          if (keepE > 0) then keepE <= keepE - 1; end if;
        end if;
      else
        if (keepE > 0) then keepE <= keepE - 1; end if;
      end if;
    end if;
  end process;

  -- check dip (&pre2/pos2 &pre3/pos3)
  process (Clock)
  begin
    if (Clock'event and Clock='1') then
      if (datain2>threshold(13 downto 0)) then
        if (dip_cand='1' and excessD7='1') then
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

  -- check mark
  process (Clock)
  begin
    if (Clock'event and Clock='1') then
      if ( (datain1(13 downto 12)/="00" and datain2(13 downto 12) ="00") or  -- <4096 -> >=4096
           (datain1(13 downto 12) ="00" and datain2(13 downto 12)/="00") or  -- >=4096 -> <4096
           (datain1(13)           ='1'  and datain2(13)           ='0' ) or  -- <8192 -> >=8192
           (datain1(13)           ='0'  and datain2(13)           ='1' ) or  -- >=8192 -> <8192
           (datain1(12)           ='0'  and datain2(13 downto 12) ="11") or  -- <12288 -> >=12288
           (datain1(13 downto 12) ="11" and datain2(12)           ='0' ) ) then  -- >=12288 -> <12288
        if (cmptype(1)='1') then
          keepM <= "011";
        end if;
      else
          if (keepM > 0) then keepM <= keepM - 1; end if;
      end if;
    end if;
  end process;
--  keepM <= "000";

  -- check zero
  process (Clock)
  begin
    if (Clock'event and Clock='1') then
      if ( (datain1>=threshold and datain2<threshold) or
           (datain1<threshold and datain2>=threshold) or
           (datain1>=threshold and datain2<threshold) or
           (datain1<threshold and datain2>=threshold) ) then
        if (cmptype(0)='1') then
          keepZ <= "011";
        end if;
      else
        if (keepZ > 0) then keepZ <= keepZ - 1; end if;
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
                keepM(2 downto 1)/="00" or
                keepD(2 downto 1)/="00" or
                keepE(2 downto 1)/="00" or
                keepF(2 downto 1)/="00" or
                keepZ(2 downto 1)/="00" or
                keepS(2 downto 1)/="00") then         -- put data
              wren <= '1';
              wrpointer <= wrpointer + 1;
              size4header <= size4header + 1;
              outdata <= "00" & datain3;
            elsif (keepP(0)='1' or
                   keepQ(0)='1' or
                   keepR(0)='1' or
                   keepM(0)='1' or
                   keepD(0)='1' or
                   keepE(0)='1' or
                   keepF(0)='1' or
                   keepZ(0)='1' or
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

end ChBufManPeakMark2;
