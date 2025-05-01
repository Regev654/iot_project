#ifndef IOT_INTERFACES_H
#define IOT_INTERFACES_H
#include <string>

class IdListener
{
public:
    virtual void onIdReceived(const std::string& id) = 0;
    virtual void onInputError() = 0;
};

class Sensor
{
public:
    virtual void onTrigger() = 0;
};
#endif
