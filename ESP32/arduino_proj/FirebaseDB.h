#ifndef IOT_FIREBASEDB_H
#define IOT_FIREBASEDB_H

#include "stubs.h"
#include "secrets.h"
#include "FirebaseClient.h"
#include "ExampleFunctions.h"

#include <string>

class FirebaseDB
{
    static constexpr const char* ACTIVE_EVENT_PATH = "/LiveEvent";
    static constexpr int WIFI_CONNECT_TIMEOUT = 1000;

    SSL_CLIENT ssl_client;
    AsyncClientClass fb_client;
    UserAuth user_auth;
    FirebaseApp firebase_app;
    RealtimeDatabase database;

    std::string activeEvent;
    AsyncResult activeEventResult;
    bool isSetActiveEvent = false;
public:
    FirebaseDB()
        : fb_client(ssl_client),
        user_auth(FIREBASE_API_KEY, FIREBASE_USER_EMAIL, FIREBASE_USER_PASSWORD)

    {
    }

    void setup()
    {
        Serial.println("FirebaseDB setup");
        WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
        Serial.print("Connecting to WiFi");
        while (WiFi.status() != WL_CONNECTED)
        {
            delay(WIFI_CONNECT_TIMEOUT);
            Serial.print(".");
        }
        Serial.println("");
        Serial.printf("Connected with IP: %s\n", WiFi.localIP().toString().c_str());

        set_ssl_client_insecure_and_buffer(ssl_client);
        initializeApp(fb_client, firebase_app, getAuth(user_auth), auth_debug_print, "authTask");
        firebase_app.getApp<RealtimeDatabase>(database);
        database.url(FIREBASE_DATABASE_URL);

        Serial.println("FirebaseDB setup done");
    }

    void onTrigger()
    {
        firebase_app.loop();
        if(!firebase_app.ready())
            return;


        registerActiveEvent();
        checkAsyncResult();
    }

    bool isReady()
    {
        return !activeEvent.empty();
    }

    void waitForConnection()
    {
        Serial.println("Waiting for FirebaseDB connection");
        while (!isReady())
        {
            Serial.print(".");
            onTrigger();
            delay(100);
        }
    }

private:
    void registerActiveEvent()
    {
        if(!isSetActiveEvent) {
            database.setSSEFilters("get,put,patch");
            database.get(fb_client, ACTIVE_EVENT_PATH, activeEventResult, true);
            isSetActiveEvent = true;
        }
    }

    void checkAsyncResult()
    {
        if (!activeEventResult.isResult())
            return;

        if(activeEventResult.isError())
        {
            Serial.printf("Error task: %s, msg: %s, code: %d\n", activeEventResult.uid().c_str(), activeEventResult.error().message().c_str(), activeEventResult.error().code());
            return;
        }

        if (!activeEventResult.available())
            return;

        RealtimeDatabaseResult& stream = activeEventResult.to<RealtimeDatabaseResult>();
        activeEvent = stream.to<const char *>();
        Serial.printf("Active event updated: %s\n", activeEvent.c_str());
    }



};

#endif //IOT_FIREBASEDB_H
