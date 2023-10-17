

module gpio_bottom #(
	parameter OPENFRAME_IO_PADS =6 
        ) (
`ifdef USE_POWER_PINS
         input logic            vccd1,    // User area 1 1.8V supply
         input logic            vssd1,    // User area 1 digital ground
`endif

    /* Basic bidirectional I/O.  Input gpio_in_h is in the 3.3V domain;  all
     * others are in the 1.8v domain.  OEB is output enable, sense inverted.
     */
    input  [OPENFRAME_IO_PADS-1:0] gpio_in,
    input  [OPENFRAME_IO_PADS-1:0] gpio_in_h,
    output [OPENFRAME_IO_PADS-1:0] gpio_out,
    output [OPENFRAME_IO_PADS-1:0] gpio_oeb,
    output [OPENFRAME_IO_PADS-1:0] gpio_inp_dis,	// a.k.a. ieb

    /* Pad configuration.  These signals are usually static values.
     * See the documentation for the sky130_fd_io__gpiov2 cell signals
     * and their use.
     */
    output [OPENFRAME_IO_PADS-1:0] gpio_ib_mode_sel,
    output [OPENFRAME_IO_PADS-1:0] gpio_vtrip_sel,
    output [OPENFRAME_IO_PADS-1:0] gpio_slow_sel,
    output [OPENFRAME_IO_PADS-1:0] gpio_holdover,
    output [OPENFRAME_IO_PADS-1:0] gpio_analog_en,
    output [OPENFRAME_IO_PADS-1:0] gpio_analog_sel,
    output [OPENFRAME_IO_PADS-1:0] gpio_analog_pol,
    output [OPENFRAME_IO_PADS-1:0] gpio_dm2,
    output [OPENFRAME_IO_PADS-1:0] gpio_dm1,
    output [OPENFRAME_IO_PADS-1:0] gpio_dm0,

    /* These signals correct directly to the pad.  Pads using analog I/O
     * connections should keep the digital input and output buffers turned
     * off.  Both signals connect to the same pad.  The "noesd" signal
     * is a direct connection to the pad;  the other signal connects through
     * a series resistor which gives it minimal ESD protection.  Both signals
     * have basic over- and under-voltage protection at the pad.  These
     * signals may be expected to attenuate heavily above 50MHz.
     */
    inout  [OPENFRAME_IO_PADS-1:0] analog_io,
    inout  [OPENFRAME_IO_PADS-1:0] analog_noesd_io,

    /* These signals are constant one and zero in the 1.8V domain, one for
     * each GPIO pad, and can be looped back to the control signals on the
     * same GPIO pad to set a static configuration at power-up.
     */
    input  [OPENFRAME_IO_PADS-1:0] gpio_loopback_one,
    input  [OPENFRAME_IO_PADS-1:0] gpio_loopback_zero


);


assign gpio_ib_mode_sel =  gpio_in;
assign gpio_out         =  gpio_in;
assign gpio_oeb         =  gpio_in;



endmodule
