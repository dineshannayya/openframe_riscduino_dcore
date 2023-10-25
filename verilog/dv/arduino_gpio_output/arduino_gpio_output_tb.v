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
////  User Risc Core Boot Validation                              ////
////                                                              ////
////  This file is part of the riscduino cores project            ////
////  https://github.com/dineshannayya/riscuino.git               ////
////  http://www.opencores.org/cores/riscuino/                    ////
////                                                              ////
////  Description                                                 ////
////    Validate gpio output                                      ////
////                                                              ////
////  To Do:                                                      ////
////    nothing                                                   ////
////                                                              ////
////  Author(s):                                                  ////
////      - Dinesh Annayya, dinesha@opencores.org                 ////
////                                                              ////
////  Revision :                                                  ////
////    0.1 - 12th June 2021, Dinesh A                            ////
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

`default_nettype none

`timescale 1 ns / 1 ps

`include "sram_macros/sky130_sram_2kbyte_1rw1r_32x512_8.v"
`include "is62wvs1288.v"
`include "user_params.svh"

`define TB_TOP arduino_gpio_output_tb

`include "bfm_spim.v"
module `TB_TOP;
parameter real CLK1_PERIOD  = 20; // 50Mhz
parameter real CLK2_PERIOD = 2.5;
parameter real IPLL_PERIOD = 5.008;
parameter real XTAL_PERIOD = 6;

`include "user_tasks.sv"

integer i,j;


    
    wire [22:0] arduino_gpio = {
                                io_out[22],
                                io_out[15],
                                io_out[14],
                                io_out[21],
                                io_out[20],
                                io_out[19],
                                io_out[18],
                                io_out[17],
                                io_out[16],
                                io_out[13],
                                io_out[12],
                                io_out[11],
                                io_out[10],
                                io_out[9],
                                io_out[8],
                                io_out[31],
                                io_out[30],
                                io_out[29],
                                io_out[28],
                                io_out[27],
                                io_out[26],
                                io_out[25],
                                io_out[24]};


	`ifdef WFDUMP
        initial
        begin
           $dumpfile("simx.vcd");
           $dumpvars(0,`TB_TOP);
           $dumpvars(0,`TB_TOP.u_spi_flash_256mb);
           $dumpvars(0,`TB_TOP.u_sram);
           $dumpvars(1,`TB_TOP.u_top);
           $dumpvars(0,`TB_TOP.u_top.u_wb_host);
           $dumpvars(0,`TB_TOP.u_top.u_pinmux);
           $dumpvars(0,`TB_TOP.u_top.u_qspi_master);
           $dumpvars(0,`TB_TOP.u_top.u_riscv_top);
	       $display("Waveform Dump started");
        end
        `endif

        initial
        begin

        $value$plusargs("risc_core_id=%d", d_risc_id);

         init();

        $display("Status:  Waiting for RISCV Core Boot ... ");
        wait(`TB_TOP.u_top.u_pinmux.u_glbl_reg.reg_15 == 32'h1); // Wait for RISCV Boot Indication
        $display("Status:  RISCV Core is Booted ");

        test_fail = 0;
        fork
        begin
           $display("Start of GPIO High Value validation ...");
           for(i = 0; i < 23; i = i+1) begin
              wait(arduino_gpio[i] == 1'b1); 
              $display("STATUS: Arduino Pin: %d High detected",i);
           end
           $display("End of GPIO High Value validation...");
           $display("Start of GPIO Low Value validation ...");
           for(i = 0; i < 23; i = i+1) begin
              wait(arduino_gpio[i] == 1'b0); 
              $display("STATUS: Arduino Pin: %d Low detected",i);
           end
           $display("End of GPIO Low Value validation...");
           test_fail = 0;
        end
        begin
           repeat (6000000) @(posedge clock);  // wait for Processor Get Ready
           test_fail = 1;
        end
        join_any


        

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
              #100
              $finish;
        end


//-------------------------------------
// Upto MPW_8 partial SRAM is not handled in
// QSPI, Any partial SRAM write access will corrupt the next valid bytes
//--------------------------------------------
event event_psram_wr;

always@(posedge clock)
begin
   if(`TB_TOP.u_top.u_qspi_master.wbd_stb_i == 1'b1 &&
      `TB_TOP.u_top.u_qspi_master.wbd_we_i  == 1'b1 && 
      `TB_TOP.u_top.u_qspi_master.wbd_sel_i != 4'hF && 
      `TB_TOP.u_top.u_qspi_master.wbd_ack_o == 1'b1 )
   begin
        $display("Partitial SRAM Write Detected at %t");
        -> event_psram_wr;
   end
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
     s25fl256s #(.mem_file_name("arduino_gpio_output.hex"),
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



endmodule
`include "s25fl256s.sv"
`default_nettype wire
