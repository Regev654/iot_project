cmake_minimum_required(VERSION 3.22)
project(iot)

set(CMAKE_CXX_STANDARD 17)

add_executable(iot arduino_proj.cpp
        LedIndicator.h
        Adafruit_NeoPixel.h
        main.cpp
        Interfaces.h
        IdChecker.h
        secrets.h
        FirebaseDB.h
        FirebaseClient.h
        User.h
        ArduinoJson.h
        WiFiMulti.h
        WifiConnection.h
        IAsyncResult.h
)
