# 🏫 Room Scheduler

A full-stack college room availability system with a **Flutter mobile app** and a **web dashboard**, both powered by a **Python Flask** backend and **SQLite** database. Teachers can log in, book rooms, upload PDF timetables, and track real-time room status across buildings.

---

## ✨ Features

- 📊 **Live Dashboard** — Every room shows real-time status: Free, Busy, or Soon (within 60 min)
- 🔍 **Search & Filter** — Filter rooms by status, building, or keyword
- 📅 **Room Schedule** — Full hourly timeline (09:00–16:00) for any room on any day
- 📤 **PDF Timetable Upload** — Automatically parses college timetable PDFs and populates the schedule
- ✏️ **Manual Entry** — Add individual timetable entries without a PDF
- 👩‍🏫 **Teacher Portal** — Login with Employee ID, view and manage your bookings
- 🔒 **Conflict Detection** — Prevents double-booking automatically
- 👤 **Role-Based Access** — Admin, Teacher, and Student roles with different permissions
- 🌑 **Dark Theme** — Mobile-first UI with a purple/teal accent palette

---

## 🛠️ Tech Stack

| Layer | Technology |
|-------|-----------|
| Mobile frontend | Flutter (Dart) |
| Web frontend | Vanilla HTML / CSS / JS |
| Backend API | Python Flask |
| Database | SQLite |
| PDF parsing | pdfplumber |
| Cross-origin | flask-cors |

---

## 📁 Project Structure

```
room_scheduler/
│
├── room_scheduler/          # Flask backend + web frontend
│   ├── app.py               # All API routes and business logic
│   ├── requirements.txt     # Python dependencies
│   ├── room_scheduler.db    # SQLite database (auto-created)
│   └── static/
│       └── index.html       # Web dashboard (no build step needed)
│
├── main.dart                # Flutter app entry point
├── app_theme.dart           # Global dark theme and color palette
├── room.dart                # Room, DaySchedule, TimeSlot models
├── user.dart                # AppUser model (Admin / Teacher / Student roles)
├── splash_screen.dart       # Animated launch screen
├── login_screen.dart        # Employee ID / password login
├── register_screen.dart     # New user registration
├── room_list_screen.dart    # Live room grid with search + filters
├── room_detail_screen.dart  # Per-room daily schedule + override dialog
├── room_card.dart           # Reusable room card widget
├── admin_screen.dart        # Admin CRUD for rooms + timetable upload
└── profile_screen.dart      # Logged-in user info and logout
```

---

## 🚀 Quick Start (Backend / Web)

### 1. Install Python dependencies

```bash
cd room_scheduler
pip install -r requirements.txt
```

### 2. Run the server

```bash
python app.py
```

### 3. Open in browser

```
http://localhost:5000
```

The SQLite database is created automatically on first run.

---

## 📱 Flutter App Setup

### Prerequisites

- Flutter SDK ≥ 3.x
- Dart ≥ 3.x

### Run the app

```bash
flutter pub get
flutter run
```

Make sure the Flask server is running and update the base URL in `StorageService` to point to your machine's IP (for physical devices).

---

## 🔌 API Reference

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/rooms` | List all rooms (optional `?building=` filter) |
| `POST` | `/api/rooms` | Add a new room |
| `GET` | `/api/rooms/status` | Live status for all rooms at current time |
| `GET` | `/api/rooms/<room_number>/schedule` | Full hourly schedule for a room |
| `GET` | `/api/teachers` | List all teachers |
| `POST` | `/api/teachers/login` | Authenticate by Employee ID |
| `GET` | `/api/bookings` | All bookings (optional `?faculty_code=` filter) |
| `POST` | `/api/bookings` | Create a booking (with conflict check) |
| `DELETE` | `/api/bookings/<id>` | Cancel a booking |
| `POST` | `/api/timetable/upload` | Upload and parse a PDF timetable |
| `POST` | `/api/timetable` | Add a single timetable entry manually |

### Room status logic

| Status | Meaning |
|--------|---------|
| 🟢 **Free** | No class or booking right now |
| 🔴 **Busy** | A class or booking is in progress |
| 🟡 **Soon** | Will be occupied within the next 60 minutes |

---

## 🗄️ Database Schema

```sql
rooms (id, room_number, room_type, capacity, building)

teachers (id, employee_id, name, faculty_code, department)

timetable_entries (
  id, day, start_time, end_time, room_number,
  subject, faculty_code, faculty_name,
  year, branch, section, session
)

bookings (
  id, room_number, day, start_time, end_time,
  booked_by, faculty_code, purpose,
  booking_type, status, created_at
)
```

---

## 📄 PDF Timetable Upload

The upload endpoint (`POST /api/timetable/upload`) uses **pdfplumber** with a two-pass parser:

1. **Pass 1** — Scans for a Faculty Acronym table and builds a `code → name` mapping
2. **Pass 2** — Reads timetable grid cells matching the pattern `Subject [FacultyCode] (RoomNumber)` using a flexible regex

Rooms and teachers found in the PDF are automatically added to the database.

---

## 👤 Default Teacher Accounts

| Employee ID | Name |
|-------------|------|
| `AP001` | Dr. Ashutosh Pandey |
| `UK002` | Dr. Umesh Kumar |
| `VJ003` | Prof. Vikas Jain |
| `SM004` | Dr. Shweta Mishra |
| `RK005` | Prof. Rakesh Kumar |
| `TG006` | Prof. Tanvi Gupta |

> These are seeded via `seed_data()` in `app.py`. The function is commented out by default — uncomment it in `init_db()` to load sample data on first run.

---

## 🏗️ Adding Real Data

### Add rooms manually via API

```bash
curl -X POST http://localhost:5000/api/rooms \
  -H "Content-Type: application/json" \
  -d '{"room_number": "101", "room_type": "Classroom", "capacity": 60, "building": "Block A"}'
```

### Add a timetable entry manually

```bash
curl -X POST http://localhost:5000/api/timetable \
  -H "Content-Type: application/json" \
  -d '{
    "day": "Monday",
    "start_time": "09:00",
    "end_time": "10:00",
    "room_number": "101",
    "subject": "Data Structures",
    "faculty_code": "AP",
    "faculty_name": "Dr. Ashutosh Pandey",
    "section": "A",
    "session": "2025-26"
  }'
```

---

## 🎨 Theme & Colors

The Flutter app uses a custom dark theme defined in `app_theme.dart`:

| Token | Color | Use |
|-------|-------|-----|
| `primary` | `#6C63FF` | Buttons, highlights |
| `accent` | `#00D4AA` | Available / free status |
| `background` | `#0F0F1A` | Screen background |
| `surface` | `#1A1A2E` | Cards |
| `occupied` | `#FF6B6B` | Busy status |
| `warning` | `#FFB347` | Soon status |

---

## 📋 Requirements

**Python (backend)**
```
flask>=3.0.0
flask-cors>=4.0.0
pdfplumber>=0.10.0
```

**Flutter (mobile)**
- Flutter 3.x / Dart 3.x
- No additional pub packages beyond standard Flutter SDK (check `pubspec.yaml`)

---

## 📌 Notes

- The SQLite database file (`room_scheduler.db`) is gitignored by default — it is generated fresh on first run.
- The `__pycache__` folder and `.git` internals are not needed in the repository.
- For production deployment, replace SQLite with PostgreSQL and serve via Gunicorn + Nginx.

---

## 📃 License

MIT — free to use, modify, and distribute.
