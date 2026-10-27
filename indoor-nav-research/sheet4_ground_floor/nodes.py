"""Ground-floor nodes read from sheet 4 of the LGU plan.

Each labeled room, gate, and parking area on the uploaded PDF is one node.
The kind field is the category, so a classroom, a toilet, a canteen, a
parking area, an office, and a gate are different node types.

The walkway from Pathway.pdf is stored beside this file in nodes.json.
shortest_route() follows that centerline from one node to another.

This file is a snapshot of that sheet. It is not imported by the app.
"""

from __future__ import annotations

import json
import math
from dataclasses import dataclass
from enum import Enum
from pathlib import Path


class NodeKind(str, Enum):
    """One value per category on the ground-floor sheet."""

    CANTEEN = "canteen"
    CLASSROOM = "classroom"
    CORRIDOR = "corridor"
    COURTYARD = "courtyard"
    DECK = "deck"
    FIRE_ESCAPE = "fire_escape"
    GATE = "gate"
    GUARD_ROOM = "guard_room"
    HALL = "hall"
    KITCHEN = "kitchen"
    LAB = "lab"
    LANDMARK = "landmark"
    LIBRARY = "library"
    LOBBY = "lobby"
    MEDICAL = "medical"
    OFFICE = "office"
    PARKING = "parking"
    PAVED = "paved"
    PLAYGROUND = "playground"
    ROOM = "room"
    STAFF_ROOM = "staff_room"
    STAIRS = "stairs"
    STATIONERY = "stationery"
    STORE = "store"
    TOILET = "toilet"


@dataclass(frozen=True, slots=True)
class RoomNode:
    """A single place on the sheet.

    sheet_x and sheet_y are PDF points on the upright page.
    Origin is the top-left corner, x grows right, y grows down.
    The point is the center of the label drawn inside that room.
    """

    id: str
    kind: NodeKind
    name: str
    zone: str
    sheet_x: float
    sheet_y: float
    size: str | None = None

    @property
    def source_x(self) -> float:
        """Mediabox x before the page rotation. Same number as sheet_y."""
        return self.sheet_y

    @property
    def source_y(self) -> float:
        """Mediabox y before the page rotation."""
        return 3456.0 - self.sheet_x


def nodes_of(kind: NodeKind) -> tuple[RoomNode, ...]:
    """Every node of one category, in sheet reading order."""
    return tuple(node for node in NODES if node.kind is kind)


NODES: tuple[RoomNode, ...] = (
    RoomNode(
        id="gf_canteen_01",
        kind=NodeKind.CANTEEN,
        name="Canteen",
        zone="block_d",
        sheet_x=923.38,
        sheet_y=839.12,
        size="20'-0\"X20'-0\"",
    ),
    RoomNode(
        id="gf_canteen_02",
        kind=NodeKind.CANTEEN,
        name="Canteen",
        zone="site",
        sheet_x=1787.22,
        sheet_y=1610.03,
        size=None,
    ),
    RoomNode(
        id="gf_classroom_01",
        kind=NodeKind.CLASSROOM,
        name="Classroom",
        zone="block_c",
        sheet_x=1290.71,
        sheet_y=800.65,
        size="21'-0\"x24'-0\"",
    ),
    RoomNode(
        id="gf_classroom_02",
        kind=NodeKind.CLASSROOM,
        name="Classroom",
        zone="block_c",
        sheet_x=1355.99,
        sheet_y=839.29,
        size="21'-0\"x24'-0\"",
    ),
    RoomNode(
        id="gf_classroom_03",
        kind=NodeKind.CLASSROOM,
        name="Classroom",
        zone="block_c",
        sheet_x=1413.95,
        sheet_y=874.57,
        size="21'-0\"x24'-0\"",
    ),
    RoomNode(
        id="gf_classroom_04",
        kind=NodeKind.CLASSROOM,
        name="Classroom",
        zone="block_c",
        sheet_x=1320.47,
        sheet_y=886.69,
        size="21'-0\"x24'-0\"",
    ),
    RoomNode(
        id="gf_classroom_05",
        kind=NodeKind.CLASSROOM,
        name="Classroom",
        zone="block_c",
        sheet_x=1473.83,
        sheet_y=909.85,
        size="21'-0\"x24'-0\"",
    ),
    RoomNode(
        id="gf_classroom_06",
        kind=NodeKind.CLASSROOM,
        name="Classroom",
        zone="block_c",
        sheet_x=1387.55,
        sheet_y=915.13,
        size="21'-0\"x24'-0\"",
    ),
    RoomNode(
        id="gf_classroom_07",
        kind=NodeKind.CLASSROOM,
        name="Classroom",
        zone="block_c",
        sheet_x=1530.59,
        sheet_y=944.05,
        size="21'-0\"x24'-0\"",
    ),
    RoomNode(
        id="gf_classroom_08",
        kind=NodeKind.CLASSROOM,
        name="Classroom",
        zone="block_c",
        sheet_x=1447.91,
        sheet_y=951.97,
        size="21'-0\"x24'-0\"",
    ),
    RoomNode(
        id="gf_classroom_09",
        kind=NodeKind.CLASSROOM,
        name="Classroom",
        zone="block_c",
        sheet_x=1502.87,
        sheet_y=986.53,
        size="21'-0\"x24'-0\"",
    ),
    RoomNode(
        id="gf_classroom_10",
        kind=NodeKind.CLASSROOM,
        name="Classroom",
        zone="block_b",
        sheet_x=1465.67,
        sheet_y=1158.08,
        size="21'-0\"x24'-0\"",
    ),
    RoomNode(
        id="gf_classroom_11",
        kind=NodeKind.CLASSROOM,
        name="Classroom",
        zone="block_b",
        sheet_x=1416.11,
        sheet_y=1158.44,
        size="21'-0\"x24'-0\"",
    ),
    RoomNode(
        id="gf_classroom_12",
        kind=NodeKind.CLASSROOM,
        name="Classroom",
        zone="block_b",
        sheet_x=1465.67,
        sheet_y=1227.68,
        size="21'-0\"x24'-0\"",
    ),
    RoomNode(
        id="gf_classroom_13",
        kind=NodeKind.CLASSROOM,
        name="Classroom",
        zone="block_b",
        sheet_x=1416.11,
        sheet_y=1227.8,
        size="21'-0\"x24'-0\"",
    ),
    RoomNode(
        id="gf_classroom_14",
        kind=NodeKind.CLASSROOM,
        name="Classroom",
        zone="block_b",
        sheet_x=1421.87,
        sheet_y=1281.32,
        size="21'-0\"x24'-0\"",
    ),
    RoomNode(
        id="gf_classroom_15",
        kind=NodeKind.CLASSROOM,
        name="Classroom",
        zone="block_b",
        sheet_x=1465.67,
        sheet_y=1298.24,
        size="21'-0\"x24'-0\"",
    ),
    RoomNode(
        id="gf_classroom_16",
        kind=NodeKind.CLASSROOM,
        name="Classroom",
        zone="block_b",
        sheet_x=1416.11,
        sheet_y=1362.68,
        size="21'-0\"x24'-0\"",
    ),
    RoomNode(
        id="gf_classroom_17",
        kind=NodeKind.CLASSROOM,
        name="Classroom",
        zone="block_b",
        sheet_x=1465.67,
        sheet_y=1362.8,
        size="21'-0\"x24'-0\"",
    ),
    RoomNode(
        id="gf_classroom_18",
        kind=NodeKind.CLASSROOM,
        name="Classroom",
        zone="block_b",
        sheet_x=1416.11,
        sheet_y=1432.04,
        size="21'-0\"x24'-0\"",
    ),
    RoomNode(
        id="gf_classroom_19",
        kind=NodeKind.CLASSROOM,
        name="Classroom",
        zone="block_b",
        sheet_x=1465.67,
        sheet_y=1432.04,
        size="21'-0\"x24'-0\"",
    ),
    RoomNode(
        id="gf_corridor_01",
        kind=NodeKind.CORRIDOR,
        name="Corridor",
        zone="block_d",
        sheet_x=1150.69,
        sheet_y=769.4,
        size="8' wide",
    ),
    RoomNode(
        id="gf_corridor_02",
        kind=NodeKind.CORRIDOR,
        name="Corridor",
        zone="block_c",
        sheet_x=1516.6,
        sheet_y=881.32,
        size="8' wide",
    ),
    RoomNode(
        id="gf_corridor_03",
        kind=NodeKind.CORRIDOR,
        name="Corridor",
        zone="block_c",
        sheet_x=1283.2,
        sheet_y=909.64,
        size="8' wide",
    ),
    RoomNode(
        id="gf_corridor_04",
        kind=NodeKind.CORRIDOR,
        name="Corridor",
        zone="block_c",
        sheet_x=1452.52,
        sheet_y=1010.32,
        size="8' wide",
    ),
    RoomNode(
        id="gf_corridor_05",
        kind=NodeKind.CORRIDOR,
        name="Corridor",
        zone="block_c",
        sheet_x=1402.48,
        sheet_y=1081.69,
        size="8' wide",
    ),
    RoomNode(
        id="gf_corridor_06",
        kind=NodeKind.CORRIDOR,
        name="Corridor",
        zone="block_b",
        sheet_x=1369.81,
        sheet_y=1303.72,
        size="8' wide",
    ),
    RoomNode(
        id="gf_corridor_07",
        kind=NodeKind.CORRIDOR,
        name="Corridor",
        zone="block_b",
        sheet_x=1511.29,
        sheet_y=1351.84,
        size="8' wide",
    ),
    RoomNode(
        id="gf_corridor_08",
        kind=NodeKind.CORRIDOR,
        name="Corridor",
        zone="block_a",
        sheet_x=1258.84,
        sheet_y=1530.97,
        size="8' wide",
    ),
    RoomNode(
        id="gf_corridor_09",
        kind=NodeKind.CORRIDOR,
        name="Corridor",
        zone="block_a",
        sheet_x=1456.6,
        sheet_y=1530.97,
        size="8' wide",
    ),
    RoomNode(
        id="gf_courtyard_01",
        kind=NodeKind.COURTYARD,
        name="Courtyard",
        zone="block_b",
        sheet_x=1425.99,
        sheet_y=1049.1,
        size=None,
    ),
    RoomNode(
        id="gf_deck_01",
        kind=NodeKind.DECK,
        name="Deck (8'-0\" wide)",
        zone="east_wing",
        sheet_x=1702.51,
        sheet_y=995.48,
        size=None,
    ),
    RoomNode(
        id="gf_deck_02",
        kind=NodeKind.DECK,
        name="Deck (15'-3\" wide)",
        zone="east_wing",
        sheet_x=1626.75,
        sheet_y=1125.54,
        size=None,
    ),
    RoomNode(
        id="gf_fire_escape_01",
        kind=NodeKind.FIRE_ESCAPE,
        name="Fire escape ladder",
        zone="east_wing",
        sheet_x=1893.83,
        sheet_y=1160.92,
        size=None,
    ),
    RoomNode(
        id="gf_fire_escape_02",
        kind=NodeKind.FIRE_ESCAPE,
        name="Fire escape ladder",
        zone="east_wing",
        sheet_x=1675.12,
        sheet_y=1427.75,
        size=None,
    ),
    RoomNode(
        id="gf_gate_01",
        kind=NodeKind.GATE,
        name="Gate",
        zone="site",
        sheet_x=770.21,
        sheet_y=943.14,
        size=None,
    ),
    RoomNode(
        id="gf_gate_02",
        kind=NodeKind.GATE,
        name="Gate 3",
        zone="site",
        sheet_x=1796.28,
        sheet_y=955.76,
        size=None,
    ),
    RoomNode(
        id="gf_gate_03",
        kind=NodeKind.GATE,
        name="Gate",
        zone="site",
        sheet_x=1375.87,
        sheet_y=1861.51,
        size=None,
    ),
    RoomNode(
        id="gf_gate_04",
        kind=NodeKind.GATE,
        name="Gate",
        zone="site",
        sheet_x=934.75,
        sheet_y=1862.47,
        size=None,
    ),
    RoomNode(
        id="gf_guard_room_01",
        kind=NodeKind.GUARD_ROOM,
        name="Guard room",
        zone="site",
        sheet_x=1912.35,
        sheet_y=930.66,
        size=None,
    ),
    RoomNode(
        id="gf_guard_room_02",
        kind=NodeKind.GUARD_ROOM,
        name="Guard room",
        zone="site",
        sheet_x=1851.65,
        sheet_y=1008.01,
        size=None,
    ),
    RoomNode(
        id="gf_guard_room_03",
        kind=NodeKind.GUARD_ROOM,
        name="Guard room",
        zone="site",
        sheet_x=876.82,
        sheet_y=1851.38,
        size=None,
    ),
    RoomNode(
        id="gf_guard_room_04",
        kind=NodeKind.GUARD_ROOM,
        name="Guard room",
        zone="site",
        sheet_x=1005.24,
        sheet_y=1905.08,
        size=None,
    ),
    RoomNode(
        id="gf_hall_01",
        kind=NodeKind.HALL,
        name="Hall",
        zone="east_wing",
        sheet_x=1674.13,
        sheet_y=1047.98,
        size="43'-0\"x41'-9\"",
    ),
    RoomNode(
        id="gf_hall_02",
        kind=NodeKind.HALL,
        name="Hall",
        zone="library",
        sheet_x=785.52,
        sheet_y=1478.27,
        size="30'-9\"X44'-0\"",
    ),
    RoomNode(
        id="gf_hall_03",
        kind=NodeKind.HALL,
        name="Hall",
        zone="library",
        sheet_x=849.72,
        sheet_y=1515.35,
        size="30'-9\"X44'-0\"",
    ),
    RoomNode(
        id="gf_kitchen_01",
        kind=NodeKind.KITCHEN,
        name="Kitchen",
        zone="block_d",
        sheet_x=884.2,
        sheet_y=898.4,
        size="15'-0\"X18'-0\"",
    ),
    RoomNode(
        id="gf_lab_01",
        kind=NodeKind.LAB,
        name="Physics lab",
        zone="block_d",
        sheet_x=1157.89,
        sheet_y=726.8,
        size="44'-3\"X25'-0\"",
    ),
    RoomNode(
        id="gf_lab_02",
        kind=NodeKind.LAB,
        name="Chemistry lab",
        zone="block_d",
        sheet_x=983.73,
        sheet_y=757.52,
        size="45'-0\"X25'-0\"",
    ),
    RoomNode(
        id="gf_landmark_01",
        kind=NodeKind.LANDMARK,
        name="Fountain",
        zone="block_a",
        sheet_x=1156.25,
        sheet_y=1532.03,
        size=None,
    ),
    RoomNode(
        id="gf_library_01",
        kind=NodeKind.LIBRARY,
        name="Library block",
        zone="library",
        sheet_x=875.52,
        sheet_y=1409.18,
        size=None,
    ),
    RoomNode(
        id="gf_lobby_01",
        kind=NodeKind.LOBBY,
        name="Lobby (double height)",
        zone="block_a",
        sheet_x=1156.3,
        sheet_y=1489.79,
        size=None,
    ),
    RoomNode(
        id="gf_medical_01",
        kind=NodeKind.MEDICAL,
        name="M.I. room",
        zone="block_a",
        sheet_x=1254.0,
        sheet_y=1503.35,
        size="12'-0\"X10'-0\"",
    ),
    RoomNode(
        id="gf_office_01",
        kind=NodeKind.OFFICE,
        name="Lab incharge",
        zone="block_d",
        sheet_x=1101.29,
        sheet_y=700.43,
        size=None,
    ),
    RoomNode(
        id="gf_office_02",
        kind=NodeKind.OFFICE,
        name="Lab incharge",
        zone="block_d",
        sheet_x=1022.66,
        sheet_y=709.92,
        size=None,
    ),
    RoomNode(
        id="gf_office_03",
        kind=NodeKind.OFFICE,
        name="Visitor room",
        zone="block_a",
        sheet_x=1211.7,
        sheet_y=1497.95,
        size="18'-3\"X19'-3\"",
    ),
    RoomNode(
        id="gf_office_04",
        kind=NodeKind.OFFICE,
        name="Exam incharge",
        zone="block_a",
        sheet_x=1055.84,
        sheet_y=1503.35,
        size="12'-0\"X19'-3\"",
    ),
    RoomNode(
        id="gf_office_05",
        kind=NodeKind.OFFICE,
        name="Manager / Admin",
        zone="block_a",
        sheet_x=1236.54,
        sheet_y=1565.15,
        size="10'-0\"X16'-0\"",
    ),
    RoomNode(
        id="gf_office_06",
        kind=NodeKind.OFFICE,
        name="V.P. room",
        zone="block_a",
        sheet_x=1279.1,
        sheet_y=1565.15,
        size="20'-0\"X16'-0\"",
    ),
    RoomNode(
        id="gf_office_07",
        kind=NodeKind.OFFICE,
        name="Clerical",
        zone="block_a",
        sheet_x=1031.26,
        sheet_y=1566.95,
        size="22'-0\"X16'-0\"",
    ),
    RoomNode(
        id="gf_office_08",
        kind=NodeKind.OFFICE,
        name="Clerical",
        zone="block_a",
        sheet_x=975.22,
        sheet_y=1581.59,
        size="20'-0\"X16'-0\"",
    ),
    RoomNode(
        id="gf_office_09",
        kind=NodeKind.OFFICE,
        name="Principal room",
        zone="block_a",
        sheet_x=1333.71,
        sheet_y=1582.19,
        size="20'-0\"X16'-0\"",
    ),
    RoomNode(
        id="gf_parking_01",
        kind=NodeKind.PARKING,
        name="Motorcycle parking (441)",
        zone="site",
        sheet_x=1285.02,
        sheet_y=620.39,
        size=None,
    ),
    RoomNode(
        id="gf_parking_02",
        kind=NodeKind.PARKING,
        name="Motorcycle parking (318)",
        zone="site",
        sheet_x=881.69,
        sheet_y=721.14,
        size=None,
    ),
    RoomNode(
        id="gf_parking_03",
        kind=NodeKind.PARKING,
        name="Parking shed",
        zone="site",
        sheet_x=1458.13,
        sheet_y=745.97,
        size=None,
    ),
    RoomNode(
        id="gf_parking_04",
        kind=NodeKind.PARKING,
        name="Bus parking",
        zone="site",
        sheet_x=557.69,
        sheet_y=1774.79,
        size=None,
    ),
    RoomNode(
        id="gf_parking_05",
        kind=NodeKind.PARKING,
        name="Bus parking",
        zone="site",
        sheet_x=2158.25,
        sheet_y=1846.07,
        size=None,
    ),
    RoomNode(
        id="gf_paved_01",
        kind=NodeKind.PAVED,
        name="Paved area",
        zone="court",
        sheet_x=1049.88,
        sheet_y=886.79,
        size=None,
    ),
    RoomNode(
        id="gf_playground_01",
        kind=NodeKind.PLAYGROUND,
        name="Playground",
        zone="site",
        sheet_x=2135.13,
        sheet_y=1501.79,
        size=None,
    ),
    RoomNode(
        id="gf_room_01",
        kind=NodeKind.ROOM,
        name="Room",
        zone="east_wing",
        sheet_x=1629.01,
        sheet_y=987.05,
        size="8'-0\"x13'-3\"",
    ),
    RoomNode(
        id="gf_room_02",
        kind=NodeKind.ROOM,
        name="Room",
        zone="east_wing",
        sheet_x=1608.37,
        sheet_y=1018.73,
        size="8'-0\"x13'-3\"",
    ),
    RoomNode(
        id="gf_room_03",
        kind=NodeKind.ROOM,
        name="Room",
        zone="east_wing",
        sheet_x=1588.69,
        sheet_y=1052.45,
        size="8'-0\"x13'-3\"",
    ),
    RoomNode(
        id="gf_room_04",
        kind=NodeKind.ROOM,
        name="Room",
        zone="block_b",
        sheet_x=1428.28,
        sheet_y=1110.94,
        size="11'-0\"x10'-0\"",
    ),
    RoomNode(
        id="gf_room_05",
        kind=NodeKind.ROOM,
        name="Room",
        zone="block_b",
        sheet_x=1394.32,
        sheet_y=1111.06,
        size="11'-0\"x10'-0\"",
    ),
    RoomNode(
        id="gf_staff_room_01",
        kind=NodeKind.STAFF_ROOM,
        name="Staff room",
        zone="block_c",
        sheet_x=1281.53,
        sheet_y=857.41,
        size="20'-9\"X12'-0\"",
    ),
    RoomNode(
        id="gf_stairs_01",
        kind=NodeKind.STAIRS,
        name="Stairs up",
        zone="block_d",
        sheet_x=1066.97,
        sheet_y=638.63,
        size=None,
    ),
    RoomNode(
        id="gf_stairs_02",
        kind=NodeKind.STAIRS,
        name="Stairs up",
        zone="block_c",
        sheet_x=1261.73,
        sheet_y=749.39,
        size=None,
    ),
    RoomNode(
        id="gf_stairs_03",
        kind=NodeKind.STAIRS,
        name="Stairs up",
        zone="library",
        sheet_x=891.41,
        sheet_y=828.03,
        size=None,
    ),
    RoomNode(
        id="gf_stairs_04",
        kind=NodeKind.STAIRS,
        name="Stairs up",
        zone="east_wing",
        sheet_x=1538.73,
        sheet_y=1048.61,
        size=None,
    ),
    RoomNode(
        id="gf_stairs_05",
        kind=NodeKind.STAIRS,
        name="Stairs up",
        zone="block_b",
        sheet_x=1490.09,
        sheet_y=1105.31,
        size=None,
    ),
    RoomNode(
        id="gf_stairs_06",
        kind=NodeKind.STAIRS,
        name="Stairs down",
        zone="east_wing",
        sheet_x=1878.76,
        sheet_y=1149.18,
        size=None,
    ),
    RoomNode(
        id="gf_stairs_07",
        kind=NodeKind.STAIRS,
        name="Stairs down",
        zone="east_wing",
        sheet_x=1711.12,
        sheet_y=1483.5,
        size=None,
    ),
    RoomNode(
        id="gf_stairs_08",
        kind=NodeKind.STAIRS,
        name="Stairs up",
        zone="block_a",
        sheet_x=1384.37,
        sheet_y=1494.83,
        size=None,
    ),
    RoomNode(
        id="gf_stairs_09",
        kind=NodeKind.STAIRS,
        name="Stairs up",
        zone="block_a",
        sheet_x=1213.85,
        sheet_y=1544.87,
        size=None,
    ),
    RoomNode(
        id="gf_stationery_01",
        kind=NodeKind.STATIONERY,
        name="Stationery / Photocopy",
        zone="block_a",
        sheet_x=1096.35,
        sheet_y=1574.15,
        size="21'-0\"X16'-0\"",
    ),
    RoomNode(
        id="gf_store_01",
        kind=NodeKind.STORE,
        name="Store",
        zone="block_d",
        sheet_x=1108.68,
        sheet_y=672.61,
        size=None,
    ),
    RoomNode(
        id="gf_store_02",
        kind=NodeKind.STORE,
        name="Store",
        zone="block_d",
        sheet_x=999.72,
        sheet_y=693.49,
        size=None,
    ),
    RoomNode(
        id="gf_store_03",
        kind=NodeKind.STORE,
        name="Store",
        zone="block_a",
        sheet_x=1100.8,
        sheet_y=1487.99,
        size="18'-3\"X19'-3\"",
    ),
    RoomNode(
        id="gf_store_04",
        kind=NodeKind.STORE,
        name="Store",
        zone="block_a",
        sheet_x=1439.88,
        sheet_y=1514.61,
        size=None,
    ),
    RoomNode(
        id="gf_toilet_01",
        kind=NodeKind.TOILET,
        name="Toilet",
        zone="block_c",
        sheet_x=1222.6,
        sheet_y=828.61,
        size=None,
    ),
    RoomNode(
        id="gf_toilet_02",
        kind=NodeKind.TOILET,
        name="Toilet",
        zone="block_c",
        sheet_x=1252.4,
        sheet_y=851.6,
        size=None,
    ),
    RoomNode(
        id="gf_toilet_03",
        kind=NodeKind.TOILET,
        name="Toilet",
        zone="block_c",
        sheet_x=1567.39,
        sheet_y=983.54,
        size=None,
    ),
    RoomNode(
        id="gf_toilet_04",
        kind=NodeKind.TOILET,
        name="Toilet",
        zone="block_a",
        sheet_x=1270.56,
        sheet_y=1475.72,
        size=None,
    ),
    RoomNode(
        id="gf_toilet_05",
        kind=NodeKind.TOILET,
        name="Toilet",
        zone="block_a",
        sheet_x=1457.73,
        sheet_y=1479.86,
        size=None,
    ),
    RoomNode(
        id="gf_toilet_06",
        kind=NodeKind.TOILET,
        name="Toilet",
        zone="block_a",
        sheet_x=944.04,
        sheet_y=1550.52,
        size="8'-6\"X8'-6\"",
    ),
    RoomNode(
        id="gf_toilet_07",
        kind=NodeKind.TOILET,
        name="Toilet",
        zone="block_a",
        sheet_x=1368.96,
        sheet_y=1550.52,
        size="8'-6\"X8'-6\"",
    ),
    RoomNode(
        id="gf_toilet_08",
        kind=NodeKind.TOILET,
        name="Toilet",
        zone="block_a",
        sheet_x=1015.32,
        sheet_y=1596.72,
        size="8'-0\"X4'-9\"",
    ),
    RoomNode(
        id="gf_toilet_09",
        kind=NodeKind.TOILET,
        name="Toilet",
        zone="block_a",
        sheet_x=1297.68,
        sheet_y=1596.72,
        size="8'-0\"X4'-9\"",
    ),
)


@dataclass(frozen=True)
class Route:
    """Shortest walk along the drawn pathway.

    length is in sheet points, the same unit as sheet_x and sheet_y.
    points is the polyline from the start node to the end node.
    """

    start_id: str
    end_id: str
    found: bool
    length: float
    points: tuple[tuple[float, float], ...]


def _sheet() -> dict:
    path = Path(__file__).with_name("nodes.json")
    return json.loads(path.read_text(encoding="utf-8"))


def shortest_route(start_id: str, end_id: str) -> Route:
    """Closest route on the pathway from one node to another.

    Search is A*. The estimate is the straight-line sheet distance to the
    goal vertex, which never exceeds the walk along the centerline.
    """
    sheet = _sheet()
    rooms = {node["id"]: node for node in sheet["nodes"]}
    if start_id not in rooms or end_id not in rooms:
        raise KeyError("Both ids must be nodes on this sheet.")
    if start_id == end_id:
        room = rooms[start_id]
        point = (room["sheet_x"], room["sheet_y"])
        return Route(start_id, end_id, True, 0.0, (point,))

    pathways = sheet["pathways"]
    links = {link["room"]: link for link in pathways["links"]}
    graph: dict[str, list[tuple[str, float, list[list[float]]]]] = {}
    for edge in pathways["edges"]:
        graph.setdefault(edge["a"], []).append((edge["b"], edge["length"], edge["points"]))
        graph.setdefault(edge["b"], []).append(
            (edge["a"], edge["length"], list(reversed(edge["points"])))
        )

    start = links[start_id]["vertex"]
    goal = links[end_id]["vertex"]
    positions = {
        vertex["id"]: (vertex["sheet_x"], vertex["sheet_y"])
        for vertex in pathways["vertices"]
    }

    def straight_line(vertex_id: str) -> float:
        point = positions.get(vertex_id)
        target = positions.get(goal)
        if point is None or target is None:
            return 0.0
        return math.hypot(point[0] - target[0], point[1] - target[1])

    dist = {start: links[start_id]["length"]}
    came: dict[str, tuple[str, list[list[float]]]] = {}
    done: set[str] = set()
    while True:
        pending = [vid for vid in dist if vid not in done]
        if not pending:
            return Route(start_id, end_id, False, 0.0, ())
        current = min(pending, key=lambda vid: dist[vid] + straight_line(vid))
        if current == goal:
            break
        done.add(current)
        for nxt, weight, points in graph.get(current, []):
            if nxt in done:
                continue
            score = dist[current] + weight
            if score < dist.get(nxt, float("inf")):
                dist[nxt] = score
                came[nxt] = (current, points)

    line: list[tuple[float, float]] = [
        (rooms[start_id]["sheet_x"], rooms[start_id]["sheet_y"])
    ]
    stack: list[list[list[float]]] = []
    cursor = goal
    while cursor != start:
        previous, points = came[cursor]
        stack.append(points)
        cursor = previous
    for points in reversed(stack):
        for x, y in points:
            if not line or (x, y) != line[-1]:
                line.append((x, y))
    end = (rooms[end_id]["sheet_x"], rooms[end_id]["sheet_y"])
    if line[-1] != end:
        line.append(end)
    length = round(dist[goal] + links[end_id]["length"], 2)
    return Route(start_id, end_id, True, length, tuple(line))


if __name__ == "__main__":
    from collections import Counter

    counts = Counter(node.kind.value for node in NODES)
    print(f"{len(NODES)} nodes")
    for kind, count in sorted(counts.items()):
        print(f"  {kind:16} {count}")
    sample = shortest_route("gf_classroom_10", "gf_gate_02")
    print(
        f"route {sample.start_id} -> {sample.end_id}: "
        f"found={sample.found} length={sample.length} points={len(sample.points)}"
    )
