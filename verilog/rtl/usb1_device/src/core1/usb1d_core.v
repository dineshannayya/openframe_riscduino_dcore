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


`include "usb1d_defines.v"


module usb1d_core(

       input           clk_i         , 
       input           rst_i         ,

	// UTMI Interface
	   output [7:0]   DataOut        , 
       output         TxValid        ,  
       input          TxReady        , 

       input          RxValid        ,
	   input          RxActive       , 
       input          RxError        , 
       input [7:0]    DataIn         , 
       input [1:0]    LineState      ,
		// USB Misc
	   input 	      phy_tx_mode    , 
       input          usb_rst        , 


		// Register Interface
        input         app_clk        ,
        input         app_rstn       ,
		input  [31:0] app_reg_addr   ,
		input         app_reg_rdwrn  ,
		input         app_reg_req    ,
		input [31:0]  app_reg_wdata  ,
		output [31:0] app_reg_rdata  ,
		output        app_reg_ack

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

// Internal Register File Interface
wire	[6:0]	funct_adr;	// This functions address (set by controller)
wire	[3:0]	ep_sel;		// Endpoint Number Input
wire		    crc16_err;	// Set CRC16 error interrupt
wire		    int_to_set;	// Set time out interrupt
wire		    int_seqerr_set;	// Set PID sequence error interrupt
wire	[31:0]	frm_nat;	// Frame Number and Time Register
wire		    nse_err;	// No Such Endpoint Error
wire		    pid_cs_err;	// PID CS error
wire		    crc5_err;	// CRC5 Error

reg	[7:0]	    tx_data_st;
wire	[7:0]	rx_ctrl_data;
wire	[7:0]	rx_ctrl_data_d;
reg	[13:0]	    cfg;
wire            rx_ctrl_dvalid;
wire            rx_ctrl_ddone;
wire	[7:0]	rx_size;
wire		    rx_done;


wire		    send_stall;
wire		    token_valid;
reg		        rst_local;		// internal reset
wire		    dropped_frame;
wire		    misaligned_frame;

reg		    ep_bf_en;
reg	[6:0]	ep_bf_size;


///////////////////////////////////////////////////////////////////
//
// Misc Logic
//

always @(posedge clk_i)
	rst_local <= #1 rst_i & ~usb_rst;


//------------------------
// UTMI Interface
//------------------------
usb1d_utmi_if	u0(
		.phy_clk         (clk_i			),
		.rst             (rst_local		),
		// Interface towards Phy-Tx
		.DataOut         (DataOut	    ),
		.TxValid         (TxValid		),
		.TxReady         (TxReady		),

		// Interface towards Phy-rx
		.RxValid         (RxValid		),
		.RxActive        (RxActive		),
		.RxError         (RxError		),
		.DataIn          (DataIn		),

		// Interfcae towards protocol layer-rx
		.rx_data         (rx_data		),
		.rx_valid        (rx_valid		),
		.rx_active       (rx_active		),
		.rx_err          (rx_err		),

		// Interfcae towards protocol layer-tx
		.tx_data         (tx_data		),
		.tx_valid        (tx_valid		),
		.tx_valid_last   (tx_valid_last	),
		.tx_ready        (tx_ready		),
		.tx_first        (tx_first		)
		);

//------------------------
// Protocol Layer
//------------------------
usb1d_pl  u1(	
         .clk            (clk_i			),
		.rst             (rst_local		),
		// Interface towards utmi-rx
		.rx_data         (rx_data		),
		.rx_valid        (rx_valid		),
		.rx_active       (rx_active		),
		.rx_err          (rx_err		),

		// Interface towards utmi-tx
		.tx_data         (tx_data		),
		.tx_valid        (tx_valid		),
		.tx_valid_last   (tx_valid_last	),
		.tx_ready        (tx_ready		),
		.tx_first        (tx_first		),
                 
		// Interface towards usb-phy-tx
		.tx_valid_out    (TxValid		),

		// unused outputs
		.token_valid     (token_valid	),
		.int_to_set      (int_to_set	),
		.int_seqerr_set  (int_seqerr_set),
		.pid_cs_err      (pid_cs_err	),
		.nse_err         (nse_err		),
		.crc5_err        (crc5_err		),
		.rx_size         (rx_size		),
		.rx_done         (rx_done		),

		// Interface towards usb-ctrl
		.fa              (funct_adr		),
		.frm_nat         (frm_nat		),
		.send_stall      (send_stall	),

		// usb-status 
		.ep_sel          (ep_sel		),
		.x_busy          (usb_busy		),
		.int_crc16_set   (crc16_err		),
		.dropped_frame   (dropped_frame	),
		.misaligned_frame(misaligned_frame),

		.ep_bf_en        (ep_bf_en		),
		.ep_bf_size      (ep_bf_size	),
		.csr             (cfg			),
		.tx_data_st      (tx_data_st	),

		.rx_ctrl_data    (rx_ctrl_data	),
		.rx_ctrl_data_d  (rx_ctrl_data_d),
		.rx_ctrl_dvalid  (rx_ctrl_dvalid),
		.rx_ctrl_ddone   (rx_ctrl_ddone ),

		.idma_re         (idma_re		),
		.idma_we         (idma_we		),
		.ep_empty        (ep_empty		),
		.ep_full         (ep_full		)
		);






endmodule
