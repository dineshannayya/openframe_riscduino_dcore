// SPDX-FileCopyrightText: 2020 Efabless Corporation
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

`default_nettype none
/*
 *-------------------------------------------------------------
 *
 * openframe_project_wrapper
 *
 * This wrapper enumerates all of the pins available to the
 * user for the user openframe project.
 *
 * Written by Tim Edwards
 * March 27, 2023
 * Efabless Corporation
 *
 *-------------------------------------------------------------
 */
`define OPENFRAME_IO_PADS 44
`include "user_params.svh"

module openframe_project_wrapper (
`ifdef USE_POWER_PINS
    inout vdda,		// User area 0 3.3V supply
    inout vdda1,	// User area 1 3.3V supply
    inout vdda2,	// User area 2 3.3V supply
    inout vssa,		// User area 0 analog ground
    inout vssa1,	// User area 1 analog ground
    inout vssa2,	// User area 2 analog ground
    inout vccd,		// Common 1.8V supply
    inout vccd1,	// User area 1 1.8V supply
    inout vccd2,	// User area 2 1.8v supply
    inout vssd,		// Common digital ground
    inout vssd1,	// User area 1 digital ground
    inout vssd2,	// User area 2 digital ground
`endif

    /* Signals exported from the frame area to the user project */
    /* The user may elect to use any of these inputs.		*/

    input	 porb_h,	// power-on reset, sense inverted, 3.3V domain
    input	 porb_l,	// power-on reset, sense inverted, 1.8V domain
    input	 por_l,		// power-on reset, noninverted, 1.8V domain
    input	 resetb_h,	// master reset, sense inverted, 3.3V domain
    input	 resetb_l,	// master reset, sense inverted, 1.8V domain
    input [31:0] mask_rev,	// 32-bit user ID, 1.8V domain

    /* GPIOs.  There are 44 GPIOs (19 left, 19 right, 6 bottom). */
    /* These must be configured appropriately by the user project. */

    /* Basic bidirectional I/O.  Input gpio_in_h is in the 3.3V domain;  all
     * others are in the 1.8v domain.  OEB is output enable, sense inverted.
     */
    input  [`OPENFRAME_IO_PADS-1:0] gpio_in,
    input  [`OPENFRAME_IO_PADS-1:0] gpio_in_h,
    output [`OPENFRAME_IO_PADS-1:0] gpio_out,
    output [`OPENFRAME_IO_PADS-1:0] gpio_oeb,
    output [`OPENFRAME_IO_PADS-1:0] gpio_inp_dis,	// a.k.a. ieb

    /* Pad configuration.  These signals are usually static values.
     * See the documentation for the sky130_fd_io__gpiov2 cell signals
     * and their use.
     */
    output [`OPENFRAME_IO_PADS-1:0] gpio_ib_mode_sel,
    output [`OPENFRAME_IO_PADS-1:0] gpio_vtrip_sel,
    output [`OPENFRAME_IO_PADS-1:0] gpio_slow_sel,
    output [`OPENFRAME_IO_PADS-1:0] gpio_holdover,
    output [`OPENFRAME_IO_PADS-1:0] gpio_analog_en,
    output [`OPENFRAME_IO_PADS-1:0] gpio_analog_sel,
    output [`OPENFRAME_IO_PADS-1:0] gpio_analog_pol,
    output [`OPENFRAME_IO_PADS-1:0] gpio_dm2,
    output [`OPENFRAME_IO_PADS-1:0] gpio_dm1,
    output [`OPENFRAME_IO_PADS-1:0] gpio_dm0,

    /* These signals correct directly to the pad.  Pads using analog I/O
     * connections should keep the digital input and output buffers turned
     * off.  Both signals connect to the same pad.  The "noesd" signal
     * is a direct connection to the pad;  the other signal connects through
     * a series resistor which gives it minimal ESD protection.  Both signals
     * have basic over- and under-voltage protection at the pad.  These
     * signals may be expected to attenuate heavily above 50MHz.
     */
    inout  [`OPENFRAME_IO_PADS-1:0] analog_io,
    inout  [`OPENFRAME_IO_PADS-1:0] analog_noesd_io,

    /* These signals are constant one and zero in the 1.8V domain, one for
     * each GPIO pad, and can be looped back to the control signals on the
     * same GPIO pad to set a static configuration at power-up.
     */
    input  [`OPENFRAME_IO_PADS-1:0] gpio_loopback_one,
    input  [`OPENFRAME_IO_PADS-1:0] gpio_loopback_zero
);


parameter     WB_WIDTH      = 32; // WB ADDRESS/DARA WIDTH

parameter OPENFRAME_IO_RIGHT_PADS  = 15;  // (0 to 14)
parameter OPENFRAME_IO_TOP_PADS    = 24;  // (23 to 15)
parameter OPENFRAME_IO_LEFT_PADS   = 38;  // (37 to 24)
parameter OPENFRAME_IO_BOTTOM_PADS = 44;  // (43 to 38)

//---------------------------------------------------------------------
// Wishbone Risc V Dcache Memory Interface
//---------------------------------------------------------------------
wire                           wbd_riscv_dcache_stb_i                 ; // strobe/request
wire   [WB_WIDTH-1:0]          wbd_riscv_dcache_adr_i                 ; // address
wire                           wbd_riscv_dcache_we_i                  ; // write
wire   [WB_WIDTH-1:0]          wbd_riscv_dcache_dat_i                 ; // data output
wire   [3:0]                   wbd_riscv_dcache_sel_i                 ; // byte enable
wire   [9:0]                   wbd_riscv_dcache_bl_i                  ; // burst length
wire                           wbd_riscv_dcache_bry_i                 ; // burst ready
wire   [WB_WIDTH-1:0]          wbd_riscv_dcache_dat_o                 ; // data input
wire                           wbd_riscv_dcache_ack_o                 ; // acknowlegement
wire                           wbd_riscv_dcache_lack_o                ; // last burst acknowlegement
wire                           wbd_riscv_dcache_err_o                 ; // error

// CACHE SRAM Memory I/F
wire                           dcache_mem_clk0                        ; // CLK
wire                           dcache_mem_csb0                        ; // CS#
wire                           dcache_mem_web0                        ; // WE#
wire   [8:0]                   dcache_mem_addr0                       ; // Address
wire   [3:0]                   dcache_mem_wmask0                      ; // WMASK#
wire   [31:0]                  dcache_mem_din0                        ; // Write Data
wire   [31:0]                  dcache_mem_dout0                       ; // Read Data
   
// SRAM-0 PORT-1, IMEM I/F
wire                           dcache_mem_clk1                        ; // CLK
wire                           dcache_mem_csb1                        ; // CS#
wire  [8:0]                    dcache_mem_addr1                       ; // Address
wire  [31:0]                   dcache_mem_dout1                       ; // Read Data
//---------------------------------------------------------------------
// Wishbone Risc V Icache Memory Interface
//---------------------------------------------------------------------
wire                           wbd_riscv_icache_stb_i                 ; // strobe/request
wire   [WB_WIDTH-1:0]          wbd_riscv_icache_adr_i                 ; // address
wire                           wbd_riscv_icache_we_i                  ; // write
wire   [3:0]                   wbd_riscv_icache_sel_i                 ; // byte enable
wire   [9:0]                   wbd_riscv_icache_bl_i                  ; // burst length
wire                           wbd_riscv_icache_bry_i                 ; // burst ready
wire   [WB_WIDTH-1:0]          wbd_riscv_icache_dat_o                 ; // data input
wire                           wbd_riscv_icache_ack_o                 ; // acknowlegement
wire                           wbd_riscv_icache_lack_o                ; // last burst acknowlegement
wire                           wbd_riscv_icache_err_o                 ; // error

// CACHE SRAM Memory I/F
wire                           icache_mem_clk0                        ; // CLK
wire                           icache_mem_csb0                        ; // CS#
wire                           icache_mem_web0                        ; // WE#
wire   [8:0]                   icache_mem_addr0                       ; // Address
wire   [3:0]                   icache_mem_wmask0                      ; // WMASK#
wire   [31:0]                  icache_mem_din0                        ; // Write Data
// wire   [31:0]               icache_mem_dout0                       ; // Read Data
   
// SRAM-0 PORT-1, IMEM I/F
wire                           icache_mem_clk1                        ; // CLK
wire                           icache_mem_csb1                        ; // CS#
wire  [8:0]                    icache_mem_addr1                       ; // Address
wire  [31:0]                   icache_mem_dout1                       ; // Read Data

//---------------------------------------------------------------------
// RISC V Wishbone Data Memory Interface
//---------------------------------------------------------------------
wire                           wbd_riscv_dmem_stb_i                   ; // strobe/request
wire   [WB_WIDTH-1:0]          wbd_riscv_dmem_adr_i                   ; // address
wire                           wbd_riscv_dmem_we_i                    ; // write
wire   [WB_WIDTH-1:0]          wbd_riscv_dmem_dat_i                   ; // data output
wire   [3:0]                   wbd_riscv_dmem_sel_i                   ; // byte enable
wire   [2:0]                   wbd_riscv_dmem_bl_i                    ; // byte enable
wire                           wbd_riscv_dmem_bry_i                   ; // burst access ready
wire   [WB_WIDTH-1:0]          wbd_riscv_dmem_dat_o                   ; // data input
wire                           wbd_riscv_dmem_ack_o                   ; // acknowlegement
wire                           wbd_riscv_dmem_lack_o                  ; // acknowlegement
wire                           wbd_riscv_dmem_err_o                   ; // error

//---------------------------------------------------------------------
// WB HOST Interface
//---------------------------------------------------------------------
wire                           wbd_int_cyc_i                          ; // strobe/request
wire                           wbd_int_stb_i                          ; // strobe/request
wire   [WB_WIDTH-1:0]          wbd_int_adr_i                          ; // address
wire                           wbd_int_we_i                           ; // write
wire   [WB_WIDTH-1:0]          wbd_int_dat_i                          ; // data output
wire   [3:0]                   wbd_int_sel_i                          ; // byte enable
wire   [WB_WIDTH-1:0]          wbd_int_dat_o                          ; // data input
wire                           wbd_int_ack_o                          ; // acknowlegement
wire                           wbd_int_err_o                          ; // error
//---------------------------------------------------------------------
//    SPI Master Wishbone Interface
//---------------------------------------------------------------------
wire                           wbd_spim_stb_o                         ; // strobe/request
wire   [WB_WIDTH-1:0]          wbd_spim_adr_o                         ; // address
wire                           wbd_spim_we_o                          ; // write
wire   [WB_WIDTH-1:0]          wbd_spim_dat_o                         ; // data output
wire   [3:0]                   wbd_spim_sel_o                         ; // byte enable
wire   [9:0]                   wbd_spim_bl_o                          ; // Burst count
wire                           wbd_spim_bry_o                         ; // Busrt Ready
wire                           wbd_spim_cyc_o                         ;
wire   [WB_WIDTH-1:0]          wbd_spim_dat_i                         ; // data input
wire                           wbd_spim_ack_i                         ; // acknowlegement
wire                           wbd_spim_lack_i                        ; // Last acknowlegement
wire                           wbd_spim_err_i                         ; // error

//---------------------------------------------------------------------
//    SPI Master Wishbone Interface
//---------------------------------------------------------------------
wire                           wbd_adc_stb_o                          ;
wire [7:0]                     wbd_adc_adr_o                          ;
wire                           wbd_adc_we_o                           ; // 1 - Write, 0 - Read
wire [WB_WIDTH-1:0]            wbd_adc_dat_o                          ;
wire [WB_WIDTH/8-1:0]          wbd_adc_sel_o                          ; // Byte enable
wire                           wbd_adc_cyc_o                          ;
wire  [2:0]                    wbd_adc_cti_o                          ;
wire  [WB_WIDTH-1:0]           wbd_adc_dat_i                          ;
wire                           wbd_adc_ack_i                          ;

//---------------------------------------------------------------------
//    Global Register Wishbone Interface
//---------------------------------------------------------------------
wire                           wbd_pinmux_stb_o                       ; // strobe/request
wire   [10:0]                  wbd_pinmux_adr_o                       ; // address
wire                           wbd_pinmux_we_o                        ; // write
wire   [WB_WIDTH-1:0]          wbd_pinmux_dat_o                       ; // data output
wire   [3:0]                   wbd_pinmux_sel_o                       ; // byte enable
wire                           wbd_pinmux_cyc_o                       ;
wire   [WB_WIDTH-1:0]          wbd_pinmux_dat_i                       ; // data input
wire                           wbd_pinmux_ack_i                       ; // acknowlegement
wire                           wbd_pinmux_err_i                       ; // error

//---------------------------------------------------------------------
//    Global Register Wishbone Interface
//---------------------------------------------------------------------
wire                           wbd_uart_stb_o                         ; // strobe/request
wire   [8:0]                   wbd_uart_adr_o                         ; // address
wire                           wbd_uart_we_o                          ; // write
wire   [31:0]                  wbd_uart_dat_o                         ; // data output
wire   [3:0]                   wbd_uart_sel_o                         ; // byte enable
wire                           wbd_uart_cyc_o                         ;
wire   [31:0]                  wbd_uart_dat_i                         ; // data input
wire                           wbd_uart_ack_i                         ; // acknowlegement
wire                           wbd_uart_err_i                         ;  // error


//----------------------------------------------------
//  CPU Configuration
//----------------------------------------------------
wire                           cpu_intf_rst_n                         ;
wire  [3:0]                    cpu_core_rst_n                         ;
wire                           qspim_rst_n                            ;
wire                           sspim_rst_n                            ;
wire [1:0]                     uart_rst_n                             ; // uart reset
wire                           i2c_rst_n                              ; // i2c reset
wire                           usb_rst_n                              ; // i2c reset
wire                           bist_rst_n                             ; // i2c reset
wire                           cpu_clk                                ;
wire                           rtc_clk                                ;
wire                           usb_clk                                ;
wire                           wbd_clk_int                            ;
wire                           wbd_clk_wh                             ;

wire                           wbd_clk_spi                            ;
wire                           wbd_clk_pinmux                         ;
wire                           wbd_int_rst_n                          ;
wire                           wbd_pll_rst_n                          ;

wire [31:0]                    irq_lines                              ;
wire                           soft_irq                               ;


wire [7:0]                     cfg_glb_ctrl                           ;
wire [31:0]                    cfg_clk_skew_ctrl1                     ;
wire [31:0]                    cfg_clk_skew_ctrl2                     ;
wire [3:0]                     cfg_wcska_wi                           ; // clock skew adjust for wishbone interconnect
wire [3:0]                     cfg_wcska_wh                           ; // clock skew adjust for web host
wire [3:0]                     cfg_wcska_peri                         ; // clock skew adjust for peripheral

wire [3:0]                     cfg_wcska_riscv                        ; // clock skew adjust for riscv
wire [3:0]                     cfg_wcska_uart                         ; // clock skew adjust for uart
wire [3:0]                     cfg_wcska_qspi                         ; // clock skew adjust for spi
wire [3:0]                     cfg_wcska_pinmux                       ; // clock skew adjust for pinmux
wire [3:0]                     cfg_wcska_qspi_co                      ; // clock skew adjust for global reg

// Bus Repeater Signals  output from Wishbone Interface
wire [3:0]                     cfg_wcska_riscv_rp                      ; // clock skew adjust for riscv
wire [3:0]                     cfg_wcska_uart_rp                       ; // clock skew adjust for uart
wire [3:0]                     cfg_wcska_qspi_rp                       ; // clock skew adjust for spi
wire [3:0]                     cfg_wcska_pinmux_rp                     ; // clock skew adjust for pinmux
wire [3:0]                     cfg_wcska_qspi_co_rp                    ; // clock skew adjust for global reg
wire [3:0]                     cfg_wcska_peri_rp                       ; // clock skew adjust for peripheral 

wire [31:0]                    irq_lines_rp                           ; // Repeater
wire                           soft_irq_rp                            ; // Repeater


// Progammable Clock Skew inserted signals
wire                           wbd_clk_wi_skew                        ; // clock for wishbone interconnect with clock skew
wire                           wbd_clk_riscv_skew                     ; // clock for riscv with clock skew
wire                           wbd_clk_uart_skew                      ; // clock for uart with clock skew
wire                           wbd_clk_spi_skew                       ; // clock for spi with clock skew
wire                           wbd_clk_glbl_skew                      ; // clock for global reg with clock skew
wire                           wbd_clk_wh_skew                        ; // clock for global reg
wire                           wbd_clk_pinmux_skew                    ;
wire                           wbd_clk_peri_skew                      ;

wire                           peri_wbclk                             ;


wire [31:0]                    spi_debug                              ;
wire [31:0]                    pinmux_debug                           ;
wire                           dbg_clk_mon                            ; // clock monitoring port
wire [63:0]                    riscv_debug                            ;

// SFLASH I/F
wire                           sflash_sck                             ;
wire [3:0]                     sflash_ss                              ;
wire [3:0]                     sflash_oen                             ;
wire [3:0]                     sflash_do                              ;
wire [3:0]                     sflash_di                              ;

// SSRAM I/F
//wire                         ssram_sck                              ;
//wire                         ssram_ss                               ;
//wire                         ssram_oen                              ;
//wire [3:0]                   ssram_do                               ;
//wire [3:0]                   ssram_di                               ;

// USB I/F
wire                           usb_dp_o                               ;
wire                           usb_dn_o                               ;
wire                           usb_oen                                ;
wire                           usb_dp_i                               ;
wire                           usb_dn_i                               ;

// UART I/F
wire       [1:0]               uart_txd                               ;
wire       [1:0]               uart_rxd                               ;

// I2CM I/F
wire                           i2cm_clk_o                             ;
wire                           i2cm_clk_i                             ;
wire                           i2cm_clk_oen                           ;
wire                           i2cm_data_oen                          ;
wire                           i2cm_data_o                            ;
wire                           i2cm_data_i                            ;

// SPI MASTER
wire                           spim_sck                               ;
wire                           spim_ss                                ;
wire                           spim_miso                              ;
wire                           spim_mosi                              ;

wire [7:0]                     sar2dac                                ;
wire                           analog_dac_out                         ;
wire                           pulse1m_mclk                           ;
wire                           h_reset_n                              ;

`ifndef SCR1_TCM_MEM
// SRAM-0 PORT-0 - DMEM I/F
wire                           sram0_clk0                             ; // CLK
wire                           sram0_csb0                             ; // CS#
wire                           sram0_web0                             ; // WE#
wire   [8:0]                   sram0_addr0                            ; // Address
wire   [3:0]                   sram0_wmask0                           ; // WMASK#
wire   [31:0]                  sram0_din0                             ; // Write Data
wire   [31:0]                  sram0_dout0                            ; // Read Data

// SRAM-0 PORT-1, IMEM I/F
wire                           sram0_clk1                             ; // CLK
wire                           sram0_csb1                             ; // CS#
wire  [8:0]                    sram0_addr1                            ; // Address
wire  [31:0]                   sram0_dout1                            ; // Read Data

// SRAM-1 PORT-0 - DMEM I/F
wire                           sram1_clk0                             ; // CLK
wire                           sram1_csb0                             ; // CS#
wire                           sram1_web0                             ; // WE#
wire   [8:0]                   sram1_addr0                            ; // Address
wire   [3:0]                   sram1_wmask0                           ; // WMASK#
wire   [31:0]                  sram1_din0                             ; // Write Data
wire   [31:0]                  sram1_dout0                            ; // Read Data

// SRAM-1 PORT-1, IMEM I/F
wire                           sram1_clk1                             ; // CLK
wire                           sram1_csb1                             ; // CS#
wire  [8:0]                    sram1_addr1                            ; // Address
wire  [31:0]                   sram1_dout1                            ; // Read Data

`endif

// SPIM I/F
wire                           sspim_sck                              ; // clock out
wire                           sspim_so                               ; // serial data out
wire                           sspim_si                               ; // serial data in
wire    [3:0]                  sspim_ssn                              ; // cs_n

// SPIS I/F
wire                           sspis_sck                              ; // clock out
wire                           sspis_so                               ; // serial data out
wire                           sspis_si                               ; // serial data in
wire                           sspis_ssn                              ; // cs_n


wire                           usb_intr_o                             ;
wire                           i2cm_intr_o                            ;

wire                           qspim_mclk                             ;
wire                           uart_mclk                              ;
wire                           pinmux_mclk                            ;

wire                           qspim_idle                             ;
wire                           aes_idle                               ;
wire                           fpu_idle                               ;

//------------------------------------------------------------
// AES Integration local decleration
//------------------------------------------------------------
wire                           cpu_clk_aes                            ;
wire                           cpu_clk_aes_skew                       ;
wire [3:0]                     cfg_ccska_aes                          ;
wire [3:0]                     cfg_ccska_aes_rp                       ;
wire                           aes_dmem_req                           ;
wire                           aes_dmem_cmd                           ;
wire [1:0]                     aes_dmem_width                         ;
wire [6:0]                     aes_dmem_addr                          ;
wire [31:0]                    aes_dmem_wdata                         ;
wire                           aes_dmem_req_ack                       ;
wire [31:0]                    aes_dmem_rdata                         ;
wire [1:0]                     aes_dmem_resp                          ;

//------------------------------------------------------------
// FPU Integration local decleration
//------------------------------------------------------------
wire                           cpu_clk_fpu                           ;
wire                           cpu_clk_fpu_skew                       ;
wire [3:0]                     cfg_ccska_fpu                          ;
wire [3:0]                     cfg_ccska_fpu_rp                       ;
wire                           fpu_dmem_req                           ;
wire                           fpu_dmem_cmd                           ;
wire [1:0]                     fpu_dmem_width                         ;
wire [4:0]                     fpu_dmem_addr                          ;
wire [31:0]                    fpu_dmem_wdata                         ;
wire                           fpu_dmem_req_ack                       ;
wire [31:0]                    fpu_dmem_rdata                         ;
wire [1:0]                     fpu_dmem_resp                          ;

//----------------------------------------------------------------
//  UART Master I/F
//  -------------------------------------------------------------
wire                           uartm_rxd                              ;
wire                           uartm_txd                              ;

//----------------------------------------------------------------
//  Digital PLL I/F
//  -------------------------------------------------------------
wire                           cfg_pll_enb                            ; // Enable PLL
wire [4:0]                     cfg_pll_fed_div                        ; // PLL feedback division ratio
wire                           cfg_dco_mode                           ; // Run PLL in DCO mode
wire [25:0]                    cfg_dc_trim                            ; // External trim for DCO mode
wire                           pll_ref_clk                            ; // Input oscillator to match
wire [1:0]                     pll_clk_out                            ; // Two 90 degree clock phases

wire [3:0]                     spi_csn                                ;
wire                           xtal_clk                               ;
wire                           e_reset_n                              ;
wire                           p_reset_n                              ;
wire                           s_reset_n                              ;
wire                           cfg_strap_pad_ctrl                     ;

wire                           e_reset_n_rp                           ;
wire                           p_reset_n_rp                           ;
wire                           s_reset_n_rp                           ;
wire                           cfg_strap_pad_ctrl_rp                  ;
//----------------------------------------------------------------------
// DAC Config
//----------------------------------------------------------------------
wire [7:0]                     cfg_dac0_mux_sel                       ;
wire [7:0]                     cfg_dac1_mux_sel                       ;
wire [7:0]                     cfg_dac2_mux_sel                       ;
wire [7:0]                     cfg_dac3_mux_sel                       ;

//---------------------------------------------------------------------
// Peripheral Reg I/F
//---------------------------------------------------------------------
wire                           reg_peri_cs                            ;
wire                           reg_peri_wr                            ;
wire [10:0]                    reg_peri_addr                          ;
wire [31:0]                    reg_peri_wdata                         ;
wire [3:0]                     reg_peri_be                            ;

wire [31:0]                    reg_peri_rdata                         ;
wire                           reg_peri_ack                           ;

wire                           rtc_intr                               ; // RTC interrupt

//---------------------------------------------------------------------
// IR Receiver
//---------------------------------------------------------------------
wire                           ir_rx                                 ; // IR Receiver Input from pad
wire                           ir_tx                                 ; // IR Transmitter
wire                           ir_intr                               ; // IR Interrupt
`ifdef YCR_DBG_EN
    // -- JTAG I/F
wire                           riscv_trst_n                          ;
wire                           riscv_tck                             ;
wire                           riscv_tms                             ;
wire                           riscv_tdi                             ;
wire                           riscv_tdo                             ;
wire                           riscv_tdo_en                          ;
`endif // YCR_DBG_EN
//---------------------------------------------------------------------
// Strap
//---------------------------------------------------------------------
wire [31:0]                    system_strap                           ;
wire [31:0]                    strap_sticky                           ;

wire [31:0]                    system_strap_rp                        ;
wire [31:0]                    strap_sticky_rp                        ;

wire [1:0]  strap_qspi_flash       = system_strap[`STRAP_QSPI_FLASH];
wire        strap_qspi_sram        = system_strap[`STRAP_QSPI_SRAM];
wire        strap_qspi_pre_sram    = system_strap[`STRAP_QSPI_PRE_SRAM];
wire        strap_qspi_init_bypass = system_strap[`STRAP_QSPI_INIT_BYPASS];

wire [37:0]                     io_out_int                   ;
wire [37:0]                     io_oeb_int                   ;
wire [37:0]                     io_in                        ;

//--------------------------------------------------------------------------
// Pinmux Risc core config
// -------------------------------------------------------------------------
wire [15:0]                    cfg_riscv_ctrl;
wire [3:0]                     cfg_riscv_sram_lphase   = cfg_riscv_ctrl[3:0];
wire [2:0]                     cfg_riscv_cache_ctrl    = cfg_riscv_ctrl[6:4];
wire [1:0]                     cfg_riscv_debug_sel     = cfg_riscv_ctrl[9:8];
wire                           cfg_bypass_icache       = cfg_riscv_ctrl[10];
wire                           cfg_bypass_dcache       = cfg_riscv_ctrl[11];

/////////////////////////////////////////////////////////
// System/WB Clock Skew Ctrl
////////////////////////////////////////////////////////

assign cfg_wcska_wi          = cfg_clk_skew_ctrl1[3:0];
assign cfg_wcska_wh          = cfg_clk_skew_ctrl1[7:4];
assign cfg_wcska_riscv       = cfg_clk_skew_ctrl1[11:8];
assign cfg_wcska_qspi        = cfg_clk_skew_ctrl1[15:12];
assign cfg_wcska_uart        = cfg_clk_skew_ctrl1[19:16];
assign cfg_wcska_pinmux      = cfg_clk_skew_ctrl1[23:20];
assign cfg_wcska_qspi_co     = cfg_clk_skew_ctrl1[27:24];
assign cfg_wcska_peri        = cfg_clk_skew_ctrl1[31:28];

/////////////////////////////////////////////////////////
// RISCV Clock skew control
/////////////////////////////////////////////////////////
wire [3:0] cfg_ccska_riscv_intf_rp  ;
wire [3:0] cfg_ccska_riscv_icon_rp  ;
wire [3:0] cfg_ccska_riscv_core0_rp ;
wire [3:0] cfg_ccska_riscv_core1_rp ;
wire [3:0] cfg_ccska_riscv_core2_rp ;
wire [3:0] cfg_ccska_riscv_core3_rp ;

wire [3:0]   cfg_ccska_riscv_intf   = cfg_clk_skew_ctrl2[3:0];
wire [3:0]   cfg_ccska_riscv_icon   = cfg_clk_skew_ctrl2[7:4];
wire [3:0]   cfg_ccska_riscv_core0  = cfg_clk_skew_ctrl2[11:8];
wire [3:0]   cfg_ccska_riscv_core1  = cfg_clk_skew_ctrl2[15:12];
wire [3:0]   cfg_ccska_riscv_core2  = cfg_clk_skew_ctrl2[19:16];
wire [3:0]   cfg_ccska_riscv_core3  = cfg_clk_skew_ctrl2[23:20];
assign       cfg_ccska_aes          = cfg_clk_skew_ctrl2[27:24];
assign       cfg_ccska_fpu          = cfg_clk_skew_ctrl2[31:28];


wire   int_pll_clock       = pll_clk_out[0];

//-------------------------------------
// cpu clock repeater mapping
//-------------------------------------
wire [2:0] cpu_clk_rp;

wire       cpu_clk_rp_risc   = cpu_clk_rp[0];
wire       cpu_clk_rp_pinmux = cpu_clk_rp[2];

wire       riscv_wbclk;

	/* All analog enable/select/polarity and holdover bits	*/
	/* will not be handled in the picosoc module.  Tie	*/
	/* each one of them off to the local loopback zero bit.	*/

	assign gpio_analog_en = gpio_loopback_zero;
	assign gpio_analog_pol = gpio_loopback_zero;
	assign gpio_analog_sel = gpio_loopback_zero;
	assign gpio_holdover = gpio_loopback_zero;

	(* keep *) vccd1_connection vccd1_connection ();
	(* keep *) vssd1_connection vssd1_connection ();

//-------------------------
// 15 Right GPIO Pads
//-------------------------
gpio_right  #(
`ifndef SYNTHESIS
	 .OPENFRAME_IO_PADS(15) 
`endif
        ) u_gpio_right (
`ifdef USE_POWER_PINS
         .vccd         (vccd),    // User area 1 1.8V supply
         .vssd         (vssd),    // User area 1 digital ground
`endif

    /* Basic bidirectional I/O.  Input gpio_in_h is in the 3.3V domain;  all
     * others are in the 1.8v domain.  OEB is output enable, sense inverted.
     */
    .gpio_in              (gpio_in        [OPENFRAME_IO_RIGHT_PADS-1:0] ),
    .gpio_in_h            (gpio_in_h      [OPENFRAME_IO_RIGHT_PADS-1:0] ),
    .gpio_out             (gpio_out       [OPENFRAME_IO_RIGHT_PADS-1:0] ),
    .gpio_oeb             (gpio_oeb       [OPENFRAME_IO_RIGHT_PADS-1:0] ),
    .gpio_inp_dis         (gpio_inp_dis   [OPENFRAME_IO_RIGHT_PADS-1:0] ),	// a.k.a. ieb

    /* Pad configuration.  These signals are usually static values.
     * See the documentation for the sky130_fd_io__gpiov2 cell signals
     * and their use.
     */
    .gpio_ib_mode_sel    (gpio_ib_mode_sel[OPENFRAME_IO_RIGHT_PADS-1:0]),
    .gpio_vtrip_sel      (gpio_vtrip_sel  [OPENFRAME_IO_RIGHT_PADS-1:0]),
    .gpio_slow_sel       (gpio_slow_sel   [OPENFRAME_IO_RIGHT_PADS-1:0]),
    .gpio_holdover       (gpio_holdover   [OPENFRAME_IO_RIGHT_PADS-1:0]),
    .gpio_analog_en      (gpio_analog_en  [OPENFRAME_IO_RIGHT_PADS-1:0]),
    .gpio_analog_sel     (gpio_analog_sel [OPENFRAME_IO_RIGHT_PADS-1:0]),
    .gpio_analog_pol     (gpio_analog_pol [OPENFRAME_IO_RIGHT_PADS-1:0]),
    .gpio_dm2            (gpio_dm2        [OPENFRAME_IO_RIGHT_PADS-1:0]),
    .gpio_dm1            (gpio_dm1        [OPENFRAME_IO_RIGHT_PADS-1:0]),
    .gpio_dm0            (gpio_dm0        [OPENFRAME_IO_RIGHT_PADS-1:0]),

    /* These signals correct directly to the pad.  Pads using analog I/O
     * connections should keep the digital input and output buffers turned
     * off.  Both signals connect to the same pad.  The "noesd" signal
     * is a direct connection to the pad;  the other signal connects through
     * a series resistor which gives it minimal ESD protection.  Both signals
     * have basic over- and under-voltage protection at the pad.  These
     * signals may be expected to attenuate heavily above 50MHz.
     */
    .analog_io          (analog_io        [OPENFRAME_IO_RIGHT_PADS-1:0]),
    .analog_noesd_io    (analog_noesd_io  [OPENFRAME_IO_RIGHT_PADS-1:0]),

    /* These signals are constant one and zero in the 1.8V domain, one for
     * each GPIO pad, and can be looped back to the control signals on the
     * same GPIO pad to set a static configuration at power-up.
     */
    .gpio_loopback_one  (gpio_loopback_one [OPENFRAME_IO_RIGHT_PADS-1:0]),
    .gpio_loopback_zero (gpio_loopback_zero[OPENFRAME_IO_RIGHT_PADS-1:0])


);
//-------------------------
// 9 Right GPIO Pads
//-------------------------
gpio_top  #(
`ifndef SYNTHESIS
	 .OPENFRAME_IO_PADS(9) 
`endif
        ) u_gpio_left (
`ifdef USE_POWER_PINS
         .vccd         (vccd),    // User area 1 1.8V supply
         .vssd         (vssd),    // User area 1 digital ground
`endif

    /* Basic bidirectional I/O.  Input gpio_in_h is in the 3.3V domain;  all
     * others are in the 1.8v domain.  OEB is output enable, sense inverted.
     */
    .gpio_in              (gpio_in[OPENFRAME_IO_TOP_PADS-1:OPENFRAME_IO_RIGHT_PADS]      ),
    .gpio_in_h            (gpio_in_h[OPENFRAME_IO_TOP_PADS-1:OPENFRAME_IO_RIGHT_PADS]    ),
    .gpio_out             (gpio_out[OPENFRAME_IO_TOP_PADS-1:OPENFRAME_IO_RIGHT_PADS]     ),
    .gpio_oeb             (gpio_oeb[OPENFRAME_IO_TOP_PADS-1:OPENFRAME_IO_RIGHT_PADS]     ),
    .gpio_inp_dis         (gpio_inp_dis[OPENFRAME_IO_TOP_PADS-1:OPENFRAME_IO_RIGHT_PADS] ),	// a.k.a. ieb

    /* Pad configuration.  These signals are usually static values.
     * See the documentation for the sky130_fd_io__gpiov2 cell signals
     * and their use.
     */
    .gpio_ib_mode_sel    (gpio_ib_mode_sel[OPENFRAME_IO_TOP_PADS-1:OPENFRAME_IO_RIGHT_PADS]),
    .gpio_vtrip_sel      (gpio_vtrip_sel[OPENFRAME_IO_TOP_PADS-1:OPENFRAME_IO_RIGHT_PADS]),
    .gpio_slow_sel       (gpio_slow_sel[OPENFRAME_IO_TOP_PADS-1:OPENFRAME_IO_RIGHT_PADS]),
    .gpio_holdover       (gpio_holdover[OPENFRAME_IO_TOP_PADS-1:OPENFRAME_IO_RIGHT_PADS]),
    .gpio_analog_en      (gpio_analog_en[OPENFRAME_IO_TOP_PADS-1:OPENFRAME_IO_RIGHT_PADS]),
    .gpio_analog_sel     (gpio_analog_sel[OPENFRAME_IO_TOP_PADS-1:OPENFRAME_IO_RIGHT_PADS]),
    .gpio_analog_pol     (gpio_analog_pol[OPENFRAME_IO_TOP_PADS-1:OPENFRAME_IO_RIGHT_PADS]),
    .gpio_dm2            (gpio_dm2[OPENFRAME_IO_TOP_PADS-1:OPENFRAME_IO_RIGHT_PADS]),
    .gpio_dm1            (gpio_dm1[OPENFRAME_IO_TOP_PADS-1:OPENFRAME_IO_RIGHT_PADS]),
    .gpio_dm0            (gpio_dm0[OPENFRAME_IO_TOP_PADS-1:OPENFRAME_IO_RIGHT_PADS]),

    /* These signals correct directly to the pad.  Pads using analog I/O
     * connections should keep the digital input and output buffers turned
     * off.  Both signals connect to the same pad.  The "noesd" signal
     * is a direct connection to the pad;  the other signal connects through
     * a series resistor which gives it minimal ESD protection.  Both signals
     * have basic over- and under-voltage protection at the pad.  These
     * signals may be expected to attenuate heavily above 50MHz.
     */
    .analog_io          (analog_io[OPENFRAME_IO_TOP_PADS-1:OPENFRAME_IO_RIGHT_PADS]),
    .analog_noesd_io    (analog_noesd_io[OPENFRAME_IO_TOP_PADS-1:OPENFRAME_IO_RIGHT_PADS]),

    /* These signals are constant one and zero in the 1.8V domain, one for
     * each GPIO pad, and can be looped back to the control signals on the
     * same GPIO pad to set a static configuration at power-up.
     */
    .gpio_loopback_one  (gpio_loopback_one[OPENFRAME_IO_TOP_PADS-1:0]),
    .gpio_loopback_zero (gpio_loopback_zero[OPENFRAME_IO_TOP_PADS-1:0])


);

//-------------------------
// 14 Right GPIO Pads
//-------------------------
gpio_left  #(
`ifndef SYNTHESIS
	 .OPENFRAME_IO_PADS(14) 
`endif
        ) u_gpio_left (
`ifdef USE_POWER_PINS
         .vccd         (vccd),    // User area 1 1.8V supply
         .vssd         (vssd),    // User area 1 digital ground
`endif

    /* Basic bidirectional I/O.  Input gpio_in_h is in the 3.3V domain;  all
     * others are in the 1.8v domain.  OEB is output enable, sense inverted.
     */
    .gpio_in              (gpio_in[OPENFRAME_IO_LEFT_PADS-1:OPENFRAME_IO_TOP_PADS]      ),
    .gpio_in_h            (gpio_in_h[OPENFRAME_IO_LEFT_PADS-1:OPENFRAME_IO_TOP_PADS]    ),
    .gpio_out             (gpio_out[OPENFRAME_IO_LEFT_PADS-1:OPENFRAME_IO_TOP_PADS]     ),
    .gpio_oeb             (gpio_oeb[OPENFRAME_IO_LEFT_PADS-1:OPENFRAME_IO_TOP_PADS]     ),
    .gpio_inp_dis         (gpio_inp_dis[OPENFRAME_IO_LEFT_PADS-1:OPENFRAME_IO_TOP_PADS] ),	// a.k.a. ieb

    /* Pad configuration.  These signals are usually static values.
     * See the documentation for the sky130_fd_io__gpiov2 cell signals
     * and their use.
     */
    .gpio_ib_mode_sel    (gpio_ib_mode_sel[OPENFRAME_IO_LEFT_PADS-1:OPENFRAME_IO_TOP_PADS]),
    .gpio_vtrip_sel      (gpio_vtrip_sel[OPENFRAME_IO_LEFT_PADS-1:OPENFRAME_IO_TOP_PADS]),
    .gpio_slow_sel       (gpio_slow_sel[OPENFRAME_IO_LEFT_PADS-1:OPENFRAME_IO_TOP_PADS]),
    .gpio_holdover       (gpio_holdover[OPENFRAME_IO_LEFT_PADS-1:OPENFRAME_IO_TOP_PADS]),
    .gpio_analog_en      (gpio_analog_en[OPENFRAME_IO_LEFT_PADS-1:OPENFRAME_IO_TOP_PADS]),
    .gpio_analog_sel     (gpio_analog_sel[OPENFRAME_IO_LEFT_PADS-1:OPENFRAME_IO_TOP_PADS]),
    .gpio_analog_pol     (gpio_analog_pol[OPENFRAME_IO_LEFT_PADS-1:OPENFRAME_IO_TOP_PADS]),
    .gpio_dm2            (gpio_dm2[OPENFRAME_IO_LEFT_PADS-1:OPENFRAME_IO_TOP_PADS]),
    .gpio_dm1            (gpio_dm1[OPENFRAME_IO_LEFT_PADS-1:OPENFRAME_IO_TOP_PADS]),
    .gpio_dm0            (gpio_dm0[OPENFRAME_IO_LEFT_PADS-1:OPENFRAME_IO_TOP_PADS]),

    /* These signals correct directly to the pad.  Pads using analog I/O
     * connections should keep the digital input and output buffers turned
     * off.  Both signals connect to the same pad.  The "noesd" signal
     * is a direct connection to the pad;  the other signal connects through
     * a series resistor which gives it minimal ESD protection.  Both signals
     * have basic over- and under-voltage protection at the pad.  These
     * signals may be expected to attenuate heavily above 50MHz.
     */
    .analog_io          (analog_io[OPENFRAME_IO_LEFT_PADS-1:OPENFRAME_IO_TOP_PADS]),
    .analog_noesd_io    (analog_noesd_io[OPENFRAME_IO_LEFT_PADS-1:OPENFRAME_IO_TOP_PADS]),

    /* These signals are constant one and zero in the 1.8V domain, one for
     * each GPIO pad, and can be looped back to the control signals on the
     * same GPIO pad to set a static configuration at power-up.
     */
    .gpio_loopback_one  (gpio_loopback_one[OPENFRAME_IO_LEFT_PADS-1:0]),
    .gpio_loopback_zero (gpio_loopback_zero[OPENFRAME_IO_LEFT_PADS-1:0])


);

//-------------------------
// 6 Bottom GPIO Pads
//-------------------------
gpio_bottom  #(
`ifndef SYNTHESIS
	 .OPENFRAME_IO_PADS(6) 
`endif
        ) u_gpio_bottom (
`ifdef USE_POWER_PINS
         .vccd         (vccd),    // User area 1 1.8V supply
         .vssd         (vssd),    // User area 1 digital ground
`endif

    /* Basic bidirectional I/O.  Input gpio_in_h is in the 3.3V domain;  all
     * others are in the 1.8v domain.  OEB is output enable, sense inverted.
     */
    .gpio_in              (gpio_in        [OPENFRAME_IO_BOTTOM_PADS-1:OPENFRAME_IO_LEFT_PADS] ),
    .gpio_in_h            (gpio_in_h      [OPENFRAME_IO_BOTTOM_PADS-1:OPENFRAME_IO_LEFT_PADS] ),
    .gpio_out             (gpio_out       [OPENFRAME_IO_BOTTOM_PADS-1:OPENFRAME_IO_LEFT_PADS] ),
    .gpio_oeb             (gpio_oeb       [OPENFRAME_IO_BOTTOM_PADS-1:OPENFRAME_IO_LEFT_PADS] ),
    .gpio_inp_dis         (gpio_inp_dis   [OPENFRAME_IO_BOTTOM_PADS-1:OPENFRAME_IO_LEFT_PADS] ),	// a.k.a. ieb

    /* Pad configuration.  These signals are usually static values.
     * See the documentation for the sky130_fd_io__gpiov2 cell signals
     * and their use.
     */
    .gpio_ib_mode_sel    (gpio_ib_mode_sel[OPENFRAME_IO_BOTTOM_PADS-1:OPENFRAME_IO_LEFT_PADS]),
    .gpio_vtrip_sel      (gpio_vtrip_sel  [OPENFRAME_IO_BOTTOM_PADS-1:OPENFRAME_IO_LEFT_PADS]),
    .gpio_slow_sel       (gpio_slow_sel   [OPENFRAME_IO_BOTTOM_PADS-1:OPENFRAME_IO_LEFT_PADS]),
    .gpio_holdover       (gpio_holdover   [OPENFRAME_IO_BOTTOM_PADS-1:OPENFRAME_IO_LEFT_PADS]),
    .gpio_analog_en      (gpio_analog_en  [OPENFRAME_IO_BOTTOM_PADS-1:OPENFRAME_IO_LEFT_PADS]),
    .gpio_analog_sel     (gpio_analog_sel [OPENFRAME_IO_BOTTOM_PADS-1:OPENFRAME_IO_LEFT_PADS]),
    .gpio_analog_pol     (gpio_analog_pol [OPENFRAME_IO_BOTTOM_PADS-1:OPENFRAME_IO_LEFT_PADS]),
    .gpio_dm2            (gpio_dm2        [OPENFRAME_IO_BOTTOM_PADS-1:OPENFRAME_IO_LEFT_PADS]),
    .gpio_dm1            (gpio_dm1        [OPENFRAME_IO_BOTTOM_PADS-1:OPENFRAME_IO_LEFT_PADS]),
    .gpio_dm0            (gpio_dm0        [OPENFRAME_IO_BOTTOM_PADS-1:OPENFRAME_IO_LEFT_PADS]),

    /* These signals correct directly to the pad.  Pads using analog I/O
     * connections should keep the digital input and output buffers turned
     * off.  Both signals connect to the same pad.  The "noesd" signal
     * is a direct connection to the pad;  the other signal connects through
     * a series resistor which gives it minimal ESD protection.  Both signals
     * have basic over- and under-voltage protection at the pad.  These
     * signals may be expected to attenuate heavily above 50MHz.
     */
    .analog_io          (analog_io        [OPENFRAME_IO_BOTTOM_PADS-1:OPENFRAME_IO_LEFT_PADS]),
    .analog_noesd_io    (analog_noesd_io  [OPENFRAME_IO_BOTTOM_PADS-1:OPENFRAME_IO_LEFT_PADS]),

    /* These signals are constant one and zero in the 1.8V domain, one for
     * each GPIO pad, and can be looped back to the control signals on the
     * same GPIO pad to set a static configuration at power-up.
     */
    .gpio_loopback_one  (gpio_loopback_one [OPENFRAME_IO_BOTTOM_PADS-1:OPENFRAME_IO_LEFT_PADS]),
    .gpio_loopback_zero (gpio_loopback_zero[OPENFRAME_IO_BOTTOM_PADS-1:OPENFRAME_IO_LEFT_PADS])


);

wire cfg_fast_sim;

wire wb_clk_i = gpio_in[38];
wire user_clock2 = gpio_in[38];
wire wb_rst_i = ~resetb_l;

/***********************************************
 Wishbone HOST
*************************************************/

wb_host u_wb_host(
`ifdef USE_POWER_PINS
          .vccd1                   (vccd1                   ),// User area 1 1.8V supply
          .vssd1                   (vssd1                   ),// User area 1 digital ground
`endif

          .cfg_fast_sim            (cfg_fast_sim            ),
          .user_clock1             (wb_clk_i                ),
          .user_clock2             (user_clock2             ),
          .int_pll_clock           (int_pll_clock           ),

          .cpu_clk                 (cpu_clk                 ),

       // to/from Pinmux
          .xtal_clk                (xtal_clk                ),
	      .e_reset_n               (e_reset_n               ),  // external reset
	      .p_reset_n               (p_reset_n               ),  // power-on reset
          .s_reset_n               (s_reset_n               ),  // soft reset
          .cfg_strap_pad_ctrl      (cfg_strap_pad_ctrl      ),
	      .system_strap            (system_strap            ),
	      .strap_sticky            (strap_sticky_rp         ),

          .wbd_int_rst_n           (wbd_int_rst_n           ),
          .wbd_pll_rst_n           (wbd_pll_rst_n           ),

    // Master Port
          .wbm_rst_i               (wb_rst_i                ),  
          .wbm_clk_i               (wb_clk_i                ),  

    // Clock Skeq Adjust
          .wbd_clk_int             (wbd_clk_int             ),
          .wbd_clk_wh              (wbd_clk_wh              ),  
          .cfg_cska_wh             (cfg_wcska_wh            ),

    // Slave Port
          .wbs_clk_out             (wbd_clk_int             ),
          .wbs_clk_i               (wbd_clk_wh              ),  
          .wbs_cyc_o               (wbd_int_cyc_i           ),  
          .wbs_stb_o               (wbd_int_stb_i           ),  
          .wbs_adr_o               (wbd_int_adr_i           ),  
          .wbs_we_o                (wbd_int_we_i            ),  
          .wbs_dat_o               (wbd_int_dat_i           ),  
          .wbs_sel_o               (wbd_int_sel_i           ),  
          .wbs_dat_i               (wbd_int_dat_o           ),  
          .wbs_ack_i               (wbd_int_ack_o           ),  
          .wbs_err_i               (wbd_int_err_o           ),  

          .cfg_clk_skew_ctrl1      (cfg_clk_skew_ctrl1      ),
          .cfg_clk_skew_ctrl2      (cfg_clk_skew_ctrl2      ),

          .uartm_rxd               (uartm_rxd               ),
          .uartm_txd               (uartm_txd               ),

          .sclk                    (sspis_sck               ),
          .ssn                     (sspis_ssn               ),
          .sdin                    (sspis_si                ),
          .sdout                   (sspis_so                ),
          .sdout_oen               (                        )



    );

/****************************************************************
  Digital PLL
*****************************************************************/

// This rtl/gds picked from efabless caravel project 
dg_pll   u_pll(
`ifdef USE_POWER_PINS
    .VPWR                           (vccd1                  ),
    .VGND                           (vssd1                  ),
`endif
    .resetb                         (wbd_pll_rst_n          ), 
    .enable                         (cfg_pll_enb            ), 
    .div                            (cfg_pll_fed_div        ), 
    .dco                            (cfg_dco_mode           ), 
    .ext_trim                       (cfg_dc_trim            ),
    .osc                            (pll_ref_clk            ), 
    .clockp                         (pll_clk_out            ) 
    );



//------------------------------------------------------------------------------
// RISC V Core instance
//------------------------------------------------------------------------------
ycr2_top_wb u_riscv_top (
`ifdef USE_POWER_PINS
          .vccd1                   (vccd1                      ),// User area 1 1.8V supply
          .vssd1                   (vssd1                      ),// User area 1 digital ground
`endif
          .wbd_clk_int             (riscv_wbclk                ), 
          .cfg_wcska_riscv_intf    (cfg_wcska_riscv_rp         ), 
          .wbd_clk_skew            (wbd_clk_riscv_skew         ),


           `ifdef YCR_DBG_EN
               // -- JTAG I/F
            .trst_n                (riscv_trst_n               ),
            .tck                   (riscv_tck                  ),
            .tms                   (riscv_tms                  ),
            .tdi                   (riscv_tdi                  ),
            .tdo                   (riscv_tdo                  ),
            .tdo_en                (riscv_tdo_en               ),
           `endif // YCR_DBG_EN

    // Reset
          .pwrup_rst_n             (wbd_int_rst_n              ),
          .rst_n                   (wbd_int_rst_n              ),
          .cpu_intf_rst_n          (cpu_intf_rst_n             ),
          .cpu_core_rst_n          (cpu_core_rst_n[1:0]        ),
          .riscv_debug             (riscv_debug                ),
          .core_debug_sel          (cfg_riscv_debug_sel        ),
	      .cfg_sram_lphase         (cfg_riscv_sram_lphase      ),
	      .cfg_cache_ctrl          (cfg_riscv_cache_ctrl       ),
	      .cfg_bypass_icache       (cfg_bypass_icache          ),
	      .cfg_bypass_dcache       (cfg_bypass_dcache          ),

    // Clock
          .core_clk_int            (cpu_clk_rp_risc            ),
          .cfg_ccska_riscv_intf    (cfg_ccska_riscv_intf_rp    ),
          .cfg_ccska_riscv_icon    (cfg_ccska_riscv_icon_rp    ),
          .cfg_ccska_riscv_core0   (cfg_ccska_riscv_core0_rp   ),
          .cfg_ccska_riscv_core1   (cfg_ccska_riscv_core1_rp   ),

          .rtc_clk                 (rtc_clk                    ),


    // IRQ
          .irq_lines               (irq_lines_rp               ), 
          .soft_irq                (soft_irq_rp                ), // TODO - Interrupts

    // DFT
    //    .test_mode               (1'b0                       ), // Moved inside IP
    //    .test_rst_n              (1'b1                       ), // Moved inside IP

`ifndef SCR1_TCM_MEM
    // SRAM-0 PORT-0
          .sram0_clk0             (sram0_clk0                  ),
          .sram0_csb0             (sram0_csb0                  ),
          .sram0_web0             (sram0_web0                  ),
          .sram0_addr0            (sram0_addr0                 ),
          .sram0_wmask0           (sram0_wmask0                ),
          .sram0_din0             (sram0_din0                  ),
          .sram0_dout0            (sram0_dout0                 ),
    
    // SRAM-0 PORT-0
          .sram0_clk1             (sram0_clk1                   ),
          .sram0_csb1             (sram0_csb1                   ),
          .sram0_addr1            (sram0_addr1                  ),
          .sram0_dout1            (sram0_dout1                  ),

  //  // SRAM-1 PORT-0
  //      .sram1_clk0             (sram1_clk0                   ),
  //      .sram1_csb0             (sram1_csb0                   ),
  //      .sram1_web0             (sram1_web0                   ),
  //      .sram1_addr0            (sram1_addr0                  ),
  //      .sram1_wmask0           (sram1_wmask0                 ),
  //      .sram1_din0             (sram1_din0                   ),
  //      .sram1_dout0            (sram1_dout0                  ),
  //  
  //  // SRAM PORT-0
  //      .sram1_clk1             (sram1_clk1                   ),
  //      .sram1_csb1             (sram1_csb1                   ),
  //      .sram1_addr1            (sram1_addr1                  ),
  //      .sram1_dout1            (sram1_dout1                  ),
`endif
    
          .wb_rst_n                (wbd_int_rst_n           ),
          .wb_clk                  (wbd_clk_riscv_skew      ),

    // Instruction cache memory interface
          .wb_icache_stb_o         (wbd_riscv_icache_stb_i  ),
          .wb_icache_adr_o         (wbd_riscv_icache_adr_i  ),
          .wb_icache_we_o          (wbd_riscv_icache_we_i   ), 
          .wb_icache_sel_o         (wbd_riscv_icache_sel_i  ),
          .wb_icache_bl_o          (wbd_riscv_icache_bl_i   ),
          .wb_icache_bry_o         (wbd_riscv_icache_bry_i  ),
          .wb_icache_dat_i         (wbd_riscv_icache_dat_o  ),
          .wb_icache_ack_i         (wbd_riscv_icache_ack_o  ),
          .wb_icache_lack_i        (wbd_riscv_icache_lack_o ),
          .wb_icache_err_i         (wbd_riscv_icache_err_o  ),

          .icache_mem_clk0    (icache_mem_clk0              ), // CLK
          .icache_mem_csb0    (icache_mem_csb0              ), // CS#
          .icache_mem_web0    (icache_mem_web0              ), // WE#
          .icache_mem_addr0   (icache_mem_addr0             ), // Address
          .icache_mem_wmask0  (icache_mem_wmask0            ), // WMASK#
          .icache_mem_din0    (icache_mem_din0              ), // Write Data
//        .icache_mem_dout0   (icache_mem_dout0             ), // Read Data
                                
                                
          .icache_mem_clk1    (icache_mem_clk1              ), // CLK
          .icache_mem_csb1    (icache_mem_csb1              ), // CS#
          .icache_mem_addr1   (icache_mem_addr1             ), // Address
          .icache_mem_dout1   (icache_mem_dout1             ), // Read Data

    // Data cache memory interface
          .wb_dcache_stb_o         (wbd_riscv_dcache_stb_i  ),
          .wb_dcache_adr_o         (wbd_riscv_dcache_adr_i  ),
          .wb_dcache_we_o          (wbd_riscv_dcache_we_i   ), 
          .wb_dcache_dat_o         (wbd_riscv_dcache_dat_i  ),
          .wb_dcache_sel_o         (wbd_riscv_dcache_sel_i  ),
          .wb_dcache_bl_o          (wbd_riscv_dcache_bl_i   ),
          .wb_dcache_bry_o         (wbd_riscv_dcache_bry_i  ),
          .wb_dcache_dat_i         (wbd_riscv_dcache_dat_o  ),
          .wb_dcache_ack_i         (wbd_riscv_dcache_ack_o  ),
          .wb_dcache_lack_i        (wbd_riscv_dcache_lack_o ),
          .wb_dcache_err_i         (wbd_riscv_dcache_err_o  ),

          .dcache_mem_clk0    (dcache_mem_clk0              ), // CLK
          .dcache_mem_csb0    (dcache_mem_csb0              ), // CS#
          .dcache_mem_web0    (dcache_mem_web0              ), // WE#
          .dcache_mem_addr0   (dcache_mem_addr0             ), // Address
          .dcache_mem_wmask0  (dcache_mem_wmask0            ), // WMASK#
          .dcache_mem_din0    (dcache_mem_din0              ), // Write Data
          .dcache_mem_dout0   (dcache_mem_dout0             ), // Read Data
                                
                                
          .dcache_mem_clk1    (dcache_mem_clk1              ), // CLK
          .dcache_mem_csb1    (dcache_mem_csb1              ), // CS#
          .dcache_mem_addr1   (dcache_mem_addr1             ), // Address
          .dcache_mem_dout1   (dcache_mem_dout1             ), // Read Data


    // Data memory interface
          .wbd_dmem_stb_o          (wbd_riscv_dmem_stb_i    ),
          .wbd_dmem_adr_o          (wbd_riscv_dmem_adr_i    ),
          .wbd_dmem_we_o           (wbd_riscv_dmem_we_i     ), 
          .wbd_dmem_dat_o          (wbd_riscv_dmem_dat_i    ),
          .wbd_dmem_sel_o          (wbd_riscv_dmem_sel_i    ),
          .wbd_dmem_bl_o           (wbd_riscv_dmem_bl_i     ),
          .wbd_dmem_bry_o          (wbd_riscv_dmem_bry_i    ),
          .wbd_dmem_dat_i          (wbd_riscv_dmem_dat_o    ),
          .wbd_dmem_ack_i          (wbd_riscv_dmem_ack_o    ),
          .wbd_dmem_lack_i         (wbd_riscv_dmem_lack_o   ),
          .wbd_dmem_err_i          (wbd_riscv_dmem_err_o    ),

          .cpu_clk_aes             (cpu_clk_aes             ),
          .aes_dmem_req            (aes_dmem_req            ),
          .aes_dmem_cmd            (aes_dmem_cmd            ),
          .aes_dmem_width          (aes_dmem_width          ),
          .aes_dmem_addr           (aes_dmem_addr           ),
          .aes_dmem_wdata          (aes_dmem_wdata          ),
          .aes_dmem_req_ack        (aes_dmem_req_ack        ),
          .aes_dmem_rdata          (aes_dmem_rdata          ),
          .aes_dmem_resp           (aes_dmem_resp           ),
          .aes_idle                (aes_idle                ),

          .cpu_clk_fpu             (cpu_clk_fpu             ),
          .fpu_dmem_req            (fpu_dmem_req            ),
          .fpu_dmem_cmd            (fpu_dmem_cmd            ),
          .fpu_dmem_width          (fpu_dmem_width          ),
          .fpu_dmem_addr           (fpu_dmem_addr           ),
          .fpu_dmem_wdata          (fpu_dmem_wdata          ),
          .fpu_dmem_req_ack        (fpu_dmem_req_ack        ),
          .fpu_dmem_rdata          (fpu_dmem_rdata          ),
          .fpu_dmem_resp           (fpu_dmem_resp           ),
          .fpu_idle                (fpu_idle                )
);

//----------------------------------------------
// TCM
//----------------------------------------------

`ifndef SCR1_TCM_MEM
sky130_sram_2kbyte_1rw1r_32x512_8 u_tsram0_2kb(
`ifdef USE_POWER_PINS
          .vccd1              (vccd1                        ),// area 1 1.8V supply
          .vssd1              (vssd1                        ),// area 1 digital ground
`endif
// Port 0: RW
          .clk0               (sram0_clk0                   ),
          .csb0               (sram0_csb0                   ),
          .web0               (sram0_web0                   ),
          .wmask0             (sram0_wmask0                 ),
          .addr0              (sram0_addr0                  ),
          .din0               (sram0_din0                   ),
          .dout0              (sram0_dout0                  ),
// Port 1: R
          .clk1               (sram0_clk1                   ),
          .csb1               (sram0_csb1                   ),
          .addr1              (sram0_addr1                  ),
          .dout1              (sram0_dout1                  )
  );

/***
sky130_sram_2kbyte_1rw1r_32x512_8 u_tsram1_2kb(
`ifdef USE_POWER_PINS
          .vccd1              (vccd1                        ),// User area 1 1.8V supply
          .vssd1              (vssd1                        ),// User area 1 digital ground
`endif
// Port 0: RW
          .clk0               (sram1_clk0                   ),
          .csb0               (sram1_csb0                   ),
          .web0               (sram1_web0                   ),
          .wmask0             (sram1_wmask0                 ),
          .addr0              (sram1_addr0                  ),
          .din0               (sram1_din0                   ),
          .dout0              (sram1_dout0                  ),
// Port 1: R
          .clk1               (sram1_clk1                   ),
          .csb1               (sram1_csb1                   ),
          .addr1              (sram1_addr1                  ),
          .dout1              (sram1_dout1                  )
  );
***/
`endif

//------------------------------------------------
// icache
//------------------------------------------------

sky130_sram_2kbyte_1rw1r_32x512_8 u_icache_2kb(
`ifdef USE_POWER_PINS
          .vccd1              (vccd1                        ),// User area 1 1.8V supply
          .vssd1              (vssd1                        ),// User area 1 digital ground
`endif
// Port 0: RW
          .clk0               (icache_mem_clk0              ),
          .csb0               (icache_mem_csb0              ),
          .web0               (icache_mem_web0              ),
          .wmask0             (icache_mem_wmask0            ),
          .addr0              (icache_mem_addr0             ),
          .din0               (icache_mem_din0              ),
          .dout0              (                             ),
// Port 1: R
          .clk1               (icache_mem_clk1              ),
          .csb1               (icache_mem_csb1              ),
          .addr1              (icache_mem_addr1             ),
          .dout1              (icache_mem_dout1             )
  );

//----------------------------------------------------------
// dcache
//----------------------------------------------------------

sky130_sram_2kbyte_1rw1r_32x512_8 u_dcache_2kb(
`ifdef USE_POWER_PINS
          .vccd1              (vccd1                        ),// User area 1 1.8V supply
          .vssd1              (vssd1                        ),// User area 1 digital ground
`endif
// Port 0: RW
          .clk0               (dcache_mem_clk0              ),
          .csb0               (dcache_mem_csb0              ),
          .web0               (dcache_mem_web0              ),
          .wmask0             (dcache_mem_wmask0            ),
          .addr0              (dcache_mem_addr0             ),
          .din0               (dcache_mem_din0              ),
          .dout0              (dcache_mem_dout0             ),
// Port 1: R
          .clk1               (dcache_mem_clk1              ),
          .csb1               (dcache_mem_csb1              ),
          .addr1              (dcache_mem_addr1             ),
          .dout1              (dcache_mem_dout1             )
  );

/***********************************************
  AES 128 Bit 
*************************************************/
aes_top u_aes (
`ifdef USE_POWER_PINS
    .vccd1                 (vccd1            ),
    .vssd1                 (vssd1            ),
`endif

    .mclk                  (cpu_clk_aes_skew ),
    .rst_n                 (cpu_intf_rst_n   ),

    .cfg_cska              (cfg_ccska_aes_rp ),
    .wbd_clk_int           (cpu_clk_aes      ),
    .wbd_clk_out           (cpu_clk_aes_skew ),

    .dmem_req              (aes_dmem_req     ),
    .dmem_cmd              (aes_dmem_cmd     ),
    .dmem_width            (aes_dmem_width   ),
    .dmem_addr             (aes_dmem_addr    ),
    .dmem_wdata            (aes_dmem_wdata   ),
    .dmem_req_ack          (aes_dmem_req_ack ),
    .dmem_rdata            (aes_dmem_rdata   ),
    .dmem_resp             (aes_dmem_resp    ),

    .idle                  (aes_idle         )
);

/***********************************************
  FPU
*************************************************/
fpu_wrapper u_fpu (
`ifdef USE_POWER_PINS
    .vccd1                 (vccd1            ),
    .vssd1                 (vssd1            ),
`endif

          .mclk               (cpu_clk_fpu_skew             ),
          .rst_n              (cpu_intf_rst_n               ),

          .cfg_cska           (cfg_ccska_fpu_rp             ),
          .wbd_clk_int        (cpu_clk_fpu                  ),
          .wbd_clk_out        (cpu_clk_fpu_skew             ),

          .dmem_req           (fpu_dmem_req                 ),
          .dmem_cmd           (fpu_dmem_cmd                 ),
          .dmem_width         (fpu_dmem_width               ),
          .dmem_addr          (fpu_dmem_addr                ),
          .dmem_wdata         (fpu_dmem_wdata               ),
          .dmem_req_ack       (fpu_dmem_req_ack             ),
          .dmem_rdata         (fpu_dmem_rdata               ),
          .dmem_resp          (fpu_dmem_resp                ),

          .idle               (fpu_idle                     )
);

/*********************************************************
* SPI Master
* This is implementation of an SPI master that is controlled via an AXI bus                                                  . 
* It has FIFOs for transmitting and receiving data. 
* It supports both the normal SPI mode and QPI mode with 4 data lines.
* *******************************************************/

qspim_top
#(
`ifndef SYNTHESIS
    .WB_WIDTH  (WB_WIDTH                                    )
`endif
) u_qspi_master
(
`ifdef USE_POWER_PINS
          .vccd1                   (vccd1                   ),// User area 1 1.8V supply
          .vssd1                   (vssd1                   ),// User area 1 digital ground
`endif
          .mclk                    (wbd_clk_spi             ),
          .rst_n                   (qspim_rst_n             ),
          .cfg_fast_sim            (cfg_fast_sim            ),

          .strap_flash             (strap_qspi_flash        ),
          .strap_pre_sram          (strap_qspi_pre_sram     ),
          .strap_sram              (strap_qspi_sram         ),
          .cfg_init_bypass         (strap_qspi_init_bypass  ),

    // Clock Skew Adjust
          .cfg_cska_sp_co          (cfg_wcska_qspi_co_rp     ),
          .cfg_cska_spi            (cfg_wcska_qspi_rp        ),
          .wbd_clk_int             (qspim_mclk               ),
          .wbd_clk_spi             (wbd_clk_spi              ),

          .qspim_idle              (qspim_idle               ),

          .wbd_stb_i               (wbd_spim_stb_o          ),
          .wbd_adr_i               (wbd_spim_adr_o          ),
          .wbd_we_i                (wbd_spim_we_o           ), 
          .wbd_dat_i               (wbd_spim_dat_o          ),
          .wbd_sel_i               (wbd_spim_sel_o          ),
          .wbd_bl_i                (wbd_spim_bl_o           ),
          .wbd_bry_i               (wbd_spim_bry_o          ),
          .wbd_dat_o               (wbd_spim_dat_i          ),
          .wbd_ack_o               (wbd_spim_ack_i          ),
          .wbd_lack_o              (wbd_spim_lack_i         ),
          .wbd_err_o               (wbd_spim_err_i          ),

          .spi_debug               (spi_debug               ),

    // Pad Interface
          .spi_sdi                 (sflash_di               ),
          .spi_clk                 (sflash_sck              ),
          .spi_csn                 (spi_csn                 ),
          .spi_sdo                 (sflash_do               ),
          .spi_oen                 (sflash_oen              )

);


//---------------------------------------------------
// wb_interconnect
//---------------------------------------------------

wb_interconnect  #(
	`ifndef SYNTHESIS
          .CH_CLK_WD          (3                            ),
          .CH_DATA_WD         (156                          )
        `endif
	) u_intercon (
`ifdef USE_POWER_PINS
       .vccd1              (vccd1                        ),// User area 1 1.8V supply
       .vssd1              (vssd1                        ),// User area 1 digital ground
`endif

      .peri_wbclk             (peri_wbclk                   ),
      .riscv_wbclk            (riscv_wbclk                  ),
	  .ch_clk_in              ({
                                     cpu_clk,
                                     cpu_clk,
                                     cpu_clk }                  ),
	  .ch_clk_out             ( cpu_clk_rp                         ),
	  .ch_data_in             ({
			                      cfg_wcska_peri[3:0],
                                  cfg_ccska_fpu[3:0],
                                  cfg_ccska_aes[3:0],
                                  strap_sticky[31:0],
                                  system_strap[31:0],
                                  p_reset_n,
                                  e_reset_n,
                                  cfg_strap_pad_ctrl,
			 
	                              soft_irq,
			                      irq_lines[31:0],

			                      cfg_ccska_riscv_core3[3:0],
			                      cfg_ccska_riscv_core2[3:0],
			                      cfg_ccska_riscv_core1[3:0],
			                      cfg_ccska_riscv_core0[3:0],
			                      cfg_ccska_riscv_icon[3:0],
			                      cfg_ccska_riscv_intf[3:0],

			                      cfg_wcska_qspi_co[3:0],
		                          cfg_wcska_pinmux[3:0],
			                      cfg_wcska_uart[3:0],
		                          cfg_wcska_qspi[3:0],
                                  cfg_wcska_riscv[3:0]
			             }                             ),
	  .ch_data_out            ({
		                          cfg_wcska_peri_rp[3:0],
			                      cfg_ccska_fpu_rp[3:0],
			                      cfg_ccska_aes_rp[3:0],
                                  strap_sticky_rp[31:0],
                                  system_strap_rp[31:0],
                                  p_reset_n_rp,
                                  e_reset_n_rp,
                                  cfg_strap_pad_ctrl_rp,

	                              soft_irq_rp,
			                      irq_lines_rp[31:0],

			                      cfg_ccska_riscv_core3_rp[3:0],
			                      cfg_ccska_riscv_core2_rp[3:0],
			                      cfg_ccska_riscv_core1_rp[3:0],
			                      cfg_ccska_riscv_core0_rp[3:0],
			                      cfg_ccska_riscv_icon_rp[3:0],
			                      cfg_ccska_riscv_intf_rp[3:0],

			                      cfg_wcska_qspi_co_rp[3:0],
		                          cfg_wcska_pinmux_rp[3:0],
			                      cfg_wcska_uart_rp[3:0],
		                          cfg_wcska_qspi_rp[3:0],
                                  cfg_wcska_riscv_rp[3:0]
                               } ),
     // Clock Skew adjust
          .wbd_clk_int        (wbd_clk_int                  ),// wb clock without skew 
          .cfg_cska_wi        (cfg_wcska_wi                 ), 
          .wbd_clk_wi         (wbd_clk_wi_skew              ),// wb clock with skew

          .mclk_raw           (wbd_clk_int                  ), // wb clock without skew
          .clk_i              (wbd_clk_wi_skew              ), // wb clock with skew
          .rst_n              (wbd_int_rst_n                ),

         // Master 0 Interface
          .m0_wbd_dat_i       (wbd_int_dat_i                ),
          .m0_wbd_adr_i       (wbd_int_adr_i                ),
          .m0_wbd_sel_i       (wbd_int_sel_i                ),
          .m0_wbd_we_i        (wbd_int_we_i                 ),
          .m0_wbd_cyc_i       (wbd_int_cyc_i                ),
          .m0_wbd_stb_i       (wbd_int_stb_i                ),
          .m0_wbd_dat_o       (wbd_int_dat_o                ),
          .m0_wbd_ack_o       (wbd_int_ack_o                ),
          .m0_wbd_err_o       (wbd_int_err_o                ),
         
         // Master 1 Interface
          .m1_wbd_dat_i       (wbd_riscv_dmem_dat_i         ),
          .m1_wbd_adr_i       (wbd_riscv_dmem_adr_i         ),
          .m1_wbd_sel_i       (wbd_riscv_dmem_sel_i         ),
          .m1_wbd_bl_i        (wbd_riscv_dmem_bl_i          ),
          .m1_wbd_bry_i       (wbd_riscv_dmem_bry_i         ),
          .m1_wbd_we_i        (wbd_riscv_dmem_we_i          ),
          .m1_wbd_cyc_i       (wbd_riscv_dmem_stb_i         ),
          .m1_wbd_stb_i       (wbd_riscv_dmem_stb_i         ),
          .m1_wbd_dat_o       (wbd_riscv_dmem_dat_o         ),
          .m1_wbd_ack_o       (wbd_riscv_dmem_ack_o         ),
          .m1_wbd_lack_o      (wbd_riscv_dmem_lack_o        ),
          .m1_wbd_err_o       (wbd_riscv_dmem_err_o         ),
         
         // Master 2 Interface
          .m2_wbd_dat_i       (wbd_riscv_dcache_dat_i       ),
          .m2_wbd_adr_i       (wbd_riscv_dcache_adr_i       ),
          .m2_wbd_sel_i       (wbd_riscv_dcache_sel_i       ),
          .m2_wbd_bl_i        (wbd_riscv_dcache_bl_i        ),
          .m2_wbd_bry_i       (wbd_riscv_dcache_bry_i       ),
          .m2_wbd_we_i        (wbd_riscv_dcache_we_i        ),
          .m2_wbd_cyc_i       (wbd_riscv_dcache_stb_i       ),
          .m2_wbd_stb_i       (wbd_riscv_dcache_stb_i       ),
          .m2_wbd_dat_o       (wbd_riscv_dcache_dat_o       ),
          .m2_wbd_ack_o       (wbd_riscv_dcache_ack_o       ),
          .m2_wbd_lack_o      (wbd_riscv_dcache_lack_o      ),
          .m2_wbd_err_o       (wbd_riscv_dcache_err_o       ),

         // Master 3 Interface
          .m3_wbd_adr_i       (wbd_riscv_icache_adr_i       ),
          .m3_wbd_sel_i       (wbd_riscv_icache_sel_i       ),
          .m3_wbd_bl_i        (wbd_riscv_icache_bl_i        ),
          .m3_wbd_bry_i       (wbd_riscv_icache_bry_i       ),
          .m3_wbd_we_i        (wbd_riscv_icache_we_i        ),
          .m3_wbd_cyc_i       (wbd_riscv_icache_stb_i       ),
          .m3_wbd_stb_i       (wbd_riscv_icache_stb_i       ),
          .m3_wbd_dat_o       (wbd_riscv_icache_dat_o       ),
          .m3_wbd_ack_o       (wbd_riscv_icache_ack_o       ),
          .m3_wbd_lack_o      (wbd_riscv_icache_lack_o      ),
          .m3_wbd_err_o       (wbd_riscv_icache_err_o       ),
         
         
         // Slave 0 Interface
       // .s0_wbd_err_i       (1'b0                         ), - Moved inside IP
          .s0_mclk            (qspim_mclk                   ),
          .s0_idle            (qspim_idle                   ),
          .s0_wbd_dat_i       (wbd_spim_dat_i               ),
          .s0_wbd_ack_i       (wbd_spim_ack_i               ),
          .s0_wbd_lack_i      (wbd_spim_lack_i              ),
          .s0_wbd_dat_o       (wbd_spim_dat_o               ),
          .s0_wbd_adr_o       (wbd_spim_adr_o               ),
          .s0_wbd_bry_o       (wbd_spim_bry_o               ),
          .s0_wbd_bl_o        (wbd_spim_bl_o                ),
          .s0_wbd_sel_o       (wbd_spim_sel_o               ),
          .s0_wbd_we_o        (wbd_spim_we_o                ),  
          .s0_wbd_cyc_o       (wbd_spim_cyc_o               ),
          .s0_wbd_stb_o       (wbd_spim_stb_o               ),
         
         // Slave 1 Interface
       // .s1_wbd_err_i       (1'b0                         ), - Moved inside IP
          .s1_mclk            (uart_mclk                    ),
          .s1_wbd_dat_i       (wbd_uart_dat_i               ),
          .s1_wbd_ack_i       (wbd_uart_ack_i               ),
          .s1_wbd_dat_o       (wbd_uart_dat_o               ),
          .s1_wbd_adr_o       (wbd_uart_adr_o               ),
          .s1_wbd_sel_o       (wbd_uart_sel_o               ),
          .s1_wbd_we_o        (wbd_uart_we_o                ),  
          .s1_wbd_cyc_o       (wbd_uart_cyc_o               ),
          .s1_wbd_stb_o       (wbd_uart_stb_o               ),
         
         // Slave 2 Interface
       // .s2_wbd_err_i       (1'b0                         ), - Moved inside IP
          .s2_mclk            (pinmux_mclk                  ),
          .s2_wbd_dat_i       (wbd_pinmux_dat_i             ),
          .s2_wbd_ack_i       (wbd_pinmux_ack_i             ),
          .s2_wbd_dat_o       (wbd_pinmux_dat_o             ),
          .s2_wbd_adr_o       (wbd_pinmux_adr_o             ),
          .s2_wbd_sel_o       (wbd_pinmux_sel_o             ),
          .s2_wbd_we_o        (wbd_pinmux_we_o              ),  
          .s2_wbd_cyc_o       (wbd_pinmux_cyc_o             ),
          .s2_wbd_stb_o       (wbd_pinmux_stb_o             )


	);

//-----------------------------------------------
// uart+i2c+usb+spi
//-----------------------------------------------

uart_i2c_usb_spi_top   u_uart_i2c_usb_spi (
`ifdef USE_POWER_PINS
          .vccd1              (vccd1                        ),// User area 1 1.8V supply
          .vssd1              (vssd1                        ),// User area 1 digital ground
`endif
          .wbd_clk_int        (uart_mclk                    ), 
          .cfg_cska_uart      (cfg_wcska_uart_rp            ), 
          .wbd_clk_uart       (wbd_clk_uart_skew            ),

          .uart_rstn          (uart_rst_n                   ), // uart reset
          .i2c_rstn           (i2c_rst_n                    ), // i2c reset
          .usb_rstn           (usb_rst_n                    ), // USB reset
          .spi_rstn           (sspim_rst_n                  ), // SPI reset
          .app_clk            (wbd_clk_uart_skew            ),
          .usb_clk            (usb_clk                      ),

        // Reg Bus Interface Signal
          .reg_cs             (wbd_uart_stb_o               ),
          .reg_wr             (wbd_uart_we_o                ),
          .reg_addr           (wbd_uart_adr_o[8:0]          ),
          .reg_wdata          (wbd_uart_dat_o               ),
          .reg_be             (wbd_uart_sel_o               ),

       // Outputs
          .reg_rdata          (wbd_uart_dat_i               ),
          .reg_ack            (wbd_uart_ack_i               ),

       // Pad interface
          .scl_pad_i          (i2cm_clk_i                   ),
          .scl_pad_o          (i2cm_clk_o                   ),
          .scl_pad_oen_o      (i2cm_clk_oen                 ),

          .sda_pad_i          (i2cm_data_i                  ),
          .sda_pad_o          (i2cm_data_o                  ),
          .sda_padoen_o       (i2cm_data_oen                ),
     
          .i2cm_intr_o        (i2cm_intr_o                  ),

          .uart_rxd           (uart_rxd                     ),
          .uart_txd           (uart_txd                     ),

          .usb_in_dp          (usb_dp_i                     ),
          .usb_in_dn          (usb_dn_i                     ),

          .usb_out_dp         (usb_dp_o                     ),
          .usb_out_dn         (usb_dn_o                     ),
          .usb_out_tx_oen     (usb_oen                      ),
       
          .usb_intr_o         (usb_intr_o                   ),

      // SPIM Master
          .sspim_sck          (sspim_sck                    ), 
          .sspim_so           (sspim_so                     ),  
          .sspim_si           (sspim_si                     ),  
          .sspim_ssn          (sspim_ssn                    )  

     );

//---------------------------------------
// Pinmux
//---------------------------------------

pinmux_top u_pinmux(
`ifdef USE_POWER_PINS
          .vccd1              (vccd1                        ),// User area 1 1.8V supply
          .vssd1              (vssd1                        ),// User area 1 digital ground
`endif
        //clk skew adjust
          .cfg_cska_pinmux    (cfg_wcska_pinmux_rp          ),
          .wbd_clk_int        (pinmux_mclk                  ),
          .wbd_clk_pinmux     (wbd_clk_pinmux_skew          ),

        // System Signals
        // Inputs
          .mclk               (wbd_clk_pinmux_skew          ),
          .e_reset_n          (e_reset_n_rp                 ),
          .p_reset_n          (p_reset_n_rp                 ),
          .s_reset_n          (wbd_int_rst_n                ),

       `ifdef YCR_DBG_EN
           // -- JTAG I/F
          .riscv_trst_n       (riscv_trst_n                 ),
          .riscv_tck          (riscv_tck                    ),
          .riscv_tms          (riscv_tms                    ),
          .riscv_tdi          (riscv_tdi                    ),
          .riscv_tdo          (riscv_tdo                    ),
          .riscv_tdo_en       (riscv_tdo_en                 ),
       `endif // YCR_DBG_EN

          .cfg_strap_pad_ctrl (cfg_strap_pad_ctrl_rp        ),
          .system_strap       (system_strap_rp              ),
          .strap_sticky       (strap_sticky                 ),

          .user_clock1        (wb_clk_i                     ),
          .user_clock2        (user_clock2               ),
          .int_pll_clock      (int_pll_clock                ),
          .xtal_clk           (xtal_clk                     ),
          .cpu_clk            (cpu_clk_rp_pinmux            ),


          .rtc_clk            (rtc_clk                      ),
          .usb_clk            (usb_clk                      ),
	// Reset Control
          .cpu_core_rst_n     (cpu_core_rst_n               ),
          .cpu_intf_rst_n     (cpu_intf_rst_n               ),
          .qspim_rst_n        (qspim_rst_n                  ),
          .sspim_rst_n        (sspim_rst_n                  ),
          .uart_rst_n         (uart_rst_n                   ),
          .i2cm_rst_n         (i2c_rst_n                    ),
          .usb_rst_n          (usb_rst_n                    ),

          .cfg_riscv_ctrl     (cfg_riscv_ctrl               ),

        // Reg Bus Interface Signal
          .reg_cs             (wbd_pinmux_stb_o             ),
          .reg_wr             (wbd_pinmux_we_o              ),
          .reg_addr           (wbd_pinmux_adr_o             ),
          .reg_wdata          (wbd_pinmux_dat_o             ),
          .reg_be             (wbd_pinmux_sel_o             ),

       // Outputs
          .reg_rdata          (wbd_pinmux_dat_i             ),
          .reg_ack            (wbd_pinmux_ack_i             ),


       // Risc configuration
          .irq_lines          (irq_lines                    ),
          .soft_irq           (soft_irq                     ),
          .user_irq           (                             ),
          .usb_intr           (usb_intr_o                   ),
          .i2cm_intr          (i2cm_intr_o                  ),

       // Digital IO
          .digital_io_out     (io_out_int                   ),
          .digital_io_oen     (io_oeb_int                   ),
          .digital_io_in      (io_in                        ),

       // SFLASH I/F
          .sflash_sck         (sflash_sck                   ),
          .sflash_ss          (spi_csn                      ),
          .sflash_oen         (sflash_oen                   ),
          .sflash_do          (sflash_do                    ),
          .sflash_di          (sflash_di                    ),


       // USB I/F
          .usb_dp_o           (usb_dp_o                     ),
          .usb_dn_o           (usb_dn_o                     ),
          .usb_oen            (usb_oen                      ),
          .usb_dp_i           (usb_dp_i                     ),
          .usb_dn_i           (usb_dn_i                     ),

       // UART I/F
          .uart_txd           (uart_txd                     ),
          .uart_rxd           (uart_rxd                     ),

       // I2CM I/F
          .i2cm_clk_o         (i2cm_clk_o                   ),
          .i2cm_clk_i         (i2cm_clk_i                   ),
          .i2cm_clk_oen       (i2cm_clk_oen                 ),
          .i2cm_data_oen      (i2cm_data_oen                ),
          .i2cm_data_o        (i2cm_data_o                  ),
          .i2cm_data_i        (i2cm_data_i                  ),

       // SPI MASTER
          .spim_sck           (sspim_sck                    ),
          .spim_ssn           (sspim_ssn                    ),
          .spim_miso          (sspim_so                     ),
          .spim_mosi          (sspim_si                     ),
       
       // SPI SLAVE
          .spis_sck           (sspis_sck                    ),
          .spis_ssn           (sspis_ssn                    ),
          .spis_miso          (sspis_so                     ),
          .spis_mosi          (sspis_si                     ),

      // UART MASTER I/F
          .uartm_rxd          (uartm_rxd                    ),
          .uartm_txd          (uartm_txd                    ),


          .pulse1m_mclk       (pulse1m_mclk                 ),
     
          .pinmux_debug       (pinmux_debug                 ),
     
     
          .cfg_pll_enb        (cfg_pll_enb                  ), 
          .cfg_pll_fed_div    (cfg_pll_fed_div              ), 
          .cfg_dco_mode       (cfg_dco_mode                 ), 
          .cfg_dc_trim        (cfg_dc_trim                  ),
          .pll_ref_clk        (pll_ref_clk                  ),
     
        // Peripheral Reg Bus Interface Signal
          .reg_peri_cs        (reg_peri_cs                  ),
          .reg_peri_wr        (reg_peri_wr                  ),
          .reg_peri_addr      (reg_peri_addr                ),
          .reg_peri_wdata     (reg_peri_wdata               ),
          .reg_peri_be        (reg_peri_be                  ),

       // Outputs
          .reg_peri_rdata     (reg_peri_rdata               ),
          .reg_peri_ack       (reg_peri_ack                 ),

          .rtc_intr           (rtc_intr                     ),

          .ir_rx              (ir_rx                        ),
          .ir_tx              (ir_tx                        ),
          .ir_intr            (ir_intr                      )

   ); 

//---------------------------------------------------------
// Peripheral block
//----------------------------------------------------------

peri_top u_peri(
`ifdef USE_POWER_PINS
          .vccd1              (vccd1                        ),// User area 1 1.8V supply
          .vssd1              (vssd1                        ),// User area 1 digital ground
`endif
        //clk skew adjust
          .cfg_cska_peri           (cfg_wcska_peri_rp       ),
          .wbd_clk_int             (peri_wbclk              ),
          .wbd_clk_peri            (wbd_clk_peri_skew       ),

        // System Signals
        // Inputs
          .mclk                    (wbd_clk_peri_skew       ),
          .s_reset_n               (wbd_int_rst_n           ),

        // Peripheral Reg Bus Interface Signal
          .reg_cs                  (reg_peri_cs             ),
          .reg_wr                  (reg_peri_wr             ),
          .reg_addr                (reg_peri_addr           ),
          .reg_wdata               (reg_peri_wdata          ),
          .reg_be                  (reg_peri_be             ),

       // Outputs
          .reg_rdata               (reg_peri_rdata          ),
          .reg_ack                 (reg_peri_ack            ),

          // RTC clock domain
          .rtc_clk                 (rtc_clk                 ),
          .rtc_intr                (rtc_intr                ),

          .inc_time_s              (                        ),
          .inc_date_d              (                        ),

          .ir_rx                   (ir_rx                   ),
          .ir_tx                   (ir_tx                   ),
          .ir_intr                 (ir_intr                 ),

          .cfg_dac0_mux_sel        (cfg_dac0_mux_sel        ),
          .cfg_dac1_mux_sel        (cfg_dac1_mux_sel        ),
          .cfg_dac2_mux_sel        (cfg_dac2_mux_sel        ),
          .cfg_dac3_mux_sel        (cfg_dac3_mux_sel        )

   ); 



//------------------------------------------
// 4 x 8 bit DAC
//------------------------------------------


dac_top  u_4x8bit_dac(
`ifdef USE_POWER_PINS
          .VDDA               (vdda1                        ),
          .VSSA               (vssa1                        ),
          .VCCD               (vccd1                        ),
          .VSSD               (vssd1                        ),
`endif
          .VREFH              (analog_io[23]                ),
          .Din0               (cfg_dac0_mux_sel             ),
          .Din1               (cfg_dac1_mux_sel             ),
          .Din2               (cfg_dac2_mux_sel             ),
          .Din3               (cfg_dac3_mux_sel             ),
          .VOUT0              (analog_io[15]                ),
          .VOUT1              (analog_io[16]                ),
          .VOUT2              (analog_io[17]                ),
          .VOUT3              (analog_io[18]                )
   );

endmodule	// openframe_project_wrapper
