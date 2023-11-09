###############################################################################
# Timing Constraints
###############################################################################
create_clock -name serial_clock -period 10.0000 [get_ports {serial_clock_in}]
create_clock -name serial_load -period 10.0000 [get_ports {serial_load_in}]

set_clock_groups \
   -name clock_group \
   -logically_exclusive \
   -group [get_clocks {serial_clock}]\
   -group [get_clocks {serial_load}]\
   -comment {Async Clock group}

set_clock_transition 0.1500 [all_clocks]
set_clock_uncertainty -setup 0.5000 [all_clocks]
set_clock_uncertainty -hold 0.2500 [all_clocks]

set ::env(SYNTH_TIMING_DERATE) 0.05
puts "\[INFO\]: Setting timing derate to: [expr {$::env(SYNTH_TIMING_DERATE) * 10}] %"
set_timing_derate -early [expr {1-$::env(SYNTH_TIMING_DERATE)}]
set_timing_derate -late [expr {1+$::env(SYNTH_TIMING_DERATE)}]

###############################################################################
# Environment
###############################################################################
set_driving_cell -lib_cell sky130_fd_sc_hd__inv_8 -pin {Y} [all_inputs]
set cap_load 0.0334
puts "\[INFO\]: Setting load to: $cap_load"
set_load  $cap_load [all_outputs]

set_max_transition 1.00 [current_design]
set_max_capacitance 0.2 [current_design]
set_max_fanout 10 [current_design]


###############################################################################
# Design Rules
###############################################################################
