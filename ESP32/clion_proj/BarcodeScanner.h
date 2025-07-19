#ifndef IOT_BARCODESCANNER_H
#define IOT_BARCODESCANNER_H

#include "stubs.h"
#include "Interfaces.h"
#include "parameters.h"

class BarcodeScanner : public Sensor
{
    static constexpr int ID_LENGTH = 9;
    HardwareSerial serial;
    IdListener* idListener = nullptr;
    bool ignoredFirstError = false;

public:
    explicit BarcodeScanner(IdListener* listener):
        serial(BARCODE_UART),
        idListener(listener)
    {};

    void setup()
    {
        Serial.println("Barcode scanner setup started");
        serial.begin(9600, SERIAL_8N1, BARCODE_TX_PIN, BARCODE_RX_PIN);
        Serial.println("Barcode scanner setup finished");
    }

    void onTrigger() override
    {
        if (!serial.available()) {
            return;
        }

        std::string id = serial.readStringUntil('\r').c_str();
        if(id.length() != ID_LENGTH)
        {
            if(!ignoredFirstError)
            {
                ignoredFirstError = true;
                Serial.printf("\nbarcode scanner: ignoring first error. len: %d, data: %s ", id.length(), id.c_str());
                return;
            }

            Serial.printf("\nbarcode scanner: Invalid ID length. len:, data %s ", id.length(), id.c_str());
            idListener->onInputError();
            return;
        }

        idListener->onIdReceived(id);
    }
};


#endif //IOT_BARCODESCANNER_H
