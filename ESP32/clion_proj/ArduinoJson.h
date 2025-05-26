#ifndef IOT_ARDUINOJSON_H
#define IOT_ARDUINOJSON_H

class MemberProxy
{
public:
    MemberProxy& operator=(int value) {
        return *this;
    }
    MemberProxy& operator=(const std::string& value) {
        return *this;
    }


    operator int() const {
        return 0;
    }
    explicit operator std::string() const {
        return "";
    }

};

class JsonDocument
{
public:

    MemberProxy& operator[](const char* key){
        static MemberProxy proxy;
        return proxy;
    }


};

void deserializeJson(JsonDocument& a, const char* b){}

void serializeJson(JsonDocument doc, std::string& data)
{}




#endif //IOT_ARDUINOJSON_H
