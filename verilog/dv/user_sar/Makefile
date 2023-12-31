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
#
# SPDX-License-Identifier: Apache-2.0


# ---- Include Partitioned Makefiles ----

CONFIG = openframe
 
#######################################################################
## Caravel Verilog for Integration Tests
#######################################################################

DESIGNS?=../../..
TOOLS?=/opt/riscv32i/

export USER_PROJECT_VERILOG ?=  $(DESIGNS)/verilog
## YIFIVE FIRMWARE
YIFIVE_FIRMWARE_PATH = $(USER_PROJECT_VERILOG)/dv/common/firmware
GCC_PREFIX?=riscv32-unknown-elf


## Simulation mode: RTL/GL
SIM?=RTL
DUMP?=OFF
RISC_CORE?=0
#DUT_TOP =<OPENFRAME/CARAVEL_TOP>
DUT_TOP?=OPENFRAME

### To Enable IVERILOG FST DUMP
export IVERILOG_DUMPER = fst


.SUFFIXES:

PATTERN = user_sar

all:  ${PATTERN:=.vcd}


vvp:  ${PATTERN:=.vvp}

%.vvp: %_tb.v
ifeq ($(SIM),RTL)
   ifeq ($(DUMP),OFF)
	iverilog -g2012 -DFUNCTIONAL -D$(DUT_TOP) -DSIM -I $(PDK_PATH) \
	-f$(USER_PROJECT_VERILOG)/includes/includes.rtl.$(CONFIG) \
	-f$(USER_PROJECT_VERILOG)/includes/includes.rtl.lib  \
	-f$(USER_PROJECT_VERILOG)/includes/includes.caravel  \
	$< -o $@ 
    else  
	iverilog -g2012 -DWFDUMP -D$(DUT_TOP) -DFUNCTIONAL -DSIM -I $(PDK_PATH) \
	-f$(USER_PROJECT_VERILOG)/includes/includes.rtl.$(CONFIG) \
	-f$(USER_PROJECT_VERILOG)/includes/includes.rtl.lib  \
	-f$(USER_PROJECT_VERILOG)/includes/includes.caravel  \
	$< -o $@ 
   endif
else  
   ifeq ($(DUMP),OFF)
	iverilog -g2012 -DFUNCTIONAL -D$(DUT_TOP) -DUSE_POWER_PINS -DGL -I $(PDK_PATH) \
	-f$(USER_PROJECT_VERILOG)/includes/includes.gl.$(CONFIG) \
	-f$(USER_PROJECT_VERILOG)/includes/includes.gl.lib \
	$< -o $@ 
    else  
	iverilog -g2012 -DWFDUMP -DFUNCTIONAL -D$(DUT_TOP) -DUSE_POWER_PINS -DGL -I $(PDK_PATH) \
	-f$(USER_PROJECT_VERILOG)/includes/includes.gl.$(CONFIG) \
	-f$(USER_PROJECT_VERILOG)/includes/includes.gl.lib \
	$< -o $@ 
   endif
endif

%.vcd: %.vvp
	vvp $< +risc_core_id=$(RISC_CORE)


# ---- Clean ----

clean:
	rm -f *.vvp *.vcd *.log *.fst

.PHONY: clean hex all
