#ifndef IOT_MAGNETICREADER_H
#define IOT_MAGNETICREADER_H

#include "stubs.h"
#include "EspUsbHost.h"
#include "Interfaces.h"
#include <string>
using std::string;

class MagneticReader : public EspUsbHost, public Sensor
{
    IdListener* idListener = nullptr;
    const int ID_LENGTH = 9;
    const int PREFIX_LENGTH = 2;
    string currentId;

public:
    explicit MagneticReader(IdListener* listener) :
        EspUsbHost(),
        idListener(listener)
    {
        currentId = "";
    }

    void setUp()
    {
        Serial.println("Magnetic reader setup started");
        begin();
        setHIDLocal(HID_LOCAL_Hebrew);
        Serial.println("Magnetic reader setup finished");
    }

    void onTrigger() override
    {
        task();
    }

    void onKeyboardKey(uint8_t ascii, uint8_t keycode, uint8_t modifier) override {
        if (' ' <= ascii && ascii <= '~') {
            currentId += static_cast<char>(ascii);
        } else if (ascii == '\r') {
            processCurrentId();
            currentId = "";
        }
    };

    void processCurrentId()
    {
        if(currentId.size() < PREFIX_LENGTH + ID_LENGTH || currentId[0] != '@' || currentId[1] != '%')
        {
            idListener->onInputError();
            return;
        }

        currentId = currentId.substr(PREFIX_LENGTH, ID_LENGTH);
        idListener->onIdReceived(currentId);
    }

};

#endif
