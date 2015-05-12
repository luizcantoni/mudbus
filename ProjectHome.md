A minimal Modbus TCP slave for Arduino.  It has function codes 1(read coils), 3(read registers), 5(write coil), and 6(write register).  It is set up to use as a library, so the Modbus related stuff is separate from the main sketch.  The register and coil data is held as Mb.R[0-125] signed int and Mb.C[0-128] bool

Martin Pettersson Has furnished some changes for compatibility with Arduino 1.0.  He also has a git repository at http://gitorious.org/mudbus and a website at http://siamect.com/test3/

I received a request to put up a few links here to more recent versions and ports of this project.
https://github.com/emmertex/Modbus-Library which apparently is for PIC24
