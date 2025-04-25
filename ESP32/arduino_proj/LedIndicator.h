#include "stubs.h"
#include "parameters.h"
#include "Adafruit_NeoPixel.h"


class LedIndicator
{
    const int DELAY = 100;
    Adafruit_NeoPixel pixels;
public:
    LedIndicator()
            : pixels(PIXELS_COUNT, LED_PIN, NEO_GRB + NEO_KHZ800)
    {
        pixels.begin();
        pixels.clear();
        pixels.show();
    }

    void displaySuccess()
    {
        Serial.println("Success");
        for (int i = 0; i < 3; i++) {
            for (int j = 0; j < PIXELS_COUNT; j++) {
                pixels.setPixelColor(j, pixels.Color(0, 70, 0));
            }
            pixels.show();
            delay(DELAY);
            pixels.clear();
            pixels.show();
            delay(DELAY);
        }
    }

    void displayFailure()
    {
        Serial.println("Failure");
        for (int i = 0; i < 3; i++) {
            int red = i % 2;
            int blue = 1 - red;

            for (int j = 0; j < PIXELS_COUNT; j++) {
                pixels.setPixelColor(j, pixels.Color(70 * red, 0, 70 * blue));
                red = (red + 1) % 2;
                blue = 1 - red;
            }

            pixels.show();
            delay(DELAY);
        }
        pixels.clear();
        pixels.show();
        delay(DELAY);
    }

};
