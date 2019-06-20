//altlvds_rx BUFFER_IMPLEMENTATION="RAM" CBX_DECLARE_ALL_CONNECTED_PORTS="OFF" COMMON_RX_TX_PLL="OFF" CYCLONEII_M4K_COMPATIBILITY="ON" DATA_ALIGN_ROLLOVER=4 DATA_RATE="560.0 Mbps" DESERIALIZATION_FACTOR=14 DEVICE_FAMILY="Cyclone IV E" DPA_INITIAL_PHASE_VALUE=0 DPLL_LOCK_COUNT=0 DPLL_LOCK_WINDOW=0 ENABLE_DPA_ALIGN_TO_RISING_EDGE_ONLY="OFF" ENABLE_DPA_CALIBRATION="ON" ENABLE_DPA_INITIAL_PHASE_SELECTION="OFF" ENABLE_DPA_MODE="OFF" ENABLE_DPA_PLL_CALIBRATION="OFF" ENABLE_SOFT_CDR_MODE="OFF" IMPLEMENT_IN_LES="ON" INCLOCK_BOOST=0 INCLOCK_DATA_ALIGNMENT="EDGE_ALIGNED" INCLOCK_PERIOD=25000 INCLOCK_PHASE_SHIFT=0 INPUT_DATA_RATE=560 NUMBER_OF_CHANNELS=8 OUTCLOCK_RESOURCE="AUTO" PLL_SELF_RESET_ON_LOSS_LOCK="OFF" PORT_RX_CHANNEL_DATA_ALIGN="PORT_UNUSED" PORT_RX_DATA_ALIGN="PORT_UNUSED" REGISTERED_OUTPUT="ON" SIM_DPA_IS_NEGATIVE_PPM_DRIFT="OFF" SIM_DPA_NET_PPM_VARIATION=0 SIM_DPA_OUTPUT_CLOCK_PHASE_SHIFT=0 USE_CORECLOCK_INPUT="OFF" USE_DPLL_RAWPERROR="OFF" USE_EXTERNAL_PLL="OFF" USE_NO_PHASE_SHIFT="ON" X_ON_BITSLIP="ON" pll_areset rx_in rx_inclock rx_out rx_outclock CARRY_CHAIN="MANUAL" CARRY_CHAIN_LENGTH=48 LOW_POWER_MODE="AUTO" ALTERA_INTERNAL_OPTIONS=AUTO_SHIFT_REGISTER_RECOGNITION=OFF
//VERSION_BEGIN 18.1 cbx_altaccumulate 2019:04:11:16:04:12:SJ cbx_altclkbuf 2019:04:11:16:04:12:SJ cbx_altddio_in 2019:04:11:16:04:12:SJ cbx_altddio_out 2019:04:11:16:04:12:SJ cbx_altera_syncram_nd_impl 2019:04:11:16:04:12:SJ cbx_altiobuf_bidir 2019:04:11:16:04:12:SJ cbx_altiobuf_in 2019:04:11:16:04:12:SJ cbx_altiobuf_out 2019:04:11:16:04:12:SJ cbx_altlvds_rx 2019:04:11:16:04:12:SJ cbx_altpll 2019:04:11:16:04:12:SJ cbx_altsyncram 2019:04:11:16:04:12:SJ cbx_arriav 2019:04:11:16:04:11:SJ cbx_cyclone 2019:04:11:16:04:12:SJ cbx_cycloneii 2019:04:11:16:04:12:SJ cbx_lpm_add_sub 2019:04:11:16:04:12:SJ cbx_lpm_compare 2019:04:11:16:04:12:SJ cbx_lpm_counter 2019:04:11:16:04:12:SJ cbx_lpm_decode 2019:04:11:16:04:12:SJ cbx_lpm_mux 2019:04:11:16:04:12:SJ cbx_lpm_shiftreg 2019:04:11:16:04:12:SJ cbx_maxii 2019:04:11:16:04:12:SJ cbx_mgl 2019:04:11:16:07:46:SJ cbx_nadder 2019:04:11:16:04:12:SJ cbx_stratix 2019:04:11:16:04:12:SJ cbx_stratixii 2019:04:11:16:04:12:SJ cbx_stratixiii 2019:04:11:16:04:12:SJ cbx_stratixv 2019:04:11:16:04:12:SJ cbx_util_mgl 2019:04:11:16:04:12:SJ  VERSION_END
//CBXI_INSTANCE_NAME="fadc1440_top_fadccore_ACORE_ADCReceiver_DRS_desconv_DRSA_altlvds_rx_ALTLVDS_RX_component"
// synthesis VERILOG_INPUT_VERSION VERILOG_2001
// altera message_off 10463



// Copyright (C) 2019  Intel Corporation. All rights reserved.
//  Your use of Intel Corporation's design tools, logic functions 
//  and other software and tools, and any partner logic 
//  functions, and any output files from any of the foregoing 
//  (including device programming or simulation files), and any 
//  associated documentation or information are expressly subject 
//  to the terms and conditions of the Intel Program License 
//  Subscription Agreement, the Intel Quartus Prime License Agreement,
//  the Intel FPGA IP License Agreement, or other applicable license
//  agreement, including, without limitation, that your use is for
//  the sole purpose of programming logic devices manufactured by
//  Intel and sold by Intel or its authorized distributors.  Please
//  refer to the applicable agreement for further details, at
//  https://fpgasoftware.intel.com/eula.




//alt_lvds_ddio_in ADD_LATENCY_REG="TRUE" CBX_DECLARE_ALL_CONNECTED_PORTS="OFF" WIDTH=8 aclr clock datain dataout_h dataout_l
//VERSION_BEGIN 18.1 cbx_altaccumulate 2019:04:11:16:04:12:SJ cbx_altclkbuf 2019:04:11:16:04:12:SJ cbx_altddio_in 2019:04:11:16:04:12:SJ cbx_altddio_out 2019:04:11:16:04:12:SJ cbx_altera_syncram_nd_impl 2019:04:11:16:04:12:SJ cbx_altiobuf_bidir 2019:04:11:16:04:12:SJ cbx_altiobuf_in 2019:04:11:16:04:12:SJ cbx_altiobuf_out 2019:04:11:16:04:12:SJ cbx_altlvds_rx 2019:04:11:16:04:12:SJ cbx_altpll 2019:04:11:16:04:12:SJ cbx_altsyncram 2019:04:11:16:04:12:SJ cbx_arriav 2019:04:11:16:04:11:SJ cbx_cyclone 2019:04:11:16:04:12:SJ cbx_cycloneii 2019:04:11:16:04:12:SJ cbx_lpm_add_sub 2019:04:11:16:04:12:SJ cbx_lpm_compare 2019:04:11:16:04:12:SJ cbx_lpm_counter 2019:04:11:16:04:12:SJ cbx_lpm_decode 2019:04:11:16:04:12:SJ cbx_lpm_mux 2019:04:11:16:04:12:SJ cbx_lpm_shiftreg 2019:04:11:16:04:12:SJ cbx_maxii 2019:04:11:16:04:12:SJ cbx_mgl 2019:04:11:16:07:46:SJ cbx_nadder 2019:04:11:16:04:12:SJ cbx_stratix 2019:04:11:16:04:12:SJ cbx_stratixii 2019:04:11:16:04:12:SJ cbx_stratixiii 2019:04:11:16:04:12:SJ cbx_stratixv 2019:04:11:16:04:12:SJ cbx_util_mgl 2019:04:11:16:04:12:SJ  VERSION_END

//synthesis_resources = reg 40 
//synopsys translate_off
`timescale 1 ps / 1 ps
//synopsys translate_on
(* ALTERA_ATTRIBUTE = {"{-to ddio_h_reg*} PLL_COMPENSATE=ON;ADV_NETLIST_OPT_ALLOWED=\"NEVER_ALLOW\""} *)
module  desconv_lvds_ddio_in
	( 
	aclr,
	clock,
	datain,
	dataout_h,
	dataout_l) /* synthesis synthesis_clearbox=1 */;
	input   aclr;
	input   clock;
	input   [7:0]  datain;
	output   [7:0]  dataout_h;
	output   [7:0]  dataout_l;
`ifndef ALTERA_RESERVED_QIS
// synopsys translate_off
`endif
	tri0   aclr;
`ifndef ALTERA_RESERVED_QIS
// synopsys translate_on
`endif

	reg	[7:0]	dataout_h_reg;
	reg	[7:0]	dataout_l_latch;
	reg	[7:0]	dataout_l_reg;
	(* ALTERA_ATTRIBUTE = {"LVDS_RX_REGISTER=HIGH;PRESERVE_REGISTER=ON;PRESERVE_FANOUT_FREE_NODE=ON"} *)
	reg	[7:0]	ddio_h_reg;
	(* ALTERA_ATTRIBUTE = {"LVDS_RX_REGISTER=LOW;PRESERVE_REGISTER=ON;PRESERVE_FANOUT_FREE_NODE=ON"} *)
	reg	[7:0]	ddio_l_reg;

	// synopsys translate_off
	initial
		dataout_h_reg = 0;
	// synopsys translate_on
	always @ ( posedge clock or  posedge aclr)
		if (aclr == 1'b1) dataout_h_reg <= 8'b0;
		else  dataout_h_reg <= ddio_h_reg;
	// synopsys translate_off
	initial
		dataout_l_latch = 0;
	// synopsys translate_on
	always @ ( negedge clock or  posedge aclr)
		if (aclr == 1'b1) dataout_l_latch <= 8'b0;
		else  dataout_l_latch <= ddio_l_reg;
	// synopsys translate_off
	initial
		dataout_l_reg = 0;
	// synopsys translate_on
	always @ ( posedge clock or  posedge aclr)
		if (aclr == 1'b1) dataout_l_reg <= 8'b0;
		else  dataout_l_reg <= dataout_l_latch;
	// synopsys translate_off
	initial
		ddio_h_reg = 0;
	// synopsys translate_on
	always @ ( posedge clock or  posedge aclr)
		if (aclr == 1'b1) ddio_h_reg <= 8'b0;
		else  ddio_h_reg <= datain;
	// synopsys translate_off
	initial
		ddio_l_reg = 0;
	// synopsys translate_on
	always @ ( negedge clock or  posedge aclr)
		if (aclr == 1'b1) ddio_l_reg <= 8'b0;
		else  ddio_l_reg <= datain;
	assign
		dataout_h = dataout_l_reg,
		dataout_l = dataout_h_reg;
endmodule //desconv_lvds_ddio_in


//dffpipe CBX_DECLARE_ALL_CONNECTED_PORTS="OFF" DELAY=4 WIDTH=8 clock clrn d q ALTERA_INTERNAL_OPTIONS=AUTO_SHIFT_REGISTER_RECOGNITION=OFF
//VERSION_BEGIN 18.1 cbx_mgl 2019:04:11:16:07:46:SJ cbx_stratixii 2019:04:11:16:04:12:SJ cbx_util_mgl 2019:04:11:16:04:12:SJ  VERSION_END

//synthesis_resources = reg 32 
//synopsys translate_off
`timescale 1 ps / 1 ps
//synopsys translate_on
(* ALTERA_ATTRIBUTE = {"AUTO_SHIFT_REGISTER_RECOGNITION=OFF"} *)
module  desconv_dffpipe
	( 
	clock,
	clrn,
	d,
	q) /* synthesis synthesis_clearbox=1 */;
	input   clock;
	input   clrn;
	input   [7:0]  d;
	output   [7:0]  q;
`ifndef ALTERA_RESERVED_QIS
// synopsys translate_off
`endif
	tri0   clock;
	tri1   clrn;
`ifndef ALTERA_RESERVED_QIS
// synopsys translate_on
`endif

	reg	[7:0]	dffe17a;
	reg	[7:0]	dffe18a;
	reg	[7:0]	dffe19a;
	reg	[7:0]	dffe20a;
	wire ena;
	wire prn;
	wire sclr;

	// synopsys translate_off
	initial
		dffe17a = 0;
	// synopsys translate_on
	always @ ( posedge clock or  negedge prn or  negedge clrn)
		if (prn == 1'b0) dffe17a <= {8{1'b1}};
		else if (clrn == 1'b0) dffe17a <= 8'b0;
		else if  (ena == 1'b1)   dffe17a <= (d & {8{(~ sclr)}});
	// synopsys translate_off
	initial
		dffe18a = 0;
	// synopsys translate_on
	always @ ( posedge clock or  negedge prn or  negedge clrn)
		if (prn == 1'b0) dffe18a <= {8{1'b1}};
		else if (clrn == 1'b0) dffe18a <= 8'b0;
		else if  (ena == 1'b1)   dffe18a <= (dffe17a & {8{(~ sclr)}});
	// synopsys translate_off
	initial
		dffe19a = 0;
	// synopsys translate_on
	always @ ( posedge clock or  negedge prn or  negedge clrn)
		if (prn == 1'b0) dffe19a <= {8{1'b1}};
		else if (clrn == 1'b0) dffe19a <= 8'b0;
		else if  (ena == 1'b1)   dffe19a <= (dffe18a & {8{(~ sclr)}});
	// synopsys translate_off
	initial
		dffe20a = 0;
	// synopsys translate_on
	always @ ( posedge clock or  negedge prn or  negedge clrn)
		if (prn == 1'b0) dffe20a <= {8{1'b1}};
		else if (clrn == 1'b0) dffe20a <= 8'b0;
		else if  (ena == 1'b1)   dffe20a <= (dffe19a & {8{(~ sclr)}});
	assign
		ena = 1'b1,
		prn = 1'b1,
		q = dffe20a,
		sclr = 1'b0;
endmodule //desconv_dffpipe

//synthesis_resources = cycloneive_pll 1 reg 328 
//synopsys translate_off
`timescale 1 ps / 1 ps
//synopsys translate_on
(* ALTERA_ATTRIBUTE = {"AUTO_SHIFT_REGISTER_RECOGNITION=OFF;{-to lvds_rx_pll} AUTO_MERGE_PLLS=OFF"} *)
module  desconv_lvds_rx
	( 
	pll_areset,
	rx_in,
	rx_inclock,
	rx_out,
	rx_outclock) /* synthesis synthesis_clearbox=1 */;
	input   pll_areset;
	input   [7:0]  rx_in;
	input   rx_inclock;
	output   [111:0]  rx_out;
	output   rx_outclock;
`ifndef ALTERA_RESERVED_QIS
// synopsys translate_off
`endif
	tri0   pll_areset;
`ifndef ALTERA_RESERVED_QIS
// synopsys translate_on
`endif

	wire  [7:0]   wire_ddio_in_dataout_h;
	wire  [7:0]   wire_ddio_in_dataout_l;
	reg	[6:0]	h_shiftreg10a;
	reg	[6:0]	h_shiftreg12a;
	reg	[6:0]	h_shiftreg14a;
	reg	[6:0]	h_shiftreg16a;
	reg	[6:0]	h_shiftreg2a;
	reg	[6:0]	h_shiftreg4a;
	reg	[6:0]	h_shiftreg6a;
	reg	[6:0]	h_shiftreg8a;
	reg	[6:0]	l_shiftreg11a;
	reg	[6:0]	l_shiftreg13a;
	reg	[6:0]	l_shiftreg15a;
	reg	[6:0]	l_shiftreg1a;
	reg	[6:0]	l_shiftreg3a;
	reg	[6:0]	l_shiftreg5a;
	reg	[6:0]	l_shiftreg7a;
	reg	[6:0]	l_shiftreg9a;
	reg	[111:0]	rx_reg;
	wire  [7:0]   wire_h_dffpipe_q;
	wire  [7:0]   wire_l_dffpipe_q;
	wire  [4:0]   wire_lvds_rx_pll_clk;
	wire  wire_lvds_rx_pll_fbout;
	wire  [7:0]  ddio_dataout_h;
	wire  [7:0]  ddio_dataout_h_int;
	wire  [7:0]  ddio_dataout_l;
	wire  [7:0]  ddio_dataout_l_int;
	wire  fast_clock;
	wire  [111:0]  rx_out_wire;
	wire  slow_clock;
	wire  w_reset;

	desconv_lvds_ddio_in   ddio_in
	( 
	.aclr(w_reset),
	.clock(fast_clock),
	.datain(rx_in),
	.dataout_h(wire_ddio_in_dataout_h),
	.dataout_l(wire_ddio_in_dataout_l));
	// synopsys translate_off
	initial
		h_shiftreg10a = 0;
	// synopsys translate_on
	always @ ( posedge fast_clock or  posedge w_reset)
		if (w_reset == 1'b1) h_shiftreg10a <= 7'b0;
		else  h_shiftreg10a <= {h_shiftreg10a[5:0], ddio_dataout_l[4]};
	// synopsys translate_off
	initial
		h_shiftreg12a = 0;
	// synopsys translate_on
	always @ ( posedge fast_clock or  posedge w_reset)
		if (w_reset == 1'b1) h_shiftreg12a <= 7'b0;
		else  h_shiftreg12a <= {h_shiftreg12a[5:0], ddio_dataout_l[5]};
	// synopsys translate_off
	initial
		h_shiftreg14a = 0;
	// synopsys translate_on
	always @ ( posedge fast_clock or  posedge w_reset)
		if (w_reset == 1'b1) h_shiftreg14a <= 7'b0;
		else  h_shiftreg14a <= {h_shiftreg14a[5:0], ddio_dataout_l[6]};
	// synopsys translate_off
	initial
		h_shiftreg16a = 0;
	// synopsys translate_on
	always @ ( posedge fast_clock or  posedge w_reset)
		if (w_reset == 1'b1) h_shiftreg16a <= 7'b0;
		else  h_shiftreg16a <= {h_shiftreg16a[5:0], ddio_dataout_l[7]};
	// synopsys translate_off
	initial
		h_shiftreg2a = 0;
	// synopsys translate_on
	always @ ( posedge fast_clock or  posedge w_reset)
		if (w_reset == 1'b1) h_shiftreg2a <= 7'b0;
		else  h_shiftreg2a <= {h_shiftreg2a[5:0], ddio_dataout_l[0]};
	// synopsys translate_off
	initial
		h_shiftreg4a = 0;
	// synopsys translate_on
	always @ ( posedge fast_clock or  posedge w_reset)
		if (w_reset == 1'b1) h_shiftreg4a <= 7'b0;
		else  h_shiftreg4a <= {h_shiftreg4a[5:0], ddio_dataout_l[1]};
	// synopsys translate_off
	initial
		h_shiftreg6a = 0;
	// synopsys translate_on
	always @ ( posedge fast_clock or  posedge w_reset)
		if (w_reset == 1'b1) h_shiftreg6a <= 7'b0;
		else  h_shiftreg6a <= {h_shiftreg6a[5:0], ddio_dataout_l[2]};
	// synopsys translate_off
	initial
		h_shiftreg8a = 0;
	// synopsys translate_on
	always @ ( posedge fast_clock or  posedge w_reset)
		if (w_reset == 1'b1) h_shiftreg8a <= 7'b0;
		else  h_shiftreg8a <= {h_shiftreg8a[5:0], ddio_dataout_l[3]};
	// synopsys translate_off
	initial
		l_shiftreg11a = 0;
	// synopsys translate_on
	always @ ( posedge fast_clock or  posedge w_reset)
		if (w_reset == 1'b1) l_shiftreg11a <= 7'b0;
		else  l_shiftreg11a <= {l_shiftreg11a[5:0], ddio_dataout_h[5]};
	// synopsys translate_off
	initial
		l_shiftreg13a = 0;
	// synopsys translate_on
	always @ ( posedge fast_clock or  posedge w_reset)
		if (w_reset == 1'b1) l_shiftreg13a <= 7'b0;
		else  l_shiftreg13a <= {l_shiftreg13a[5:0], ddio_dataout_h[6]};
	// synopsys translate_off
	initial
		l_shiftreg15a = 0;
	// synopsys translate_on
	always @ ( posedge fast_clock or  posedge w_reset)
		if (w_reset == 1'b1) l_shiftreg15a <= 7'b0;
		else  l_shiftreg15a <= {l_shiftreg15a[5:0], ddio_dataout_h[7]};
	// synopsys translate_off
	initial
		l_shiftreg1a = 0;
	// synopsys translate_on
	always @ ( posedge fast_clock or  posedge w_reset)
		if (w_reset == 1'b1) l_shiftreg1a <= 7'b0;
		else  l_shiftreg1a <= {l_shiftreg1a[5:0], ddio_dataout_h[0]};
	// synopsys translate_off
	initial
		l_shiftreg3a = 0;
	// synopsys translate_on
	always @ ( posedge fast_clock or  posedge w_reset)
		if (w_reset == 1'b1) l_shiftreg3a <= 7'b0;
		else  l_shiftreg3a <= {l_shiftreg3a[5:0], ddio_dataout_h[1]};
	// synopsys translate_off
	initial
		l_shiftreg5a = 0;
	// synopsys translate_on
	always @ ( posedge fast_clock or  posedge w_reset)
		if (w_reset == 1'b1) l_shiftreg5a <= 7'b0;
		else  l_shiftreg5a <= {l_shiftreg5a[5:0], ddio_dataout_h[2]};
	// synopsys translate_off
	initial
		l_shiftreg7a = 0;
	// synopsys translate_on
	always @ ( posedge fast_clock or  posedge w_reset)
		if (w_reset == 1'b1) l_shiftreg7a <= 7'b0;
		else  l_shiftreg7a <= {l_shiftreg7a[5:0], ddio_dataout_h[3]};
	// synopsys translate_off
	initial
		l_shiftreg9a = 0;
	// synopsys translate_on
	always @ ( posedge fast_clock or  posedge w_reset)
		if (w_reset == 1'b1) l_shiftreg9a <= 7'b0;
		else  l_shiftreg9a <= {l_shiftreg9a[5:0], ddio_dataout_h[4]};
	// synopsys translate_off
	initial
		rx_reg = 0;
	// synopsys translate_on
	always @ ( posedge slow_clock or  posedge w_reset)
		if (w_reset == 1'b1) rx_reg <= 112'b0;
		else  rx_reg <= rx_out_wire;
	desconv_dffpipe   h_dffpipe
	( 
	.clock(fast_clock),
	.clrn((~ w_reset)),
	.d(ddio_dataout_h_int),
	.q(wire_h_dffpipe_q));
	desconv_dffpipe   l_dffpipe
	( 
	.clock(fast_clock),
	.clrn((~ w_reset)),
	.d(ddio_dataout_l_int),
	.q(wire_l_dffpipe_q));
	cycloneive_pll   lvds_rx_pll
	( 
	.activeclock(),
	.areset(pll_areset),
	.clk(wire_lvds_rx_pll_clk),
	.clkbad(),
	.fbin(wire_lvds_rx_pll_fbout),
	.fbout(wire_lvds_rx_pll_fbout),
	.inclk({1'b0, rx_inclock}),
	.locked(),
	.phasedone(),
	.scandataout(),
	.scandone(),
	.vcooverrange(),
	.vcounderrange()
	`ifndef FORMAL_VERIFICATION
	// synopsys translate_off
	`endif
	,
	.clkswitch(1'b0),
	.configupdate(1'b0),
	.pfdena(1'b1),
	.phasecounterselect({3{1'b0}}),
	.phasestep(1'b0),
	.phaseupdown(1'b0),
	.scanclk(1'b0),
	.scanclkena(1'b1),
	.scandata(1'b0)
	`ifndef FORMAL_VERIFICATION
	// synopsys translate_on
	`endif
	);
	defparam
		lvds_rx_pll.clk0_divide_by = 1,
		lvds_rx_pll.clk0_multiply_by = 7,
		lvds_rx_pll.clk0_phase_shift = "-892",
		lvds_rx_pll.clk1_divide_by = 7,
		lvds_rx_pll.clk1_multiply_by = 7,
		lvds_rx_pll.clk1_phase_shift = "-892",
		lvds_rx_pll.inclk0_input_frequency = 25000,
		lvds_rx_pll.operation_mode = "source_synchronous",
		lvds_rx_pll.self_reset_on_loss_lock = "off",
		lvds_rx_pll.lpm_type = "cycloneive_pll";
	assign
		ddio_dataout_h = wire_h_dffpipe_q,
		ddio_dataout_h_int = wire_ddio_in_dataout_h,
		ddio_dataout_l = wire_l_dffpipe_q,
		ddio_dataout_l_int = wire_ddio_in_dataout_l,
		fast_clock = wire_lvds_rx_pll_clk[0],
		rx_out = rx_reg,
		rx_out_wire = {l_shiftreg15a[6], h_shiftreg16a[6], l_shiftreg15a[5], h_shiftreg16a[5], l_shiftreg15a[4], h_shiftreg16a[4], l_shiftreg15a[3], h_shiftreg16a[3], l_shiftreg15a[2], h_shiftreg16a[2], l_shiftreg15a[1], h_shiftreg16a[1], l_shiftreg15a[0], h_shiftreg16a[0], l_shiftreg13a[6], h_shiftreg14a[6], l_shiftreg13a[5], h_shiftreg14a[5], l_shiftreg13a[4], h_shiftreg14a[4], l_shiftreg13a[3], h_shiftreg14a[3], l_shiftreg13a[2], h_shiftreg14a[2], l_shiftreg13a[1], h_shiftreg14a[1], l_shiftreg13a[0], h_shiftreg14a[0], l_shiftreg11a[6], h_shiftreg12a[6], l_shiftreg11a[5], h_shiftreg12a[5], l_shiftreg11a[4], h_shiftreg12a[4], l_shiftreg11a[3], h_shiftreg12a[3], l_shiftreg11a[2], h_shiftreg12a[2], l_shiftreg11a[1], h_shiftreg12a[1], l_shiftreg11a[0], h_shiftreg12a[0], l_shiftreg9a[6], h_shiftreg10a[6], l_shiftreg9a[5], h_shiftreg10a[5], l_shiftreg9a[4], h_shiftreg10a[4], l_shiftreg9a[3], h_shiftreg10a[3], l_shiftreg9a[2], h_shiftreg10a[2], l_shiftreg9a[1], h_shiftreg10a[1], l_shiftreg9a[0], h_shiftreg10a[0], l_shiftreg7a[6], h_shiftreg8a[6], l_shiftreg7a[5], h_shiftreg8a[5], l_shiftreg7a[4], h_shiftreg8a[4], l_shiftreg7a[3], h_shiftreg8a[3], l_shiftreg7a[2], h_shiftreg8a[2], l_shiftreg7a[1], h_shiftreg8a[1], l_shiftreg7a[0], h_shiftreg8a[0], l_shiftreg5a[6], h_shiftreg6a[6], l_shiftreg5a[5], h_shiftreg6a[5], l_shiftreg5a[4], h_shiftreg6a[4], l_shiftreg5a[3], h_shiftreg6a[3], l_shiftreg5a[2], h_shiftreg6a[2], l_shiftreg5a[1], h_shiftreg6a[1], l_shiftreg5a[0], h_shiftreg6a[0], l_shiftreg3a[6], h_shiftreg4a[6], l_shiftreg3a[5], h_shiftreg4a[5], l_shiftreg3a[4], h_shiftreg4a[4], l_shiftreg3a[3], h_shiftreg4a[3], l_shiftreg3a[2], h_shiftreg4a[2], l_shiftreg3a[1], h_shiftreg4a[1], l_shiftreg3a[0], h_shiftreg4a[0], l_shiftreg1a[6], h_shiftreg2a[6], l_shiftreg1a[5], h_shiftreg2a[5], l_shiftreg1a[4], h_shiftreg2a[4], l_shiftreg1a[3], h_shiftreg2a[3], l_shiftreg1a[2], h_shiftreg2a[2], l_shiftreg1a[1], h_shiftreg2a[1], l_shiftreg1a[0], h_shiftreg2a[0]},
		rx_outclock = slow_clock,
		slow_clock = wire_lvds_rx_pll_clk[1],
		w_reset = pll_areset;
endmodule //desconv_lvds_rx
//VALID FILE
