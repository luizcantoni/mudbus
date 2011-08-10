/*
    Mudbus.cpp - an Arduino library for a Modbus TCP slave.
    Copyright (C) 2011  Dee Wykoff

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#include "Mudbus.h"

Server MbServer(MB_PORT);

Mudbus::Mudbus()
{
}

void Mudbus::Run()
{  
  Runs = 1 + Runs * (Runs < 999);

  //****************** Read from socket ****************
  Client client = MbServer.available();
  if(client.available())
  {
    Reads = 1 + Reads * (Reads < 999);
    int i = 0;
    while(client.available())
    {
      ByteArray[i] = client.read();
      i++;
    }
    SetFC(ByteArray[7]);  //Byte 7 of request is FC
    if(!Active)
    {
      Active = true;
      PreviousActivityTime = millis();
      #ifdef MbDebug
        Serial.println("Mb active");
      #endif
    }
  }
  if(millis() > (PreviousActivityTime + 60000))
  {
    if(Active)
    {
      Active = false;
      #ifdef MbDebug
        Serial.println("Mb not active");
      #endif
    }
  }
  
  int Start, WordDataLength, ByteDataLength, CoilDataLength, MessageLength;

  //****************** Read Coils **********************
  if(FC == MB_FC_READ_COILS)
  {
    Start = word(ByteArray[8],ByteArray[9]);
    CoilDataLength = word(ByteArray[10],ByteArray[11]);
    ByteDataLength = CoilDataLength / 8;
    if(ByteDataLength * 8 < CoilDataLength) ByteDataLength++;      
    CoilDataLength = ByteDataLength * 8;
    #ifdef MbDebug
      Serial.print(" MB_FC_READ_COILS S=");
      Serial.print(Start);
      Serial.print(" L=");
      Serial.println(CoilDataLength);
    #endif
    ByteArray[5] = ByteDataLength + 3; //Number of bytes after this one.
    ByteArray[8] = ByteDataLength;     //Number of bytes after this one (or number of bytes of data).
    for(int i = 0; i < ByteDataLength ; i++)
    {
      for(int j = 0; j < 8; j++)
      {
        bitWrite(ByteArray[9 + i], j, C[Start + i * 8 + j]);
      }      
    }
    MessageLength = ByteDataLength + 9;
    client.write(ByteArray, MessageLength);
    Writes = 1 + Writes * (Writes < 999);
    FC = MB_FC_NONE;
  }

  //****************** Read Registers ******************
  if(FC == MB_FC_READ_REGISTERS)
  {
    Start = word(ByteArray[8],ByteArray[9]);
    WordDataLength = word(ByteArray[10],ByteArray[11]);
    ByteDataLength = WordDataLength * 2;
    #ifdef MbDebug
      Serial.print(" MB_FC_READ_REGISTERS S=");
      Serial.print(Start);
      Serial.print(" L=");
      Serial.println(WordDataLength);
    #endif    
    ByteArray[5] = ByteDataLength + 3; //Number of bytes after this one.
    ByteArray[8] = ByteDataLength;     //Number of bytes after this one (or number of bytes of data).
    for(int i = 0; i < WordDataLength; i++)
    {
      ByteArray[ 9 + i * 2] = highByte(R[Start + i]);
      ByteArray[10 + i * 2] =  lowByte(R[Start + i]);
    }
    MessageLength = ByteDataLength + 9;
    client.write(ByteArray, MessageLength);
    Writes = 1 + Writes * (Writes < 999);
    FC = MB_FC_NONE;
  }

  //****************** Write Coil **********************
  if(FC == MB_FC_WRITE_COIL)
  {
    Start = word(ByteArray[8],ByteArray[9]);
    C[Start] = word(ByteArray[10],ByteArray[11]) > 0;
    #ifdef MbDebug
      Serial.print(" MB_FC_WRITE_COIL C");
      Serial.print(Start);
      Serial.print("=");
      Serial.println(C[Start]);
    #endif    
    ByteArray[5] = 2; //Number of bytes after this one.
    MessageLength = 8;
    client.write(ByteArray, MessageLength);
    Writes = 1 + Writes * (Writes < 999);
    FC = MB_FC_NONE;
  } 

  //****************** Write Register ******************
  if(FC == MB_FC_WRITE_REGISTER)
  {
    Start = word(ByteArray[8],ByteArray[9]);
    R[Start] = word(ByteArray[10],ByteArray[11]);
    #ifdef MbDebug
      Serial.print(" MB_FC_WRITE_REGISTER R");
      Serial.print(Start);
      Serial.print("=");
      Serial.println(R[Start]);
    #endif    
    ByteArray[5] = 2; //Number of bytes after this one.
    MessageLength = 8;
    client.write(ByteArray, MessageLength);
    Writes = 1 + Writes * (Writes < 999);
    FC = MB_FC_NONE;
  }  

  #ifdef MbDebug
    Serial.print("Mb runs: ");
    Serial.print(Runs);
    Serial.print("  reads: ");
    Serial.print(Reads);
    Serial.print("  writes: ");
    Serial.print(Writes);
    Serial.println();
  #endif
}

void Mudbus::SetFC(int fc)
{
  if(fc == 1) FC = MB_FC_READ_COILS;
  if(fc == 3) FC = MB_FC_READ_REGISTERS;
  if(fc == 5) FC = MB_FC_WRITE_COIL;
  if(fc == 6) FC = MB_FC_WRITE_REGISTER;
}
