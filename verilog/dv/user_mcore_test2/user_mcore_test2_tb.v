////////////////////////////////////////////////////////////////////////////
// SPDX-FileCopyrightText:  2021 , Dinesh Annayya
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
// SPDX-FileContributor: Modified by Dinesh Annayya <dinesha@opencores.org>
//////////////////////////////////////////////////////////////////////
////                                                              ////
////  Standalone User validation Test bench                       ////
////                                                              ////
////  This file is part of the riscduino cores project            ////
////                                                              ////
////  Description                                                 ////
////   This is a standalone test bench to validate the            ////
////   Digital core multi-core behaviour.                         ////
////                                                              ////
////  To Do:                                                      ////
////    nothing                                                   ////
////                                                              ////
////  Author(s):                                                  ////
////      - Dinesh Annayya, dinesha@opencores.org                 ////
////                                                              ////
////  Revision :                                                  ////
////    0.1 - 16th Feb 2021, Dinesh A                             ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2000 Authors and OPENCORES.ORG                 ////
////                                                              ////
//// This source file may be used and distributed without         ////
//// restriction provided that this copyright statement is not    ////
//// removed from the file and that any derivative work contains  ////
//// the original copyright notice and the associated disclaimer. ////
////                                                              ////
//// This source file is free software; you can redistribute it   ////
//// and/or modify it under the terms of the GNU Lesser General   ////
//// Public License as published by the Free Software Foundation; ////
//// either version 2.1 of the License, or (at your option) any   ////
//// later version.                                               ////
////                                                              ////
//// This source is distributed in the hope that it will be       ////
//// useful, but WITHOUT ANY WARRANTY; without even the implied   ////
//// warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR      ////
//// PURPOSE.  See the GNU Lesser General Public License for more ////
//// details.                                                     ////
////                                                              ////
//// You should have received a copy of the GNU Lesser General    ////
//// Public License along with this source; if not, download it   ////
//// from http://www.opencores.org/lgpl.shtml                     ////
////                                                              ////
//////////////////////////////////////////////////////////////////////

`default_nettype wire

`timescale 1 ns / 1 ns

`include "sram_macros/sky130_sram_2kbyte_1rw1r_32x512_8.v"
`include "uart_agent.v"
`include "user_params.svh"

`define TB_HEX_FILE "user_mcore_test2.hex"
`define TB_TOP    user_mcore_test2_tb

`include "bfm_spim.v"
module `TB_TOP;
parameter real CLK1_PERIOD  = 20; // 50Mhz
parameter real CLK2_PERIOD = 2.5;
parameter real IPLL_PERIOD = 5.008;
parameter real XTAL_PERIOD = 6;

`include "user_tasks.sv"

        // Uart Configuration
        // ---------------------------------
        reg [1:0]      uart_data_bit        ;
        reg	       uart_stop_bits       ; // 0: 1 stop bit; 1: 2 stop bit;
        reg	       uart_stick_parity    ; // 1: force even parity
        reg	       uart_parity_en       ; // parity enable
        reg	       uart_even_odd_parity ; // 0: odd parity; 1: even parity
        
        reg [7:0]      uart_data            ;
        reg [15:0]     uart_divisor         ;	// divided by n * 16
        reg [15:0]     uart_timeout         ;// wait time limit
        
        reg [15:0]     uart_rx_nu           ;
        reg [15:0]     uart_tx_nu           ;
        reg [7:0]      uart_write_data [0:39];
        reg 	       uart_fifo_enable     ;	// fifo mode disable
	reg            flag                 ;

	reg [31:0]     check_sum            ;
    reg [7:0]      test_start           ;

         integer i,j;
	initial begin
        test_start    = 0;
	    flag          = 0;
	end

	`ifdef WFDUMP
	   initial begin
	   	$dumpfile("simx.vcd");
	   	$dumpvars(1, `TB_TOP);
	   	$dumpvars(0, `TB_TOP.tb_uart);
	   	$dumpvars(1, `TB_TOP.u_top);
	   	$dumpvars(0, `TB_TOP.u_top.u_riscv_top);
	   	$dumpvars(0, `TB_TOP.u_top.u_uart_i2c_usb_spi);
	   	$dumpvars(0, `TB_TOP.u_top.u_pinmux);
	   end
       `endif

	initial begin
               uart_data_bit           = 2'b11;
               uart_stop_bits          = 0; // 0: 1 stop bit; 1: 2 stop bit;
               uart_stick_parity       = 0; // 1: force even parity
               uart_parity_en          = 0; // parity enable
               uart_even_odd_parity    = 1; // 0: odd parity; 1: even parity
	           tb_set_uart_baud(50000000,1152000,uart_divisor);// 50Mhz Ref clock, Baud Rate: 230400
               uart_timeout            = 2000;// wait time limit
               uart_fifo_enable        = 0;	// fifo mode disable

		$value$plusargs("risc_core_id=%d", d_risc_id);

       init();


		#200; // Wait for reset removal
	        repeat (10) @(posedge clock);
		$display("Monitor: Standalone User Risc Boot Test Started");

  
		// Remove Wb Reset
		//`SPIM_REG_WRITE(`ADDR_SPACE_WBHOST+`WBHOST_GLBL_CFG,'h1);

	        repeat (2) @(posedge clock);
		#1;
		// Remove all the reset
		$display("STATUS: Working with Both core Risc core 0 & 1 ");
        `SPIM_REG_WRITE(`ADDR_SPACE_GLBL+`GLBL_CFG_CFG0,'h31F);


	    tb_uart.debug_mode = 0; // disable debug display
        tb_uart.uart_init;
        tb_uart.control_setup (uart_data_bit, uart_stop_bits,uart_stop_bits, uart_parity_en, uart_even_odd_parity, uart_stick_parity, uart_timeout, uart_divisor);

        wait_riscv_boot();
        set_tb_ready();


	    flag  = 0;
		check_sum = 0;
        test_start    = 1;
            
        fork
           begin
              while(flag == 0)
              begin
                 tb_uart.read_char(read_data,flag);
		         if(flag == 0)  begin
		            $write ("%c",read_data);
		            check_sum = check_sum+read_data;
		         end
              end
           end
           begin
              repeat (600000) @(posedge clock);  // wait for Processor Get Ready
           end
           join_any
            
           #100
           tb_uart.report_status(uart_rx_nu, uart_tx_nu);
            

           test_fail = 0;
		   $display("Total Rx Char: %d Check Sum : %x ",uart_rx_nu, check_sum);
             // Check 
             // if all the 4224 byte received
             // if no error 
             if(uart_rx_nu != 216) test_fail = 1;
             if(check_sum != 32'h44f0) test_fail = 1;
             if(tb_uart.err_cnt != 0) test_fail = 1;

	   
	    	$display("###################################################");
          	if(test_fail == 0) begin
		   `ifdef GL
	    	       $display("Monitor: %m (GL) Passed");
		   `else
		       $display("Monitor: %m (RTL) Passed");
		   `endif
	        end else begin
		    `ifdef GL
	    	        $display("Monitor: %m (GL) Failed");
		    `else
		        $display("Monitor: %m (RTL) Failed");
		    `endif
		 end
	    	$display("###################################################");
	    $finish;
	end



//------------------------------------------------------
//  Integrate the Serial flash with qurd support to
//  user core using the gpio pads
//  ----------------------------------------------------

   wire flash_clk = (io_oeb[32] == 1'b0) ? io_out[32]: 1'b0;
   wire flash_csb = (io_oeb[33] == 1'b0) ? io_out[33]: 1'b0;
   // Creating Pad Delay
   wire #1 io_oeb_37 = io_oeb[37];
   wire #1 io_oeb_38 = io_oeb[38];
   wire #1 io_oeb_39 = io_oeb[39];
   wire #1 io_oeb_40 = io_oeb[40];
   tri  #1 flash_io0 = (io_oeb_37== 1'b0) ? io_out[37] : 1'bz;
   tri  #1 flash_io1 = (io_oeb_38== 1'b0) ? io_out[38] : 1'bz;
   tri  #1 flash_io2 = (io_oeb_39== 1'b0) ? io_out[39] : 1'bz;
   tri  #1 flash_io3 = (io_oeb_40== 1'b0) ? io_out[40] : 1'bz;

   assign io_in[37] = (io_oeb[37] == 1'b1) ? flash_io0: 1'b0;
   assign io_in[38] = (io_oeb[38] == 1'b1) ? flash_io1: 1'b0;
   assign io_in[39] = (io_oeb[39] == 1'b1) ? flash_io2: 1'b0;
   assign io_in[40] = (io_oeb[40] == 1'b1) ? flash_io3: 1'b0;

   // Quard flash
     s25fl256s #(.mem_file_name(`TB_HEX_FILE),
	         .otp_file_name("none"),
                 .TimingModel("S25FL512SAGMFI010_F_30pF")) 
		 u_spi_flash_256mb (
           // Data Inputs/Outputs
       .SI      (flash_io0),
       .SO      (flash_io1),
       // Controls
       .SCK     (flash_clk),
       .CSNeg   (flash_csb),
       .WPNeg   (flash_io2),
       .HOLDNeg (flash_io3),
       .RSTNeg  (!wb_rst_i)

       );


//---------------------------
//  UART Agent integration
// --------------------------
wire uart_txd,uart_rxd;

assign uart_txd   = (io_oeb[25] == 1'b0) ? io_out[25] : 1'b0;
assign io_in[24]   = (io_oeb[24] == 1'b1) ? uart_rxd  : 1'b0;
 
uart_agent tb_uart(
	.mclk                (clock              ),
	.txd                 (uart_rxd           ),
	.rxd                 (uart_txd           )
	);


endmodule
`include "s25fl256s.sv"
`default_nettype wire