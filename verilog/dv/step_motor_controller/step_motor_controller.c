//////////////////////////////////////////////////////////////////////////////
// SPDX-FileCopyrightText: 2021, Dinesh Annayya
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
// SPDX-FileContributor: Dinesh Annayya <dinesha@opencores.org>
// //////////////////////////////////////////////////////////////////////////
#define SC_SIM_OUTPORT (0xf0000000)


#include "int_reg_map.h"
#include "common_misc.h"
#include "common_bthread.h"


void main(void)
{
    int exit;

   //printf("\nTesting Steppe Motor \n\n");

   reg_glbl_cfg0 |= 0x1F;       // Remove Reset for UART
   reg_glbl_multi_func &=0x7FFFFFFF; // Disable UART Master Bit[31] = 0
   reg_glbl_multi_func |=0x100; // Enable UART Multi func
   reg_gpio_dsel  =0x00FF; // Enable PORT A As output
   reg_uart0_ctrl = 0x07;       // Enable Uart Access {3'h0,2'b00,1'b1,1'b1,1'b1}

   //// GLBL_CFG_MAIL_BOX used as mail box, each core update boot up handshake at 8 bit
   //// bit[7:0]   - core-0
   //// bit[15:8]  - core-1
   //// bit[23:16] - core-2
   //// bit[31:24] - core-3

    reg_glbl_mail_box = 0x1 << (bthread_get_core_id() * 8); // Start of Main 

  // Configure the controller
  reg_smotor_multiplier = 0x00000001;
  reg_smotor_divider    = 0x0000000A;
  reg_smotor_period     = 0x0000000A;
  reg_smotor_config     = 0x800000FF;
  
  // Start the motor
  reg_smotor_control    = 0x80000016;
  
  // Wait end of step moving
  int data;
  do {
     data = reg_smotor_control;
  } while ((data & 0x00FFFFFF) != 0x00000000 );

  // Flag end of the test
  reg_gpio_odata  = 0x00000018; 

}
