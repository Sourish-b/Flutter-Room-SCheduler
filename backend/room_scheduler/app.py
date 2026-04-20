from flask import Flask, request, jsonify, send_from_directory
from flask_cors import CORS
import sqlite3, os, json, tempfile
from datetime import datetime, date
import pdfplumber, re

app = Flask(__name__, static_folder="static")
CORS(app)

DB = "room_scheduler.db"

# ──────────────────────────────── DB SETUP ────────────────────────────────

def get_db():
    conn = sqlite3.connect(DB)
    conn.row_factory = sqlite3.Row
    return conn

def init_db():
    with get_db() as c:
        c.executescript("""
        CREATE TABLE IF NOT EXISTS rooms (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            room_number TEXT UNIQUE NOT NULL,
            room_type TEXT DEFAULT 'Classroom',
            capacity INTEGER DEFAULT 60,
            building TEXT DEFAULT 'Main Block'
        );

        CREATE TABLE IF NOT EXISTS teachers (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            employee_id TEXT UNIQUE NOT NULL,
            name TEXT NOT NULL,
            faculty_code TEXT NOT NULL,
            department TEXT DEFAULT 'CSE'
        );

        CREATE TABLE IF NOT EXISTS timetable_entries (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            day TEXT NOT NULL,
            start_time TEXT NOT NULL,
            end_time TEXT NOT NULL,
            room_number TEXT NOT NULL,
            subject TEXT,
            faculty_code TEXT,
            faculty_name TEXT,
            year TEXT,
            branch TEXT,
            section TEXT,
            session TEXT DEFAULT '2025-26'
        );

        CREATE TABLE IF NOT EXISTS bookings (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            room_number TEXT NOT NULL,
            day TEXT NOT NULL,
            start_time TEXT NOT NULL,
            end_time TEXT NOT NULL,
            booked_by TEXT NOT NULL,
            faculty_code TEXT,
            purpose TEXT,
            booking_type TEXT DEFAULT 'booking',
            original_entry INTEGER,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP,
            status TEXT DEFAULT 'confirmed',
            FOREIGN KEY (original_entry) REFERENCES timetable_entries(id)
        );
        """)
        
        # Check if we need to seed
        count = c.execute("SELECT COUNT(*) FROM teachers").fetchone()[0]
        if count == 0:
            seed_data(c)

def seed_data(c):
    # 1. Add your REAL Rooms here
    rooms = [
        ("203","Lab",40,"Block A"), 
        ("204","Classroom",60,"Block A"),
        ("211","Classroom",60,"Block A"),
        ("212","Lab",30,"Block A"),
        ("216","Lab",35,"Block A"),
        ("312","Lab",30,"Block B"),
        ("314","Classroom",60,"Block B"),
        ("315","Classroom",60,"Block B"),
        ("101","Seminar Hall",100,"Block C"),
    ]
    for r in rooms:
        c.execute("INSERT OR IGNORE INTO rooms (room_number,room_type,capacity,building) VALUES (?,?,?,?)", r)

    # 2. Add your REAL Teachers here (Employee ID, Name, Faculty Code, Dept)
    teachers = [
        ("AP001","Dr. Ashutosh Pandey","AP","CSE"),
        ("UK002","Dr. Umesh Kumar","UK","CSE"),
        ("VJ003","Prof. Vikas Jain","VJ","ECE"),
        ("SM004","Dr. Shweta Mishra","SM","CSE"),
        ("RK005","Prof. Rakesh Kumar","RK","ECE"),
        ("TG006","Prof. Tanvi Gupta","TG","CSE"),
    ]
    for t in teachers:
        c.execute("INSERT OR IGNORE INTO teachers (employee_id,name,faculty_code,department) VALUES (?,?,?,?)", t)

    # Note: We completely removed the dummy schedule template loops here.
    # The timetable_entries and bookings tables will now start 100% empty!
# ──────────────────────────────── HELPERS ────────────────────────────────

def time_to_mins(t):
    h, m = map(int, t.split(":"))
    return h * 60 + m

def get_room_status(room_number, day, current_time):
    cur = time_to_mins(current_time)
    with get_db() as c:
        entries = c.execute("""
            SELECT start_time, end_time, subject, faculty_name, year, branch, section
            FROM timetable_entries WHERE room_number=? AND day=?
        """, (room_number, day)).fetchall()
        bookings = c.execute("""
            SELECT start_time, end_time, purpose, booked_by, '' as year, '' as branch
            FROM bookings WHERE room_number=? AND day=? AND status='confirmed'
        """, (room_number, day)).fetchall()

    all_slots = list(entries) + list(bookings)
    for s in all_slots:
        s_min = time_to_mins(s["start_time"])
        e_min = time_to_mins(s["end_time"])
        if s_min <= cur < e_min:
            return "busy", dict(s)

    # Check if busy within 60 min
    for s in all_slots:
        s_min = time_to_mins(s["start_time"])
        if 0 < s_min - cur <= 60:
            return "soon", dict(s)

    return "free", None

# ──────────────────────────────── ROUTES ────────────────────────────────

@app.route("/")
def index():
    return send_from_directory("static", "index.html")

# --- Rooms ---
@app.route("/api/rooms", methods=["GET"])
def get_rooms():
    building = request.args.get("building")
    with get_db() as c:
        if building:
            rows = c.execute("SELECT * FROM rooms WHERE building=? ORDER BY room_number", (building,)).fetchall()
        else:
            rows = c.execute("SELECT * FROM rooms ORDER BY room_number").fetchall()
    return jsonify([dict(r) for r in rows])

@app.route("/api/rooms/status", methods=["GET"])
def rooms_status():
    now = datetime.now()
    day = request.args.get("day", now.strftime("%A"))
    time_str = request.args.get("time", now.strftime("%H:%M"))

    with get_db() as c:
        rooms = c.execute("SELECT * FROM rooms ORDER BY room_number").fetchall()

    result = []
    for room in rooms:
        status, info = get_room_status(room["room_number"], day, time_str)
        result.append({**dict(room), "status": status, "current_class": info})

    free = sum(1 for r in result if r["status"] == "free")
    busy = sum(1 for r in result if r["status"] == "busy")
    soon = sum(1 for r in result if r["status"] == "soon")

    return jsonify({"rooms": result, "summary": {"free": free, "busy": busy, "soon": soon},
                    "day": day, "time": time_str})

@app.route("/api/rooms/<room_number>/schedule", methods=["GET"])
def room_schedule(room_number):
    now = datetime.now()
    day = request.args.get("day", now.strftime("%A"))
    with get_db() as c:
        entries = c.execute("""
            SELECT start_time, end_time, subject, faculty_name, year, branch, section
            FROM timetable_entries WHERE room_number=? AND day=?
            ORDER BY start_time
        """, (room_number, day)).fetchall()
        bookings = c.execute("""
            SELECT start_time, end_time, purpose as subject, booked_by as faculty_name, '' as year, '' as branch, 'Booking' as section
            FROM bookings WHERE room_number=? AND day=? AND status='confirmed'
            ORDER BY start_time
        """, (room_number, day)).fetchall()
        room = c.execute("SELECT * FROM rooms WHERE room_number=?", (room_number,)).fetchone()

    all_entries = sorted(
        [dict(e) for e in entries] + [dict(b) for b in bookings],
        key=lambda x: x["start_time"]
    )

    all_entries = sorted(
        [dict(e) for e in entries] + [dict(b) for b in bookings],
        key=lambda x: x["start_time"]
    )

    # Build full hourly timeline 09:00–16:00
    timeline = []
    hours = [(f"{h:02d}:00", f"{h+1:02d}:00") for h in range(9, 16)]
    for start, end in hours:
        found = next((e for e in all_entries
                      if time_to_mins(e["start_time"]) <= time_to_mins(start) < time_to_mins(e["end_time"])), None)
        timeline.append({"time": start, "end": end, "entry": found})

    return jsonify({"room": dict(room) if room else {}, "schedule": timeline, "day": day})

# --- Teachers ---
@app.route("/api/teachers/login", methods=["POST"])
def teacher_login():
    data = request.json or {}
    raw_id = data.get("employee_id", "")
    employee_id = str(raw_id).strip().upper()
    if not employee_id:
        return jsonify({"success": False, "message": "Employee ID is required"}), 400

    normalized_code = re.sub(r"[^A-Z]", "", employee_id)

    with get_db() as c:
        t = c.execute(
            """
            SELECT * FROM teachers
            WHERE UPPER(employee_id)=?
               OR UPPER(faculty_code)=?
               OR UPPER(employee_id)=?
               OR UPPER(faculty_code)=?
            LIMIT 1
            """,
            (employee_id, employee_id, normalized_code, normalized_code),
        ).fetchone()
    if t:
        return jsonify({"success": True, "teacher": dict(t)})
    return jsonify({"success": False, "message": "Employee ID not found"}), 401

@app.route("/api/teachers", methods=["GET"])
def get_teachers():
    with get_db() as c:
        rows = c.execute("SELECT * FROM teachers ORDER BY name").fetchall()
    return jsonify([dict(r) for r in rows])

# --- Bookings ---
@app.route("/api/bookings", methods=["POST"])
def create_booking():
    data = request.json
    now = datetime.now()
    day = data.get("day", now.strftime("%A"))
    with get_db() as c:
        # Check conflict
        conflict = c.execute("""
            SELECT id FROM timetable_entries
            WHERE room_number=? AND day=?
            AND start_time < ? AND end_time > ?
        """, (data["room_number"], day, data["end_time"], data["start_time"])).fetchone()
        if conflict:
            return jsonify({"success": False, "message": "Room is already scheduled for a class at this time"}), 409
        booking_conflict = c.execute("""
            SELECT id FROM bookings
            WHERE room_number=? AND day=? AND status='confirmed'
            AND start_time < ? AND end_time > ?
        """, (data["room_number"], day, data["end_time"], data["start_time"])).fetchone()
        if booking_conflict:
            return jsonify({"success": False, "message": "Room already booked at this time"}), 409

        cursor = c.execute("""INSERT INTO bookings
            (room_number,day,start_time,end_time,booked_by,faculty_code,purpose,booking_type)
            VALUES (?,?,?,?,?,?,?,?)""",
            (data["room_number"], day, data["start_time"], data["end_time"],
             data["booked_by"], data.get("faculty_code",""), data.get("purpose",""), data.get("booking_type","booking")))
        booking_id = cursor.lastrowid

    return jsonify({"success": True, "booking_id": booking_id, "message": "Room booked successfully!"})

@app.route("/api/bookings", methods=["GET"])
def get_bookings():
    faculty_code = request.args.get("faculty_code")
    with get_db() as c:
        if faculty_code:
            rows = c.execute("SELECT * FROM bookings WHERE faculty_code=? ORDER BY created_at DESC", (faculty_code,)).fetchall()
        else:
            rows = c.execute("SELECT * FROM bookings ORDER BY created_at DESC").fetchall()
    return jsonify([dict(r) for r in rows])

@app.route("/api/bookings/<int:booking_id>", methods=["DELETE"])
def cancel_booking(booking_id):
    with get_db() as c:
        c.execute("UPDATE bookings SET status='cancelled' WHERE id=?", (booking_id,))
    return jsonify({"success": True, "message": "Booking cancelled"})

# --- Timetable upload (PDF parse) ---
@app.route("/api/timetable/upload", methods=["POST"])
def upload_timetable():
    if "file" not in request.files:
        return jsonify({"success": False, "message": "No file provided"}), 400
    file = request.files["file"]
    session = request.form.get("session", "2025-26")
    if not file.filename.endswith(".pdf"):
        return jsonify({"success": False, "message": "Only PDF files are supported"}), 400

    tmp = os.path.join(tempfile.gettempdir(), f"timetable_{datetime.now().timestamp()}.pdf")
    file.save(tmp)
    inserted_count = 0
    faculty_dict = {}
    rooms_set = set()

    try:
        with pdfplumber.open(tmp) as pdf:
            with get_db() as c:  # Open Database connection
                # First pass: extract faculty acronyms
                for page in pdf.pages:
                    tables = page.extract_tables()
                    if not tables:
                        tables = page.extract_tables({"vertical_strategy": "text", "horizontal_strategy": "text"})
                    
                    for table in tables:
                        if not table or len(table) < 2: continue
                        # Check if it's a faculty acronym table
                        if table[0] and table[0][0] and 'Faculty Acronym' in str(table[0][0]):
                            for row in table[1:]:
                                if not row: continue
                                for i in range(0, len(row), 2):
                                    if i+1 < len(row) and row[i] and row[i+1]:
                                        code = str(row[i]).strip()
                                        name = str(row[i+1]).strip()
                                        if code and name:
                                            faculty_dict[code] = name
                
                # Insert teachers
                for code, name in faculty_dict.items():
                    c.execute("INSERT OR IGNORE INTO teachers (employee_id, name, faculty_code, department) VALUES (?,?,?,?)",
                              (code, name, code, 'Unknown'))  # Use code as employee_id for now
                
                # Second pass: extract timetable
                for page in pdf.pages:
                    tables = page.extract_tables()
                    if not tables:
                        tables = page.extract_tables({"vertical_strategy": "text", "horizontal_strategy": "text"})

                    for table in tables:
                        if not table or len(table) < 3: continue
                        
                        # Find the year/branch header row
                        year = branch = section_prefix = None
                        for row in table:
                            if row and row[0] and 'Year' in str(row[0]):
                                header_text = str(row[0]).strip()
                                match = re.search(r'(\d+)(?:st|nd|rd|th)\s+Year\s+([A-Z]+)-([A-Z\d]+)', header_text)
                                if match:
                                    year = match.group(1) + ('st' if match.group(1)=='1' else 'nd' if match.group(1)=='2' else 'rd' if match.group(1)=='3' else 'th')
                                    branch = match.group(2)
                                    section_prefix = match.group(3)
                                break
                        
                        # Find the time header row (starts with 'Days \\ Time')
                        time_header_row = None
                        data_start_index = None
                        for i, row in enumerate(table):
                            if row and row[0] and 'Days' in str(row[0]) and 'Time' in str(row[0]):
                                time_header_row = row
                                data_start_index = i + 1
                                break
                        if not time_header_row:
                            continue  # Skip non-timetable tables
                        
                        # 1. Extract times from the time header row
                        time_headers = []
                        for header_cell in time_header_row[1:]:  # Skip 'Days \\ Time'
                            if header_cell:
                                # Forgiving regex for times (handles "9:00-10:00" and "09:00 - 10:00")
                                times = re.findall(r'(\d{1,2}:\d{2})\s*-\s*(\d{1,2}:\d{2})', str(header_cell).replace('\n', ''))
                                if times:
                                    # Ensure format is exactly "09:00"
                                    start = times[0][0].zfill(5)
                                    end = times[0][1].zfill(5)
                                    time_headers.append((start, end))
                                else:
                                    time_headers.append(None)
                            else:
                                time_headers.append(None)

                        current_day = None
                        
                        # 2. Extract data from the remaining rows
                        for row in table[data_start_index:]:
                            if not row: continue
                            
                            # Safely read the day column
                            raw_day = str(row[0]).replace('\n', '').strip() if row[0] else ""
                            
                            # Track the current day (this remembers the day even if the cell is blank on the next row)
                            for valid_day in ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]:
                                if valid_day in raw_day:
                                    current_day = valid_day
                                    break
                            
                            # Skip the row entirely if we haven't established what day it is yet
                            if not current_day:
                                continue 

                            # Iterate through each column in the row
                            for col_idx, cell in enumerate(row[1:], 1):  # Skip day column
                                # Skip invalid columns or columns without an associated time
                                if col_idx > len(time_headers) or not time_headers[col_idx-1]:
                                    continue
                                
                                start_time, end_time = time_headers[col_idx-1]
                                
                                # Clean up newlines so the whole cell is one string
                                clean_cell = str(cell).replace('\n', ' ').strip() if cell else ""
                                if not clean_cell:
                                    continue
                                
                                # 3. Super-Regex! Matches Faculty in [] OR () and ignores trailing typos like ]]
                                # Example matches: "DS CSE-A [UK] (312)" OR "A2 (UK) (312)" OR "ECW [VJ/SJY] (311)"
                                matches = re.findall(r'(.*?)\s*(?:\[|\()([A-Za-z\s/]+)(?:\]|\))\]?\s*\(([^)]+)\)', clean_cell)
                                
                                for subject_sec, faculty_code, room_number in matches:
                                    faculty_name = faculty_dict.get(faculty_code.strip(), '')
                                    # Parse subject and section
                                    subject_sec = subject_sec.strip()
                                    parts = subject_sec.split()
                                    subject_parts = []
                                    section = ''
                                    for part in parts:
                                        if re.match(r'[A-Z]{2,3}-[A-Z]', part):  # Like CSE-A
                                            section = part.split('-')[1]  # 'A'
                                        elif re.match(r'[A-Z]\d+', part):  # A2
                                            section += (' ' + part) if section else part
                                        else:
                                            subject_parts.append(part)
                                    section = section.strip()
                                    subject = ' '.join(subject_parts)
                                    
                                    # Save to the database
                                    c.execute("""INSERT INTO timetable_entries
                                        (day,start_time,end_time,room_number,subject,faculty_code,faculty_name,year,branch,section,session)
                                        VALUES (?,?,?,?,?,?,?,?,?,?,?)""",
                                        (current_day, start_time, end_time, room_number.strip(), subject, faculty_code.strip(), faculty_name, year, branch, section, session))
                                    inserted_count += 1
                                    rooms_set.add(room_number.strip())
                
                # Insert rooms
                for room_number in rooms_set:
                    c.execute("INSERT OR IGNORE INTO rooms (room_number, room_type, capacity, building) VALUES (?, ?, ?, ?)",
                              (room_number, 'Unknown', 60, 'Unknown'))
                                        
    except Exception as e:
        return jsonify({"success": False, "message": f"PDF parsing error: {str(e)}"}), 500
    finally:
        if os.path.exists(tmp):
            os.remove(tmp)

    return jsonify({
        "success": True,
        "message": f"PDF processed successfully. {inserted_count} classes added to the schedule. {len(faculty_dict)} teachers and {len(rooms_set)} rooms added.",
        "session": session,
        "extracted_count": inserted_count,
        "teachers_added": len(faculty_dict),
        "rooms_added": len(rooms_set)
    })
@app.route("/api/rooms", methods=["POST"])
def add_room():
    data = request.json
    with get_db() as c:
        c.execute("INSERT OR IGNORE INTO rooms (room_number,room_type,capacity,building) VALUES (?,?,?,?)",
                  (data["room_number"], data.get("room_type","Classroom"), data.get("capacity",60), data.get("building","Main Block")))
    return jsonify({"success": True})

@app.route("/api/timetable", methods=["POST"])
def add_timetable_entry():
    data = request.json
    with get_db() as c:
        c.execute("""INSERT INTO timetable_entries
            (day,start_time,end_time,room_number,subject,faculty_code,faculty_name,section,session)
            VALUES (?,?,?,?,?,?,?,?,?)""",
            (data["day"], data["start_time"], data["end_time"], data["room_number"],
             data.get("subject"), data.get("faculty_code"), data.get("faculty_name"),
             data.get("section"), data.get("session","2025-26")))
    return jsonify({"success": True})

@app.route("/api/timetable/reset", methods=["POST"])
def reset_timetable():
    with get_db() as c:
        c.execute("DELETE FROM timetable_entries")
        c.execute("DELETE FROM bookings")
    return jsonify({"success": True, "message": "Schedule reset successfully."})

if __name__ == "__main__":
    init_db()
    print("\n✅ Room Scheduler API running → http://localhost:5000\n")
    app.run(debug=True, port=5000)
