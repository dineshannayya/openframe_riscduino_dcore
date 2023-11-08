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
////    Validate gpio input                                       ////
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
`include "uart_agent.v"

`define TB_HEX "arduino_gpio_input.hex"
`define TB_TOP arduino_gpio_input_tb

`include "bfm_spim.v"
module `TB_TOP;
parameter real CLK1_PERIOD  = 20; // 50Mhz
parameter real CLK2_PERIOD = 2.5;
parameter real IPLL_PERIOD = 5.008;
parameter real XTAL_PERIOD = 6;

`include "user_tasks.sv"

    //----------------------------------
    // Uart Configuration
    // ---------------------------------
    reg [1:0]      uart_data_bit        ;
    reg	           uart_stop_bits       ; // 0: 1 stop bit; 1: 2 stop bit;
    reg	           uart_stick_parity    ; // 1: force even parity
    reg	           uart_parity_en       ; // parity enable
    reg	           uart_even_odd_parity ; // 0: odd parity; 1: even parity
    
    reg [7:0]      uart_data            ;
    reg [15:0]     uart_divisor         ;	// divided by n * 16
    reg [15:0]     uart_timeout         ;// wait time limit
    
    reg [15:0]     uart_rx_nu           ;
    reg [15:0]     uart_tx_nu           ;
    reg [7:0]      uart_write_data [0:39];
    reg 	       uart_fifo_enable     ;	// fifo mode disable
	reg            flag                 ;

	reg [31:0]     check_sum            ;
        
        integer i,j;
/*********************************************************************************
*   Pin-2         0             PD0/WS[0]/MRXD/RXD[0]                       digital_io[24] -
*   Pin-3         1             PD1/WS[0]/MTXD/TXD[0]                       digital_io[25] -
*   Pin-4         2             PD2/WS[0]/RXD[1]/INT0                       digital_io[26] -
*   Pin-5         3             PD3/WS[1]INT1/OC2B(PWM0)                    digital_io[27] -
*   Pin-6         4             PD4/WS[1]TXD[1]                             digital_io[28] -
*   Pin-11        5             PD5/WS[2]/SS[3]/OC0B(PWM1)/T1               digital_io[29] -
*   Pin-12        6             PD6/WS[2]/SS[2]/OC0A(PWM2)/AIN0             digital_io[30]/analog_io[2] -
*   Pin-13        7             PD7/WS[2]/A1N1/IR-TX                        digital_io[31]/analog_io[3] -
*   Pin-14        8             PB0/WS[2]/CLKO/ICP1                         digital_io[8] -
*   Pin-15        9             PB1/WS[3]/SS[1]/OC1A(PWM3)                  digital_io[9] -
*   Pin-16        10            PB2/WS[3]/SS[0]/OC1B(PWM4)                  digital_io[10] -
*   Pin-17        11            PB3/WS[3]/MOSI/OC2A(PWM5)                   digital_io[11] -
*   Pin-18        12            PB4/WS[3]/MISO                              digital_io[12] -
*   Pin-19        13            PB5/SCK                                     digital_io[13] -
*   Pin-23        14            PC0/ADC0                                    digital_io[16]/analog_io[11] -
*   Pin-24        15            PC1/ADC1                                    digital_io[17]/analog_io[12] -
*   Pin-25        16            PC2/usb_dp/ADC2                             digital_io[18]/analog_io[13] -
*   Pin-26        17            PC3/usb_dn/ADC3                             digital_io[19]/analog_io[14] -
*   Pin-27        18            PC4/ADC4/SDA                                digital_io[20]/analog_io[15] -
*   Pin-28        19            PC5/ADC5/SCL                                digital_io[21]/analog_io[16] -
*   Pin-9         20            PB6/WS[1]/XTAL1/TOSC1                       digital_io[14] -
*   Pin-10        21            PB7/WS[1]/XTAL2/TOSC2/IR-RX                 digital_io[15] -
******************************************************************************/
	
   
    reg  [19:0]   arduino_gpio; 
    assign  { io_in[15],
              io_in[14],
              io_in[21],
              io_in[20],
              io_in[19],
              io_in[18],
              io_in[17],
              io_in[16],
              io_in[13],
              io_in[12],
              io_in[11],
              io_in[10],
              io_in[9],
              io_in[8],
              io_in[31],
              io_in[30],
              io_in[29],
              io_in[28],
              io_in[27],
              io_in[26]
              } = arduino_gpio;


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
        arduino_gpio            = 'h0;
        uart_data_bit           = 2'b11;
        uart_stop_bits          = 0; // 0: 1 stop bit; 1: 2 stop bit;
        uart_stick_parity       = 0; // 1: force even parity
        uart_parity_en          = 0; // parity enable
        uart_even_odd_parity    = 1; // 0: odd parity; 1: even parity
	    tb_set_uart_baud(50000000,1152000,uart_divisor);// 50Mhz Ref clock, Baud Rate: 230400
        uart_timeout            = 2000;// wait time limit
        uart_fifo_enable        = 0;	// fifo mode disable

        $value$plusargs("risc_core_id=%d", d_risc_id);

         init();

        $display("Status:  Waiting for RISCV Core Boot ... ");
        wait(`TB_TOP.u_top.u_pinmux.u_glbl_reg.reg_15 == 32'h1); // Wait for RISCV Boot Indication
        $display("Status:  RISCV Core is Booted ");

	    tb_uart.debug_mode = 0; // disable debug display
        tb_uart.uart_init;
        tb_uart.control_setup (uart_data_bit, uart_stop_bits,uart_stop_bits, uart_parity_en, uart_even_odd_parity, uart_stick_parity, uart_timeout, uart_divisor);

        test_fail = 0;
		check_sum = 0;
        fork
        begin
           for(i = 0; i < 20; i = i+1) begin
              arduino_gpio[i] = 1'b1; 
              $display("STATUS: Setting Pin: %d High %h:%b",i,arduino_gpio,io_in);
              // Wait for UART Response from RISCV 
              read_data = 0;
              while(read_data != 32'hA)
              begin
                 tb_uart.read_char(read_data,flag);
		         if(flag == 0)  begin
		            $write ("%c",read_data);
		            check_sum = check_sum+read_data;
		         end
              end
           end
           for(i = 0; i < 20; i = i+1) begin
              arduino_gpio[i] = 1'b0; 
              $display("STATUS: Setting Pin: %d Low %h:%b",i,arduino_gpio,io_in);
              // Wait for UART Response from RISCV 
              flag = 0;
              while(flag == 0)
              begin
                 tb_uart.read_char(read_data,flag);
		         if(flag == 0)  begin
		            $write ("%c",read_data);
		            check_sum = check_sum+read_data;
		         end
              end
           end
           test_fail = 0;
        end
        begin
           repeat (20000000) @(posedge clock);  // wait for Processor Get Ready
           test_fail = 1;
        end
        join_any


        
        tb_uart.report_status(uart_rx_nu, uart_tx_nu);
		$display("Total Rx Char: %d Check Sum : %x ",uart_rx_nu, check_sum);
        if(uart_rx_nu != 600) test_fail = 1;
        if(check_sum != 32'hb784 ) test_fail = 1;

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
// SSFLASH has 1ps/1ps time scale
`include "s25fl256s.sv"
`default_nettype wire