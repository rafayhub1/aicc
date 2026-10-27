"""Captioned design figures for the AICC report."""

import math
import os

from PIL import Image, ImageDraw, ImageFont

OUT = r"e:\FYP\docs\figures"
NAVY = (11, 61, 102)
LIGHT = (232, 240, 246)
PALE = (245, 248, 251)
WHITE = (255, 255, 255)
INK = (22, 32, 42)
GOLD = (122, 84, 28)
GREEN = (28, 92, 72)


def font(size, bold=False):
    path = r"C:\Windows\Fonts\timesbd.ttf" if bold else r"C:\Windows\Fonts\times.ttf"
    return ImageFont.truetype(path, size)


def canvas(w, h):
    image = Image.new("RGB", (w, h), "white")
    return image, ImageDraw.Draw(image)


def wrap(draw, text, face, max_w):
    lines = []
    for paragraph in str(text).split("\n"):
        words = paragraph.split()
        if not words:
            lines.append("")
            continue
        current = words[0]
        for word in words[1:]:
            trial = current + " " + word
            if draw.textlength(trial, font=face) <= max_w:
                current = trial
            else:
                lines.append(current)
                current = word
        lines.append(current)
    return lines


def rounded(draw, box, text, face, fill=LIGHT, outline=NAVY, width=3, ink=INK):
    draw.rounded_rectangle(box, radius=16, fill=fill, outline=outline, width=width)
    lines = wrap(draw, text, face, box[2] - box[0] - 28)
    line_h = face.size + 6
    y = box[1] + ((box[3] - box[1]) - len(lines) * line_h) / 2
    for line in lines:
        tw = draw.textlength(line, font=face)
        draw.text((box[0] + (box[2] - box[0] - tw) / 2, y), line, font=face, fill=ink)
        y += line_h


def label(draw, xy, text, face, fill=INK, anchor="mm"):
    draw.text(xy, text, font=face, fill=fill, anchor=anchor)


def center_wrap(draw, cx, top, text, face, max_w, fill=INK):
    lines = wrap(draw, text, face, max_w)
    y = top
    for line in lines:
        draw.text((cx, y), line, font=face, fill=fill, anchor="ma")
        y += face.size + 6


def arrow(draw, start, end, fill=NAVY, width=3):
    draw.line([start, end], fill=fill, width=width)
    angle = math.atan2(end[1] - start[1], end[0] - start[0])
    length = 16
    spread = 0.42
    left = (
        end[0] - length * math.cos(angle - spread),
        end[1] - length * math.sin(angle - spread),
    )
    right = (
        end[0] - length * math.cos(angle + spread),
        end[1] - length * math.sin(angle + spread),
    )
    draw.polygon([end, left, right], fill=fill)


def actor(draw, x, y, name, face):
    draw.ellipse((x - 18, y, x + 18, y + 36), outline=NAVY, width=3)
    draw.line((x, y + 36, x, y + 92), fill=NAVY, width=3)
    draw.line((x - 34, y + 58, x + 34, y + 58), fill=NAVY, width=3)
    draw.line((x, y + 92, x - 26, y + 138), fill=NAVY, width=3)
    draw.line((x, y + 92, x + 26, y + 138), fill=NAVY, width=3)
    label(draw, (x, y + 162), name, face)


def ellipse(draw, box, text, face):
    draw.ellipse(box, fill=WHITE, outline=NAVY, width=3)
    lines = wrap(draw, text, face, box[2] - box[0] - 36)
    line_h = face.size + 4
    y = box[1] + ((box[3] - box[1]) - len(lines) * line_h) / 2
    for line in lines:
        tw = draw.textlength(line, font=face)
        draw.text((box[0] + (box[2] - box[0] - tw) / 2, y), line, font=face, fill=INK)
        y += line_h


def save(image, name):
    os.makedirs(OUT, exist_ok=True)
    path = os.path.join(OUT, name)
    image.save(path, "PNG")
    return path


def use_case():
    image, draw = canvas(1700, 1180)
    title = font(28, True)
    body_f = font(20)
    small = font(18)
    label(draw, (850, 36), "AICC system boundary", title, NAVY)
    draw.rounded_rectangle((250, 70, 1450, 1120), radius=18, outline=NAVY, width=4)
    cases = [
        (430, 120, "Sign in or sign up"),
        (980, 120, "View academic dashboard"),
        (430, 280, "Ask a campus question"),
        (980, 280, "Open fee challan or roll slip"),
        (430, 440, "Get outdoor directions"),
        (980, 440, "Navigate inside a building"),
        (430, 600, "Search a teacher"),
        (980, 600, "Read notifications"),
        (430, 760, "Manage students and teachers"),
        (980, 760, "Publish places and walkways"),
        (430, 920, "Broadcast a notice"),
        (980, 920, "Edit an indoor area"),
    ]
    for x, y, text in cases:
        ellipse(draw, (x, y, x + 390, y + 110), text, body_f)
    actor(draw, 110, 430, "Student", body_f)
    actor(draw, 1585, 700, "Administrator", small)
    for y in (175, 335, 495, 655):
        draw.line((148, 520, 430, y), fill=NAVY, width=2)
        draw.line((820, y, 980, y), fill=NAVY, width=2)
    arrow(draw, (1520, 758), (1370, 815))
    arrow(draw, (1520, 820), (1370, 975))
    draw.line([(1520, 820), (1520, 1088), (300, 1088), (300, 815)], fill=NAVY, width=2)
    arrow(draw, (300, 815), (430, 815))
    arrow(draw, (625, 1088), (625, 1032))
    label(draw, (850, 1148), "Student uses the companion. Administrator maintains campus data.", small, INK)
    return save(image, "fig_6_1_usecase.png")


def er_diagram():
    image, draw = canvas(1800, 1240)
    f = font(20, True)
    s = font(16)
    boxes = {
        "student": (40, 80, 280, 210),
        "course": (40, 360, 280, 490),
        "note": (40, 640, 280, 770),
        "doc": (40, 920, 280, 1050),
        "place": (760, 80, 1040, 230),
        "node": (1320, 80, 1720, 230),
        "edge": (1320, 360, 1720, 500),
        "building": (760, 420, 1040, 560),
        "floor": (760, 700, 1040, 850),
        "room": (1120, 920, 1460, 1070),
        "user": (400, 920, 680, 1050),
        "session": (400, 640, 700, 790),
    }
    texts = {
        "student": "Student\nid, name, registration,\ndepartment, semester,\nsection, CGPA",
        "course": "Course\ncode, name,\nattendance, semester",
        "note": "Notification\ntype, message,\nread, time",
        "doc": "Document\nfee challan or\nroll slip, status, file",
        "place": "Place\nname, aliases, category,\nlatitude, longitude, node",
        "node": "Walkway node\nid, label,\nlatitude, longitude",
        "edge": "Walkway connection\nfrom, to, distance,\ninstruction, two-way",
        "building": "Building\nname, origin,\nentrance node",
        "floor": "Floor\nlevel, rooms,\nnodes, edges",
        "room": "Room\nname, type,\npolygon, door",
        "user": "App account\nuid, role, email",
        "session": "Chat session\nmessages, time",
    }
    for key, box in boxes.items():
        rounded(draw, box, texts[key], s if "\n" in texts[key] else f, fill=LIGHT)
    pairs = [
        ((280, 145), (760, 145), "located at"),
        ((160, 210), (160, 360), "enrols"),
        ((160, 490), (160, 640), "receives"),
        ((160, 770), (160, 920), "owns"),
        ((1040, 155), (1320, 155), "links to"),
        ((1520, 230), (1520, 360), "joins"),
        ((900, 230), (900, 420), "may open"),
        ((900, 560), (900, 700), "contains"),
        ((1040, 775), (1120, 960), "contains"),
        ((540, 920), (540, 790), "owns"),
    ]
    small = font(15, True)
    for start, end, name in pairs:
        arrow(draw, start, end)
        mx, my = (start[0] + end[0]) / 2, (start[1] + end[1]) / 2
        label(draw, (mx + 8, my - 16), name, small, GOLD)
    label(draw, (900, 30), "Campus records and the mobile account are separate stores", f, NAVY)
    label(draw, (900, 1188), "A place card is attached only when a stored place id already exists.", s, INK)
    return save(image, "fig_6_2_er.png")


def architecture():
    image, draw = canvas(1700, 1100)
    f = font(22, True)
    s = font(18)
    layers = [
        (80, 70, 1620, 250, "Student and administrator application  —  Flutter", "Home, UniBot chat, history, notifications, teachers, campus map, indoor floor map, admin console"),
        (80, 290, 1620, 470, "On-phone decision layer", "Intent classifier, place-name match, campus Dijkstra, indoor A* and Dijkstra, session and theme"),
        (80, 510, 1620, 690, "Campus service  —  FastAPI", "Students, courses, documents, notifications, places, indoor maps, chat, admin, statistics"),
        (80, 730, 1620, 980, "External services and stores", ""),
    ]
    for x1, y1, x2, y2, title, subtitle in layers[:3]:
        rounded(draw, (x1, y1, x2, y2), "", f, fill=PALE)
        label(draw, ((x1 + x2) / 2, y1 + 36), title, f, NAVY)
        center_wrap(draw, (x1 + x2) / 2, y1 + 78, subtitle, s, x2 - x1 - 80, INK)
    rounded(draw, layers[3][:4], "", f, fill=PALE)
    stores = [
        (120, 800, 470, 940, "Mobile Firebase\naccounts, chat,\nfaculty, activity"),
        (510, 800, 860, 940, "Campus records\nstudents, places,\nindoor maps"),
        (900, 800, 1220, 940, "Groq\nhandbook answer\nand transcription"),
        (1260, 800, 1580, 940, "Google Maps\noff-campus walking\nhandoff"),
    ]
    for x1, y1, x2, y2, text in stores:
        rounded(draw, (x1, y1, x2, y2), text, s, fill=WHITE)
    for y in (250, 470, 690):
        arrow(draw, (850, y), (850, y + 40))
    label(draw, (850, 1060), "The language-model key never leaves the campus service.", s, INK)
    return save(image, "fig_6_3_architecture.png")


def activity():
    image, draw = canvas(1100, 1560)
    f = font(20, True)
    s = font(18)

    def term(y, text, kind="box"):
        if kind == "round":
            draw.rounded_rectangle((380, y, 720, y + 70), radius=35, fill=NAVY)
            label(draw, (550, y + 35), text, f, WHITE)
        elif kind == "diamond":
            draw.polygon([(550, y), (860, y + 55), (550, y + 110), (240, y + 55)], fill=LIGHT, outline=NAVY)
            label(draw, (550, y + 55), text, s, INK)
        else:
            rounded(draw, (300, y, 800, y + 80), text, s, fill=WHITE)

    term(30, "Student sends a question", "round")
    arrow(draw, (550, 100), (550, 140))
    term(140, "Classify greeting, document,\nacademics, faculty, or place")
    arrow(draw, (550, 220), (550, 260))
    term(260, "Known place name?", "diamond")
    arrow(draw, (860, 315), (980, 315))
    rounded(draw, (860, 250, 1060, 380), "Show the\nstored place\ncard", s, fill=WHITE)
    label(draw, (900, 240), "Yes", font(16, True), GREEN)
    arrow(draw, (550, 370), (550, 420))
    label(draw, (575, 385), "No", font(16, True), GOLD)
    term(420, "Local handbook rule?", "diamond")
    arrow(draw, (240, 475), (140, 475))
    rounded(draw, (20, 420, 200, 540), "Reply with\nthe stored\nrule", s, fill=WHITE)
    label(draw, (180, 400), "Yes", font(16, True), GREEN)
    arrow(draw, (550, 530), (550, 580))
    label(draw, (575, 545), "No", font(16, True), GOLD)
    term(580, "Send the question to the campus service")
    arrow(draw, (550, 660), (550, 700))
    term(700, "Retrieve handbook passages\nwith BM25 and embeddings")
    arrow(draw, (550, 780), (550, 820))
    term(820, "Groq writes a short answer\nfrom those passages only")
    arrow(draw, (550, 900), (550, 940))
    term(940, "Attach a place card only if\nthe passage already has a place")
    arrow(draw, (550, 1020), (550, 1060))
    term(1060, "Student asks for directions?", "diamond")
    arrow(draw, (860, 1115), (980, 1115))
    rounded(draw, (900, 1040, 1080, 1200), "Dijkstra on\ncampus graph,\nor indoor A*", s, fill=WHITE)
    arrow(draw, (550, 1170), (550, 1220))
    term(1220, "Show the answer", "round")
    label(draw, (550, 1360), "Personal CGPA and attendance come from the student record,", s, INK)
    label(draw, (550, 1400), "not from the language model.", s, INK)
    return save(image, "fig_6_4_activity.png")


def sequence():
    image, draw = canvas(1700, 980)
    f = font(18, True)
    s = font(16)
    actors = [
        (120, "Student"),
        (420, "UniBot"),
        (720, "Intent"),
        (1020, "Service"),
        (1320, "Handbook"),
        (1560, "Groq"),
    ]
    for x, name in actors:
        rounded(draw, (x - 90, 40, x + 90, 110), name, f, fill=NAVY, ink=WHITE)
        draw.line((x, 110, x, 900), fill=(180, 196, 208), width=2)
    steps = [
        (160, 120, 420, "Where is the library?"),
        (250, 420, 720, "classify"),
        (340, 720, 420, "place id = library"),
        (450, 420, 120, "Central Library card"),
        (560, 120, 420, "When does it open?"),
        (650, 420, 720, "not a place-only question"),
        (740, 420, 1020, "POST /api/chat"),
        (820, 1020, 1320, "retrieve passages"),
    ]
    for y, x1, x2, text in steps:
        arrow(draw, (x1, y), (x2, y))
        label(draw, ((x1 + x2) / 2, y - 18), text, s, INK)
    arrow(draw, (1320, 880), (1560, 880))
    label(draw, (1440, 862), "passages only", s, INK)
    return save(image, "fig_6_5_sequence.png")


def component():
    image, draw = canvas(1700, 1000)
    f = font(20, True)
    s = font(17)
    rounded(draw, (40, 40, 1660, 470), "", f, fill=PALE)
    label(draw, (850, 70), "Flutter application", f, NAVY)
    parts = [
        (70, 120, 360, 280, "Shell and theme\nroutes, session, appearance"),
        (390, 120, 700, 280, "Home and documents\nCGPA, courses, slips"),
        (730, 120, 1040, 280, "UniBot\nintent, voice, history"),
        (1070, 120, 1360, 280, "Campus guide\nmap, QR, outdoor route"),
        (70, 310, 360, 440, "Indoor map\nfloors, A*, instructions"),
        (390, 310, 700, 440, "Teachers and inbox\nfaculty, push, notices"),
        (730, 310, 1100, 440, "Admin console\nstudents, broadcast, places"),
    ]
    for x1, y1, x2, y2, text in parts:
        rounded(draw, (x1, y1, x2, y2), text, s, fill=WHITE)
    rounded(draw, (40, 520, 1660, 940), "", f, fill=PALE)
    label(draw, (850, 550), "Campus service", f, NAVY)
    services = [
        (70, 610, 360, 760, "Students API\ncourses, documents"),
        (390, 610, 680, 760, "Chat API\nretrieval and Groq"),
        (710, 610, 1000, 760, "Places API\ngraph and aliases"),
        (1030, 610, 1320, 760, "Indoor maps API"),
        (1350, 610, 1620, 760, "Admin API\nbroadcast, accounts"),
        (390, 790, 1000, 900, "Handbook file and embedding cache"),
    ]
    for x1, y1, x2, y2, text in services:
        rounded(draw, (x1, y1, x2, y2), text, s, fill=WHITE)
    arrow(draw, (850, 470), (850, 520))
    return save(image, "fig_6_6_component.png")


def state_machine():
    image, draw = canvas(1700, 820)
    f = font(20, True)
    s = font(16)
    states = [
        (40, 250, 250, 370, "Idle"),
        (360, 250, 600, 370, "Locating"),
        (720, 250, 980, 370, "Routing"),
        (1100, 250, 1360, 370, "On route"),
        (1460, 250, 1670, 370, "Arrived"),
        (720, 520, 980, 640, "Off route"),
        (1100, 520, 1360, 640, "Ended"),
    ]
    for x1, y1, x2, y2, text in states:
        draw.rounded_rectangle((x1, y1, x2, y2), radius=40, fill=LIGHT, outline=NAVY, width=3)
        label(draw, ((x1 + x2) / 2, (y1 + y2) / 2), text, f, NAVY)
    arrows = [
        ((250, 310), (360, 310), "Directions", (305, 285)),
        ((600, 310), (720, 310), "Start known", (660, 285)),
        ((980, 290), (1100, 290), "Path found", (1040, 265)),
        ((1360, 310), (1460, 310), "Last step", (1410, 285)),
        ((1230, 370), (1230, 520), "End", (1275, 445)),
        ((1100, 340), (980, 560), "Left the path", (980, 470)),
        ((850, 520), (850, 370), "Recalculate", (900, 445)),
    ]
    for start, end, name, where in arrows:
        arrow(draw, start, end)
        label(draw, where, name, s, GOLD)
    label(draw, (850, 50), "A route session on the campus map or the indoor floor map", f, NAVY)
    label(draw, (850, 740), "Cancel from any state ends the session. Off campus, locating hands off to Google Maps instead of Routing.", s, INK)
    return save(image, "fig_6_7_state.png")


def class_diagram():
    image, draw = canvas(1800, 1100)
    f = font(20, True)
    s = font(16)

    def klass(box, title, fields):
        draw.rectangle(box, fill=WHITE, outline=NAVY, width=3)
        head = (box[0], box[1], box[2], box[1] + 42)
        draw.rectangle(head, fill=NAVY)
        label(draw, ((box[0] + box[2]) / 2, box[1] + 21), title, f, WHITE)
        y = box[1] + 56
        for field in fields:
            draw.text((box[0] + 14, y), field, font=s, fill=INK)
            y += 26

    klass((40, 40, 430, 280), "Building", ["id, name", "origin lat, lng, rotation", "entranceNodeId", "floors"])
    klass((480, 40, 860, 250), "Floor", ["id, level, name", "footprint", "rooms, nodes, edges"])
    klass((910, 40, 1280, 250), "Room", ["id, name, type", "polygon", "door point"])
    klass((1330, 40, 1740, 250), "NavNode", ["id, x, y", "type", "link to other floor"])
    klass((40, 400, 460, 680), "IndoorRouter", ["costs: RouteCosts", "route() uses A*", "dijkstra() heuristic 0", "preference: stairs or lift"])
    klass((520, 400, 940, 650), "RouteCosts", ["stairs 12 per floor", "lift 8 per floor", "speed 1.2 m/s", "off-route 8 m"])
    klass((1000, 400, 1460, 680), "CampusRouter", ["published nodes only", "Dijkstra", "missing length = 25 m", "marks estimate"])
    klass((1500, 430, 1760, 620), "CampusPlace", ["id, aliases", "lat, lng", "nodeId"])
    arrow(draw, (430, 140), (480, 140))
    arrow(draw, (860, 140), (910, 140))
    arrow(draw, (1280, 160), (1330, 160))
    arrow(draw, (250, 400), (250, 280))
    label(draw, (900, 760), "Indoor coordinates are local metres. Outdoor coordinates are latitude and longitude.", s, INK)
    label(draw, (900, 820), "A stair or lift node carries a link id so the same search can change floors.", s, INK)
    label(draw, (900, 920), "Aggregation: a building owns floors; a floor owns rooms and navigation nodes.", f, NAVY)
    return save(image, "fig_6_8_class.png")


def data_flow():
    image, draw = canvas(1700, 980)
    f = font(20, True)
    s = font(17)
    actor(draw, 140, 360, "Student", f)
    actor(draw, 1560, 360, "Administrator", f)
    draw.ellipse((620, 250, 1080, 470), fill=LIGHT, outline=NAVY, width=4)
    label(draw, (850, 340), "AICC", f, NAVY)
    label(draw, (850, 380), "companion", s, INK)
    stores = [
        (560, 40, 860, 160, "Student record"),
        (900, 40, 1220, 160, "Handbook"),
        (560, 760, 860, 900, "Campus graph"),
        (900, 760, 1220, 900, "Chat history"),
    ]
    for x1, y1, x2, y2, text in stores:
        draw.rectangle((x1, y1 + 16, x2, y2 - 16), outline=NAVY, width=3)
        draw.line((x1, y1 + 16, x1 + 18, y1), fill=NAVY, width=3)
        draw.line((x1 + 18, y1, x2 - 18, y1), fill=NAVY, width=3)
        draw.line((x2 - 18, y1, x2, y1 + 16), fill=NAVY, width=3)
        label(draw, ((x1 + x2) / 2, (y1 + y2) / 2), text, s, NAVY)
    arrow(draw, (190, 430), (620, 380))
    label(draw, (360, 360), "question, location", s, INK)
    arrow(draw, (620, 340), (190, 400))
    label(draw, (340, 300), "answer, route", s, INK)
    arrow(draw, (1480, 430), (1080, 400))
    label(draw, (1280, 360), "places, notices", s, INK)
    arrow(draw, (850, 250), (710, 160))
    arrow(draw, (1040, 160), (980, 250))
    arrow(draw, (740, 470), (700, 760))
    arrow(draw, (1000, 470), (1060, 760))
    label(draw, (850, 950), "Context diagram. Personal marks are read from the student record. Routes are read from the graph.", s, INK)
    return save(image, "fig_6_9_dfd.png")


def database():
    image, draw = canvas(1800, 1100)
    f = font(22, True)
    s = font(17)
    rounded(draw, (40, 40, 860, 1040), "", f, fill=PALE)
    rounded(draw, (920, 40, 1760, 1040), "", f, fill=PALE)
    label(draw, (450, 80), "Mobile Firebase", f, NAVY)
    label(draw, (1340, 80), "Campus data service", f, NAVY)
    left = [
        (80, 140, "users\nuid, role, display name"),
        (80, 320, "chat_sessions\nowner, title, updated"),
        (80, 500, "chat_messages\nsession, role, text"),
        (80, 680, "faculty\nname, department, hours"),
        (80, 860, "activity_events\nactor, action, time"),
    ]
    right = [
        (960, 140, "students\nregistration number is the id"),
        (960, 300, "courses, notifications, documents\nnested under each student"),
        (960, 480, "places\naliases, coordinates, node id"),
        (960, 660, "walkway graph\nnodes and connections"),
        (960, 840, "indoor_maps\nareas, points, edges"),
    ]
    for x, y, text in left + right:
        rounded(draw, (x, y, x + 700, y + 140), text, s, fill=WHITE)
    label(draw, (900, 1075), "The handbook is a versioned file on the service, not a student-writable collection.", s, INK)
    return save(image, "fig_6_10_database.png")


def build_all():
    return {
        "usecase": use_case(),
        "er": er_diagram(),
        "architecture": architecture(),
        "activity": activity(),
        "sequence": sequence(),
        "component": component(),
        "state": state_machine(),
        "class": class_diagram(),
        "dfd": data_flow(),
        "database": database(),
    }


if __name__ == "__main__":
    print(build_all())
