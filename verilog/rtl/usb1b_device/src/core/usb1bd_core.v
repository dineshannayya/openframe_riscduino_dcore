/**********************************************************************
*  Ported to USB2UART Project
*  Author:  Dinesh Annayya
*           Email:- dinesha@opencores.org
*
*     Date: 4th Feb 2013
*     Changes:
*     A. Warning Clean Up
*     B. USB1-phy is move to core level
*
**********************************************************************/
/////////////////////////////////////////////////////////////////////
////                                                             ////
////  USB 1.1 function IP core                                   ////
////                                                             ////
////                                                             ////
////  Author: Rudolf Usselmann                                   ////
////          rudi@asics.ws                                      ////
////                                                             ////
////                                                             ////
////  Downloaded from: http://www.opencores.org/projects/usb1_funct/////
////                                                             ////
/////////////////////////////////////////////////////////////////////
////                                                             ////
//// Copyright (C) 2000-2002 Rudolf Usselmann                    ////
////                         www.asics.ws                        ////
////                         rudi@asics.ws                       ////
////                                                             ////
//// This source file may be used and distributed without        ////
//// restriction provided that this copyright statement is not   ////
//// removed from the file and that any derivative work contains ////
//// the original copyright notice and the associated disclaimer.////
////                                                             ////
////     THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY     ////
//// EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED   ////
//// TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS   ////
//// FOR A PARTICULAR PURPOSE. IN NO EVENT SHALL THE AUTHOR      ////
//// OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,         ////
//// INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES    ////
//// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE   ////
//// GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR        ////
//// BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF  ////
//// LIABILITY, WHETHER IN  CONTRACT, STRICT LIABILITY, OR TORT  ////
//// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT  ////
//// OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE         ////
//// POSSIBILITY OF SUCH DAMAGE.                                 ////
////                                                             ////
/////////////////////////////////////////////////////////////////////


`include "usb1bd_defines.v"


module usb1bd_core(

       input logic           clk_i               , 
       input logic           rst_i               ,
       input logic           srst_n              ,

	// UTMI Interface
	   output logic[7:0]     TxDataOut            , 
       output logic          TxValid              ,  
       input  logic          TxReady              , 

       input  logic          RxValid              ,
	   input  logic          RxActive             , 
       input  logic          RxError              , 
       input  logic[ 7:0]    RxDataIn             , 
       input  logic [1:0]    LineState            ,
		// USB Misc
	   input  logic	         phy_tx_mode          , 
       input  logic          usb_rst              , 


       // Config Register
       input  logic [7:0]    cfg_max_hms         ,
	   input  logic          cfg_tx_send_token   , 
       input  logic [1:0]    cfg_tx_token_pid_sel,
	   input  logic          cfg_tx_send_data    , 
       input  logic [1:0]    cfg_tx_data_pid_sel ,


	   output logic          rx_token_valid      ,
	   output logic [6:0]   rx_token_fadr,       // Function address from token
	   output logic [3:0]    rx_ep_sel           , // Endpoint Number Input
	   output logic          x_busy              , // Indicates USB is busy

	   // Misc
	   output logic [31:0]   frm_nat             ,
	   output logic          pid_cs_err          , // pid checksum error
	   output logic          crc5_err            , // crc5 error
       output logic          crc16_err           , // Data packet CRC 16 error

	  // TX FIFO
      input  logic [7:0]     tx_fifo_data        ,
      output logic           tx_fifo_re          ,
	  input  logic           tx_fifo_empty       ,

	  // RX FIFO
      output logic [7:0]     rx_fifo_data        ,
      output logic		     rx_fifo_dvalid      ,
      output logic		     rx_fifo_ddone

		); 		


///////////////////////////////////////////////////////////////////
//
// Local Wires and Registers
//

wire	[7:0]	rx_data;
wire		    rx_valid, rx_active, rx_err;
wire	[7:0]	tx_data;
wire		    tx_valid;
wire		    tx_ready;
wire		    tx_first;
wire		    tx_valid_last;

reg		        rst_local;		// internal reset



///////////////////////////////////////////////////////////////////
//
// Misc Logic
//

always @(posedge clk_i)
	rst_local <= #1 rst_i & ~usb_rst & srst_n;


//------------------------
// UTMI Interface
//------------------------
usb1bd_utmi_if	u0(
		.phy_clk               (clk_i			     ),
		.rst                   (rst_local		     ),
		// Interface towards Phy-Tx
		.TxDataOut             (TxDataOut	         ),
		.TxValid               (TxValid		         ),
		.TxReady               (TxReady		         ),

		// Interface towards Phy-rx
		.RxValid               (RxValid		         ),
		.RxActive              (RxActive		     ),
		.RxError               (RxError		         ),
		.RxDataIn              (RxDataIn		     ),

		// Interfcae towards protocol layer-rx
		.rx_data               (rx_data		         ),
		.rx_valid              (rx_valid		     ),
		.rx_active             (rx_active		     ),
		.rx_err                (rx_err		         ),

		// Interfcae towards protocol layer-tx
		.tx_data               (tx_data		         ),
		.tx_valid              (tx_valid		     ),
		.tx_valid_last         (tx_valid_last	     ),
		.tx_ready              (tx_ready		     ),
		.tx_first              (tx_first		     )
		);

//------------------------
// Protocol Layer
//------------------------
usb1bd_pl  u1(	

        .clk                   (clk_i			     ),
		.rst                   (rst_local		     ),

		// Interface towards utmi-rx
		.rx_data               (rx_data		         ),
		.rx_valid              (rx_valid		     ),
		.rx_active             (rx_active		     ),
		.rx_err                (rx_err		         ),

		// Interface towards utmi-tx
		.tx_data               (tx_data		         ),
		.tx_valid              (tx_valid		     ),
		.tx_valid_last         (tx_valid_last	     ),
		.tx_ready              (tx_ready		     ),
		.tx_first              (tx_first		     ),


        // Configuration
        .cfg_max_hms           (cfg_max_hms          ), 
        .cfg_tx_send_token     (cfg_tx_send_token    ),
        .cfg_tx_token_pid_sel  (cfg_tx_token_pid_sel ),
        .cfg_tx_send_data      (cfg_tx_send_data     ),
        .cfg_tx_data_pid_sel   (cfg_tx_data_pid_sel  ),

		.rx_token_valid        (rx_token_valid       ),
        .rx_token_fadr         (rx_token_fadr        ),
		.rx_ep_sel             (rx_ep_sel		     ),
		.x_busy                (x_busy   		     ),
                 
		// usb-status 
		.frm_nat               (frm_nat              ),
		.pid_cs_err            (pid_cs_err	         ),
		.crc5_err              (crc5_err		     ),
        .crc16_err             (crc16_err            ),

         // TX FIFO I/F
		.tx_fifo_data          (tx_fifo_data	     ),
		.tx_fifo_re            (tx_fifo_re	         ),
		.tx_fifo_empty         (tx_fifo_empty        ),

         // RX FIFO I/F
		.rx_fifo_data          (rx_fifo_data         ),
		.rx_fifo_dvalid        (rx_fifo_dvalid       ),
		.rx_fifo_ddone         (rx_fifo_ddone        )

		);






endmodule
