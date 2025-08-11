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

//use unique ptr to allocate memory on the heap and save stack space
auto ledIndicator = make_unique<LedIndicator>();

void onApStart(WiFiManager* notUsed)
{
    ledIndicator->displaySearchingWifi();
}

//use unique ptr to allocate memory on the heap and save stack space
auto settings = make_unique<Settings>();
auto wifiConnection = make_unique<WifiConnection>(ledIndicator.get(),onApStart, settings.get());
auto firebaseDB = make_unique<FirebaseDB>(ledIndicator.get(), settings.get());
auto printer = make_unique<Printer>(settings.get());
auto idChecker = make_unique<IdChecker>(printer.get(), ledIndicator.get(), firebaseDB.get(), settings.get());
auto magneticReader = make_unique<MagneticReader>(idChecker.get());
auto barcodeScanner = make_unique<BarcodeScanner>(idChecker.get());

void ledLoop(void* arg) {
    while (true) {
        ledIndicator->onTrigger();
        delay(11);
    }
}

void setup() {
    Serial.begin(115200);
    Serial.println("starting");

    ledIndicator->setup();
    settings->setup();
    printer->setup();
    magneticReader->setUp();
    barcodeScanner->setup();
    wifiConnection->setup();
    firebaseDB->setup();

    xTaskCreate(ledLoop, "ledLoop", 2048, nullptr, 3, nullptr);
    Serial.print("finished setups connection");
}

unsigned int lastTime = 0;
unsigned int timeInterval = 1000;
unsigned int timeIntervalStep = 1000;
void monitorMemory()
{
    if(millis() - lastTime < timeInterval) {
        return;
    }
    Serial.printf("\nFree heap: %u. ", ESP.getFreeHeap());
    Serial.printf("\nFree stack: %u. ", uxTaskGetStackHighWaterMark(nullptr));
    lastTime = millis();
    if(timeInterval < 60*1000)
    {
        timeInterval += timeIntervalStep;
        timeIntervalStep += 500;
    }
}

void loop() {
    monitorMemory();

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
