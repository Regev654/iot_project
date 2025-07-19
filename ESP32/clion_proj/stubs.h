#ifndef TEMP_STUBS_H
#define TEMP_STUBS_H



#include <string>


class SerialObj
{
public:
    void printf(const std::string&){}
    void println(const std::string&){}
    void print(const std::string&){}
    size_t printf(const char *format, ...) {return 0;}
    void begin(int){}
};

void delay(int){}
unsigned long millis(){return 0;}

#define SERIAL_8N1 (-1)

class ESPclass
{
public:
    unsigned int getFreeHeap(){return 0;}
};

ESPclass ESP;

unsigned int uxTaskGetStackHighWaterMark(void *) {return 0;}

class String
{
public:
    const char* c_str(){return "";}
    String(const char *cstr = "") {}
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

void xTaskCreate(void(void*),const char*, int, void*, int, void**){};

#endif //TEMP_STUBS_H
