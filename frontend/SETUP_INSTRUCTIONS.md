# Flutter Frontend Setup Instructions

## Quick Start

Since Flutter CLI was not found on your system, follow these steps to complete the setup:

### Step 1: Install Flutter

1. **Download Flutter**:
   - Visit: https://docs.flutter.dev/get-started/install/windows
   - Download the Flutter SDK zip file
   - Extract it to a location like `C:\src\flutter` (avoid spaces in path)

2. **Add Flutter to PATH**:
   - Open "Environment Variables" in Windows
   - Add `C:\src\flutter\bin` to your PATH
   - Restart your terminal/IDE

3. **Verify Installation**:
   ```powershell
   flutter doctor
   ```

### Step 2: Complete Flutter Project Setup

Once Flutter is installed, navigate to the frontend folder and run:

```powershell
cd frontend
flutter pub get
flutter create .
```

The `flutter create .` command will:
- Create Android, iOS, and Web platform folders
- Generate necessary configuration files
- Set up the project structure properly

**Note**: When prompted about overwriting files, you can choose to keep existing files (like `pubspec.yaml` and `lib/main.dart` that were already created).

### Step 3: Run the Application

```powershell
flutter run
```

This will:
1. Analyze the project
2. Install dependencies
3. Launch the app on available devices (Chrome, Android emulator, etc.)

## Alternative: Manual Platform Setup

If you prefer to set up platforms manually or want to target specific platforms:

### For Android Only:
```powershell
flutter create --platforms=android .
```

### For Web Only:
```powershell
flutter create --platforms=web .
```

### For iOS (macOS only):
```powershell
flutter create --platforms=ios .
```

## Development Workflow

1. **Install dependencies**:
   ```powershell
   flutter pub get
   ```

2. **Check for issues**:
   ```powershell
   flutter doctor
   flutter analyze
   ```

3. **Run the app**:
   ```powershell
   flutter run
   ```

4. **Hot reload**: Press `r` in the terminal while the app is running
5. **Hot restart**: Press `R` in the terminal
6. **Quit**: Press `q` in the terminal

## Project Structure

The project has been initialized with:

- ✅ `pubspec.yaml` - Dependencies and configuration
- ✅ `lib/main.dart` - Entry point with basic app structure
- ✅ `.gitignore` - Git ignore rules
- ✅ `analysis_options.yaml` - Linter configuration
- ⚠️ Platform folders - Will be created with `flutter create .`

## Next Steps

After completing the setup:

1. Review `lib/main.dart` and customize the initial screen
2. Create folder structure:
   - `lib/models/` - Data models
   - `lib/services/` - API services
   - `lib/screens/` - UI screens
   - `lib/widgets/` - Reusable widgets
   - `lib/providers/` - State management
   - `lib/utils/` - Utility functions

3. **Configure API URL**: Update `lib/config/api_config.dart` with the correct backend URL:
   - **Android Emulator**: `http://10.0.2.2:8080` (default)
   - **iOS Simulator**: `http://localhost:8080`
   - **Physical Device**: Use your computer's local IP (e.g., `http://192.168.1.100:8080`)
   
   To find your computer's IP:
   - Windows: Run `ipconfig` in PowerShell and look for IPv4 Address
   - macOS/Linux: Run `ifconfig` or `ip addr`

## API Configuration

The app connects to the backend API configured in `lib/config/api_config.dart`.

### Default Configuration
- Default URL: `http://10.0.2.2:8080` (for Android emulator)
- Timeout: 30 seconds

### Changing the API URL

Edit `lib/config/api_config.dart`:

```dart
class ApiConfig {
  // For Android Emulator (default):
  static const String baseUrl = 'http://10.0.2.2:8080';
  
  // For iOS Simulator:
  // static const String baseUrl = 'http://localhost:8080';
  
  // For Physical Device (replace with your computer's IP):
  // static const String baseUrl = 'http://192.168.1.100:8080';
}
```

### Troubleshooting Connection Issues

**Error: "Connection timeout" or "SocketConnection timed out"**

1. **Check Backend Server**:
   - Ensure Spring Boot backend is running on port 8080
   - Verify with: `curl http://localhost:8080/api/auth/login` (or your configured URL)

2. **Check API Configuration**:
   - Open `lib/config/api_config.dart`
   - Verify the `baseUrl` matches your setup:
     - Android Emulator → `http://10.0.2.2:8080`
     - iOS Simulator → `http://localhost:8080`
     - Physical Device → Your computer's local IP (e.g., `http://192.168.1.100:8080`)

3. **Network Connectivity**:
   - Ensure device/emulator and computer are on the same network
   - Check firewall settings (Windows Firewall may block connections)
   - Try accessing the backend URL from a browser on the same device

4. **Backend CORS Configuration**:
   - Ensure backend allows requests from your Flutter app origin
   - Check Spring Security CORS configuration

## Troubleshooting

### Flutter command not found
- Ensure Flutter is in your PATH
- Restart your terminal after adding to PATH
- Verify with: `flutter --version`

### Dependencies issues
```powershell
flutter clean
flutter pub get
```

### Build errors
```powershell
flutter doctor -v
```
Check the output for any missing components and install them.











