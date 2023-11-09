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

`include "usb1bd_defines.v"

module usb1bd_pl(	
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


		// Register File Interface
        input logic [7:0]    cfg_max_hms         ,
		input  logic         cfg_tx_send_token   , 
        input  logic [1:0]   cfg_tx_token_pid_sel,
		input  logic         cfg_tx_send_data    , 
        input  logic [1:0]   cfg_tx_data_pid_sel ,


		output logic         rx_token_valid  ,
		output logic [6:0]   rx_token_fadr,       // Function address from token
		output logic [3:0]   rx_ep_sel       , // Endpoint Number Input
		output logic         x_busy          , // Indicates USB is busy

		// Misc
		output logic [31:0]  frm_nat         ,
		output logic         pid_cs_err      , // pid checksum error
		output logic         crc5_err        , // crc5 error
        output logic         crc16_err       , // Data packet CRC 16 error

		// TX FIFO
        input  logic [7:0]	 tx_fifo_data    ,
        output logic         tx_fifo_re      ,
		input  logic         tx_fifo_empty   ,

		// RX FIFO
        output logic [7:0]	 rx_fifo_data    ,
        output logic		 rx_fifo_dvalid  ,
        output logic		 rx_fifo_ddone


		);



///////////////////////////////////////////////////////////////////
//
// Local Wires and Registers
//

// Packet Disassembler Interface
wire		pid_OUT, pid_IN, pid_SOF, pid_SETUP;
wire		pid_DATA0, pid_DATA1, pid_DATA2, pid_MDATA;
wire		pid_ACK, pid_NACK, pid_STALL, pid_NYET;
wire		pid_PRE, pid_ERR, pid_SPLIT, pid_PING;
wire	[10:0]	frame_no;
wire		rx_ctrl_ddone;
wire		rx_seq_err;

// Packet Assembler Interface
wire		send_token;
wire	[1:0]	token_pid_sel;
wire		send_data;
wire	[1:0]	data_pid_sel;
wire	[7:0]	tx_data_st_o;

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

wire		rx_busy ; 
wire		tx_busy = 0; // Need fix Dinesh

///////////////////////////////////////////////////////////////////
//
// Misc Logic
//

assign x_busy = tx_busy | rx_busy;

// PIDs we should never receive
assign pid_bad = pid_ACK | pid_NACK | pid_STALL | pid_NYET | pid_PRE |
			pid_ERR | pid_SPLIT |  pid_PING;



// Frame Number (from SOF token)
assign frame_no_we = rx_token_valid & !crc5_err & pid_SOF;

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


///////////////////////////////////////////////////////////////////



///////////////////////////////////////////////////////////////////
//
// Module Instantiations
//

//Packet Decoder
usb1bd_pd	u0(	
        .clk             (	clk		         ),
		.rst_n           (	rst		         ),

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
		.token_fadr      (rx_token_fadr	     ),
		.token_endp      (rx_ep_sel		     ),
		.token_valid     (rx_token_valid	 ),

		.rx_data_st      (rx_fifo_data	     ),
		.rx_data_valid   (rx_fifo_dvalid     ),
		.rx_data_done    (rx_fifo_ddone	     ),

		.frame_no        (frame_no	         ),
		.crc5_err        (crc5_err	         ),
		.crc16_err       (crc16_err	         ),
		.seq_err         (rx_seq_err	     ),
		.rx_busy         (rx_busy		     )
		);

// Packet Assembler
usb1bd_pa	u1(	

        .clk                 (clk		            ),
		.rst_n               (rst_n		            ),

		// UTMI TX I/F
		.tx_data             (tx_data		        ),
		.tx_valid            (tx_valid	            ),
		.tx_valid_last       (tx_valid_last	        ),
		.tx_ready            (tx_ready	            ),
		.tx_first            (tx_first       	    ),

		// Register I/F
		.cfg_tx_send_token   (cfg_tx_send_token	    ),
		.cfg_tx_token_pid_sel(cfg_tx_token_pid_sel	),
		.cfg_tx_send_data    (cfg_tx_send_data      ),
		.cfg_tx_data_pid_sel (cfg_tx_data_pid_sel	),

		.tx_fifo_data        (tx_fifo_data	        ),
		.tx_fifo_re          (tx_fifo_re		    ),
		.tx_fifo_empty       (tx_fifo_empty         )
		);




endmodule
