#ifndef IOT_IASYNCRESULT_H
#define IOT_IASYNCRESULT_H


#define ENABLE_USER_AUTH
#define ENABLE_DATABASE

#include "FirebaseClient.h"
#include "User.h"

class IAsyncResult
{
public:
    virtual ~IAsyncResult() = default;
    virtual bool isResult()  = 0;
    virtual bool isError() = 0;
    virtual bool available() = 0;
    virtual String uid()  = 0;
    virtual FirebaseError error() = 0;
    virtual const char* c_str() = 0;
};

class AsyncResultWrap : public IAsyncResult
{
private:
    AsyncResult asyncResult;
public:

    AsyncResult& getInternal()
    {
        return asyncResult;
    }

    bool isResult() override
    {
        return asyncResult.isResult();
    }
    bool isError() override
    {
        return asyncResult.isError();
    }
    bool available()  override
    {
        return asyncResult.available();
    }
    String uid() override
    {
        return asyncResult.uid();
    }
    const char* c_str() override
    {
        return asyncResult.c_str();
    }

    FirebaseError error() override
    {
        return asyncResult.error();
    }
};

class UserAsyncResultMock : public IAsyncResult
{
private:
    std::string id;
    std::string content;
    bool used = false;
public:
    UserAsyncResultMock(const std::string& id) : id(id), content(User(id, 1, "Test User", 0).toString()) {}

    bool isResult() override
    {
        return true;
    }

    bool isError() override
    {
        return false;
    }

    bool available() override
    {
        return !used;
    }

    String uid() override
    {
        return {id.c_str()};
    }

    const char* c_str() override
    {
        used = true;
        return content.c_str();
    }

    FirebaseError error() override
    {
        return FirebaseError();
    }
};


#endif //IOT_IASYNCRESULT_H
