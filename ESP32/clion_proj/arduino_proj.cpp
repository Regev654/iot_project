#include "stubs.h"
#include "MagneticReader.h"
#include "LedIndicator.h"
#include "Printer.h"
#include "BarcodeScanner.h"
#include "IdChecker.h"
#include "FirebaseDB.h"
#include "WifiConnection.h"
#include <memory>

using std::unique_ptr;
using std::make_unique;


auto ledIndicator = make_unique<LedIndicator>();
auto wifiConnection = make_unique<WifiConnection>(ledIndicator.get());
auto firebaseDB = make_unique<FirebaseDB>(ledIndicator.get());
auto printer = make_unique<Printer>();
auto idChecker = make_unique<IdChecker>(printer.get(), ledIndicator.get(), firebaseDB.get());
auto magneticReader = make_unique<MagneticReader>(idChecker.get());
auto barcodeScanner = make_unique<BarcodeScanner>(idChecker.get());

void setup() {
    Serial.begin(115200);
    Serial.println("starting");

    ledIndicator->setup();
    printer->setup();
    magneticReader->setUp();
    barcodeScanner->setup();
    wifiConnection->setup();
    firebaseDB->setup();

    Serial.println("finished setups connection");
}

unsigned int lastTime = 0;
unsigned int timeInterval = 1000;
unsigned int timeIntervalStep = 1000;
void monitorMemory()
{
    if(millis() - lastTime < timeInterval) {
        return;
    }
    Serial.printf("\nFree heap: %u\n", ESP.getFreeHeap());
    Serial.printf("Free stack: %u\n", uxTaskGetStackHighWaterMark(NULL));
    lastTime = millis();
    if(timeInterval < 60*1000)
    {
        timeInterval += timeIntervalStep;
        timeIntervalStep += 500;
    }
}

void loop() {
    monitorMemory();
    ledIndicator->onTrigger();

    if(!wifiConnection->isReady())
    {
        firebaseDB->onWifiDisconnect();
        return;
    }

    if(!firebaseDB->isReady())
    {
        return;
    }

    magneticReader->onTrigger();
    barcodeScanner->onTrigger();
    idChecker->onTrigger();
}
