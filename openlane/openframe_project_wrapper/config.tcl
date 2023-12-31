# SPDX-FileCopyrightText: 2020 Efabless Corporation
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

# Base Configurations. Don't Touch
# section begin

set ::env(STD_CELL_LIBRARY) "sky130_fd_sc_hd"

# YOU ARE NOT ALLOWED TO CHANGE ANY VARIABLES DEFINED IN THE FIXED WRAPPER CFGS 
set ::env(FP_DEF_TEMPLATE) $::env(DESIGN_DIR)/fixed_dont_change/openframe_project_wrapper.def

set script_dir [file dirname [file normalize [info script]]]
set proj_dir [file dirname [file normalize [info script]]]

set ::env(DESIGN_NAME) openframe_project_wrapper
set verilog_root $::env(DESIGN_DIR)/../../verilog/
set lef_root $::env(DESIGN_DIR)/../../lef/
set gds_root $::env(DESIGN_DIR)/../../gds/
#section end

# User Configurations
#
set ::env(DESIGN_IS_CORE) 1


## Source Verilog Files
set ::env(VERILOG_FILES) "\
	$::env(DESIGN_DIR)/../../verilog/rtl//yifive/ycr2c/src/top/ycr2_top_wb.sv \
	$::env(DESIGN_DIR)/../../verilog/rtl/openframe_project_netlists.v         \
	$::env(DESIGN_DIR)/../../verilog/rtl/openframe_project_wrapper.v "


## Clock configurations
set ::env(CLOCK_PORT) "gpio_in\[38\]"

set ::env(CLOCK_PERIOD) "25"

## Internal Macros
### Macro Placement
set ::env(MACRO_PLACEMENT_CFG) $::env(DESIGN_DIR)/macro.cfg

set ::env(FP_PDN_CFG) $::env(DESIGN_DIR)/pdn_cfg.tcl

set ::env(SDC_FILE) $::env(DESIGN_DIR)/base.sdc
set ::env(BASE_SDC_FILE) $::env(DESIGN_DIR)/base.sdc

set ::env(SYNTH_READ_BLACKBOX_LIB) 1
set ::env(RUN_LINTER) "0"


### Black-box verilog and views
set ::env(VERILOG_FILES_BLACKBOX) "\
        $::env(DESIGN_DIR)/../../verilog/gl/qspim_top.v \
        $::env(DESIGN_DIR)/../../verilog/gl/wb_interconnect.v \
        $::env(DESIGN_DIR)/../../verilog/gl/pinmux_top.v     \
        $::env(DESIGN_DIR)/../../verilog/gl/uart_i2c_usb_spi_top.v     \
	    $::env(DESIGN_DIR)/../../verilog/gl/wb_host.v \
	    $::env(DESIGN_DIR)/../../verilog/gl/ycr_intf.v \
	    $::env(DESIGN_DIR)/../../verilog/gl/ycr_core_top.v \
	    $::env(DESIGN_DIR)/../../verilog/gl/ycr2_iconnect.v \
	    $::env(DESIGN_DIR)/../../verilog/gl/dg_pll.v \
	    $::env(DESIGN_DIR)/../../verilog/rtl/sram_macros/sky130_sram_2kbyte_1rw1r_32x512_8.v \
	    $::env(DESIGN_DIR)/../../verilog/gl/adc_dac_top.v \
	    $::env(DESIGN_DIR)/../../verilog/gl/aes_top.v \
	    $::env(DESIGN_DIR)/../../verilog/gl/fpu_wrapper.v \
	    $::env(DESIGN_DIR)/../../verilog/gl/gpio_pads_left.v \
	    $::env(DESIGN_DIR)/../../verilog/gl/gpio_pads_right.v \
	    $::env(DESIGN_DIR)/../../verilog/gl/gpio_pads_bottom.v \
	    $::env(DESIGN_DIR)/../../verilog/gl/gpio_pads_top.v \
	    $::env(DESIGN_DIR)/../../verilog/gl/peri_top.v \
	    $::env(DESIGN_DIR)/../../verilog/gl/vccd1_connection.v \
	    $::env(DESIGN_DIR)/../../verilog/gl/vssd1_connection.v \
	    $::env(DESIGN_DIR)/../../verilog/gl/vdda1_connection_0.v \
	    $::env(DESIGN_DIR)/../../verilog/gl/vdda1_connection_1.v \
	    $::env(DESIGN_DIR)/../../verilog/gl/vssa1_connection_0.v \
	    $::env(DESIGN_DIR)/../../verilog/gl/vssa1_connection_1.v \
	    "

set ::env(EXTRA_LEFS) "\
	$lef_root/qspim_top.lef \
	$lef_root/pinmux_top.lef \
	$lef_root/wb_interconnect.lef \
	$lef_root/uart_i2c_usb_spi_top.lef \
	$lef_root/wb_host.lef \
	$lef_root/ycr_intf.lef \
	$lef_root/ycr_core_top.lef \
	$lef_root/ycr2_iconnect.lef \
	$lef_root/dg_pll.lef \
	$::env(PDK_ROOT)/$::env(PDK)/libs.ref/sky130_sram_macros/lef/sky130_sram_2kbyte_1rw1r_32x512_8.lef \
	$lef_root/adc_dac_top.lef \
	$lef_root/aes_top.lef \
	$lef_root/fpu_wrapper.lef \
	$lef_root/gpio_pads_left.lef \
	$lef_root/gpio_pads_right.lef \
	$lef_root/gpio_pads_bottom.lef \
	$lef_root/gpio_pads_top.lef \
	$lef_root/peri_top.lef \
	$lef_root/vccd1_connection.lef \
	$lef_root/vssd1_connection.lef \
	$lef_root/vdda1_connection_0.lef \
	$lef_root/vdda1_connection_1.lef \
	$lef_root/vssa1_connection_0.lef \
	$lef_root/vssa1_connection_1.lef \
	"

set ::env(EXTRA_GDS_FILES) "\
	$gds_root/qspim_top.gds \
	$gds_root/pinmux_top.gds \
	$gds_root/wb_interconnect.gds \
	$gds_root/uart_i2c_usb_spi_top.gds \
	$gds_root/wb_host.gds \
	$gds_root/ycr_intf.gds \
	$gds_root/ycr_core_top.gds \
	$gds_root/ycr2_iconnect.gds \
	$gds_root/dg_pll.gds \
	$gds_root/adc_dac_top.gds \
	$::env(PDK_ROOT)/$::env(PDK)/libs.ref/sky130_sram_macros/gds/sky130_sram_2kbyte_1rw1r_32x512_8.gds \
	$gds_root/aes_top.gds \
	$gds_root/fpu_wrapper.gds \
	$gds_root/gpio_pads_left.gds \
	$gds_root/gpio_pads_right.gds \
	$gds_root/gpio_pads_bottom.gds \
	$gds_root/gpio_pads_top.gds \
	$gds_root/peri_top.gds \
	$gds_root/vccd1_connection.gds \
	$gds_root/vssd1_connection.gds \
	$gds_root/vdda1_connection_0.gds \
	$gds_root/vdda1_connection_1.gds \
	$gds_root/vssa1_connection_0.gds \
	$gds_root/vssa1_connection_1.gds \
	"

set ::env(SYNTH_DEFINES) [list PnR SYNTHESIS USE_POWER_PINS YCR_DBG_EN YCR_SERIAL_DEBUG ]

set ::env(VERILOG_INCLUDE_DIRS) [glob $::env(DESIGN_DIR)/../../verilog/rtl/yifive/includes ]

#set ::env(GLB_RT_MAXLAYER) 6
set ::env(RT_MAX_LAYER) {met5}
set ::env(GRT_ALLOW_CONGESTION) {1}
set ::env(SYNTH_USE_PG_PINS_DEFINES) "USE_POWER_PINS"


## Internal Macros
### Macro PDN Connections
set ::env(RUN_IRDROP_REPORT) "0"
####################
set ::env(FP_PDN_ENABLE_MACROS_GRID) {1}
set ::env(FP_PDN_ENABLE_GLOBAL_CONNECTIONS) "0"
set ::env(FP_PDN_CHECK_NODES) 1
set ::env(FP_PDN_ENABLE_RAILS) 0

set ::env(FP_PDN_HORIZONTAL_LAYER) {met5}
set ::env(FP_PDN_VERTICAL_LAYER) {met4}

set ::env(FP_PDN_VPITCH) 80
set ::env(FP_PDN_HPITCH) 80
set ::env(FP_PDN_VOFFSET) 18.43
set ::env(FP_PDN_HOFFSET) 22.83
set ::env(FP_PDN_VWIDTH) 6.4
set ::env(FP_PDN_HWIDTH) 6.4
set ::env(FP_PDN_HSPACING) 3.2
set ::env(FP_PDN_VSPACING) 3.2

set ::env(FP_PDN_CORE_RING) 1
set ::env(FP_PDN_CORE_RING_VWIDTH) 20
set ::env(FP_PDN_CORE_RING_HWIDTH) 20
set ::env(FP_PDN_CORE_RING_VOFFSET) -8.780
set ::env(FP_PDN_CORE_RING_HOFFSET) -8
set ::env(FP_PDN_CORE_RING_VSPACING) 2.4
set ::env(FP_PDN_CORE_RING_HSPACING) 2.4

set ::env(VDD_NETS) {vccd1 vdda1 }
set ::env(GND_NETS) {vssd1 vssa1 }
set ::env(VDD_NET) {vdda1}
set ::env(GND_NET) {vssa1}
set ::env(VDD_PIN) {vccd1}
set ::env(GND_PIN) {vssd1}

set ::env(FP_TEMPLATE_PINS) { vccd1 vssd1 vccd vssd vccd2 vssd2 vssa vdda vssa1 vdda1 vssa2 vdda2 vddio vssio }

set ::env(PDN_STRIPE) {vdda1 vccd1 vssa1 vssd1}
set ::env(DRT_OPT_ITERS) {32}

set ::env(FP_SIZING) absolute
set ::env(DIE_AREA) "0 0 3166.63 4766.630"
set ::env(CORE_AREA) "80 80 3086.63 4686.630"

set ::env(GRT_OBS) " met5  0 0 3166.63  4766.630"

set ::env(FP_PDN_MACRO_HOOKS) " \
    u_pll                       vccd1 vssd1 VPWR  VGND, \
	u_intercon                  vccd1 vssd1 vccd1 vssd1,\
	u_pinmux                    vccd1 vssd1 vccd1 vssd1,\
	u_qspi_master               vccd1 vssd1 vccd1 vssd1,\
	u_tsram0_2kb                vccd1 vssd1 vccd1 vssd1,\
	u_tsram1_2kb                vccd1 vssd1 vccd1 vssd1,\
	u_tsram2_2kb                vccd1 vssd1 vccd1 vssd1,\
	u_tsram3_2kb                vccd1 vssd1 vccd1 vssd1,\
	u_icache_2kb                vccd1 vssd1 vccd1 vssd1,\
	u_dcache_2kb                vccd1 vssd1 vccd1 vssd1,\
	u_uart_i2c_usb_spi          vccd1 vssd1 vccd1 vssd1,\
	u_wb_host                   vccd1 vssd1 vccd1 vssd1,\
	u_riscv_top.i_core_top_0    vccd1 vssd1 vccd1 vssd1,\
	u_riscv_top.i_core_top_1    vccd1 vssd1 vccd1 vssd1,\
	u_riscv_top.u_connect       vccd1 vssd1 VPWR  VGND, \
	u_riscv_top.u_intf          vccd1 vssd1 vccd1 vssd1,\
	u_4x8bit_adc_dac            vdda1 vssa1 VDDA  VSSA,\
	u_4x8bit_adc_dac            vccd1 vssd1 VCCD  VSSD,\
	u_aes                       vccd1 vssd1 vccd1 vssd1,\
	u_fpu                       vccd1 vssd1 vccd1 vssd1,\
	u_gpio_right                vccd1 vssd1 vccd  vssd,\
	u_gpio_top                  vccd1 vssd1 vccd  vssd,\
	u_gpio_left                 vccd1 vssd1 vccd  vssd,\
	u_gpio_bottom               vccd1 vssd1 vccd  vssd,\
	u_peri                      vccd1 vssd1 vccd1 vssd1
      	"



# The following is because there are no std cells in the example wrapper project.
set ::env(SYNTH_ELABORATE_ONLY) 0
set ::env(PL_RANDOM_GLB_PLACEMENT) 1

set ::env(GLB_RESIZER_DESIGN_OPTIMIZATIONS) "0"
set ::env(GLB_RESIZER_TIMING_OPTIMIZATIONS) "0"


set ::env(PL_RESIZER_DESIGN_OPTIMIZATIONS) 0
set ::env(PL_RESIZER_TIMING_OPTIMIZATIONS) 0
set ::env(PL_RESIZER_BUFFER_INPUT_PORTS) 0
set ::env(PL_RESIZER_BUFFER_OUTPUT_PORTS) 0
set ::env(PL_RESIZER_REPAIR_TIE_FANOUT) "0"

set ::env(GRT_REPAIR_ANTENNAS) 0
set ::env(RUN_HEURISTIC_DIODE_INSERTION) 0
set ::env(RUN_FILL_INSERTION) 0
set ::env(RUN_TAP_DECAP_INSERTION) 0
set ::env(QUIT_ON_LVS_ERROR) "1"
set ::env(QUIT_ON_MAGIC_DRC) "1"
set ::env(QUIT_ON_NEGATIVE_WNS) "0"
set ::env(QUIT_ON_SLEW_VIOLATIONS) "0"
set ::env(QUIT_ON_TIMING_VIOLATIONS) "0"


set ::env(RUN_CTS) 0
set ::env(RUN_CVS) 0
set ::env(RUN_LVS) 0
set ::env(RUN_KLAYOUT_XOR) 0
set ::env(RUN_MAGIC_DRC) 0

