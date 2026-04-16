# 🏫 Room Scheduler

A full-stack web application for real-time college room availability tracking.

## Tech Stack
- **Backend**: Python Flask + SQLite
- **Frontend**: Vanilla HTML/CSS/JS (mobile-first, no build step needed)

## Quick Start

### 1. Install dependencies
```bash
pip install -r requirements.txt
```

### 2. Run the app
```bash
python app.py
```

### 3. Open in browser
```
http://localhost:5000
```

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
