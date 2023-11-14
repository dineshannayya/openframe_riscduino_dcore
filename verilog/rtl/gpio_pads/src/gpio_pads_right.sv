

module gpio_pads_right #(
	parameter OPENFRAME_IO_PADS =15 
        ) (
`ifdef USE_POWER_PINS
         input logic                     vccd               , // User area 1 1.8V supply
         input logic                     vssd               , // User area 1 digital ground
`endif

    // Soc-facing signals
        input  logic                     resetn              ,// Global reset, locally propagated
        input  logic                     serial_shift_rstn   , // Reset Only Shift Register
        input  logic                     serial_clock_in     ,// Global clock, locally propatated
        output logic                     serial_clock_out    ,
        input  logic                     serial_load_in      ,// Register load strobe
        output logic                     serial_load_out     ,

    // Serial data chain for pad configuration
    input  	 logic                       serial_data_in      ,
    output 	 logic                       serial_data_out     ,

    // User-facing signals
    input   logic [OPENFRAME_IO_PADS-1:0] user_gpio_out       ,// User space to pad
    input   logic [OPENFRAME_IO_PADS-1:0] user_gpio_oeb       ,// Output enable (user)
    output	logic [OPENFRAME_IO_PADS-1:0] user_gpio_in        ,// Pad to user space



    /* Basic bidirectional I/O.  Input gpio_in_h is in the 3.3V domain;  all
     * others are in the 1.8v domain.  OEB is output enable, sense inverted.
     */
    input  logic [OPENFRAME_IO_PADS-1:0]  gpio_in            ,
    input  logic [OPENFRAME_IO_PADS-1:0]  gpio_in_h          ,
    output logic [OPENFRAME_IO_PADS-1:0]  gpio_out           ,
    output logic [OPENFRAME_IO_PADS-1:0]  gpio_oeb           ,
    output logic [OPENFRAME_IO_PADS-1:0]  gpio_inp_dis       ,	// a.k.a. ieb

    /* Pad configuration.  These signals are usually static values.
     * See the documentation for the sky130_fd_io__gpiov2 cell signals
     * and their use.
     */
    output logic [OPENFRAME_IO_PADS-1:0]   gpio_ib_mode_sel  ,
    output logic [OPENFRAME_IO_PADS-1:0]   gpio_vtrip_sel    ,
    output logic [OPENFRAME_IO_PADS-1:0]   gpio_slow_sel     ,
    output logic [OPENFRAME_IO_PADS-1:0]   gpio_holdover     ,
    output logic [OPENFRAME_IO_PADS-1:0]   gpio_analog_en    ,
    output logic [OPENFRAME_IO_PADS-1:0]   gpio_analog_sel   ,
    output logic [OPENFRAME_IO_PADS-1:0]   gpio_analog_pol   ,
    output logic [OPENFRAME_IO_PADS-1:0]   gpio_dm2          ,
    output logic [OPENFRAME_IO_PADS-1:0]   gpio_dm1          ,
    output logic [OPENFRAME_IO_PADS-1:0]   gpio_dm0          



);

logic [OPENFRAME_IO_PADS-1:0] serial_clock;
logic [OPENFRAME_IO_PADS-1:0] serial_load;
logic [OPENFRAME_IO_PADS-1:0] serial_data;
logic [OPENFRAME_IO_PADS-1:0] serial_clock_chain;
logic [OPENFRAME_IO_PADS-1:0] serial_load_chain;
logic [OPENFRAME_IO_PADS-1:0] serial_data_chain;

assign serial_clock_out = serial_clock_chain[OPENFRAME_IO_PADS-1];
assign serial_data_out  = serial_data_chain[OPENFRAME_IO_PADS-1];
assign serial_load_out  = serial_load_chain[OPENFRAME_IO_PADS-1];

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
         .PAD_CTRL_BITS(16),
         .GPIO_DEFAULTS(16'h3000)
     ) gpio_ctrl_(
         `ifdef USE_POWER_PINS
         .vccd                (vccd                          ),
         .vssd                (vssd                          ),
         `endif
     
     
         // Management Soc-facing signals
         .resetn              (resetn                        ),		// Global reset, locally propagated
         .serial_shift_rstn   (serial_shift_rstn             ),
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
