#ifndef IOT_ARDUINOJSON_H
#define IOT_ARDUINOJSON_H

class JsonObject;


class JsonString {
public:
    JsonString(const char* p=0, bool isStatic=false){}
    JsonString(const char* p, size_t n, bool isStatic=false){}

    size_t size() const{return 0;}
    const char* c_str() const {return "";}
    bool isStatic() const {return false;}
};


class MemberProxy
{
public:
    MemberProxy& operator=(int value) {
        return *this;
    }
    MemberProxy& operator=(const std::string& value) {
        return *this;
    }


    MemberProxy& operator[](const char* key){
        static MemberProxy proxy;
        return proxy;
    }

    MemberProxy& operator[](const std::string& key){
        static MemberProxy proxy;
        return proxy;
    }

    operator int() const {
        return 0;
    }

    operator JsonObject() const;

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

class JsonVariant
{
public:

    MemberProxy& operator[](const char* key){
        static MemberProxy proxy;
        return proxy;
    }


};

class JsonPair {
public:
    JsonString key() const {return {};}
    JsonVariant value() const {return {};};
};

class JsonObject
{
public:

    MemberProxy& operator[](const char* key){
        static MemberProxy proxy;
        return proxy;
    }

    class iterator
    {
    public:
        iterator& operator++() {return *this;}

        bool operator!=(const iterator&) const {return false;}

        JsonPair& operator*() {
            static JsonPair proxy;
            return proxy;
        }
    };

    iterator begin() {
        return {};
    }

    iterator end() {
        return {};
    }

};

MemberProxy::operator JsonObject() const
{
    return {};
}

void deserializeJson(JsonDocument& a, const char* b){}

void serializeJson(JsonDocument doc, std::string& data)
{}




#endif //IOT_ARDUINOJSON_H
