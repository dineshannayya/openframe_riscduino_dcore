// Make Sure that Pull up added for Column pins
#include <Arduino.h>
const int numRows = 23;
const int numCols = 0;

// Defining the row and column pins
const int colPins [numCols] = {};
const int rowPins [numRows] = {0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22};

void setup();
void loop();
void setup() {
  // put your setup code here, to run once:
   for (int i = 0; i < numRows; i++) {
    pinMode(rowPins[i], OUTPUT);
    digitalWrite(rowPins[i], HIGH);
  }
 

}

void loop() {
  // put your main code here, to run repeatedly:
  for (int row = 0; row < numRows; row++) {
        digitalWrite(rowPins[row], LOW);
  }
  for (int row = 0; row < numRows; row++) {
        digitalWrite(rowPins[row], HIGH);
  }


}

