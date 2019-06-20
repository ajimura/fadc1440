library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

package AddressMap is

  constant CurVersion : std_logic_vector(31 downto 0) := x"20181216";
  constant NumUserModules : natural := 7;
  constant NumEvtBuffer : natural := 3; --4;
  constant NumCh : natural := 16;

-- Address Map --
-- <Ch:31-24> <Buf:23-20> <Func:19-16> <addr: 15-0>
-- Func --
--   L1D: 0000
--   LTC: 0001
--   TGC: 0010
--   ROC: 0011
--   EBM: 0100
--   ASC: 0101
--   TMP: 0110
--   GEN: 1xxx
-- Buffer Memory (15-0)
--   bit#31"1": multichannel mode
--   bit#31"0": normal mode

  -- Register Relative Address -----------------------------------------------
  ---- L1_Delay ----
  constant L1D_Delay		: std_logic_vector(15 downto 0):= x"0000";
  constant L1D_Delayed		: std_logic_vector(15 downto 0):= x"0004";
  ---- LocalTrigGer ----
  ---- TrigGerController ----
  constant TGC_FreeBuf		: std_logic_vector(15 downto 0):= x"0000";
  constant TGC_NextBuf		: std_logic_vector(15 downto 0):= x"0004";
  constant TGC_Count		: std_logic_vector(15 downto 0):= x"0008";
  constant TGC_CountEach	: std_logic_vector(15 downto 0):= x"000C";
  constant TGC_TrigEnab		: std_logic_vector(15 downto 0):= x"0010";
  constant TGC_TrigInOut	: std_logic_vector(15 downto 0):= x"0014";
  constant TGC_BufEnab		: std_logic_vector(15 downto 0):= x"0018";
  constant TGC_ClkTrig		: std_logic_vector(15 downto 0):= x"001C";
  constant TGC_CntRst		: std_logic_vector(15 downto 0):= x"0020";
  constant TGC_TrigID		: std_logic_vector(15 downto 0):= x"0024";
  constant TGC_FClk		: std_logic_vector(15 downto 0):= x"0028";
  constant TGC_CClk		: std_logic_vector(15 downto 0):= x"002C";
  constant TGC_IOstat		: std_logic_vector(15 downto 0):= x"0030";
  constant TGC_NoEmpty		: std_logic_vector(15 downto 0):= x"0034";
  constant TGC_Busy		: std_logic_vector(15 downto 0):= x"0038";
--  constant TGC_IN		: std_logic_vector(15 downto 0):= x"003C";
  ---- RreadOutController ----
  constant ROC_Ready		: std_logic_vector(15 downto 0):= x"0000";
  constant ROC_Done		: std_logic_vector(15 downto 0):= x"0004";
  ---- EventBufferManager ----
  constant EBM_Count		: std_logic_vector(15 downto 0):= x"0000";
  constant EBM_DataSize		: std_logic_vector(15 downto 0):= x"0004";
  constant EBM_TotSize		: std_logic_vector(15 downto 0):= x"0008";
  constant EBM_CntRst           : std_logic_vector(15 downto 0):= x"000C";
--  constant EBM_Status           : std_logic_vector(15 downto 0):= x"0010";
  constant EBM_Range		: std_logic_vector(15 downto 0):= x"0080";
  constant EBM_Thres		: std_logic_vector(15 downto 0):= x"0084";
  constant EBM_CmpType		: std_logic_vector(15 downto 0):= x"0088";
  ---- General
  constant CMN_Version		: std_logic_vector(15 downto 0):= x"0000";
  constant CMN_HardRst		: std_logic_vector(15 downto 0):= x"0000";
  constant CMN_Reset		: std_logic_vector(15 downto 0):= x"0004";
  constant CMN_LogAddr		: std_logic_vector(15 downto 0):= x"0008";
  constant CMN_SpWStatus0       : std_logic_vector(15 downto 0):= x"0010";
  constant CMN_SpWStatus1       : std_logic_vector(15 downto 0):= x"0014";
  constant CMN_SpWStatus2       : std_logic_vector(15 downto 0):= x"0018";
  ----------------------------------------------- Register Relative Address --

end package AddressMap;

library ieee,work;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.AddressMap.all;

package AddressBook is

  subtype ModuleID is integer range -1 to NumUserModules-1;
  subtype BuffID is integer range 0 to NumEvtBuffer-1;
  subtype ChanID is integer range 0 to NumCh-1;
  type Leaf is record
    ID : ModuleID;
  end record;
  type Binder is array (integer range <>) of Leaf;
  constant L1D : Leaf := ( ID => 0);
  constant LTG : Leaf := ( ID => 1);
  constant TGC : Leaf := ( ID => 2);
  constant ROC : Leaf := ( ID => 3);
  constant EBM : Leaf := ( ID => 4);
  constant ASC : Leaf := ( ID => 5);
  constant TMP : Leaf := ( ID => 6);
  constant DUMMY : Leaf := ( ID => -1);
  constant AddressBook : Binder(NumUserModules-1 downto 0) :=
    (
    0=>L1D, 1=> LTG, 2=>TGC, 3=>ROC, 4=>EBM, 5=>ASC, 6=>TMP, others=> DUMMY);

  type ChArray32 is array (integer range NumCh-1 downto 0) of std_logic_vector(31 downto 0);
  type ChArray16 is array (integer range NumCh-1 downto 0) of std_logic_vector(15 downto 0);
  type ChArray11 is array (integer range NumCh-1 downto 0) of std_logic_vector(10 downto 0);
  type ChArray10 is array (integer range NumCh-1 downto 0) of std_logic_vector( 9 downto 0);
  type ChArray8  is array (integer range NumCh-1 downto 0) of std_logic_vector( 7 downto 0);
  type ChArray4  is array (integer range NumCh-1 downto 0) of std_logic_vector( 3 downto 0);

  type BufArray32 is array (integer range NumEvtBuffer-1 downto 0) of std_logic_vector(31 downto 0);

end package AddressBook;

library ieee, work;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.AddressMap.all;

package BusSignalTypes is

  type AddressArray is array (integer range NumUserModules-1 downto 0)
    of std_logic_vector(31 downto 0);
  type DataArray is array (integer range NumUserModules-1 downto 0)
    of std_logic_vector(31 downto 0);
  type ControlRegArray is array (integer range NumUserModules-1 downto 0)
    of std_logic;
  type BusControlProcessType is (
      Initialize,
      Idle,
      GetDest,
      SetBus,
      Connect,
      WaitLocalDone,
      Done,
      AckDone);

  type BusProcessType is (
      Initialize,
      Idle,
      Write,
      Read,
      Done );
  type BusProcessTypeL1 is (
      Initialize,
      Idle,
      Wait1,
      Wait2,
      Write,
      Read,
      Done );

end package BusSignalTypes;
