#include "stubs.h"
#include "MagneticReader.h"
#include "LedIndicator.h"
#include "Printer.h"
#include "BarcodeScanner.h"
#include "IdChecker.h"
#include "FirebaseDB.h"
#include "WifiConnection.h"


LedIndicator ledIndicator;
WifiConnection wifiConnection(&ledIndicator);
FirebaseDB firebaseDB(&ledIndicator);
// !!!important!!!
//need to init the LED after firebase to avoid error
//e (5) rmt: rmt_new_tx_channel(269): not able to power down in light sleep neopixel
Printer printer;
IdChecker idChecker(&printer, &ledIndicator, &firebaseDB);
MagneticReader magneticReader(&idChecker);
BarcodeScanner barcodeScanner(&idChecker);

void setup() {
    Serial.begin(115200);
    Serial.println("starting");

    ledIndicator.setup();
    printer.setup();
    magneticReader.setUp();
    barcodeScanner.setup();
    wifiConnection.setup();
    firebaseDB.setup();

    Serial.println("finished setups connection");
}

bool lastReady = false;
void loop() {

    if(!wifiConnection.isReady())
    {
        firebaseDB.onWifiDisconnect();
        return;
    }

    if(!firebaseDB.isReady())
    {
        return;
    }

    magneticReader.onTrigger();
    barcodeScanner.onTrigger();
    idChecker.onTrigger();
}
