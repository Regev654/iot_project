#ifndef IOT_WIFICONNECTION_H
#define IOT_WIFICONNECTION_H

#include "stubs.h"
#include "secrets.h"
#include "User.h"
#include "LedIndicator.h"
#include <string>
#include <memory>

class WifiConnection
{
    static constexpr int WIFI_CONNECT_TIMEOUT = 1000;

    LedIndicator* ledIndicator;
    bool isLastConnected = true;
public:
    explicit WifiConnection(LedIndicator* ledIndicator)
            :ledIndicator(ledIndicator)
    {
    }

    void setup()
    {
        Serial.println("wifi setup");
        WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
        WiFi.setSleep(false);
        Serial.println("wifi setup done");
    }


    bool isReady()
    {
        if (WiFi.status() != WL_CONNECTED)
        {
            if(isLastConnected)
            {
                Serial.print("\nConnecting to WiFi ");
                isLastConnected = false;
            }
            ledIndicator->displayLoadingWifi();
            return false;
        }

        if (isLastConnected)
        {
            return true;
        }

        isLastConnected = true;
        ledIndicator->clear();
        Serial.printf("\nConnected with IP: %s ", WiFi.localIP().toString().c_str());
        return true;
    }

};


#endif //IOT_WIFICONNECTION_H
