# Troubleshooting Guide - Connection Issues

## Common Error: "TimeoutException after 0:00:30.000000"

This error means your Flutter app cannot reach the backend server. Follow these steps to resolve:

## Step 1: Verify Backend Server is Running

### On Windows (PowerShell):
```powershell
# Check if port 8080 is listening
Get-NetTCPConnection -LocalPort 8080 -ErrorAction SilentlyContinue

# Or check if Spring Boot process is running
Get-Process | Where-Object {$_.ProcessName -like "*java*"}
```

### Check Backend Logs:
Look for this message in your Spring Boot console:
```
Started FlipApplication in X.XXX seconds
```

If you don't see this, start your backend server:
```powershell
cd ..
.\mvnw.cmd spring-boot:run
```

## Step 2: Test Backend Connectivity

### From Your Computer:
Open a browser and navigate to:
```
http://localhost:8080/api/auth/login
```

You should see a response (even if it's an error about missing request body). If you see "This site can't be reached", the backend is not running.

### Using curl (if available):
```powershell
curl http://localhost:8080/api/auth/login -Method POST -ContentType "application/json" -Body '{}'
```

## Step 3: Configure Correct API URL

The API URL depends on where you're running the Flutter app:

### For Android Emulator:
Edit `lib/config/api_config.dart`:
```dart
static const String baseUrl = 'http://10.0.2.2:8080';
```

### For iOS Simulator (macOS only):
```dart
static const String baseUrl = 'http://localhost:8080';
```

### For Physical Device (Phone/Tablet):

1. **Find your computer's IP address:**
   - Windows: Run `ipconfig` in PowerShell
   - Look for "IPv4 Address" under your active network adapter (usually Wi-Fi or Ethernet)
   - Example: `192.168.1.100`

2. **Update api_config.dart:**
   ```dart
   static const String baseUrl = 'http://192.168.1.100:8080';  // Replace with your IP
   ```

3. **Important**: Ensure your phone and computer are on the **same Wi-Fi network**

## Step 4: Check Firewall Settings

Windows Firewall may block incoming connections to port 8080:

1. Open Windows Defender Firewall
2. Click "Advanced settings"
3. Click "Inbound Rules" → "New Rule"
4. Select "Port" → Next
5. Select "TCP" and enter "8080" → Next
6. Select "Allow the connection" → Next
7. Apply to all profiles → Next
8. Name it "Spring Boot 8080" → Finish

Or allow through PowerShell (Run as Administrator):
```powershell
New-NetFirewallRule -DisplayName "Spring Boot 8080" -Direction Inbound -LocalPort 8080 -Protocol TCP -Action Allow
```

## Step 5: Verify Network Connectivity

### If using Physical Device:
1. Ensure your phone and computer are on the same Wi-Fi network
2. Some corporate/public Wi-Fi networks block device-to-device communication
3. Try using your phone's mobile hotspot with your computer connected to it

### If using Emulator:
- Android Emulator should work with `10.0.2.2:8080` automatically
- iOS Simulator should work with `localhost:8080` automatically

## Step 6: Quick Test

After making changes, test the connection:

1. **Hot restart the Flutter app** (press `R` in terminal, or restart completely)
2. Try logging in again
3. Check if the error message provides more details

## Still Having Issues?

### Check Backend CORS Configuration
If you see CORS errors, ensure your Spring Boot `SecurityConfig` allows requests from your Flutter app origin.

### Verify Backend is Listening on All Interfaces
Your Spring Boot app should bind to `0.0.0.0:8080` (not just `localhost`). Check `application.properties`:
```properties
server.address=0.0.0.0
server.port=8080
```

### Use Network Monitoring
- Check Windows Firewall logs
- Use Wireshark or similar tool to see if packets are being sent/received
- Check Spring Boot logs for incoming requests

## Summary Checklist

- [ ] Backend server is running (check console for "Started FlipApplication")
- [ ] Port 8080 is listening (check with `Get-NetTCPConnection`)
- [ ] Backend responds in browser at `http://localhost:8080/api/auth/login`
- [ ] Correct API URL in `lib/config/api_config.dart` for your setup
- [ ] Windows Firewall allows port 8080 (if using physical device)
- [ ] Device and computer on same network (if using physical device)
- [ ] Flutter app has been restarted after changing API URL

