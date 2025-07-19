#ifndef IOT_LEDINDICATOR_H
#define IOT_LEDINDICATOR_H

#include "stubs.h"
#include "parameters.h"
#include "Adafruit_NeoPixel.h"
#include <cmath>

enum class State
{
    WIFI_LOADING,
    FIREBASE_LOADING,
    USER_LOADING,
    IDLE,
    RESULT
};

class LedIndicator
{
    static constexpr int ROUNDS = 3;
    static constexpr int DELAY = 300;
    Adafruit_NeoPixel pixels;
    State ledState = State::IDLE;
    int loadingState = 0;
    unsigned long loadingLastTime = 0;
    bool blinkIdleState = true;

    int getPercent(int index) const
    {
        auto indexDouble = static_cast<double>(index);
        double percent = indexDouble / ROUNDS * PIXELS_COUNT;
        int intPercent = static_cast<int>(std::round(percent));
        if (intPercent < 0 || PIXELS_COUNT < intPercent) {
            intPercent = PIXELS_COUNT;
            Serial.printf("\nError: intPercent out of bounds %d", intPercent);
        }
        return intPercent;
    }

    void displayIdle()
    {
        if (millis() - loadingLastTime < 400) {
            return;
        }

        Serial.print(".i");
        pixels.clear();
        if (blinkIdleState)
            pixels.setPixelColor(0, pixels.Color(0, 96, 128));

        blinkIdleState = !blinkIdleState;
        loadingLastTime = millis();
        pixels.show();
    }

    void displayLoading(int red, int green, int blue, const char* message = ".", int interval = 400)
    {
        if (millis() - loadingLastTime < interval) {
            return;
        }
        loadingLastTime = millis();
        loadingState = (loadingState + 1) % PIXELS_COUNT;
        Serial.print(message);
        for (int j = 0; j < PIXELS_COUNT; j++) {
            if (j == loadingState) {
                pixels.setPixelColor(j, pixels.Color(red, green, blue));
            }
            else {
                pixels.setPixelColor(j, pixels.Color(123, 51, 0));
            }
        }
        pixels.show();
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
        Serial.print("\nled display: Success. ";
        ledState = State::RESULT;
        loadingLastTime = millis();
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
        Serial.print("\nled display: Success finished. ";
        ledState = State::IDLE;
    }

    void displayError()
    {
        Serial.print("\nled display: Error. ";
        ledState = State::RESULT;

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

        Serial.print("\nled display: Error finished. ";
        ledState = State::IDLE;
    }

    void displayUnauthorised()
    {
        Serial.print("\nled display: Unauthorised. ";
        ledState = State::RESULT;

        for (int i = 0; i < ROUNDS * 2; i++) {
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

        Serial.print("\nled display: Unauthorised finished. ";
        ledState = State::IDLE;
    }

    void displayReachedMax()
    {
        Serial.print("\nled display: Reached Max. ";
        ledState = State::RESULT;

        for (int i = 0; i < ROUNDS; i++) {
            int percent = getPercent(i);
            for (int j = 0; j < PIXELS_COUNT - percent; j++) {
                pixels.setPixelColor(j, pixels.Color(70, 0, 0));
            }
            pixels.show();
            delay(DELAY);
            delay(DELAY);
            pixels.clear();
        }
        pixels.show();

        Serial.print("\nled display: Reached Max finished. ";
        ledState = State::IDLE;
    }

    void displayLoadingWifi()
    {
        ledState = State::WIFI_LOADING;
    }

    void displayLoadingFirebase()
    {
        ledState = State::FIREBASE_LOADING;
    }

    void displayLoadingUser()
    {
        ledState = State::USER_LOADING;
    }

    void clear()
    {
        ledState = State::IDLE;
    }

    void onTrigger()
    {
        switch (ledState) {
            case State::WIFI_LOADING:
                displayLoading(100, 100, 0, ".W", 400); //yellow
                break;
            case State::FIREBASE_LOADING:
                displayLoading(120, 10, 0, ".F", 700); //close to red
                break;
            case State::USER_LOADING:
                displayLoading(10, 100, 0, ".U", 400); //close to green
                break;
            case State::IDLE:
                displayIdle();
                break;
            case State::RESULT:
                break;
            default:
                Serial.print("\nled display: unknown state. ";
                break;
        }
    }

};

#endif