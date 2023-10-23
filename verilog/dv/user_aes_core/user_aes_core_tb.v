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
////  This file is part of the Riscduino cores project            ////
////                                                              ////
////  Description                                                 ////
////      To validate AES IP Encription & Decription              ////
////                                                              ////
////  To Do:                                                      ////
////    nothing                                                   ////
////                                                              ////
////  Author(s):                                                  ////
////      - Dinesh Annayya, dinesha@opencores.org                 ////
////                                                              ////
////  Revision :                                                  ////
////    0.1 - 7th Nov 2022, Dinesh A                              ////
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

`define TB_TOP  user_aes_core_tb

`include "bfm_spim.v"
module `TB_TOP;

parameter real CLK1_PERIOD  = 20; // 50Mhz
parameter real CLK2_PERIOD = 2.5;
parameter real IPLL_PERIOD = 5.008;
parameter real XTAL_PERIOD = 6;

`include "user_tasks.sv"


//----------------------------------
// Uart Configuration
// ---------------------------------
reg [1:0]  uart_data_bit        ;
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



     /************* Port-B Mapping **********************************
      *   pin-29                      PA0/trst_n/sm_a1                            digital_io[0] -
      *   pin-30                      PA1/tck/sm_a2                               digital_io[1] -
      *   pin-31                      PA2/tms/sm_b1                               digital_io[2] -
      *   pin-32                      PA3/tdi/sm_b2                               digital_io[3] -
      *   pin-33                      PA4/tdo                                     digital_io[4] -
      *   pin-34                      PA5                                         digital_io[5] -
      *   pin-35                      PA6                                         digital_io[6] -
      *   pin-36                      PA7                                         digital_io[7] -
     *   ********************************************************/

     wire [7:0]  port_a_in = {  (io_oeb[7]== 1'b0) ? io_out[7] : 1'b0,
		                        (io_oeb[6]== 1'b0) ? io_out[6] : 1'b0,
		                        (io_oeb[5]== 1'b0) ? io_out[5] : 1'b0,
		                        (io_oeb[4]== 1'b0) ? io_out[4] : 1'b0,
			                    (io_oeb[3]== 1'b0) ? io_out[3] : 1'b0,
			                    (io_oeb[2]== 1'b0) ? io_out[2] : 1'b0,
		                        (io_oeb[1]== 1'b0) ? io_out[1]  : 1'b0,
		                        (io_oeb[0]== 1'b0) ? io_out[0]  : 1'b0
			     };
	initial begin
		test_fail = 0;
	end

	`ifdef WFDUMP
	   initial begin
	   	$dumpfile("simx.vcd");
	   	$dumpvars(2, user_aes_core_tb);
	   	$dumpvars(0, user_aes_core_tb.u_top.u_aes);
	   	$dumpvars(0, user_aes_core_tb.u_top.u_riscv_top);
	   	$dumpvars(0, user_aes_core_tb.u_top.u_pinmux);
	   	$dumpvars(0, user_aes_core_tb.u_top.u_wb_host);
	   end
       `endif

	initial begin

	       $value$plusargs("risc_core_id=%d", d_risc_id);
           init();

               uart_data_bit           = 2'b11;
               uart_stop_bits          = 0; // 0: 1 stop bit; 1: 2 stop bit;
               uart_stick_parity       = 0; // 1: force even parity
               uart_parity_en          = 0; // parity enable
               uart_even_odd_parity    = 1; // 0: odd parity; 1: even parity
               uart_divisor            = 15;// divided by n * 16
               uart_timeout            = 500;// wait time limit
               uart_fifo_enable        = 0;	// fifo mode disable

               #200; // Wait for reset removal
               repeat (10) @(posedge clock);
               $display("Monitor: Standalone User Uart Test Started");
               
               // Remove Wb Reset
               //`SPIM_REG_WRITE(`ADDR_SPACE_WBHOST+`WBHOST_GLBL_CFG,'h1);

               // Enable UART Multi Functional Ports
               `SPIM_REG_WRITE(`ADDR_SPACE_GLBL+`GLBL_CFG_MUTI_FUNC,'h100);
               
                wait_riscv_boot();
               repeat (2) @(posedge clock);
               #1;
		// Remove all the reset
		if(d_risc_id == 0) begin
		     $display("STATUS: Working with Risc core 0");
                   //`SPIM_REG_WRITE(`ADDR_SPACE_GLBL+`GLBL_CFG_CFG0,'h11F);
		end else if(d_risc_id == 1) begin
		     $display("STATUS: Working with Risc core 1");
                     `SPIM_REG_WRITE(`ADDR_SPACE_GLBL+`GLBL_CFG_CFG0,'h21F);
		end else if(d_risc_id == 2) begin
		     $display("STATUS: Working with Risc core 2");
                     `SPIM_REG_WRITE(`ADDR_SPACE_GLBL+`GLBL_CFG_CFG0,'h41F);
		end else if(d_risc_id == 3) begin
		     $display("STATUS: Working with Risc core 3");
                     `SPIM_REG_WRITE(`ADDR_SPACE_GLBL+`GLBL_CFG_CFG0,'h81F);
		end

               repeat (100) @(posedge clock);  // wait for Processor Get Ready

               tb_uart.uart_init;
               `SPIM_REG_WRITE(`ADDR_SPACE_UART0+8'h0,{3'h0,2'b00,1'b1,1'b1,1'b1});  
               tb_uart.control_setup (uart_data_bit, uart_stop_bits,uart_stop_bits, uart_parity_en, uart_even_odd_parity, 
                                              uart_stick_parity, uart_timeout, uart_divisor);

		// Set the PORT-A Direction as Output
                `SPIM_REG_WRITE(`ADDR_SPACE_GPIO+`GPIO_CFG_DSEL,'h000000FF);
		// Set the GPIO Output data: 0x00000000
                `SPIM_REG_WRITE(`ADDR_SPACE_GPIO+`GPIO_CFG_ODATA,'h0000000);
   
              fork
	          //begin
              //       repeat (4000000) @(posedge clock); 
	          //end
	          begin
                     wait(port_a_in == 8'h18 || port_a_in == 8'hA8);
                     $display("Breaking loop with port_a: %h",port_a_in);
	          end
	          begin
                     while(1) begin
                        `SPIM_REG_READ(`ADDR_SPACE_GPIO+`GPIO_CFG_ODATA,read_data);
                        repeat (1000) @(posedge clock); 
                     end
	          end
               join_any
	
	       `SPIM_REG_CHECK(`ADDR_SPACE_GLBL+`GLBL_CFG_SOFT_REG_0,32'h00000000);
           `SPIM_REG_CHECK(`ADDR_SPACE_GPIO+`GPIO_CFG_ODATA,32'h00000018);

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
               #1000
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
     s25fl256s #(.mem_file_name("user_aes_core.hex"),
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
