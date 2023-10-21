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
////  This file is part of the YIFive cores project               ////
////  https://github.com/dineshannayya/yifive_r0.git              ////
////  http://www.opencores.org/cores/yifive/                      ////
////                                                              ////
////  Description                                                 ////
////   This is a standalone test bench to validate the            ////
////   gpio interfaface through External WB i/F.                  ////
////      1.gpio posedge & negedge interrupt generation           ////
////      2.gpio as input and output                              ////
////                                                              ////
////  To Do:                                                      ////
////    nothing                                                   ////
////                                                              ////
////  Author(s):                                                  ////
////      - Dinesh Annayya, dinesha@opencores.org                 ////
////                                                              ////
////  Revision :                                                  ////
////    0.1 - 01 Oct 2021, Dinesh A                               ////
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

`define TB_GLBL user_gpio_tb
`define TB_TOP  user_gpio_tb
`include "bfm_spim.v"

module user_gpio_tb;
parameter real CLK1_PERIOD  = 20; // 50Mhz
parameter real CLK2_PERIOD = 2.5;
parameter real IPLL_PERIOD = 5.008;
parameter real XTAL_PERIOD = 6;

`include "user_tasks.sv"


    reg        test_start;
    integer    test_step;
    wire       clock_mon;




     /************* Port-A Mapping **********************************
     *                PA0        digital_io[0]
     *                PA1        digital_io[1]
     *                PA2        digital_io[2]
     *                PA3        digital_io[3]
     *                PA4        digital_io[4]
     *                PA5        digital_io[5]
     *                PA6        digital_io[6]
     *                PA7        digital_io[5]
     *   ********************************************************/

     reg  [7:0]  port_a_out;
     wire [7:0]  port_a_in = {   
		                         (io_oeb[7] == 1'b0) ? io_out[7]: 1'b0,
		                         (io_oeb[6] == 1'b0) ? io_out[6]: 1'b0,
		                         (io_oeb[5] == 1'b0) ? io_out[5]: 1'b0,
		                         (io_oeb[4] == 1'b0) ? io_out[4]: 1'b0,
			                     (io_oeb[3] == 1'b0) ? io_out[3]: 1'b0,
			                     (io_oeb[2] == 1'b0) ? io_out[2]: 1'b0,
		                         (io_oeb[1] == 1'b0) ? io_out[1]: 1'b0,
		                         (io_oeb[0] == 1'b0) ? io_out[0]: 1'b0
			                 };


   assign io_in[7:0]   = (test_start) ? port_a_out[7:0] :  8'hZ;


     /************* Port-B Mapping **********************************
       *   Pin-14        8             PB0/WS[2]/CLKO/ICP1             strap[3]    digital_io[8]
       *   Pin-15        9             PB1/WS[3]/SS[1]OC1A(PWM3)       strap[4]    digital_io[9]      
       *   Pin-16        10            PB2/WS[3]/SS[0]/OC1B(PWM4)      strap[5]    digital_io[10]      - Reserved for SSPIS
       *   Pin-17        11            PB3/WS[3]/MOSI/OC2A(PWM5)       strap[6]    digital_io[11]      - Reserved for SSPIS
       *   Pin-18        12            PB4/WS[3]/MISO                  strap[7]    digital_io[12]      - Reserved for SSPIS
       *   Pin-19        13            PB5/SCK                                     digital_io[13]      - Reserved for SSPIS
       *   Pin-9         20            PB6/WS[1]/XTAL1/TOSC1                       digital_io[14]
       *   Pin-10        21            PB7/WS[1]/XTAL2/TOSC2                       digital_io[15]
     *   ********************************************************/

     reg  [7:0]  port_b_out;
     wire [7:0]  port_b_in = {  (io_oeb[15]== 1'b0)? io_out[15] : 1'b0,
		                        (io_oeb[14]== 1'b0)? io_out[14] : 1'b0,
		                        1'b0,
			                    1'b0,
			                    1'b0,
		                        (io_oeb[10]== 1'b0)? io_out[10] : 1'b0,
		                        (io_oeb[9]== 1'b0)? io_out[9] : 1'b0,
		                        (io_oeb[8]== 1'b0)? io_out[8] : 1'b0
			                 };
     
     assign    io_in[15:14] = (test_start) ? port_b_out[7:6]: 2'hZ;
     assign    io_in[10:8]  = (test_start) ? port_b_out[2:0]: 3'hZ;

     /************* Port-C Mapping **********************************
     *   Pin-23        14            PC0/uartm_rxd/ADC0                          digital_io[16]/analog_io[11]
     *   Pin-24        15            PC1/uartm_txd/ADC1                          digital_io[17]/analog_io[12]
     *   Pin-25        16            PC2/usb_dp/ADC2                             digital_io[18]/analog_io[13]
     *   Pin-26        17            PC3/usb_dn/ADC3                             digital_io[19]/analog_io[14]
     *   Pin-27        18            PC4/ADC4/SDA                                digital_io[20]/analog_io[15]
     *   Pin-28        19            PC5/ADC5/SCL                                digital_io[21]/analog_io[16]
     *   Pin-1         22            PC6/WS[0]/RESET*                            digital_io[22] - Reserved for SSPIS
     *                               PC7                                         digital_io[23]
     *   ********************************************************/

     reg  [7:0]  port_c_out;
     wire [7:0]  port_c_in = {   
		             (io_oeb[23]  == 1'b0) ? io_out[23]  : 1'b0,
		             1'b0,
		             (io_oeb[21] == 1'b0)  ? io_out[21] : 1'b0,
		             (io_oeb[20] == 1'b0)  ? io_out[20] : 1'b0,
			         (io_oeb[19] == 1'b0)  ? io_out[19] : 1'b0,
			         (io_oeb[18] == 1'b0)  ? io_out[18] : 1'b0,
		             (io_oeb[17] == 1'b0)  ? io_out[17] : 1'b0,
		             (io_oeb[16] == 1'b0)  ? io_out[16] : 1'b0
			     };
      assign    io_in[23]   = (test_start) ? port_c_out[7] : 1'hZ;
      assign    io_in[21:16]= (test_start) ? port_c_out[5:0] : 6'hZ;


     /************* Port-D Mapping **********************************
      *   Pin-2         0             PD0/WS[0]/RXD[0]                            digital_io[24]
      *   Pin-3         1             PD1/WS[0]/TXD[0]                            digital_io[25]
      *   Pin-4         2             PD2/WS[0]/RXD[1]/INT0                       digital_io[26]
      *   Pin-5         3             PD3/WS[1]INT1/OC2B(PWM0)                    digital_io[27]
      *   Pin-6         4             PD4/WS[1]TXD[1]                             digital_io[28]
      *   Pin-11        5             PD5/WS[2]/SS[3]/OC0B(PWM1)/T1   strap[0]    digital_io[29]
      *   Pin-12        6             PD6/WS[2]/SS[2]/OC0A(PWM2)/AIN0 strap[1]    digital_io[30]/analog_io[2]
      *   Pin-13        7             PD7/WS[2]/A1N1                  strap[2]    digital_io[31]/analog_io[3]
      *   ********************************************************/

     reg  [7:0]  port_d_out;
     wire [7:0]  port_d_in = { (io_oeb[31]== 1'b0)  ? io_out[31]  : 1'b0,
		                       (io_oeb[30]== 1'b0)  ? io_out[30]  : 1'b0,
		                       (io_oeb[29]== 1'b0)  ? io_out[29]  : 1'b0,
		                       (io_oeb[28]== 1'b0)  ? io_out[28]  : 1'b0,
			                   (io_oeb[27] == 1'b0) ? io_out[27]  : 1'b0,
			                   (io_oeb[26] == 1'b0) ? io_out[26]  : 1'b0,
		                       (io_oeb[25] == 1'b0) ? io_out[25]  : 1'b0,
		                       (io_oeb[24] == 1'b0) ? io_out[24]  : 1'b0
			        };

	assign   io_in[31:24]=  (test_start) ? port_d_out : 8'hz;


	/*****************************/

	wire [31:0] irq_lines = u_top.u_pinmux.u_glbl_reg.irq_lines;


	`ifdef WFDUMP
	   initial begin
	   	$dumpfile("simx.vcd");
	   	$dumpvars(1, `TB_GLBL);
	   	$dumpvars(0, `TB_GLBL.u_top.u_wb_host);
	   	$dumpvars(0, `TB_GLBL.u_top.u_intercon);
	   	$dumpvars(0, `TB_GLBL.u_top.u_pinmux);
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
        port_a_out = 'h0;
        port_b_out = 'h0;
        port_c_out = 'h0;
        port_d_out = 'h0;


	    repeat (2) @(posedge clock);
		#1;
        //`SPIM_REG_WRITE(`ADDR_SPACE_WBHOST+`WBHOST_GLBL_CFG,'h1);

        // Disable Multi func
        `SPIM_REG_WRITE(`ADDR_SPACE_GLBL+`GLBL_CFG_MUTI_FUNC,'h000);

		// config 1us based on system clock - 1000/25ns = 40 
        `SPIM_REG_WRITE(`ADDR_SPACE_TIMER+`TIMER_CFG_GLBL,39);

		/************* GPIO As Output ******************/
		$display("#####################################");
		$display("Step-1: Testing GPIO As Output ");
		// Set the Direction as Output
        `SPIM_REG_WRITE(`ADDR_SPACE_GPIO+`GPIO_CFG_DSEL,'hFFFFFFFF);
		// Set the GPIO Output data: 0x55555555
        `SPIM_REG_WRITE(`ADDR_SPACE_GPIO+`GPIO_CFG_ODATA,'h55555555);
		cmp_gpio_output(8'h55,8'h55,8'h55,8'h55);

		// Set the GPIO Output data: 0xAAAAAAAA
        `SPIM_REG_WRITE(`ADDR_SPACE_GPIO+`GPIO_CFG_ODATA,'hAAAAAAAA);
		cmp_gpio_output(8'hAA,8'hAA,8'hAA,8'hAA);

		// Set the GPIO Output data: 0x5A5A5A5A5A5A
        `SPIM_REG_WRITE(`ADDR_SPACE_GPIO+`GPIO_CFG_ODATA,'h5A5A5A5A);
		cmp_gpio_output(8'h5A,8'h5A,8'h5A,8'h5A);
		
		// Set the GPIO Output data: 0xA5A5A5A5A5A5
        `SPIM_REG_WRITE(`ADDR_SPACE_GPIO+`GPIO_CFG_ODATA,'hA5A5A5A5);
		cmp_gpio_output(8'hA5,8'hA5,8'hA5,8'hA5);

		/************* GPIO As Input ******************/
		$display("#####################################");
		$display("Step-2: Testing GPIO As Input ");
		// Set the Direction as Input
        `SPIM_REG_WRITE(`ADDR_SPACE_GPIO+`GPIO_CFG_DSEL,'h00000000);

		cmp_gpio_input(8'h55,8'h55,8'h55,8'h55);
		cmp_gpio_input(8'hAA,8'hAA,8'hAA,8'hAA);
		cmp_gpio_input(8'h5A,8'h5A,8'h5A,8'h5A);
		cmp_gpio_input(8'hA5,8'hA5,8'hA5,8'hA5);

		/************* GPIO As Input & GPIO Pos edge Interrupt ******************/
		$display("#####################################");
		$display("Step-3: Testing GPIO As Posedge Interrupt ");
		// Set the Direction as Input
        `SPIM_REG_WRITE(`ADDR_SPACE_GPIO+`GPIO_CFG_DSEL,'h00000000);
		// Set GPIO for posedge Interrupt
        `SPIM_REG_WRITE(`ADDR_SPACE_GPIO+`GPIO_CFG_INTR_MASK,'hFFFFFFFF);
        `SPIM_REG_WRITE(`ADDR_SPACE_GPIO+`GPIO_CFG_POS_INTR_SEL,'hFFFFFFFF);
        `SPIM_REG_WRITE(`ADDR_SPACE_GPIO+`GPIO_CFG_NEG_INTR_SEL,'h00000000);
        `SPIM_REG_WRITE(`ADDR_SPACE_GLBL+`GLBL_CFG_INTR_MSK,'hFFFFFF00);
		
		// Drive GPIO with 0x55
		cmp_gpio_pos_intr(8'h55,8'h55,8'h55,8'h55);
		
		// Drive GPIO with 0xAA
		cmp_gpio_pos_intr(8'hAA,8'hAA,8'hAA,8'hAA);
		
		// Drive GPIO with 0x5A
		cmp_gpio_pos_intr(8'h5A,8'h5A,8'h5A,8'h5A);
		
		// Drive GPIO with 0xA5
		cmp_gpio_pos_intr(8'hA5,8'hA5,8'hA5,8'hA5);

	        repeat (200) @(posedge clock);
		/************* GPIO As Input & GPIO NEG edge Interrupt ******************/
		$display("#####################################");
		$display("Step-3: Testing GPIO As Negedge Interrupt ");
		// Set the Direction as Input
         `SPIM_REG_WRITE(`ADDR_SPACE_GPIO+`GPIO_CFG_DSEL,'h00000000);
		// Set GPIO for negedge Interrupt
         `SPIM_REG_WRITE(`ADDR_SPACE_GPIO+`GPIO_CFG_INTR_MASK,'hFFFFFFFF);
         `SPIM_REG_WRITE(`ADDR_SPACE_GPIO+`GPIO_CFG_POS_INTR_SEL,'h00000000);
         `SPIM_REG_WRITE(`ADDR_SPACE_GPIO+`GPIO_CFG_NEG_INTR_SEL,'hFFFFFFFF);
         `SPIM_REG_WRITE(`ADDR_SPACE_GLBL+`GLBL_CFG_INTR_MSK,'hFFFF);
		
		// Drive GPIO with 0x55
		cmp_gpio_neg_intr(8'h55,8'h55,8'h55,8'h55);
		
		// Drive GPIO with 0xAA
		cmp_gpio_neg_intr(8'hAA,8'hAA,8'hAA,8'hAA);
		
		// Drive GPIO with 0x5A
		cmp_gpio_neg_intr(8'h5A,8'h5A,8'h5A,8'h5A);
		
		// Drive GPIO with 0xA5
		cmp_gpio_neg_intr(8'hA5,8'hA5,8'hA5,8'hA5);

	     repeat (200) @(posedge clock);
        check_fast_dglitch();

        check_slow_dglitch();
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


/***************************
* Check the GPIO Output
* **************************/

task cmp_gpio_output;
input [7:0] exp_port_a;
input [7:0] exp_port_b;
input [7:0] exp_port_c;
input [7:0] exp_port_d;
begin
    // Wait for some cycle to reg to be written through wbbone host
    repeat (20) @(posedge clock); 

    if((exp_port_a & 8'hFF) != (port_a_in & 8'hFF))
    begin
       $display("ERROR-1: PORT A Exp: %x  Rxd: %x",exp_port_a & 8'hFF,port_a_in & 8'hFF);
       `TB_GLBL.test_fail = 1;
    end else begin
       $display("STATUS: PORT A Data: %x Matched  ",port_a_in & 8'hFF);
    end
    
    if((exp_port_b & 8'hC7) != (port_b_in & 8'hC7))
    begin
       $display("ERROR-2: PORT B Exp: %x  Rxd: %x",exp_port_b & 8'hC7,port_b_in & 8'hC7);
       `TB_GLBL.test_fail = 1;
    end else begin
       $display("STATUS: PORT B Data: %x Matched  ",port_b_in & 8'hC7);
    end
    
    if((exp_port_c & 8'hBF) != (port_c_in & 8'hBF))
    begin
       $display("ERROR-3: PORT C Exp: %x  Rxd: %x",exp_port_c & 8'hBF,port_c_in & 8'hBF);
       `TB_GLBL.test_fail = 1;
    end else begin
       $display("STATUS: PORT C Data: %x Matched  ",port_c_in & 8'hBF);
    end

    if((exp_port_d & 8'hFF) != (port_d_in & 8'hFF))
    begin
       $display("ERROR-4: PORT D Exp: %x  Rxd: %x",exp_port_d & 8'hFF,port_d_in & 8'hFF);
       `TB_GLBL.test_fail = 1;
    end else begin
       $display("STATUS: PORT D Data: %x Matched  ",port_d_in & 8'hFF);
    end
end
endtask

/***************************
* Check the GPIO input
* **************************/

task cmp_gpio_input;
input [7:0] port_a;
input [7:0] port_b;
input [7:0] port_c;
input [7:0] port_d;

reg [31:0] read_data;
reg [7:0] exp_port_a;
reg [7:0] exp_port_b;
reg [7:0] exp_port_c;
reg [7:0] exp_port_d;
begin
    port_a_out  = port_a;
    port_b_out  = port_b;
    port_c_out  = port_c;
    port_d_out  = port_d;

	repeat (200) @(posedge clock); // for de-glitch period
    `SPIM_REG_READ(`ADDR_SPACE_GPIO+`GPIO_CFG_IDATA,read_data);
  
    exp_port_a  = read_data[7:0];
    exp_port_b  = read_data[15:8];
    exp_port_c  = read_data[23:16];
    exp_port_d  = read_data[31:24];

    if((exp_port_a & 8'hFF) != (port_a & 8'hFF))
    begin
       $display("ERROR-5: PORT A Exp: %x  Rxd: %x",exp_port_a & 8'hFF,port_a & 8'hFF);
       `TB_GLBL.test_fail = 1;
    end else begin
       $display("STATUS: PORT A Data: %x Matched  ",port_a & 8'hFF);
    end
    
    if((exp_port_b & 8'hC7) != (port_b & 8'hC7))
    begin
       $display("ERROR-6: PORT B Exp: %x  Rxd: %x",exp_port_b & 8'hC7,port_b & 8'hC7);
       `TB_GLBL.test_fail = 1;
    end else begin
       $display("STATUS: PORT B Data: %x Matched  ",port_b & 8'hC7);
    end
    
    if((exp_port_c & 8'hBF) != (port_c & 8'hBF))
    begin
       $display("ERROR-7: PORT C Exp: %x  Rxd: %x",exp_port_c & 8'hBF,port_c & 8'hBF);
       `TB_GLBL.test_fail = 1;
    end else begin
       $display("STATUS: PORT C Data: %x Matched  ",port_c & 8'hBF);
    end

    if((exp_port_d & 8'hFF) != (port_d & 8'hFF))
    begin
       $display("ERROR-8: PORT D Exp: %x  Rxd: %x",exp_port_d & 8'hFF,port_d & 8'hFF);
       `TB_GLBL.test_fail = 1;
    end else begin
       $display("STATUS: PORT D Data: %x Matched  ",port_d & 8'hFF);
    end
end
endtask


// Check for posedge Interrupt
task cmp_gpio_pos_intr;
input [7:0] port_a;
input [7:0] port_b;
input [7:0] port_c;
input [7:0] port_d;
reg [31:0] read_data;
reg [31:0] exp_data;
begin

   // Drive GPIO with zero
    cmp_gpio_input(8'h00,8'h00,8'h00,8'h00);

   // Clear all the Interrupt
    `SPIM_REG_WRITE(`ADDR_SPACE_GPIO+`GPIO_CFG_INTR_CLR,'hFFFFFFFF);
    exp_data = 0;
    `SPIM_REG_MASK_CHECK(`ADDR_SPACE_GPIO+`GPIO_CFG_INTR_STAT,32'hFFBFC7FF,exp_data);
    // Clear Global Interrupt
    `SPIM_REG_WRITE(`ADDR_SPACE_GLBL+`GLBL_CFG_INTR_STAT,'hFFFFFFFF);
    `SPIM_REG_MASK_CHECK(`ADDR_SPACE_GLBL+`GPIO_CFG_INTR_STAT,32'hFFBFC700,exp_data);

    // Drive Ports
    cmp_gpio_input(port_d,port_c,port_b,port_a);


    // Wait for Edge Detection
    repeat (20) @(posedge clock); 

   // Drive GPIO with zero
    cmp_gpio_input(8'h00,8'h00,8'h00,8'h00);

    // Wait for Edge Detection
    repeat (20) @(posedge clock); 

    // Check the GPIO Interrupt
    exp_data = {port_d[7:0],port_c[7:0],port_b[7:0],port_a[7:0]};
    `SPIM_REG_MASK_CHECK(`ADDR_SPACE_GPIO+`GPIO_CFG_INTR_STAT,32'hFFBFC7FF,exp_data);
    
    // Check The Global Interrupt
    `SPIM_REG_MASK_CHECK(`ADDR_SPACE_GLBL+`GLBL_CFG_INTR_STAT,32'hFFBFC700,exp_data);
    
    if(irq_lines[31:8] == 0) begin
	$display("ERROR-13: Global GPIO Interrupt not detected");
       `TB_GLBL.test_fail = 1;
    end

    // Clear The GPIO Interrupt
    `SPIM_REG_WRITE(`ADDR_SPACE_GPIO+`GPIO_CFG_INTR_CLR,32'hFFFFFFFF);

    // Clear GLBL Interrupt
    `SPIM_REG_WRITE(`ADDR_SPACE_GLBL+`GLBL_CFG_INTR_STAT,'hFFFFFFFF);


    // Check Interrupt are cleared
    exp_data = 0;
    `SPIM_REG_MASK_CHECK(`ADDR_SPACE_GLBL+`GLBL_CFG_INTR_STAT,32'hFFBFC7FF,exp_data);
    `SPIM_REG_MASK_CHECK(`ADDR_SPACE_GPIO+`GPIO_CFG_INTR_STAT,32'hFFBFC700,exp_data);

    if(irq_lines[15] != 1'b0) begin
	$display("ERROR-14: Global GPIO Interrupt is not cleared");
       `TB_GLBL.test_fail = 1;
    end

end
endtask

// Check for negedge Interrupt
task cmp_gpio_neg_intr;
input [7:0] port_a;
input [7:0] port_b;
input [7:0] port_c;
input [7:0] port_d;
reg [31:0] exp_data;
begin

   // Drive GPIO with All One's
    cmp_gpio_input(8'hFF,8'hFF,8'hFF,8'hFF);

    `SPIM_REG_WRITE(`ADDR_SPACE_GPIO+`GPIO_CFG_INTR_CLR,'hFFFFFFFF);
    `SPIM_REG_MASK_CHECK(`ADDR_SPACE_GPIO+`GPIO_CFG_INTR_STAT,32'hFFBFC7FF,32'h0);

    // Clear Global Interrupt
    `SPIM_REG_WRITE(`ADDR_SPACE_GLBL+`GLBL_CFG_INTR_STAT,'hFFFFFFFF);
    `SPIM_REG_MASK_CHECK(`ADDR_SPACE_GLBL+`GLBL_CFG_INTR_STAT,32'hFFBFC700,32'h0);

    // Drive Ports
    cmp_gpio_input(port_d,port_c,port_b,port_a);

    // Wait for Edge Detection
    repeat (20) @(posedge clock); 

   // Drive GPIO with All One's
    cmp_gpio_input(8'hFF,8'hFF,8'hFF,8'hFF);

    // Wait for Edge Detection
    repeat (20) @(posedge clock); 

    // Neg edge interrupt is will compliment  of input value
    exp_data = {port_d[7:0] ^ 8'hFF,port_c[7:0] ^ 8'hFF,port_b[7:0] ^ 8'hFF,port_a[7:0] ^ 8'hFF};
    `SPIM_REG_MASK_CHECK(`ADDR_SPACE_GPIO+`GPIO_CFG_INTR_STAT,32'hFFBFC7FF,exp_data);
    
    // Check The Global Interrupt
    `SPIM_REG_MASK_CHECK(`ADDR_SPACE_GLBL+`GLBL_CFG_INTR_STAT,32'hFFBFC700,exp_data);

    if(irq_lines[31:8] == 0) begin
	$display("ERROR-15: Global GPIO Interrupt not detected");
       `TB_GLBL.test_fail = 1;
    end

    // Clear The GPIO Interrupt
    `SPIM_REG_WRITE(`ADDR_SPACE_GPIO+`GPIO_CFG_INTR_CLR,32'hFFFFFFFF);

    // Clear GPIO Interrupt
    `SPIM_REG_WRITE(`ADDR_SPACE_GLBL+`GLBL_CFG_INTR_STAT,'hFFFFFFFF);

    // Check Interrupt are cleared
    `SPIM_REG_MASK_CHECK(`ADDR_SPACE_GLBL+`GLBL_CFG_INTR_STAT,32'hFFBFC7FF,32'h0);
    `SPIM_REG_MASK_CHECK(`ADDR_SPACE_GPIO+`GPIO_CFG_INTR_STAT,32'hFFBFC700,32'h0);

    if(irq_lines[15] != 1'b0) begin
	$display("ERROR-16: Global GPIO Interrupt is not cleared");
       `TB_GLBL.test_fail = 1;
    end
end
endtask

// Check for slow De-Glitch (1us based sampling)
task check_slow_dglitch;
reg [7:0] port_a;
reg [7:0] port_b;
reg [7:0] port_c;
reg [7:0] port_d;
reg [31:0] exp_data;
begin
    $display("STATUS: Testing Slow De-Glitch Mode");
    `SPIM_REG_WRITE(`ADDR_SPACE_GLBL+`GLBL_CFG_CFG1,32'h0);
    port_a = 8'hAA;
    port_b = 8'hAA;
    port_c = 8'hAA;
    port_d = 8'hAA;
    port_a_out  = port_a;
    port_b_out  = port_b;
    port_c_out  = port_c;
    port_d_out  = port_d;

	repeat (200) @(posedge clock); // for de-glitch period
    exp_data = {port_d[7:0],port_c[7:0],port_b[7:0],port_a[7:0]};
    `SPIM_REG_MASK_CHECK(`ADDR_SPACE_GPIO+`GPIO_CFG_IDATA,32'hFFBFC7FF,exp_data);

    port_a_out = $random();
    port_b_out = $random();
    port_c_out = $random();
    port_d_out = $random();
	repeat (10) @(posedge clock); 
    port_a_out  = port_a;
    port_b_out  = port_b;
    port_c_out  = port_c;
    port_d_out  = port_d;
	repeat (10) @(posedge clock); 
    port_a_out = $random();
    port_b_out = $random();
    port_c_out = $random();
    port_d_out = $random();
	repeat (10) @(posedge clock); 
    port_a_out  = port_a;
    port_b_out  = port_b;
    port_c_out  = port_c;
    port_d_out  = port_d;
	repeat (10) @(posedge clock); 
    exp_data = {port_d[7:0],port_c[7:0],port_b[7:0],port_a[7:0]};
    `SPIM_REG_MASK_CHECK(`ADDR_SPACE_GPIO+`GPIO_CFG_IDATA,32'hFFBFC7FF,exp_data);

    port_a = 8'h11;
    port_b = 8'h22;
    port_c = 8'h33;
    port_d = 8'h44;
    port_a_out  = port_a;
    port_b_out  = port_b;
    port_c_out  = port_c;
    port_d_out  = port_d;
	repeat (200) @(posedge clock); 
    exp_data = {port_d[7:0],port_c[7:0],port_b[7:0],port_a[7:0]};
    `SPIM_REG_MASK_CHECK(`ADDR_SPACE_GPIO+`GPIO_CFG_IDATA,32'hFFBFC7FF,exp_data);
    
    port_a = 8'h55;
    port_b = 8'h66;
    port_c = 8'h77;
    port_d = 8'h88;
    port_a_out  = port_a;
    port_b_out  = port_b;
    port_c_out  = port_c;
    port_d_out  = port_d;
	repeat (200) @(posedge clock); 
    exp_data = {port_d[7:0],port_c[7:0],port_b[7:0],port_a[7:0]};
    `SPIM_REG_MASK_CHECK(`ADDR_SPACE_GPIO+`GPIO_CFG_IDATA,32'hFFBFC7FF,exp_data);
end
endtask


// Check for slow De-Glitch (system clock based sampling)
task check_fast_dglitch;
reg [7:0] port_a;
reg [7:0] port_b;
reg [7:0] port_c;
reg [7:0] port_d;
reg [31:0] exp_data;
begin
    $display("STATUS: Testing Fast De-Glitch Mode");
    `SPIM_REG_WRITE(`ADDR_SPACE_GLBL+`GLBL_CFG_CFG1,32'h100);
    port_a = 8'h55;
    port_b = 8'h55;
    port_c = 8'h55;
    port_d = 8'h55;
    port_a_out  = port_a;
    port_b_out  = port_b;
    port_c_out  = port_c;
    port_d_out  = port_d;

	repeat (10) @(posedge clock); // for de-glitch period
    exp_data = {port_d[7:0],port_c[7:0],port_b[7:0],port_a[7:0]};
    `SPIM_REG_MASK_CHECK(`ADDR_SPACE_GPIO+`GPIO_CFG_IDATA,32'hFFBFC7FF,exp_data);

    port_a_out = $random();
    port_b_out = $random();
    port_c_out = $random();
    port_d_out = $random();

	repeat (2) @(posedge clock); 
    port_a_out  = port_a;
    port_b_out  = port_b;
    port_c_out  = port_c;
    port_d_out  = port_d;
	repeat (2) @(posedge clock); 

    port_a_out = $random();
    port_b_out = $random();
    port_c_out = $random();
    port_d_out = $random();
	repeat (2) @(posedge clock); 
    port_a_out  = port_a;
    port_b_out  = port_b;
    port_c_out  = port_c;
    port_d_out  = port_d;
	repeat (2) @(posedge clock); 
    exp_data = {port_d[7:0],port_c[7:0],port_b[7:0],port_a[7:0]};
    `SPIM_REG_MASK_CHECK(`ADDR_SPACE_GPIO+`GPIO_CFG_IDATA,32'hFFBFC7FF,exp_data);

    port_a = 8'h11;
    port_b = 8'h22;
    port_c = 8'h33;
    port_d = 8'h44;
    port_a_out  = port_a;
    port_b_out  = port_b;
    port_c_out  = port_c;
    port_d_out  = port_d;
	repeat (10) @(posedge clock); 
    exp_data = {port_d[7:0],port_c[7:0],port_b[7:0],port_a[7:0]};
    `SPIM_REG_MASK_CHECK(`ADDR_SPACE_GPIO+`GPIO_CFG_IDATA,32'hFFBFC7FF,exp_data);
    
    port_a = 8'h55;
    port_b = 8'h66;
    port_c = 8'h77;
    port_d = 8'h88;
    port_a_out  = port_a;
    port_b_out  = port_b;
    port_c_out  = port_c;
    port_d_out  = port_d;
	repeat (10) @(posedge clock); 
    exp_data = {port_d[7:0],port_c[7:0],port_b[7:0],port_a[7:0]};
    `SPIM_REG_MASK_CHECK(`ADDR_SPACE_GPIO+`GPIO_CFG_IDATA,32'hFFBFC7FF,exp_data);

end
endtask

endmodule
`default_nettype wire
