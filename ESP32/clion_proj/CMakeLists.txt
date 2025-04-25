cmake_minimum_required(VERSION 3.22)
project(temp)

set(CMAKE_CXX_STANDARD 17)

add_executable(temp arduino_proj.cpp
        LedIndicator.h
        Adafruit_NeoPixel.h
        main.cpp)
