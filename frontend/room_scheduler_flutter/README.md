# 🏫 Room Scheduler — Flutter App

A Flutter mobile application for real-time college classroom availability.

## 📁 Project Structure

```
room_scheduler/
├── lib/
│   ├── main.dart                    # App entry point + bottom nav shell
│   ├── theme.dart                   # Colors, typography, Material theme
│   ├── models/
│   │   ├── room.dart                # Room, RoomWithStatus, TimetableEntry, ScheduleSlot
│   │   ├── booking.dart             # Booking model
│   │   └── teacher.dart             # Teacher model
│   ├── services/
│   │   └── data_service.dart        # All data logic (mock data, room status algorithm)
│   ├── screens/
│   │   ├── home/
│   │   │   ├── dashboard_screen.dart    # Main room status grid
│   │   │   └── room_detail_screen.dart  # Single room schedule
│   │   ├── upload/
│   │   │   └── upload_screen.dart       # PDF upload + manual timetable entry
│   │   └── teacher/
│   │       ├── login_screen.dart        # Teacher authentication
│   │       ├── portal_screen.dart       # Teacher home + bookings list
│   │       └── book_room_screen.dart    # Room booking form
│   ├── widgets/
│   │   ├── room_card.dart           # Room row with status badge
│   │   ├── status_badge.dart        # Free/Busy/Soon pill badge
│   │   ├── time_slot_row.dart       # Schedule timeline row
│   │   └── avatar_widget.dart       # Teacher initials avatar
│   └── providers/
│       ├── room_provider.dart       # Room state management (ChangeNotifier)
│       └── auth_provider.dart       # Teacher auth state
├── pubspec.yaml
└── README.md
```

## 🚀 Getting Started

### Prerequisites
- Flutter SDK ≥ 3.0.0  →  https://flutter.dev/docs/get-started/install
- Android Studio / VS Code with Flutter extension

### Run the app
```bash
# Get dependencies
flutter pub get

# Run on connected device / emulator
flutter run

# Build APK
flutter build apk --release
```

## ✅ Features

| Feature | Details |
|---------|---------|
| 📊 Live Dashboard | Free / Busy / Soon status computed from current time |
| 🔍 Filters | Filter by status (free/busy/soon) or building |
| 📅 Room Schedule | Full hourly timeline 09:00–16:00 with current slot highlighted |
| 📤 PDF Upload | File picker integration + manual entry form |
| 🔐 Teacher Login | Employee ID or quick-select from list |
| 📋 Booking | Book rooms with conflict detection |
| ❌ Cancel Bookings | Cancel any confirmed booking |
| 🔄 Pull to Refresh | Refresh dashboard and bookings |

## 👩‍🏫 Teacher Login IDs

| Employee ID | Name |
|-------------|------|
| AP001 | Dr. Ashutosh Pandey |
| UK002 | Dr. Umesh Kumar |
| VJ003 | Prof. Vikas Jain |
| SM004 | Dr. Shweta Mishra |
| RK005 | Prof. Rakesh Kumar |
| TG006 | Prof. Tanvi Gupta |

## 🏠 Room Status Logic

- 🟢 **FREE** — No class scheduled at current time
- 🔴 **BUSY** — Class in progress right now
- 🟡 **SOON** — Room will be occupied within 60 minutes

## 🔌 Connecting to a Real Backend

All data is in `lib/services/data_service.dart`. To switch from mock data to a real Flask API:

1. Set `_useMock = false` in `data_service.dart`
2. Set `baseUrl = 'http://YOUR_SERVER:5000'`
3. Replace each method body with an `http.get / http.post` call

The Flask backend (from the previous version) uses the exact same data schema.

## 📦 Dependencies

```yaml
provider: ^6.1.2          # State management
http: ^1.2.1               # HTTP client (for real backend)
intl: ^0.19.0              # Date formatting
file_picker: ^8.0.3        # PDF file selection
shared_preferences: ^2.2.3 # Local storage
google_fonts: ^6.2.1       # DM Sans font
```
