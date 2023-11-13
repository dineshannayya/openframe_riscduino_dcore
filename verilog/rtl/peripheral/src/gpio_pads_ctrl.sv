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
//////////////////////////////////////////////////////////////////////
////                                                              ////
////  gpio_pad_ctrl                                               ////
////     Control logic to shift 16 bit config to specific         ////
////     pad shift register chains.                               ////
////     Note: Each pads has 16 bit configuration register        ////
////                                                              ////
////                                                              ////
////                                                              ////
////  To Do:                                                      ////
////    nothing                                                   ////
////                                                              ////
////  Author(s):                                                  ////
////      - Dinesh Annayya, dinesh.annayya@gmail.com              ////
////                                                              ////
////  Revision :                                                  ////
////    0.0 - Nov 12, 2023, Dinesh A                              ////
////          Initial integration                                 ////
////                                                              ////
//////////////////////////////////////////////////////////////////////

module gpio_pads_ctrl
       (

    // Master Port
       input   logic               rst_n           ,  // Regular Reset signal
       input   logic               clk             ,  // System clock

       input   logic               shift_req       ,
       input   logic [7:0]         cfg_pad_no      ,
       input   logic [15:0]        cfg_shift_data  ,
       output  logic               shift_done      ,
       output  logic  [15:0]       capture_data    ,

    // GPIO Pad I/F - Daisy chain Serial I/F
       output  logic               shift_rstn      ,  // Pad Shift Register Reset
       output  logic               shift_clock     ,  // Shift clock
       output  logic               shift_load      ,  // Shift Load
       output  logic               shift_data_out  ,  // Shift Data Out
       input   logic               shift_data_in      // Shift Data In

    );


    parameter IDLE               = 4'b0000;
    parameter SHIFT_RST_EXIT     = 4'b0001;
    parameter SHIFT_DATA         = 4'b0010;
    parameter SHIFT_DATA_WAIT    = 4'b0011;
    parameter SHIFT_CLOCK_ENTRY  = 4'b0100;
    parameter SHIFT_CLOCK_EXIT   = 4'b0101;
    parameter SHIFT_LOAD_ENTRY   = 4'b0110;
    parameter DUMMY_WAIT         = 4'b0111;

    logic [3:0]  state;
    logic [3:0]  bit_cnt;
    logic [1:0]  wait_cnt;
    logic [15:0] shift_reg;
    logic [7:0]  cur_pad_no;
    logic        drive_zero;


always@(negedge rst_n or posedge clk)
begin
   if(rst_n == 0) begin
      shift_rstn            <= 1'b0;
      shift_data_out        <= 1'b0;
      shift_load            <= 1'b0;
      shift_clock           <= 1'b0;
      shift_reg             <= 16'h0;
      bit_cnt               <= 4'h0;
      cur_pad_no            <= 8'h0;
      wait_cnt              <= 2'h0;
      drive_zero            <= 1'b0;
      capture_data          <= 16'b0;
      cur_pad_no            <= 8'h0;
      state                 <= IDLE;
   end else begin
       case(state)

       // Wait for Shift Request
       IDLE: begin
                shift_done    <= 1'b0;
		        if(shift_req) begin
                   shift_reg   <= cfg_shift_data;
                   shift_rstn  <= 1'b0;
                   cur_pad_no  <= 8'h0;
                   drive_zero  <= 1'b0;
                   bit_cnt     <= 4'h0;
                   wait_cnt    <= 2'h0;
	               state       <= SHIFT_RST_EXIT;
                end
	     end
         // Remove the Shift Rst
         SHIFT_RST_EXIT: begin
             if(wait_cnt == 2'h3) begin
                 shift_rstn  <= 1'b1;
                 wait_cnt    <= 2'h0;
                 state       <= SHIFT_DATA;
             end else begin
                 wait_cnt    <= wait_cnt+1;
             end
         end
            
        // Drive Data     
        SHIFT_DATA: begin
            if(drive_zero) begin
                shift_data_out <= 1'b0;
            end else begin
                shift_data_out <= shift_reg[15];
		        shift_reg      <= {shift_reg[14:0],1'b0};
            end
            capture_data   <= {capture_data[14:0],shift_data_in};
            state          <= SHIFT_DATA_WAIT;
	     end
         // Wait for Data To be Stable at Pad
         SHIFT_DATA_WAIT: begin
             if(wait_cnt == 2'h3) begin
                 wait_cnt    <= 2'h0;
                 shift_clock <= 1'b1;
                 state       <= SHIFT_CLOCK_ENTRY;
             end else begin
                 wait_cnt    <= wait_cnt+1;
             end
         end

         // Drive Serial clock =1
         SHIFT_CLOCK_ENTRY: begin
             if(wait_cnt == 2'h3) begin
                 shift_clock <= 1'b0;
                 wait_cnt    <= 2'h0;
                 state       <= SHIFT_CLOCK_EXIT;
             end else begin
                 wait_cnt    <= wait_cnt+1;
             end
         end
         // Wait for 4 cycle and Drive Serial clock =0
         // Check if 16 bit shift completed and cfg_pad_no matches with cur pad no
         SHIFT_CLOCK_EXIT: begin
             if(wait_cnt == 2'h3) begin
                 wait_cnt    <= 2'h0;
                 bit_cnt     <= bit_cnt+1;
                 if(bit_cnt != 15) begin 
                     wait_cnt       <= 2'h0;
                     state          <= SHIFT_DATA;
                 end else begin
                     if(cur_pad_no == cfg_pad_no) begin
                        shift_load    <= 1'b1;
                        drive_zero    <= 1'b0;
                        state         <= SHIFT_LOAD_ENTRY;
                     end else begin
                        bit_cnt       <= 0;
                        drive_zero    <= 1'b1;
                        cur_pad_no    <= cur_pad_no+1;
                        state         <= SHIFT_DATA;
                     end
                 end
             end else begin
                 wait_cnt    <= wait_cnt+1;
             end
         end
         SHIFT_LOAD_ENTRY: begin
             if(wait_cnt == 2'h3) begin
                 shift_load  <= 1'b0;
                 wait_cnt    <= 0;
                 shift_done  <= 1'b1;
                 state       <= DUMMY_WAIT;
             end else begin
                 wait_cnt    <= wait_cnt+1;
             end
         end
         // Wait for Shift_done Propgation
         DUMMY_WAIT: begin
             shift_done  <= 1'b0;
             if(wait_cnt == 2'h3) begin
                 state       <= IDLE;
             end else begin
                 wait_cnt    <= wait_cnt+1;
             end
         end
       endcase
   end
end




endmodule
