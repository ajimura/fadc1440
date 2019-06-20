library ieee,work;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use work.AddressMap.all;
use work.BusSignalTypes.all;
use work.AddressBook.all;

entity LocalTriggerPos is
	port(
		Clock : in std_logic;
		BusClk : in std_logic;
		Reset : in std_logic;
		DataIn : in  std_logic_vector(223 downto 0);
		TriggerOut : out std_logic;
		LocalBusAddress : in std_logic_vector(31 downto 0);
		LocalBusDataIn : in std_logic_vector(31 downto 0);
		LocalBusDataOut : out std_logic_vector(31 downto 0);
		LocalBusRS : in  std_logic;
		LocalBusWS : in  std_logic;
		LocalBusRDY : out std_logic
		);
end LocalTriggerPos;

architecture LocalTrigger of LocalTriggerPos is

	-- Signal Declarations -----------------------------------------------------
	signal thres_high : std_logic_vector(15 downto 0) := x"0070";
	signal thres_low : std_logic_vector(15 downto 0) := x"0060";
	signal width : std_logic_vector(7 downto 0) := x"0F";
	signal TrigSelect : std_logic_vector(15 downto 0) := (others => '1');
	signal event_count : std_logic_vector(31 downto 0);
	signal discri : std_logic_vector(15 downto 0) := (others => '0');
	signal discriout : std_logic;
	signal count : std_logic_vector(7 downto 0);

	type ss_type is (ss_idle, ss_trig_0, ss_trig, ss_wait);
	signal ss : ss_type;
	signal ss_bus : BusProcessType;
	----------------------------------------------------- Signal Declarations --

begin

	discriout <= '1' when (discri and TrigSelect)>0 else '0';

	DiscGen: for i in 0 to 15 generate
		Disc : process ( Clock )
		begin
			if ( Clock'event and Clock = '1' ) then
				if    (DataIn( 13+i*14 downto i*14) > thres_high( 13 downto   0)) then
					discri(i) <= '1';
				elsif (DataIn( 13+i*14 downto i*14) < thres_low( 13 downto   0)) then
					discri(i) <= '0';
				end if;
			end if;
		end process;
	end generate DiscGen;

	process ( Clock )
	begin
		if ( Clock'event and Clock = '1' ) then
			if ( ss = ss_trig ) then
				TriggerOut <= '1';
			else
				TriggerOut <= '0';
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
						if ( LocalBusAddress(4 downto 2) = LTG_ThresLow(4 downto 2) ) then
							thres_low(13 downto 0) <= LocalBusDataIn(13 downto 0);
						elsif ( LocalBusAddress(4 downto 2) = LTG_ThresHigh(4 downto 2) ) then
							thres_high(13 downto 0) <= LocalBusDataIn(13 downto 0);
						elsif ( LocalBusAddress(4 downto 2) = LTG_Width(4 downto 2) ) then
							width <= LocalBusDataIn(7 downto 0);
						elsif ( LocalBusAddress(4 downto 2) = LTG_TrigSelect(4 downto 2) ) then
							TrigSelect <= LocalBusDataIn(15 downto 0);
						end if;
					ss_bus <= Done;

				when Read =>
						if ( LocalBusAddress(4 downto 2) = LTG_ThresHigh(4 downto 2) ) then
							LocalBusDataOut(15 downto 0) <= thres_high;
						elsif ( LocalBusAddress(4 downto 2) = LTG_ThresLow(4 downto 2) ) then
							LocalBusDataOut(15 downto 0) <= thres_low;
						elsif ( LocalBusAddress(4 downto 2) = LTG_EventCount(4 downto 2) ) then
							LocalBusDataOut <= event_count;
						elsif ( LocalBusAddress(4 downto 2) <= LTG_Width(4 downto 2) ) then
							LocalBusDataOut( 7 downto 0 ) <= width;
						elsif ( LocalBusAddress(4 downto 2) <= LTG_TrigSelect(4 downto 2) ) then
							LocalBusDataOut(15 downto 0 ) <= TrigSelect;
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

end LocalTrigger;
