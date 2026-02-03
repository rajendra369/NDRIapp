# Data Collector - Flutter App

A Flutter mobile application for collecting rainfall and spring discharge data with Firebase cloud storage.

## Features

✅ **Data Entry Form**
- Select data collector from predefined list
- Date picker (defaults to today)
- Toggle between Rainfall and Discharge entry
- Dynamic station dropdowns based on collector
- Decimal input for measurements

✅ **Real-time Data Sync**
- Automatic cloud backup to Firebase Firestore
- Real-time updates across devices
- Upsert logic (one entry per date-station)

✅ **Data Management**
- View all recorded data in chronological order
- Record count display
- Formatted date and value display

✅ **CSV Export**
- Export rainfall data in wide format
- Export discharge data in wide format
- Share exported files via any app

## Project Structure

```
lib/
├── main.dart                          # App entry point
├── models/
│   ├── data_record.dart              # Data model
│   └── station_mapping.dart          # Collector-station mappings
├── screens/
│   └── home_screen.dart              # Main screen
├── services/
│   ├── firestore_service.dart        # Firebase operations
│   └── csv_export_service.dart       # CSV export logic
├── widgets/
│   └── record_card.dart              # Record display widget
└── utils/
    └── constants.dart                # App constants & theme
```

## Setup Instructions

### Prerequisites

- ✅ Flutter SDK installed (3.38.5 or later)
- ✅ Android Studio or VS Code with Flutter extension
- ✅ Firebase account

### 1. Clone/Navigate to Project

```powershell
cd c:\Users\raj10\Desktop\app\data_collector
```

### 2. Install Dependencies

```powershell
flutter pub get
```

### 3. Configure Firebase

**Option A: Using FlutterFire CLI (Recommended)**

```powershell
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase
flutterfire configure
```

**Option B: Manual Setup**

See [Firebase Setup Guide](../../../.gemini/antigravity/brain/dac62698-8b9f-40fb-ba3c-2299514a16e8/firebase_setup_guide.md) for detailed instructions.

### 4. Run the App

```powershell
# Check connected devices
flutter devices

# Run on connected device
flutter run

# Or run in release mode
flutter run --release
```

### 5. Build APK for Distribution

```powershell
# Build release APK
flutter build apk --release

# APK location:
# build/app/outputs/flutter-apk/app-release.apk
```

## Station Mappings

| Collector | Rain Stations | Flow Stations |
|-----------|---------------|---------------|
| Chhabi Thapa | - | Flow_311050406 |
| Niruta Purbachhane | Index_311050201, Index_110701_Daily, Index_110702_Daily | Flow_311050218, Flow_311050219 |
| Menuka Rai | Index_311060601, Index_585_Daily | Flow_311050719, Flow_311050602 |
| Yuvaraja Shrestha | Index_311060401, Index_1115_Daily | Flow_311060410, Flow_311060306 |
| Muna Kumari Pahadi | - | - |

## Firebase Configuration

### Firestore Collection Structure

```
records/
  └── {date}_{station}/
      ├── date: "2025-12-24"
      ├── collector: "Niruta Purbachhane"
      ├── rainStation: "Index_311050201" (optional)
      ├── rainfall: "15.5" (optional)
      ├── flowStation: "Flow_311050218" (optional)
      ├── discharge: "2.34" (optional)
      └── lastUpdated: "2025-12-24T10:30:00.000Z"
```

### Security Rules (Development)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /records/{recordId} {
      allow read, write: if true;
    }
  }
}
```

## Troubleshooting

### App won't build

```powershell
# Clean build
flutter clean
flutter pub get
flutter build apk
```

### Firebase connection issues

1. Verify `google-services.json` is in `android/app/`
2. Run `flutterfire configure` again
3. Check internet connection
4. Verify Firestore rules allow read/write

### Android license issues

```powershell
flutter doctor --android-licenses
```

## Development

### Adding New Collectors

Edit `lib/models/station_mapping.dart`:

```dart
static const Map<String, Map<String, List<String>>> mapping = {
  'New Collector Name': {
    'rain': ['Station1', 'Station2'],
    'flow': ['Flow1', 'Flow2']
  },
  // ... existing collectors
};

static const List<String> collectors = [
  'New Collector Name',
  // ... existing collectors
];
```

### Customizing Theme

Edit `lib/utils/constants.dart` to change colors, spacing, or text styles.

## Tech Stack

- **Framework:** Flutter 3.38.5
- **Language:** Dart 3.10.4
- **Backend:** Firebase Firestore
- **Platform:** Android (Kotlin)
- **Dependencies:**
  - `firebase_core` - Firebase initialization
  - `cloud_firestore` - Cloud database
  - `csv` - CSV file generation
  - `path_provider` - File system access
  - `share_plus` - File sharing
  - `intl` - Date formatting

## Migration from Web App

This Flutter app replaces the previous Capacitor-based web application with:
- ✅ Native performance
- ✅ Better offline support
- ✅ Improved UI/UX
- ✅ Type-safe Dart code
- ✅ Same Firebase backend (data compatible)

## License

Private project for data collection purposes.
