#ifndef IOT_IFIREBASEDB_H
#define IOT_IFIREBASEDB_H

#include "User.h"
#include "IAsyncResult.h"
#include <string>
#include <memory>

class IFirebaseDB
{
public:
    virtual void setup() = 0;
    virtual bool isReady() = 0;
    virtual void onWifiDisconnect() = 0;
    virtual std::unique_ptr<IAsyncResult> getUser(const std::string& id) = 0;
    virtual std::unique_ptr<IAsyncResult> setUser(const std::string& id, const User& user) = 0;
    virtual std::unique_ptr<IAsyncResult> updateUsedTokens(const std::string& id, int amount) = 0;
};

class FirebaseDBMock : public IFirebaseDB
{
public:
    void setup() override{}

    bool isReady() override{return true;}

    void onWifiDisconnect() override{}

    std::unique_ptr<IAsyncResult> getUser(const std::string& id) override
    {
        return std::make_unique<UserAsyncResultMock>(id);
    }

    std::unique_ptr<IAsyncResult> setUser(const std::string& id, const User& user) override
    {
        return std::make_unique<UserAsyncResultMock>(id);
    }

    std::unique_ptr<IAsyncResult> updateUsedTokens(const std::string& id, int amount) override
    {
        return std::make_unique<UserAsyncResultMock>(id);
    }
};




#endif //IOT_IFIREBASEDB_H
