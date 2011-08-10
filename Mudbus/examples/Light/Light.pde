#include <SPI.h>
#include <Ethernet.h>

#include "Mudbus.h"

//#define DEBUG

Mudbus Mb;
//Function codes 1(read coils), 3(read registers), 5(write coil), 6(write register)
//signed int Mb.R[0 to 125] and bool Mb.C[0 to 128] MB_N_R MB_N_C
//Port 502 (defined in Mudbus.h) MB_PORT

void setup()
{
  uint8_t mac[]     = { 0x90, 0xA2, 0xDA, 0x00, 0x51, 0x06 };
  uint8_t ip[]      = { 192, 168, 1, 8 };
  uint8_t gateway[] = { 192, 168, 1, 1 };
  uint8_t subnet[]  = { 255, 255, 255, 0 };
  Ethernet.begin(mac, ip, gateway, subnet);
  //Avoid pins 4,10,11,12,13 when using ethernet shield

  delay(5000);  //Time to open the terminal
  Serial.begin(9600);
  
  pinMode(7, OUTPUT);
  pinMode(8, OUTPUT);
 
  //Pick a reasonable threshold level to start with.
  Mb.R[2] = 1500;  //Is V x 1000 so 1500=1.5Volts
 
}

void loop()
{
  Mb.Run();
  
  //Analog inputs 0-1023
  Mb.R[0] = analogRead(A0);                   //Raw signal from sensor.
  //Photocell 5-10KOhms when light and about 200KOhms when dark.
  //Photocell to 5V and A0.  Pulldown 10KOhm resistor from A0 to Gnd.
  double Volts = double(Mb.R[0]) / 1023 * 5;
  Mb.R[1] = Volts * 1000;                     //Volts on A0 (x1000 to get digits to the right of the decimal).
  double Threshold = double(Mb.R[2]) / 1000;  //Below threshold = dark.  Above threshold = light.
    
  //Analog outputs 0-255
  int Rescaled = map(Mb.R[0], 0, 1023, 0, 255);
  analogWrite(6, Rescaled);                   //Send rescaled copy of analog input to an analog output.

  //Digital outputs
  Mb.C[0] = Volts > Threshold;
  digitalWrite(7, Mb.C[0]);                   //pin 7 indicates light.
  
  Mb.C[1] = Volts < Threshold;
  digitalWrite(8, Mb.C[1]);                   //pin 8 indicates that darkness approaches.

#ifdef DEBUG
  delay(1000);
  Serial.print("A0=");
  Serial.print(Mb.R[0]);
  Serial.print("  Volts=");
  Serial.print(Volts);
  Serial.print("  Threshold=");
  Serial.print(Threshold);
  Serial.print("  ");
  if(Mb.C[0]) Serial.println("It is light");
  if(Mb.C[1]) Serial.println("Darkness approaches");
#endif
}

/*
Modpoll commands
  Read the registers Mb.R[0], Mb.R[1], and Mb.R[2]
    ./modpoll -m tcp -t4 -r 1 -c 3 192.168.1.8
  Read the coil Mb.C[0]
    ./modpoll -m tcp -t0 -r 1 -c 1 192.168.1.8        
*/

