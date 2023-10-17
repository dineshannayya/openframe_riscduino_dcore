// SPDX-FileCopyrightText: 2020 Efabless Corporation
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// SPDX-License-Identifier: Apache-2.0

`default_nettype none
/* 
 *---------------------------------------------------------------------
 * See gpio_control_block for description.  This module is like
 * gpio_contro_block except that it has an additional two management-
 * Soc-facing pins, which are the out_enb line and the output line.
 * If the chip is configured for output with the oeb control
 * register = 1, then the oeb line is controlled by the additional
 * signal from the management SoC.  If the oeb control register = 0,
 * then the output is disabled completely.  The "io" line is input
 * only in this module.
 *
 *---------------------------------------------------------------------
 */

/*
 *---------------------------------------------------------------------
 *
 * This module instantiates a shift register chain that passes through
 * each gpio cell.  These are connected end-to-end around the padframe
 * periphery.  The purpose is to avoid a massive number of control
 * wires between the digital core and I/O, passing through the user area.
 *
 * See mprj_ctrl.v for the module that registers the data for each
 * I/O and drives the input to the shift register.
 *
 * Modified 7/24/2022 by Tim Edwards
 * Replaced the data delay with a negative edge-triggered flop
 * so that the serial data bit out from the module only changes on
 * the clock half cycle.  This avoids the need to fine-tune the clock
 * skew between GPIO blocks.
 *
 * Modified 10/05/2022 by Tim Edwards
 *
 *---------------------------------------------------------------------
 */

module gpio_control_block #(
    parameter PAD_CTRL_BITS = 12,
    parameter GPIO_DEFAULTS = 12'hC00
) (
    `ifdef USE_POWER_PINS
         inout vccd,
         inout vssd,
    `endif


    // Soc-facing signals
    input  	     resetn,		     // Global reset, locally propagated
    input  	     serial_clock,		// Global clock, locally propatated
    output  	 serial_clock_out,
    input	     serial_load,		// Register load strobe
    output	     serial_load_out,


    // Serial data chain for pad configuration
    input  	     serial_data_in,
    output reg	 serial_data_out,

    // User-facing signals
    input        user_gpio_out,		// User space to pad
    input        user_gpio_oeb,		// Output enable (user)
    output	     user_gpio_in,		// Pad to user space

    // Pad-facing signals (Pad GPIOv2)
    output	     pad_gpio_holdover,
    output	     pad_gpio_slow_sel,
    output	     pad_gpio_vtrip_sel,
    output       pad_gpio_inenb,
    output       pad_gpio_ib_mode_sel,
    output	     pad_gpio_ana_en,
    output	     pad_gpio_ana_sel,
    output	     pad_gpio_ana_pol,
    output       pad_gpio_dm2,
    output       pad_gpio_dm1,
    output       pad_gpio_dm0,
    output       pad_gpio_outenb,
    output	     pad_gpio_out,
    input	     pad_gpio_in

);

    /* Parameters defining the bit offset of each function in the chain */
    localparam OEB = 0;
    localparam HLDH = 1;
    localparam INP_DIS = 2;
    localparam MOD_SEL = 3;
    localparam AN_EN = 4;
    localparam AN_SEL = 5;
    localparam AN_POL = 6;
    localparam SLOW = 7;
    localparam TRIP = 8;
    localparam DM = 9;

    /* Internally registered signals */
    reg	 	    gpio_holdover   ;
    reg	 	    gpio_slow_sel   ;
    reg	  	    gpio_vtrip_sel  ;
    reg  	    gpio_inenb      ;
    reg	 	    gpio_ib_mode_sel;
    reg  	    gpio_outenb     ;
    reg [2:0] 	gpio_dm         ;
    reg	 	    gpio_ana_en     ;
    reg	 	    gpio_ana_sel    ;
    reg	 	    gpio_ana_pol    ;

    /* Derived output values */
    wire	    one_unbuf       ;
    wire	    zero_unbuf      ;

    //wire user_gpio_in;
    wire        gpio_logic1     ;

    /* Serial shift for the above (latched) values */
    reg [PAD_CTRL_BITS-1:0] shift_register;

    /* Latch the output on the clock negative edge */
    always @(negedge serial_clock or negedge resetn) begin
	if (resetn == 1'b0) begin
	    /* Clear the shift register output */
	    serial_data_out <= 1'b0;
        end else begin
	    serial_data_out <= shift_register[PAD_CTRL_BITS-1];
	end
    end

    /* Propagate the clock and reset signals so that they aren't wired	*/
    /* all over the chip, but are just wired between the blocks.	*/
    assign serial_clock_out = serial_clock;
    assign serial_load_out = serial_load;

    always @(posedge serial_clock or negedge resetn) begin
	if (resetn == 1'b0) begin
	    /* Clear shift register */
	    shift_register <= 'd0;
	end else begin
	    /* Shift data in */
	    shift_register <= {shift_register[PAD_CTRL_BITS-2:0], serial_data_in};
	end
    end


    always @(posedge serial_load or negedge resetn) begin
	if (resetn == 1'b0) begin
	    /* Initial state on reset depends on applied defaults */
	    gpio_holdover    <= GPIO_DEFAULTS[HLDH];
	    gpio_slow_sel    <= GPIO_DEFAULTS[SLOW];
	    gpio_vtrip_sel   <= GPIO_DEFAULTS[TRIP];
        gpio_ib_mode_sel <= GPIO_DEFAULTS[MOD_SEL];
	    gpio_inenb       <= GPIO_DEFAULTS[INP_DIS];
	    gpio_outenb      <= GPIO_DEFAULTS[OEB];
	    gpio_dm          <= GPIO_DEFAULTS[DM+2:DM];
	    gpio_ana_en      <= GPIO_DEFAULTS[AN_EN];
	    gpio_ana_sel     <= GPIO_DEFAULTS[AN_SEL];
	    gpio_ana_pol     <= GPIO_DEFAULTS[AN_POL];
	end else begin
	    /* Load data */
	    gpio_outenb      <= shift_register[OEB];
	    gpio_holdover    <= shift_register[HLDH]; 
	    gpio_inenb 	     <= shift_register[INP_DIS];
	    gpio_ib_mode_sel <= shift_register[MOD_SEL];
	    gpio_ana_en      <= shift_register[AN_EN];
	    gpio_ana_sel     <= shift_register[AN_SEL];
	    gpio_ana_pol     <= shift_register[AN_POL];
	    gpio_slow_sel    <= shift_register[SLOW];
	    gpio_vtrip_sel   <= shift_register[TRIP];
	    gpio_dm 	     <= shift_register[DM+2:DM];

	end
    end

    /* These pad configuration signals are static and do not change	*/
    /* after setup.							*/

    assign pad_gpio_holdover 	= gpio_holdover;
    assign pad_gpio_slow_sel 	= gpio_slow_sel;
    assign pad_gpio_vtrip_sel	= gpio_vtrip_sel;
    assign pad_gpio_ib_mode_sel	= gpio_ib_mode_sel;
    assign pad_gpio_ana_en	    = gpio_ana_en;
    assign pad_gpio_ana_sel	    = gpio_ana_sel;
    assign pad_gpio_ana_pol	    = gpio_ana_pol;
    assign pad_gpio_dm2		    = gpio_dm[2];
    assign pad_gpio_dm1		    = gpio_dm[1];
    assign pad_gpio_dm0		    = gpio_dm[0];
    assign pad_gpio_inenb 	    = gpio_inenb;

    assign pad_gpio_outenb = user_gpio_oeb;

    assign pad_gpio_out = user_gpio_out;

    assign user_gpio_in = pad_gpio_in ;



endmodule
`default_nettype wire
