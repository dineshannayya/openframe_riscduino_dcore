set env CARRY_SELECT_ADDER_MAP pdk/sky130A/libs.tech/openlane/sky130_fd_sc_hd/csa_map.v
set env CLOCK_PERIOD 25
set env DESIGN_NAME openframe_project_wrapper
set env EXTRA_LIBS home/dinesha/workarea/efabless/MPW-10/caravel_openframe_project/openlane/openframe_project_wrapper/../../lib/picosoc.lib
set env FULL_ADDER_MAP pdk/sky130A/libs.tech/openlane/sky130_fd_sc_hd/fa_map.v
set env LIB_SYNTH ./tmp/synthesis/trimmed.lib
set env LIB_SYNTH_COMPLETE_NO_PG ./tmp/synthesis/1-sky130_fd_sc_hd__tt_025C_1v80.no_pg.lib
set env LIB_SYNTH_NO_PG ./tmp/synthesis/1-trimmed.no_pg.lib
set env PACKAGED_SCRIPT_0 openlane/scripts/yosys/synth.tcl
set env PACKAGED_SCRIPT_1 ./tmp/synthesis/synthesis.sdc
set env QUIT_ON_SYNTH_CHECKS 0
set env RIPPLE_CARRY_ADDER_MAP pdk/sky130A/libs.tech/openlane/sky130_fd_sc_hd/rca_map.v
set env SAVE_NETLIST ./results/synthesis/openframe_project_wrapper.v
set env SYNTH_ADDER_TYPE YOSYS
set env SYNTH_BUFFERING 1
set env SYNTH_CAP_LOAD 33.442
set env SYNTH_DEFINES PnR
set env SYNTH_DRIVING_CELL sky130_fd_sc_hd__inv_2
set env SYNTH_EXTRA_MAPPING_FILE 
set env SYNTH_LATCH_MAP pdk/sky130A/libs.tech/openlane/sky130_fd_sc_hd/latch_map.v
set env SYNTH_MAX_FANOUT 10
set env SYNTH_MAX_TRAN 0.75
set env SYNTH_MIN_BUF_PORT sky130_fd_sc_hd__buf_2 A X
set env SYNTH_NO_FLAT 0
set env SYNTH_READ_BLACKBOX_LIB 1
set env SYNTH_SHARE_RESOURCES 1
set env SYNTH_SIZING 0
set env SYNTH_STRATEGY AREA 0
set env SYNTH_TIEHI_PORT sky130_fd_sc_hd__conb_1 HI
set env SYNTH_TIELO_PORT sky130_fd_sc_hd__conb_1 LO
set env TRISTATE_BUFFER_MAP pdk/sky130A/libs.tech/openlane/sky130_fd_sc_hd/tribuff_map.v
set env VERILOG_FILES home/dinesha/workarea/efabless/MPW-10/caravel_openframe_project/openlane/openframe_project_wrapper/../../verilog/rtl/openframe_project_netlists.v home/dinesha/workarea/efabless/MPW-10/caravel_openframe_project/openlane/openframe_project_wrapper/../../verilog/rtl/openframe_project_wrapper.v
set env VERILOG_FILES_BLACKBOX home/dinesha/workarea/efabless/MPW-10/caravel_openframe_project/openlane/openframe_project_wrapper/../picosoc/sky130_sram_2kbyte_1rw1r_32x512_8.v home/dinesha/workarea/efabless/MPW-10/caravel_openframe_project/openlane/openframe_project_wrapper/../../verilog/gl/picosoc.v home/dinesha/workarea/efabless/MPW-10/caravel_openframe_project/openlane/openframe_project_wrapper/../../verilog/gl/vccd1_connection.v home/dinesha/workarea/efabless/MPW-10/caravel_openframe_project/openlane/openframe_project_wrapper/../../verilog/gl/vssd1_connection.v home/dinesha/workarea/efabless/MPW-10/caravel_openframe_project/openlane/openframe_project_wrapper/../../verilog/gl/digital_locked_loop.v
set env synth_report_prefix ./reports/synthesis/1-synthesis
set env synthesis_results ./results/synthesis
set env synthesis_tmpfiles ./tmp/synthesis