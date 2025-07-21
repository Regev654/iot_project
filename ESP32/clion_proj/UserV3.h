#ifndef IOT_USERV3_H
#define IOT_USERV3_H

#include <string>
#include <map>
#include <vector>
#include "ArduinoJson.h"
#include "FirebaseClient.h"


class Item
{
    int max;
    std::string text;
    int used;
public:

    bool operator<(const Item& other) const{
        return text < other.text;
    }

    Item() : max(0), text(""), used(0) {}

    Item(const char* text, JsonVariant data) {
        max = data["maxTokens"];
        this->text = text;
        used = data["usedTokens"];
    }

    std::string getText() const
    {
        return text;
    }

    int getMax() const
    {
        return max;
    }

    int getUsed() const
    {
        return used;
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
        for(const auto& item : items)
        {
            JsonObject itemObj = doc["items"][item.first];
            itemObj["maxTokens"] = item.second.getMax();
            itemObj["usedTokens"] = item.second.getUsed();
        }
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
