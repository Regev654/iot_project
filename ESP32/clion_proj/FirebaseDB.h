#ifndef IOT_FIREBASEDB_H
#define IOT_FIREBASEDB_H

#define ENABLE_USER_AUTH
#define ENABLE_DATABASE

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
    bool hadSetup = false;
    unsigned long lastTimeTriggered = 0;
    bool isLastReady = false;
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
        Serial.println("FirebaseDB setup done");
    }

    void connectSetup()
    {
        if(hadSetup) {
            return;
        }

        Serial.println("FirebaseDB connection setup");
        set_ssl_client_insecure_and_buffer(ssl_client);
        initializeApp(fb_client, firebase_app, getAuth(user_auth), auth_debug_print, "authTask");
        firebase_app.getApp<RealtimeDatabase>(database);
        database.url(FIREBASE_DATABASE_URL);
        Serial.println("FirebaseDB connection done");
        hadSetup = true;
    }

    bool isReady()
    {
        connectSetup();
        firebaseLoop();

        if(!firebase_app.ready() )
        {
            ledIndicator->displayLoadingFirebase();
            return false;
        }

        registerActiveEvent();
        checkAsyncResult();

        if(activeEvent.empty())
        {
            ledIndicator->displayLoadingFirebase();
            return false;
        }

        notifyConnected();
        return true;
    }

    void notifyConnected()
    {
        if(isLastReady)
            return;

        ledIndicator->clear();
        Serial.println("Firebase connected");
        isLastReady = true;
    }

    void onWifiDisconnect()
    {
        if(!isLastReady)
            return;

        Serial.println("firebase disconnected due to wifi disconnection");
        isLastReady = false;
    }

    void firebaseLoop()
    {
        unsigned long before = millis();
        if(millis() - lastTimeTriggered > 100) {
            Serial.printf("before firebase loop %d\n", millis() - lastTimeTriggered);
        }
        firebase_app.loop();
        if(millis() - lastTimeTriggered > 100) {
            Serial.println("after firebase loop");
            if(millis() - before > 100) {
                Serial.printf("Firebase loop took %lu ms\n", millis() - before);
            }
        }
        lastTimeTriggered = millis();
    }

    std::unique_ptr<AsyncResult> getUser(const std::string& id)
    {
        auto databaseResult = std::make_unique<AsyncResult>();
        database.get(fb_client, getUserUrl(id).c_str(), *databaseResult, false);
        return databaseResult;
    }

    std::unique_ptr<AsyncResult> setUser(const std::string& id, const User& user)
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
            Serial.println("Registering active event finished");
        }
    }

    void checkAsyncResult()
    {
        if (!activeEventResult.isResult())
            return;

        if(activeEventResult.isError())
        {
            Serial.printf("active event, Error task: %s, msg: %s, code: %d\n", activeEventResult.uid().c_str(), activeEventResult.error().message().c_str(), activeEventResult.error().code());
            return;
        }

        if (!activeEventResult.available())
            return;
        Firebase.printf("active event, task: %s, payload: ***%s****\n", activeEventResult.uid().c_str(), activeEventResult.c_str());
        auto& stream = activeEventResult.to<RealtimeDatabaseResult>();
        if(std::string("keep-alive") == stream.event().c_str())
        {
            Serial.println("active event Keep-alive event received, skipping update");
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
