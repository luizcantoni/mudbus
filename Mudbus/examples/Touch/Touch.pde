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
  
  //Pick a reasonable threshold level to start with.
  Mb.R[5] = 500;  //Is V x 1000 so 5=0.5Volts
 
}

void loop()
{
  Mb.Run();
  
  //Analog inputs 0-1023
  Mb.R[3] = analogRead(A1);                   //Raw signal from sensor.
  //Photocell 5-10KOhms when light and about 200KOhms when dark.
  //Photocell to 5V and A0.  Pulldown 10KOhm resistor from A0 to Gnd.
  double Volts = double(Mb.R[3]) / 1023 * 5;
  Mb.R[4] = Volts * 1000;                     //Volts on A1 (x1000 to get digits to the right of the decimal).
  double Threshold = double(Mb.R[5]) / 1000;  //Below threshold = dark.  Above threshold = light.
    
  Mb.C[2] = Volts > Threshold;                //Indicates touch.
  
#ifdef DEBUG
  delay(1000);
  Serial.print("A1=");
  Serial.print(Mb.R[3]);
  Serial.print("  Volts=");
  Serial.print(Volts);
  Serial.print("  Threshold=");
  Serial.print(Threshold);
  Serial.print("  ");
  if(Mb.C[2]) Serial.println("Touching");
  if(!Mb.C[2]) Serial.println("Not Touching");
#endif
}

/*
Modpoll commands
  Read the registers Mb.R[3], Mb.R[4], and Mb.R[5]
    ./modpoll -m tcp -t4 -r 4 -c 3 192.168.1.8
  Read the coil Mb.C[2]
    ./modpoll -m tcp -t0 -r 3 -c 1 192.168.1.8        
*/
  
