# SPDX-FileCopyrightText:  2021 , Dinesh Annayya
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# SPDX-License-Identifier: Apache-2.0
# SPDX-FileContributor: Modified by Dinesh Annayya <dinesha@opencores.org>

set ::env(USER_ROOT)    ".."
set ::env(CARAVEL_ROOT) "/home/dinesha/workarea/efabless/MPW-10/caravel"

set ::env(LIB_FASTEST) "$::env(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__ff_n40C_1v95.lib"
set ::env(LIB_TYPICAL) "$::env(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib"
set ::env(LIB_SLOWEST) "$::env(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__ss_100C_1v60.lib"
set ::env(DESIGN_NAME) "openframe_project_wrapper"



set_cmd_units -time ns -capacitance pF -current mA -voltage V -resistance kOhm -distance um
#define_corners wc bc tt
define_corners tt
#read_liberty -corner bc $::env(LIB_FASTEST)
#read_liberty -corner wc $::env(LIB_SLOWEST)
read_liberty -corner tt $::env(LIB_TYPICAL)

read_lib  -corner tt   $::env(PDK_ROOT)/sky130A/libs.ref/sky130_sram_macros/lib/sky130_sram_2kbyte_1rw1r_32x512_8_TT_1p8V_25C.lib


read_verilog $::env(USER_ROOT)/verilog/gl/qspim_top.v
read_verilog $::env(USER_ROOT)/verilog/gl/ycr2_iconnect.v
read_verilog $::env(USER_ROOT)/verilog/gl/ycr_intf.v
read_verilog $::env(USER_ROOT)/verilog/gl/ycr_core_top.v
read_verilog $::env(USER_ROOT)/verilog/gl/uart_i2c_usb_spi_top.v
read_verilog $::env(USER_ROOT)/verilog/gl/wb_host.v  
read_verilog $::env(USER_ROOT)/verilog/gl/wb_interconnect.v
read_verilog $::env(USER_ROOT)/verilog/gl/pinmux_top.v
read_verilog $::env(USER_ROOT)/verilog/gl/dg_pll.v
read_verilog $::env(USER_ROOT)/verilog/gl/aes_top.v
read_verilog $::env(USER_ROOT)/verilog/gl/fpu_wrapper.v
read_verilog $::env(USER_ROOT)/verilog/gl/peri_top.v
read_verilog $::env(USER_ROOT)/verilog/gl/gpio_pads_left.v
read_verilog $::env(USER_ROOT)/verilog/gl/gpio_pads_right.v
read_verilog $::env(USER_ROOT)/verilog/gl/gpio_pads_top.v
read_verilog $::env(USER_ROOT)/verilog/gl/gpio_pads_bottom.v
read_verilog $::env(USER_ROOT)/verilog/gl/openframe_project_wrapper.v  


link_design  $::env(DESIGN_NAME)

read_spef -path u_riscv_top.u_connect      $::env(USER_ROOT)/signoff/ycr2_iconnect/openlane-signoff/spef/ycr2_iconnect.nom.spef
read_spef -path u_riscv_top.u_intf         $::env(USER_ROOT)/signoff/ycr_intf/openlane-signoff/spef/ycr_intf.nom.spef
read_spef -path u_riscv_top.i_core_top_0   $::env(USER_ROOT)/signoff/ycr_core_top/openlane-signoff/spef/ycr_core_top.nom.spef
read_spef -path u_riscv_top.i_core_top_1   $::env(USER_ROOT)/signoff/ycr_core_top/openlane-signoff/spef/ycr_core_top.nom.spef
read_spef -path u_pinmux                   $::env(USER_ROOT)/signoff/pinmux_top/openlane-signoff/spef/pinmux_top.nom.spef
read_spef -path u_qspi_master              $::env(USER_ROOT)/signoff/qspim_top/openlane-signoff/spef/qspim_top.nom.spef
read_spef -path u_uart_i2c_usb_spi         $::env(USER_ROOT)/signoff/uart_i2c_usb_spi_top/openlane-signoff/spef/uart_i2c_usb_spi_top.nom.spef
read_spef -path u_wb_host                  $::env(USER_ROOT)/signoff/wb_host/openlane-signoff/spef/wb_host.nom.spef
read_spef -path u_intercon                 $::env(USER_ROOT)/signoff/wb_interconnect/openlane-signoff/spef/wb_interconnect.nom.spef
#read_spef -path u_pll                      $::env(USER_ROOT)/signoff/dg_pll/openlane-signoff/spef/dg_pll.nom.spef	
read_spef -path u_aes                      $::env(USER_ROOT)/signoff/aes_top/openlane-signoff/spef/aes_top.nom.spef	
read_spef -path u_fpu                      $::env(USER_ROOT)/signoff/fpu_wrapper/openlane-signoff/spef/fpu_wrapper.nom.spef	
read_spef -path u_peri                     $::env(USER_ROOT)/signoff/peri_top/openlane-signoff/spef/peri_top.nom.spef	
read_spef -path u_gpio_left                $::env(USER_ROOT)/signoff/gpio_pads_left/openlane-signoff/spef/gpio_pads_left.nom.spef
read_spef -path u_gpio_right               $::env(USER_ROOT)/signoff/gpio_pads_right/openlane-signoff/spef/gpio_pads_right.nom.spef
read_spef -path u_gpio_top                 $::env(USER_ROOT)/signoff/gpio_pads_top/openlane-signoff/spef/gpio_pads_top.nom.spef
read_spef -path u_gpio_bottom              $::env(USER_ROOT)/signoff/gpio_pads_bottom/openlane-signoff/spef/gpio_pads_bottom.nom.spef
read_spef                                  $::env(USER_ROOT)/signoff/openframe_project_wrapper/openlane-signoff/spef/openframe_project_wrapper.nom.spef  


read_sdc -echo sdc/openframe.sdc

# check for missing constraints
check_setup  -verbose > reports/unconstraints.rpt


check_setup  -verbose >  unconstraints.rpt
report_checks -path_delay min -fields {slew cap input nets fanout} -format full_clock_expanded -group_count 50	
report_checks -path_delay max -fields {slew cap input nets fanout} -format full_clock_expanded -group_count 50	
report_worst_slack -max 	
report_worst_slack -min 	
report_checks -path_delay min -fields {slew cap input nets fanout} -format full_clock_expanded -slack_max 0.18 -group_count 10	
report_check_types -max_slew -max_capacitance -max_fanout -violators  > slew.cap.fanout.vio.rpt
