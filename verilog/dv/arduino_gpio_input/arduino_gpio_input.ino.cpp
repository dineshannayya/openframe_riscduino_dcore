// Make Sure that Pull up added for Column pins
#include <Arduino.h>
const int numRows = 20;

// Defining the row and column pins
const int rowPins [numRows] = {2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21};

void setup();
void loop();
void setup() {
  // put your setup code here, to run once:
   for (int i = 0; i < numRows; i++) {
    pinMode(rowPins[i], INPUT);
  }
 
  Serial.begin(1152000);

}

void loop() {
  // put your main code here, to run repeatedly:
  //for (int row = 0; row < numRows; row++) {
  //      while(digitalRead(rowPins[row]) != LOW);
  //      Serial.print("Digital Input Pin:");
  //      Serial.write(rowPins[row]);
  //      Serial.println(" LOW");
  //}
  for (int row = 0; row < 20; row++) {
        while(digitalRead(rowPins[row]) != HIGH);
        Serial.print("Digital Input Pin:");
        Serial.print(rowPins[row]);
        Serial.println(" HIGH");
  }

  for (int row = 0; row < 20; row++) {
        while(digitalRead(rowPins[row]) != LOW);
        Serial.print("Digital Input Pin:");
        Serial.print(rowPins[row]);
        Serial.println(" LOW");
  }
}


