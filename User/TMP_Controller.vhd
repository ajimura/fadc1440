library ieee,work;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use work.AddressMap.all;
use work.BusSignalTypes.all;
use work.AddressBook.all;

entity TMPController is
   port(
      Clock : in std_logic; -- SysClock(1MHz)
      BusClk : in std_logic;
      Reset : in std_logic;
      SCL : out std_logic;
      SDA : inout std_logic_vector(0 downto 0);
      LocalBusAddress : in std_logic_vector(31 downto 0);
      LocalBusDataIn : in std_logic_vector(31 downto 0);
      LocalBusDataOut : out std_logic_vector(31 downto 0);
      LocalBusRS : in  std_logic;
      LocalBusWS : in  std_logic;
      LocalBusRDY : out std_logic
      );
end TMPController;

architecture TMPController of TMPController is

component iobidir0
   PORT (
      datain      : IN STD_LOGIC_VECTOR (0 DOWNTO 0);
      oe      : IN STD_LOGIC_VECTOR (0 DOWNTO 0);
      dataio      : INOUT STD_LOGIC_VECTOR (0 DOWNTO 0);
      dataout      : OUT STD_LOGIC_VECTOR (0 DOWNTO 0)
   );
   end component;

   constant slave_addr : std_logic_vector(6 downto 0) := "1110000";

   signal TMP_Data, TMP_Send, TMP_Ret : std_logic_vector(7 downto 0);
   signal TMP_reg : std_logic_vector(7 downto 0);

   signal TMP_Go : std_logic := '0';
   signal TMP_Ack : std_logic := '0';
   signal TMP_W, TMP_R : std_logic;
   signal RW_flag : std_logic;
   signal ack : std_logic;
   signal ack_ret : std_logic_vector(2 downto 0);

   signal SCL_buf, SDA_buf : std_logic := '1';
   signal OE_buf : std_logic;
   signal OE_sig, SDO_sig, SDI_sig, SDA_sig : std_logic_vector(0 downto 0);

   signal pointer : natural range 0 to 63;
   signal Clk0p5 : std_logic;
   
   type LBusType is (
      Initialize,
      Idle,
      Write,
      Read,
      WaitTMP,
      Done );
   signal ss_bus : LBusType;
   
   type RWType is (Idle,
                   w_step0, w_step1, w_step2, w_step3, w_step4, w_step5, w_step6, w_step7, w_step8,
                   w_step9,
                   r_step0, r_step1, r_step2, r_step3, r_step4, r_step5, r_step6, r_step7, r_step8,
                   r_step9, r_step10, r_step11, r_step12, r_step13, r_step14,
                   start0, start1,
                   slave0, slave1, slave2,
                   rw0, rw1, rw2, rw3,
                   ack0, ack1, ack2,
                   reg0, reg1, reg2,
                   get0, get1, get2, get3,
                   ackw0, ackw1, ackw2, ackw3,
                   stop0, stop1,
                   Done );
   signal ss_rw, ss_next : RWType;

begin

   SDA_IO : iobidir0 port map (
      datain => SDO_sig,
      oe => OE_sig,
      dataio => SDA,
      dataout => SDI_sig
   );
   
   SCL <= SCL_buf;
   SDO_sig(0) <= SDA_buf;
   OE_sig(0) <= OE_buf;
   
   -- clock
   process (Clock, Reset)
   begin
      if (Reset='1') then
         Clk0p5 <= '0';
      elsif (Clock'event and Clock='1') then
         Clk0p5 <= not(Clk0p5);
      end if;
   end process;

   --read/write process--
   process (Clk0p5, Reset)
   begin
     if ( Reset = '1' ) then
       ss_rw <= Idle;
       TMP_Ack <= '0';
       SCL_buf <= '1';
       SDA_buf <= '1';
       OE_buf <= '1';
       TMP_Ret <= (others => '0');
     elsif (Clk0p5'event and Clk0p5='1') then
       case ss_rw is
         when Idle =>
           TMP_Ack <= '0';
           SCL_buf <= '1';
           SDA_buf <= '1';
           OE_buf <= '1';
           TMP_Ret <= (others => '0');
           if (TMP_Go='1') then
             if (TMP_W='1') then
               ss_rw <= w_step0;
             elsif (TMP_R='1') then
               ss_rw <= r_step0;
             end if;
           end if;
-------------------------------------------------------------------------------
-- write process
-------------------------------------------------------------------------------
         when w_step0 =>               -- start
           ss_next <= w_step1; ss_rw <= start0;
         when w_step1 =>               -- slave addr
           pointer <= 6;
           ss_next <= w_step2; ss_rw <= slave0;
         when w_step2 =>               -- r/w
           SCL_buf <= '0';
           RW_flag <= '0';
           ss_next <= w_step3; ss_rw <= rw0;
         when w_step3 =>               -- ack
           SCL_buf <= '0';
           ss_next <= w_step4; ss_rw <= ack0;
         when w_step4 =>               -- reg. pointer
           ack_ret(0) <= ack;
           TMP_Send <= TMP_reg;
           SCL_buf <= '0';
           ss_next <= w_step5; ss_rw <= reg0;
         when w_step5 =>               -- ack
           SCL_buf <= '0';
           ss_next <= w_step6; ss_rw <= ack0;
         when w_step6 =>               -- data
           ack_ret(1) <= ack;
           TMP_Send <= TMP_Data;
           SCL_buf <= '0';
           ss_next <= w_step7; ss_rw <= reg0;
         when w_step7 =>               -- ack
           SCL_buf <= '0';
           ss_next <= w_step8; ss_rw <= ack0;
         when w_step8 =>               -- pre stop
           ack_ret(2) <= ack;
           SCL_buf <= '0';
           ss_rw <= w_step9;
         when w_step9 =>
           SDA_buf <= '0'; OE_buf <= '1';
           ss_next <= Done; ss_rw <= stop0;
-------------------------------------------------------------------------------
-- read process
-------------------------------------------------------------------------------
         when r_step0 =>               -- start
           ss_next <= r_step1; ss_rw <= start0;
         when r_step1 =>               -- slave addr
           pointer <= 6;
           ss_next <= r_step2; ss_rw <= slave0;
         when r_step2 =>               -- r/w
           SCL_buf <= '0';
           RW_flag <= '0';
           ss_next <= r_step3; ss_rw <= rw0;
         when r_step3 =>               -- ack
           SCL_buf <= '0';
           ss_next <= r_step4; ss_rw <= ack0;
         when r_step4 =>               -- reg. pointer
           ack_ret(0) <= ack;
           TMP_Send <= TMP_reg;
           SCL_buf <= '0';
           ss_next <= r_step5; ss_rw <= reg0;
         when r_step5 =>               -- ack
           SCL_buf <= '0';
           ss_next <= r_step6; ss_rw <= ack0;
         when r_step6 =>               -- stop
           ack_ret(1) <= ack;
           SCL_buf <= '0'; SDA_buf <= '0'; OE_buf <= '1';
           ss_next <= r_step7; ss_rw <= stop0;
         when r_step7 =>               -- start
           ss_next <= r_step8; ss_rw <= start0;
         when r_step8 =>               -- slave
           SCL_buf <= '0';
           pointer <= 6;
           ss_next <= r_step9; ss_rw <= slave0;
         when r_step9 =>               -- R/W
           SCL_buf <= '0';
           RW_flag <= '1';
           ss_next <= r_step10; ss_rw <= rw0;
         when r_step10 =>              -- ack
           SCL_buf <= '0';
           ss_next <= r_step11; ss_rw <= ack0;
         when r_step11 =>              -- get data
           ack_ret(2) <= ack;
           SCL_buf <= '0';
           ss_next <= r_step12; ss_rw <= get0;
         when r_step12 =>              -- send ack
           SCL_buf <= '0'; SDA_buf <= '0'; OE_buf <= '1';
           ss_next <= r_step13; ss_rw <= ackw0;
         when r_step13 =>              -- pre-stop
           SCL_buf <= '0';
           ss_rw <= r_step14;
         when r_step14 =>
           SDA_buf <= '0';
           ss_next <= Done; ss_rw <= stop0;

-- start seq.
         when start0 =>
           SCL_buf <= '1'; SDA_buf <= '0';
           ss_rw <= start1;
         when start1 =>
           SCL_buf <= '0'; SDA_buf <= '0';
           pointer <= 6;
           ss_rw <= ss_next;
-- slave addr.
         when slave0 =>
           SCL_buf <= '0'; SDA_buf <= '0';
           ss_rw <=slave1;
         when slave1 =>
           SCL_buf <= '0'; SDA_buf <= slave_addr(pointer);
           ss_rw <= slave2;
         when slave2 =>
           SCL_buf <= '1';
           pointer <= pointer -1;
           if (pointer=0) then
             ss_rw <= ss_next;
           else
             ss_rw <= slave0;
           end if;
-- R/W
         when rw0 =>
			  SCL_buf <= '0';
           ss_rw <= rw1;
         when rw1 =>
           SCL_buf <= '0'; SDA_buf <= RW_flag;
           ss_rw <= rw2;
         when rw2 =>
           SCL_buf <= '1';  --SDA_buf
           ss_rw <= rw3;
         when rw3 =>
           ss_rw <= ss_next;
-- ack0
         when ack0 =>
			  SCL_buf <= '0';
           OE_buf <= '0';
           ss_rw <= ack1;
         when ack1 =>
           SCL_buf <= '1';
           ss_rw <= ack2;
         when ack2 =>
           ack <= SDI_sig(0);
           pointer <= 7;
           ss_rw <= ss_next;
-- reg. pointer/data: 8-bit send
         when reg0 =>
			  SCL_buf <= '0';
           ss_rw <= reg1;
         when reg1 =>
           SCL_buf <= '0'; SDA_buf <= TMP_Send(pointer);
           OE_buf <= '1';
           ss_rw <= reg2;
         when reg2 =>
           SCL_buf <= '1';  --SDA_buf
           pointer <= pointer - 1;
           if (pointer=0) then
             ss_rw <= ss_next;
           else
             ss_rw <= reg0;
           end if;
-- get data
         when get0 =>
           SCL_buf <= '0';
           ss_rw <= get1;
         when get1 =>
           SCL_buf <= '0';
           ss_rw <= get2;
         when get2 =>
           SCL_buf <= '1';
           ss_rw <= get3;
         when get3 =>
           TMP_Ret(pointer) <= SDI_sig(0);
           pointer <= pointer - 1;
           if (pointer=0) then
             ss_rw <= ss_next;
           else
             ss_rw <= get0;
           end if;
-- send ack
         when ackw0 =>
           SCL_buf <= '0'; SDA_buf <= '0';
           ss_rw <= ackw1;
         when ackw1 =>
           SCL_buf <= '1'; SDA_buf <= '0';
           ss_rw <= ackw2;
         when ackw2 =>
           SCL_buf <= '1'; SDA_buf <= '0';
           ss_rw <= ackw3;
         when ackw3 =>
           SCL_buf <= '0'; SDA_buf <= '0';
           ss_rw <= ss_next;
-- stop seq.
         when stop0 =>
           SCL_buf <= '1'; SDA_buf <= '0';
           ss_rw <= stop1;
         when stop1 =>
           SCL_buf <= '1'; SDA_buf <= '1';
           ss_rw <= ss_next;
-- end process
         when Done =>
           TMP_Ack <= '1';
           if (TMP_R = '0' and TMP_W='0') then
             ss_rw <= Idle;
           end if;
       end case;
     end if;
   end process;
               
         

   -- Bus Process -------------------------------------------------------------
   BusProcess : process ( BusClk, Reset )
   begin
      if ( Reset = '1' ) then
         ss_bus <= Initialize;
         TMP_Go <= '0';
         TMP_W <= '0';
         TMP_R <= '0';
      elsif ( BusClk'event and BusClk='1' ) then
         case ss_bus is
            when Initialize =>
               LocalBusDataOut <= x"00000000";
               LocalBusRDY <= '0';
               TMP_Go <= '0';
               TMP_W <= '0';
               TMP_R <= '0';
               ss_bus <= Idle;

            when Idle =>
               if ( LocalBusWS = '1') then
                  ss_bus <= Write;
               elsif ( LocalBusRS = '1' ) then
                  ss_bus <= Read;
               end if;
            
            when Write =>
               TMP_W <= '1';
               TMP_reg <= LocalBusAddress(9 downto 2);
               TMP_Data <= LocalBusDataIn(7 downto 0);
               ss_bus <= WaitTMP;
               
            when Read =>
               TMP_R <= '1';
               if (LocalBusAddress(7 downto 4)="0000") then
                  TMP_reg <= LocalBusAddress(9 downto 2);
                  ss_bus <= WaitTMP;
               else
                  LocalBusDataOut <= x"0123456" & '0' & ack_ret;
                                           ss_bus <= Done;
               end if;
            when WaitTMP =>
               TMP_Go <= '1';
               if (TMP_Ack = '1') then
                  TMP_Go <= '0';
                  if (LocalBusRS='1') then
--                     LocalBusDataOut <= x"000000" & TMP_Data(8 downto 1);
                     LocalBusDataOut(7 downto 0) <= TMP_Ret(7 downto 0);
                  end if;
                  ss_bus <= Done;
               end if;

            when Done =>
               LocalBusRDY <= '1';
               if ( LocalBusWS='0' and LocalBusRS='0' ) then
                  ss_bus <= Initialize;
               end if;
               
         end case;
      end if;
   end process BusProcess;
   ------------------------------------------------------------- Bus Process --

end TMPController;
