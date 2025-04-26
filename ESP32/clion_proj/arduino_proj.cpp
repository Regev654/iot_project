#include "stubs.h"
#include "MagneticReader.h"
#include "LedIndicator.h"
#include "Printer.h"

MagneticReader usbHost;
LedIndicator ledIndicator;
Printer printer;

void setup() {
    Serial.begin(115200);
    delay(500);
    Serial.printf("starting");

    usbHost.setUp();
    ledIndicator.setup();
    printer.setup();

    Serial.printf("set");
}

void loop() {
    if(usbHost.getState() == State::PROCESS) {
        usbHost.task();
        return;
    }

    if(usbHost.getState() == State::INVALID)
        ledIndicator.displayFailure();
    else if(usbHost.getState() == State::VALID) {
        printer.println("Free beer :)");
        ledIndicator.displaySuccess();
    }

    usbHost.startProcessing();
}
