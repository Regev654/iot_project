#ifndef IOT_FIREBASECLIENT_H
#define IOT_FIREBASECLIENT_H

#include <string>
#include "stubs.h"

class SSL_CLIENT{

};

void set_ssl_client_insecure_and_buffer(SSL_CLIENT ssl_client){}

class AsyncClientClass{
public:
    AsyncClientClass(SSL_CLIENT ssl_client){}
};

class UserAuth
{
public:
    explicit UserAuth(const char* api_key, const char* email, const char* password){}
};


class FirebaseApp{
public:
    template<class T>
    void getApp(T db){}
    void loop(){}
    bool ready(){return true;}
};

class FirebaseError{
public:
    String message(){return {};}
    int code(){return {};}
};

class RealtimeDatabaseResult{

public:
    template<class T>
    T& to(){
        static T a;
        return a;
    }
    String event(){return {};}
};

class AsyncResult{
public:
    bool isResult(){return true;}
    bool isError(){return false;}
    bool available(){return true;}
    size_t length(){return 0;}
    FirebaseError error(){return {};}
    String uid(){return {};}
    const char* c_str(){return "";}

    template<class T>
    T& to(){
        static T a;
        return a;
    }
};

class FirebaseClass{
public:
    size_t printf(const char *format, ...) {return 0;}
};

FirebaseClass Firebase;



class RealtimeDatabase{
public:
    void url(const char* url){}
    void setSSEFilters(const char* filters){}
    void get(AsyncClientClass aClient, const char* path, AsyncResult res, bool flag){}

    template<class T>
    void set(AsyncClientClass aClient, const char* path, T data, AsyncResult res){}


};

constexpr int WL_CONNECTED = 1;

class IPAddress{
public:
    String toString(bool includeZone = false) const {return {};}
};


class WiFiClass{
public:
    void begin(const char* ssid, const char* password){}

    int status(){return 0;}

    IPAddress localIP(){return {};}

    const char* SSID() {return "";}

    void setSleep(bool sleep) {}

};

class object_t{
public:
    object_t(const char* str){}
};
WiFiClass WiFi;

int auth_debug_print;
int getAuth(UserAuth user_auth) {return 0;}
void initializeApp(AsyncClientClass fb_client, FirebaseApp firebase_app, int auth, int auth_debug_print, const char* task_name){}




#endif //IOT_FIREBASECLIENT_H
