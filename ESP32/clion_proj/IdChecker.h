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
    static constexpr int REQUEST_TIMEOUT = 30000;
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
            Serial.println("Previous ID processing is still pending, ignoring new ID");
            return;
        }
        Serial.printf("got ID %s \n", id.c_str());
        isRequestPending = true;
        lastRequest = millis();
        lastResult = firebaseDB->getUser(id);
        lastId = id;
        Serial.printf("sent request for user %s info\n", id.c_str());
    }

    void onTrigger()
    {
        if(isRequestPending)
        {
            if(millis() - lastRequest > REQUEST_TIMEOUT)
            {
                Serial.println("Request timeout, resetting");
                isRequestPending = false;
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
            Serial.println("handle user result error");
            isRequestPending = false;
            ledIndicator->displayError();
            return;
        }

        if (!lastResult->available()) {
            return;
        }
        ledIndicator->clear();

        Serial.println("handle user result");
        Firebase.printf("handle user result, task: %s, payload: ***%s****\n", lastResult->uid().c_str(), lastResult->c_str());
        bool isAuthorised = std::string("null") != lastResult->c_str();

        if(!isAuthorised && defaultAmount <= 0)
        {
            ledIndicator->displayUnauthorised();
            Firebase.printf("handle user result, Error task: %s, msg: %s, code: %d\n", lastResult->uid().c_str(), lastResult->error().message().c_str(), lastResult->error().code());
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
            ledIndicator->displayReachedMax()   ;
            Firebase.printf("No more tokens left for user %s\n", lastId.c_str());
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
            Serial.printf("User has %d tokens left, setting 1\n", left);
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
