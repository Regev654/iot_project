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
    virtual bool hasDefaultItems() const = 0;
    virtual const std::map<std::string, int>& getDefaultItems() const = 0;
    virtual std::unique_ptr<IAsyncResult> getUser(const std::string& id) = 0;
    virtual std::unique_ptr<IAsyncResult> updateUserStats(const User& user) = 0;
};

class FirebaseDBMock : public IFirebaseDB
{
public:
    void setup() override{}

    bool isReady() override{return true;}

    void onWifiDisconnect() override{}

    bool hasDefaultItems() const override
    {
        return true;
    }

    const std::map<std::string, int>& getDefaultItems() const override
    {
        static std::map<std::string, int> defaultItems = {{"item1", 10}, {"item2", 20}};
        return defaultItems;
    }

    std::unique_ptr<IAsyncResult> getUser(const std::string& id) override
    {
        return std::make_unique<UserAsyncResultMock>(id);
    }


    std::unique_ptr<IAsyncResult> updateUserStats(const User& user) override
    {
        return std::make_unique<UserAsyncResultMock>(user.getId());
    }
};




#endif //IOT_IFIREBASEDB_H
