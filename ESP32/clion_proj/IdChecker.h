#ifndef IOT_IDCHECKER_H
#define IOT_IDCHECKER_H

#include "stubs.h"
#include "Interfaces.h"
#include "Printer.h"
#include "LedIndicator.h"
#include "FirebaseDB.h"
#include "ArduinoJson.h"

class IdChecker : public IdListener
{
    Printer* printer;
    LedIndicator* ledIndicator;
    IFirebaseDB* firebaseDB;
    Settings* settings;
    std::unique_ptr<IAsyncResult> lastResult;
    std::string lastId;
    bool isRequestPending = false;
    unsigned long lastRequest = 0;
public:
    IdChecker(Printer* printer, LedIndicator* ledIndicator, IFirebaseDB* firebaseDB, Settings* settings)
        : printer(printer), ledIndicator(ledIndicator), firebaseDB(firebaseDB), settings(settings)
    {
    }

    void onIdReceived(const std::string& id) override
    {
        if(isRequestPending)
        {
            Serial.print("\nPrevious ID processing is still pending, ignoring new ID. ");
            return;
        }
        Serial.printf("\ngot ID %s. ", id.c_str());
        isRequestPending = true;
        ledIndicator->displayLoadingUser();
        lastRequest = millis();
        lastResult = firebaseDB->getUser(id);
        lastId = id;
        Serial.printf("\nsent request for user %s info. ", id.c_str());
    }

    void onTrigger()
    {
        if(isRequestPending)
        {
            if(millis() - lastRequest > settings->getRequestTimeout())
            {
                Serial.print("\nRequest timeout, resetting. ");
                isRequestPending = false;
                ledIndicator->clear();
                ledIndicator->displayError();
                return;
            }
            ledIndicator->displayLoadingUser();
        }

        // Exits when no result available when calling from the loop.
        if (!lastResult || !lastResult->isResult())
        {
            return;
        }

        if (lastResult->isError())
        {
            Serial.print("\nhandle user result error. ");
            isRequestPending = false;
            ledIndicator->clear();
            ledIndicator->displayError();
            return;
        }

        if (!lastResult->available()) {
            return;
        }

        handleAvailableResult();
    }

    void handleAvailableResult()
    {
        ledIndicator->clear();

        Firebase.printf("\nhandle user result, task: %s, payload: ***%s****. ", lastResult->uid().c_str(), lastResult->c_str());
        bool isAuthorised = std::string("null") != lastResult->c_str();



        if(!isAuthorised && !firebaseDB->hasDefaultItems())
        {
            ledIndicator->clear();
            ledIndicator->displayUnauthorised();
            Firebase.printf("\nhandle user result, Unauthorised task: %s, msg: %s, code: %d. ", lastResult->uid().c_str(), lastResult->error().message().c_str(), lastResult->error().code());
            isRequestPending = false;
            return;
        }

        User user;
        if(!isAuthorised && firebaseDB->hasDefaultItems()) {
            Firebase.printf("\nhandle user result, Unauthorised, setting default amount, task: %s, msg: %s, code: %d. ", lastResult->uid().c_str(), lastResult->error().message().c_str(), lastResult->error().code());
            user = User(lastId, firebaseDB->getDefaultItems());
        }
        else
        {
            user = User(lastResult->c_str());
        }

        Serial.printf("\nparsed user: %s", user.toString().c_str());
        std::map<string, int> leftItems;
        bool hasLeft = false;
        for( const auto& item : user.getItems())
        {
            if(item.second.getLeft() <= 0) {
                continue;
            }

            int left = item.second.getLeft();
            if(left > settings->getMaxTokensAtOnce()) {
                Serial.printf("\nUser has %d tokens left, setting 1. ", left);
                left = 1;
            }

            leftItems[item.first] = left;
            user.increaseUsed(item.first, left);
            hasLeft = true;
        }

        if(!hasLeft)
        {
            ledIndicator->clear();
            ledIndicator->displayReachedMax();

            Firebase.printf("\nhandle user result, No more tokens left for user %s. ", lastId.c_str());
            isRequestPending = false;
            return;
        }

        Serial.printf("\nparsed updated user: %s", user.toString().c_str());
        firebaseDB->updateUserStats(user);
        printAmount(leftItems);
    }

    void onInputError() override
    {
        ledIndicator->displayError();
    }
private:

    void printAmount(const std::map<string, int>& items)
    {
        isRequestPending= false;
        ledIndicator->clear();
        printer->printItems(items);
        ledIndicator->displaySuccess();
    }
};
#endif //IOT_IDCHECKER_H
