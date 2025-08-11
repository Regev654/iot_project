#ifndef IOT_USERV3_H
#define IOT_USERV3_H

#include <string>
#include <map>
#include <vector>
#include "ArduinoJson.h"


class Item
{
    int max;
    std::string text;
    int used;
public:

    bool operator<(const Item& other) const{
        return text < other.text;
    }

     Item(const char* text, JsonVariant data) {
        max = data["maxTokens"];
        this->text = text;
        used = data["usedTokens"];
    }

    std::string getText() const
    {
        return text;
    }

    void increaseUsed(int usedTokens)
    {
        used += usedTokens;
    }

};


class UserV3
{
    std::map<std::string, Item> items;
    std::string id;
public:
    explicit UserV3(const char* data){
        JsonDocument doc;
        deserializeJson(doc, data);
        id = static_cast<std::string>(doc["ID"]);
        JsonObject itemsObj = doc["items"];
        for(const auto& itemObj : itemsObj)
        {
            Item item =  Item(itemObj.key().c_str(), itemObj.value());
            auto entry = std::pair<std::string, Item>(item.getText(),item);
            items[item.getText()] = item;
        }
    }

    explicit UserV3()
    {}

    const std::map<std::string, Item>& getItems() const
    {
        return items;
    }


    void increaseUsed(std::string text, int usedTokens)
    {
        items[text].increaseUsed(usedTokens);
    }

    std::string toString() const
    {
        JsonDocument doc;
        doc["ID"] = id;
        doc["maxTokens"] = max;
        doc["textToPrint"] = text;
        doc["usedTokens"] = used;
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

#endif //IOT_STUDENT_H
