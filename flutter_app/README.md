# IOT Beer Token

A Flutter application for managing beer tokens.

## Setup Instructions

1. Clone the repository
2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Configure Firebase:
   - Copy `.env.example` to `.env` and fill in your Firebase configuration values
   - Copy `firebase.json.example` to `firebase.json` and update with your Firebase project details
   - Place your `google-services.json` in `android/app/`
   - Place your `GoogleService-Info.plist` in `ios/Runner/`

4. Run the app:
   ```bash
   flutter run
   ```

## Environment Variables

The following environment variables are required in your `.env` file:

- `FIREBASE_DATABASE_URL`: Your Firebase Realtime Database URL
- `FIREBASE_API_KEY`: Your Firebase API Key
- `FIREBASE_PROJECT_ID`: Your Firebase Project ID
- `FIREBASE_STORAGE_BUCKET`: Your Firebase Storage Bucket
- `FIREBASE_AUTH_DOMAIN`: Your Firebase Auth Domain
- `FIREBASE_MESSAGING_SENDER_ID`: Your Firebase Messaging Sender ID
- `FIREBASE_APP_ID`: Your Firebase App ID
- `FIREBASE_IOS_CLIENT_ID`: Your Firebase iOS Client ID
- `FIREBASE_IOS_BUNDLE_ID`: Your Firebase iOS Bundle ID
- `ADMIN_EMAIL`: Admin email for authentication
- `ADMIN_PASSWORD`: Admin password for authentication

## Security Notes

- Never commit `.env` or `firebase.json` files containing real credentials
- Keep your Firebase configuration files secure
- Use environment variables for all sensitive information
- Follow Firebase security best practices for your project

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request
