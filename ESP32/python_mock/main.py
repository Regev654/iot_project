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


def parse_data(data):
    parsed_data = {}
    if data.each():
        for item in data.each():
            key = item.key()
            value = item.val()
            parsed_data[key] = value
    else:
        print("[!] No data to parse.")
    return parsed_data

def create_user_data(user_id, default):
    user_data = {"ID": user_id, "items":{}}
    for name, amount in default.items():
        user_data["items"][name] = { "maxTokens": amount, "usedTokens": 0 }
    return user_data

def use_and_print_user_tokens(user_data):
    items = user_data["items"]
    print("user tokens:")
    for name, data in items.items():
        max_tokens = data["maxTokens"]
        used_tokens = data["usedTokens"]
        left_tokens = max_tokens - used_tokens
        for i in range(left_tokens):
            print("--------------")
            print(name)
        print("--------------")
        data["usedTokens"] = max_tokens


def get_data(user_id):
    live_event = db.child("/LiveEventV3").get(id_token)
    if not live_event.each():
        print("[!] No data found at 'LiveEventV3'.")
        return

    live_event = parse_data(live_event)
    live_event_id = live_event["id"]
    user_path = "EventsV3/" + live_event_id + "/Participants/" + user_id
    user_data = db.child(user_path).get(id_token)
    return live_event, user_data, user_path


def handle_user_id(user_id):
    try:
        live_event, user_data, user_path = get_data(user_id)
        has_default_items = sum([count for name, count in live_event["defaultItems"].items()])

        if not user_data.each() and not has_default_items:
            print("[!] unauthorized user, no default items found.")
            return

        if not user_data.each():
            print("[!] unauthorized user, creating new default user data.")
            user_data = create_user_data(user_id, live_event["defaultItems"])
        else:
            user_data = parse_data(user_data)

        user_total_left_tokens = sum([data["maxTokens"] - data["usedTokens"] for name, data in user_data["items"].items()])
        if user_total_left_tokens <= 0:
            print("[!] User has no tokens left.")
            return
        use_and_print_user_tokens(user_data)
        db.child(user_path).set(user_data, id_token)

    except Exception as e:
        print("[!] Error retrieving data from 'LiveEventV3':", e)


def delete_user(user_id):
    try:
        live_event, user_data, user_path = get_data(user_id)

        if not user_data.each():
            print(f"[!] User with ID {user_id} does not exist in the current live event.")
            return

        db.child(user_path).remove(id_token)
        print(f"[+] User with ID {user_id} has been successfully deleted from the current live event.")
    except Exception as e:
        print(f"[!] Error deleting user with ID {user_id}:", e)



def reset_user_tokens(user_id):
    try:
        live_event, user_data, user_path = get_data(user_id)

        if not user_data.each():
            print(f"[!] User with ID {user_id} does not exist in the current live event.")
            return

        # Parse user data and reset tokens
        user_data = parse_data(user_data)
        for item in user_data["items"].values():
            item["usedTokens"] = 0

        # Update the user data in the database
        db.child(user_path).set(user_data, id_token)
        print(f"[+] All tokens for user with ID {user_id} have been reset.")
    except Exception as e:
        print(f"[!] Error resetting tokens for user with ID {user_id}:", e)

# Update the main_loop function to include the reset command
def main_loop():
    print("Starting new device Simulation")
    print("what is the device ID? (default: device_1)")
    global DEVICE_ID
    device_id_input = input("Device ID: ").strip()
    if device_id_input:
        DEVICE_ID = device_id_input
    print(f"Using Device ID: {DEVICE_ID}")
    print("Type 'start' to simulate device start")
    print("Type 'stop' to simulate device stop")
    print("Type 'id <id>' to simulate id scan")
    print("Type 'delete <id>' to delete a user from the current live event")
    print("Type 'reset <id>' to reset all tokens for a user")
    print("Type 'exit' to quit.")

    while True:
        cmd = input("> ").strip().lower()
        user_id = cmd.split(" ")[1] if len(cmd.split(" ")) > 1 else "0"

        if cmd == "start":
            start_keep_alive()
        elif cmd == "stop":
            stop_keep_alive()
        elif cmd == "exit":
            stop_keep_alive()
            break
        elif cmd.split(" ")[0] == "id":
            if len(user_id) != 9:
                print("[!] invalid User ID")
                continue
            handle_user_id(user_id)
        elif cmd.split(" ")[0] == "delete":
            if len(user_id) != 9:
                print("[!] invalid User ID")
                continue
            delete_user(user_id)
        elif cmd.split(" ")[0] == "reset":
            if len(user_id) != 9:
                print("[!] invalid User ID")
                continue
            reset_user_tokens(user_id)
        else:
            print("Unknown command. Use 'start', 'stop', 'id', 'delete', 'reset' or 'exit'.")


if __name__ == "__main__":
    main_loop()
