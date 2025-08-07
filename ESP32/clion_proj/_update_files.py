import os
import shutil
import json
from pathlib import Path

# List of files to exclude (case-sensitive, include file extensions)
blacklist = {'Adafruit_NeoPixel.h',
             'EspUsbHost.h',
             'stubs.h',
             'main.cpp',
             'FirebaseClient.h',
             'ExampleFunctions.h',
             'ArduinoJson.h',
             'WiFiManager.h',
             'Preferences.h'}


destination_dir = '../arduino_proj/'
manifest_path = 'last_move_times.json'
os.makedirs(destination_dir, exist_ok=True)

if os.path.exists(manifest_path):
    with open(manifest_path, 'r') as f:
        last_moved = json.load(f)
else:
    last_moved = {}

print(f"running from {os.getcwd()}")

updated_manifest = last_moved

# Iterate through current directory
for filename in os.listdir('.'):
    if filename in blacklist:
        continue

    if filename.endswith('.h'):
        dest_filename = filename  # Keep .h as-is
    elif filename.endswith('.cpp'):
        dest_filename = os.path.splitext(filename)[0] + '.ino'
    else:
        continue  # Skip non .h/.cpp files

    file_path = Path(filename)
    mtime = file_path.stat().st_mtime
    recorded_mtime = last_moved.get(filename)
    if recorded_mtime is not None and abs(mtime - recorded_mtime) < 1e-6:
        continue # File has changed, skip it

    source_path = str(file_path)
    dest_path = os.path.join(destination_dir, dest_filename)
    shutil.copy2(source_path, dest_path)
    print(f'Copied {filename} as {dest_filename} to {destination_dir}')

    updated_manifest[filename] = mtime

with open(manifest_path, 'w') as f:
    json.dump(updated_manifest, f, indent=2)
