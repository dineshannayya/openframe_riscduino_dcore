//////////////////////////////////////////////////////////////////////////////
// SPDX-FileCopyrightText: 2021 , Dinesh Annayya                          
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
// SPDX-FileContributor: Created by Dinesh Annayya <dinesha@opencores.org>
//
//////////////////////////////////////////////////////////////////////
////                                                              ////
////  USB1BD Register                                             ////
////                                                              ////
////                                                              ////
////  Description                                                 ////
////                                                              ////
////  To Do:                                                      ////
////    nothing                                                   ////
////                                                              ////
////  Author(s):                                                  ////
////      - Dinesh Annayya                                        ////
////                                                              ////
////  Revision :                                                  //// 
////    0.1 - 30th Oct 2023, Dinesh A                             ////
////          initial version                                     ////
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

module usb1bd_reg (

             input logic           mclk                   ,
             input logic           reset_n                ,

        // Reg Bus Interface Signal
             input logic           reg_cs                 ,
             input logic           reg_wr                 ,
             input logic [3:0]     reg_addr               ,
             input logic [31:0]    reg_wdata              ,
             input logic [3:0]     reg_be                 ,

            // Outputs
             output logic [31:0]   reg_rdata              ,
             output logic          reg_ack                ,


       // Config Register
             output logic           cfg_usb_enb           ,
             output logic           usb_srst_n            ,
             output logic           cfg_phy_tx_mode       ,
             output  logic [7:0]    cfg_max_hms           ,
	         output  logic          cfg_tx_send_token     , 
             output  logic [1:0]    cfg_tx_token_pid_sel  ,
	         output  logic          cfg_tx_send_data      , 
             output  logic [1:0]    cfg_tx_data_pid_sel   ,


	         input   logic          rx_token_valid        ,
             input   logic          rx_fifo_ddone         ,        
	         input   logic [6:0]    rx_token_fadr         , // Function address from token
	         input   logic [3:0]    rx_ep_sel             , // Endpoint Number Input
	         input   logic          x_busy                , // Indicates USB is busy

	   // Misc
             input  logic          usb_rst                ,
	         input  logic [31:0]   frm_nat                ,
	         input  logic          pid_cs_err             , // pid checksum error
	         input  logic          crc5_err               , // crc5 error
             input  logic          crc16_err              , // Data packet CRC 16 error


         // Uart Tx fifo interface
             output logic          tx_fifo_wr_en          ,
             output logic [7:0]    tx_fifo_data           ,
             input logic [4:0]     tx_fifo_occ            ,
             input logic           tx_fifo_full           ,
             input logic           tx_fifo_empty          ,
             input logic           tx_fifo_oflow          ,

         // Uart Rx fifo interface
             output logic          rx_fifo_rd_en          ,
             input logic [7:0]     rx_fifo_data           ,
             input  logic [4:0]    rx_fifo_occ            ,
             input  logic          rx_fifo_full           ,
             input  logic          rx_fifo_empty          ,
             input  logic          rx_fifo_uflow          ,

             output logic          usb_irq

        );



//-----------------------------------------------------------------------
// Internal Wire Declarations
//-----------------------------------------------------------------------

wire           sw_rd_en;
wire           sw_wr_en;
wire  [3:0]    sw_addr ; // addressing 16 registers
wire  [31:0]   sw_wr_data ; 
wire  [3:0]    sw_wr_be   ;


wire [31:0]    reg_0;  // Software_Reg_0
wire [31:0]    reg_1;  // Software-Reg_1
wire [31:0]    reg_2;  // Software-Reg_2
wire [31:0]    reg_3;  // Software-Reg_3
wire [31:0]    reg_4;  // Software-Reg_4
wire [31:0]    reg_5;  // Software-Reg_5
wire [31:0]    reg_6;  // Software-Reg_6
wire [31:0]    reg_7;  // Software-Reg_7
wire [31:0]    reg_8;  // Software-Reg_8
wire [31:0]    reg_9;  // Software-Reg_9
wire [31:0]    reg_10; // Software-Reg_10
wire [31:0]    reg_11; // Software-Reg_11
wire [31:0]    reg_12; // Software-Reg_12
wire [31:0]    reg_13; // Software-Reg_13
wire [31:0]    reg_14; // Software-Reg_14
wire [31:0]    reg_15; // Software-Reg_15
reg  [31:0]    reg_out;

//-----------------------------------------------------------------------
// Main code starts here
//-----------------------------------------------------------------------

//-----------------------------------------------------------------------
// Internal Logic Starts here
//-----------------------------------------------------------------------
    assign sw_addr       = reg_addr [3:0];
    assign sw_wr_data    = reg_wdata;
    assign sw_rd_en      = reg_cs & !reg_wr;
    assign sw_wr_en      = reg_cs & reg_wr;
    assign sw_wr_be      = reg_be;


//-----------------------------------------------------------------------
// Read path mux
//-----------------------------------------------------------------------

always @ (posedge mclk or negedge reset_n)
begin : preg_out_Seq
   if (reset_n == 1'b0)
   begin
      reg_rdata [31:0]  <= 32'h00;
      reg_ack          <= 1'b0;
   end
   else if (sw_rd_en && !reg_ack) 
   begin
      reg_rdata [31:0]  <= reg_out [31:0];
      reg_ack          <= 1'b1;
   end
   else if (sw_wr_en && !reg_ack) 
      reg_ack          <= 1'b1;
   else
   begin
      reg_ack        <= 1'b0;
   end
end


//-----------------------------------------------------------------------
// register read enable and write enable decoding logic
//-----------------------------------------------------------------------
wire   sw_wr_en_0 = sw_wr_en & (sw_addr == 4'h0);
wire   sw_rd_en_0 = sw_rd_en & (sw_addr == 4'h0);
wire   sw_wr_en_1 = sw_wr_en & (sw_addr == 4'h1);
wire   sw_rd_en_1 = sw_rd_en & (sw_addr == 4'h1);
wire   sw_wr_en_2 = sw_wr_en & (sw_addr == 4'h2);
wire   sw_rd_en_2 = sw_rd_en & (sw_addr == 4'h2);
wire   sw_wr_en_3 = sw_wr_en & (sw_addr == 4'h3);
wire   sw_rd_en_3 = sw_rd_en & (sw_addr == 4'h3);
wire   sw_wr_en_4 = sw_wr_en & (sw_addr == 4'h4);
wire   sw_rd_en_4 = sw_rd_en & (sw_addr == 4'h4);
wire   sw_wr_en_5 = sw_wr_en & (sw_addr == 4'h5);
wire   sw_rd_en_5 = sw_rd_en & (sw_addr == 4'h5);
wire   sw_wr_en_6 = sw_wr_en & (sw_addr == 4'h6);
wire   sw_rd_en_6 = sw_rd_en & (sw_addr == 4'h6);
wire   sw_wr_en_7 = sw_wr_en & (sw_addr == 4'h7);
wire   sw_rd_en_7 = sw_rd_en & (sw_addr == 4'h7);
wire   sw_wr_en_8 = sw_wr_en & (sw_addr == 4'h8);
wire   sw_rd_en_8 = sw_rd_en & (sw_addr == 4'h8);
wire   sw_wr_en_9 = sw_wr_en & (sw_addr == 4'h9);
wire   sw_rd_en_9 = sw_rd_en & (sw_addr == 4'h9);
wire   sw_wr_en_10 = sw_wr_en & (sw_addr == 4'hA);
wire   sw_rd_en_10 = sw_rd_en & (sw_addr == 4'hA);
wire   sw_wr_en_11 = sw_wr_en & (sw_addr == 4'hB);
wire   sw_rd_en_11 = sw_rd_en & (sw_addr == 4'hB);
wire   sw_wr_en_12 = sw_wr_en & (sw_addr == 4'hC);
wire   sw_rd_en_12 = sw_rd_en & (sw_addr == 4'hC);
wire   sw_wr_en_13 = sw_wr_en & (sw_addr == 4'hD);
wire   sw_rd_en_13 = sw_rd_en & (sw_addr == 4'hD);
wire   sw_wr_en_14 = sw_wr_en & (sw_addr == 4'hE);
wire   sw_rd_en_14 = sw_rd_en & (sw_addr == 4'hE);
wire   sw_wr_en_15 = sw_wr_en & (sw_addr == 4'hF);
wire   sw_rd_en_15 = sw_rd_en & (sw_addr == 4'hF);


always @( *)
begin : preg_sel_Com

  reg_out [31:0] = 32'd0;

  case (sw_addr [3:0])
    4'b0000 : reg_out [31:0] = reg_0 [31:0];     
    4'b0001 : reg_out [31:0] = reg_1 [31:0];    
    4'b0010 : reg_out [31:0] = reg_2 [31:0];     
    4'b0011 : reg_out [31:0] = reg_3 [31:0];    
    4'b0100 : reg_out [31:0] = reg_4 [31:0];    
    4'b0101 : reg_out [31:0] = reg_5 [31:0];
    4'b0110 : reg_out [31:0] = reg_6 [31:0];    
    4'b0111 : reg_out [31:0] = reg_7 [31:0];    
    4'b1000 : reg_out [31:0] = reg_8 [31:0];    
    4'b1001 : reg_out [31:0] = 'h0;
    4'b1010 : reg_out [31:0] = 'h0;
    4'b1011 : reg_out [31:0] = 'h0;
    4'b1100 : reg_out [31:0] = 'h0;
    4'b1101 : reg_out [31:0] = 'h0;
    4'b1110 : reg_out [31:0] = 'h0;
    4'b1111 : reg_out [31:0] = 'h0;
  endcase
end



//-----------------------------------------------------------------------
// Individual register assignments
//-----------------------------------------------------------------------
// Logic for Register 0 : 
//-----------------------------------------------------------------------

assign       cfg_usb_enb           = reg_0[0];
assign       usb_srst_n            = !reg_0[1];
assign       cfg_phy_tx_mode       = reg_0[2];

assign       cfg_tx_token_pid_sel  = reg_0[9:8];
assign       cfg_tx_send_token     = reg_0[11];

assign       cfg_tx_data_pid_sel   = reg_0[13:12];
assign       cfg_tx_send_data      = reg_0[15];

assign       cfg_max_hms           = reg_0[23:16]; // priority mode, 0 -> nop, 1 -> Even, 2 -> Odd

gen_32b_reg  #(32'h00000004) u_reg_0	(
	      //List of Inputs
	      .reset_n    (reset_n       ),
	      .clk        (mclk          ),
	      .cs         (sw_wr_en_0    ),
	      .we         (sw_wr_be      ),		 
	      .data_in    (sw_wr_data    ),
	      
	      //List of Outs
	      .data_out   (reg_0         )
         );

//-----------------------------------------------------------------------
// Logic for Register 1 : interrupt status
//-----------------------------------------------------------------------

wire [7:0] hware_intr_req = {rx_fifo_uflow,tx_fifo_oflow,crc16_err,crc5_err,pid_cs_err, rx_fifo_ddone,rx_token_valid,usb_rst};


generic_intr_stat_reg #(.WD(8),
	                .RESET_DEFAULT(0)) u_reg1_be0 (
		 //inputs
		 .clk         (mclk              ),
		 .reset_n     (reset_n         ),
	     .reg_we      ({8{sw_wr_en_1 & reg_ack & sw_wr_be[0]}}),		 
		 .reg_din    (sw_wr_data[7:0] ),
		 .hware_req  (hware_intr_req           ),
		 
		 //outputs
		 .data_out    (reg_1[7:0]       )
	      );



generic_register #(4,4'h0  ) u_reg1_set1 (
	      .we            ({4{token_valid}}       ),
	      .data_in       (rx_ep_sel[3:0]         ),
	      .reset_n       (reset_n                ),
	      .clk           (mclk                   ),
	      
	      //List of Outs
	      .data_out      (reg_1[11:8]            )
          );

generic_register #(7,7'h0  ) u_reg1_set3 (
	      .we            ({7{token_valid}}       ),
	      .data_in       (rx_token_fadr[6:0]     ),
	      .reset_n       (reset_n                ),
	      .clk           (mclk                   ),
	      
	      //List of Outs
	      .data_out      (reg_1[18:12]           )
          );



assign reg_1[19] = x_busy;

//-----------------------------------------------------------------------
// Logic for Register 2 : interrupt mask  
//-----------------------------------------------------------------------

generic_register #(8,8'h0  ) u_reg2_be0 (
           .we            ({8{sw_wr_en_2 & 
                              sw_wr_be[0]   }}  ),		 

	      .data_in       (sw_wr_data[7:0]     ),
	      .reset_n       (reset_n                ),
	      .clk           (mclk                   ),
	      
	      //List of Outs
	      .data_out      (reg_2[7:0]           )
          );


// USB interrupt generation

assign  usb_irq     = |(reg_1[7:0] & reg_2[7:0]); 


//-----------------------------------------------------------------------
// Logic for Register 3 :  
//-----------------------------------------------------------------------
assign   reg_3    = frm_nat;


// reg-4  status
//
assign reg_4      = {8'h0,
                     3'h0,rx_fifo_occ,
                     3'h0,tx_fifo_occ,
                     4'h0,rx_fifo_empty,rx_fifo_full,tx_fifo_empty,tx_fifo_full};

// reg_5 is tx_fifo wr
assign tx_fifo_wr_en  = sw_wr_en_5 & reg_ack & !tx_fifo_full;
assign tx_fifo_data   = sw_wr_data[7:0];

// reg_6 is rx_fifo read
// rx_fifo read data
assign reg_6[7:0] = {rx_fifo_data};
assign  rx_fifo_rd_en = sw_rd_en_6 & reg_ack & !rx_fifo_empty;


endmodule
