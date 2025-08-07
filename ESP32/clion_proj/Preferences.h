#ifndef IOT_PREFERENCES_H
#define IOT_PREFERENCES_H

#include "stubs.h"

class Preferences
{
public:
    bool begin(const char*, bool){ return true; }
    void end(){}
    void putString(const char *, const char*){}
    String getString(const char *, const char*){ return ""; }
    int getInt(const char *, int){return 0;}
    bool getBool(const char *, bool){return true;}
    void putBool(const char *, bool){}
    void putInt(const char *, int){}
};

#endif //IOT_PREFERENCES_H
