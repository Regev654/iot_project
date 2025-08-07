#ifndef IOT_PRINTER_H
#define IOT_PRINTER_H

#include <map>
#include "stubs.h"
#include "parameters.h"
#include "Settings.h"

class SerialWrapper
{
    HardwareSerial serial;
    Settings* settings;
public:
    SerialWrapper(int uart, Settings* settings):
        serial(uart),
        settings(settings)
    {}

    void begin(int baud, int config, int rxPin, int txPin)
    {
        serial.begin(baud, config, rxPin, txPin);
    }

    void println(const char* str)
    {
        if (!settings->isUsePrinter())
            return;

        serial.println(str);
    }

    void write(uint8_t* data, int size)
    {
        if (!settings->isUsePrinter())
            return;


        serial.write(data, size);
    }

    bool isActive()
    {
        return settings->isUsePrinter();
    }
};

class Printer
{
    SerialWrapper serial;
public:
    Printer(Settings* settings): serial(PRINTER_UART, settings)
    {};

    void setup()
    {
        Serial.println("Printer setup started");
        serial.begin(9600, SERIAL_8N1, PRINTER_RX_PIN, PRINTER_TX_PIN);
        Serial.println("Printer setup finished");
    }

    void printItems(const std::map<string, int>& items)
    {
        Serial.printf("\nPrinting to printer %d items", items.size());

        if(!serial.isActive())
            Serial.print("\nPrinter is disabled, printing to serial only. ");

        setAlignCenter();
        setBigTest();
        setUpsideDownDirection();


        std:string msg = "\n\n----------------\n";
        for(const auto& item : items) {
            for (int i = 0; i < item.second; i++) {
                msg += item.first;
                msg += "\n";
                msg += "----------------\n";
            }
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
