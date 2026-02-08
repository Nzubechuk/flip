# Flip POS System - Flutter Frontend

This is the Flutter frontend application for the Flip Point of Sale (POS) system.

## Prerequisites

Before you begin, ensure you have Flutter installed on your system:

1. **Install Flutter**: 
   - Download Flutter from [https://docs.flutter.dev/get-started/install](https://docs.flutter.dev/get-started/install)
   - Follow the installation instructions for Windows
   - Verify installation by running `flutter doctor`

2. **Install Dependencies**:
   ```bash
   flutter pub get
   ```

## Setup Instructions

Since the Flutter project structure was created manually, you'll need to complete the setup:

1. **Navigate to the frontend directory**:
   ```bash
   cd frontend
   ```

2. **Run Flutter pub get**:
   ```bash
   flutter pub get
   ```

3. **Create platform-specific files** (if needed):
   ```bash
   flutter create .
   ```
   This will create the Android, iOS, and Web platform folders with necessary configuration files.

4. **Run the application**:
   ```bash
   flutter run
   ```

## Project Structure

```
frontend/
├── lib/
│   ├── main.dart          # Application entry point
│   ├── models/            # Data models
│   ├── services/          # API services
│   ├── providers/         # State management
│   ├── screens/           # UI screens
│   ├── widgets/           # Reusable widgets
│   └── utils/             # Utility functions
├── test/                  # Unit tests
├── pubspec.yaml           # Dependencies and configuration
└── README.md             # This file
```

## API Configuration

The backend API is running at: `http://localhost:8080`

Update the API base URL in your service files as needed.

## Features to Implement

- [ ] User Authentication (Login/Logout)
- [ ] Dashboard
- [ ] Product Management
- [ ] Sales/Checkout
- [ ] Analytics
- [ ] Branch Management (CEO)
- [ ] User Management (CEO)

## Development

1. **Get dependencies**:
   ```bash
   flutter pub get
   ```

2. **Run in development mode**:
   ```bash
   flutter run
   ```

3. **Build for production**:
   ```bash
   flutter build apk        # Android
   flutter build ios        # iOS
   flutter build web        # Web
   ```

## Dependencies

Key dependencies included:
- `http` / `dio` - HTTP client for API calls
- `provider` - State management
- `go_router` - Navigation/routing
- `shared_preferences` - Local storage
- `intl` - Internationalization











