# 🏫 Room Scheduler

A full-stack web application for real-time college room availability tracking.

## Tech Stack
- **Backend**: Python Flask + SQLite
- **Frontend**: Flutter (Dart) for cross-platform mobile support

## Quick Start

### 1. Backend Setup
Navigate to the backend directory and run the Flask server:
```bash
cd backend/room_scheduler
pip install -r requirements.txt
python app.py

```
http://localhost:5000
```
cd frontend/room_scheduler_flutter
flutter pub get
flutter run

## Features
- 📊 **Live Dashboard** — Real-time room status (Free / Busy / Soon) based on current time
- 🔍 **Filter** — By status or building
- 📅 **Room Schedule** — Full daily timeline for any room
- 📤 **Timetable Upload** — Upload PDF or add entries manually
- 👩‍🏫 **Teacher Portal** — Login, view/create/cancel bookings
- 🔒 **Conflict Detection** — Prevents double-booking automatically

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/rooms` | List all rooms |
| GET | `/api/rooms/status` | Live status of all rooms |
| GET | `/api/rooms/<id>/schedule` | Schedule for a room |
| POST | `/api/teachers/login` | Teacher authentication |
| GET | `/api/teachers` | List all teachers |
| POST | `/api/bookings` | Create a booking |
| GET | `/api/bookings` | List bookings |
| DELETE | `/api/bookings/<id>` | Cancel a booking |
| POST | `/api/timetable/upload` | Upload PDF timetable |
| POST | `/api/timetable` | Add manual timetable entry |

## Default Teacher IDs
| ID | Name |
|----|------|
| AP001 | Dr. Ashutosh Pandey |
| UK002 | Dr. Umesh Kumar |
| VJ003 | Prof. Vikas Jain |
| SM004 | Dr. Shweta Mishra |
| RK005 | Prof. Rakesh Kumar |
| TG006 | Prof. Tanvi Gupta |

## Room Status Logic
- 🟢 **FREE** — No class scheduled right now
- 🔴 **BUSY** — Class in progress
- 🟡 **SOON** — Will be occupied within 60 minutes

## Database
SQLite database (`room_scheduler.db`) is auto-created on first run with seed data.
