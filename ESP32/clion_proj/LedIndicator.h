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
    int loadingState = 0;
    unsigned long loadingLastTime = 0;

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
        Serial.println("led display: Success");
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
        Serial.println("led display: Success finished");
    }

    void displayError()
    {
        Serial.println("led display: Error");

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

        Serial.println("led display: Error finished");
    }

    void displayUnauthorised()
    {
        Serial.println("led display: Unauthorised");
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
        Serial.println("led display: Unauthorised finished");
    }

    void displayReachedMax()
    {
        Serial.println("led display: Reached Max");
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
        Serial.println("led display: Reached Max finished");
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
        if(millis() - loadingLastTime < 100) {
            return;
        }
        loadingLastTime = millis();
        loadingState = (loadingState + 1) % PIXELS_COUNT;
        Serial.print(message);
        for (int j = 0; j < PIXELS_COUNT; j++) {
            if(j == loadingState)
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
        Serial.println("\nclear");
        pixels.clear();
        pixels.show();
    }

};

#endif