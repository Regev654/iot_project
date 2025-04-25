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

SerialObj Serial;



#endif //TEMP_STUBS_H
