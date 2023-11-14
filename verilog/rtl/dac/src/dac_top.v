module dac_top (
    VOUT0,
    VOUT1,
    VOUT2,
    VOUT3,
    VREFH,
    VDDA,  // User area 1 3.3V supply
    VSSA,  // User area 1 3.3V analog ground
    VCCD,  // User area 1 1.8V Digital
    VSSD,  // User area 1 1.8V Digital ground
    Din0,
    Din1,
    Din2,
    Din3,

   SAMPLE0, // ADC-0 Sample Trigger
   SAMPLE1, // ADC-1 Sample Trigger
   SAMPLE2, // ADC-2 Sample Trigger
   SAMPLE3, // ADC-3 Sample Trigger
   
   RESULT0, // ADC-0 Result 
   RESULT1, // ADC-1 Result 
   RESULT2, // ADC-2 Result 
   RESULT3, // ADC-3 Result 
   
   PIN0,
   PIN1,
   PIN2,
   PIN3,
   
   SEL0,   // ADC/DAC-0 Selection
   SEL1,   // ADC/DAC-1 Selection
   SEL2,   // ADC/DAC-2 Selection
   SEL3  // ADC/DAC-3 Selection










);
 output VOUT0;
 output VOUT1;
 output VOUT2;
 output VOUT3;
 input VREFH;
 inout VDDA;
 inout VSSA;
 inout VCCD;
 inout VSSD;
 input [7:0] Din0;
 input [7:0] Din1;
 input [7:0] Din2;
 input [7:0] Din3;

input  SAMPLE0; // ADC-0 Sample Trigger
input  SAMPLE1; // ADC-1 Sample Trigger
input  SAMPLE2; // ADC-2 Sample Trigger
input  SAMPLE3; // ADC-3 Sample Trigger

output RESULT0; // ADC-0 Result 
output RESULT1; // ADC-1 Result 
output RESULT2; // ADC-2 Result 
output RESULT3; // ADC-3 Result 

output PIN0;
output PIN1;
output PIN2;
output PIN3;

input  SEL0;   // ADC/DAC-0 Selection
input  SEL1;   // ADC/DAC-1 Selection
input  SEL2;   // ADC/DAC-2 Selection
input  SEL3;  // ADC/DAC-3 Selection


endmodule
