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
////  Gpio Pad Control Register                                   ////
////                                                              ////
////  This file is part of the riscduino cores project            ////
////  https://github.com/dineshannayya/riscduino.git              ////
////                                                              ////
////  Description                                                 ////
////     Manages all the GPIO Pad Control related config          ////
////                                                              ////
////  To Do:                                                      ////
////    nothing                                                   ////
////                                                              ////
////  Author(s):                                                  ////
////      - Dinesh Annayya, dinesha@opencores.org                 ////
////                                                              ////
////  Revision :                                                  ////
////    0.1 - Nov 12 2023, Dinesh A                               ////
////          initial version                                     ////
//////////////////////////////////////////////////////////////////////


module gpio_pads_reg #(   
                        parameter DW = 32,    // DATA WIDTH
                        parameter AW = 4,     // ADDRESS WIDTH
                        parameter BW = 4      // BYTE WIDTH
                    ) (
                       // System Signals
                       // Inputs
		               input logic           mclk                 ,
                       input logic           h_reset_n            ,

		               // Reg Bus Interface Signal
                       input logic           reg_cs               ,
                       input logic           reg_wr               ,
                       input logic [AW-1:0]  reg_addr             ,
                       input logic [DW-1:0]  reg_wdata            ,
                       input logic [BW-1:0]  reg_be               ,

                       // Outputs
                       output logic [DW-1:0] reg_rdata            ,
                       output logic          reg_ack              ,

   // GPIO Pad I/F - Daisy chain Serial I/F
                       output  logic               shift_rstn      ,  // Pad Shift Register Reset
                       output  logic               shift_clock     ,  // Shift clock
                       output  logic               shift_load      ,  // Shift Load
                       output  logic               shift_data_out  ,  // Shift Data Out
                       input   logic               shift_data_in      // Shift Data In





                ); 

//-----------------------------------------------------------------------
// Internal Wire Declarations
//-----------------------------------------------------------------------

logic          sw_rd_en              ;
logic          sw_wr_en              ;
logic [AW-1:0] sw_addr               ; 
logic [DW-1:0] sw_reg_wdata          ;
logic [BW-1:0] sw_be                 ;

logic [DW-1:0] reg_out               ;
logic [DW-1:0] reg_0                 ; 
logic [DW-1:0] reg_1                 ; 

logic               shift_req        ; // Serail Shift Request
logic [7:0]         cfg_pad_no       ; // Serial Shift Pad no, each pas has 16 Shift Reg
logic [15:0]        cfg_shift_data   ; // Serial Shift Register
logic               shift_done       ; // Indicate Shift is completed
logic  [15:0]       capture_data     ; // Serial Shift Capture data



assign       sw_addr       = reg_addr;
assign       sw_be         = reg_be;
assign       sw_rd_en      = reg_cs & !reg_wr;
assign       sw_wr_en      = reg_cs & reg_wr;
assign       sw_reg_wdata  = reg_wdata;

//-----------------------------------------------------------------------
// register read enable and write enable decoding logic
//-----------------------------------------------------------------------
wire   sw_wr_en_0  = sw_wr_en  & (sw_addr == 4'h0);
wire   sw_wr_en_1  = sw_wr_en  & (sw_addr == 4'h1);



always @ (posedge mclk or negedge h_reset_n)
begin : preg_out_Seq
   if (h_reset_n == 1'b0) begin
      reg_rdata  <= 'h0;
      reg_ack    <= 1'b0;
   end else if (reg_cs && !reg_ack) begin
      reg_rdata  <= reg_out[DW-1:0] ;
      reg_ack    <= 1'b1;
   end else begin
      reg_ack    <= 1'b0;
   end
end

//-----------------------------------------------------------------------
//   reg-0
//-----------------------------------------------------------------

assign cfg_pad_no          = reg_0[7:0];
assign cfg_shift_data      = reg_0[23:8];

generic_register #(8,8'h0  ) u_reg0_be0 (
	      .we            ({8{sw_wr_en_0 & 
                             sw_be[0]   }}  ),		 
	      .data_in       (sw_reg_wdata[7:0]    ),
	      .reset_n       (h_reset_n           ),
	      .clk           (mclk              ),
	      
	      //List of Outs
	      .data_out      (reg_0[7:0]        )
          );

generic_register #(8,8'h0  ) u_reg0_be1 (
	      .we            ({8{sw_wr_en_0 & 
                             sw_be[1]   }}  ),		 
	      .data_in       (sw_reg_wdata[15:8]    ),
	      .reset_n       (h_reset_n           ),
	      .clk           (mclk              ),
	      
	      //List of Outs
	      .data_out      (reg_0[15:8]        )
          );

generic_register #(8,8'h0  ) u_reg0_be2 (
	      .we            ({8{sw_wr_en_0 & 
                             sw_be[2]   }}  ),		 
	      .data_in       (sw_reg_wdata[23:16]    ),
	      .reset_n       (h_reset_n           ),
	      .clk           (mclk              ),
	      
	      //List of Outs
	      .data_out      (reg_0[23:16]        )
          );

req_register #(0  ) u_reg0_31 (
	      .cpu_we       ({sw_wr_en_0 & 
                             sw_be[3]   }),		 
	      .cpu_req      (sw_reg_wdata[31] ),
	      .hware_ack    (shift_done       ),
	      .reset_n      (h_reset_n        ),
	      .clk          (mclk             ),
	      
	      //List of Outs
	      .data_out     (shift_req        )
          );




assign reg_0[30:24] = 'h0;
assign reg_0[31] = shift_req;

//-----------------------------------------------------------------------
//   reg-1
//-----------------------------------------------------------------

assign reg_1[15:0] =  capture_data;
assign reg_1[31:16] = 'h0;

//-----------------------------------------------------------------------
// Register Read Path Multiplexer instantiation
//-----------------------------------------------------------------------

always_comb
begin 
  reg_out [31:0] = 32'h0;

  case (sw_addr [3:0])
    4'b0000 : reg_out [31:0] = reg_0  ;     
    4'b0001 : reg_out [31:0] = reg_1  ;    
    default  : reg_out [31:0] = 32'h0;
  endcase
end




gpio_pads_ctrl  u_pads_ctrl
       (

    // Master Port
       .rst_n              (h_reset_n      ),  // Regular Reset signal
       .clk                (mclk           ),  // System clock

       // Register i/F
       .shift_req          (shift_req       ),
       .cfg_pad_no         (cfg_pad_no      ),
       .cfg_shift_data     (cfg_shift_data  ),
       .shift_done         (shift_done      ),
       .capture_data       (capture_data    ),

    // GPIO Pad I/F - Daisy chain Serial I/F
       .shift_rstn         (shift_rstn      ),  // Pad Shift Register Reset
       .shift_clock        (shift_clock     ),  // Shift clock
       .shift_load         (shift_load      ),  // Shift Load
       .shift_data_out     (shift_data_out  ),  // Shift Data Out
       .shift_data_in      (shift_data_in   )   // Shift Data In

    );



endmodule
