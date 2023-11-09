/////////////////////////////////////////////////////////////////////
////                                                             ////
////  Packet Assembler                                           ////
////  Assembles Token and Data USB packets                       ////
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

module usb1bd_pa(	
        input  logic         clk, 
        input  logic         rst_n,

		// UTMI TX I/F
		output logic   [7:0] tx_data, 
        output logic         tx_valid, 
        output logic         tx_valid_last, 
        input  logic         tx_ready,
		output logic         tx_first,

		// Register I/F
		input  logic        cfg_tx_send_token, 
        input  logic [1:0]  cfg_tx_token_pid_sel,
		input  logic        cfg_tx_send_data, 
        input  logic [1:0]  cfg_tx_data_pid_sel,

		// TX FIFO Interface
		input  logic [7:0]  tx_fifo_data, 
        output logic        tx_fifo_re,
		input  logic        tx_fifo_empty,

        // Debug Info
        output logic [3:0]  state
		);



///////////////////////////////////////////////////////////////////
//
// Local Wires and Registers
//

parameter	[3:0]	// synopsys enum state
		IDLE   = 4'b0001,
		DATA   = 4'b0010,
		CRC1   = 4'b0100,
		CRC2   = 4'b1000;

reg	[3:0]	/* synopsys enum state */ next_state;
// synopsys state_vector state

reg		last;

reg	[7:0]	token_pid, data_pid;	// PIDs from selectors
reg	[7:0]	tx_data_d;
reg	[7:0]	tx_data_data;
reg		dsel;
reg		tx_valid_d;
reg		send_token_r;
reg	[7:0]	tx_spec_data;
reg		crc_sel1, crc_sel2;
reg		tx_first_r;
reg		send_data_r;
wire		crc16_clr;
reg	[15:0]	crc16;
wire	[15:0]	crc16_next;
wire	[15:0]	crc16_rev;
reg		crc16_add;
reg		send_data_r2;
reg		tx_valid_r;
reg		tx_valid_r1;

wire		zero_length;

///////////////////////////////////////////////////////////////////
//
// Misc Logic
//
reg		zero_length_r;
assign	zero_length = tx_fifo_empty;

always @(posedge clk or negedge rst_n)
	if(!rst_n)	zero_length_r <= #1 1'b0;
	else
	if(last)	zero_length_r <= #1 1'b0;
	else
	if(crc16_clr)	zero_length_r <= #1 zero_length;

always @(posedge clk)
	tx_valid_r1 <= #1 tx_valid;

always @(posedge clk)
	tx_valid_r <= #1 tx_valid_r1;

always @(posedge clk or negedge rst_n)
	if(!rst_n)	send_token_r <= #1 1'b0;
	else
	if(cfg_tx_send_token)	send_token_r <= #1 1'b1;
	else
	if(tx_ready)	send_token_r <= #1 1'b0;

// PID Select
always @(cfg_tx_token_pid_sel)
	case(cfg_tx_token_pid_sel)		// synopsys full_case parallel_case
	   2'd0: token_pid = {  ~`USB1BD_T_PID_ACK,   `USB1BD_T_PID_ACK};
	   2'd1: token_pid = { ~`USB1BD_T_PID_NACK,  `USB1BD_T_PID_NACK};
	   2'd2: token_pid = {~`USB1BD_T_PID_STALL, `USB1BD_T_PID_STALL};
	   2'd3: token_pid = { ~`USB1BD_T_PID_NYET,  `USB1BD_T_PID_NYET};
	endcase

always @(cfg_tx_data_pid_sel)
	case(cfg_tx_data_pid_sel)		// synopsys full_case parallel_case
	   2'd0: data_pid = { ~`USB1BD_T_PID_DATA0, `USB1BD_T_PID_DATA0};
	   2'd1: data_pid = { ~`USB1BD_T_PID_DATA1, `USB1BD_T_PID_DATA1};
	   2'd2: data_pid = { ~`USB1BD_T_PID_DATA2, `USB1BD_T_PID_DATA2};
	   2'd3: data_pid = { ~`USB1BD_T_PID_MDATA, `USB1BD_T_PID_MDATA};
	endcase

// Data path Muxes

always @(cfg_tx_send_token or send_token_r or token_pid or tx_data_data)
	if(cfg_tx_send_token | send_token_r)	tx_data_d = token_pid;
	else				tx_data_d = tx_data_data;

always @(dsel or tx_fifo_data or tx_spec_data)
	if(dsel)	tx_data_data = tx_spec_data;
	else		tx_data_data = tx_fifo_data;

always @(crc_sel1 or crc_sel2 or data_pid or crc16_rev)
	if(!crc_sel1 & !crc_sel2)	tx_spec_data = data_pid;
	else
	if(crc_sel1)			tx_spec_data = crc16_rev[15:8];	// CRC 1
	else				tx_spec_data = crc16_rev[7:0];	// CRC 2

assign tx_data = tx_data_d;

// TX Valid assignment
assign tx_valid_last = cfg_tx_send_token | last;
assign tx_valid = tx_valid_d;

always @(posedge clk)
	tx_first_r <= #1 cfg_tx_send_token | cfg_tx_send_data;

assign tx_first = (cfg_tx_send_token | cfg_tx_send_data) & ! tx_first_r;

// CRC Logic
always @(posedge clk)
	send_data_r <= #1 cfg_tx_send_data;

always @(posedge clk)
	send_data_r2 <= #1 send_data_r;

assign crc16_clr = cfg_tx_send_data & !send_data_r;

always @(posedge clk)
	crc16_add <= #1 !zero_length_r &
			((send_data_r & !send_data_r2) | (tx_fifo_re & !crc_sel1));

always @(posedge clk)
	if(crc16_clr)		crc16 <= #1 16'hffff;
	else
	if(crc16_add)		crc16 <= #1 crc16_next;

usb1bd_crc16 u1(
	.crc_in (	crc16		),
	.din    (	{tx_fifo_data[0], tx_fifo_data[1],
		         tx_fifo_data[2], tx_fifo_data[3],
		         tx_fifo_data[4], tx_fifo_data[5],
		         tx_fifo_data[6], tx_fifo_data[7]}	),
	.crc_out(	crc16_next		) );

assign crc16_rev[15] = ~crc16[8];
assign crc16_rev[14] = ~crc16[9];
assign crc16_rev[13] = ~crc16[10];
assign crc16_rev[12] = ~crc16[11];
assign crc16_rev[11] = ~crc16[12];
assign crc16_rev[10] = ~crc16[13];
assign crc16_rev[9]  = ~crc16[14];
assign crc16_rev[8]  = ~crc16[15];
assign crc16_rev[7]  = ~crc16[0];
assign crc16_rev[6]  = ~crc16[1];
assign crc16_rev[5]  = ~crc16[2];
assign crc16_rev[4]  = ~crc16[3];
assign crc16_rev[3]  = ~crc16[4];
assign crc16_rev[2]  = ~crc16[5];
assign crc16_rev[1]  = ~crc16[6];
assign crc16_rev[0]  = ~crc16[7];

///////////////////////////////////////////////////////////////////
//
// Transmit/Encode state machine
//

always @(posedge clk or negedge rst_n)
	if(!rst_n)	state <= #1 IDLE;
	else		state <= #1 next_state;

always @(state or cfg_tx_send_data or tx_ready or tx_valid_r or zero_length)
   begin
	next_state = state;	// Default don't change current state
	tx_valid_d = 1'b0;
	dsel = 1'b0;
	tx_fifo_re = 1'b0;
	last = 1'b0;
	crc_sel1 = 1'b0;
	crc_sel2 = 1'b0;
	case(state)		// synopsys full_case parallel_case
	   IDLE:
		   begin
			if(zero_length & cfg_tx_send_data)
			   begin
				tx_valid_d = 1'b1;
				dsel = 1'b1;
				next_state = CRC1;
			   end
			else
			if(cfg_tx_send_data)		// Send DATA packet
			   begin
				tx_valid_d = 1'b1;
				dsel = 1'b1;
				next_state = DATA;
			   end
		   end
	   DATA:
		   begin
			if(tx_ready & tx_valid_r)
				tx_fifo_re = 1'b1;

			tx_valid_d = 1'b1;
			if(!cfg_tx_send_data & tx_ready & tx_valid_r)
			   begin
				dsel = 1'b1;
				crc_sel1 = 1'b1;
				next_state = CRC1;
			   end
		   end
	   CRC1:
		   begin
			dsel = 1'b1;
			tx_valid_d = 1'b1;
			if(tx_ready)
			   begin
				last = 1'b1;
				crc_sel2 = 1'b1;
				next_state = CRC2;
			   end
			else
			   begin
				tx_valid_d = 1'b1;
				crc_sel1 = 1'b1;
			   end

		   end
	   CRC2:
		   begin
			dsel = 1'b1;
			crc_sel2 = 1'b1;
			if(tx_ready)
			   begin
				next_state = IDLE;
			   end
			else
			   begin
				last = 1'b1;
			   end

		   end
	endcase
   end

endmodule

