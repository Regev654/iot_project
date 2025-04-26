#ifndef TEMP_PRINTER_H
#define TEMP_PRINTER_H
#include "stubs.h"

class Printer
{
    HardwareSerial serial;
public:
    Printer(): serial(1)
    {};

    void setup()
    {
        serial.begin(9600, SERIAL_8N1, PRINTER_RX_PIN, PRINTER_TX_PIN);
    }

    void println(const char* str)
    {
        serial.println("");
        serial.println("");
        serial.println(str);
        serial.println("");
        serial.println("");
    }
};

#endif //TEMP_PRINTER_H
