#pragma once
#include <string>

constexpr int HID_LOCAL_Hebrew = -1;


class EspUsbHost{
public:

    void begin(){}
    void setHIDLocal(int){}
    virtual void onKeyboardKey(uint8_t ascii, uint8_t keycode, uint8_t modifier){}
    void task(){};
};
