/////////////////////////////////////////////////////////////////////
////                                                             ////
////  Protocol Engine                                            ////
////  Performs automatic protocol functions                      ////
////                                                             ////
////  Author: Rudolf Usselmann                                   ////
////          rudi@asics.ws                                      ////
////                                                             ////
////                                                             ////
////  Downloaded from: http://www.opencores.org/cores/usb1_funct/////
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

module usb1bd_pe(	
        input logic              clk, 
        input logic              rst,

		// UTMI Interfaces
		input logic              tx_valid, 
        input logic              rx_active,

		// PID Information
		// Decoded PIDs (used when token_valid is asserted)
		input logic              pid_OUT, 
        input logic              pid_IN, 
        input logic              pid_SOF, 
        input logic              pid_SETUP,
		input logic              pid_DATA0, 
        input logic              pid_DATA1, 
        input logic              pid_DATA2, 
        input logic              pid_MDATA,
		input logic              pid_ACK, 
        input logic              pid_PING,

		// Token Information
		input logic              token_valid, 

		// Receive Data Output
		input logic              rx_data_done,     // Indicates end of a transfer
        input logic              crc16_err,        // Data packet CRC 16 error

		// Packet Assembler Interface
		output logic             send_token, 
        output logic       [1:0] token_pid_sel,
		output logic       [1:0] data_pid_sel,

		// IDMA Interface
		output logic             rx_dma_en, // Allows the data to be stored
        output logic             tx_dma_en, // Allows for data to be retrieved
		output logic             abort,     // Abort Transfer (time_out, crc_err or rx_error)
		input  logic             idma_done, // DMA is done indicator

		// Register File Interface

		input  logic            fsel,       // This function is selected
        input  logic            match,      // Endpoint Matched
        output logic            nse_err,    // no such endpoint error


		input  logic            ep_full,    // Indicates the endpoints fifo is full
        input  logic            ep_empty,   // Indicates the endpoints fifo is empty

        output logic            int_crc16_set, // Set CRC16 error interrupt
        output logic            int_to_set,    // Set time out interrupt
        output logic            int_seqerr_set,	// Set PID sequence error interrupt

		input  logic [13:0]     cfg_csr,        // Internal CSR Output
		input  logic            cfg_send_stall,    // Force sending a STALL during setup

        input  logic [1:0]      cfg_this_dpid  // current pid

		);



///////////////////////////////////////////////////////////////////
//
// Local Wires and Registers
//

// tx token decoding
parameter	ACK   = 0,
		    NACK  = 1,
		    STALL = 2,
		    NYET  = 3;

// State decoding
parameter	[9:0]	// synopsys enum state
		IDLE	= 10'b000000_0001,
		TOKEN	= 10'b000000_0010,
		IN	    = 10'b000000_0100,
		IN2	    = 10'b000000_1000,
		OUT	    = 10'b000001_0000,
		OUT2A	= 10'b000010_0000,
		OUT2B	= 10'b000100_0000,
		UPDATEW	= 10'b001000_0000,
		UPDATE	= 10'b010000_0000,
		UPDATE2	= 10'b100000_0000;

reg	[1:0]	token_pid_sel_d;
reg		    int_seqerr_set_d;
reg		    send_token_d;

reg		    match_r;

// Endpoint Decoding
wire		IN_ep, OUT_ep, CTRL_ep;		// Endpoint Types
wire		txfr_iso, txfr_bulk, txfr_int;	// Transfer Types

reg	[1:0]	uc_dpd;

// Buffer checks
reg	[9:0]	/* synopsys enum state */ state, next_state;
// synopsys state_vector state

// PID next and current decoders
reg		pid_seq_err;
wire	[1:0]	tr_fr_d;

wire	[13:0]	size_next;
wire		buf_smaller;

// After sending Data in response to an IN token from host, the
// host must reply with an ack. The host has XXXnS to reply.
// "rx_ack_to" indicates when this time has expired.
// rx_ack_to_clr, clears the timer
reg		    rx_ack_to_clr;
reg		    rx_ack_to_clr_d;
reg		    rx_ack_to;
reg	[7:0]	rx_ack_to_cnt;

// After sending a OUT token the host must send a data packet.
// The host has XX nS to send the packet. "tx_data_to" indicates
// when this time has expired.
// tx_data_to_clr, clears the timer
wire		tx_data_to_clr;
reg		tx_data_to;
reg	[7:0]	tx_data_to_cnt;

wire	[7:0]	rx_ack_to_val, tx_data_to_val;


wire	[1:0]	next_bsel;
reg		uc_stat_set_d;
reg		uc_dpd_set;


wire	[1:0]	ep_type, txfr_type;

///////////////////////////////////////////////////////////////////
//
// Misc Logic
//

// Endpoint/CSR Decoding
assign IN_ep        = cfg_csr[9];
assign OUT_ep       = cfg_csr[10];
assign CTRL_ep      = cfg_csr[11];

assign txfr_iso     = cfg_csr[12];
assign txfr_bulk    = cfg_csr[13];
assign txfr_int     = !cfg_csr[12] & !cfg_csr[13];

assign ep_type      = cfg_csr[10:9];
assign txfr_type    = cfg_csr[13:12];

always @(posedge clk)
	match_r <= #1 match  & fsel;

// No Such Endpoint Indicator
always @(posedge clk)
	nse_err <= #1 token_valid & (pid_OUT | pid_IN | pid_SETUP) & !match;

always @(posedge clk)
	send_token <= #1 send_token_d;

always @(posedge clk)
	token_pid_sel <= #1 token_pid_sel_d;


// Current PID decoder

// Assign PID for outgoing packets
assign data_pid_sel = cfg_this_dpid;

// Verify PID for incoming data packets
always @(posedge clk)
	pid_seq_err <= #1 !(	(cfg_this_dpid==2'b00 & pid_DATA0) |
				            (cfg_this_dpid==2'b01 & pid_DATA1) |
				            (cfg_this_dpid==2'b10 & pid_DATA2) |
				            (cfg_this_dpid==2'b11 & pid_MDATA)	);


///////////////////////////////////////////////////////////////////
//
// Determine if packet is to small or to large
// This is used to NACK and ignore packet for OUT endpoints
//


///////////////////////////////////////////////////////////////////
//
// Register File Update Logic
//

always @(posedge clk)
	uc_dpd_set <= #1 uc_stat_set_d;

// Abort signal
always @(posedge clk)
	abort <= #1 match & fsel & (state != IDLE);

///////////////////////////////////////////////////////////////////
//
// TIME OUT TIMERS
//

// After sending Data in response to an IN token from host, the
// host must reply with an ack. The host has 622nS in Full Speed
// mode and 400nS in High Speed mode to reply.
// "rx_ack_to" indicates when this time has expired.
// rx_ack_to_clr, clears the timer

always @(posedge clk)
	rx_ack_to_clr <= #1 tx_valid | rx_ack_to_clr_d;

always @(posedge clk)
	if(rx_ack_to_clr)	rx_ack_to_cnt <= #1 8'h0;
	else			rx_ack_to_cnt <= #1 rx_ack_to_cnt + 8'h1;

always @(posedge clk)
	rx_ack_to <= #1 (rx_ack_to_cnt == rx_ack_to_val);

assign rx_ack_to_val = `USB1BD_RX_ACK_TO_VAL_FS;

// After sending a OUT token the host must send a data packet.
// The host has 622nS in Full Speed mode and 400nS in High Speed
// mode to send the data packet.
// "tx_data_to" indicates when this time has expired.
// "tx_data_to_clr" clears the timer

assign	tx_data_to_clr = rx_active;

always @(posedge clk)
	if(tx_data_to_clr)	tx_data_to_cnt <= #1 8'h0;
	else			tx_data_to_cnt <= #1 tx_data_to_cnt + 8'h1;

always @(posedge clk)
	tx_data_to <= #1 (tx_data_to_cnt == tx_data_to_val);

assign tx_data_to_val = `USB1BD_TX_DATA_TO_VAL_FS;

///////////////////////////////////////////////////////////////////
//
// Interrupts
//
reg	pid_OUT_r, pid_IN_r, pid_PING_r, pid_SETUP_r;

always @(posedge clk)
	pid_OUT_r <= #1 pid_OUT;

always @(posedge clk)
	pid_IN_r <= #1 pid_IN;

always @(posedge clk)
	pid_PING_r <= #1 pid_PING;

always @(posedge clk)
	pid_SETUP_r <= #1 pid_SETUP;


assign int_to_set  = ((state == IN2) & rx_ack_to) | ((state == OUT) & tx_data_to);

assign int_crc16_set = rx_data_done & crc16_err;

always @(posedge clk)
	int_seqerr_set <= #1 int_seqerr_set_d;

reg	send_stall_r;

always @(posedge clk or negedge rst)
	if(!rst)	send_stall_r <= #1 1'b0;
	else
	if(cfg_send_stall)	send_stall_r <= #1 1'b1;
	else	
	if(send_token)	send_stall_r <= #1 1'b0;

///////////////////////////////////////////////////////////////////
//
// Main Protocol State Machine
//

always @(posedge clk or negedge rst)
	if(!rst)	state <= #1 IDLE;
	else
	if(match)	state <= #1 IDLE;
	else		state <= #1 next_state;

always @(state or 
	pid_seq_err or idma_done or ep_full or ep_empty or
	token_valid or pid_ACK or rx_data_done or
	tx_data_to or crc16_err or 
	rx_ack_to or pid_PING or txfr_iso or txfr_int or
	CTRL_ep or pid_IN or pid_OUT or IN_ep or OUT_ep or pid_SETUP or pid_SOF
	or match_r or abort or send_stall_r
	)
   begin
	next_state = state;
	token_pid_sel_d = ACK;
	send_token_d = 1'b0;
	rx_dma_en = 1'b0;
	tx_dma_en = 1'b0;
	uc_stat_set_d = 1'b0;
	rx_ack_to_clr_d = 1'b1;
	int_seqerr_set_d = 1'b0;

	case(state)	// synopsys full_case parallel_case
	   IDLE:
		   begin
// synopsys translate_off
`ifdef USBF_VERBOSE_DEBUG
		$display("PE: Entered state IDLE (%t)", $time);
`endif
`ifdef USBF_DEBUG
		if(rst & match_r & !pid_SOF)
		begin
		if(match_r === 1'bx)	$display("ERROR: IDLE: match_r is unknown. (%t)", $time);
		if(pid_SOF === 1'bx)	$display("ERROR: IDLE: pid_SOF is unknown. (%t)", $time);
		if(CTRL_ep === 1'bx)	$display("ERROR: IDLE: CTRL_ep is unknown. (%t)", $time);
		if(pid_IN === 1'bx)	$display("ERROR: IDLE: pid_IN is unknown. (%t)", $time);
		if(pid_OUT === 1'bx)	$display("ERROR: IDLE: pid_OUT is unknown. (%t)", $time);
		if(pid_SETUP === 1'bx)	$display("ERROR: IDLE: pid_SETUP is unknown. (%t)", $time);
		if(pid_PING === 1'bx)	$display("ERROR: IDLE: pid_PING is unknown. (%t)", $time);
		if(IN_ep === 1'bx)	$display("ERROR: IDLE: IN_ep is unknown. (%t)", $time);
		if(OUT_ep === 1'bx)	$display("ERROR: IDLE: OUT_ep is unknown. (%t)", $time);
		end
`endif
// synopsys translate_on

			if(match_r & !pid_SOF)
			   begin
				if(IN_ep | (CTRL_ep & pid_IN))
				   begin
					if(txfr_int & ep_empty)
					   begin
						token_pid_sel_d = NACK;
						send_token_d = 1'b1;
						next_state = TOKEN;
					   end
					else
					   begin
						tx_dma_en = 1'b1;
						next_state = IN;
					   end
				   end
				else
				if(OUT_ep | (CTRL_ep & (pid_OUT | pid_SETUP)))
				   begin
					rx_dma_en = 1'b1;
					next_state = OUT;
				   end
			   end
		   end

	   TOKEN:
		   begin
// synopsys translate_off
`ifdef USBF_VERBOSE_DEBUG
		$display("PE: Entered state TOKEN (%t)", $time);
`endif
// synopsys translate_on
			next_state = IDLE;
		   end

	   IN:
		   begin
// synopsys translate_off
`ifdef USBF_VERBOSE_DEBUG
		$display("PE: Entered state IN (%t)", $time);
`endif
`ifdef USBF_DEBUG
		if(idma_done === 1'bx)	$display("ERROR: IN: idma_done is unknown. (%t)", $time);
		if(txfr_iso === 1'bx)	$display("ERROR: IN: txfr_iso is unknown. (%t)", $time);
`endif
// synopsys translate_on
			rx_ack_to_clr_d = 1'b0;
			if(idma_done)
			   begin
				if(txfr_iso)	next_state = UPDATE;
				else		next_state = IN2;
			   end

		   end
	   IN2:
		   begin
// synopsys translate_off
`ifdef USBF_VERBOSE_DEBUG
		$display("PE: Entered state IN2 (%t)", $time);
`endif
`ifdef USBF_DEBUG
		if(rx_ack_to === 1'bx)	$display("ERROR: IN2: rx_ack_to is unknown. (%t)", $time);
		if(token_valid === 1'bx)$display("ERROR: IN2: token_valid is unknown. (%t)", $time);
		if(pid_ACK === 1'bx)	$display("ERROR: IN2: pid_ACK is unknown. (%t)", $time);
`endif
// synopsys translate_on
			rx_ack_to_clr_d = 1'b0;
			// Wait for ACK from HOST or Timeout
			if(rx_ack_to)	next_state = IDLE;
			else
			if(token_valid & pid_ACK)
			   begin
				next_state = UPDATE;
			   end
		   end

	   OUT:
		   begin
// synopsys translate_off
`ifdef USBF_VERBOSE_DEBUG
		$display("PE: Entered state OUT (%t)", $time);
`endif
`ifdef USBF_DEBUG
		if(tx_data_to === 1'bx)	$display("ERROR: OUT: tx_data_to is unknown. (%t)", $time);
		if(crc16_err === 1'bx)	$display("ERROR: OUT: crc16_err is unknown. (%t)", $time);
		if(abort === 1'bx)	$display("ERROR: OUT: abort is unknown. (%t)", $time);
		if(rx_data_done === 1'bx)$display("ERROR: OUT: rx_data_done is unknown. (%t)", $time);
		if(txfr_iso === 1'bx)	$display("ERROR: OUT: txfr_iso is unknown. (%t)", $time);
		if(pid_seq_err === 1'bx)$display("ERROR: OUT: rx_data_done is unknown. (%t)", $time);
`endif
// synopsys translate_on
			if(tx_data_to | crc16_err | abort )
				next_state = IDLE;
			else
			if(rx_data_done)
			   begin		// Send Ack
				if(txfr_iso)
				   begin
					if(pid_seq_err)		int_seqerr_set_d = 1'b1;
					next_state = UPDATEW;
				   end
				else		next_state = OUT2A;
			   end
		   end

	   OUT2B:
		   begin	// This is a delay State to NACK to small or to
				// large packets. this state could be skipped
// synopsys translate_off
`ifdef USBF_VERBOSE_DEBUG
		$display("PE: Entered state OUT2B (%t)", $time);
`endif
`ifdef USBF_DEBUG
		if(abort === 1'bx)	$display("ERROR: OUT2A: abort is unknown. (%t)", $time);
`endif
// synopsys translate_on
			if(abort)	next_state = IDLE;
			else		next_state = OUT2B;
		   end
	   OUT2A:
		   begin	// Send ACK/NACK/NYET
// synopsys translate_off
`ifdef USBF_VERBOSE_DEBUG
		$display("PE: Entered state OUT2A (%t)", $time);
`endif
`ifdef USBF_DEBUG
		if(abort === 1'bx)	$display("ERROR: OUT2A: abort is unknown. (%t)", $time);
		if(pid_seq_err === 1'bx)$display("ERROR: OUT2A: rx_data_done is unknown. (%t)", $time);
`endif
// synopsys translate_on
			if(abort)	next_state = IDLE;
			else

			if(send_stall_r)
			   begin
				token_pid_sel_d = STALL;
				send_token_d = 1'b1;
				next_state = IDLE;
			   end
			else
			if(ep_full)
			   begin
				token_pid_sel_d = NACK;
				send_token_d = 1'b1;
				next_state = IDLE;
			   end
			else
			   begin
				token_pid_sel_d = ACK;
				send_token_d = 1'b1;
				if(pid_seq_err)	next_state = IDLE;
				else		next_state = UPDATE;
			   end
		   end

	   UPDATEW:
		   begin
// synopsys translate_off
`ifdef USBF_VERBOSE_DEBUG
		$display("PE: Entered state UPDATEW (%t)", $time);
`endif
// synopsys translate_on
			next_state = UPDATE;
		   end

	   UPDATE:
		   begin
// synopsys translate_off
`ifdef USBF_VERBOSE_DEBUG
		$display("PE: Entered state UPDATE (%t)", $time);
`endif
// synopsys translate_on
			uc_stat_set_d = 1'b1;
			next_state = IDLE;
		   end
	endcase
   end

endmodule

