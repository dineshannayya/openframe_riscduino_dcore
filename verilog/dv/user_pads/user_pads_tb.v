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
////                                                              ////
////  Description                                                 ////
////   This is a standalone test bench to validate the            ////
////   gpio pads interfaface through External SSPIS.              ////
////                                                              ////
////  To Do:                                                      ////
////    nothing                                                   ////
////                                                              ////
////  Author(s):                                                  ////
////      - Dinesh Annayya, dinesha@opencores.org                 ////
////                                                              ////
////  Revision :                                                  ////
////    0.1 - 12 Nov 2023, Dinesh A                               ////
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

`timescale 1 ns/1 ps

`include "sram_macros/sky130_sram_2kbyte_1rw1r_32x512_8.v"
`include "is62wvs1288.v"
`include "user_params.svh"

`define TB_GLBL user_pads_tb
`define TB_TOP  user_pads_tb
`include "bfm_spim.v"

module `TB_TOP;
parameter real CLK1_PERIOD  = 20; // 50Mhz
parameter real CLK2_PERIOD = 2.5;
parameter real IPLL_PERIOD = 5.008;
parameter real XTAL_PERIOD = 6;

`include "user_tasks.sv"


    reg        test_start;
    integer    test_step;
    wire       clock_mon;
    reg [7:0]  loop;


	`ifdef WFDUMP
	   initial begin
	   	$dumpfile("simx.vcd");
	   	$dumpvars(0, `TB_TOP);
	   	$dumpvars(0, `DUT_TOP.u_wb_host);
	   	$dumpvars(0, `DUT_TOP.u_intercon);
	   	$dumpvars(0, `DUT_TOP.u_pinmux);
	   	$dumpvars(0, `DUT_TOP.u_peri);
	   end
       `endif

	initial begin
        test_start = 0;
		test_fail = 0;
        $value$plusargs("risc_core_id=%d", d_risc_id);

        init();
        test_start = 1;

		#200; // Wait for reset removal
	        repeat (10) @(posedge clock);
		$display("Monitor: Standalone User Risc Boot Test Started");

	    repeat (2) @(posedge clock);
		#1;
        //`SPIM_REG_WRITE(`ADDR_SPACE_WBHOST+`WBHOST_GLBL_CFG,'h1);

        // Disable Multi func
        //`SPIM_REG_WRITE(`ADDR_SPACE_GLBL+`GLBL_CFG_MUTI_FUNC,'h000);

        // Don't Disturb some of critical pads like clock & sspis
        // gpio[41] = clock
        // gpio[42] = clock2
        // gpio[14] = xtal_clk
        // gpio[22] = sspis reset
        // gpio[13] = sspis clk
        // gpio[12] = sspis sdi
        // gpio[11] = sspis sdo
    
        $display("TEST: Enable Pad 0 to 7 sequential in master mode and drive gpio output to 1 ");   
        for(loop = 0; loop < 8; loop = loop+1) begin
             // GPIO-0 as Master Pads with output = 1
             `SPIM_REG_WRITE(`ADDR_SPACE_PADS+`PADS_CFG_CTRL,{1'b1,7'b0,16'hB005,loop[7:0]});
              read_data[31]= 1'b1;
              while(read_data[31] == 1'b1) begin
                 `SPIM_REG_READ(`ADDR_SPACE_PADS+`PADS_CFG_CTRL,read_data);
              end
              // check if the io_out[0] = 1 and oen = 0
              if(io_out[loop] == 1'b1 && io_oeb[loop] == 1'b0) begin
                   $display("STATUS: PASS  Pad-%d control sucessfull",loop[7:0]);
              end else begin
                   $display("STATUS: FAIL  Pad-%d control ",loop);
                   test_fail = 1;
              end
        end
        // check gpio 30 to 40
        $display("TEST: Enable Pad 30 to 39 sequential in master mode and drive gpio output to 1");
        for(loop = 30; loop < 40; loop = loop+1) begin
             // GPIO-0 as Master Pads with output = 1
             `SPIM_REG_WRITE(`ADDR_SPACE_PADS+`PADS_CFG_CTRL,{1'b1,7'b0,16'hB005,loop[7:0]});
              read_data[31]= 1'b1;
              while(read_data[31] == 1'b1) begin
                 `SPIM_REG_READ(`ADDR_SPACE_PADS+`PADS_CFG_CTRL,read_data);
              end
              // check if the io_out[0] = 1 and oen = 0
              if(io_out[loop] == 1'b1 && io_oeb[loop] == 1'b0) begin
                   $display("STATUS: PASS  Pad-%d control sucessfull",loop[7:0]);
              end else begin
                   $display("STATUS: FAIL  Pad-%d control ",loop);
                   test_fail = 1;
              end
        end

        $display("TEST: Set Pad to 8'd44 and see shift data is capture by the pad_ctrl back");
        `SPIM_REG_WRITE(`ADDR_SPACE_PADS+`PADS_CFG_CTRL,{1'b1,7'b0,16'hB005,8'd44});
         read_data[31]= 1'b1;
         while(read_data[31] == 1'b1) begin
            `SPIM_REG_READ(`ADDR_SPACE_PADS+`PADS_CFG_CTRL,read_data);
         end

        `SPIM_REG_CHECK(`ADDR_SPACE_PADS+`PADS_CAPTURE_DATA,{16'h0,16'hB005});



		repeat (100) @(posedge clock);
			// $display("+1000 cycles");

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


//----------------------------------------------------
//  Task
// --------------------------------------------------
task test_err;
begin
     test_fail = 1;
end
endtask



endmodule
`default_nettype wire
