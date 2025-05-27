#ifndef TEMP_ADAFRUIT_NEOPIXEL_H
#define TEMP_ADAFRUIT_NEOPIXEL_H

#define NEO_GRB 0
#define NEO_KHZ800 0


class Adafruit_NeoPixel
{
public:

    uint32_t Color(int red, int green, int blue) { return {};}
    Adafruit_NeoPixel(int pixelsCount, int ledPin, int frequency){}
    void begin() {}
    void setPixelColor(int index, const uint32_t& color) {}

    void show() {}
    void clear() {}
};



#endif //TEMP_ADAFRUIT_NEOPIXEL_H
