"""Lay the campus out on the DHA site plan. North is up on lgu_site_plan.png.

x is west to east across the image, y is north to south (0 at the top).
Replace these with surveyed coordinates before a field demo.
"""

import csv
import json
import struct
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"
ASSETS = ROOT.parent / "aicc" / "assets" / "maps"

SOUTH, NORTH = 31.468823, 31.471078
WEST, EAST = 74.405577, 74.407263


def ll(x: float, y: float) -> tuple[float, float]:
    lat = round(NORTH - y * (NORTH - SOUTH), 6)
    lng = round(WEST + x * (EAST - WEST), 6)
    return lat, lng


def point(x: float, y: float) -> dict:
    lat, lng = ll(x, y)
    return {"lat": lat, "lng": lng}


NODES = {
    "gate": (0.22, 0.93, "Main Gate", "", ""),
    "south": (0.32, 0.84, "South walk", "", ""),
    "cafe": (0.80, 0.40, "Canteen", "", ""),
    "park": (0.74, 0.10, "Parking", "", ""),
    "moto": (0.46, 0.16, "Motorcycle parking", "", ""),
    "masjid": (0.60, 0.52, "Green lawn", "", ""),
    "central": (0.48, 0.58, "Paved area", "", ""),
    "fountain": (0.46, 0.78, "Circular lawn", "", ""),
    "wash": (0.52, 0.64, "Washrooms", "", ""),
    "west": (0.30, 0.66, "Admin walk", "", ""),
    "east": (0.68, 0.42, "East walk", "", ""),
    "north": (0.50, 0.30, "North walk", "", ""),
    "admin": (0.24, 0.66, "Admin", "Admin", "Ground"),
    "lib": (0.34, 0.50, "Library", "Faculty A", "Ground"),
    "blockb": (0.40, 0.56, "Faculty B door", "Faculty B", "Ground"),
    "blockc": (0.56, 0.42, "Faculty C", "Faculty C", "Ground"),
    "blockd": (0.70, 0.40, "Canteen wing", "Canteen", "Ground"),
    "blocke": (0.36, 0.44, "Faculty wing", "Faculty A", "Ground"),
    "blocka": (0.32, 0.48, "Faculty A", "Faculty A", "Ground"),
    "sports": (0.62, 0.22, "Play ground", "Play Ground", "Ground"),
    "labs": (0.50, 0.46, "Labs", "Faculty C", "Ground"),
    "gate3": (0.34, 0.30, "North gate", "", ""),
    "auditorium": (0.42, 0.46, "Hall", "Faculty B", "Ground"),
    "stationery": (0.22, 0.56, "Stationery", "Admin", "Ground"),
    "bbg": (0.42, 0.56, "Faculty B hall", "Faculty B", "Ground"),
    "bbgs": (0.44, 0.54, "Faculty B stairs", "Faculty B", "Ground"),
    "bb1s": (0.44, 0.54, "Faculty B stairs", "Faculty B", "First"),
    "bbgl": (0.46, 0.56, "Faculty B lift", "Faculty B", "Ground"),
    "bb1l": (0.46, 0.56, "Faculty B lift", "Faculty B", "First"),
    "bb1": (0.44, 0.50, "Classroom B-104", "Faculty B", "First"),
}

EDGES = [
    ("gate", "south", False),
    ("south", "cafe", False),
    ("south", "park", False),
    ("south", "central", False),
    ("south", "masjid", False),
    ("masjid", "moto", False),
    ("central", "fountain", False),
    ("central", "wash", False),
    ("central", "west", False),
    ("central", "east", False),
    ("central", "north", False),
    ("west", "lib", False),
    ("west", "blockb", False),
    ("lib", "sports", False),
    ("north", "admin", False),
    ("north", "blocke", False),
    ("admin", "blocka", False),
    ("admin", "auditorium", False),
    ("admin", "stationery", False),
    ("east", "blockd", False),
    ("east", "labs", False),
    ("east", "blockc", False),
    ("labs", "gate3", False),
    ("blockb", "bbg", False),
    ("bbg", "bbgs", False),
    ("bbg", "bbgl", False),
    ("bbgs", "bb1s", True),
    ("bbgl", "bb1l", False),
    ("bb1s", "bb1", False),
    ("bb1l", "bb1", False),
]

PLACES = [
    ("lgu", "LGU Main Campus", "lgu;lahore garrison university;campus", "Gates", "central", "", "", "", "Lahore Garrison University campus in DHA Phase 6."),
    ("main-gate", "Main Gate", "main gate;front gate", "Gates", "gate", "", "", "06:00-22:00", "Primary student entrance on the south side."),
    ("gate-3", "Gate 3", "gate 3;gate #3;gate no 3", "Gates", "gate3", "", "", "06:00-22:00", "North-east campus gate."),
    ("cafe", "LGU Cafe", "lgu cafe;cafe;canteen;cafeteria", "Food", "cafe", "", "", "08:00-20:00", "Snacks, lunch and tea."),
    ("block-a", "Faculty A", "block a;a block;faculty a", "Academic", "blocka", "Faculty A", "Ground", "08:00-16:00", "Faculty A wing beside the admin block."),
    ("block-b", "Faculty B", "block b;b block;faculty b", "Academic", "blockb", "Faculty B", "Ground", "08:00-16:00", "Faculty B classrooms."),
    ("block-c", "Faculty C", "block c;c block;faculty c", "Academic", "blockc", "Faculty C", "Ground", "08:00-16:00", "Faculty C beside the canteen."),
    ("block-d", "Canteen Wing", "block d;d block", "Food", "blockd", "Canteen", "Ground", "08:00-16:00", "Second canteen on the site plan."),
    ("block-e", "Faculty Wing", "block e;e block", "Academic", "blocke", "Faculty A", "Ground", "08:00-16:00", "Upper faculty wing."),
    ("fountain", "Circular Lawn", "fountain ground;fountain;circular lawn", "Sports", "fountain", "", "", "", "Round green lawn in front of the faculty blocks."),
    ("sports", "Play Ground", "play ground;playground;sports;sports complex", "Sports", "sports", "Play Ground", "Ground", "08:00-18:00", "Football ground on the north side."),
    ("library", "Central Library", "library;central library", "Library", "lib", "Faculty A", "Ground", "08:30-20:00", "Library inside the faculty wing. Closed Saturday and Sunday."),
    ("admin", "Admin Block", "admin;admin block;student desk", "Admin", "admin", "Admin", "Ground", "08:30-16:00", "Admin block on the west side of the site."),
    ("masjid", "Masjid", "masjid;mosque;prayer area;namaz", "Prayer", "masjid", "", "Ground", "05:00-22:00", "Prayer area on the green lawn."),
    ("labs", "Computer Labs", "computer lab;labs;lab", "Labs", "labs", "Labs", "Ground", "08:30-16:00", "Junior and senior computer labs."),
    ("washroom", "Central Washrooms", "washroom;washrooms;toilet;restroom", "Washrooms", "wash", "", "", "", "Washrooms beside the central walk."),
    ("parking", "Car Parking", "parking;car parking", "Parking", "park", "", "", "", "Car parking on the north side."),
    ("auditorium", "Auditorium", "auditorium;hall", "Academic", "auditorium", "Faculty B", "Ground", "09:00-16:00", "Hall beside Faculty B."),
    ("principal", "Principal Office", "principal;principal office", "Admin", "admin", "Block A", "Ground", "09:00-15:00", "Principal office inside the admin block."),
    ("stationery", "Stationery Shop", "stationery;photocopy", "Admin", "stationery", "Block A", "Ground", "08:30-16:00", "Stationery and photocopy."),
    ("motorcycle", "Motorcycle Parking", "motorcycle parking;bike parking;motorcycle", "Parking", "moto", "", "", "", "Motorcycle shed on the east side."),
    ("classroom-b104", "Classroom B-104", "b-104;b104;classroom b-104", "Academic", "bb1", "Faculty B", "First", "08:00-16:00", "First-floor classroom in Faculty B."),
    ("phy-lab", "Physics Lab", "physics lab;phy lab", "Labs", "blockc", "Block C", "Ground", "08:30-16:00", "Physics lab in Block C."),
]


def box(x: float, y: float, half_x: float = 0.06, half_y: float = 0.045) -> list[dict]:
    corners = [
        (x - half_x, y - half_y),
        (x + half_x, y - half_y),
        (x + half_x, y + half_y),
        (x - half_x, y + half_y),
    ]
    return [point(px, py) for px, py in corners]


def png(path: Path, width: int, height: int, painter) -> None:
    raw = bytearray()
    for y in range(height):
        raw.append(0)
        for x in range(width):
            raw.extend(painter(x, y))
    def chunk(tag: bytes, data: bytes) -> bytes:
        return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)
    ihdr = struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0)
    blob = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", ihdr) + chunk(b"IDAT", zlib.compress(bytes(raw), 9)) + chunk(b"IEND", b"")
    path.write_bytes(blob)


def floor_painter(first: bool):
    def paint(x: int, y: int):
        wall = x < 10 or y < 10 or x > 389 or y > 229 or abs(x - 200) < 6
        door = (abs(x - 200) < 6 and 100 < y < 128) or (y > 220 and 170 < x < 210)
        stair = 40 < x < 90 and y > 170
        lift = 300 < x < 350 and y > 175
        room = 16 < x < 190 or 210 < x < 384
        if wall and not door:
            return (30, 41, 59)
        if stair:
            return (148, 163, 184) if (y // 8) % 2 == 0 else (226, 232, 240)
        if lift:
            return (14, 116, 144)
        if door:
            return (254, 243, 199)
        if abs(x - 200) < 28:
            return (241, 245, 249)
        if room and not first and x < 190 and y < 110:
            return (219, 234, 254)
        if room and first and x > 210 and y < 120:
            return (254, 226, 226)
        return (248, 250, 252)
    return paint


def main() -> None:
    DATA.mkdir(parents=True, exist_ok=True)
    ASSETS.mkdir(parents=True, exist_ok=True)
    node_ll = {key: ll(x, y) for key, (x, y, *_) in NODES.items()}

    places = []
    for pid, name, aliases, category, node, building, floor, hours, description in PLACES:
        lat, lng = node_ll[node]
        places.append(
            {
                "id": pid,
                "name": name,
                "aliases": [part.strip() for part in aliases.split(";") if part.strip()],
                "category": category,
                "lat": lat,
                "lng": lng,
                "entrance": {"lat": lat, "lng": lng},
                "building": building,
                "floor": floor,
                "hours": hours,
                "description": description,
                "photoUrl": "",
                "nodeId": node,
                "isActive": True,
            }
        )

    nodes = []
    for key, (x, y, label, building, floor) in NODES.items():
        lat, lng = node_ll[key]
        nodes.append(
            {
                "id": key,
                "lat": lat,
                "lng": lng,
                "label": label,
                "building": building,
                "floor": floor,
            }
        )

    graph = {
        "nodes": nodes,
        "edges": [
            {"a": a, "b": b, "stairs": stairs, "accessible": True} for a, b, stairs in EDGES
        ],
        "campusPolygon": [
            point(x, y)
            for x, y in (
                (0.06, 0.97),
                (0.62, 0.97),
                (0.94, 0.62),
                (0.88, 0.06),
                (0.28, 0.08),
                (0.05, 0.48),
            )
        ],
        "gates": ["main-gate", "gate-3"],
        "sitePlan": {
            "image": "assets/maps/lgu_site_plan.png",
            "south": SOUTH,
            "west": WEST,
            "north": NORTH,
            "east": EAST,
        },
        "buildings": [
            {"id": "admin", "name": "Admin", "category": "Admin", "polygon": box(0.24, 0.66, 0.08, 0.08)},
            {"id": "faculty-a", "name": "Faculty A", "category": "Academic", "polygon": box(0.34, 0.48, 0.07, 0.05)},
            {"id": "faculty-b", "name": "Faculty B", "category": "Academic", "polygon": box(0.42, 0.54, 0.07, 0.05)},
            {"id": "faculty-c", "name": "Faculty C", "category": "Academic", "polygon": box(0.56, 0.42, 0.07, 0.05)},
            {"id": "canteen", "name": "Canteen", "category": "Food", "polygon": box(0.80, 0.40, 0.06, 0.045)},
            {"id": "lawn", "name": "Circular Lawn", "category": "Sports", "polygon": box(0.46, 0.78, 0.08, 0.07)},
            {"id": "playground", "name": "Play Ground", "category": "Sports", "polygon": box(0.62, 0.22, 0.10, 0.07)},
            {"id": "parking", "name": "Parking", "category": "Parking", "polygon": box(0.74, 0.10, 0.08, 0.05)},
        ],
        "floors": [
            {
                "id": "block-b-ground",
                "building": "Faculty B",
                "floor": "Ground",
                "image": "assets/maps/block_b_ground.png",
                "south": ll(0.36, 0.60)[0],
                "west": ll(0.36, 0.60)[1],
                "north": ll(0.50, 0.48)[0],
                "east": ll(0.50, 0.48)[1],
            },
            {
                "id": "block-b-first",
                "building": "Faculty B",
                "floor": "First",
                "image": "assets/maps/block_b_first.png",
                "south": ll(0.36, 0.60)[0],
                "west": ll(0.36, 0.60)[1],
                "north": ll(0.50, 0.48)[0],
                "east": ll(0.50, 0.48)[1],
            },
        ],
    }

    csv_path = DATA / "places.csv"
    with csv_path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(
            handle,
            fieldnames=["id", "name", "aliases", "category", "lat", "lng", "building", "floor", "hours", "description", "node_id"],
        )
        writer.writeheader()
        for place in places:
            writer.writerow(
                {
                    "id": place["id"],
                    "name": place["name"],
                    "aliases": ";".join(place["aliases"]),
                    "category": place["category"],
                    "lat": place["lat"],
                    "lng": place["lng"],
                    "building": place["building"],
                    "floor": place["floor"],
                    "hours": place["hours"],
                    "description": place["description"],
                    "node_id": place["nodeId"],
                }
            )

    (DATA / "graph.json").write_text(json.dumps(graph, indent=2), encoding="utf-8")
    (DATA / "places.json").write_text(json.dumps(places, indent=2), encoding="utf-8")
    (ASSETS / "graph.json").write_text(json.dumps(graph, indent=2), encoding="utf-8")
    (ASSETS / "places.json").write_text(json.dumps(places, indent=2), encoding="utf-8")
    png(ASSETS / "block_b_ground.png", 400, 240, floor_painter(False))
    png(ASSETS / "block_b_first.png", 400, 240, floor_painter(True))
    print(f"Wrote {len(places)} places and {len(nodes)} nodes")


if __name__ == "__main__":
    main()
