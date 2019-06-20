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
use work.SpaceWireRouterIPPackage.all;
use work.SpaceWireCODECIPPackage.all;

entity fadc1440_top is
	port
	(
		OSC : in std_logic;
		
		CIN : in std_logic_vector(2 downto 0);
		COUT : out std_logic_vector(2 downto 0);

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

		ACLKA : out std_logic;
		ACLKB : out std_logic;

		LVDSin : in std_logic_vector(3 downto 0);
		LVDSout : out std_logic_vector(3 downto 0);

		TrigIn : in std_logic_vector(3 downto 0);
		TrigOut : out std_logic_vector(1 downto 0);
		
		TMP0 : out std_logic;
		TMP1 : inout std_logic_vector(0 downto 0);
		
		LED : out std_logic
	);

end fadc1440_top;

architecture ppl_type of fadc1440_top is

	--Component Difinitions--
	component clkgen PORT (
		inclk0: in std_logic;
		locked : out std_logic;
		c0: out std_logic;
		c1: out std_logic;
		c2: out std_logic;
		c3: out std_logic;
		c4: out std_logic
	);
	end component;
	component swclkgen PORT (
		inclk0: in std_logic;
		locked : out std_logic;
		c0: out std_logic; -- 50M
		c1: out std_logic; -- 100M
		c2: out std_logic -- 167M
	);
	end component;

-- FADC core
	component fadccore port (
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
	end component;

component SpaceWireRouterIP is
    generic (
        gNumberOfInternalPort : integer
        );
    port (
        clock                       : in  std_logic;
        transmitClock               : in  std_logic;
        receiveClock                : in  std_logic;
        reset                       : in  std_logic;
        -- SpaceWire Signals.
        -- Port1.
        spaceWireDataIn1            : in  std_logic;
        spaceWireStrobeIn1          : in  std_logic;
        spaceWireDataOut1           : out std_logic;
        spaceWireStrobeOut1         : out std_logic;
        -- Port2.
        spaceWireDataIn2            : in  std_logic;
        spaceWireStrobeIn2          : in  std_logic;
        spaceWireDataOut2           : out std_logic;
        spaceWireStrobeOut2         : out std_logic;
        -- Port3.
        spaceWireDataIn3            : in  std_logic;
        spaceWireStrobeIn3          : in  std_logic;
        spaceWireDataOut3           : out std_logic;
        spaceWireStrobeOut3         : out std_logic;
        -- Port4.
        spaceWireDataIn4            : in  std_logic;
        spaceWireStrobeIn4          : in  std_logic;
        spaceWireDataOut4           : out std_logic;
        spaceWireStrobeOut4         : out std_logic;
        -- Port5.
        spaceWireDataIn5            : in  std_logic;
        spaceWireStrobeIn5          : in  std_logic;
        spaceWireDataOut5           : out std_logic;
        spaceWireStrobeOut5         : out std_logic;
        -- Port6.
        spaceWireDataIn6            : in  std_logic;
        spaceWireStrobeIn6          : in  std_logic;
        spaceWireDataOut6           : out std_logic;
        spaceWireStrobeOut6         : out std_logic;
        --
        oPort0LogicalAddress        : out std_logic_vector(7 downto 0);
        --
        statisticalInformationPort1 : out bit32X8Array;
        statisticalInformationPort2 : out bit32X8Array;
        statisticalInformationPort3 : out bit32X8Array;
        statisticalInformationPort4 : out bit32X8Array;
        statisticalInformationPort5 : out bit32X8Array;
        statisticalInformationPort6 : out bit32X8Array;
        --
        oneShotStatusPort1          : out std_logic_vector(7 downto 0);
        oneShotStatusPort2          : out std_logic_vector(7 downto 0);
        oneShotStatusPort3          : out std_logic_vector(7 downto 0);
        oneShotStatusPort4          : out std_logic_vector(7 downto 0);
        oneShotStatusPort5          : out std_logic_vector(7 downto 0);
        oneShotStatusPort6          : out std_logic_vector(7 downto 0);

        busMasterUserAddressIn      : in  std_logic_vector (31 downto 0);
        busMasterUserDataOut        : out std_logic_vector (31 downto 0);
        busMasterUserDataIn         : in  std_logic_vector (31 downto 0);
        busMasterUserWriteEnableIn  : in  std_logic;
        busMasterUserByteEnableIn   : in  std_logic_vector (3 downto 0);
        busMasterUserStrobeIn       : in  std_logic;
        busMasterUserRequestIn      : in  std_logic;
        busMasterUserAcknowledgeOut : out std_logic
        );
end component;

--Signal Difinitions--
	-- Clocks and Resets
	signal Clk200, Clk40 : std_logic;
	signal clk1p0 : std_logic;
	signal SysClk: std_logic;
        signal RstFADC, RstSW : std_logic;

	signal BusClk: std_logic;
	signal CntClk : std_logic;
	signal CGENlocked : std_logic;
	signal SGENlocked : std_logic;
	-- Clocks for SpW
	signal SWRxClk: std_logic;
	signal SWTxClk: std_logic;
	signal SWClk: std_logic;
	-- LED --
	signal ToLED : std_logic;
        -- Router port
	signal DIN3, SIN3, DOUT3, SOUT3 : std_logic;
	signal DIN4, SIN4, DOUT4, SOUT4 : std_logic;
	signal DIN5, SIN5, DOUT5, SOUT5 : std_logic;
	signal DIN6, SIN6, DOUT6, SOUT6 : std_logic;
	signal StatInfo1 : bit32X8Array;
	signal StatInfo2 : bit32X8Array;
	signal StatInfo3 : bit32X8Array;
	signal StatInfo4 : bit32X8Array;
	signal StatInfo5 : bit32X8Array;
	signal StatInfo6 : bit32X8Array;
	signal OneShot1 : std_logic_vector(7 downto 0);
	signal OneShot2 : std_logic_vector(7 downto 0);
	signal OneShot3 : std_logic_vector(7 downto 0);
	signal OneShot4 : std_logic_vector(7 downto 0);
	signal OneShot5 : std_logic_vector(7 downto 0);
	signal OneShot6 : std_logic_vector(7 downto 0);
        signal busMasterUserAddressIn      : std_logic_vector (31 downto 0);
        signal busMasterUserDataOut        : std_logic_vector (31 downto 0);
        signal busMasterUserDataIn         : std_logic_vector (31 downto 0);
        signal busMasterUserWriteEnableIn  : std_logic;
        signal busMasterUserByteEnableIn   : std_logic_vector (3 downto 0);
        signal busMasterUserStrobeIn       : std_logic;
        signal busMasterUserRequestIn      : std_logic;
        signal busMasterUserAcknowledgeOut : std_logic;
        signal Port0LogicalAddress         : std_logic_vector(7 downto 0);

begin

-- BusClk should be same with SWClk.
	BusClk <= SWClk;

-- for in-house
	SysClk <= Clk40;

-- used for the timesatamp in TGC
	CntClk <= Clk200;

	CGEN : clkgen PORT MAP (
		inclk0 => OSC, -- input 10MHz
		locked => CGENlocked,
		c0 => Clk40,
		c1 => Clk200,
		c2 => Clk1p0,
		c3 => ACLKA, -- for ADC A
		c4 => ACLKB -- for ADC B
	);
	
	SGEN : swclkgen PORT MAP (
		inclk0 => Clk40,
		locked => SGENlocked,
		c0 => SWClk, -- 50MHz
		c1 => SWTxClk, -- 100MHz
		c2 => SWRxClk -- 167MHz
	);
	
-- FADC core
	ACORE : fadccore port map (
		SysClk => SysClk,
		BusClk => BusClk,
		SWRxClk => SWRxClk,
		SWTxClk => SWTxClk,
		SWClk => SWClk,
		CntClk => CntClk,
		ClkTMP => clk1p0,
		CGENlocked => CGENlocked,

		Reset => RstFADC,
--                ResetOut => ResetFromFADC,

		FCOA => FCOA,
		FCOB => FCOB,
		DCOA => DCOA,
		DCOB => DCOB,
		DINA => DINA,
		DINB => DINB,

		PDWN => PDWN,
		CSB => CSB,
		SDIO => SDIO,
		SCLK => SCLK,
		SYNC => SYNC,

                ToLED => ToLED,
		
                TrigIn => TrigIn,
                TrigOut => TrigOut,

		TSCL => TMP0,
		TSDA => TMP1,

                port0logicaladdress => port0logicaladdress,

		SpW_D_in => DOUT3,
		SpW_S_in => SOUT3,
		SpW_D_out => DIN3,
		SpW_S_out => SIN3
	);

RCORE : SpaceWireRouterIP
    generic map (
        gNumberOfInternalPort => cNumberOfInternalPort
        )
    port map (
        clock                       => SWClk,
        transmitClock               => SWTxClk,
        receiveClock                => SWRxClk,
        reset                       => RstSW,
        -- SpaceWire Signals.
        -- Port1.
        spaceWireDataIn1            => LVDSin(0),
        spaceWireStrobeIn1          => LVDSin(1),
        spaceWireDataOut1           => LVDSout(0),
        spaceWireStrobeOut1         => LVDSout(1),
        -- Port2.
        spaceWireDataIn2            => LVDSin(2),
        spaceWireStrobeIn2          => LVDSin(3),
        spaceWireDataOut2           => LVDSout(2),
        spaceWireStrobeOut2         => LVDSout(3),
        -- Port3.
        spaceWireDataIn3            => DIN3,
        spaceWireStrobeIn3          => SIN3,
        spaceWireDataOut3           => DOUT3,
        spaceWireStrobeOut3         => SOUT3,
        -- Port4.
        spaceWireDataIn4            => DIN4,
        spaceWireStrobeIn4          => SIN4,
        spaceWireDataOut4           => DOUT4,
        spaceWireStrobeOut4         => SOUT4,
        -- Port5.
        spaceWireDataIn5            => DIN5,
        spaceWireStrobeIn5          => SIN5,
        spaceWireDataOut5           => DOUT5,
        spaceWireStrobeOut5         => SOUT5,
        -- Port6.
        spaceWireDataIn6            => DIN6,
        spaceWireStrobeIn6          => SIN6,
        spaceWireDataOut6           => DOUT6,
        spaceWireStrobeOut6         => SOUT6,
        --
        oPort0LogicalAddress        => Port0LogicalAddress,
		  --
        statisticalInformationPort1 => StatInfo1,
        statisticalInformationPort2 => StatInfo2,
        statisticalInformationPort3 => StatInfo3,
        statisticalInformationPort4 => StatInfo4,
        statisticalInformationPort5 => StatInfo5,
        statisticalInformationPort6 => StatInfo6,
        --
        oneShotStatusPort1          => OneShot1,
        oneShotStatusPort2          => OneShot2,
        oneShotStatusPort3          => OneShot3,
        oneShotStatusPort4          => OneShot4,
        oneShotStatusPort5          => OneShot5,
        oneShotStatusPort6          => OneShot6,

        busMasterUserAddressIn      => busMasterUserAddressIn,
        busMasterUserDataOut        => busMasterUserDataOut,
        busMasterUserDataIn         => busMasterUserDataIn,
        busMasterUserWriteEnableIn  => busMasterUserWriteEnableIn,
        busMasterUserByteEnableIn   => busMasterUserByteEnableIn,
        busMasterUserStrobeIn       => busMasterUserStrobeIn,
        busMasterUserRequestIn      => busMasterUserRequestIn,
        busMasterUserAcknowledgeOut => busMasterUserAcknowledgeOut
        );

	DIN4 <= '0'; SIN4 <= '0';
	DIN5 <= '0'; SIN5 <= '0';
	DIN6 <= '0'; SIN6 <= '0';

--	LED <= not LBsy;
        LED <= not ToLED;

	RstFADC <= not (CGENlocked and SGENlocked);
	RstSW <= not (SGENlocked);
	
--	COUT <= CIN;
	COUT <= (others=>'0');
	
        busMasterUserAddressIn      <= x"00000000";
--        busMasterUserDataOut        <= busMasterUserDataOut;
        busMasterUserDataIn         <= x"00000000";
        busMasterUserWriteEnableIn  <= '0';
        busMasterUserByteEnableIn   <= "0000";
        busMasterUserStrobeIn       <= '0';
        busMasterUserRequestIn      <= '0';
--        busMasterUserAcknowledgeOut <= busMasterUserAcknowledgeOut;

end;
