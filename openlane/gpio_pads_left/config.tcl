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

# Global
# ------

set script_dir [file dirname [file normalize [info script]]]
# Name
set ::env(DESIGN_NAME) gpio_pads_left


set ::env(DESIGN_IS_CORE) "1"
set ::env(FP_PDN_CORE_RING) {1}

# Timing configuration
set ::env(CLOCK_PERIOD) "10"
set ::env(CLOCK_PORT) "serial_clock_in serial_load_in"

set ::env(SYNTH_MAX_FANOUT) 4
set ::env(SYNTH_BUFFERING) {0}


## CTS BUFFER
set ::env(CTS_CLK_MAX_WIRE_LENGTH) {250}
set ::env(CTS_CLK_BUFFER_LIST) "sky130_fd_sc_hd__clkbuf_4 sky130_fd_sc_hd__clkbuf_8"
set ::env(CTS_SINK_CLUSTERING_SIZE) "16"
set ::env(CLOCK_BUFFER_FANOUT) "8"

# Sources
# -------

# Local sources + no2usb sources
set ::env(VERILOG_FILES) "\
        $::env(DESIGN_DIR)/../../verilog/rtl/gpio_pads/src/gpio_pads_left.sv \
        $::env(DESIGN_DIR)/../../verilog/rtl/gpio_pads/src/gpio_control_block.v \
	"

set ::env(SYNTH_DEFINES) [list SYNTHESIS ]

set ::env(SYNTH_PARAMETERS) "OPENFRAME_IO_PADS=14  "

set ::env(SYNTH_READ_BLACKBOX_LIB) 1
set ::env(SDC_FILE) $::env(DESIGN_DIR)/base.sdc
set ::env(BASE_SDC_FILE) $::env(DESIGN_DIR)/base.sdc

set ::env(LEC_ENABLE) 0

set ::env(VDD_PIN) [list {vccd}]
set ::env(GND_PIN) [list {vssd}]


# Floorplanning
# -------------

set ::env(FP_PIN_ORDER_CFG) $::env(DESIGN_DIR)/pin_order.cfg
#set ::env(MACRO_PLACEMENT_CFG) $::env(DESIGN_DIR)/macro.cfg

set ::env(FP_SIZING) absolute
set ::env(DIE_AREA) "0 0 100 1800"

#set ::env(GRT_OBS) "met4  0 0 300 1725"

# If you're going to use multiple power domains, then keep this disabled.
set ::env(RUN_CVC) 0

#set ::env(PDN_CFG) $::env(DESIGN_DIR)/pdn.tcl


set ::env(GRT_ALLOW_CONGESTION) {0}
set ::env(PL_TIME_DRIVEN) 0
set ::env(PL_TARGET_DENSITY) "0.20"
set ::env(CELL_PAD) "8"

# helps in anteena fix
set ::env(USE_ARC_ANTENNA_CHECK) "0"


#set ::env(GLB_RT_MAX_DIODE_INS_ITERS) 10
set ::env(DIODE_INSERTION_STRATEGY) 4
set ::env(FP_PDN_CHECK_NODES) "1"

## CTS
set ::env(CLOCK_TREE_SYNTH) {1}

## Placement
set ::env(PL_RESIZER_DESIGN_OPTIMIZATIONS) 1
set ::env(PL_RESIZER_TIMING_OPTIMIZATIONS) 1
set ::env(PL_RESIZER_BUFFER_INPUT_PORTS) 1
set ::env(PL_RESIZER_BUFFER_OUTPUT_PORTS) 1

## Routing
set ::env(GLB_RESIZER_TIMING_OPTIMIZATIONS) 1

#LVS Issue - DEF Base looks to having issue
set ::env(MAGIC_EXT_USE_GDS) {1}

#set ::env(GLB_RT_MAXLAYER) 3
set ::env(RT_MAX_LAYER) {met3}

set ::env(FP_PDN_VERTICAL_LAYER) {met2}
set ::env(FP_PDN_HORIZONTAL_LAYER) {met3}
set ::env(FP_PDN_LOWER_LAYER) {met2}
set ::env(FP_PDN_UPPER_LAYER) {met3}

set ::env(FP_IO_HLAYER) {met1}
set ::env(FP_IO_VLAYER) {met2}

#set ::env(FP_IO_VEXTEND) 1
#set ::env(FP_IO_HEXTEND) 1


#Lef 
set ::env(MAGIC_GENERATE_LEF) {1}
set ::env(MAGIC_WRITE_FULL_LEF) {0}

## Placement
set ::env(PL_RESIZER_DESIGN_OPTIMIZATIONS) 1
set ::env(PL_RESIZER_MAX_CAP_MARGIN) 2
set ::env(PL_RESIZER_MAX_WIRE_LENGTH) "500"
set ::env(PL_RESIZER_MAX_SLEW_MARGIN) "2.0"

set ::env(ECO_ENABLE) {0}
#set ::env(CURRENT_STEP) "synthesis"
#set ::env(LAST_STEP) "parasitics_sta"

set ::env(QUIT_ON_TIMING_VIOLATIONS) "0"
set ::env(QUIT_ON_MAGIC_DRC) "1"
set ::env(QUIT_ON_LVS_ERROR) "1"
set ::env(QUIT_ON_SLEW_VIOLATIONS) "0"
