library ieee,work;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use work.AddressMap.all;
use work.BusSignalTypes.all;
use work.AddressBook.all;

entity ASC_Command is
  port(
    Clock : in std_logic;
    RW : in std_logic;
    Command : in std_logic;
    ACK : out std_logic;
    RegData : in std_logic_vector(23 downto 0);
    RetData : out std_logic_vector(15 downto 0);
    CSB : out  std_logic_vector(1 downto 0);
    SDIO : inout std_logic_vector(1 downto 0);
    SCLK : out std_logic_vector(1 downto 0)
    );
end ASC_Command;

architecture ASC_Command of ASC_Command is

  component iobidir PORT (
    datain		: IN STD_LOGIC_VECTOR (1 DOWNTO 0);
    oe		: IN STD_LOGIC_VECTOR (1 DOWNTO 0);
    dataio		: INOUT STD_LOGIC_VECTOR (1 DOWNTO 0);
    dataout		: OUT STD_LOGIC_VECTOR (1 DOWNTO 0)
    );
  end component;

  type ss_type is (ss_init, ss_idle, ss_start, ss_command1, ss_command2, ss_write1, ss_write2, ss_read1, ss_read2, ss_final);
  signal ss : ss_type;
  signal ss_bus : BusProcessType;
  signal reg_content : std_logic_vector(23 downto 0);
  signal send_pointer : natural range 0 to 23;
  signal SDI : std_logic_vector(1 downto 0);
  signal SDO : std_logic;
  signal SINOUT : std_logic;
  signal SDI_sig, SDO_sig, OE_sig : std_logic_vector(1 downto 0);
  signal oSDO : std_logic;
  signal oSCLK : std_logic;

begin

  SDIO_Buf : iobidir port map (
    datain => SDO_sig,
    oe => OE_sig,
    dataio => SDIO,
    dataout => SDI_sig
    );
  OE_sig <= (others => (not SINOUT));
  SDO_sig <= (others => SDO);
  SDI <= SDI_sig;

  Control : Process (Clock)
  begin
    if (Clock'event and Clock='1') then
      case ss is
        when ss_init =>
          ACK<='0';
          CSB<="11";
          SDO<='0';
          SCLK <= "00";
          reg_content <= x"000000";
          ss <= ss_idle;
        when ss_idle =>
          if (Command='1') then
            CSB <= "00";
            ss <= ss_start;
          end if;
        when ss_start =>
          SINOUT <= '0';
          reg_content <= RegData;
          send_pointer <= 23;
          ss <= ss_command1;
        when ss_command1 =>
          SCLK <= "00";
          SDO <= reg_content(send_pointer);
          ss <= ss_command2;
        when ss_command2 =>
          SCLK <= "11";
          SDO <= reg_content(send_pointer);
          send_pointer <= send_pointer - 1;
          if (send_pointer=8) then
            if (RW='0') then
              ss <= ss_write1;
            else
              SINOUT <= '1';
              ss <= ss_read1;
            end if;
          else
            ss <= ss_command1;
          end if;
        when ss_write1 =>
          SINOUT <= '0';
          SCLK <= "00";
          SDO <= reg_content(send_pointer);
          ss <= ss_write2;
        when ss_write2 =>
          SINOUT <= '0';
          SCLK <= "11";
          SDO <= reg_content(send_pointer);
          send_pointer <= send_pointer -1;
          if (send_pointer=0) then
            ss <= ss_final;
          else 
            ss <= ss_write1;
          end if;
        when ss_read1 =>
          SCLK <= "00";
          RetData(send_pointer) <= SDI(0);
          RetData(send_pointer+8) <= SDI(1);
          ss <= ss_read2;
        when ss_read2 =>
          SCLK <= "11";
          RetData(send_pointer) <= SDI(0);
          RetData(send_pointer+8) <= SDI(1);
          send_pointer <= send_pointer-1;
          if (send_pointer=0) then
            ss <= ss_final;
          else
            ss <= ss_read1;
          end if;
        when ss_final =>
          ACK <= '1';
          SINOUT <= '0';
          if (Command='0') then
            ACK <= '0';
            SDO<='0';
            SCLK<="00";
            ss <= ss_init;
          end if;
      end case;
    end if;
  end process Control;
end ASC_Command;
