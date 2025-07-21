#ifndef IOT_WIFIMANAGER_H
#define IOT_WIFIMANAGER_H

class WiFiManager
{
public:
    bool autoConnect(const char* ssid, const char* password){return true;}
    void setAPCallback(void (*func)(WiFiManager*)) {}
    void resetSettings(){}
};

#endif //IOT_WIFIMANAGER_H
