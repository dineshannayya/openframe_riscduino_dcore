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
/********************************************************************
  Standalone IR Receiver  validation Test bench           

     Test case:  IR Transmitter io_out[15] is loop back to IO Reciver io_in[12]

     Author(s):                                                  
        - Dinesh Annayya, dinesh.annayya@gmail.com                
     Revision :                                                  
        - 0.1 - 13 Dec 2022, Dinesh A                           
*********************************************************************/

`default_nettype wire

`timescale 1 ns/1 ps

`include "sram_macros/sky130_sram_2kbyte_1rw1r_32x512_8.v"
`include "user_params.svh"

`define TB_TOP user_ir_tx_tb

`include "bfm_spim.v"
module `TB_TOP;
parameter real CLK1_PERIOD  = 25; // 40Mhz
parameter real CLK2_PERIOD = 2.5;
parameter real IPLL_PERIOD = 5.008;
parameter real XTAL_PERIOD = 6;

integer  i;
reg [7:0]  cmd_addr;
reg [7:0]  cmd_data;


`include "user_tasks.sv"



	`ifdef WFDUMP
	   initial begin
	   	$dumpfile("simx.vcd");
	   	$dumpvars(1, `TB_TOP);
	   	$dumpvars(1, `TB_TOP.u_top);
	   	//$dumpvars(0, `TB_TOP.u_top.u_pll);
	   	$dumpvars(0, `TB_TOP.u_top.u_wb_host);
	   	//$dumpvars(0, `TB_TOP.u_top.u_intercon);
	   	//$dumpvars(1, `TB_TOP.u_top.u_intercon);
	   	$dumpvars(0, `TB_TOP.u_top.u_pinmux);
	   	$dumpvars(0, `TB_TOP.u_top.u_peri);
	   end
       `endif

initial
begin

   init();

   #200; // Wait for reset removal
   repeat (10) @(posedge clock);
   $display("Monitor: Standalone User Basic Test Started");
   
   repeat (2) @(posedge clock);

   test_fail=0;

   // Normal tick period: 562.5µs = 562500ns
   //Protocol tick period divided by 10 for simulation speed-up, 10x slow Tick Period = 56250ns
   //Protocol tick period divided by 100 for simulation speed-up, 100x slow Tick Period = 5625ns


  // Configuration of IR receiver
  // Typical Oversampling is 8 time of Tick period = 562500/8 = 70312.5ns

  // Protocol tick period divided by 10 for simulation speed-up
  // with 10x slow speed up = 56250/8= 7031.25ns
  // With 25ns clock period , Tick  = (Clock Period * Divider) / Multiplier  
  //  Tick = 25ns * 0x6DDD / 0x64 = 25ns * 28125 / 100 = 7031.25ns
  
  // Protocol tick period divided by 100 for simulation speed-up
  // with 100x slow speed up = 5625/8= 703.125ns
  // With 25ns clock period , Tick  = (Clock Period * Divider) / Multiplier  
  //  Tick = 25ns * 0x6DDD / 0x3E8 = 25ns * 28125 / 1000 = 703.125ns

  `SPIM_REG_WRITE(`ADDR_SPACE_GLBL+`GLBL_CFG_MUTI_FUNC,'h100);
  `SPIM_REG_WRITE(`ADDR_SPACE_IR+`IR_CFG_MULTIPLIER,32'h000003E8);
  `SPIM_REG_WRITE(`ADDR_SPACE_IR+`IR_CFG_DIVIDER,32'h00006DDD);
  `SPIM_REG_WRITE(`ADDR_SPACE_IR+`IR_CFG_CMD,32'hE4100000); // Enable Both Tx/RX Enable

   // Enable GPIO IR TX at bit [15]
   `SPIM_REG_WRITE(`ADDR_SPACE_GLBL+`GLBL_CFG_MUTI_FUNC,'h2_0000);

   repeat (100) @(posedge clock);
   fork
   begin
       for(i =0; i < 2; i = i+1) begin
          // Setp-1: Check the TX FIFO is not full
          read_data[7:4] = 4'h8;
          while(read_data[7:4] == 'h8) begin
             `SPIM_REG_READ(`ADDR_SPACE_IR+`IR_CFG_CMD,read_data);
          end
          cmd_addr = $random%256;
          cmd_data = $random%256;
          `SPIM_REG_WRITE(`ADDR_SPACE_IR+`IR_CFG_TX_DATA,{16'h0,cmd_addr[7:0],cmd_data[7:0]}); 

          // Setp-2: Check the RX FIFO is not empty
          read_data = 0;
          while(read_data[3:0] == 'h0) begin
             `SPIM_REG_READ(`ADDR_SPACE_IR+`IR_CFG_CMD,read_data);
          end
          `SPIM_REG_READ(`ADDR_SPACE_IR+`IR_CFG_RX_DATA,read_data);
          if(read_data[15:8] != cmd_addr && read_data[7:0] != cmd_data)
          begin
             $display("ERROR : Exp: [%x] -> [%x] Rxd [%x] -> [%x]",cmd_addr,cmd_data,read_data[15:8],read_data[7:0]);
             test_fail = 1;
          end 
       end
   end
   begin
      repeat (1000000) @(posedge clock);
      test_fail = 1;
   end
   join_any
   disable fork; //disable pending fork activity

   repeat (100) @(posedge clock);
   
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

// Look back the IR Tx from Port [15] to PORT[31]
wire   ir_tx     = (io_oeb[31] == 1'b0) ? io_out[31] : 1'b0;;
assign io_in[15] = (io_oeb[15] == 1'b1) ? ir_tx : 1'b0;


endmodule
`default_nettype wire
