import threading
import time
import pyrebase
from secret import *

# --- secret content: ---
"""
firebase_config = {
  "apiKey": "",
  "authDomain": "your-app.firebaseapp.com",
  "databaseURL": "https://your-app.firebaseio.com",
  "projectId": "your-app",
  "storageBucket": "your-app.firebasestorage.app",
  "messagingSenderId": "",
  "appId": "",
  "measurementId": ""
};

# --- Credentials ---
EMAIL = "email"
PASSWORD = "password"
"""


DEVICE_ID = "device_1"

# --- Firebase Init ---
firebase = pyrebase.initialize_app(firebase_config)
auth = firebase.auth()
db = firebase.database()

# Authenticate and get token
user = auth.sign_in_with_email_and_password(EMAIL, PASSWORD)
id_token = user['idToken']

# Control flag for keep-alive thread
keep_alive_running = False
keep_alive_thread = None

def send_keep_alive():
    global keep_alive_running
    while keep_alive_running:
        try:
            db.child("devices").child(DEVICE_ID).update({
                "lastSeen": {".sv": "timestamp"}
            }, id_token)
        except Exception as e:
            print("[!] Error sending keep-alive:", e)
        time.sleep(2)

def start_keep_alive():
    global keep_alive_running, keep_alive_thread
    if keep_alive_running:
        print("[!] Keep-alive is already running.")
        return
    keep_alive_running = True
    keep_alive_thread = threading.Thread(target=send_keep_alive)
    keep_alive_thread.start()
    print("[+] Started keep-alive.")

def stop_keep_alive():
    global keep_alive_running
    if not keep_alive_running:
        print("[!] Keep-alive is not running.")
        return
    keep_alive_running = False
    print("[-] Stopping keep-alive...")

def main_loop():
    print("Starting new device Simulation")
    print("what is the device ID? (default: device_1)")
    global DEVICE_ID
    device_id_input = input("Device ID: ").strip()
    if device_id_input:
        DEVICE_ID = device_id_input
    print(f"Using Device ID: {DEVICE_ID}")
    print("Type 'start' to start keep-alive, 'stop' to stop, 'exit' to quit.")

    while True:
        cmd = input("> ").strip().lower()
        if cmd == "start":
            start_keep_alive()
        elif cmd == "stop":
            stop_keep_alive()
        elif cmd == "exit":
            stop_keep_alive()
            break
        else:
            print("Unknown command. Use 'start', 'stop', or 'exit'.")

if __name__ == "__main__":
    main_loop()
