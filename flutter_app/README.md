# IOT Beer Token

A Flutter application for managing beer tokens and event participation tracking. This app allows event organizers to create events, manage participant groups, and track token usage in real-time.

## Features

### Event Management
- **Create and manage events** with custom titles
- **Live event mode** for real-time token tracking
- **Event statistics** and participant analytics
- **Default items** that can be applied to all participants

### Group Management
- **Create participant groups** with custom names
- **Add participants individually** or via CSV upload
- **Group-specific items** with token allocations
- **Participant search** and filtering

### Token System
- **Real-time token tracking** for each participant
- **Item-based tokens** (e.g., "Free Pizza: 2 tokens")
- **Usage monitoring** with visual progress indicators
- **Token consumption** tracking (used vs. available)

### Live Event Features
- **Real-time updates** across multiple devices
- **Live event mode** for active event management
- **Instant token consumption** tracking
- **Participant activity monitoring**

## Setup Instructions

1. **Clone the repository**
   ```bash
   git clone https://github.com/Regev654/iot_project.git
   cd flutter_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Copy `.env.example` to `.env` and fill in your Firebase configuration values
   - Copy `firebase.json.example` to `firebase.json` and update with your Firebase project details

4. **Run the app**
   ```bash
   flutter run
   ```

## Environment Variables

The following environment variables are required in your `.env` file:

### Firebase Configuration (in .env file)
- `FIREBASE_DATABASE_URL`: Your Firebase Realtime Database URL
- `FIREBASE_API_KEY`: Your Firebase API Key
- `FIREBASE_PROJECT_ID`: Your Firebase Project ID
- `FIREBASE_STORAGE_BUCKET`: Your Firebase Storage Bucket
- `FIREBASE_AUTH_DOMAIN`: Your Firebase Auth Domain
- `FIREBASE_MESSAGING_SENDER_ID`: Your Firebase Messaging Sender ID
- `FIREBASE_APP_ID`: Your Firebase App ID



## Database Structure

The app uses Firebase Realtime Database with the following structure:

```
EventsV3/
├── {eventId}/
│   ├── eventTitle: string
│   ├── defaultItems: {itemName: maxTokens}
│   ├── groups/
│   │   └── {groupId}/
│   │       ├── groupName: string
│   │       ├── participantIds: [string]
│   │       └── items: {itemName: {maxTokens: number}}
│   └── Participants/
│       └── {participantId}/
│           ├── ID: string
│           └── items: {itemName: {maxTokens: number, usedTokens: number}}

LiveEventV3/
├── id: string (current live event ID)
└── defaultItems: {itemName: maxTokens} (if enabled)
```

## Usage Guide

### Creating an Event
1. Log in with admin credentials
2. Click "Add Event" and enter event details
3. Configure default items (optional)
4. Set up participant groups

### Managing Groups
1. Navigate to "Manage Groups" from the event detail screen
2. Create groups and add participants
3. Configure group-specific items and token allocations
4. Upload participant lists via CSV if needed

### Running a Live Event
1. Click "Make Live Event" to activate real-time mode
2. Monitor participant token usage in real-time
3. Use the + and - buttons to adjust token consumption
4. View live statistics and participant activity

### Token Management
- **Default Items**: Applied to all participants automatically
- **Group Items**: Specific to participants in each group
- **Token Consumption**: Tracked per participant per item
- **Real-time Updates**: Changes reflect immediately across all devices

## Security Notes

- Never commit `.env` or `firebase.json` files containing real credentials
- Keep your Firebase configuration files secure
- Use environment variables for all sensitive information
- Follow Firebase security best practices for your project
- Implement proper Firebase security rules for production use

## Development

### Building for Web
```bash
# Use the provided PowerShell script
.\build_web.ps1
```

