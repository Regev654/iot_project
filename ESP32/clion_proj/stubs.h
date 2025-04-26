//
// Created by regev on 23/04/2025.
//

#ifndef TEMP_STUBS_H
#define TEMP_STUBS_H



#include <string>


class SerialObj
{
public:
    void printf(const std::string&){}
    void println(const std::string&){}
    void begin(int){}
};

void delay(int){}

#define SERIAL_8N1 -1

class HardwareSerial
{
public:
    explicit HardwareSerial(int uartIndex){}
    void begin(int frequency, int config, int rxPin, int txPin){}
    void println(const char* str){}
};
SerialObj Serial;



#endif //TEMP_STUBS_H
