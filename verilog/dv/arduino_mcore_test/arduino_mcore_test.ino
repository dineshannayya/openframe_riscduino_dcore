#include "common_misc.h"
#include "common_bthread.h"
#include "int_reg_map.h"


char iHexChar(char cData) {

    switch (cData) {
         case 0  : return '0';
         case 1  : return '1';
         case 2  : return '2';
         case 3  : return '3';
         case 4  : return '4';
         case 5  : return '5';
         case 6  : return '6';
         case 7  : return '7';
         case 8  : return '8';
         case 9  : return '9';
         case 10 : return 'A';
         case 11 : return 'B';
         case 12 : return 'C';
         case 13 : return 'D';
         case 14 : return 'E';
         case 15 : return 'F';
      }

     return '0';
}


  void print_message(const char *fmt,int iCnt) {
      char ch;
     // Wait for Semaphore-lock=0
     while((reg_sema_lock0 & 0x1) == 0x0);
     while(ch = *(unsigned char *)fmt) {

        while((reg_uart0_status & 0x1) == 0x1);

	    reg_uart0_txdata = ch;
        ++fmt;
     }

	 Serial.print('L');
	 Serial.print('O');
	 Serial.print('O');
	 Serial.print('P');
	 Serial.print(' ');
	 Serial.print('C');
	 Serial.print('O');
	 Serial.print('U');
	 Serial.print('N');
	 Serial.print('T');
	 Serial.print(':');
	 Serial.print(iHexChar((iCnt >> 12) & 0xF),HEX);
	 Serial.print(iHexChar((iCnt >> 8 ) & 0xF),HEX);
	 Serial.print(iHexChar((iCnt >> 4 ) & 0xF),HEX);
	 Serial.print(iHexChar(iCnt & 0xF));
	 Serial.println();

     // Release Semaphore Lock
     reg_sema_lock0 = 0x1;

    // Added nop to Semaphore to acquire by other core
    asm ("nop");
    asm ("nop");
    asm ("nop");
    asm ("nop");


  }

void setup() {
  // put your setup code here, to run once:
  if ( bthread_get_core_id() == 0 ) {
    // Remove the reset for 2nd Riscv core
    reg_glbl_cfg0 = 0x31f;
   Serial.begin(9600);
              // GLBL_CFG_MAIL_BOX used as mail box, each core update boot up handshake at 8 bit
           // bit[7:0]   - core-0
           // bit[15:8]  - core-1
           // bit[23:16] - core-2
           // bit[31:24] - core-3

        reg_glbl_mail_box = 0x1 << (bthread_get_core_id() * 8); // Start of Main 
  }
}

void loop() {
  // put your main code here, to run repeatedly:

      char ch;
      int iCnt[4];
       iCnt[0] = 0;
       iCnt[1] = 0;
       iCnt[2] = 0;
       iCnt[3] = 0;

       // Common Sub-Routine 
 
       while((reg_glbl_mail_box & 0x1) == 0x0); // wait for test start from core-0, waiting for other core

       // Core 0 thread
       while ( bthread_get_core_id() == 0 ) {
         print_message("UART command from core-0\n",iCnt[0]);
         iCnt[0]++;

       }
       // Core 1 thread
       while ( bthread_get_core_id() == 1 ) {
         print_message("UART command from core-1\n",iCnt[1]);
         iCnt[1]++;

       }
       // Core 2 thread
       while ( bthread_get_core_id() == 2 ) {
         print_message("UART command from core-2\n",iCnt[2]);
         iCnt[2]++;

       }
       // Core 3 thread
       while ( bthread_get_core_id() == 3 ) {
         print_message("UART command from core-3\n",iCnt[3]);
         iCnt[3]++;

       }
}






