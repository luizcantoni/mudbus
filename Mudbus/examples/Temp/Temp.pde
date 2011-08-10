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
  
  analogReference(EXTERNAL);                      //Power the sensor with the 3.3V supply and run a wire from there to the AREF pin.  
}

#define AREF_VOLTS 3.33

void loop()
{
  Mb.Run();
  
  //Analog inputs 0-1023
  Mb.R[6] = analogRead(A2);                       //Raw signal from sensor.
  //TMP36 analog temperature sensor 1=5V 2=Signal 3=Gnd
  //From 0.1V to 2.0V = -40 to 150 C / -40 to 302 F
  //Seems like the TMP36 needs a cap on the output or it reads 10F low.  Don't know what value cap, about the size of a tic.
  double Volts = double(Mb.R[6]) / 1023 * AREF_VOLTS;
  Mb.R[7] = Volts * 1000;                         //Volts on A2 (x1000 to get digits to the right of the decimal).
  Mb.R[8] = map(Mb.R[7], 100, 2000, -400, 1500);  //Degrees C x 10
  Mb.R[9] = map(Mb.R[7], 100, 2000, -400, 3020);  //Degrees F x 10
    
 
#ifdef DEBUG
  delay(1000);
  Serial.print("A2=");
  Serial.print(Mb.R[6]);
  Serial.print("  Volts=");
  Serial.print(Mb.R[7] / 1000);
  Serial.print("  C=");
  Serial.print(Mb.R[8] / 10);
  Serial.print("  F=");
  Serial.println(Mb.R[9] / 10);
#endif
}

/*
Modpoll commands
  Read the registers Mb.R[6], Mb.R[7], and Mb.R[8]
    ./modpoll -m tcp -t4 -r7 -c4 192.168.1.8
*/
  
