//
// Created by regev on 22/05/2025.
//

#ifndef IOT_STUDENT_H
#define IOT_STUDENT_H

#include <string>
#include "ArduinoJson.h"


class User
{
    int max;
    std::string text;
    int used;
    std::string id;
public:
    explicit User(const char* data){
        JsonDocument doc;
        deserializeJson(doc, data);
        max = doc["maxTokens"];
        text = static_cast<string>(doc["textToPrint"]);
        used = doc["usedTokens"];
        id = static_cast<string>(doc["ID"]);
    }

    explicit User(const std::string& id, int maxTokens, const char* textToPrint, int usedTokens)
        : max(maxTokens), text(textToPrint), used(usedTokens), id(id)
    {}

    int getMax() const
    {
        return max;
    }

    const std::string& getText() const
    {
        return text;
    }

    int getUsed() const
    {
        return used;
    }

    void increaseUsed(int usedTokens)
    {
        used += usedTokens;
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
