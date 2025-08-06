#ifndef IOT_FIREBASEDB_H
#define IOT_FIREBASEDB_H

#define ENABLE_USER_AUTH
#define ENABLE_DATABASE

#include "stubs.h"
#include "secrets.h"
#include "FirebaseClient.h"
#include "ExampleFunctions.h"
#include "User.h"
#include "IAsyncResult.h"
#include <string>
#include <memory>
#include "IFirebaseDB.h"
#include "ActiveEvent.h"


class FirebaseDB : public IFirebaseDB
{
    static constexpr const char* ACTIVE_EVENT_PATH = "/LiveEventV3";

    LedIndicator* ledIndicator;
    SSL_CLIENT ssl_client;
    AsyncClientClass fb_client;
    UserAuth user_auth;
    FirebaseApp firebase_app;
    RealtimeDatabase database;


    ActiveEvent activeEvent;
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

    void setup() override
    {
        Serial.println("FirebaseDB setup");
        Serial.println("FirebaseDB setup done");
    }

    bool isReady() override
    {
        connectSetup();

        if(!firebase_app.ready() ||  !activeEvent.isEventReady()) {
            ledIndicator->displayLoadingFirebase();
        }

        firebaseLoop();

        if(!firebase_app.ready() )
        {
            return false;
        }

        registerActiveEvent();
        checkAsyncResult();

        if(!activeEvent.isEventReady())
        {
            return false;
        }

        notifyConnected();
        return true;
    }

    void onWifiDisconnect() override
    {
        if(!isLastReady)
            return;

        Serial.print("\nfirebase disconnected due to wifi disconnection. ");
        isLastReady = false;
        activeEvent.reset();

    }

    bool hasDefaultItems() const override
    {
        return activeEvent.hasDefaultItems();
    }

    const std::map<std::string, int>& getDefaultItems() const override
    {
        return activeEvent.getDefaultItems();
    }

    std::unique_ptr<IAsyncResult> getUser(const std::string& id) override
    {
        auto databaseResult = std::make_unique<AsyncResultWrap>();
        database.get(fb_client, getUserUrl(id).c_str(), databaseResult->getInternal(), false);
        return databaseResult;
    }

    std::unique_ptr<IAsyncResult> updateUserStats(const User& user) override
    {
        auto databaseResult = std::make_unique<AsyncResultWrap>();
        database.set<object_t>(fb_client, getUserUrl(user.getId()).c_str(), user.toObject_t(), databaseResult->getInternal());
        return databaseResult;
    }


private:
    void connectSetup()
    {
        if(hadSetup) {
            return;
        }

        Serial.print("\nFirebaseDB connection setup. ");
        ledIndicator->displayLoadingFirebase();
        set_ssl_client_insecure_and_buffer(ssl_client);
        initializeApp(fb_client, firebase_app, getAuth(user_auth), auth_debug_print, "auth");
        firebase_app.getApp<RealtimeDatabase>(database);
        database.url(FIREBASE_DATABASE_URL);
        Serial.print("\nFirebaseDB connection setup done. ");
        hadSetup = true;
    }

    void notifyConnected()
    {
        if(isLastReady)
            return;

        ledIndicator->clear();
        Serial.print("\nFirebase connected. ");
        isLastReady = true;
    }

    void firebaseLoop()
    {
        unsigned long before = millis();
        if(millis() - lastTimeTriggered > 100) {
            Serial.printf("\nbefore firebase loop %d. ", millis() - lastTimeTriggered);
        }
        firebase_app.loop();
        if(millis() - lastTimeTriggered > 100) {
            Serial.print("\nafter firebase loop. ");
            if(millis() - before > 100) {
                Serial.printf("\nFirebase loop took %lu ms. ", millis() - before);
            }
        }
        lastTimeTriggered = millis();
    }

    void registerActiveEvent()
    {
        if(!isSetActiveEvent) {
            Serial.print("\nRegistering active event. ");
            database.setSSEFilters("get,put,patch");
            database.get(fb_client, ACTIVE_EVENT_PATH, activeEventResult, true);
            isSetActiveEvent = true;
            Serial.print("\nRegistering active event finished. ");
        }
    }

    void checkAsyncResult()
    {
        if (!activeEventResult.isResult())
            return;

        if(activeEventResult.isError())
        {
            Serial.printf("\nactive event, Error task: %s, msg: %s, code: %d. ", activeEventResult.uid().c_str(), activeEventResult.error().message().c_str(), activeEventResult.error().code());
            return;
        }

        if (!activeEventResult.available())
            return;
        Firebase.printf("\nactive event, task: %s, payload: ***%s****. ", activeEventResult.uid().c_str(), activeEventResult.c_str());
        auto& stream = activeEventResult.to<RealtimeDatabaseResult>();
        if(std::string("keep-alive") == stream.event().c_str())
        {
            Serial.print("\nactive event Keep-alive event received, skipping update. ");
            return;
        }


        string path = stream.dataPath().c_str();
        string data = stream.data().c_str();

        activeEvent.update(path, data);
        if(activeEvent.getId().empty())
        {
            Serial.print("\nActive event is empty, skipping update. ");
            return;
        }

        Serial.printf("\nActive event updated: '%s'", activeEvent.getId().c_str());
    }


    std::string getUserUrl(const std::string& id) const
    {
        return "EventsV3/" + activeEvent.getId() + "/Participants/" + id;
    }



};



#endif //IOT_FIREBASEDB_H
