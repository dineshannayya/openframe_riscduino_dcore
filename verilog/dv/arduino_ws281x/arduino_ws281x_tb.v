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
////   This test bench to validate ws281x driver                  ////
////                                                              ////
////  To Do:                                                      ////
////    nothing                                                   ////
////                                                              ////
////  Author(s):                                                  ////
////      - Dinesh Annayya, dinesh.annayya@gmail.com              ////
////                                                              ////
////  Revision :                                                  ////
////    0.1 - 29th July 2022, Dinesh A                            ////
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
`include "is62wvs1288.v"
`include "uart_agent.v"
`include "bfm_ws281x.sv"
`include "user_params.svh"

`define TB_HEX "arduino_ws281x.hex"
`define TB_TOP arduino_ws281x_tb
`include "bfm_spim.v"
module `TB_TOP;
parameter real CLK1_PERIOD  = 20; // 50Mhz
parameter real CLK2_PERIOD = 2.5;
parameter real IPLL_PERIOD = 5.008;
parameter real XTAL_PERIOD = 6;

`include "user_tasks.sv"

	reg            flag                 ;
    reg            compare_start        ; // User Need to make sure that compare start match with RiscV core completing initial booting

	reg [31:0]     rx_wcnt              ;
	reg [31:0]     check_sum            ;
        

         integer i,j;

//-----------------------------------------------
// WS281X BFM integration
//----------------------------------------------
parameter WS2811_LS  = 0;
parameter WS2811_HS  = 1;
parameter WS2812_HS  = 2;
parameter WS2812S_HS = 3;
parameter WS2812B_HS = 4;

wire [3:0] ws281x_port ;
reg        ws281x_enb ;



	// 50Mhz CLock
	always #10 clock <= (clock === 1'b0);

	initial begin
	clock = 0;
	flag  = 0;
        compare_start = 0;
	end

	`ifdef WFDUMP
	   initial begin
	   	$dumpfile("simx.vcd");
	   	$dumpvars(3, `TB_TOP);
	   	$dumpvars(0, `TB_TOP.u_top.u_riscv_top);
	   	$dumpvars(0, `TB_TOP.u_top.u_pinmux);
	   	$dumpvars(0, `TB_TOP.u_top.u_uart_i2c_usb_spi);
	   end
       `endif




/**********************************************************************
    Arduino Digital PinMapping
* Pin Mapping    Arduino              ATMGE CONFIG
*   ATMEGA328     Port                                        caravel Pin Mapping
*   Pin-1         22            PC6/WS[0]/RESET*                digital_io[22]
*   Pin-2         0             PD0/WS[0]/RXD[0]                digital_io[24]
*   Pin-3         1             PD1/WS[0]/TXD[0]                digital_io[25]
*   Pin-4         2             PD2/WS[0]/RXD[1]/INT0           digital_io[26]
*   Pin-5         3             PD3/WS[1]INT1/OC2B(PWM0)        digital_io[27]
*   Pin-6         4             PD4/WS[1]TXD[1]                 digital_io[28]
*   Pin-7                       VCC                  -
*   Pin-8                       GND                  -
*   Pin-9         20            PB6/WS[1]/XTAL1/TOSC1           digital_io[14]
*   Pin-10        21            PB7/WS[1]/XTAL2/TOSC2           digital_io[15]
*   Pin-11        5             PD5/WS[0]/SS[3]/OC0B(PWM1)/T1   digital_io[29]
*   Pin-12        6             PD6/WS[0]/SS[2]/OC0A(PWM2)/AIN0 digital_io[30]/analog_io[2]
*   Pin-13        7             PD7/WS[0]/A1N1                  digital_io[31]/analog_io[3]
*   Pin-14        8             PB0/WS[0]/CLKO/ICP1             digital_io[8]
*   Pin-15        9             PB1/WS[1]/SS[1]OC1A(PWM3)       digital_io[9]
*   Pin-16        10            PB2/WS[1]/SS[0]/OC1B(PWM4)      digital_io[10]
*   Pin-17        11            PB3/WS[1]/MOSI/OC2A(PWM5)       digital_io[11]
*   Pin-18        12            PB4/WS[1]/MISO                  digital_io[12]
*   Pin-19        13            PB5/SCK                         digital_io[13]
*   Pin-20                      AVCC                -
*   Pin-21                      AREF                            analog_io[10]
*   Pin-22                      GND                 -
*   Pin-23        14            PC0/ADC0                        digital_io[16]/analog_io[11]
*   Pin-24        15            PC1/ADC1                        digital_io[17]/analog_io[12]
*   Pin-25        16            PC2/ADC2                        digital_io[18]/analog_io[13]
*   Pin-26        17            PC3/ADC3                        digital_io[19]/analog_io[14]
*   Pin-27        18            PC4/ADC4/SDA                    digital_io[20]/analog_io[15]
*   Pin-28        19            PC5/ADC5/SCL                    digital_io[21]/analog_io[16]
*****************************************************************************/


	initial begin

        ws281x_enb              = 0;

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

        wait_riscv_boot();
        repeat (100) @(posedge clock);  // wait for Processor Get Ready


        repeat (1000) @(posedge clock);  // wait for Processor Get Ready
        ws281x_enb = 1;
	    flag  = 0;
		check_sum = 0;
        compare_start = 1;
        
        fork
           begin
              wait(u_ws281x_port0.rx_wcnt == 16);
              wait(u_ws281x_port1.rx_wcnt == 16);
              wait(u_ws281x_port2.rx_wcnt == 16);
              wait(u_ws281x_port3.rx_wcnt == 16);
           end
           begin
              repeat (300000) @(posedge clock);  // wait for Processor Get Ready
           end
           join_any
        
           #1000
        
           test_fail = 0;
           rx_wcnt = u_ws281x_port0.rx_wcnt + u_ws281x_port1.rx_wcnt + u_ws281x_port2.rx_wcnt + u_ws281x_port3.rx_wcnt;
           check_sum = u_ws281x_port0.check_sum + u_ws281x_port1.check_sum + u_ws281x_port2.check_sum + u_ws281x_port3.check_sum;

		   $display("Total Rx Cnt: %d Check Sum : %x ",rx_wcnt, check_sum);
           // Check 
           // if all the 102 byte received
           // if no error 
           if(rx_wcnt != 64) test_fail = 1;
           if(check_sum != 32'h2f0e0) test_fail = 1;

	   
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

   wire spiram_csb = (io_oeb[35] == 1'b0) ? io_out[35] : 1'b0;

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

//-----------------------------------------------
// WS281X BFM integration
//----------------------------------------------
assign ws281x_port[0] = (io_oeb[26] == 1'b0) ? io_out[26] : 1'b0;

bfm_ws281x #(
              .PORT_ID(0),
              .MODE(WS2811_HS)) u_ws281x_port0(
                  .reset_n   (!wb_rst_i     ),
                  .clk       (clock         ),
                  .enb       (ws281x_enb    ),
                  .rxd       (ws281x_port[0])
               );

//-----------------------------------------------
// WS281X BFM integration
//----------------------------------------------
assign ws281x_port[1] = (io_oeb[27] == 1'b0 ) ? io_out[27] : 1'b0;

bfm_ws281x #(
              .PORT_ID(1),
              .MODE(WS2811_HS)) u_ws281x_port1(
                  .reset_n   (!wb_rst_i     ),
                  .clk       (clock         ),
                  .enb       (ws281x_enb    ),
                  .rxd       (ws281x_port[1])
               );

//-----------------------------------------------
// WS281X BFM integration
//----------------------------------------------
assign ws281x_port[2] = (io_oeb[29] == 1'b0) ? io_out[29] : 1'b0 ;

bfm_ws281x #(
              .PORT_ID(2),
              .MODE(WS2811_HS)) u_ws281x_port2(
                  .reset_n   (!wb_rst_i     ),
                  .clk       (clock         ),
                  .enb       (ws281x_enb    ),
                  .rxd       (ws281x_port[2])
               );

//-----------------------------------------------
// WS281X BFM integration
//----------------------------------------------
assign ws281x_port[3] = (io_oeb[9] == 1'b0) ? io_out[9] : 1'b0 ;

bfm_ws281x #(
              .PORT_ID(3),
              .MODE(WS2811_HS)) u_ws281x_port3(
                  .reset_n   (!wb_rst_i     ),
                  .clk       (clock         ),
                  .enb       (ws281x_enb    ),
                  .rxd       (ws281x_port[3])
               );
endmodule
`include "s25fl256s.sv"
`default_nettype wire
