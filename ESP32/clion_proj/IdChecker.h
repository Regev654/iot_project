#ifndef IOT_IDCHECKER_H
#define IOT_IDCHECKER_H

#include "stubs.h"
#include "Interfaces.h"
#include "Printer.h"
#include "LedIndicator.h"

class IdChecker : public IdListener
{
    Printer* printer = nullptr;
    LedIndicator* ledIndicator = nullptr;
    int counter = 0;
public:
    IdChecker(Printer* printer, LedIndicator* ledIndicator)
    {
        this->printer = printer;
        this->ledIndicator = ledIndicator;
    }

    void onIdReceived(const std::string& id) override
    {
        if(counter > 2)
        {
            ledIndicator->displayReachedMax();
            counter = 0;
            return;
        }

        if(id == "207708603" )
        {
            printer->println("Free beer :)");
            ledIndicator->displaySuccess();
            counter++;
            return;
        }

        ledIndicator->displayUnauthorised();
    }

    void onInputError() override
    {
        ledIndicator->displayError();
    }

};
#endif //IOT_IDCHECKER_H
