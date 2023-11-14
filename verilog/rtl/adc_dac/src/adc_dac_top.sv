module adc_dac_top (
    inout  logic VDDA,  // User area 1 3.3V supply
    inout  logic VSSA,  // User area 1 3.3V analog ground
    inout  logic VCCD,  // User area 1 1.8V Digital
    inout  logic VSSD,  // User area 1 1.8V Digital ground


    inout  logic VREFH, // Reference voltage for DAC
    output logic VOUT0, // DAC Output-0
    output logic VOUT1, // DAC Output-1
    output logic VOUT2, // DAC Output-2
    output logic VOUT3, // DAC Output-3

    input logic [7:0] Din0,  // DAC-0 Input
    input logic [7:0] Din1,  // DAC-1 Input
    input logic [7:0] Din2,  // DAC-2 Input
    input logic [7:0] Din3,  // DAC-3 Input

    input logic       SAMPLE0, // ADC-0 Sample Trigger
    input logic       SAMPLE1, // ADC-1 Sample Trigger
    input logic       SAMPLE2, // ADC-2 Sample Trigger
    input logic       SAMPLE3, // ADC-3 Sample Trigger

    output logic      RESULT0, // ADC-0 Result 
    output logic      RESULT1, // ADC-1 Result 
    output logic      RESULT2, // ADC-2 Result 
    output logic      RESULT3, // ADC-3 Result 

    output logic      PIN0,
    output logic      PIN1,
    output logic      PIN2,
    output logic      PIN3,

    input  logic      SEL0,   // ADC/DAC-0 Selection
    input  logic      SEL1,   // ADC/DAC-1 Selection
    input  logic      SEL2,   // ADC/DAC-2 Selection
    input  logic      SEL3   // ADC/DAC-3 Selection

   );


assign  RESULT0 = (Din0 <= 8'h11) ? 1'b1: 1'b0;
assign  RESULT1 = (Din1 <= 8'h22) ? 1'b1: 1'b0;
assign  RESULT2 = (Din2 <= 8'h33) ? 1'b1: 1'b0;
assign  RESULT3 = (Din3 <= 8'h44) ? 1'b1: 1'b0;

endmodule
