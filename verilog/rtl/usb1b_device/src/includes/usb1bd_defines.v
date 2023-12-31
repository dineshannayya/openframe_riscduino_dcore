/////////////////////////////////////////////////////////////////////
////                                                             ////
////  USB 1.1 function defines file                              ////
////                                                             ////
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

//`define USBF_DEBUG
//`define USBF_VERBOSE_DEBUG

// Enable or disable Block Frames
//`define USB1_BF_ENABLE

/////////////////////////////////////////////////////////////////////
//
// Items below this point should NOT be modified by the end user
// UNLESS you know exactly what you are doing !
// Modify at you own risk !!!
//
/////////////////////////////////////////////////////////////////////


// Endpoint Configuration Constants
`define USB1BD_IN	14'b00_001_000000000
`define USB1BD_OUT	14'b00_010_000000000
`define USB1BD_CTRL	14'b10_100_000000000
`define USB1BD_ISO	14'b01_000_000000000
`define USB1BD_BULK	14'b10_000_000000000
`define USB1BD_INT	14'b00_000_000000000

// PID Encodings
`define USB1BD_T_PID_OUT	4'b0001
`define USB1BD_T_PID_IN		4'b1001
`define USB1BD_T_PID_SOF	4'b0101
`define USB1BD_T_PID_SETUP	4'b1101
`define USB1BD_T_PID_DATA0	4'b0011
`define USB1BD_T_PID_DATA1	4'b1011
`define USB1BD_T_PID_DATA2	4'b0111
`define USB1BD_T_PID_MDATA	4'b1111
`define USB1BD_T_PID_ACK	4'b0010
`define USB1BD_T_PID_NACK	4'b1010
`define USB1BD_T_PID_STALL	4'b1110
`define USB1BD_T_PID_NYET	4'b0110
`define USB1BD_T_PID_PRE	4'b1100
`define USB1BD_T_PID_ERR	4'b1100
`define USB1BD_T_PID_SPLIT	4'b1000
`define USB1BD_T_PID_PING	4'b0100
`define USB1BD_T_PID_RES	4'b0000

// The HMS_DEL is a constant for the "Half Micro Second"
// Clock pulse generator. This constant specifies how many
// Phy clocks there are between two hms_clock pulses. This
// constant plus 2 represents the actual delay.
// Example: For a 60 Mhz (16.667 nS period) Phy Clock, the
// delay must be 30 phy clock: 500ns / 16.667nS = 30 clocks
`define USB1BD_HMS_DEL		5'h16

// After sending Data in response to an IN token from host, the
// host must reply with an ack. The host has 622nS in Full Speed
// mode and 400nS in High Speed mode to reply. RX_ACK_TO_VAL_FS
// and RX_ACK_TO_VAL_HS are the numbers of UTMI clock cycles
// minus 2 for Full and High Speed modes.
//`define USBF_RX_ACK_TO_VAL_FS	8'd36
`define USB1BD_RX_ACK_TO_VAL_FS	8'd200

// After sending a OUT token the host must send a data packet.
// The host has 622nS in Full Speed mode and 400nS in High Speed
// mode to send the data packet.
// TX_DATA_TO_VAL_FS and TX_DATA_TO_VAL_HS are is the numbers of
// UTMI clock cycles minus 2.
//`define USBF_TX_DATA_TO_VAL_FS	8'd36
`define USB1BD_TX_DATA_TO_VAL_FS	8'd200
