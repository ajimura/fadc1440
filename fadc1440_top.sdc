# The refclk assignment may need to be renamed to match design top level port name.
# May be desireable to move refclk assignment to a top level SDC file.
derive_pll_clocks 
derive_clock_uncertainty
create_clock -period "10 MHz" -name {OSC} {OSC}
create_clock -period "40 MHz" -name {FCOA} {FCOA}
create_clock -period "40 MHz" -name {FCOB} {FCOB}
create_clock -period "280 MHz" -name {DCOA} {DCOA}
create_clock -period "280 MHz" -name {DCOB} {DCOB}
#set_false_path -from {*TTLin*}
#set_false_path -through SysRst
#set_false_path -through {*RstBusy*}
#
set_false_path -from SGEN|altpll_component|auto_generated|pll1|clk[0] -to SGEN|altpll_component|auto_generated|pll1|clk[1]
set_false_path -from SGEN|altpll_component|auto_generated|pll1|clk[1] -to SGEN|altpll_component|auto_generated|pll1|clk[0]
set_false_path -from SGEN|altpll_component|auto_generated|pll1|clk[0] -to SGEN|altpll_component|auto_generated|pll1|clk[2]
set_false_path -from SGEN|altpll_component|auto_generated|pll1|clk[2] -to SGEN|altpll_component|auto_generated|pll1|clk[0]
set_false_path -from SGEN|altpll_component|auto_generated|pll1|clk[1] -to SGEN|altpll_component|auto_generated|pll1|clk[2]
set_false_path -from SGEN|altpll_component|auto_generated|pll1|clk[2] -to SGEN|altpll_component|auto_generated|pll1|clk[1]
#
set_false_path -from CGEN|altpll_component|auto_generated|pll1|clk[1] -to SGEN|altpll_component|auto_generated|pll1|clk[0]
set_false_path -from SGEN|altpll_component|auto_generated|pll1|clk[0] -to CGEN|altpll_component|auto_generated|pll1|clk[1]
#
set_false_path -from CGEN|altpll_component|auto_generated|pll1|clk[0] -to SGEN|altpll_component|auto_generated|pll1|clk[0]
set_false_path -from SGEN|altpll_component|auto_generated|pll1|clk[0] -to CGEN|altpll_component|auto_generated|pll1|clk[0]
