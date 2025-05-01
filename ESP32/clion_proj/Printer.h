#ifndef IOT_PRINTER_H
#define IOT_PRINTER_H
#include "stubs.h"
#include "parameters.h"

class Printer
{
    HardwareSerial serial;
public:
    Printer(): serial(PRINTER_UART)
    {};

    void setup()
    {
        Serial.println("Printer setup started");
        serial.begin(9600, SERIAL_8N1, PRINTER_RX_PIN, PRINTER_TX_PIN);
        Serial.println("Printer setup finished");
    }

    void println(const char* str)
    {
        if(!USE_PRINTER)
        {
            Serial.println("Printer is disabled, printing to serial");
            Serial.println(str);
            return;
        }

        serial.println("");
        serial.println("");
        serial.println(str);
        serial.println("");
        serial.println("");
    }
};

#endif //IOT_PRINTER_H
