-- Copyright (C) 1991-2011 Altera Corporation
-- Your use of Altera Corporation's design tools, logic functions 
-- and other software and tools, and its AMPP partner logic 
-- functions, and any output files from any of the foregoing 
-- (including device programming or simulation files), and any 
-- associated documentation or information are expressly subject 
-- to the terms and conditions of the Altera Program License 
-- Subscription Agreement, Altera MegaCore Function License 
-- Agreement, or other applicable license agreement, including, 
-- without limitation, that your use is for the sole purpose of 
-- programming logic devices manufactured by Altera and sold by 
-- Altera or its authorized distributors.  Please refer to the 
-- applicable agreement for further details.

-- 2012/12/18 S. Ajimura: Base structure, RS232C OK, SpW OK, ASC OK
-- 2014/03/14 S. Ajimura: Base for ASIC-FADC v1

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
library altera;
use altera.altera_syn_attributes.all;
library work;
use work.AddressMap.all;
use work.AddressBook.all;
use work.BusSignalTypes.all;

entity fadccore is
  port
    (
      SysClk : in std_logic;
      BusClk : in std_logic;
      SWRxClk : in std_logic;
      SWTxClk : in std_logic;
      SWClk : in std_logic;
      CntClk : in std_logic;
      ClkTMP : in std_logic;
      CGENlocked : in std_logic;

      Reset : in std_logic;
--                ResetOut : out std_logic;

      FCOA : in std_logic;
      FCOB : in std_logic;
      DCOA : in std_logic;
      DCOB : in std_logic;
      DINA : in std_logic_vector(7 downto 0);
      DINB : in std_logic_vector(7 downto 0);

      PDWN : out std_logic_vector(1 downto 0);
      CSB : out std_logic_vector(1 downto 0);
      SDIO : inout std_logic_vector(1 downto 0);
      SCLK : out std_logic_vector(1 downto 0);
      SYNC : out std_logic_vector(1 downto 0);

      ToLED : out std_logic;
		
      TrigIn : in std_logic_vector(3 downto 0);
      TrigOut : out std_logic_vector(1 downto 0);

      TSCL : out std_logic;
      TSDA : inout std_logic_vector(0 downto 0);

      port0logicaladdress : in std_logic_vector(7 downto 0);

      SpW_D_in : in std_logic;
      SpW_S_in : in std_logic;
      SpW_D_out : out std_logic;
      SpW_S_out : out std_logic
      );

end fadccore;

architecture ppl_type of fadccore is

-- DRS --
  component ADCReceiver port (
    Clock : in std_logic;
    nClk : in std_logic;
    Reset : in std_logic;
    DataInA : in std_logic_vector(7 downto 0);
    DataInB : in std_logic_vector(7 downto 0);
    FCOA : in std_logic;
    FCOB : in std_logic;
    DCOA : in std_logic;
    DCOB : in std_logic;
    DataOut : out std_logic_vector(223 downto 0)
    );
  end component;
-- L1D --
  component L1_Delay PORT (
    Clock: in std_logic;
    BusClk : in std_logic;
    Reset: in std_logic;
    RstSoftS: in std_logic;
    RstSoftH: in std_logic;
    DataIn: in std_logic_vector(223 downto 0);
    DelayOut: out std_logic_vector(223 downto 0);
    LocalBusAddress : in std_logic_vector(31 downto 0);
    LocalBusDataIn : in std_logic_vector(31 downto 0);
    LocalBusDataOut : out std_logic_vector(31 downto 0);
    LocalBusRS : in std_logic;
    LocalBusWS : in std_logic;
    LocalBusRDY : out std_logic
    );
  end component;
-- LTG --
--	component LocalTrigger port(
--		Clock : in std_logic;
--		BusClk : in std_logic;
--		Reset : in std_logic;
--		DataIn : in std_logic_vector(223 downto 0);
--		TriggerOut : out std_logic;
--		LocalBusAddress : in std_logic_vector(31 downto 0);
--		LocalBusDataIn : in std_logic_vector(31 downto 0);
--		LocalBusDataOut : out std_logic_vector(31 downto 0);
--		LocalBusRS : in std_logic;
--		LocalBusWS : in std_logic;
--		LocalBusRDY : out std_logic
--	);
--	end component;
-- TGC --
  component TriggerController port(
    Clock : in std_logic;
    BusClk : in std_logic;
    CntClk : in std_logic;
    ResetIn : in std_logic;
    ResetTGC : out std_logic;
    RstBCTS : in std_logic;
    RstBCTH : in std_logic;
    BufferFree : in std_logic_vector(NumEvtBuffer-1 downto 0);
    BufferStart : out std_logic_vector(NumEvtBuffer-1 downto 0);
    ReadReady : in std_logic_vector(NumEvtBuffer-1 downto 0);
    ToLED : out std_logic;
    TrigIn : in std_logic_vector(3 downto 0);
    TrigOut : out std_logic_vector(1 downto 0);
    LocalBusAddress : in std_logic_vector(31 downto 0);
    LocalBusDataIn : in std_logic_vector(31 downto 0);
    LocalBusDataOut : out std_logic_vector(31 downto 0);
    LocalBusRS : in std_logic;
    LocalBusWS : in std_logic;
    LocalBusRDY : out std_logic
    );
  end component;
-- ROC --
  component ReadOutController port(
    Clock : in std_logic;
    BusClk : in std_logic;
    Reset : in std_logic;
    RstSoftS: in std_logic;
    RstSoftH: in std_logic;
    ReadReady : in std_logic_vector(NumEvtBuffer-1 downto 0);
    ReadDone : out std_logic_vector(NumEvtBuffer-1 downto 0);
    LocalBusAddress : in std_logic_vector(31 downto 0);
    LocalBusDataIn : in std_logic_vector(31 downto 0);
    LocalBusDataOut : out std_logic_vector(31 downto 0);
    LocalBusRS : in std_logic;
    LocalBusWS : in std_logic;
    LocalBusRDY : out std_logic
    );
  end component;
-- EBM --
  component EventBuffer port(
    Clock : in std_logic;
    BusClk : in std_logic;
    Reset : in std_logic;
    RstSoftS: in std_logic;
    RstSoftH: in std_logic;
    DataIn : in std_logic_vector(223 downto 0);
    BufferStart : in std_logic_vector(NumEvtBuffer-1 downto 0);
    BufferFree : out std_logic_vector(NumEvtBuffer-1 downto 0);
    ReadDone : in std_logic_vector(NumEvtBuffer-1 downto 0);
    ReadReady : out std_logic_vector(NumEvtBuffer-1 downto 0);
    LocalBusAddress : in std_logic_vector(31 downto 0);
    LocalBusDataIn : in std_logic_vector(31 downto 0);
    LocalBusDataOut : out std_logic_vector(31 downto 0);
    LocalBusRS : in std_logic;
    LocalBusWS : in std_logic;
    LocalBusRDY : out std_logic
    );
  end component;
-- BCT --
  component BusController port(
    Clock : in std_logic;
    Reset : in std_logic;
    ResetOutS : out std_logic;
    ResetOutH : out std_logic;
    RstTGC : in std_logic;
    -- Local Bus
    LocalBusAddress : out std_logic_vector(31 downto 0);
    LocalBusDataFromUserModules : in DataArray;
    LocalBusDataToUserModules : out std_logic_vector(31 downto 0);
    LocalBusRS : out std_logic_vector(NumUserModules-1 downto 0);
    LocalBusWS : out std_logic_vector(NumUserModules-1 downto 0);
    LocalBusRDY : in std_logic_vector(NumUserModules-1 downto 0);
    -- SpaceWire I/O
    port0logicaladdress : in std_logic_vector(7 downto 0);
    SpW_D_in: in std_logic;
    SpW_S_in: in std_logic;
    SpW_D_out: out std_logic;
    SpW_S_out: out std_logic;
    -- Clocks for SpW
    SWRxClk: in std_logic;
    SWTxClk: in std_logic;
    SWClk: in std_logic
    );
  end component;	
---- ASC --
  component ADCController port(
    Clock : in std_logic;
    BusClk : in std_logic;
    Reset : in std_logic;
    PDWN : out std_logic_vector(1 downto 0);
    CSB : out std_logic_vector(1 downto 0); -- active low
    SDIO : inout std_logic_vector(1 downto 0);
    SCLK : out std_logic_vector(1 downto 0);
    SYNC : out std_logic_vector(1 downto 0);
    ClkEnab : out std_logic;
    LocalBusAddress : in std_logic_vector(31 downto 0);
    LocalBusDataIn : in std_logic_vector(31 downto 0);
    LocalBusDataOut : out std_logic_vector(31 downto 0);
    LocalBusRS : in  std_logic;
    LocalBusWS : in  std_logic;
    LocalBusRDY : out std_logic
    );
  end component;
  
  component TMPController port(
    Clock : in std_logic; -- SysClock(4MHz)
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
  end component;
  
--Signal Difinitions--
  -- Clocks and Resets
  signal SysRst : std_logic;
  signal RstSoftS, RstSoftH : std_logic;
  signal RstTGC, RstBCTS, RstBCTH : std_logic;
  signal ClkEnab : std_logic;
  --  signal ADClk: std_logic;
  signal PreData: std_logic_vector(223 downto 0);
  signal RawData: std_logic_vector(223 downto 0);
  signal PromptData: std_logic_vector(223 downto 0);
  signal DelData: std_logic_vector(223 downto 0);
--	signal SerDesOClkA, SerDesOClkB: std_logic;
--	signal SerDesAlign, SerDesAlign_reg : std_logic := '0';
  -- Trigger --
  signal LTrigger : std_logic;
  -- Trigger Control
  signal BufferFree : std_logic_vector(NumEvtBuffer-1 downto 0);
  signal BufferStart : std_logic_vector(NumEvtBuffer-1 downto 0);
  signal Busy: std_logic;
  -- Readout Control
  signal ReadReady : std_logic_vector(NumEvtBuffer-1 downto 0);
  signal ReadDone : std_logic_vector(NumEvtBuffer-1 downto 0);
  -- Local Bus
  signal LocalBusAddress : std_logic_vector(31 downto 0);
  signal LocalBusDataIn : std_logic_vector(31 downto 0);
  signal LocalBusDataOut : DataArray;
  signal LocalBusRS : std_logic_vector(NumUserModules-1 downto 0);
  signal LocalBusWS : std_logic_vector(NumUserModules-1 downto 0);
  signal LocalBusRDY : std_logic_vector(NumUserModules-1 downto 0);

begin

-- Reset
--	SysRst <= Reset or RstTGC or RstBct;
--	Rst2BCT <= Reset or RstTGC;
--	Rst2TGC <= Reset or RstBCT;
--        ResetOut <= RstTGC;
  SysRst <= Reset;
  RstSoftS <= RstTGC or RstBCTS;
  RstSoftH <= RstBCTH;
--  RstSoftS <= '0';
--  RstSoftH <= '0';

  DRS : ADCReceiver port map (
    Clock => SysClk,
    nClk => (not SysClk),
    Reset => (not CGENlocked), --Reset,
    DataInA => DINA,
    DataInB => DINB,
    FCOA => FCOA,
    FCOB => FCOB,
    DCOA => DCOA,
    DCOB => DCOB,
    DataOut => PreData
    );
  
  -- sync with SysClk
--  process (SysRST, SysClk)
--  begin
--    if (SysClk'event and SysClk='1') then
      RawData <= PreData;
--    end if;
--  end process;
	
  comL1D : L1_Delay PORT MAP (
    Clock => SysClk,
    BusClk => BusClk,
    Reset => SysRST,
    RstSoftS => RstSoftS,
    RstSoftH => RstSoftH,
    DataIn => RawData,
    DelayOut => DelData,
    LocalBusAddress => LocalBusAddress,
    LocalBusDataIn => LocalBusDataIn,
    LocalBusDataOut => LocalBusDataOut(L1D.ID),
    LocalBusRS => LocalBusRS(L1D.ID),
    LocalBusWS => LocalBusWS(L1D.ID),
    LocalBusRDY => LocalBusRDY(L1D.ID)
    );

--	comLTG : LocalTrigger port map(
--		Clock => SysClk,
--		BusClk => BusClk,
--		Reset => SysRST,
--		DataIn => RawData,
--		TriggerOut => LTrigger,
--		LocalBusAddress => LocalBusAddress,
--		LocalBusDataIn => LocalBusDataIn,
--		LocalBusDataOut => LocalBusDataOut( LTG.ID ),
--		LocalBusRS => LocalBusRS( LTG.ID ),
--		LocalBusWS => LocalBusWS( LTG.ID ),
--		LocalBusRDY => LocalBusRDY( LTG.ID ) 
--	);

  comTGC : TriggerController port map(
    Clock => SysClk,
    BusClk => BusClk,
    CntClk => CntClk,
    ResetIn => SysRst,
    ResetTGC => RstTGC,
    RstBCTS => RstBCTS,
    RstBCTH => RstBCTH,
    BufferFree => BufferFree,
    BufferStart => BufferStart,
    ReadReady => ReadReady,
    ToLED => ToLED,
    TrigIn => TrigIn,
    TrigOut => TrigOut,
    LocalBusAddress => LocalBusAddress,
    LocalBusDataIn => LocalBusDataIn,
    LocalBusDataOut => LocalBusDataOut( TGC.ID ),
    LocalBusRS => LocalBusRS( TGC.ID ),
    LocalBusWS => LocalBusWS( TGC.ID ),
    LocalBusRDY => LocalBusRDY( TGC.ID ) 
    );

  comROC : ReadOutController port map(
    Clock => SysClk,
    BusClk => BusClk,
    Reset => SysRST,
    RstSoftS => RstSoftS,
    RstSoftH => RstSoftH,
    ReadReady => ReadReady,
    ReadDone => ReadDone,
    LocalBusAddress => LocalBusAddress,
    LocalBusDataIn => LocalBusDataIn,
    LocalBusDataOut => LocalBusDataOut( ROC.ID ),
    LocalBusRS => LocalBusRS( ROC.ID ),
    LocalBusWS => LocalBusWS( ROC.ID ),
    LocalBusRDY => LocalBusRDY( ROC.ID ) 
    );

  comEBMintf : EventBuffer port map(
    Clock => SysClk,
    BusClk => BusClk,
    Reset => SysRST,
    RstSoftS => RstSoftS,
    RstSoftH => RstSoftH,
    DataIn => DelData,
    BufferStart => BufferStart,
    BufferFree => BufferFree,
    ReadDone => ReadDone,
    ReadReady => ReadReady,
    LocalBusAddress => LocalBusAddress,
    LocalBusDataIn => LocalBusDataIn,
    LocalBusDataOut => LocalBusDataOut( EBM.ID ),
    LocalBusRS => LocalBusRS( EBM.ID ),
    LocalBusWS => LocalBusWS( EBM.ID ),
    LocalBusRDY => LocalBusRDY( EBM.ID ) 
    );
  
  comBCT : BusController port map (
    Clock => BusClk,
    Reset => SysRst,
    ResetOutS => RstBCTS,
    ResetOutH => RstBCTH,
    RstTGC => RstTGC,
    -- Local Bus
    LocalBusAddress => LocalBusAddress,
    LocalBusDataFromUserModules => LocalBusDataOut( NumUserModules-1 downto 0 ),
    LocalBusDataToUserModules  => LocalBusDataIn,
    LocalBusRS => LocalBusRS( NumUserModules-1 downto 0 ),
    LocalBusWS => LocalBusWS( NumUserModules-1 downto 0 ),
    LocalBusRDY => LocalBusRDY( NumUserModules-1 downto 0 ),
    port0logicaladdress => port0logicaladdress,
    SpW_D_in => SpW_D_in,
    SpW_S_in => SpW_S_in,
    SpW_D_out => SpW_D_out,
    SpW_S_out => SpW_S_out,
    SWRxClk => SWRxClk,
    SWTxClk => SWTxClk,
    SWClk => SWClk
    );
--	ResetTGC <= Reset2BCT;

  comASC : ADCController port map(
    Clock => SysClk,
    BusClk => BusClk,
    Reset => SysRST,
    PDWN => PDWN,
    CSB => CSB, -- active low
    SDIO => SDIO, -- from ADC
    SCLK => SCLK,
    SYNC => SYNC,
    ClkEnab => ClkEnab,
    LocalBusAddress => LocalBusAddress,
    LocalBusDataIn => LocalBusDataIn,
    LocalBusDataOut => LocalBusDataOut( ASC.ID ),
    LocalBusRS => LocalBusRS( ASC.ID ),
    LocalBusWS => LocalBusWS( ASC.ID ),
    LocalBusRDY => LocalBusRDY( ASC.ID ) 
    );
	
  comTMP : TMPController port map(
    Clock => ClkTMP,
    BusClk => BusClk,
    Reset => SysRST,
    SCL => TSCL,
    SDA => TSDA,
    LocalBusAddress => LocalBusAddress,
    LocalBusDataIn => LocalBusDataIn,
    LocalBusDataOut => LocalBusDataOut( TMP.ID ),
    LocalBusRS => LocalBusRS( TMP.ID ),
    LocalBusWS => LocalBusWS( TMP.ID ),
    LocalBusRDY => LocalBusRDY( TMP.ID ) 
    );		

end;
