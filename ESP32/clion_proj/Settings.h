#ifndef IOT_SETTINGS_H
#define IOT_SETTINGS_H

#include <string>
#include "Preferences.h"
#include "secrets.h"
#include "ArduinoJson.h"


class Settings
{
    constexpr static const char* SETTINGS_PATH = "iot_settings";
    constexpr static const char* KEEP_ALIVE_TIMEOUT = "keepAliveTimeout";
    constexpr static const char* REQUEST_TIMEOUT = "requestTimeout";
    constexpr static const char* WIFI_RECONNECT_TIMEOUT = "wifiReconnectTimeout";
    constexpr static const char* MAX_TOKENS_AT_ONCE = "maxTokensAtOnce";
    constexpr static const char* USE_PRINTER = "usePrinter";
    constexpr static const char* WIFI_SSID = "wifiSsid";
    constexpr static const char* WIFI_PASSWORD = "wifiPassword";


public:
    void setup()
    {
        preferences.begin(SETTINGS_PATH, false);
        requestTimeout = preferences.getInt(REQUEST_TIMEOUT, REQUEST_TIMEOUT_PARAM);
        wifiReconnectTimeout = preferences.getInt(WIFI_RECONNECT_TIMEOUT, WIFI_RECONNECT_TIMEOUT_PARAM);
        maxTokensAtOnce = preferences.getInt(MAX_TOKENS_AT_ONCE, MAX_TOKENS_AT_ONCE_PARAM);
        usePrinter = preferences.getBool(USE_PRINTER, USE_PRINTER_PARAM);
        wifiSsid = preferences.getString(WIFI_SSID, IOT_WIFI_SSID).c_str();
        wifiPassword = preferences.getString(WIFI_PASSWORD, IOT_WIFI_PASSWORD).c_str();
        keepAliveTimeout = preferences.getInt(KEEP_ALIVE_TIMEOUT, KEEP_ALIVE_TIMEOUT_PARAM);

        preferences.end();
    }

    int getRequestTimeout() const
    {
        return requestTimeout;
    }

    int getWifiReconnectTimeout() const
    {
        return wifiReconnectTimeout;
    }

    bool isUsePrinter() const
    {
        return usePrinter;
    }

    const char* getWifiSsid() const
    {
        return wifiSsid.c_str();
    }

    const char* getWifiPassword() const
    {
        return wifiPassword.c_str();
    }

    int getMaxTokensAtOnce() const
    {
        return maxTokensAtOnce;
    }

    int getKeepAliveTimeout() const
    {
        return keepAliveTimeout;
    }

    void updateSettings(const char* data)
    {
        Serial.printf("\nUpdate settings: %s", data);
        preferences.begin(SETTINGS_PATH, false);
        JsonDocument doc;
        deserializeJson(doc, data);

        requestTimeout = doc.containsKey(REQUEST_TIMEOUT) ? doc[REQUEST_TIMEOUT] : REQUEST_TIMEOUT_PARAM;
        wifiReconnectTimeout = doc.containsKey(WIFI_RECONNECT_TIMEOUT) ? doc[WIFI_RECONNECT_TIMEOUT] : WIFI_RECONNECT_TIMEOUT_PARAM;
        maxTokensAtOnce = doc.containsKey(MAX_TOKENS_AT_ONCE) ? doc[MAX_TOKENS_AT_ONCE] : MAX_TOKENS_AT_ONCE_PARAM;
        usePrinter = doc.containsKey(USE_PRINTER) ? doc[USE_PRINTER].as<bool>() : USE_PRINTER_PARAM;
        keepAliveTimeout = doc.containsKey(KEEP_ALIVE_TIMEOUT) ? doc[KEEP_ALIVE_TIMEOUT] : KEEP_ALIVE_TIMEOUT_PARAM;


        wifiSsid = doc.containsKey(WIFI_SSID) ? doc[WIFI_SSID].as<std::string>() : IOT_WIFI_SSID;
        if(wifiSsid.empty() || 32 < wifiSsid.size()) {
            Serial.printf("\nInvalid WiFi SSID, using default: %s", IOT_WIFI_SSID);
            wifiSsid = IOT_WIFI_SSID;
        }
        wifiPassword = doc.containsKey(WIFI_PASSWORD) ? doc[WIFI_PASSWORD].as<std::string>() : IOT_WIFI_PASSWORD;
        if(wifiPassword.size() < 8 || 63 < wifiPassword.size()) {
            Serial.printf("\nInvalid WiFi Password, using default: %s", IOT_WIFI_PASSWORD);
            wifiPassword = IOT_WIFI_PASSWORD;
        }
        Serial.printf("\nSettings updated: requestTimeout=%d, wifiReconnectTimeout=%d, maxTokensAtOnce=%d, wifiSsid=%s, wifiPassword=%s, usePrinter=%s",
                      requestTimeout, wifiReconnectTimeout, maxTokensAtOnce, wifiSsid.c_str(), wifiPassword.c_str(), usePrinter ? "true" : "false");

        preferences.putInt(REQUEST_TIMEOUT, requestTimeout);
        preferences.putInt(WIFI_RECONNECT_TIMEOUT, wifiReconnectTimeout);
        preferences.putInt(MAX_TOKENS_AT_ONCE, maxTokensAtOnce);
        preferences.putBool(USE_PRINTER, usePrinter);
        preferences.putString(WIFI_SSID, wifiSsid.c_str());
        preferences.putString(WIFI_PASSWORD, wifiPassword.c_str());
        preferences.putInt(KEEP_ALIVE_TIMEOUT, KEEP_ALIVE_TIMEOUT_PARAM);
        preferences.end();
    }

private:
    int requestTimeout = REQUEST_TIMEOUT_PARAM;
    int wifiReconnectTimeout = WIFI_RECONNECT_TIMEOUT_PARAM;
    int maxTokensAtOnce = MAX_TOKENS_AT_ONCE_PARAM;
    bool usePrinter = USE_PRINTER_PARAM;
    std::string wifiSsid = IOT_WIFI_SSID;
    std::string wifiPassword = IOT_WIFI_PASSWORD;
    int keepAliveTimeout = KEEP_ALIVE_TIMEOUT_PARAM;
    Preferences preferences;
};



#endif //IOT_SETTINGS_H
