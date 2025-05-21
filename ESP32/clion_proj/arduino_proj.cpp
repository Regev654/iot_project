#include "stubs.h"
#include "MagneticReader.h"
#include "LedIndicator.h"
#include "Printer.h"
#include "BarcodeScanner.h"
#include "IdChecker.h"
#include "FirebaseDB.h"



FirebaseDB firebaseDB;
// !!!important!!!
//need to init the LED after firebase to avoid error
//e (5) rmt: rmt_new_tx_channel(269): not able to power down in light sleep neopixel
LedIndicator ledIndicator;
Printer printer;
IdChecker idChecker(&printer, &ledIndicator);
MagneticReader magneticReader(&idChecker);
BarcodeScanner barcodeScanner(&idChecker);

void setup() {
    Serial.begin(115200);
    Serial.println("starting");

    firebaseDB.setup();
    ledIndicator.setup();
    printer.setup();
    magneticReader.setUp();
    barcodeScanner.setup();

    firebaseDB.waitForConnection();
    Serial.println("set");
}

void loop() {
    firebaseDB.onTrigger();
    magneticReader.onTrigger();
    barcodeScanner.onTrigger();
}
