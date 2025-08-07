#ifndef IOT_WIFICONNECTION_H
#define IOT_WIFICONNECTION_H

#include "stubs.h"
#include "secrets.h"
#include "User.h"
#include "LedIndicator.h"
#include <string>
#include <memory>
#include "WiFiManager.h"

using WiFiManagerCallback = void (*)(WiFiManager*);
class WifiConnection
{
    LedIndicator* ledIndicator;
    bool isLastConnected = true;
    bool hasFirstSetup = false;
    WiFiManagerCallback callback;
    int firstDisconnected = 0;
    Settings* settings;

public:
    explicit WifiConnection(LedIndicator* ledIndicator, WiFiManagerCallback callback, Settings* settings)
            :ledIndicator(ledIndicator), callback(callback), settings(settings)
    {
    }

    void setup()
    {
        Serial.println("wifi setup");
        Serial.println("wifi setup done");
    }

    void firstConnection()
    {
        bool shouldReconnect = !hasFirstSetup || millis() - firstDisconnected > settings->getWifiReconnectTimeout();
        if(!shouldReconnect && hasFirstSetup)
            return;

        hasFirstSetup = true;
        WiFiManager wm;
        wm.setAPCallback(callback);
        Serial.println("\nconnecting using wifiManager");
        if (!wm.autoConnect(settings->getWifiSsid(), settings->getWifiPassword())) {
            Serial.println("\nFailed to connect, restarting");
            ESP.restart();
        }
        WiFi.setSleep(false);
    }

    bool isReady()
    {
        if (WiFi.status() != WL_CONNECTED)
        {
            if(isLastConnected)
            {
                Serial.print("\nConnecting to WiFi. ");
                firstDisconnected = millis();
                isLastConnected = false;
            }
            ledIndicator->displayLoadingWifi();
            firstConnection();
            return false;
        }

        if (isLastConnected)
        {
            return true;
        }

        isLastConnected = true;
        ledIndicator->clear();
        Serial.printf("\nConnected with IP: %s. ", WiFi.localIP().toString().c_str());
        return true;
    }

};


#endif //IOT_WIFICONNECTION_H
