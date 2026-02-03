# Atmosyn App - Technical Analysis Report

**Project Name:** Atmosyn (Meteoflow)  
**Platform:** Flutter Cross-Platform Application  
**Version:** 1.0.0+1  
**Last Updated:** February 2026  

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Application Overview](#2-application-overview)
3. [Technical Architecture](#3-technical-architecture)
4. [Project Structure](#4-project-structure)
5. [Data Models](#5-data-models)
6. [Features Analysis](#6-features-analysis)
7. [Dependencies & Libraries](#7-dependencies--libraries)
8. [Screens & UI Components](#8-screens--ui-components)
9. [Services Layer](#9-services-layer)
10. [Current Limitations](#10-current-limitations)
11. [Recommendations](#11-recommendations)
12. [Appendix](#12-appendix)

---

## 1. Executive Summary

**Atmosyn** is a Flutter-based mobile and web application designed for collecting and managing meteorological and hydrological data in Nepal. The application serves as a data collection tool for field workers (collectors) to record rainfall measurements and spring/stream discharge data, with real-time synchronization to Firebase Firestore.

### Key Highlights:
- **Purpose:** Hydrometeorological data collection for Nepal
- **Target Users:** Field data collectors and administrators
- **Data Types:** Rainfall (mm) and Spring Discharge (LPS)
- **Backend:** Firebase Firestore with real-time sync
- **Export Format:** Wide-format CSV with 8-row headers

---

## 2. Application Overview

### 2.1 Core Functionality

The application provides the following primary capabilities:

| Feature | Description |
|---------|-------------|
| **Data Entry** | Record rainfall and discharge measurements with date, collector, and station information |
| **Data Viewing** | View collected data with date range and station filters |
| **Data Export** | Export data to CSV format with wide/pivot table structure |
| **Map Visualization** | Interactive map showing station locations across Nepal |
| **Station Charts** | Line charts showing historical data trends per station |
| **Collector Management** | Add, edit, and manage data collectors and their assigned stations |

### 2.2 Data Collection Workflow

```
Collector Selection → Date Selection → Station Selection → Value Entry → Save to Firestore
```

### 2.3 Station Configuration

The application supports **5 predefined data collectors** with assigned stations:

| Collector | Rain Stations | Flow Stations |
|-----------|--------------|---------------|
| Chhabi Thapa | - | Flow_311050406 |
| Niruta Purbachhane | Index_311050201, Index_110701_Daily, Index_110702_Daily | Flow_311050218, Flow_311050219 |
| Menuka Rai | Index_311050601, Index_585_Daily | Flow_311050719, Flow_311050602 |
| Yuvaraja Shrestha | Index_311060401, Index_1115_Daily | Flow_311060410, Flow_311060306 |
| Muna Kumari Pahadi | Index_311060301 | Flow_311060306 |

---

## 3. Technical Architecture

### 3.1 Technology Stack

| Layer | Technology |
|-------|-----------|
| **Framework** | Flutter (Dart SDK ^3.10.4) |
| **State Management** | StatefulWidget with StreamBuilder |
| **Backend** | Firebase Firestore |
| **Authentication** | Not implemented (UI only) |
| **Local Storage** | Not implemented (sqflite available but unused) |
| **Maps** | flutter_map with OpenStreetMap tiles |
| **Charts** | fl_chart |
| **CSV Export** | csv, path_provider, share_plus |

### 3.2 Architecture Pattern

The application follows a **simple layered architecture**:

```
┌─────────────────────────────────────┐
│           UI Layer (Screens)        │
│  - AddRecordScreen                  │
│  - ViewDataScreen                   │
│  - DashboardScreen                  │
│  - SettingsScreen                   │
├─────────────────────────────────────┤
│         Service Layer               │
│  - FirestoreService                 │
│  - CsvExportService                 │
├─────────────────────────────────────┤
│         Model Layer                 │
│  - DataRecord                       │
│  - Collector                        │
│  - StationMapping                   │
├─────────────────────────────────────┤
│         Data Layer                  │
│  - Firebase Firestore               │
└─────────────────────────────────────┘
```

### 3.3 Data Flow

1. **User Input** → Screen Widgets
2. **Form Validation** → Local state management
3. **Data Creation** → Model objects (DataRecord, Collector)
4. **Persistence** → FirestoreService → Firebase Firestore
5. **Real-time Updates** → StreamBuilder → UI refresh
6. **Export** → CsvExportService → Local file → Share

---

## 4. Project Structure

```
Atmosyn_App/Meteoflow/Meteoflow/lib/
│
├── main.dart                          # Application entry point
├── firebase_options.dart              # Firebase configuration
│
├── models/                            # Data models
│   ├── data_record.dart               # Core data record model
│   ├── collector.dart                 # Collector model
│   └── station_mapping.dart           # Static station configuration
│
├── screens/                           # UI screens
│   ├── main_container_screen.dart     # Bottom navigation container
│   ├── add_record_screen.dart         # Data entry form
│   ├── view_data_screen.dart          # Data list with filters
│   ├── dashboard_screen.dart          # Map visualization
│   ├── login_screen.dart              # Login UI (non-functional)
│   ├── settings_screen.dart           # Collector management
│   └── station_viz_dialog.dart        # Station data charts
│
├── services/                          # Business logic
│   ├── firestore_service.dart         # Firebase CRUD operations
│   └── csv_export_service.dart        # CSV export functionality
│
├── widgets/                           # Reusable UI components
│   └── record_card.dart               # Data record display card
│
└── utils/                             # Utilities
    └── constants.dart                 # App colors, styles, constants
```

---

## 5. Data Models

### 5.1 DataRecord

**Purpose:** Represents a single data collection entry (rainfall or discharge)

**File:** `lib/models/data_record.dart`

**Properties:**

| Property | Type | Description |
|----------|------|-------------|
| `date` | String | Date in yyyy-MM-dd format |
| `collector` | String | Name of the data collector |
| `rainStation` | String? | Rainfall station ID (optional) |
| `rainfall` | String? | Rainfall value in mm (optional) |
| `flowStation` | String? | Flow/discharge station ID (optional) |
| `discharge` | String? | Discharge value in LPS (optional) |
| `lastUpdated` | DateTime | Timestamp of last modification |

**Key Methods:**
- `documentId`: Generates unique ID as `DATE_STATION`
- `toJson()`: Serializes to Firestore format
- `fromJson()`: Deserializes from Firestore
- `copyWith()`: Creates modified copy

**Document ID Format:**
```dart
'${date}_$sanitizedStationId'
// Example: "2026-02-02_Index_311050201"
```

### 5.2 Collector

**Purpose:** Represents a data collector with their assigned stations

**File:** `lib/models/collector.dart`

**Properties:**

| Property | Type | Description |
|----------|------|-------------|
| `id` | String | Firestore document ID |
| `name` | String | Collector's full name |
| `rainStations` | List<String> | Assigned rainfall station IDs |
| `flowStations` | List<String> | Assigned flow station IDs |

**Key Methods:**
- `fromFirestore()`: Creates from Firestore document
- `toFirestore()`: Serializes for Firestore
- `copyWith()`: Creates modified copy

### 5.3 StationMapping

**Purpose:** Static configuration for station metadata and coordinates

**File:** `lib/models/station_mapping.dart`

**Static Properties:**

| Property | Type | Description |
|----------|------|-------------|
| `mapping` | Map<String, Map<String, List<String>>> | Collector → station type → station IDs |
| `collectors` | List<String> | List of all collector names |
| `metadata` | Map<String, Map<String, String>> | Station ID → metadata (region, lat, lon, etc.) |
| `coordinates` | Map<String, List<double>> | Station ID → [latitude, longitude] |

**Metadata Structure per Station:**
```dart
{
  'region': 'District name',
  'muni': 'Municipality/Ward',
  'loc': 'Location Description',
  'lat': 'Latitude (*N)',
  'lon': 'Longitude (*E)',
  'alt': 'Altitude (m)',
  'collector': 'Data collector name'
}
```

**Helper Methods:**
- `getRainStations(collector)`: Returns rain stations for a collector
- `getFlowStations(collector)`: Returns flow stations for a collector
- `getAllRainStations()`: Returns all unique rain stations
- `getAllFlowStations()`: Returns all unique flow stations
- `getCoordinates(stationId)`: Returns [lat, lng] for a station

---

## 6. Features Analysis

### 6.1 Data Entry (Add Record Screen)

**File:** `lib/screens/add_record_screen.dart`

**Features:**
- Collector selection dropdown (populated from Firestore)
- Date picker with calendar interface
- Entry type toggle: Rainfall vs Discharge
- Dynamic station dropdown based on collector assignment
- Value input with validation
- Success/error feedback via SnackBar

**Form Validation:**
- Collector must be selected
- Station must be selected
- Value must not be empty

**Data Saving:**
```dart
DataRecord(
  date: 'yyyy-MM-dd',
  collector: collectorName,
  rainStation: selectedRainStation,  // or null
  rainfall: rainfallValue,           // or null
  flowStation: selectedFlowStation,  // or null
  discharge: dischargeValue,         // or null
  lastUpdated: DateTime.now(),
)
```

### 6.2 Data Viewing (View Data Screen)

**File:** `lib/screens/view_data_screen.dart`

**Features:**
- Real-time data list via Firestore streams
- Date range filter with date picker
- Station filter dropdown
- Record count display
- CSV export options (Rainfall/Discharge)
- Record cards showing date, collector, and values

**Filtering Logic:**
- Date filter: Records within selected range
- Station filter: Records matching selected station ID
- Combined filters supported

**Export Behavior:**
- Exports ALL records from Firestore (not just filtered view)
- Separate exports for rainfall and discharge data
- Uses share_plus for file sharing

### 6.3 Map Dashboard

**File:** `lib/screens/dashboard_screen.dart`

**Features:**
- Interactive map using flutter_map
- OpenStreetMap base tiles
- Nepal GeoJSON boundaries (Province, District, Palika)
- Station markers with icons:
  - Rain stations: Water drop icon (cyan)
  - Flow stations: Waves icon (blue)
- Double-tap marker to view station charts
- Zoom controls (in/out floating buttons)

**GeoJSON Sources:**
- Provinces: `nepal-with-provinces-acesmndr.geojson`
- Districts: `nepal-with-districts-acesmndr.geojson`
- Palikas: `municipalities.simplified.geojson`

**Map Configuration:**
```dart
initialCenter: LatLng(28.3949, 84.1240)  // Center of Nepal
initialZoom: 7
minZoom: 5
```

### 6.4 Station Visualization Dialog

**File:** `lib/screens/station_viz_dialog.dart`

**Features:**
- Line chart showing historical data for a station
- Uses fl_chart library
- X-axis: Dates (MM/dd format)
- Y-axis: Values (rainfall mm or discharge LPS)
- Curved line with area fill
- Data points as dots
- Responsive sizing

**Chart Configuration:**
- Curved line with gradient fill
- Grid lines for readability
- Date labels on bottom axis
- Value labels on left axis

### 6.5 Settings Screen

**File:** `lib/screens/settings_screen.dart`

**Features:**
- View all collectors from Firestore
- Add new collectors
- Edit collector station assignments
- Delete collectors
- Auto-seed default collectors on first load

**Station Editor:**
- Bottom sheet interface
- Add/remove rain stations
- Add/remove flow stations
- Real-time Firestore updates

### 6.6 CSV Export Service

**File:** `lib/services/csv_export_service.dart`

**Export Format:** Wide/Pivot Table

**8-Row Header Structure:**
| Row | Content | Example |
|-----|---------|---------|
| 1 | District | Kathmandu |
| 2 | Municipality/Ward | KMC-1 |
| 3 | Location Description | Naxal |
| 4 | Latitude (*N) | 27.721 |
| 5 | Longitude (*E) | 85.342 |
| 6 | Altitude (m) | 1350 |
| 7 | Data Collector | Niruta Purbachhane |
| 8 | Station ID | Index_311050201 |

**Data Structure:**
- Rows: Dates (sorted ascending)
- Columns: Station IDs (sorted alphabetically)
- Cells: Measurement values (empty if no data)

**Export Files:**
- `rainfall_data_wide.csv` - Rainfall data only
- `discharge_data_wide.csv` - Discharge data only

---

## 7. Dependencies & Libraries

### 7.1 Core Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `flutter` | SDK | UI framework |
| `cupertino_icons` | ^1.0.8 | iOS-style icons |

### 7.2 Firebase Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `firebase_core` | ^3.8.1 | Firebase initialization |
| `cloud_firestore` | ^5.5.0 | Cloud database |

### 7.3 CSV Export Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `csv` | ^6.0.0 | CSV generation |
| `path_provider` | ^2.1.5 | File system access |
| `share_plus` | 10.1.3 | File sharing |

### 7.4 Date & Time Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `intl` | ^0.19.0 | Date formatting |

### 7.5 Mapping Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `flutter_map` | ^7.0.2 | Map visualization |
| `latlong2` | ^0.9.1 | Latitude/longitude calculations |

### 7.6 Chart Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `fl_chart` | ^0.70.2 | Line charts |

### 7.7 Network Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `http` | ^1.2.1 | GeoJSON fetching |

### 7.8 Utility Dependencies (Unused)

| Package | Version | Status |
|---------|---------|--------|
| `equatable` | ^2.0.8 | Available, unused |
| `sqflite` | ^2.4.2 | Available, unused |
| `path` | ^1.9.1 | Available, unused |
| `dartz` | ^0.10.1 | Available, unused |
| `get_it` | ^9.2.0 | Available, unused |
| `internet_connection_checker` | ^3.0.1 | Available, unused |

---

## 8. Screens & UI Components

### 8.1 MainContainerScreen

**Purpose:** Bottom navigation container

**Navigation Items:**
| Index | Icon | Label | Screen |
|-------|------|-------|--------|
| 0 | add_circle | Add Record | AddRecordScreen |
| 1 | table_chart | View Data | ViewDataScreen |
| 2 | dashboard | Dashboard | DashboardScreen |

**UI Component:** Material 3 NavigationBar

### 8.2 AddRecordScreen

**Layout:**
- AppBar with title
- Form with card-based layout
- SegmentedButton for entry type selection
- Dropdowns for collector and station
- Date picker button
- TextField for value input
- Submit button with loading state

**State Management:**
- Form key for validation
- Selected collector ID
- Selected date
- Entry type (rain/discharge)
- Available stations (dynamic based on collector)
- Loading state for submission

### 8.3 ViewDataScreen

**Layout:**
- AppBar with export button
- Filter card with date range and station dropdown
- Record count display
- Scrollable list of RecordCards
- Empty state when no data

**Filters:**
- Date range picker
- Station dropdown (populated from records)
- Clear filter buttons

### 8.4 DashboardScreen

**Layout:**
- AppBar with refresh button and loading indicator
- Full-screen FlutterMap
- Floating action buttons for zoom
- Station markers overlay

**Map Layers (bottom to top):**
1. OpenStreetMap tile layer
2. Palika boundaries (grey, thin)
3. District boundaries (black, medium)
4. Province boundaries (blue, thick)
5. Station markers

### 8.5 LoginScreen

**Layout:**
- Split-screen card design
- Left side: User login (image header, username, password, PP fields)
- Right side: Admin login
- Remember me checkbox
- Login button

**Status:** UI only - no actual authentication implemented

### 8.6 SettingsScreen

**Layout:**
- AppBar with title
- Floating action button to add collectors
- StreamBuilder for collectors list
- List tiles for each collector
- Edit/delete actions per collector

### 8.7 StationVizDialog

**Layout:**
- AlertDialog with station ID as title
- SizedBox containing LineChart
- Close button

**Loading States:**
- CircularProgressIndicator while loading
- Empty message if no data

### 8.8 RecordCard Widget

**Layout:**
- Card with padding
- Date header (formatted)
- Collector name (caption style)
- Rain data row (if present) with water_drop icon
- Flow data row (if present) with waves icon

**Icons:**
- Rain: `Icons.water_drop` (primary color)
- Flow: `Icons.waves` (primary color)

---

## 9. Services Layer

### 9.1 FirestoreService

**File:** `lib/services/firestore_service.dart`

**Purpose:** Handles all Firebase Firestore operations

**Collections:**
- `records` - Data collection entries
- `collectors` - Collector profiles

**Record Operations:**

| Method | Description |
|--------|-------------|
| `saveRecord(record)` | Upsert record with merge |
| `clearAllRecords()` | Delete all records (batch) |
| `getRecordsStream()` | Real-time stream of all records |
| `getAllRecords()` | One-time fetch (for CSV export) |
| `deleteRecord(docId)` | Delete specific record |
| `getRecordCount()` | Get total record count |

**Collector Operations:**

| Method | Description |
|--------|-------------|
| `getCollectorsStream()` | Real-time stream of collectors |
| `addCollector(name)` | Add new collector |
| `updateCollector(collector)` | Update collector data |
| `removeCollector(id)` | Delete collector |
| `seedDefaultCollectors()` | Initialize default collectors |

**Seeding Logic:**
1. Check if collectors collection is empty
2. For each collector in StationMapping.mapping:
   - If not exists, create with assigned stations
3. For each collector in StationMapping.collectors:
   - If not in mapping, create with empty stations

### 9.2 CsvExportService

**File:** `lib/services/csv_export_service.dart`

**Purpose:** Export data to CSV format

**Export Methods:**

| Method | Output File | Data Type |
|--------|-------------|-----------|
| `exportRainData(records)` | rainfall_data_wide.csv | Rainfall measurements |
| `exportDischargeData(records)` | discharge_data_wide.csv | Discharge measurements |

**Export Process:**
1. Get all stations of the target type
2. Build 8-row header from StationMapping.metadata
3. Create pivot data structure (date → station → value)
4. Sort dates ascending
5. Build data rows
6. Convert to CSV string using ListToCsvConverter
7. Save to temporary directory
8. Share via share_plus

**Header Rows Generated:**
1. District (region)
2. Municipality/Ward (muni)
3. Location Description (loc)
4. Latitude (*N) (lat)
5. Longitude (*E) (lon)
6. Altitude (m) (alt)
7. Data collector (collector)
8. Station ID (station ID itself)

---

## 10. Current Limitations

### 10.1 Authentication
- **Issue:** Login screen is UI-only with no actual authentication
- **Impact:** No user security or role-based access
- **Risk:** Anyone can access and modify data

### 10.2 Offline Support
- **Issue:** No offline data persistence
- **Impact:** App requires constant internet connection
- **Risk:** Data loss if connection drops during entry

### 10.3 Data Validation
- **Issue:** Minimal validation on numeric inputs
- **Impact:** Can enter invalid values (negative, non-numeric)
- **Risk:** Data quality issues

### 10.4 Settings Accessibility
- **Issue:** Settings screen not linked in main navigation
- **Impact:** Users cannot access collector management
- **Workaround:** Must navigate programmatically

### 10.5 Unused Dependencies
- **Issue:** Several packages included but not used
- **Packages:** flutter_bloc, sqflite, dartz, get_it, internet_connection_checker
- **Impact:** Increased app size, potential confusion

### 10.6 CSV Export Scope
- **Issue:** Export always exports ALL records, not filtered view
- **Impact:** Cannot export specific date ranges or stations only
- **Note:** This may be intentional per code comments

### 10.7 Error Handling
- **Issue:** Basic error handling with generic messages
- **Impact:** Users may not understand error causes
- **Risk:** Poor user experience during failures

### 10.8 No Data Import
- **Issue:** No functionality to import existing data
- **Impact:** Cannot migrate historical data
- **Risk:** Data silos

---

## 11. Recommendations

### 11.1 High Priority

1. **Implement Firebase Authentication**
   - Add email/password authentication
   - Implement role-based access (admin vs collector)
   - Secure Firestore rules based on user roles

2. **Add Offline Support**
   - Enable Firestore offline persistence
   - Implement sqflite for local caching
   - Add sync status indicators

3. **Improve Data Validation**
   - Validate numeric ranges (rainfall ≥ 0, discharge ≥ 0)
   - Add input masks for decimal values
   - Prevent duplicate entries for same date/station

### 11.2 Medium Priority

4. **Clean Up Dependencies**
   - Remove unused packages (sqflite, dartz, get_it) OR
   - Implement proper architecture using these packages
   - Consider BLoC pattern since flutter_bloc is included

5. **Add Settings to Navigation**
   - Include Settings in bottom navigation OR
   - Add to AppBar menu
   - Make collector management accessible

6. **Enhance CSV Export**
   - Option to export filtered data only
   - Add export progress indicator
   - Support additional formats (Excel, JSON)

### 11.3 Low Priority

7. **Add Data Import**
   - Import from CSV
   - Bulk data upload
   - Data migration tools

8. **Improve Error Handling**
   - User-friendly error messages
   - Retry mechanisms
   - Error logging

9. **Add Unit Tests**
   - Test CSV export logic
   - Test data models
   - Test service layer

10. **UI/UX Improvements**
    - Dark mode support
    - Responsive layout for tablets
    - Loading skeletons
    - Pull-to-refresh

---

## 12. Appendix

### 12.1 Station Metadata Sample

```dart
'Index_311050201': {
  'region': 'Kathmandu',
  'muni': 'KMC-1',
  'loc': 'Naxal',
  'lat': '27.721',
  'lon': '85.342',
  'alt': '1350',
  'collector': 'Niruta Purbachhane',
}
```

### 12.2 CSV Export Sample Structure

```csv
District,Kathmandu,Kathmandu,Kaski
Municipality,KMC-1,KMC-3,Pokhara-6
Location,Naxal,Lazimpat,Lakeside
Latitude,27.721,27.712,28.192
Longitude,85.342,85.312,84.012
Altitude,1350,1320,820
Collector,Niruta,Niruta,Menuka
Date,Index_311050201,Flow_311050218,Index_311050601
2026-01-01,15.2,,12.5
2026-01-02,8.5,45.2,6.0
2026-01-03,,52.1,18.3
```

### 12.3 Firestore Document Structure

**Records Collection:**
```
records/{date}_{stationId}
  - date: "2026-02-02"
  - collector: "Niruta Purbachhane"
  - rainStation: "Index_311050201"
  - rainfall: "15.5"
  - lastUpdated: Timestamp
```

**Collectors Collection:**
```
collectors/{autoId}
  - name: "Niruta Purbachhane"
  - rain: ["Index_311050201", "Index_110701_Daily"]
  - flow: ["Flow_311050218", "Flow_311050219"]
```

### 12.4 File Statistics

| File Type | Count | Lines of Code (approx) |
|-----------|-------|------------------------|
| Models | 3 | ~500 |
| Screens | 7 | ~2000 |
| Services | 2 | ~400 |
| Widgets | 1 | ~100 |
| Utils | 1 | ~60 |
| **Total** | **14** | **~3060** |

---

## Document Information

- **Analysis Date:** February 2, 2026
- **Analyst:** Kilo Code
- **App Version:** 1.0.0+1
- **Flutter SDK:** ^3.10.4
- **Repository:** https://github.com/rajendra369/AtmosynApp

---

*End of Technical Analysis Report*