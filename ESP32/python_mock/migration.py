import json
import uuid

def migrate_db_v1_to_v3(input_file):
    output_file = 'v3_' + input_file
    try:
        # Load the version 1 database
        with open(input_file, 'r') as infile:
            v1_data = json.load(infile)

        # Initialize the version 3 database structure
        v3_data = {
            "Participants": {},
            "defaultItems": {},
            "eventTitle": v1_data.get("eventTitle", ""),
            "groups": {}
        }

        # Transform participants
        participant_ids = []
        group_items = {}
        for participant_id, participant_data in v1_data.get("Participants", {}).items():
            v3_data["Participants"][participant_id] = {
                "ID": participant_id,
                "items": {
                    participant_data["textToPrint"]: {
                        "maxTokens": participant_data["maxTokens"],
                        "usedTokens": participant_data["usedTokens"]
                    }
                }
            }
            participant_ids.append(participant_id)
            group_items[participant_data["textToPrint"]] = {
                "maxTokens": participant_data["maxTokens"],
                "usedTokens": 0
            }

        # Create a single group with all participants
        group_id = str(uuid.uuid4())
        v3_data["groups"][group_id] = {
            "groupId": group_id,
            "groupName": "Students",
            "items": group_items,
            "participantIds": participant_ids
        }

        # Write the version 3 database to the output file
        with open(output_file, 'w') as outfile:
            json.dump(v3_data, outfile, indent=4)

        print(f"Database successfully migrated to version 3 and saved to {output_file}")

    except Exception as e:
        print(f"Error during migration: {e}")

# Example usage
migrate_db_v1_to_v3('v1_db_event.json')