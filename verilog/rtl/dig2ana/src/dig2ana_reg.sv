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
////  Digital To Analog Register                                  ////
////                                                              ////
////  This file is part of the riscduino cores project            ////
////  https://github.com/dineshannayya/riscduino.git              ////
////                                                              ////
////  Description                                                 ////
////     Manages all the analog related config                    ////
////                                                              ////
////  To Do:                                                      ////
////    nothing                                                   ////
////                                                              ////
////  Author(s):                                                  ////
////      - Dinesh Annayya, dinesha@opencores.org                 ////
////                                                              ////
////  Revision :                                                  ////
////    0.1 - 29rd Sept 2022, Dinesh A                            ////
////          initial version                                     ////
//////////////////////////////////////////////////////////////////////


module dig2ana_reg #(   
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

                       output logic [7:0]    cfg_dac0_mux_sel     ,
                       output logic [7:0]    cfg_dac1_mux_sel     ,
                       output logic [7:0]    cfg_dac2_mux_sel     ,
                       output logic [7:0]    cfg_dac3_mux_sel     ,
                       output logic [3:0]    cfg_adc_sample_trg   ,     
                       output logic [3:0]    cfg_adc_dac_sel      ,     
                       input  logic [3:0]    adc_result



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
logic [DW-1:0] reg_2                 ; 
logic [DW-1:0] reg_3                 ; 
logic [DW-1:0] reg_4                 ; 

logic [3:0]    cfg_sar_enable        ;
logic [3:0]    sar_sample_pulse      ;
logic [7:0]    sar_dac0_mux_sel      ;
logic [7:0]    sar_dac1_mux_sel      ;
logic [7:0]    sar_dac2_mux_sel      ;
logic [7:0]    sar_dac3_mux_sel      ;
logic [7:0]    sar_adc0_result       ;
logic [7:0]    sar_adc1_result       ;
logic [7:0]    sar_adc2_result       ;
logic [7:0]    sar_adc3_result       ;
logic [3:0]    sar_adc_done          ;
logic [3:0]    cfg_sar_sample_req    ;
logic          cfg_invert_adc_result;
logic          cfg_invert_sample_trg;


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
wire   sw_wr_en_2  = sw_wr_en  & (sw_addr == 4'h2);
wire   sw_wr_en_3  = sw_wr_en  & (sw_addr == 4'h3);
wire   sw_wr_en_4  = sw_wr_en  & (sw_addr == 4'h4);



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

assign cfg_adc_dac_sel[0]        = reg_0[0];
assign cfg_sar_enable[0]         = reg_0[1];
assign cfg_adc_sample_trg[0]     = (cfg_sar_enable[0]) ? sar_sample_pulse[0] ^ cfg_invert_sample_trg :  reg_0[2];
assign cfg_dac0_mux_sel          = (cfg_sar_enable[0]) ? sar_dac0_mux_sel    :  reg_0[15:8];

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

req_register #(0  ) u_reg0_31 (
	      .cpu_we       ({sw_wr_en_0 & 
                             sw_be[3]   }),		 
	      .cpu_req      (sw_reg_wdata[31] ),
	      .hware_ack    (sar_adc_done[0]  ),
	      .reset_n      (h_reset_n        ),
	      .clk          (mclk             ),
	      
	      //List of Outs
	      .data_out     (cfg_sar_sample_req[0] )
          );

assign reg_0[23:16] = sar_adc0_result;
assign reg_0[29:24] = 'h0;
assign reg_0[30]   =  adc_result[0] ^ cfg_invert_adc_result;
assign reg_0[31]   =  cfg_sar_sample_req[0];

//-----------------------------------------------------------------------
//   reg-1
//-----------------------------------------------------------------

assign cfg_adc_dac_sel[1]        = reg_1[0];
assign cfg_sar_enable[1]         = reg_1[1];
assign cfg_adc_sample_trg[1]     = (cfg_sar_enable[1]) ? sar_sample_pulse[1] ^ cfg_invert_sample_trg :  reg_1[2];
assign cfg_dac1_mux_sel          = (cfg_sar_enable[1]) ? sar_dac1_mux_sel    :  reg_1[15:8];

generic_register #(8,8'h0  ) u_reg1_be0 (
	      .we            ({8{sw_wr_en_1 & 
                             sw_be[0]   }}  ),		 
	      .data_in       (sw_reg_wdata[7:0]    ),
	      .reset_n       (h_reset_n           ),
	      .clk           (mclk              ),
	      
	      //List of Outs
	      .data_out      (reg_1[7:0]        )
          );

generic_register #(8,8'h0  ) u_reg1_be1 (
	      .we            ({8{sw_wr_en_1 & 
                             sw_be[1]   }}  ),		 
	      .data_in       (sw_reg_wdata[15:8]),
	      .reset_n       (h_reset_n         ),
	      .clk           (mclk              ),
	      
	      //List of Outs
	      .data_out      (reg_1[15:8]        )
          );

req_register #(0  ) u_reg1_31 (
	      .cpu_we       ({sw_wr_en_1 & 
                             sw_be[3]   }),		 
	      .cpu_req      (sw_reg_wdata[31] ),
	      .hware_ack    (sar_adc_done[1]  ),
	      .reset_n      (h_reset_n        ),
	      .clk          (mclk             ),
	      
	      //List of Outs
	      .data_out     (cfg_sar_sample_req[1] )
          );

assign reg_1[23:16] = sar_adc1_result;
assign reg_1[29:24] = 'h0;
assign reg_1[30]   =  adc_result[1] ^ cfg_invert_adc_result;
assign reg_1[31]   =  cfg_sar_sample_req[1];

//-----------------------------------------------------------------------
//   reg-2
//-----------------------------------------------------------------

assign cfg_adc_dac_sel[2]        = reg_2[0];
assign cfg_sar_enable[2]         = reg_2[1];
assign cfg_adc_sample_trg[2]     = (cfg_sar_enable[2]) ? sar_sample_pulse[2] ^ cfg_invert_sample_trg :  reg_2[2];
assign cfg_dac2_mux_sel          = (cfg_sar_enable[2]) ? sar_dac2_mux_sel    :  reg_2[15:8];

generic_register #(8,8'h0  ) u_reg2_be0 (
	      .we            ({8{sw_wr_en_2 & 
                             sw_be[0]   }}  ),		 
	      .data_in       (sw_reg_wdata[7:0]    ),
	      .reset_n       (h_reset_n           ),
	      .clk           (mclk              ),
	      
	      //List of Outs
	      .data_out      (reg_2[7:0]        )
          );

generic_register #(8,8'h0  ) u_reg2_be1 (
	      .we            ({8{sw_wr_en_2 & 
                             sw_be[1]   }}  ),		 
	      .data_in       (sw_reg_wdata[15:8]),
	      .reset_n       (h_reset_n         ),
	      .clk           (mclk              ),
	      
	      //List of Outs
	      .data_out      (reg_2[15:8]        )
          );

req_register #(0  ) u_reg2_31 (
	      .cpu_we       ({sw_wr_en_2 & 
                             sw_be[3]   }),		 
	      .cpu_req      (sw_reg_wdata[31] ),
	      .hware_ack    (sar_adc_done[2]  ),
	      .reset_n      (h_reset_n        ),
	      .clk          (mclk             ),
	      
	      //List of Outs
	      .data_out     (cfg_sar_sample_req[2] )
          );
assign reg_2[23:16] = sar_adc2_result;
assign reg_2[29:24] = 'h0;
assign reg_2[30]   =  adc_result[2] ^ cfg_invert_adc_result;
assign reg_2[31]   =  cfg_sar_sample_req[2];

//-----------------------------------------------------------------------
//   reg-3
//-----------------------------------------------------------------
assign cfg_adc_dac_sel[3]        = reg_3[0];
assign cfg_sar_enable[3]         = reg_3[1];
assign cfg_adc_sample_trg[3]     = (cfg_sar_enable[3]) ? sar_sample_pulse[3] ^ cfg_invert_sample_trg :  reg_3[3];
assign cfg_dac3_mux_sel          = (cfg_sar_enable[3]) ? sar_dac3_mux_sel    :  reg_3[15:8];

generic_register #(8,8'h0  ) u_reg3_be0 (
	      .we            ({8{sw_wr_en_3 & 
                             sw_be[0]   }}  ),		 
	      .data_in       (sw_reg_wdata[7:0] ),
	      .reset_n       (h_reset_n         ),
	      .clk           (mclk              ),
	      
	      //List of Outs
	      .data_out      (reg_3[7:0]        )
          );
generic_register #(8,8'h0  ) u_reg3_be1 (
	      .we            ({8{sw_wr_en_3 & 
                             sw_be[1]   }}  ),		 
	      .data_in       (sw_reg_wdata[15:8]),
	      .reset_n       (h_reset_n         ),
	      .clk           (mclk              ),
	      
	      //List of Outs
	      .data_out      (reg_3[15:8]        )
          );

req_register #(0  ) u_reg3_31 (
	      .cpu_we       ({sw_wr_en_3 & 
                             sw_be[3]   }),		 
	      .cpu_req      (sw_reg_wdata[31] ),
	      .hware_ack    (sar_adc_done[3]  ),
	      .reset_n      (h_reset_n        ),
	      .clk          (mclk             ),
	      
	      //List of Outs
	      .data_out     (cfg_sar_sample_req[3] )
          );

assign reg_3[23:16] = sar_adc3_result;
assign reg_3[29:24] = 'h0;
assign reg_3[30]   =  adc_result[3] ^ cfg_invert_adc_result;
assign reg_3[31]   =  cfg_sar_sample_req[3];


//-----------------------------------------------------------------------
//   reg-4
//-----------------------------------------------------------------
wire [3:0] cfg_sh_timer          =  reg_4[3:0];
wire [3:0] cfg_dac_timer         =  reg_4[7:4];
wire [3:0] cfg_adc_comp_timer    =  reg_4[11:8];
assign     cfg_invert_adc_result =  reg_4[12];
assign     cfg_invert_sample_trg =  reg_4[13];



gen_32b_reg  #(32'h0) u_reg_4	(
	      //List of Inputs
	      .reset_n    (h_reset_n     ),
	      .clk        (mclk          ),
	      .cs         (sw_wr_en_4    ),
	      .we         (sw_be         ),		 
	      .data_in    (sw_reg_wdata  ),
	      
	      //List of Outs
	      .data_out   (reg_4         )
	      );


//-----------------------------------------------------------------------
// Register Read Path Multiplexer instantiation
//-----------------------------------------------------------------------

always_comb
begin 
  reg_out [31:0] = 32'h0;

  case (sw_addr [3:0])
    4'b0000 : reg_out [31:0] = reg_0  ;     
    4'b0001 : reg_out [31:0] = reg_1  ;    
    4'b0010 : reg_out [31:0] = reg_2  ;     
    4'b0011 : reg_out [31:0] = reg_3  ;    
    default  : reg_out [31:0] = 32'h0;
  endcase
end


// SAR for ADC/DAC-0
sar_logic u_sar_0 (
                       // System Signals
                       // Inputs
		        .mclk                 (mclk                  ),
                .h_reset_n            (h_reset_n             ),

                       // Towards Reg I/F
               .cfg_sar_enable       (cfg_sar_enable[0]      ),  // SAR Logic enable
               .cfg_sar_sample_req   (cfg_sar_sample_req[0]  ),  // ADC Sample Request
               .cfg_sh_timer         (cfg_sh_timer           ),  // Sample Hold Timer
               .cfg_dac_timer        (cfg_dac_timer          ),  // DAC Timer
               .cfg_adc_comp_timer   (cfg_adc_comp_timer     ),  // ADC Comparator Timer

               .sar_adc_done         (sar_adc_done[0]        ),  
               .sar_adc_result       (sar_adc0_result        ),

               // Towards ADC/DAC 
               .dac_mux_sel          (sar_dac0_mux_sel       ),  // DAC Value
               .adc_sample_pulse     (sar_sample_pulse[0]    ),  // Sample Input   
               .adc_cmp_result       (adc_result[0] ^ cfg_invert_adc_result          )   // ADC comparator output
                );

// SAR for ADC/DAC-1
sar_logic u_sar_1 (
                       // System Signals
                       // Inputs
		        .mclk                 (mclk                  ),
                .h_reset_n            (h_reset_n             ),

                       // Towards Reg I/F
               .cfg_sar_enable       (cfg_sar_enable[1]      ),  // SAR Logic enable
               .cfg_sar_sample_req   (cfg_sar_sample_req[1]  ),  // ADC Sample Request
               .cfg_sh_timer         (cfg_sh_timer           ),  // Sample Hold Timer
               .cfg_dac_timer        (cfg_dac_timer          ),  // DAC Timer
               .cfg_adc_comp_timer   (cfg_adc_comp_timer     ),  // ADC Comparator Timer

               .sar_adc_done         (sar_adc_done[1]        ),  
               .sar_adc_result       (sar_adc1_result        ),

               // Towards ADC/DAC 
               .dac_mux_sel          (sar_dac1_mux_sel       ),  // DAC Value
               .adc_sample_pulse     (sar_sample_pulse[1]    ),  // Sample Input   
               .adc_cmp_result       (adc_result[1] ^ cfg_invert_adc_result          )   // ADC comparator output
                );

// SAR for ADC/DAC-2
sar_logic u_sar_2 (
                       // System Signals
                       // Inputs
		        .mclk                 (mclk                  ),
                .h_reset_n            (h_reset_n             ),

                       // Towards Reg I/F
               .cfg_sar_enable       (cfg_sar_enable[2]      ),  // SAR Logic enable
               .cfg_sar_sample_req   (cfg_sar_sample_req[2]  ),  // ADC Sample Request
               .cfg_sh_timer         (cfg_sh_timer           ),  // Sample Hold Timer
               .cfg_dac_timer        (cfg_dac_timer          ),  // DAC Timer
               .cfg_adc_comp_timer   (cfg_adc_comp_timer     ),  // ADC Comparator Timer

               .sar_adc_done         (sar_adc_done[2]        ),  
               .sar_adc_result       (sar_adc2_result        ),

               // Towards ADC/DAC 
               .dac_mux_sel          (sar_dac2_mux_sel       ),  // DAC Value
               .adc_sample_pulse     (sar_sample_pulse[2]    ),  // Sample Input   
               .adc_cmp_result       (adc_result[2] ^ cfg_invert_adc_result          )   // ADC comparator output
                );

// SAR for ADC/DAC-3
sar_logic u_sar_3 (
                       // System Signals
                       // Inputs
		        .mclk                 (mclk                  ),
                .h_reset_n            (h_reset_n             ),

                       // Towards Reg I/F
               .cfg_sar_enable       (cfg_sar_enable[3]      ),  // SAR Logic enable
               .cfg_sar_sample_req   (cfg_sar_sample_req[3]  ),  // ADC Sample Request
               .cfg_sh_timer         (cfg_sh_timer           ),  // Sample Hold Timer
               .cfg_dac_timer        (cfg_dac_timer          ),  // DAC Timer
               .cfg_adc_comp_timer   (cfg_adc_comp_timer     ),  // ADC Comparator Timer

               .sar_adc_done         (sar_adc_done[3]        ),  
               .sar_adc_result       (sar_adc3_result        ),

               // Towards ADC/DAC 
               .dac_mux_sel          (sar_dac3_mux_sel       ),  // DAC Value
               .adc_sample_pulse     (sar_sample_pulse[3]    ),  // Sample Input   
               .adc_cmp_result       (adc_result[3] ^ cfg_invert_adc_result          )   // ADC comparator output
                );

endmodule
