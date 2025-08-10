## Beer Tokens Project by Regev Avraham, Ido Tausi, Afek Nahum:  
  
## Details about the project
A smart system that identifies users and prints drink vouchers using student IDs and a thermal printer.

### Main features:
- Scans student ID (magnetic/barcode) for quick user verification
- Checks voucher eligibility in real-time via a Firestore database
- Instantly prints a custom voucher with event-specific details

 
## Folder description :
* ESP32: source code for the esp side (firmware).
* Documentation: wiring diagram + basic operating instructions
* Unit Tests: tests for individual hardware components (input / output devices)
* flutter_app : dart code for our Flutter app.
* Parameters: contains description of parameters and settings that can be modified IN YOUR CODE
* Assets: link to 3D printed parts, Audio files used in this project, Fritzing file for connection diagram (FZZ format) etc

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
<img width="4128" height="2028" alt="connection_diagram" src="https://github.com/user-attachments/assets/27762a61-a028-4956-975d-f24a7d5bd025" />

## Project Poster: 
![Beer Tokens IOT Poster_page-0001](https://github.com/user-attachments/assets/186464a5-9e7b-4e56-9771-a6f8021c276a)

This project is part of ICST - The Interdisciplinary Center for Smart Technologies, Taub Faculty of Computer Science, Technion
https://icst.cs.technion.ac.il/

