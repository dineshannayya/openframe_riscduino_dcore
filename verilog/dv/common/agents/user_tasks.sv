
`ifndef DISABLE_SSPIM

`define SPIM_REG_WRITE          `TB_TOP.u_bfm_spim.reg_wr_dword              // Reg Write
`define SPIM_REG_BE_WRITE       `TB_TOP.u_bfm_spim.reg_be_wr_dword           // Reg Write with Byte Enable
`define SPIM_REG_READ           `TB_TOP.u_bfm_spim.reg_rd_dword              // Reg Read
`define SPIM_REG_CHECK          `TB_TOP.u_bfm_spim.reg_rd_dword_cmp          // Reg Read and compare
`define SPIM_REG_MASK_CHECK     `TB_TOP.u_bfm_spim.reg_rd_dword_mask_cmp     // Reg Read , Mask and compare
`define SPIM_REG_READ_RWAIT     `TB_TOP.u_bfm_spim.reg_rd_dword_rwait        // Reg Read with readback wait
`define SPIM_REG_CHECK_RWAIT    `TB_TOP.u_bfm_spim.reg_rd_dword_cmp_rwait    // Reg Read and compare with readback wait

`endif

/***********************************************

wire  [15:0]    strap_in;
assign strap_in[`PSTRAP_CLK_SRC] = 2'b00;            // System Clock Source wbs/riscv: User clock1
assign strap_in[`PSTRAP_CLK_DIV] = 2'b00;            // Clock Division for wbs/riscv : 0 Div
assign strap_in[`PSTRAP_UARTM_CFG] = 1'b0;           // uart master config control -  constant value based on system clock selection
assign strap_in[`PSTRAP_QSPI_SRAM] = 1'b1;           // QSPI SRAM Mode Selection - Quad 
assign strap_in[`PSTRAP_QSPI_FLASH] = 2'b10;         // QSPI Fash Mode Selection - Quad
assign strap_in[`PSTRAP_RISCV_RESET_MODE] = 1'b1;    // Riscv Reset control - Removed Riscv on Power On Reset
assign strap_in[`PSTRAP_RISCV_CACHE_BYPASS] = 1'b0;  // Riscv Cache Bypass: 0 - Cache Enable
assign strap_in[`PSTRAP_RISCV_SRAM_CLK_EDGE] = 1'b0; // Riscv SRAM clock edge selection: 0 - Normal

assign strap_in[`PSTRAP_DEFAULT_VALUE] = 1'b0;       // 0 - Normal
parameter bit  [15:0] PAD_STRAP = (2'b00 << `PSTRAP_CLK_SRC             ) |
                                  (2'b00 << `PSTRAP_CLK_DIV             ) |
                                  (1'b1  << `PSTRAP_UARTM_CFG           ) |
                                  (1'b1  << `PSTRAP_QSPI_SRAM           ) |
                                  (2'b10 << `PSTRAP_QSPI_FLASH          ) |
                                  (1'b1  << `PSTRAP_RISCV_RESET_MODE    ) |
                                  (1'b1  << `PSTRAP_RISCV_CACHE_BYPASS  ) |
                                  (1'b1  << `PSTRAP_RISCV_SRAM_CLK_EDGE ) |
                                  (2'b00 << `PSTRAP_CLK_SKEW            ) |
                                  (1'b0  << `PSTRAP_DEFAULT_VALUE       ) ;
****/

//--------------------------------------------------------
// Pad Pull-up/down initialization based on Boot Mode
//---------------------------------------------------------

`ifdef RISC_BOOT // RISCV Based Test case
parameter bit  [7:0] PAD_STRAP = 8'b0011_0100;
`else
parameter bit  [7:0] PAD_STRAP = 8'b0001_0100;
`endif

//-------------------------------------------------------------
// Variable Decleration
//-------------------------------------------------------------

reg            clock         ;
reg            clock2        ;
reg            xtal_clk      ;
wire           wb_rst_i      ;

reg            power1, power2;
reg            power3, power4;


// User I/O
wire [43:0]    io_oeb        ;
wire [43:0]    io_out        ;
wire [43:0]    io_in         ;

reg            test_fail     ;
reg [31:0]     write_data    ;
reg [31:0]     read_data     ;
integer        d_risc_id     ;
wire          rst_n;

wire USER_VDD1V8 = 1'b1;
wire VSS = 1'b0;

//-----------------------------------------
// Clock Decleration
//-----------------------------------------

always #(CLK1_PERIOD/2) clock  <= (clock === 1'b0);
always #(CLK2_PERIOD/2) clock2 <= (clock2 === 1'b0);
always #(XTAL_PERIOD/2) xtal_clk <= (xtal_clk === 1'b0);


assign io_in[41] = clock;
assign io_in[42] = clock2;

`ifndef GPIO_TEST
assign io_in[14] = xtal_clk;
`endif

//-----------------------------------------
// Variable Initiatlization
//-----------------------------------------
initial
begin
   // Run in Fast Sim Mode
   `ifdef GL
       // Note During wb_host resynth this FF is changes,
       // Keep cross-check during Gate Sim - u_reg.cfg_glb_ctrl[8]
       force u_top.u_wb_host._10252_.Q= 1'b1; 
       //force u_top.u_wb_host.u_reg.u_fastsim_buf.u_buf.X = 1'b1; 
       //force u_top.u_wb_host.u_reg.cfg_fast_sim = 1'b1; 
   `else
       force u_top.u_wb_host.u_reg.u_fastsim_buf.X = 1'b1; 
    `endif

    clock = 0;
    clock2 = 0;
    xtal_clk = 0;
    test_fail = 0;
end


	//-----------------------------------------------------------------
	// Since this is regression, reset will be applied multiple time
	// Reset logic
	// ----------------------------------------------------------------
    event	      reinit_event;
	bit [1:0]     rst_cnt;
    bit           rst_init;


    assign rst_n = &rst_cnt;
        
    always_ff @(posedge clock) begin
	if (rst_init)   begin
	     rst_cnt <= '0;
	     -> reinit_event;
	end
            else if (~&rst_cnt) rst_cnt <= rst_cnt + 1'b1;
    end

    assign wb_rst_i = !rst_n;

//--------------------------------------------------------
// Apply Reset Sequence and wait for reset completion
//-------------------------------------------------------

task init;
begin
   //#1 - Apply Reset
   rst_init = 1; 
   repeat (10) @(posedge clock);
   #100 rst_init = 0; 

   //#3 - Remove Reset
   wait(rst_n == 1'b1);

   repeat (10) @(posedge clock);
   //#4 - Wait for Power on reset removal
   wait(u_top.p_reset_n == 1);          

   // #5 - Wait for system reset removal
   wait(u_top.s_reset_n == 1);          // Wait for system reset removal
   repeat (10) @(posedge clock);

  end
endtask

//-----------------------------------------------
// Apply user defined strap at power-on
//-----------------------------------------------

task        apply_strap;
input [7:0] strap;
begin
   repeat (10) @(posedge clock);
   //#1 - Apply Reset
   rst_init = 1; 
   force u_top.gpio_in[43] = strap[7];
   force u_top.gpio_in[38] = strap[6];
   force u_top.gpio_in[37] = strap[5];
   force u_top.gpio_in[36] = strap[4];
   force u_top.gpio_in[35] = strap[3];
   force u_top.gpio_in[34] = strap[2];
   force u_top.gpio_in[33] = strap[1];
   force u_top.gpio_in[32]  = strap[0];
   repeat (10) @(posedge clock);
    
   //#3 - Remove Reset
   rst_init = 0; // Remove Reset

   //#4 - Wait for Power on reset removal
   wait(u_top.p_reset_n == 1);          

   // #5 - Release the Strap
   release u_top.gpio_in[43] ;
   release u_top.gpio_in[38] ;
   release u_top.gpio_in[37] ;
   release u_top.gpio_in[36] ;
   release u_top.gpio_in[35] ;
   release u_top.gpio_in[34] ;
   release u_top.gpio_in[33] ;
   release u_top.gpio_in[32]  ;

   // #6 - Wait for system reset removal
   wait(u_top.s_reset_n == 1);          // Wait for system reset removal
   repeat (10) @(posedge clock);


end
endtask

//---------------------------------------------------------
// Create Pull Up/Down Based on Reset Strap Parameter
// System strap are in io_in[13] to [20] and 29 to [36]
//---------------------------------------------------------
genvar gCnt;
generate
    if(PAD_STRAP[0]) begin
        pullup(io_in[32]); 
    end else begin
        pulldown(io_in[32]); 
    end

    if(PAD_STRAP[1]) begin
        pullup(io_in[33]); 
    end else begin
        pulldown(io_in[33]); 
    end
    if(PAD_STRAP[2]) begin
        pullup(io_in[34]); 
    end else begin
        pulldown(io_in[34]); 
    end
    if(PAD_STRAP[3]) begin
        pullup(io_in[35]); 
    end else begin
        pulldown(io_in[35]); 
    end
    if(PAD_STRAP[4]) begin
        pullup(io_in[36]); 
    end else begin
        pulldown(io_in[36]); 
    end
    if(PAD_STRAP[5]) begin
        pullup(io_in[37]); 
    end else begin
        pulldown(io_in[37]); 
    end
    if(PAD_STRAP[6]) begin
        pullup(io_in[38]); 
    end else begin
        pulldown(io_in[38]); 
    end
    if(PAD_STRAP[7]) begin
        pullup(io_in[43]); 
    end else begin
        pulldown(io_in[43]); 
    end
endgenerate

`ifdef GL

 // Add Non Strap with pull-up to avoid unkown propagation during gate sim 
 pullup(io_in[0]); 
 pullup(io_in[1]); 
 pullup(io_in[2]); 
 pullup(io_in[3]); 
 pullup(io_in[4]); 
 pullup(io_in[5]); 
 pullup(io_in[6]); 
 pullup(io_in[8]); 
 pullup(io_in[9]); 
 pullup(io_in[10]); 
 pullup(io_in[11]); 
 pullup(io_in[12]); 
 pullup(io_in[14]); 
 pullup(io_in[15]); 
 pullup(io_in[16]); 
 pullup(io_in[17]); 
 pullup(io_in[18]); 
 pullup(io_in[19]); 
 pullup(io_in[20]); 
 pullup(io_in[21]); 
 pullup(io_in[22]); 
 pullup(io_in[23]); 
 pullup(io_in[24]); 
 pullup(io_in[25]); 
 pullup(io_in[26]); 
 pullup(io_in[27]); 
 pullup(io_in[28]); 
 pullup(io_in[29]); 
 pullup(io_in[30]); 
 pullup(io_in[31]); 
 pullup(io_in[39]); 
 pullup(io_in[40]); 
 pullup(io_in[41]); 
 pullup(io_in[42]); 

`endif

//-----------------------------------------
// DUT Instatiation
//-----------------------------------------
openframe_project_wrapper u_top(
`ifdef USE_POWER_PINS
    .vccd1(USER_VDD1V8),	// User area 1 1.8V supply
    .vssd1(VSS)	// User area 1 digital ground
`endif
    /* Signals exported from the frame area to the user project */
    /* The user may elect to use any of these inputs.		*/

    .porb_h     (),	// power-on reset, sense inverted, 3.3V domain
    .porb_l     (rst_n),	// power-on reset, sense inverted, 1.8V domain
    .por_l      (),	// power-on reset, noninverted, 1.8V domain
    .resetb_h   (),	// master reset, sense inverted, 3.3V domain
    .resetb_l   (),	// master reset, sense inverted, 1.8V domain
    .mask_rev   (),	// 32-bit user ID, 1.8V domain

    /* GPIOs.  There are 44 GPIOs (19 left, 19 right, 6 bottom). */
    /* These must be configured appropriately by the user project. */

    /* Basic bidirectional I/O.  Input gpio_in_h is in the 3.3V domain;  all
     * others are in the 1.8v domain.  OEB is output enable, sense inverted.
     */
    .gpio_in      (io_in),
    .gpio_in_h    (),
    .gpio_out     (io_out),
    .gpio_oeb     (io_oeb),
    .gpio_inp_dis (),	// a.k.a. ieb

    /* Pad configuration.  These signals are usually static values.
     * See the documentation for the sky130_fd_io__gpiov2 cell signals
     * and their use.
     */
    .gpio_ib_mode_sel  (),
    .gpio_vtrip_sel    (),
    .gpio_slow_sel     (),
    .gpio_holdover     (),
    .gpio_analog_en    (),
    .gpio_analog_sel   (),
    .gpio_analog_pol   (),
    .gpio_dm2          (),
    .gpio_dm1          (),
    .gpio_dm0          (),

    /* These signals correct directly to the pad.  Pads using analog I/O
     * connections should keep the digital input and output buffers turned
     * off.  Both signals connect to the same pad.  The "noesd" signal
     * is a direct connection to the pad;  the other signal connects through
     * a series resistor which gives it minimal ESD protection.  Both signals
     * have basic over- and under-voltage protection at the pad.  These
     * signals may be expected to attenuate heavily above 50MHz.
     */
    .analog_io        (),
    .analog_noesd_io  (),

    /* These signals are constant one and zero in the 1.8V domain, one for
     * each GPIO pad, and can be looped back to the control signals on the
     * same GPIO pad to set a static configuration at power-up.
     */
    .gpio_loopback_one (),
    .gpio_loopback_zero()
);

`ifndef DISABLE_SSPIM
//--------------------------------------------------
// SPI Slave to Manage the boot up configuration
//--------------------------------------------------
// SCLK
wire     sclk;
wire     ssn;
wire     sdi;
wire     sdo;
wire     sd_oen;


assign io_in[22] = 1'b0;
assign io_in[13] = (io_oeb[13] == 1'b1) ? sclk : 1'b0;
assign io_in[12] = (io_oeb[12] == 1'b1) ? sdi  : 1'b0;
assign sdo       = (io_oeb[11] == 1'b0) ? io_out[11] : 1'b0;

bfm_spim  u_bfm_spim (
          // SPI
                .spi_clk     (sclk         ),
                .spi_sel_n   (ssn          ),
                .spi_din     (sdi          ),
                .spi_dout    (sdo          )

                );



`else
  assign io_in[22] = 1'b1;
`endif

`ifndef  DISABLE_SSPIM

`ifdef RISC_BOOT // RISCV Based Test case
//-------------------------------------------
task wait_riscv_boot;
begin
   // GLBL_CFG_MAIL_BOX used as mail box, each core update boot up handshake at 8 bit
   // bit[7:0]  - core-0
   // bit[15:8]  - core-1
   // bit[23:16] - core-2
   // bit[31:24] - core-3
   $display("Status:  Waiting for RISCV Core Boot ... ");
   read_data = 0;
   //while((read_data >> (d_risc_id*8)) != 8'h1) begin
   while(read_data  != 8'h1) begin // Temp fix - Hardcoded to risc_id = 0
       `SPIM_REG_READ(`ADDR_SPACE_GLBL+`GLBL_CFG_MAIL_BOX,read_data);
	    repeat (100) @(posedge clock);
   end

   $display("Status:  RISCV Core is Booted ");

end
endtask

task wait_riscv_exit;
begin
   // GLBL_CFG_MAIL_BOX used as mail box, each core update boot up handshake at 8 bit
   // bit[7:0]  - core-0
   // bit[15:8]  - core-1
   // bit[23:16] - core-2
   // bit[31:24] - core-3
   $display("Status:  Waiting for RISCV Core Boot ... ");
   read_data = 0;
   //while((read_data >> (d_risc_id*8)) != 8'hFF) begin
   while(read_data != 8'hFF) begin
       `SPIM_REG_READ(`ADDR_SPACE_GLBL+`GLBL_CFG_MAIL_BOX,read_data);
	    repeat (1000) @(posedge clock);
   end

   $display("Status:  RISCV Core is Booted ");

end
endtask

//-----------------------
// Set TB ready indication
//-----------------------
task set_tb_ready;
begin
   // GLBL_CFG_MAIL_BOX used as mail box, each core update boot up handshake at 8 bit
   // bit[7:0]  - core-0
   // bit[15:8]  - core-1
   // bit[23:16] - core-2
   // bit[31:24] - core-3
   `SPIM_REG_WRITE(`ADDR_SPACE_GLBL+`GLBL_CFG_MAIL_BOX,32'h81818181);

   $display("Status:  Set TB Ready Indication");

end
endtask

`endif

`endif


 /*************************************************************************
 * This is Baud Rate to clock divider conversion for Test Bench
 * Note: DUT uses 16x baud clock, where are test bench uses directly
 * baud clock, Due to 16x Baud clock requirement at RTL, there will be
 * some resolution loss, we expect at lower baud rate this resolution
 * loss will be less. For Quick simulation perpose higher baud rate used
 * *************************************************************************/
 task tb_set_uart_baud;
 input [31:0] ref_clk;
 input [31:0] baud_rate;
 output [31:0] baud_div;
 reg   [31:0] baud_div;
 begin
// for 230400 Baud = (50Mhz/230400) = 216.7
baud_div = ref_clk/baud_rate; // Get the Bit Baud rate
// Baud 16x = 216/16 = 13
    baud_div = baud_div/16; // To find the RTL baud 16x div value to find similar resolution loss in test bench
// Test bench baud clock , 16x of above value
// 13 * 16 = 208,  
// (Note if you see original value was 216, now it's 208 )
    baud_div = baud_div * 16;
// Test bench half cycle counter to toggle it 
// 208/2 = 104
     baud_div = baud_div/2;
//As counter run's from 0 , substract from 1
 baud_div = baud_div-1;
 end
 endtask
 
/*************************************************************************
 * This is I2C Prescale value computation logic
 * Note: from I2c Logic 3 Prescale value SCL = 0, and 2 Prescale value SCL=1
 *       Filtering logic uses two sample of Precale/4-1 period.
 *       I2C Clock = System Clock / ((5*(Prescale-1)) + (2 * ((Prescale/4)-1)))
 *   for 50Mhz system clock, 400Khz I2C clock
 *       400,000 =  50,000,000 * (5*(Prescale-1) + 2*(Prescale/4+1)+2)
 *      5*Prescale -5 + 2*Prescale/4 + 2 + 2= 50,000,000/400,000
 *      5*prescale -5 + Prescale/2 + 4 = 125
 *      (10*prescale+Prescale)/2 - 1 = 125
 *      (11 *Prescale)/2 = 125+1
 *      Prescale = 126*2/11

 * *************************************************************************/
 task tb_set_i2c_prescale;
 input [31:0] ref_clk;
 input [31:0] rate;
 output [15:0] prescale;
 reg   [15:0] prescale;
 begin 
   prescale   = ref_clk/rate; 
   prescale = prescale +1; 
   prescale = (prescale *2)/11; 
 end
 endtask

/**
`ifdef GL
//-----------------------------------------------------------------------------
// RISC IMEM amd DMEM Monitoring TASK
//-----------------------------------------------------------------------------

`define RISC_CORE  user_uart_tb.u_top.u_core.u_riscv_top

always@(posedge `RISC_CORE.wb_clk) begin
    if(`RISC_CORE.wbd_imem_ack_i)
          $display("RISCV-DEBUG => IMEM ADDRESS: %x Read Data : %x", `RISC_CORE.wbd_imem_adr_o,`RISC_CORE.wbd_imem_dat_i);
    if(`RISC_CORE.wbd_dmem_ack_i && `RISC_CORE.wbd_dmem_we_o)
          $display("RISCV-DEBUG => DMEM ADDRESS: %x Write Data: %x Resonse: %x", `RISC_CORE.wbd_dmem_adr_o,`RISC_CORE.wbd_dmem_dat_o);
    if(`RISC_CORE.wbd_dmem_ack_i && !`RISC_CORE.wbd_dmem_we_o)
          $display("RISCV-DEBUG => DMEM ADDRESS: %x READ Data : %x Resonse: %x", `RISC_CORE.wbd_dmem_adr_o,`RISC_CORE.wbd_dmem_dat_i);
end

`endif
**/

