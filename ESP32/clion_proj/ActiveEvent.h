#ifndef IOT_ACTIVEEVENT_H
#define IOT_ACTIVEEVENT_H

#include <string>
#include "ArduinoJson.h"
#include "FirebaseClient.h"


class ActiveEvent
{
    bool isReady = false;
    bool mHasDefaultItems = false;
    std::string id;
    std::map<string, int> defaultItems;
    JsonDocument doc;

    void fullUpdate(const char* data){
        Serial.printf("\nFull update: %s", data);
        doc = JsonDocument();
        deserializeJson(doc, data);
    }

    void updateFromJson()
    {
        id = static_cast<std::string>(doc["id"]);
        JsonObject itemsObj = doc["defaultItems"];
        mHasDefaultItems = false;
        defaultItems.clear();
        for(auto itemObj : itemsObj)
        {
            int value = itemObj.value().as<int>();
            defaultItems[itemObj.key().c_str()] = value;
            if(value > 0) {
                mHasDefaultItems = true;
            }
        }
    }

    void partialUpdate(const string path, const string value) {
        JsonDocument patch;
        deserializeJson(patch, value.c_str());

        size_t slashIndex;
        string remainingPath = path;
        if (remainingPath.find('/') == 0)
            remainingPath = path.substr(1);

        JsonVariant current = doc.as<JsonVariant>();
        while ((slashIndex = remainingPath.find('/')) != string::npos) {
            string key = remainingPath.substr(0, slashIndex);
            remainingPath = remainingPath.substr(slashIndex + 1);

            if (!current[key].is<JsonObject>()) {
                current = current.createNestedObject(key);
            } else {
                current = current[key];
            }
        }

        string finalKey = remainingPath;
        if (value == "null") {
            current.remove(finalKey);
            Serial.printf("\nRemoved key: %s", finalKey.c_str());
        } else {
            current[finalKey] = patch.as<JsonVariant>();
            Serial.printf("\nSet key: %s to value: %s", finalKey.c_str(), patch.as<std::string>().c_str());
        }
    }
public:
    ActiveEvent() = default;

    void update(const std::string path, const std::string& value)
    {
        isReady = true;
        if(path=="/")
        {
            fullUpdate(value.c_str());
        }
        else
        {
            partialUpdate(path, value);
        }
        updateFromJson();
    }


    explicit ActiveEvent(const std::string& id, const string& text, int amount)
        : id(id), defaultItems{{text, amount}}, isReady(true), mHasDefaultItems(true) {

        doc["id"] = id;
        JsonObject itemsObj = doc.createNestedObject("defaultItems");
        for (const auto& item : defaultItems) {
            itemsObj[item.first.c_str()] = item.second;
        }
    }


    bool hasDefaultItems() const
    {
        return mHasDefaultItems;
    }

    bool isEventReady() const
    {
        return isReady;
    }

    void reset()
    {
        Serial.printf("\nResetting ActiveEvent");
        isReady = false;
        mHasDefaultItems = false;
    }

    const std::string& getId() const
    {
        return id;
    }

    const std::map<string, int>& getDefaultItems() const
    {
        return defaultItems;
    }

    std::string toString() const
    {
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
