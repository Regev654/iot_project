#ifndef IOT_ACTIVEEVENT_H
#define IOT_ACTIVEEVENT_H

#include <string>
#include "ArduinoJson.h"
#include "FirebaseClient.h"


class ActiveEvent
{
    std::string id;
    int defaultAmount;
public:
    explicit ActiveEvent(const char* data){
        JsonDocument doc;
        deserializeJson(doc, data);
        id = static_cast<std::string>(doc["id"]);
        defaultAmount = doc["defaultAmount"];
    }

    explicit ActiveEvent(const std::string& id, int defaultAmount)
        : id(id), defaultAmount(defaultAmount)
    {}

    const std::string& getId() const
    {
        return id;
    }

    int getDefaultAmount() const
    {
        return defaultAmount;
    }

    std::string toString() const
    {
        JsonDocument doc;
        doc["id"] = id;
        doc["defaultAmount"] = defaultAmount;
        std::string data;
        serializeJson(doc, data);
        return data;
    }

    object_t toObject_t() const
    {
        std::string data = toString();
        return object_t(data.c_str());
    }
};


#endif //IOT_ACTIVEEVENT_H
