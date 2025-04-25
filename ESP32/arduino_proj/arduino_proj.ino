#include "stubs.h"
#include "MagneticReader.h"
#include "LedIndicator.h"


MagneticReader usbHost;
LedIndicator ledIndicator;

void setup() {
    Serial.begin(115200);
    delay(500);
    Serial.printf("starting");
    usbHost.begin();
    usbHost.setHIDLocal(HID_LOCAL_Hebrew);
    Serial.printf("set");
}

void loop() {
    if(usbHost.getState() == State::PROCESS) {
        usbHost.task();
        return;
    }

    if(usbHost.getState() == State::INVALID)
        ledIndicator.displayFailure();
    else if(usbHost.getState() == State::VALID)
        ledIndicator.displaySuccess();

    usbHost.startProcessing();
}
