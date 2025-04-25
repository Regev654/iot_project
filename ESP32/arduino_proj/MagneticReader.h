#include "stubs.h"
#include "EspUsbHost.h"
#include <string>
using std::string;

enum class State
{
    PROCESS,
    VALID,
    INVALID
};

class MagneticReader : public EspUsbHost {
    const int ID_LENGTH = 9;
    const int PREFIX_LENGTH = 2;
    string currentId;
    State state = State::PROCESS;
public:
    void onKeyboardKey(uint8_t ascii, uint8_t keycode, uint8_t modifier) override {
        if (' ' <= ascii && ascii <= '~') {
            currentId += static_cast<char>(ascii);
        } else if (ascii == '\r') {
            processCurrentId();
            currentId = "";
        }
    };

    void processCurrentId()
    {
        if(currentId.size() < PREFIX_LENGTH + ID_LENGTH || currentId[0] != '@' || currentId[1] != '%')
        {
            state = State::INVALID;
            return;
        }
        currentId = currentId.substr(2, ID_LENGTH);
        string valid_id = "207708603";


        state = currentId == valid_id ? State::VALID : State::INVALID;
    }

    void startProcessing()
    {
        state = State::PROCESS;
    }

    State getState()
    {
        return state;
    }

};

