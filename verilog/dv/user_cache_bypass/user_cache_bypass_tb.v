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
////   This is a standalone test bench to validate the            ////
////   Digital core with Risc core executing code from TCM/SRAM.  ////
////   with icache and dcache bypass mode                         ////
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

`define TB_TOP  user_cache_bypass_tb

`include "bfm_spim.v"

module `TB_TOP;
parameter real CLK1_PERIOD  = 25;
parameter real CLK2_PERIOD = 2.5;
parameter real IPLL_PERIOD = 5.008;
parameter real XTAL_PERIOD = 6;

`include "user_tasks.sv"


reg  [15:0]    strap_in;

	`ifdef WFDUMP
	   initial begin
	   	$dumpfile("simx.vcd");
	   	$dumpvars(2, `TB_TOP);
	   	$dumpvars(0, `TB_TOP.u_top.u_riscv_top);
	   	$dumpvars(0, `TB_TOP.u_top.u_qspi_master);
	   end
       `endif

	initial begin

		$value$plusargs("risc_core_id=%d", d_risc_id);

        strap_in = PAD_STRAP;
        strap_in[`PSTRAP_RISCV_CACHE_BYPASS] = 1'b1;
        // Aplly the Strap
        apply_strap(strap_in);

        // Cross-check if the icache/dcache bypass flag is set
        wait(u_top.u_riscv_top.cfg_bypass_icache == 1'b1);
        wait(u_top.u_riscv_top.cfg_bypass_dcache == 1'b1);

	    repeat (10) @(posedge clock);
		$display("Monitor: Standalone User Risc Boot Test Started");

        // wait for risc execution started 
        wait_riscv_boot();
		$display("Monitor: RISCV execution started");

        // wait for risc execution Completed 
        wait_riscv_exit();
		$display("Monitor: RISCV execution completed");
		// User RISC core expect to write these value in global
		// register, read back and decide on pass fail
		// 0x30000018  = 0x11223344; 
        // 0x3000001C  = 0x22334455; 
        // 0x30000020  = 0x33445566; 
        // 0x30000024  = 0x44556677; 
        // 0x30000028 = 0x55667788; 
        // 0x3000002C = 0x66778899; 

        test_fail = 0;
		`SPIM_REG_CHECK(`ADDR_SPACE_GLBL+`GLBL_CFG_SOFT_REG_0,32'h11223344);
		`SPIM_REG_CHECK(`ADDR_SPACE_GLBL+`GLBL_CFG_SOFT_REG_1,32'h22334455);
		`SPIM_REG_CHECK(`ADDR_SPACE_GLBL+`GLBL_CFG_SOFT_REG_2,32'h33445566);
		`SPIM_REG_CHECK(`ADDR_SPACE_GLBL+`GLBL_CFG_SOFT_REG_3,32'h44556677);
		`SPIM_REG_CHECK(`ADDR_SPACE_GLBL+`GLBL_CFG_SOFT_REG_4,32'h55667788);
		`SPIM_REG_CHECK(`ADDR_SPACE_GLBL+`GLBL_CFG_SOFT_REG_5,32'h66778899);


	   
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
     s25fl256s #(.mem_file_name("user_cache_bypass.hex"),
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



endmodule
`include "s25fl256s.sv"
`default_nettype wire
