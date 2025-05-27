#ifndef IOT_FIREBASEDB_H
#define IOT_FIREBASEDB_H

#include "stubs.h"
#include "secrets.h"
#include "FirebaseClient.h"
#include "ExampleFunctions.h"
#include "User.h"
#include <string>
#include <memory>

class FirebaseDB
{
    static constexpr const char* ACTIVE_EVENT_PATH = "/LiveEvent";
    static constexpr int WIFI_CONNECT_TIMEOUT = 1000;

    LedIndicator* ledIndicator;
    SSL_CLIENT ssl_client;
    AsyncClientClass fb_client;
    UserAuth user_auth;
    FirebaseApp firebase_app;
    RealtimeDatabase database;


    std::string activeEvent;
    AsyncResult activeEventResult;
    bool isSetActiveEvent = false;
public:
    explicit FirebaseDB(LedIndicator* ledIndicator)
        :ledIndicator(ledIndicator),
        fb_client(ssl_client),
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
            ledIndicator->displayLoadingWifi();
            Serial.print(".");
        }
        ledIndicator->clear();
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
            ledIndicator->displayLoadingFirebase();
            onTrigger();
            delay(100);
        }
        ledIndicator->clear();
        Serial.println("Done waiting for FirebaseDB connection");
    }

    std::unique_ptr<AsyncResult> getUser(const std::string& id)
    {
        auto databaseResult = std::make_unique<AsyncResult>();
        database.get(fb_client, getUserUrl(id).c_str(), *databaseResult, false);
        return databaseResult;
    }

    std::unique_ptr<AsyncResult> setUser(const std::string& id, User user)
    {
        auto databaseResult = std::make_unique<AsyncResult>();
        database.set(fb_client, getUserUrl(id).c_str(), user.toObject_t(), *databaseResult);
        return databaseResult;
    }

    std::unique_ptr<AsyncResult> updateUsedTokens(const std::string& id, int amount)
    {
        auto databaseResult = std::make_unique<AsyncResult>();
        database.set<int>(fb_client, getTokensUrl(id).c_str(), amount ,*databaseResult);
        return databaseResult;
    }



private:
    void registerActiveEvent()
    {
        if(!isSetActiveEvent) {
            Serial.println("Registering active event");
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
        Firebase.printf("task: %s, payload: ***%s****\n", activeEventResult.uid().c_str(), activeEventResult.c_str());
        auto& stream = activeEventResult.to<RealtimeDatabaseResult>();
        if(std::string("keep-alive") == stream.event().c_str())
        {
            Serial.println("Keep-alive event received, skipping update");
            return;
        }
        activeEvent = stream.to<const char *>();
        if(activeEvent.empty())
        {
            Serial.println("Active event is empty, skipping update");
            return;
        }
        Serial.printf("Active event updated: %s\n", activeEvent.c_str());
    }

    std::string getUserUrl(const std::string& id) const
    {
        return "Events/" + activeEvent + "/Participants/" + id;
    }

    std::string getTokensUrl(const std::string& id) const
    {
        return getUserUrl(id) + "/usedTokens";
    }



};

#endif //IOT_FIREBASEDB_H
