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
////  This file is part of the riscdunio cores project            ////
////  https://github.com/dineshannayya/riscdunio.git              ////
////                                                              ////
////  Description                                                 ////
////   This is a standalone test bench to validate the            ////
////   Digital core.                                              ////
////   This test bench to valid Arduino example:                  ////
////     <example><line_follower                >                 ////
////                                                              ////
////  To Do:                                                      ////
////    nothing                                                   ////
////                                                              ////
////  Author(s):                                                  ////
////      - Dinesh Annayya, dinesh.annayya@gmail.com              ////
////                                                              ////
////  Revision :                                                  ////
////    0.1 - 2nd Aug 2023, Dinesh A                              ////
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
`include "is62wvs1288.v"
`include "user_params.svh"

`define TB_HEX "arduino_line_follower.hex"
`define TB_TOP  arduino_line_follower

`include "bfm_spim.v"

module `TB_TOP;
parameter real CLK1_PERIOD  = 20; // 50Mhz
parameter real CLK2_PERIOD = 2.5;
parameter real IPLL_PERIOD = 5.008;
parameter real XTAL_PERIOD = 6;

`include "user_tasks.sv"

	    reg            flag                 ;
        reg [7:0]      dCnt                 ; // DataCount

	    reg [31:0]     check_sum            ;
        

         integer i,j;


	initial begin
	        flag  = 0;
	end

	`ifdef WFDUMP
	   initial begin
	   	$dumpfile("simx.vcd");
	   	$dumpvars(0, `TB_TOP);
	   	//$dumpvars(0, `TB_TOP.u_top.u_riscv_top.i_core_top_0);
	   	//$dumpvars(0, `TB_TOP.u_top.u_riscv_top.u_connect);
	   	//$dumpvars(0, `TB_TOP.u_top.u_riscv_top.u_intf);
	   	$dumpvars(0, `TB_TOP.u_top.u_uart_i2c_usb_spi.u_uart0_core);
	   end
       `endif

/**********************************************************
Left Sensor  -------------> PC3 -  A3/D17  - io[19] -->  Input
Right Sensor -------------> PC0 -  A0/D14  - io[16] -->  Input
Right Motor (+) ----------> PB1 - D9       - io[9] ---> Output
Right Motor (-) ----------> PB2 - D10      - io[10] ---> Output
Left Motor (-) ---------->  PC1 - D15      - io[17] ---> Output
Left Motor (+) ---------->  PC2 - D16      - io[18] ---> Output
Buzzer          ----------> PD4 - D4       - io[28] ---> Output

****************************************************/
reg samp_left_sensor,samp_right_sensor;

wire drv_buzer         = io_out[28];
wire drv_right_motor_p = io_out[9];
wire drv_right_motor_n = io_out[10];
wire drv_left_motor_n  = io_out[17];
wire drv_left_motor_p  = io_out[18];

assign io_in[19]  = samp_left_sensor;
assign io_in[16]  = samp_right_sensor;




    


	initial begin

        samp_left_sensor = 0;
        samp_right_sensor = 0;

		$value$plusargs("risc_core_id=%d", d_risc_id);

		#200; // Wait for reset removal
	    repeat (10) @(posedge clock);
		$display("Monitor: Standalone User Risc Boot Test Started");
   
       init();
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

        repeat (10000) @(posedge clock);  // wait for Processor Get Ready

        fork
        begin 
           begin
              samp_left_sensor = 0;
              samp_right_sensor = 0;
              repeat (2000) @(posedge clock);  
              if(drv_buzer == 0 && drv_right_motor_p  == 1 && drv_right_motor_n == 1 && drv_left_motor_n == 1 && drv_left_motor_p == 1) begin
                 $display("STATUS: left_sensor = 0 and right sensor = 0 test passed");
              end else begin
                 $display("STATUS: left_sensor = 0 and right sensor = 0 test Failed");
                 test_fail = 1;
              end

              repeat (100) @(posedge clock);  
              samp_left_sensor = 0;
              samp_right_sensor = 1;
              repeat (2000) @(posedge clock);  
              if(drv_buzer == 1 && drv_right_motor_p  == 0 && drv_right_motor_n == 0 && drv_left_motor_n == 0 && drv_left_motor_p == 1) begin
                 $display("STATUS: left_sensor = 0 and right sensor = 1 test passed");
              end else begin
                 $display("STATUS: left_sensor = 0 and right sensor = 1 test Failed");
                 test_fail = 1;
              end

              repeat (100) @(posedge clock);  
              samp_left_sensor = 1;
              samp_right_sensor = 0;
              repeat (2000) @(posedge clock);  
              if(drv_buzer == 1 && drv_right_motor_p  == 1 && drv_right_motor_n == 0 && drv_left_motor_n == 0 && drv_left_motor_p == 0) begin
                 $display("STATUS: left_sensor = 1 and right sensor = 0 test passed");
              end else begin
                 $display("STATUS: left_sensor = 1 and right sensor = 0 test Failed");
                 test_fail = 1;
              end

              repeat (100) @(posedge clock);  
              samp_left_sensor = 1;
              samp_right_sensor = 1;
              repeat (2000) @(posedge clock);  
              if(drv_buzer == 1 && drv_right_motor_p  == 1 && drv_right_motor_n == 0 && drv_left_motor_n == 0 && drv_left_motor_p == 1) begin
                 $display("STATUS: left_sensor = 1 and right sensor = 1 test passed");
              end else begin
                 $display("STATUS: left_sensor = 1 and right sensor = 1 test Failed");
                 test_fail = 1;
              end
           end
        end
        begin
           repeat (4000000) @(posedge clock);  // wait for Processor Get Ready
        end
        join_any
                
           #100
           


	    	$display("###################################################");
          	if(test_fail == 0) begin
		   `ifdef GL
	    	   $display("Monitor: %m (GL) Passed");
		   `else
		       $display("Monitor: %m (RTL) Passed");
		   `endif
	        end else begin
		    `ifdef GL
	    	   $display("Monitor: %m  (GL) Failed");
		    `else
		       $display("Monitor: %m (RTL) Failed");
		    `endif
		 end
	    	$display("###################################################");
	    $finish;
	end



`ifndef GL // Drive Power for Hold Fix Buf
    // All standard cell need power hook-up for functionality work
    initial begin

    end
`endif    

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
     s25fl256s #(.mem_file_name(`TB_HEX),
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

   wire spiram_csb = (io_oeb[31] == 1'b0) ? io_out[31] : 1'b0;

   is62wvs1288 #(.mem_file_name("none"))
	u_sram (
         // Data Inputs/Outputs
           .io0     (flash_io0),
           .io1     (flash_io1),
           // Controls
           .clk    (flash_clk),
           .csb    (spiram_csb),
           .io2    (flash_io2),
           .io3    (flash_io3)
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
