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
    std::unique_ptr<IAsyncResult> lastResult;
    std::string lastId;
    bool isRequestPending = false;
    unsigned long lastRequest = 0;
    static constexpr int REQUEST_TIMEOUT = 60*1000;
    int defaultAmount = 0;
public:
    IdChecker(Printer* printer, LedIndicator* ledIndicator, IFirebaseDB* firebaseDB)
        : printer(printer), ledIndicator(ledIndicator), firebaseDB(firebaseDB)
    {
    }

    void onIdReceived(const std::string& id) override
    {
        if(isRequestPending)
        {
            Serial.print("\nPrevious ID processing is still pending, ignoring new ID. ";
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
            if(millis() - lastRequest > REQUEST_TIMEOUT)
            {
                Serial.print("\nRequest timeout, resetting. ";
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
            Serial.print("\nhandle user result error. ";
            isRequestPending = false;
            ledIndicator->clear();
            ledIndicator->displayError();
            return;
        }

        if (!lastResult->available()) {
            return;
        }
        ledIndicator->clear();

        Firebase.printf("\nhandle user result, task: %s, payload: ***%s****. ", lastResult->uid().c_str(), lastResult->c_str());
        bool isAuthorised = std::string("null") != lastResult->c_str();

        if(!isAuthorised && defaultAmount <= 0)
        {
            ledIndicator->clear();
            ledIndicator->displayUnauthorised();
            Firebase.printf("\nhandle user result, Error task: %s, msg: %s, code: %d. ", lastResult->uid().c_str(), lastResult->error().message().c_str(), lastResult->error().code());
            isRequestPending = false;
            return;
        }

        if(!isAuthorised && defaultAmount > 0) {
            User user(lastId, defaultAmount, "text", 0);
            int left = getLeftAmount(user);
            user.increaseUsed(left);
            firebaseDB->setUser(lastId, user);
            printAmount(user, left);
            return;
        }


        User user(lastResult->c_str());
        int left = getLeftAmount(user);

        if(left <= 0)
        {
            ledIndicator->clear();
            ledIndicator->displayReachedMax();

            Firebase.printf("\nhandle user result, No more tokens left for user %s. ", lastId.c_str());
            isRequestPending = false;
            return;
        }

        firebaseDB->updateUsedTokens(lastId, left);
        printAmount(user, left);
        isRequestPending= false;
    }

    void onInputError() override
    {
        ledIndicator->displayError();
    }
private:
    int getLeftAmount(const User& user)
    {
        int left = user.getMax() - user.getUsed();
        if(left>10) {
            Serial.printf("\nUser has %d tokens left, setting 1. ", left);
            left = 1;
        }

        return left;
    }

    void printAmount(const User& user, int amount)
    {
        printer->println(user.getText().c_str(), amount);
        ledIndicator->displaySuccess();
    }
};
#endif //IOT_IDCHECKER_H
