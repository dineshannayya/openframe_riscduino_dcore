#include <Arduino.h>
#define int_reg_tcm            (*(volatile uint32_t*)0x0C480000)    // TCM Register
#define char_reg_tcm           (*(volatile uint8_t*)0x0C480000)    // TCM Register
#define mail_box               (*(volatile uint8_t*)0x1002003C)    // Mail Box for TB and RISCV Communication
#define uart0_txfifo_stat      (*(volatile uint32_t*)0x1001001C)  // 


#define BIST_DATA_PAT_TYPE1 0x55555555
#define BIST_DATA_PAT_TYPE2 0x33333333
#define BIST_DATA_PAT_TYPE3 0x0F0F0F0F
#define BIST_DATA_PAT_TYPE4 0x00FF00FF
#define BIST_DATA_PAT_TYPE5 0x0000FFFF
#define BIST_DATA_PAT_TYPE6 0xFFFFFFFF
#define BIST_DATA_PAT_TYPE7 0x01010101
#define BIST_DATA_PAT_TYPE8 0x00000000

bool TestStatus = true;

int hextochar(char iData);
void print_int(int iData);
void print_char(char iData);
void run_tcm_mem_check();
void setup();
void loop();
int hextochar(char iData){

switch(iData) {
case 0 : return '0';
case 1 : return '1';
case 2 : return '2';
case 3 : return '3';
case 4 : return '4';
case 5 : return '5';
case 6 : return '6';
case 7 : return '7';
case 8 : return '8';
case 9 : return '9';
case 0xA : return 'A';
case 0xB : return 'B';
case 0xC : return 'C';
case 0xD : return 'D';
case 0xE : return 'E';
case 0xF : return 'F';
}

return ' ';

}

void reg_write(volatile uint32_t *addr, uint32_t data) {

      *addr = data;
      Serial.print("A:0x");
      print_int(addr);
      Serial.print(" D:0x");
      print_int(data);
      Serial.println();


}

void reg_8bit_write(volatile uint8_t *addr, uint8_t data) {

      *addr = data;
      Serial.print("A:0x");
      print_int(addr);
      Serial.print(" D:0x");
      print_char(data);
      Serial.println();


}

void reg_read(volatile uint32_t *addr) {

uint32_t rxd_data;

      rxd_data = *addr;
      Serial.print("A:0x");
      print_int(addr);
      Serial.print(" R:0x");
      print_int(rxd_data);
      Serial.println();


}

void reg_cmp(volatile uint32_t *addr, uint32_t exp_data) {

uint32_t rxd_data;

      rxd_data = *addr;
      if(rxd_data != exp_data) { 
        TestStatus = false; 
        Serial.print("ERROR => ");
      } 
      Serial.print("A:0x");
      print_int(addr);
      Serial.print(" E:0x");
      print_int(exp_data);
      Serial.print(" R:0x");
      print_int(rxd_data);
      Serial.println();


}
void print_int(int iData) {

	   Serial.write(hextochar((iData >> 28) & 0xF));
	   Serial.write(hextochar((iData >> 24) & 0xF));
	   Serial.write(hextochar((iData >> 20) & 0xF));
	   Serial.write(hextochar((iData >> 16) & 0xF));
	   Serial.write(hextochar((iData >> 12) & 0xF));
	   Serial.write(hextochar((iData >> 8) & 0xF));
	   Serial.write(hextochar((iData >> 4) & 0xF));
	   Serial.write(hextochar((iData ) & 0xF));
  }
void print_char(char iData) {

	   Serial.write(hextochar((iData >> 4) & 0xF));
	   Serial.write(hextochar((iData ) & 0xF));
  }

void run_tcm_mem_check() {

  // put your main code here, to run repeatedly:

// Write 2K Location in 32 Bit Aligned write and Read
Serial.print("########### Testing TCM Memory in 32 Bit Aligned Write ###########");
Serial.println();

      reg_write(&int_reg_tcm       ,0x00000000);
      reg_write(&int_reg_tcm+1     ,0x00040004);
      reg_write(&int_reg_tcm+510   ,0x20402040);
      reg_write(&int_reg_tcm+511   ,0x20442044);

      reg_write(&int_reg_tcm+512    , 0x20482048);
      reg_write(&int_reg_tcm+513    , 0x20522052);
      reg_write(&int_reg_tcm+1022   , 0x40884088);
      reg_write(&int_reg_tcm+1023   , 0x40924092);

      reg_write(&int_reg_tcm+1024   , 0x40964096);
      reg_write(&int_reg_tcm+1025   , 0x41004100);
      reg_write(&int_reg_tcm+1534   , 0x61366136);
      reg_write(&int_reg_tcm+1535   , 0x61406140);

      reg_write(&int_reg_tcm+1536   , 0x61446144);
      reg_write(&int_reg_tcm+1537   , 0x61486148);
      reg_write(&int_reg_tcm+2046   , 0x81848184);
      reg_write(&int_reg_tcm+2047   , 0x81888188);

Serial.print("########### Testing TCM Memory in 32 Bit Aligned Read Back and Verify ###########");
Serial.println();
      reg_cmp(&int_reg_tcm          , 0x00000000) ;
      reg_cmp(&int_reg_tcm+1        , 0x00040004) ;
      reg_cmp(&int_reg_tcm+510      , 0x20402040) ;
      reg_cmp(&int_reg_tcm+511      , 0x20442044) ;

      reg_cmp(&int_reg_tcm+512      , 0x20482048) ;
      reg_cmp(&int_reg_tcm+513      , 0x20522052) ;
      reg_cmp(&int_reg_tcm+1022     , 0x40884088) ;
      reg_cmp(&int_reg_tcm+1023     , 0x40924092) ;

      reg_cmp(&int_reg_tcm+1024     , 0x40964096) ;
      reg_cmp(&int_reg_tcm+1025     , 0x41004100) ;
      reg_cmp(&int_reg_tcm+1534     , 0x61366136) ;
      reg_cmp(&int_reg_tcm+1535     , 0x61406140) ;

      reg_cmp(&int_reg_tcm+1536     , 0x61446144) ;
      reg_cmp(&int_reg_tcm+1537     , 0x61486148) ;
      reg_cmp(&int_reg_tcm+2046     , 0x81848184) ;
      reg_cmp(&int_reg_tcm+2047     , 0x81888188) ;

Serial.print("########### Testing TCM Memory in 8 Bit Aligned Write ###########");
Serial.println();

      reg_8bit_write(&char_reg_tcm          ,0x11);
      reg_8bit_write(&char_reg_tcm+1        ,0x22);
      reg_8bit_write(&char_reg_tcm+2        ,0x33);
      reg_8bit_write(&char_reg_tcm+3        ,0x44);

      reg_8bit_write(&char_reg_tcm+2048     ,0x55);
      reg_8bit_write(&char_reg_tcm+2048+1   ,0x66);
      reg_8bit_write(&char_reg_tcm+2048+2   ,0x77);
      reg_8bit_write(&char_reg_tcm+2048+3   ,0x88);

      reg_8bit_write(&char_reg_tcm+4096     ,0x99);
      reg_8bit_write(&char_reg_tcm+4096+1   ,0xAA);
      reg_8bit_write(&char_reg_tcm+4096+2   ,0xBB);
      reg_8bit_write(&char_reg_tcm+4096+3   ,0xCC);

      reg_8bit_write(&char_reg_tcm+6144     ,0xDD);
      reg_8bit_write(&char_reg_tcm+6144+1   ,0xEE);
      reg_8bit_write(&char_reg_tcm+6144+2   ,0xFF);
      reg_8bit_write(&char_reg_tcm+6144+3   ,0x00);


Serial.print("########### Testing TCM Memory in 32 Bit Aligned Read Back and Verify ###########");
Serial.println();
      reg_cmp(&int_reg_tcm          , 0x44332211) ;
      reg_cmp(&int_reg_tcm+512      , 0x88776655) ;
      reg_cmp(&int_reg_tcm+1024     , 0xCCBBAA99) ;
      reg_cmp(&int_reg_tcm+1536     , 0x00FFEEDD) ;

}


void setup() {
  // put your setup code here, to run once:
  Serial.begin(1152000);

  //run_tcm_mem_check(2048*4);
  run_tcm_mem_check();
  
  if(TestStatus==false) Serial.println("#### TCM MEMORY TEST FAILED ####");
  else Serial.println("#### TCM Memory TEST PASSED #####");
  // Wait for all uart char transmission
  while(!Serial.txFifoEmpty());
  mail_box = 0xff; // indication to tb
}



void loop() {

}

