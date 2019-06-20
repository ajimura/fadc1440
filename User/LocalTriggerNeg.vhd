library ieee,work;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use work.AddressMap.all;
use work.BusSignalTypes.all;
use work.AddressBook.all;

entity LocalTriggerNeg is
	port(
		Clock : in std_logic;
		BusClk : in std_logic;
		Reset : in std_logic;
		DataIn : in  std_logic_vector(223 downto 0);
		TriggerOut : out std_logic;
		LocalBusAddress : in std_logic_vector(15 downto 0);
		LocalBusDataIn : in std_logic_vector(31 downto 0);
		LocalBusDataOut : out std_logic_vector(31 downto 0);
		LocalBusRS : in  std_logic;
		LocalBusWS : in  std_logic;
		LocalBusRDY : out std_logic
		);
end LocalTriggerNeg;

architecture LocalTrigger of LocalTriggerNeg is

	-- Signal Declarations -----------------------------------------------------
	signal thres_high : std_logic_vector(15 downto 0) := x"0070";
	signal thres_low : std_logic_vector(15 downto 0) := x"0060";
	signal width : std_logic_vector(7 downto 0) := x"0F";
	signal TrigSelect : std_logic_vector(15 downto 0) := "1111111111111111";
	signal event_count : std_logic_vector(31 downto 0);
	signal discri : std_logic_vector(15 downto 0) := "0000000000000000";
	signal discriout : std_logic;
	signal count : std_logic_vector(7 downto 0);
	signal status : std_logic_vector(15 downto 0);

	type ss_type is (ss_idle, ss_trig_0, ss_trig, ss_wait);
	signal ss : ss_type;
	signal ss_bus : BusProcessType;
	----------------------------------------------------- Signal Declarations --

begin
	-- concurrent --------------------------------------------------------------
	discriout <= '1' when (discri and TrigSelect)>0 else '0';

	-- Discrimination ------------------------------------------------------------
	Sync : process ( Clock )
	begin
		if ( Clock'event and Clock = '1' ) then
			if    (DataIn( 13 downto   0) < thres_low ( 13 downto   0)) then discri( 0) <= '1';
			elsif (DataIn( 13 downto   0) > thres_high( 13 downto   0)) then discri( 0) <= '0'; end if;
			if    (DataIn( 27 downto  14) < thres_low ( 13 downto   0)) then discri( 1) <= '1';
			elsif (DataIn( 27 downto  14) > thres_high( 13 downto   0)) then discri( 1) <= '0'; end if;
			if    (DataIn( 41 downto  28) < thres_low ( 13 downto   0)) then discri( 2) <= '1';
			elsif (DataIn( 41 downto  28) > thres_high( 13 downto   0)) then discri( 2) <= '0'; end if;
			if    (DataIn( 55 downto  42) < thres_low ( 13 downto   0)) then discri( 3) <= '1';
			elsif (DataIn( 55 downto  42) > thres_high( 13 downto   0)) then discri( 3) <= '0'; end if;
			if    (DataIn( 69 downto  56) < thres_low ( 13 downto   0)) then discri( 4) <= '1';
			elsif (DataIn( 69 downto  56) > thres_high( 13 downto   0)) then discri( 4) <= '0'; end if;
			if    (DataIn( 83 downto  70) < thres_low ( 13 downto   0)) then discri( 5) <= '1';
			elsif (DataIn( 83 downto  70) > thres_high( 13 downto   0)) then discri( 5) <= '0'; end if;
			if    (DataIn( 97 downto  84) < thres_low ( 13 downto   0)) then discri( 6) <= '1';
			elsif (DataIn( 97 downto  84) > thres_high( 13 downto   0)) then discri( 6) <= '0'; end if;
			if    (DataIn(111 downto  98) < thres_low ( 13 downto   0)) then discri( 7) <= '1';
			elsif (DataIn(111 downto  98) > thres_high( 13 downto   0)) then discri( 7) <= '0'; end if;
			if    (DataIn(125 downto 112) < thres_low ( 13 downto   0)) then discri( 8) <= '1';
			elsif (DataIn(125 downto 112) > thres_high( 13 downto   0)) then discri( 8) <= '0'; end if;
			if    (DataIn(139 downto 126) < thres_low ( 13 downto   0)) then discri( 9) <= '1';
			elsif (DataIn(139 downto 126) > thres_high( 13 downto   0)) then discri( 9) <= '0'; end if;
			if    (DataIn(153 downto 140) < thres_low ( 13 downto   0)) then discri(10) <= '1';
			elsif (DataIn(153 downto 140) > thres_high( 13 downto   0)) then discri(10) <= '0'; end if;
			if    (DataIn(167 downto 154) < thres_low ( 13 downto   0)) then discri(11) <= '1';
			elsif (DataIn(167 downto 154) > thres_high( 13 downto   0)) then discri(11) <= '0'; end if;
			if    (DataIn(181 downto 168) < thres_low ( 13 downto   0)) then discri(12) <= '1';
			elsif (DataIn(181 downto 168) > thres_high( 13 downto   0)) then discri(12) <= '0'; end if;
			if    (DataIn(195 downto 182) < thres_low ( 13 downto   0)) then discri(13) <= '1';
			elsif (DataIn(195 downto 182) > thres_high( 13 downto   0)) then discri(13) <= '0'; end if;
			if    (DataIn(209 downto 196) < thres_low ( 13 downto   0)) then discri(14) <= '1';
			elsif (DataIn(209 downto 196) > thres_high( 13 downto   0)) then discri(14) <= '0'; end if;
			if    (DataIn(223 downto 210) < thres_low ( 13 downto   0)) then discri(15) <= '1';
			elsif (DataIn(223 downto 210) > thres_high( 13 downto   0)) then discri(15) <= '0'; end if;

			if ( ss = ss_idle ) then
				TriggerOut <= '1';
				status(3 downto 0) <= "0001";
			elsif ( ss = ss_trig_0 ) then
				TriggerOut <= '1';
				status(3 downto 0) <= "0010";
			elsif ( ss = ss_trig ) then
				TriggerOut <= '0';
				status(3 downto 0) <= "0100";
			elsif ( ss = ss_wait ) then
				TriggerOut <= '1';
				status(3 downto 0) <= "1000";
			end if;

		end if;
	end process Sync;

	-- Trigger Process ---------------------------------------------------------
	TrigProcess : process (Clock, Reset)
	begin
		if ( Reset = '1' ) then
			ss <= ss_idle;
			event_count <= ( others => '0' );
		elsif ( Clock'event and Clock = '1' ) then
			case ss is
				when ss_idle =>
					if ( discriout='1') then
						ss <= ss_trig_0;
					end if;
				when ss_trig_0 =>
					count <= x"00";
					event_count <= event_count + 1;
					ss <= ss_trig;
				when ss_trig =>
					count <= count + 1;
					if ( count=width ) then
						ss <= ss_wait;
					end if;
				when ss_wait =>
					if ( discriout ='0' ) then
						ss <= ss_idle;
					end if;
			end case;
		end if;
	end process TrigProcess;
	--------------------------------------------------------- Trigger Process --

	-- Bus Process -------------------------------------------------------------
	BusProcess : process ( BusClk, Reset )
	begin
		if ( Reset = '1' ) then
			ss_bus <= Initialize;
		elsif ( BusClk'event and BusClk='1' ) then
			case ss_bus is
				when Initialize =>
					LocalBusDataOut <= x"00000000";
					LocalBusRDY <= '0';
					ss_bus <= Idle;

				when Idle =>
					if ( LocalBusWS = '1') then
						ss_bus <= Write;
					elsif ( LocalBusRS = '1' ) then
						ss_bus <= Read;
					end if;
				
				when Write =>
						if ( LocalBusAddress(7 downto 0) = LTG_Thres ) then
							thres_low <= LocalBusDataIn(15 downto 0);
							thres_high <= LocalBusDataIn(31 downto 16);
						elsif ( LocalBusAddress(7 downto 0) = LTG_Width ) then
							width <= LocalBusDataIn(7 downto 0);
						elsif ( LocalBusAddress(7 downto 0) = LTG_TrigSelect ) then
							TrigSelect <= LocalBusDataIn(15 downto 0);
						end if;
					ss_bus <= Done;

				when Read =>
						if ( LocalBusAddress(7 downto 0) = LTG_Thres ) then
							LocalBusDataOut(15 downto 0) <= thres_low;
							LocalBusDataOut(31 downto 16) <= thres_high;
						elsif ( LocalBusAddress(7 downto 0) = LTG_EventCount ) then
							LocalBusDataOut <= event_count;
						elsif ( LocalBusAddress(7 downto 0) <= LTG_TrigStatus ) then
							LocalBusDataOut( 3 downto 0 ) <= status(3 downto 0);
						elsif ( LocalBusAddress(7 downto 0) <= LTG_Width ) then
							LocalBusDataOut( 7 downto 0 ) <= width;
						elsif ( LocalBusAddress(7 downto 0) <= LTG_TrigSelect ) then
							LocalBusDataOut(15 downto 0 ) <= TrigSelect;
						end if;
					ss_bus <= Done;

				when Done =>
					LocalBusRDY <= '1';
					if ( LocalBusWS='0' and LocalBusRS='0' ) then
--						LocalBusRDY <= '0';
						ss_bus <= Initialize;
					end if;
					
			end case;
		end if;
	end process BusProcess;
	------------------------------------------------------------- Bus Process --

end LocalTrigger;
