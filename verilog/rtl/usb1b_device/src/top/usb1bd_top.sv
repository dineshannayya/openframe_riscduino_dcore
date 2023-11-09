//////////////////////////////////////////////////////////////////////
////                                                              ////
////                                                              ////
////  Description                                                 ////
////  USB Basic Device level integration.                         ////
////     Following modules are integrated                         ////
////         1. usb1_phy                                          ////
////         2. usb1_core                                         ////
////         3. usb register i/f                                  ////
////         4. app clk to usb clk sync                           ////
////                                                              ////
////  To Do:                                                      ////
////    nothing                                                   ////
////                                                              ////
////  Author(s):                                                  ////
////      - Dinesh Annayya, dinesh.annayya@gmail.com              ////
////  Revision :                                                  //// 
////    0.1 - 28th Oct 2023, Dinesh A                             ////
////          initial version picked by                           ////
////          http://www.opencores.org/projects/usb1_funct        ////
////    0.2 - 30th Oct 2023, Dinesh A                             ////
////          Reduced the hardware logic around usb device and    ////
////          made it more software driven                        ////
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


module usb1bd_top(
        input logic           usb_clk, 
        input logic           app_clk, 
        input logic           arst_n,

        // Transciever Interface
        output logic          usb_txoe , // USB TX OEN, Output driven at txoe=0
        output logic          usb_txdp ,
        output logic          usb_txdn ,

        input logic           usb_rxdp ,
        input logic           usb_rxdn ,

		// Register Interface

		input logic           app_reg_req,
		input logic [3:0]     app_reg_addr,
		input logic           app_reg_we,
        input logic [3:0]     app_reg_be,
		input logic [31:0]    app_reg_wdata,

		output logic  [31:0]  app_reg_rdata,
		output logic          app_reg_ack,

        output logic          usb_irq

        );      

///////////////////////////////////////////////////////////////////
// Local Wires and Registers
///////////////////////////////////////////////////////////////////
//------------------------------------
// UTMI Interface
// -----------------------------------
wire    [7:0]   utmi_tx_data          ;
wire            utmi_tx_valid         ;
wire            utmi_tx_ready         ;

wire    [7:0]   utmi_rx_data          ;
wire            utmi_rx_valid         ;
wire            utmi_rx_active        ;
wire            utmi_rx_error         ;

wire    [1:0]   utmi_line_state       ;
wire            usb_rst               ;
wire            cfg_phy_tx_mode;


// Config Register
wire [7:0]    cfg_max_hms             ;
wire          cfg_tx_send_token       ; 
wire [1:0]    cfg_tx_token_pid_sel    ;
wire          cfg_tx_send_data        ; 
wire [1:0]    cfg_tx_data_pid_sel     ;

wire          rx_token_valid          ;
wire [3:0]    rx_ep_sel               ; // Endpoint Number Input
wire [6:0]    rx_token_fadr           ; // Function address from token
wire          x_busy                  ; // Indicates USB is busy

// Misc
wire  [31:0]   frm_nat                ;
wire           pid_cs_err             ; // pid checksum error
wire           crc5_err               ; // crc5 error
wire           crc16_err              ; // Data packet CRC 16 error

// TX FIFO
wire  [7:0]    tx_fifo_wdata          ;
wire           tx_fifo_we             ;
wire           tx_fifo_full           ;
wire           tx_fifo_empty          ;
wire           tx_fifo_oflow          ;
wire [7:0]     tx_fifo_rdata          ;
wire           tx_fifo_re             ;
wire [4:0]     tx_fifo_occ            ;


// RX FIFO

wire [7:0]     rx_fifo_wdata          ;
wire           rx_fifo_we             ;
wire           rx_fifo_full           ;
wire           rx_fifo_uflow          ;
wire           rx_fifo_empty          ;
wire [7:0]     rx_fifo_rdata          ;
wire           rx_fifo_re             ;
wire [4:0]     rx_fifo_occ            ;


// Reg Bus Interface Signal
wire           usb_reg_cs             ;
wire           usb_reg_wr             ;
wire [3:0]     usb_reg_addr           ;
wire [31:0]    usb_reg_wdata          ;
wire [3:0]     usb_reg_be             ;

// Outputs
wire [31:0]    usb_reg_rdata          ;
wire           usb_reg_ack            ;

// USB Traceiver interface
wire          usb_rxd; 

assign  usb_rxd =  usb_rxdp;


// Reset Sync - Application clock
reset_sync  u_app_rst (
	      .scan_mode  (1'b0         ),
          .dclk       (app_clk      ), // Destination clock domain
	      .arst_n     (arst_n       ), // active low async reset
          .srst_n     (app_rst_ssn  )
          );

// Reset Sync - USB clock
reset_sync  u_usb_rst (
	      .scan_mode  (1'b0         ),
          .dclk       (usb_clk      ), // Destination clock domain
	      .arst_n     (arst_n       ), // active low async reset
          .srst_n     (usb_rst_ssn  )
          );

    
usb1bd_phy u_usb_phy(
                    .clk                ( usb_clk           ),
                    .rstn               ( usb_rst_ssn       ),  
                    .phy_tx_mode        ( cfg_phy_tx_mode   ),
                    .usb_rst            ( usb_rst           ),

        // Transceiver Interface
                    .rxd                ( usb_rxd           ),
                    .rxdp               ( usb_rxdp          ),
                    .rxdn               ( usb_rxdn          ),
                    .txdp               ( usb_txdp          ),
                    .txdn               ( usb_txdn          ),
                    .txoe               ( usb_txoe          ),

        // UTMI Interface
                    .DataIn_o           ( utmi_rx_data      ),
                    .RxValid_o          ( utmi_rx_valid     ),
                    .RxActive_o         ( utmi_rx_active    ),
                    .RxError_o          ( utmi_rx_error     ),

                    .DataOut_i          ( utmi_tx_data      ),
                    .TxValid_i          ( utmi_tx_valid     ),
                    .TxReady_o          ( utmi_tx_ready     ),
                    .LineState_o        ( utmi_line_state   )
        );


usb1bd_core  u_usb_core(
                    .clk_i              ( usb_clk           ), 
                    .rst_i              ( usb_rst_ssn       ),
                    .srst_n             ( usb_srst_n        ),

                 // USB Misc
                    .phy_tx_mode        ( cfg_phy_tx_mode   ), 
                    .usb_rst            ( usb_rst           ), 

                 // UTMI Interface
                    .RxDataIn           ( utmi_rx_data      ),
                    .RxValid            ( utmi_rx_valid     ),
                    .RxActive           ( utmi_rx_active    ),
                    .RxError            ( utmi_rx_error     ),

                    .TxDataOut          ( utmi_tx_data      ),
                    .TxValid            ( utmi_tx_valid     ),
                    .TxReady            ( utmi_tx_ready     ),
                    .LineState          ( utmi_line_state   ),


       // Config Register
                    .cfg_max_hms         (cfg_max_hms        ) ,
	                .cfg_tx_send_token   (cfg_tx_send_token  ) , 
                    .cfg_tx_token_pid_sel(cfg_tx_token_pid_sel),
	                .cfg_tx_send_data    (cfg_tx_send_data   ) , 
                    .cfg_tx_data_pid_sel (cfg_tx_data_pid_sel) ,


	                .rx_token_valid      (rx_token_valid     ) ,
                    .rx_token_fadr       (rx_token_fadr      ),
	                .rx_ep_sel           (rx_ep_sel          ) , // Endpoint Number Input
	                .x_busy              (x_busy             ) , // Indicates USB is busy

	   // Misc
	                .frm_nat             (frm_nat            ) ,
	                .pid_cs_err          (pid_cs_err         ) , // pid checksum error
	                .crc5_err            (crc5_err           ) , // crc5 error
                    .crc16_err           (crc16_err          ) , // Data packet CRC 16 error

	  // TX FIFO
                    .tx_fifo_data        (tx_fifo_rdata      ) ,
                    .tx_fifo_re          (tx_fifo_re         ) ,
	                .tx_fifo_empty       (tx_fifo_empty      ) ,

	  // RX FIFO
                    .rx_fifo_data        (rx_fifo_wdata      ) ,
                    .rx_fifo_dvalid      (rx_fifo_we         ) ,
                    .rx_fifo_ddone       (rx_fifo_ddone      ) 

        );      



usb1bd_reg u_reg  (

             .mclk                   (usb_clk                ),
             .reset_n                (usb_rst_ssn            ),

        // Reg Bus Interface Signal
             .reg_cs                 (usb_reg_cs             ),
             .reg_wr                 (usb_reg_wr             ),
             .reg_addr               (usb_reg_addr           ),
             .reg_wdata              (usb_reg_wdata          ),
             .reg_be                 (usb_reg_be             ),

            // Outputs
             .reg_rdata              (usb_reg_rdata          ),
             .reg_ack                (usb_reg_ack            ),


       // Config Register
             .cfg_usb_enb            (cfg_usb_enb            ),
             .usb_srst_n             (usb_srst_n             ),
             .cfg_phy_tx_mode        (cfg_phy_tx_mode        ),
             .cfg_max_hms            (cfg_max_hms            ),
	         .cfg_tx_send_token      (cfg_tx_send_token      ), 
             .cfg_tx_token_pid_sel   (cfg_tx_token_pid_sel   ),
	         .cfg_tx_send_data       (cfg_tx_send_data       ), 
             .cfg_tx_data_pid_sel    (cfg_tx_data_pid_sel    ),


	         .rx_token_valid         (rx_token_valid         ),
             .rx_fifo_ddone          (rx_fifo_ddone          ),
	         .rx_token_fadr          (rx_token_fadr          ),
	         .rx_ep_sel              (rx_ep_sel              ), 
	         .x_busy                 (x_busy                 ), 

	   // Misc
             .usb_rst                (usb_rst                ),
	         .frm_nat                (frm_nat                ),
	         .pid_cs_err             (pid_cs_err             ), 
	         .crc5_err               (crc5_err               ), 
             .crc16_err              (crc16_err              ), 


         // Uart Tx fifo interface
             .tx_fifo_wr_en          (tx_fifo_we             ),
             .tx_fifo_data           (tx_fifo_wdata          ),
             .tx_fifo_occ            (tx_fifo_occ            ),
             .tx_fifo_full           (tx_fifo_full           ),
             .tx_fifo_empty          (tx_fifo_empty          ),
             .tx_fifo_oflow          (tx_fifo_oflow          ),

         // Uart Rx fifo interface
             .rx_fifo_rd_en          (rx_fifo_re             ),
             .rx_fifo_data           (rx_fifo_rdata          ),
             .rx_fifo_occ            (rx_fifo_occ            ),
             .rx_fifo_full           (rx_fifo_full           ),
             .rx_fifo_empty          (rx_fifo_empty          ),
             .rx_fifo_uflow          (rx_fifo_uflow          ),

             .usb_irq                (usb_irq                ) 

        );



  // RX FIFO <UTMI Rx => RXFIFO >
  sync_fifo_occ #( .DP(16), .WD(8), .AW(4)) i_rx_fifo (
    .reset_n     (usb_rst_ssn          ),
    .clk         (usb_clk              ),
    .sreset_n    (usb_srst_n           ),
    .wr_data     (rx_fifo_wdata        ),
    .wr_en       (rx_fifo_we           ),
    .full        (rx_fifo_full         ),
    .uflow       (rx_fifo_uflow        ),
    .empty       (rx_fifo_empty        ),
    .rd_data     (rx_fifo_rdata        ),
    .rd_en       (rx_fifo_re           ),
    .occupancy   (rx_fifo_occ          )
  );


  // TX FIFO TXFIFO  => UTMI Tx
  sync_fifo_occ #( .DP(16), .WD(8), .AW(4)) i_tx_fifo (
    .reset_n     (usb_rst_ssn          ),
    .clk         (usb_clk              ),
    .sreset_n    (usb_srst_n           ),
    .wr_data     (tx_fifo_wdata        ),
    .wr_en       (tx_fifo_we           ),
    .full        (tx_fifo_full         ),
    .empty       (tx_fifo_empty        ),
    .oflow       (tx_fifo_oflow        ),
    .rd_data     (tx_fifo_rdata        ),
    .rd_en       (tx_fifo_re           ),
    .occupancy   (tx_fifo_occ          )
  );



//----------------------------------------------------
//  Application <=> USB clock domain change over
// Async App clock to Uart clock handling
//----------------------------------------------------

async_reg_bus #(.AW(4), .DW(32),.BEW(4))
          u_async_reg_bus (
    // Initiator declartion
          .in_clk                     (app_clk            ),
          .in_reset_n                 (app_rst_ssn        ),
       // Reg Bus Master
          // outputs
          .in_reg_rdata               (app_reg_rdata      ),
          .in_reg_ack                 (app_reg_ack        ),
          .in_reg_timeout             (),

          // Inputs
          .in_reg_cs                  (app_reg_req        ),
          .in_reg_addr                (app_reg_addr       ),
          .in_reg_wdata               (app_reg_wdata      ),
          .in_reg_wr                  (app_reg_wr         ),
          .in_reg_be                  (app_reg_be         ), 

    // Target Declaration
          .out_clk                    (usb_clk            ),
          .out_reset_n                (usb_rst_ssn        ),
      // Reg Bus Slave
          // output
          .out_reg_cs                 (usb_reg_cs         ),
          .out_reg_addr               (usb_reg_addr       ),
          .out_reg_wdata              (usb_reg_wdata      ),
          .out_reg_wr                 (usb_reg_wr         ),
          .out_reg_be                 (usb_reg_be         ),

          // Inputs
          .out_reg_rdata              (usb_reg_rdata      ),
          .out_reg_ack                (usb_reg_ack        )
   );






endmodule
