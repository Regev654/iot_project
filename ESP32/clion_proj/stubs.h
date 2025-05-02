#ifndef TEMP_STUBS_H
#define TEMP_STUBS_H



#include <string>


class SerialObj
{
public:
    void printf(const std::string&){}
    void println(const std::string&){}
    size_t printf(const char *format, ...) {return 0;}
    void begin(int){}
};

void delay(int){}

#define SERIAL_8N1 (-1)

class String
{
public:
    const char* c_str(){return "";}
};

class HardwareSerial
{
public:
    explicit HardwareSerial(int uartIndex){}
    void begin(int frequency, int config, int rxPin, int txPin){}
    void println(const char* str){}
    bool available(){return true;}
    String readStringUntil(char c){ return {}; }
    void write(uint8_t* byte, int size){}
};

SerialObj Serial;



#endif //TEMP_STUBS_H
