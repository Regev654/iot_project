#ifndef IOT_LEDINDICATOR_H
#define IOT_LEDINDICATOR_H

#include "stubs.h"
#include "parameters.h"
#include "Adafruit_NeoPixel.h"
#include <cmath>


class LedIndicator
{
    static constexpr int ROUNDS = 3;
    static constexpr int DELAY = 300;
    Adafruit_NeoPixel pixels;

    int getPercent(int index) const
    {
        auto indexDouble = static_cast<double>(index);
        double percent = indexDouble / ROUNDS * PIXELS_COUNT;
        int intPercent = static_cast<int>(std::round(percent));
        if (intPercent < 0 || PIXELS_COUNT < intPercent) {
            intPercent = PIXELS_COUNT;
            Serial.printf("Error: intPercent out of bounds %d", intPercent);
        }
        return intPercent;
    }


public:
    explicit LedIndicator()
        : pixels(PIXELS_COUNT, LED_PIN, NEO_GRB + NEO_KHZ800)
    {
    }

    void setup()
    {
        Serial.println("LED setup started");
        pixels.begin();
        pixels.clear();
        pixels.show();
        Serial.println("LED setup finished");
    }

    void displaySuccess()
    {
        Serial.println("Success");
        for (int i = 0; i < ROUNDS; i++) {
            for (int j = 0; j < PIXELS_COUNT; j++) {
                pixels.setPixelColor(j, pixels.Color(0, 70, 0));
            }
            pixels.show();
            delay(DELAY);
            pixels.clear();
            pixels.show();
            delay(DELAY);
        }
        Serial.println("led finished");
    }

    void displayError()
    {
        Serial.println("Error");
        for (int i = 0; i < ROUNDS; i++) {
            for (int j = 0; j < PIXELS_COUNT; j++) {
                pixels.setPixelColor(j, pixels.Color(70, 0, 0));
            }
            pixels.show();
            delay(DELAY);
            pixels.clear();
            pixels.show();
            delay(DELAY);
        }
    }

    void displayUnauthorised()
    {
        Serial.println("Unauthorised");
        for (int i = 0; i < ROUNDS*2; i++) {
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

    void displayReachedMax()
    {
        Serial.println("Reached Max");
        for (int i = 0; i < ROUNDS; i++) {
            int percent = getPercent(i);
            for (int j = 0; j < PIXELS_COUNT-percent; j++) {
                pixels.setPixelColor(j, pixels.Color(70, 0, 0));
            }
            pixels.show();
            delay(DELAY);
            delay(DELAY);
            pixels.clear();
        }
        pixels.show();
    }

    void displayLoadingWifi()
    {
        displayLoading(70, 70, 0, ".W");
    }

    void displayLoadingFirebase()
    {
        displayLoading(40, 100, 0, ".F");
    }

    void displayLoadingUser()
    {
        displayLoading(10, 100, 0, ".U");
    }

    void displayLoading(int red, int green, int blue, const char* message = ".")
    {
        static int state = 0;
        static unsigned long lastTime = millis();
        if(millis() - lastTime < 100) {
            return;
        }
        lastTime = millis();
        state = (state + 1) % PIXELS_COUNT;
        Serial.print(message);
        for (int j = 0; j < PIXELS_COUNT; j++) {
            if(j==state)
            {
                pixels.setPixelColor(j, pixels.Color(red, green, blue));
            }
            else
            {
                pixels.setPixelColor(j, pixels.Color(123, 51, 0));
            }
        }
        pixels.show();
    }

    void clear()
    {
        Serial.println("clear");
        pixels.clear();
        pixels.show();
    }

};

#endif