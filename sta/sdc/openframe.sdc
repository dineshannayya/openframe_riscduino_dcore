set ::env(SYNTH_TIMING_DERATE) 0.05
set ::env(SYNTH_CLOCK_SETUP_UNCERTAINITY) 0.25
set ::env(SYNTH_CLOCK_HOLD_UNCERTAINITY) 0.25
set ::env(SYNTH_CLOCK_TRANSITION) 0.15

## MASTER CLOCKS
create_clock -name clk -period 15 [get_ports {gpio_in[41]}] 
create_clock -name clk2 -period 15 [get_ports {gpio_in[42]}] 



### User Project Clocks
create_clock -name int_pll_clock -period 5.0000  [get_pins {u_pinmux/int_pll_clock}]

create_clock -name wbs_ref_clk -period 5.0000   [get_pins {u_wb_host/u_reg.u_wbs_ref_clkbuf.u_buf/X}]
create_clock -name wbs_clk_i   -period 15.0000  [get_pins {u_wb_host/wbs_clk_out}]

create_clock -name cpu_ref_clk -period 5.0000   [get_pins {u_wb_host/u_reg.u_cpu_ref_clkbuf.u_buf/X}]
create_clock -name cpu_clk     -period 25.0000  [get_pins {u_wb_host/cpu_clk}]

create_clock -name rtc_ref_clk -period 50.0000  [get_pins {u_pinmux/u_glbl_reg.u_rtc_ref_clkbuf.u_buf/X}]
create_clock -name rtc_clk     -period 50.0000  [get_pins {u_pinmux/u_glbl_reg.u_clkbuf_rtc.u_buf/X}]

create_clock -name pll_ref_clk -period 20.0000  [get_pins {u_pinmux/pll_ref_clk}]
create_clock -name pll_clk_0   -period 5.0000   [get_pins {u_pll/ringosc.ibufp01/Y}]

create_clock -name usb_ref_clk -period 5.0000   [get_pins {u_pinmux/u_glbl_reg.u_usb_ref_clkbuf.u_buf/X}]
create_clock -name usb_clk     -period 20.0000  [get_pins {u_pinmux/u_glbl_reg.u_clkbuf_usb.u_buf/X}]
create_clock -name uarts0_clk  -period 100.0000 [get_pins {u_uart_i2c_usb_spi/u_uart0_core.u_lineclk_buf.genblk1.u_mux/X}]
create_clock -name uarts1_clk  -period 100.0000 [get_pins {u_uart_i2c_usb_spi/u_uart1_core.u_lineclk_buf.genblk1.u_mux/X}]
create_clock -name uartm_clk   -period 100.0000 [get_pins {u_wb_host/u_uart2wb.u_core.u_uart_clk.genblk1.u_mux/X}]
create_clock -name dbg_ref_clk -period 10.0000 [get_pins {u_pinmux/u_glbl_reg.u_clkbuf_dbg_ref.u_buf/X}]

create_clock -name riscv_tck -period 100.0000  [get_pins {u_pinmux/riscv_tck}]
create_clock -name gpio_serial_clock -period 100.0000  [get_pins {u_peri/gpio_serial_clock}]
create_clock -name gpio_serial_load -period 100.0000  [get_pins {u_peri/gpio_serial_load}]

set_clock_groups \
   -name clock_group \
   -logically_exclusive \
   -group [get_clocks {clk}]\
   -group [get_clocks {clk2}]\
   -group [get_clocks {int_pll_clock}]\
   -group [get_clocks {wbs_clk_i}]\
   -group [get_clocks {wbs_ref_clk}]\
   -group [get_clocks {cpu_clk}]\
   -group [get_clocks {cpu_ref_clk}]\
   -group [get_clocks {rtc_clk}]\
   -group [get_clocks {usb_ref_clk}]\
   -group [get_clocks {pll_ref_clk}]\
   -group [get_clocks {pll_clk_0}]\
   -group [get_clocks {usb_clk}]\
   -group [get_clocks {uarts0_clk}]\
   -group [get_clocks {uarts1_clk}]\
   -group [get_clocks {uartm_clk}]\
   -group [get_clocks {dbg_ref_clk}]\
   -group [get_clocks {rtc_ref_clk}]\
   -group [get_clocks {riscv_tck}]\
   -group [get_clocks {gpio_serial_clock}]\
   -group [get_clocks {gpio_serial_load}]\
   -comment {Async Clock group}

set_propagated_clock [all_clocks]

set_max_fanout 12 [current_design]
# synthesis max fanout should be less than 12 (7 maybe)


######################################################
#  Caravel Case Analysis
#######################################################




#################################################################
## User Case analysis
#################################################################

# clock skew cntrl-1
#cfg_clk_skew_ctrl1[31:28]
set_case_analysis 0 [get_pins {u_peri/cfg_cska_peri[3]}]             
set_case_analysis 1 [get_pins {u_peri/cfg_cska_peri[2]}]             
set_case_analysis 1 [get_pins {u_peri/cfg_cska_peri[0]}]             
set_case_analysis 1 [get_pins {u_peri/cfg_cska_peri[1]}]             

#cfg_clk_skew_ctrl1[27:24]
set_case_analysis 0 [get_pins {u_qspi_master/cfg_cska_sp_co[3]}]  
set_case_analysis 0 [get_pins {u_qspi_master/cfg_cska_sp_co[2]}] 
set_case_analysis 0 [get_pins {u_qspi_master/cfg_cska_sp_co[1]}] 
set_case_analysis 0 [get_pins {u_qspi_master/cfg_cska_sp_co[0]}] 

#cfg_clk_skew_ctrl1[23:20]
set_case_analysis 0 [get_pins {u_pinmux/cfg_cska_pinmux[3]}]         
set_case_analysis 1 [get_pins {u_pinmux/cfg_cska_pinmux[2]}]         
set_case_analysis 0 [get_pins {u_pinmux/cfg_cska_pinmux[1]}]         
set_case_analysis 0 [get_pins {u_pinmux/cfg_cska_pinmux[0]}]         

#cfg_clk_skew_ctrl1[19:16]
set_case_analysis 0 [get_pins {u_uart_i2c_usb_spi/cfg_cska_uart[3]}]
set_case_analysis 1 [get_pins {u_uart_i2c_usb_spi/cfg_cska_uart[2]}]
set_case_analysis 1 [get_pins {u_uart_i2c_usb_spi/cfg_cska_uart[1]}]
set_case_analysis 1 [get_pins {u_uart_i2c_usb_spi/cfg_cska_uart[0]}]

#cfg_clk_skew_ctrl1[15:12]
set_case_analysis 0 [get_pins {u_qspi_master/cfg_cska_spi[3]}]
set_case_analysis 1 [get_pins {u_qspi_master/cfg_cska_spi[2]}]
set_case_analysis 1 [get_pins {u_qspi_master/cfg_cska_spi[1]}]
set_case_analysis 1 [get_pins {u_qspi_master/cfg_cska_spi[0]}]

#cfg_clk_skew_ctrl1[11:8]
set_case_analysis 1 [get_pins {u_riscv_top.u_intf/cfg_wcska[3]}]
set_case_analysis 0 [get_pins {u_riscv_top.u_intf/cfg_wcska[2]}]
set_case_analysis 0 [get_pins {u_riscv_top.u_intf/cfg_wcska[1]}]
set_case_analysis 0 [get_pins {u_riscv_top.u_intf/cfg_wcska[0]}]

#cfg_clk_skew_ctrl1[7:4]
set_case_analysis 1 [get_pins {u_wb_host/cfg_cska_wh[3]}]
set_case_analysis 0 [get_pins {u_wb_host/cfg_cska_wh[2]}]
set_case_analysis 1 [get_pins {u_wb_host/cfg_cska_wh[1]}]
set_case_analysis 1 [get_pins {u_wb_host/cfg_cska_wh[0]}]

#cfg_clk_skew_ctrl1[3:0]
set_case_analysis 1 [get_pins {u_intercon/cfg_cska_wi[3]}]
set_case_analysis 0 [get_pins {u_intercon/cfg_cska_wi[2]}] 
set_case_analysis 0 [get_pins {u_intercon/cfg_cska_wi[0]}] 
set_case_analysis 1 [get_pins {u_intercon/cfg_cska_wi[1]}]


# clock skew cntrl-2
# cfg_clk_skew_ctrl2[31:28]
set_case_analysis 0 [get_pins {u_fpu/cfg_cska[3]}]                      
set_case_analysis 0 [get_pins {u_fpu/cfg_cska[2]}]                      
set_case_analysis 0 [get_pins {u_fpu/cfg_cska[1]}]                      
set_case_analysis 1 [get_pins {u_fpu/cfg_cska[0]}]                      

# cfg_clk_skew_ctrl2[27:24]
set_case_analysis 1 [get_pins {u_aes/cfg_cska[3]}]                      
set_case_analysis 0 [get_pins {u_aes/cfg_cska[2]}]                      
set_case_analysis 0 [get_pins {u_aes/cfg_cska[1]}]                      
set_case_analysis 0 [get_pins {u_aes/cfg_cska[0]}]                      

# cfg_clk_skew_ctrl2[23:20]
#set_case_analysis 0 [get_pins {u_riscv_top.i_core_top_3/cfg_ccska[3]}] 
#set_case_analysis 1 [get_pins {u_riscv_top.i_core_top_3/cfg_ccska[2]}] 
#set_case_analysis 0 [get_pins {u_riscv_top.i_core_top_3/cfg_ccska[1]}] 
#set_case_analysis 0 [get_pins {u_riscv_top.i_core_top_3/cfg_ccska[0]}] 

# cfg_clk_skew_ctrl2[19:16]
#set_case_analysis 0 [get_pins {u_riscv_top.i_core_top_2/cfg_ccska[3]}] 
#set_case_analysis 1 [get_pins {u_riscv_top.i_core_top_2/cfg_ccska[2]}] 
#set_case_analysis 0 [get_pins {u_riscv_top.i_core_top_2/cfg_ccska[1]}] 
#set_case_analysis 0 [get_pins {u_riscv_top.i_core_top_2/cfg_ccska[0]}] 

# cfg_clk_skew_ctrl2[15:12]
set_case_analysis 0 [get_pins {u_riscv_top.i_core_top_1/cfg_ccska[3]}]
set_case_analysis 1 [get_pins {u_riscv_top.i_core_top_1/cfg_ccska[2]}]
set_case_analysis 0 [get_pins {u_riscv_top.i_core_top_1/cfg_ccska[1]}]
set_case_analysis 0 [get_pins {u_riscv_top.i_core_top_1/cfg_ccska[0]}]

# cfg_clk_skew_ctrl2[11:8]
set_case_analysis 0 [get_pins {u_riscv_top.i_core_top_0/cfg_ccska[3]}] 
set_case_analysis 1 [get_pins {u_riscv_top.i_core_top_0/cfg_ccska[2]}] 
set_case_analysis 0 [get_pins {u_riscv_top.i_core_top_0/cfg_ccska[1]}] 
set_case_analysis 0 [get_pins {u_riscv_top.i_core_top_0/cfg_ccska[0]}] 

# cfg_clk_skew_ctrl2[7:4]
set_case_analysis 1 [get_pins {u_riscv_top.u_connect/cfg_ccska[3]}]
set_case_analysis 0 [get_pins {u_riscv_top.u_connect/cfg_ccska[2]}]
set_case_analysis 0 [get_pins {u_riscv_top.u_connect/cfg_ccska[1]}] 
set_case_analysis 0 [get_pins {u_riscv_top.u_connect/cfg_ccska[0]}]

# cfg_clk_skew_ctrl2[3:0]
set_case_analysis 1 [get_pins {u_riscv_top.u_intf/cfg_ccska[3]}]
set_case_analysis 1 [get_pins {u_riscv_top.u_intf/cfg_ccska[2]}]
set_case_analysis 0 [get_pins {u_riscv_top.u_intf/cfg_ccska[1]}]
set_case_analysis 0 [get_pins {u_riscv_top.u_intf/cfg_ccska[0]}]






#Keept the SRAM clock driving edge at pos edge
set_case_analysis 0 [get_pins {u_riscv_top.u_intf/cfg_sram_lphase[0]}]
set_case_analysis 0 [get_pins {u_riscv_top.u_intf/cfg_sram_lphase[1]}]

set_case_analysis 0 [get_pins {u_riscv_top.u_connect/cfg_sram_lphase[0]}]
set_case_analysis 0 [get_pins {u_riscv_top.u_connect/cfg_sram_lphase[1]}]
set_case_analysis 0 [get_pins {u_riscv_top.u_connect/cfg_sram_lphase[2]}]
set_case_analysis 0 [get_pins {u_riscv_top.u_connect/cfg_sram_lphase[3]}]

############## Caravel False Path ########################################################
## FALSE PATHS (ASYNCHRONOUS INPUTS)
set_false_path -from [get_ports {resetb_l}]

## All interrupts are double sync
set_false_path -through [get_pins {u_uart_i2c_usb_spi/i2cm_intr_o}]

# Double Sync FF
set_false_path -to [get_pins u_riscv_top.u_connect/i_timer.u_wakeup_dsync.bus_.bit_[0].u_dsync0/D ]
set_false_path -to [get_pins u_riscv_top.u_connect/i_timer.u_wakeup_dsync.bus_.bit_[1].u_dsync0/D ]
set_false_path -to [get_pins u_intercon/u_dsync.bus_.bit_[4].u_dsync0/D ]
set_false_path -to [get_pins u_intercon/u_dsync.bus_.bit_[3].u_dsync0/D ]
set_false_path -to [get_pins u_intercon/u_dsync.bus_.bit_[2].u_dsync0/D ]
set_false_path -to [get_pins u_intercon/u_dsync.bus_.bit_[1].u_dsync0/D ]
set_false_path -to [get_pins u_intercon/u_dsync.bus_.bit_[0].u_dsync0/D ]

################ Caravel Timing Constraints ##########################################################


set input_delay_value 4
set output_delay_value 4
puts "\[INFO\]: Setting output delay to: $output_delay_value"
puts "\[INFO\]: Setting input delay to: $input_delay_value"


####################################################################################################





# TODO set this as parameter
set cap_load 10
puts "\[INFO\]: Setting load to: $cap_load"
set_load  $cap_load [all_outputs]

#add input transition for the inputs pins
set_input_transition 2 [all_inputs]

puts "\[INFO\]: Setting timing derate to: [expr {$::env(SYNTH_TIMING_DERATE) * 10}] %"
set_timing_derate -early [expr {1-$::env(SYNTH_TIMING_DERATE)}]
set_timing_derate -late [expr {1+$::env(SYNTH_TIMING_DERATE)}]

puts "\[INFO\]: Setting clock setup uncertainity to: $::env(SYNTH_CLOCK_SETUP_UNCERTAINITY)"
puts "\[INFO\]: Setting clock hold uncertainity to: $::env(SYNTH_CLOCK_HOLD_UNCERTAINITY)"
set_clock_uncertainty -setup $::env(SYNTH_CLOCK_SETUP_UNCERTAINITY) [all_clocks]
set_clock_uncertainty -hold $::env(SYNTH_CLOCK_HOLD_UNCERTAINITY) [all_clocks]




#puts "\[INFO\]: Setting clock transition to: $::env(SYNTH_CLOCK_TRANSITION)"
set_clock_transition $::env(SYNTH_CLOCK_TRANSITION) [all_clocks]

