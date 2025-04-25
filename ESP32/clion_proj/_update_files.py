import os
import shutil

# List of files to exclude (case-sensitive, include file extensions)
blacklist = {'Adafruit_NeoPixel.h',
             'EspUsbHost.h',
             'stubs.h',
             'main.cpp'}


destination_dir = '../arduino_proj/'
os.makedirs(destination_dir, exist_ok=True)
print(f"running from {os.getcwd()}")


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

    source_path = os.path.join('.', filename)
    dest_path = os.path.join(destination_dir, dest_filename)
    shutil.copy2(source_path, dest_path)
    print(f'Copied {filename} as {dest_filename} to {destination_dir}')
