//lpm_mux CBX_SINGLE_OUTPUT_FILE="ON" LPM_SIZE=16 LPM_TYPE="LPM_MUX" LPM_WIDTH=14 LPM_WIDTHS=4 data result sel
//VERSION_BEGIN 18.1 cbx_mgl 2019:04:11:16:07:46:SJ cbx_stratixii 2019:04:11:16:04:12:SJ cbx_util_mgl 2019:04:11:16:04:12:SJ  VERSION_END
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



//synthesis_resources = lpm_mux 1 
//synopsys translate_off
`timescale 1 ps / 1 ps
//synopsys translate_on
module  mgk0a
	( 
	data,
	result,
	sel) /* synthesis synthesis_clearbox=1 */;
	input   [223:0]  data;
	output   [13:0]  result;
	input   [3:0]  sel;

	wire  [13:0]   wire_mgl_prim1_result;

	lpm_mux   mgl_prim1
	( 
	.data(data),
	.result(wire_mgl_prim1_result),
	.sel(sel));
	defparam
		mgl_prim1.lpm_size = 16,
		mgl_prim1.lpm_type = "LPM_MUX",
		mgl_prim1.lpm_width = 14,
		mgl_prim1.lpm_widths = 4;
	assign
		result = wire_mgl_prim1_result;
endmodule //mgk0a
//VALID FILE
