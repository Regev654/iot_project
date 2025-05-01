#include "stubs.h"
#include "MagneticReader.h"
#include "LedIndicator.h"
#include "Printer.h"
#include "BarcodeScanner.h"
#include "IdChecker.h"


Printer printer;
// !!!important!!!
//need to init the LED after the printer
LedIndicator ledIndicator;
IdChecker idChecker(&printer, &ledIndicator);
MagneticReader magneticReader(&idChecker);
BarcodeScanner barcodeScanner(&idChecker);

void setup() {
    Serial.begin(115200);
    Serial.println("starting");

    ledIndicator.setup();
    printer.setup();
    magneticReader.setUp();
    barcodeScanner.setup();

    Serial.println("set");
}

void loop() {
    magneticReader.onTrigger();
    barcodeScanner.onTrigger();
}
