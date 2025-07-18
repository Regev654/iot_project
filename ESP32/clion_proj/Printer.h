#ifndef IOT_PRINTER_H
#define IOT_PRINTER_H
#include "stubs.h"
#include "parameters.h"

class DummySerial
{
public:
    DummySerial(int uart) {}

    void begin(int baud, int config, int rxPin, int txPin)
    {
        Serial.printf("DummySerial started with baud %d on pins RX: %d, TX: %d\n", baud, rxPin, txPin);
    }

    void println(const char* str)
    {
        Serial.println(str);
    }

    void write(const uint8_t* data, size_t size)
    {
        Serial.printf("called write with data: %zu bytes\n", size);
    }
};

class Printer
{
    HardwareSerial serial;
    //DummySerial serial;
public:
    Printer(): serial(PRINTER_UART)
    {};

    void setup()
    {
        Serial.println("Printer setup started");
        serial.begin(9600, SERIAL_8N1, PRINTER_RX_PIN, PRINTER_TX_PIN);
        Serial.println("Printer setup finished");
    }

    void println(const char* str, int amount)
    {
        Serial.printf("Printing to printer %d times\n", amount);

        if(!USE_PRINTER)
        {
            Serial.println("Printer is disabled, printing to serial only");
            return;
        }
        setAlignCenter();
        setBigTest();
        setUpsideDownDirection();


        std:string msg = "\n\n----------------\n";
        for(int i = 0; i < amount; i++)
        {
            msg += str;
            msg += "\n";
            msg += "----------------\n";
        }
        msg += "\n\n";
        serial.println(msg.c_str());
        Serial.println(msg.c_str());
    }


private:



    void setBigTest()
    {
        uint8_t doubleSize[] = {0x1B, 0x21, 0x38};
        serial.write(doubleSize, sizeof(doubleSize));
    }

    void setUpsideDownDirection()
    {
        uint8_t reverse[] = {0x1B, 0x7B, 0x01};
        serial.write(reverse, sizeof(reverse));
    }

    void setAlignCenter()
    {
        uint8_t alignCenter[] = {0x1B, 0x61, 0x01};
        serial.write(alignCenter, sizeof(alignCenter));
    }


    void setAlignLeft()
    {
        uint8_t alignLeft[] = {0x1B, 0x61, 0x00};
        serial.write(alignLeft, sizeof(alignLeft));
    }

    void setNormalSize()
    {
        uint8_t normalSize[] = {0x1B, 0x21, 0x00};
        serial.write(normalSize, sizeof(normalSize));
    }
};

#endif //IOT_PRINTER_H
