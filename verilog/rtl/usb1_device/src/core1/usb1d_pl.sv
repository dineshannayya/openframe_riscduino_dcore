/////////////////////////////////////////////////////////////////////
////                                                             ////
////  Protocol Layer                                             ////
////  This block is typically referred to as the SEI in USB      ////
////  Specification. It encapsulates the Packet Assembler,       ////
////  disassembler, protocol engine and internal DMA             ////
////                                                             ////
////  Author: Rudolf Usselmann                                   ////
////          rudi@asics.ws                                      ////
////                                                             ////
////                                                             ////
////  Downloaded from: http://www.opencores.org/cores/usb1_fucnt/////
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

module usb1d_pl(	
        input logic          clk             , 
        input logic          rst             ,

		// UTMI Interface
		input logic [7:0]    rx_data         , 
        input logic          rx_valid        , 
        input logic          rx_active       , 
        input logic          rx_err          ,


		output logic [7:0]   tx_data         , 
        output logic         tx_valid        , 
        output logic         tx_valid_last   , 
        output logic         tx_ready        ,
		output logic         tx_first        , 

		output logic         token_valid     ,

        input logic [7:0]    cfg_max_hms     ,

		// Register File Interface
		input  logic [6:0]   fa              , // Function Address (as set by the controller)
		output logic [3:0]   ep_sel          , // Endpoint Number Input
		output logic         x_busy          , // Indicates USB is busy

		// Misc
		output logic [31:0]  frm_nat         ,
		output logic         pid_cs_err      , // pid checksum error
		output logic         crc5_err        , // crc5 error
		output logic [7:0]   rx_size, 
        output logic         rx_done,

		// EP Interface
        input  logic	[7:0]	tx_data_st,
        output logic	[7:0]	rx_ctrl_data,
        output logic	[7:0]	rx_ctrl_data_d,
        output logic		    rx_ctrl_dvalid,
        output logic		    rx_ctrl_ddone


		);



///////////////////////////////////////////////////////////////////
//
// Local Wires and Registers
//

// Packet Disassembler Interface
wire		clk, rst;
wire	[7:0]	rx_data;
wire		pid_OUT, pid_IN, pid_SOF, pid_SETUP;
wire		pid_DATA0, pid_DATA1, pid_DATA2, pid_MDATA;
wire		pid_ACK, pid_NACK, pid_STALL, pid_NYET;
wire		pid_PRE, pid_ERR, pid_SPLIT, pid_PING;
wire	[6:0]	token_fadr;
wire		token_valid;
wire		crc5_err;
wire	[10:0]	frame_no;
wire	[7:0]	rx_ctrl_data;
reg	[7:0]	rx_ctrl_data_d;
wire		rx_ctrl_dvalid;
wire		rx_ctrl_ddone;
wire		crc16_err;
wire		rx_seq_err;

// Packet Assembler Interface
wire		send_token;
wire	[1:0]	token_pid_sel;
wire		send_data;
wire	[1:0]	data_pid_sel;
wire	[7:0]	tx_data_st;
wire	[7:0]	tx_data_st_o;
wire		rd_next;

// Memory Arbiter Interface

// Local signals
wire		pid_bad;

reg		hms_clk;	// 0.5 Micro Second Clock
reg	[7:0]	hms_cnt;
reg	[10:0]	frame_no_r;	// Current Frame Number register
wire		frame_no_we;
reg	[11:0]	sof_time;	// Time since last sof
reg		clr_sof_time;

reg		frame_no_we_r;

wire		ep_empty_int;
wire		rx_busy;
wire		tx_busy;

///////////////////////////////////////////////////////////////////
//
// Misc Logic
//

assign x_busy = tx_busy | rx_busy;

// PIDs we should never receive
assign pid_bad = pid_ACK | pid_NACK | pid_STALL | pid_NYET | pid_PRE |
			pid_ERR | pid_SPLIT |  pid_PING;



// Frame Number (from SOF token)
assign frame_no_we = token_valid & !crc5_err & pid_SOF;

always @(posedge clk)
	frame_no_we_r <= #1 frame_no_we;

always @(posedge clk or negedge rst)
	if(!rst)		frame_no_r <= #1 11'h0;
	else
	if(frame_no_we_r)	frame_no_r <= #1 frame_no;

//SOF delay counter
always @(posedge clk)
	clr_sof_time <= #1 frame_no_we;

always @(posedge clk)
	if(clr_sof_time)	sof_time <= #1 12'h0;
	else
	if(hms_clk)		sof_time <= #1 sof_time + 12'h1;

assign frm_nat = {4'h0, 1'b0, frame_no_r, 4'h0, sof_time};

// 0.5 Micro Seconds Clock Generator
always @(posedge clk or negedge rst)
	if(!rst)				hms_cnt <= #1 5'h0;
	else
	if(hms_clk | frame_no_we_r)		hms_cnt <= #1 5'h0;
	else					        hms_cnt <= #1 hms_cnt + 5'h1;

always @(posedge clk)
	hms_clk <= #1 (hms_cnt == cfg_max_hms);

always @(posedge clk)
	rx_ctrl_data_d <= rx_ctrl_data;

///////////////////////////////////////////////////////////////////



///////////////////////////////////////////////////////////////////
//
// Module Instantiations
//

//Packet Decoder
usb1d_pd	u0(	
        .clk             (	clk		         ),
		.rst             (	rst		         ),

		.rx_data         (rx_data	         ),
		.rx_valid        (rx_valid	         ),
		.rx_active       (rx_active	         ),
		.rx_err          (rx_err	         ),

		.pid_OUT         (pid_OUT	         ),
		.pid_IN          (pid_IN	         ),
		.pid_SOF         (pid_SOF	         ),
		.pid_SETUP       (pid_SETUP	         ),
		.pid_DATA0       (pid_DATA0	         ),
		.pid_DATA1       (pid_DATA1	         ),
		.pid_DATA2       (pid_DATA2	         ),
		.pid_MDATA       (pid_MDATA	         ),
		.pid_ACK         (pid_ACK	         ),
		.pid_NACK        (pid_NACK	         ),
		.pid_STALL       (pid_STALL	         ),
		.pid_NYET        (pid_NYET	         ),
		.pid_PRE         (pid_PRE	         ),
		.pid_ERR         (pid_ERR	         ),
		.pid_SPLIT       (pid_SPLIT	         ),
		.pid_PING        (pid_PING	         ),
		.pid_cks_err     (pid_cs_err	     ),
		.token_fadr      (token_fadr	     ),
		.token_endp      (ep_sel		     ),
		.token_valid     (token_valid	     ),
		.crc5_err        (crc5_err	         ),
		.frame_no        (frame_no	         ),
		.rx_data_st      (rx_ctrl_data	     ),
		.rx_data_valid   (rx_ctrl_dvalid     ),
		.rx_data_done    (rx_ctrl_ddone	     ),
		.crc16_err       (crc16_err	         ),
		.seq_err         (rx_seq_err	     ),
		.rx_busy         (rx_busy		     )
		);

// Packet Assembler
usb1d_pa	u1(	

        .clk             (clk		        ),
		.rst             (rst		        ),
		.tx_data         (tx_data		    ),
		.tx_valid        (tx_valid	        ),
		.tx_valid_last   (tx_valid_last	    ),
		.tx_ready        (tx_ready	        ),
		.tx_first        (tx_first       	),
		.send_token      (send_token	    ),
		.token_pid_sel   (token_pid_sel	    ),
		.send_data       (send_data      	),
		.data_pid_sel    (data_pid_sel	    ),
		.tx_data_st      (tx_data_st_o	    ),
		.rd_next         (rd_next		    ),
		.ep_empty        (ep_empty_int      )
		);




endmodule
