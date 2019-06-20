library ieee,work;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use work.AddressMap.all;
use work.BusSignalTypes.all;
use work.AddressBook.all;

entity ChBufManZero is
	generic( ChID : std_logic_vector(3 downto 0) );
	port(
		Clock : in std_logic;
		Reset : in std_logic;
		datain : in std_logic_vector(13 downto 0);
		dataout : out std_logic_vector(31 downto 0);
		address : out std_logic_vector(9 downto 0);
		datasize : out std_logic_vector(10 downto 0);
		threshold : in std_logic_vector(15 downto 0);
		fullrange : in std_logic_vector(15 downto 0);
		wren : out std_logic;
		byteena : out std_logic_vector(3 downto 0);
		req : in std_logic;
		ack : out std_logic
	);
end ChBufManZero;

architecture ChBufManZero of ChBufManZero is

	-- Signal Declarations -----------------------------------------------------
	signal wrpointer : std_logic_vector(10 downto 0);
	signal end_mark: std_logic;
	signal ins_tick: std_logic;
	signal total_count: std_logic_vector(15 downto 0);

	signal curr : std_logic_vector(13 downto 0);
	signal post0,post1,post2,post3 : std_logic_vector(13 downto 0);
	signal post4,post5 : std_logic_vector(13 downto 0);
	signal StoreOn, PrevOn : std_logic;
	signal count, count0 : natural;

	type ss_type is (ss_init, ss_record, ss_instick, ss_thru, ss_endmark, ss_wait);
	signal ss : ss_type;
	
	type ss_ticktype is (ss_init,ss_on,ss_off,ss_wait);
	signal ss_tick : ss_ticktype;

	signal ss_bus : BusProcessType;
	type BusProcessSubType is ( SetPointer, Waitdataout1, Waitdataout2, GetData );
	signal ss_sub : BusProcessSubType;
	----------------------------------------------------- Signal Declarations --

begin

	dataout <= ("00" & curr & "00" & curr) when (end_mark='0' and ins_tick='0') else
					x"FFFFFFFF" when (end_mark='1' and ins_tick='0') else
					("10" & total_count(13 downto 0) & "10" & total_count(13 downto 0)) when (ins_tick='1') else
					x"F0F0F0F0";
	address <= wrpointer(10 downto 1);
	byteena <= "0011" when wrpointer(0)='0' else
					"1100";

	
	DataGet : process ( Clock )
	begin
		if (Clock'event and Clock='1') then
			post5 <= datain;
			post4 <= post5;
			post3 <= post4;
			post2 <= post3;
			post1 <= post2;
			post0 <= post1;
			curr <= post0;
		end if;
	end process DataGet;

	PrevOnOff : process (Clock)
	begin
		if (Clock'event and Clock='1') then
			case ss_tick is
			when ss_init =>
				if (((threshold(15)='0') and (post5 > threshold(13 downto 0))) or
						((threshold(15)='1') and (post5 < threshold(13 downto 0)))) then
					PrevOn<='1';
					ss_tick <= ss_on;
				else
					PrevOn<='0';
					ss_tick <= ss_off;
				end if;
			when ss_on =>
				if (((threshold(15)='0') and (post5 < threshold(13 downto 0))) or
						((threshold(15)='1') and (post5 > threshold(13 downto 0)))) then
					count <= 6;
					ss_tick <= ss_wait;
				end if;
			when ss_wait =>
				count <= count - 1;
				if (count=0) then
					if (((threshold(15)='0') and (post5<threshold(13 downto 0))) or
							((threshold(15)='1') and (post5>threshold(13 downto 0)))) then
						PrevOn<='0';
						ss_tick <= ss_off;
					elsif (((threshold(15)='0') and (post5>=threshold(13 downto 0))) or
								((threshold(15)='1') and (post5<=threshold(13 downto 0)))) then
						PrevOn<='1';
						ss_tick <= ss_on;
					end if;
				end if;
			when ss_off =>
				if (((threshold(15)='0') and (post5 > threshold(13 downto 0))) or
						((threshold(15)='1') and (post5 < threshold(13 downto 0)))) then
					PrevOn<='1';
					ss_tick <=ss_on;
				end if;
			end case;
		end if;
	end process PrevOnOff;

	OnOff : process (Clock)
	begin
		if (Clock'event and Clock='1') then
			StoreOn <= PrevOn;
		end if;
	end process OnOff;

	ReadWrite : process ( Clock, Reset )
	begin
		if( Reset='1' ) then
			ss <= ss_init;
		elsif ( Clock'event and Clock = '1' ) then
			case ss is
				when ss_init =>
					end_mark <= '0';
					ins_tick <= '0';
					wrpointer   <= "00000000000"; -- 11 bits
					total_count <= "0000000000000000"; -- 16 bits
					if (req='1') then
						if (StoreOn='1') then
							wren<='1';
							ss<=ss_record;
						else
							wren<='0';
							ss<=ss_thru;
						end if;
					end if;
				when ss_record =>
					total_count <= total_count + 1;
					wrpointer <= wrpointer + 1;
					if (total_count=fullrange or wrpointer="00111111101") then
						end_mark <= '1';
						ins_tick <= '1';
						wren <= '1';
						ss <= ss_instick;
					else
						wren<='1';
						if (PrevOn='0') then
							ins_tick <= '1';
							ss <= ss_instick;
						end if;
					end if;
				when ss_instick =>
					total_count <= total_count + 1;
					ins_tick <= '0';
					wrpointer <= wrpointer + 1;
					if (end_mark='1') then
						ss<=ss_endmark;
					else
						if (total_count=fullrange or wrpointer="00111111110") then
							end_mark<='1';
							ss<=ss_endmark;
						else
							if (StoreOn='1') then
								wren<='1';
								ss<=ss_record;
							else
								wren<='0';
								ss<=ss_thru;
							end if;
						end if;
					end if;						
				when ss_thru =>
					total_count <= total_count + 1;
					if (total_count=fullrange or wrpointer="00111111110") then
						wren<='1';
						end_mark<='1';
						ss<=ss_endmark;
					else
						if (StoreOn='1') then
							wren<='1';
							ss<=ss_record;
						else
							wren<='0';
						end if;
					end if;
				when ss_endmark =>
					wrpointer <= wrpointer + 1;
					if (wrpointer(0)='1') then
						wren <= '0';
						end_mark <= '0';
						ss <= ss_wait;
					end if;
				when ss_wait =>
					if (req='0') then
						ack <= '0';
						ss <= ss_init;
					else
						ack <= '1';
						datasize <= wrpointer(10 downto 0);
					end if;
			end case;				
		end if;
	end process ReadWrite;	
	------------------------------------------------------- ReadWrite Process --
end ChBufManZero;
