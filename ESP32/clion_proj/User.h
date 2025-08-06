#ifndef IOT_USER_H
#define IOT_USER_H

#include <string>
#include <map>
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
    Item(const char* text, int maxTokens, int usedTokens)
        : max(maxTokens), text(text), used(usedTokens) {}

    Item(const char* text, const JsonVariant& data) {
        max = data["maxTokens"];
        this->text = text;
        used = data["usedTokens"];
    }

    int getLeft() const
    {
        return max - used;
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


class User
{
    std::map<std::string, Item> items;
    std::string id;
public:
    User() = default;
    explicit User(const char* data){
        JsonDocument doc;
        deserializeJson(doc, data);
        id = static_cast<std::string>(doc["ID"]);
        JsonObject itemsObj = doc["items"];
        for(auto itemObj : itemsObj)
        {
            Item item =  Item(itemObj.key().c_str(), itemObj.value());
            items[item.getText()] = item;
        }
    }

    explicit User(const string& id, int maxTokens, std::string text, int usedTokens)
        : id(id){
        items[text] = Item(text.c_str(), maxTokens, usedTokens);
    }

    explicit User(const string& id, const std::map<string, int>& itemsMap)
            : id(id){
        for(const auto& item : itemsMap)
        {
            items[item.first] = Item(item.first.c_str(),item.second, 0);
        }
    }

    std::string getId() const
    {
        return id;
    }

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
        JsonObject itemsObj = doc.createNestedObject("items");
        for(const auto& item : items)
        {
            JsonObject itemObj = itemsObj.createNestedObject(item.first.c_str());
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
