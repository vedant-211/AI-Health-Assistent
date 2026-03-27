# Emulator Testing Guide - SwasthMitra AI

This guide ensures safe and successful testing on Android and iOS emulators.

---

## Quick Start

### ✅ Prerequisites
- Flutter SDK 3.4.3 or later
- Valid Google Generative AI API key
- Firebase project configured
- Emulator with internet connectivity

---

## Android Emulator Setup

### 1. Enable Mock Location Support

**For API Level 29+:**
```bash
# Start emulator
emulator -avd pixel_4_api_31 -writable-system
```

**In Emulator:**
1. Settings > Apps > Special app access > Apps with permission access
2. Look for your app or Maps
3. Ensure mock location app permission is granted

### 2. Configure Environment Variables

Create `.env` file in project root:
```
GOOGLE_API_KEY=your_actual_api_key_here
FIREBASE_PROJECT_ID=your_firebase_project
FIREBASE_API_KEY=your_firebase_api_key
```

### 3. Run Tests

```bash
# Clean and get dependencies
flutter clean
flutter pub get

# Run on emulator
flutter run -v

# Run with specific device
flutter run -d emulator-5554
```

### 4. Mock Geolocation

In the Android Emulator:
1. Extended Controls (⋮) > Location
2. Set Mock Latitude/Longitude
3. Click "Send"
4. App will receive mocked GPS data

**Alternative - Use Maps Simulation:**
```bash
telnet localhost 5554
geo fix 40.7128 -74.0060  # NYC coordinates
```

### 5. Mock Camera/Gallery

- Emulator > Settings > Apps > Permissions
- Grant Camera and Photos permissions
- Use emulator's virtual camera or gallery files

---

## iOS Simulator Setup

### 1. Simulator Configuration

```bash
# List available simulators
xcrun simctl list devices

# Boot specific simulator
xcrun simctl boot "iPhone 15"

# Or use Flutter
flutter run -d "iPhone 15"
```

### 2. Set Mock Location

**Method 1: Xcode**
1. Xcode > Debug > Simulate Location
2. Select from predefined locations
3. Or set custom coordinates

**Method 2: Terminal**
```bash
# Requires Xcode setup
xcrun simctl location set "iPhone 15" "40.7128 -74.0060"
```

### 3. Environment Configuration

Same as Android - use `.env` or `ios/Runner/Info.plist` for Firebase config.

### 4. Test Camera/Photos

- Simulator > Features > Camera
- Use system Photos app for gallery simulation

---

## Firebase Emulator Setup (Recommended)

### 1. Install Firebase CLI

```bash
npm install -g firebase-tools
firebase login
```

### 2. Initialize Emulator

```bash
cd project_root
firebase init emulators

# Select: Firestore, Storage, Authentication
firebase emulators:start
```

### 3. Configure Flutter App

Update `lib/main.dart`:

```dart
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "YOUR_API_KEY",
      projectId: "YOUR_PROJECT_ID",
      messagingSenderId: "YOUR_SENDER_ID",
      appId: "YOUR_APP_ID",
    ),
  );

  // Connect to emulator (only for testing)
  if (kDebugMode) {
    try {
      FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
      FirebaseStorage.instance.useStorageEmulator('localhost', 9199);
    } catch (e) {
      // Already initialized
    }
  }

  runApp(const MyApp());
}
```

### 4. Run Emulator & App

```bash
# Terminal 1: Start Firebase Emulator
firebase emulators:start

# Terminal 2: Run Flutter app
flutter run
```

---

## Google Generative AI API Testing

### 1. Get API Key

1. Visit [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Create new API key
3. Add to your `.env` or `main.dart`:

```dart
const String apiKey = "your_actual_key";
final model = GenerativeModel(model: 'gemini-2.0-flash', apiKey: apiKey);
```

### 2. Test API Calls

```bash
# Run specific test page
flutter run --target=lib/pages/ai_symptoms.dart

# Then interact with the app
```

---

## Debugging Features

### 1. Enable Verbose Logging

```bash
flutter run -v
```

### 2. Use DevTools

```bash
flutter pub global activate devtools
flutter pub global run devtools

# Then open http://localhost:9100 in browser
```

### 3. Monitor Firebase Calls

Open Firebase Emulator UI:
```
http://localhost:4000
```

View in real-time:
- Firestore writes/reads
- Storage uploads/downloads
- Authentication events

---

## Common Issues & Solutions

### Issue: "Geolocator permission denied"

**Solution:**
```bash
# Android
flutter run --target=lib/pages/nearby_doctors.dart

# Grant location permission in emulator
# Settings > Apps > Permissions > Location > [App Name]

# Then restart app
```

### Issue: "Firebase initialization failed"

**Solution:**
```bash
# Check if emulator is running first
firebase emulators:start

# Verify connection in Flutter debug console
adb logcat | grep Firebase
```

### Issue: "Image picker not showing"

**Solution:**
```bash
# Grant camera and photos permissions
adb shell pm grant com.example.medical android.permission.CAMERA
adb shell pm grant com.example.medical android.permission.READ_EXTERNAL_STORAGE
adb shell pm grant com.example.medical android.permission.WRITE_EXTERNAL_STORAGE

# Restart app
flutter run
```

### Issue: "API rate limit exceeded"

**Solution:**
- Check Google API quota at https://console.cloud.google.com
- Wait for quota reset (typically 100 requests per minute)
- Test with fallback symptoms first

---

## Performance Testing on Emulator

### 1. Monitor Memory Usage

```bash
flutter run --profile

# In DevTools > Memory tab
```

### 2. Monitor Frame Rate

```bash
flutter run --profile

# In DevTools > Performance tab
# Target: 60 FPS on emulator
```

### 3. Test Network Conditions

**Android:**
```bash
emulator -avd pixel_4 -netdelay 100 -netspeed slow
```

**iOS:**
No built-in network throttling, but can use:
```bash
networkQuality -I
```

---

## Automated Testing

### 1. Run Unit Tests

```bash
flutter test test/
```

### 2. Run Widget Tests

```bash
flutter test test/widget_test.dart
```

### 3. Run Integration Tests

```bash
flutter drive --target=test_driver/app.dart
```

---

## Deployment Checklist

Before releasing to real devices:

- [ ] ✅ Tested on Android emulator (API 28-34)
- [ ] ✅ Tested on iOS simulator (iOS 14-17)
- [ ] ✅ Firebase emulator successful
- [ ] ✅ Google API key valid and under quota
- [ ] ✅ All permissions properly requested
- [ ] ✅ Location mocking tested
- [ ] ✅ Image upload/download tested
- [ ] ✅ AI symptom analysis tested
- [ ] ✅ Doctor list retrieval tested
- [ ] ✅ No console errors or warnings

---

## Key Takeaway

🚀 **Your app is fully emulator-safe and has NO Bluetooth dependencies!**

All features work on emulators:
- ✅ AI analysis (API-based)
- ✅ Geolocation (Mock location support)
- ✅ Image selection (Emulator camera/gallery)
- ✅ Firebase (Emulator suite)
- ✅ Real-time updates (Network-based)

Proceed with confidence! 🎉

---

*Last Updated: March 18, 2026*
