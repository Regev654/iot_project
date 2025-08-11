## Beer Tokens Project by Regev Avraham, Ido Tausi, Afek Nahum:  
  
## Details about the project
A smart system that identifies users and prints drink vouchers using student IDs and a thermal printer.

### Main features:
- Scans student ID (magnetic/barcode) for quick user verification
- Checks voucher eligibility in real-time via a Firestore database
- Instantly prints a custom voucher with event-specific details

 
## Folder description :
* ESP32: source code for the esp side (firmware).
  * clion_proj - all the source code of the esp side, having stub methods to allow programing in CLion IDE, without the esp32 SDK and long compile times. using a python script, the code can be converted to a format that can be uploaded to the esp32, and moved to the arduino_proj folder.
    * Parameters: contains description of parameters and settings that can be modified in the code
  * arduino_proj - the source code to be loaded to the esp32
  * python_mock - a python script that simulates an esp32 device to allow testing the app with multiple esp devices.
* Documentation: 
  * wiring diagram
  * esp control flow diagram
  * app control flow 
  * physical setup
  * led state explanation
* flutter_app : dart code for our Flutter app.

## ESP32 SDK version used in this project: 
esp32 - version 3.2.1
Arduino AVR Boards 1.8.6

## Arduino/ESP32 libraries used in this project:
* WifiManager - version 2.0.17
* FirebaseClient - version 2.1.5
* EspUsbHost - version 1.0.2
* ArduinoJson - version 7.4.2
* Adafruit NeoPixel - NeoPixel 1.15.1

## Hardware used in this project:
* 1 - esp32-s3-wroom-1
* 1 - 3 led strip
* 1 - HID magnetic stripe reader
* 1 - GM65 barcode reader
* 1 - 58mm thermal printer
* 1 - 470 microfarad capacitor 50v

## Connection diagram:
![Connection diagram](https://github.com/user-attachments/assets/27762a61-a028-4956-975d-f24a7d5bd025)

## Project Poster: 
![Beer Tokens IOT Poster_page](https://github.com/user-attachments/assets/186464a5-9e7b-4e56-9771-a6f8021c276a)

This project is part of ICST - The Interdisciplinary Center for Smart Technologies, Taub Faculty of Computer Science, Technion
https://icst.cs.technion.ac.il/

