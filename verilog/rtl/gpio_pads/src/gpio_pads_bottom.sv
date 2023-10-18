

module gpio_pads_bottom #(
	parameter OPENFRAME_IO_PADS =6 
        ) (
`ifdef USE_POWER_PINS
         input logic                     vccd               , // User area 1 1.8V supply
         input logic                     vssd               , // User area 1 digital ground
`endif

    // Soc-facing signals
    input  	                            resetn              ,// Global reset, locally propagated
    input  	                            serial_clock_in     ,// Global clock, locally propatated
    output  	                        serial_clock_out    ,
    input	                            serial_load_in      ,// Register load strobe
    output	                            serial_load_out     ,

    // Serial data chain for pad configuration
    input  	                            serial_data_in      ,
    output reg	                        serial_data_out     ,

    // User-facing signals
    input   [OPENFRAME_IO_PADS-1:0]     user_gpio_out       ,// User space to pad
    input   [OPENFRAME_IO_PADS-1:0]     user_gpio_oeb       ,// Output enable (user)
    output	[OPENFRAME_IO_PADS-1:0]     user_gpio_in        ,// Pad to user space



    /* Basic bidirectional I/O.  Input gpio_in_h is in the 3.3V domain;  all
     * others are in the 1.8v domain.  OEB is output enable, sense inverted.
     */
    input  [OPENFRAME_IO_PADS-1:0]      gpio_in            ,
    input  [OPENFRAME_IO_PADS-1:0]      gpio_in_h          ,
    output [OPENFRAME_IO_PADS-1:0]      gpio_out           ,
    output [OPENFRAME_IO_PADS-1:0]      gpio_oeb           ,
    output [OPENFRAME_IO_PADS-1:0]      gpio_inp_dis       ,	// a.k.a. ieb

    /* Pad configuration.  These signals are usually static values.
     * See the documentation for the sky130_fd_io__gpiov2 cell signals
     * and their use.
     */
    output [OPENFRAME_IO_PADS-1:0]      gpio_ib_mode_sel  ,
    output [OPENFRAME_IO_PADS-1:0]      gpio_vtrip_sel    ,
    output [OPENFRAME_IO_PADS-1:0]      gpio_slow_sel     ,
    output [OPENFRAME_IO_PADS-1:0]      gpio_holdover     ,
    output [OPENFRAME_IO_PADS-1:0]      gpio_analog_en    ,
    output [OPENFRAME_IO_PADS-1:0]      gpio_analog_sel   ,
    output [OPENFRAME_IO_PADS-1:0]      gpio_analog_pol   ,
    output [OPENFRAME_IO_PADS-1:0]      gpio_dm2          ,
    output [OPENFRAME_IO_PADS-1:0]      gpio_dm1          ,
    output [OPENFRAME_IO_PADS-1:0]      gpio_dm0          ,

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

logic [OPENFRAME_IO_PADS-1:0] serial_clock;
logic [OPENFRAME_IO_PADS-1:0] serial_load;
logic [OPENFRAME_IO_PADS-1:0] serial_data;
logic [OPENFRAME_IO_PADS-1:0] serial_clock_chain;
logic [OPENFRAME_IO_PADS-1:0] serial_load_chain;
logic [OPENFRAME_IO_PADS-1:0] serial_data_chain;

assign serial_clock_out = serial_clock_chain[OPENFRAME_IO_PADS-1:0];
assign serial_data_out = serial_data_chain[OPENFRAME_IO_PADS-1:0];
assign serial_load_out = serial_load_chain[OPENFRAME_IO_PADS-1:0];

generate
genvar tcnt;
   for (tcnt = 0; $unsigned(tcnt) < OPENFRAME_IO_PADS; tcnt=tcnt+1) begin : bit_
     if (tcnt == 0) begin
        assign serial_clock[0]       = serial_clock_in;
        assign serial_load[0]        = serial_load_in;
        assign serial_data[0]        = serial_data_in;
     end else begin
        assign serial_clock[tcnt]    = serial_clock_chain[tcnt-1];
        assign serial_load[tcnt]     = serial_load_chain[tcnt-1];
        assign serial_data[tcnt]     = serial_data_chain[tcnt-1];
     end

     gpio_control_block #(
         .PAD_CTRL_BITS(12),
         .GPIO_DEFAULTS(12'hC00)
     ) gpio_ctrl_(
         `ifdef USE_POWER_PINS
         .vccd                (vccd                          ),
         .vssd                (vssd                          ),
         `endif
     
     
         // Management Soc-facing signals
         .resetn              (resetn                        ),		// Global reset, locally propagated
         .serial_clock        (serial_clock[tcnt]            ),		// Global clock, locally propatated
         .serial_clock_out    (serial_clock_chain[tcnt]      ),
         .serial_load         (serial_load[tcnt]             ),		// Register load strobe
         .serial_load_out     (serial_load_chain[tcnt]       ),
     
     
         // Serial data chain for pad configuration
         .serial_data_in      (serial_data[tcnt]             ),
         .serial_data_out     (serial_data_chain[tcnt]       ),
     
         // User-facing signals
         .user_gpio_out       (user_gpio_out[tcnt]           ),		// User space to pad
         .user_gpio_oeb       (user_gpio_oeb[tcnt]           ),		// Output enable (user)
         .user_gpio_in        (user_gpio_in[tcnt]            ),		// Pad to user space
     
         // Pad-facing signals (Pad GPIOv2)
         .pad_gpio_holdover   (gpio_holdover[tcnt]       ),
         .pad_gpio_slow_sel   (gpio_slow_sel[tcnt]       ),
         .pad_gpio_vtrip_sel  (gpio_vtrip_sel[tcnt]      ),
         .pad_gpio_inenb      (gpio_inp_dis[tcnt]        ),
         .pad_gpio_ib_mode_sel(gpio_ib_mode_sel[tcnt]    ),
         .pad_gpio_ana_en     (gpio_analog_en[tcnt]      ),
         .pad_gpio_ana_sel    (gpio_analog_sel[tcnt]     ),
         .pad_gpio_ana_pol    (gpio_analog_pol[tcnt]     ),
         .pad_gpio_dm2        (gpio_dm2[tcnt]            ),
         .pad_gpio_dm1        (gpio_dm1[tcnt]            ),
         .pad_gpio_dm0        (gpio_dm0[tcnt]            ),
         .pad_gpio_outenb     (gpio_oeb[tcnt]            ),
         .pad_gpio_out        (gpio_out[tcnt]            ),
         .pad_gpio_in         (gpio_in[tcnt]             )
     
     );
   end
endgenerate

endmodule
