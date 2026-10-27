"""20-slide AICC final-year presentation."""

import os

from PIL import Image, ImageDraw, ImageFont
from pptx import Presentation
from pptx.dml.color import RGBColor
from pptx.enum.shapes import MSO_SHAPE
from pptx.enum.text import MSO_ANCHOR, PP_ALIGN
from pptx.oxml.ns import qn
from pptx.util import Emu, Inches, Pt

OUT = r"e:\FYP\docs\AICC_FYP_Presentation.pptx"
UI = r"e:\FYP\docs\slides\ui"
FIG = r"e:\FYP\docs\figures"
ICON = r"e:\FYP\aicc\assets\branding\app_icon.jpg"
SITE = r"e:\FYP\aicc\assets\maps\lgu_site_plan.png"
FLOOR = r"e:\FYP\aicc\assets\maps\block_b_first.png"

NAVY = RGBColor(0x0B, 0x3D, 0x66)
NAVY_T = (11, 61, 102)
BLUE = RGBColor(0x1B, 0x5F, 0x9C)
GREEN = RGBColor(0x2E, 0x9E, 0x6C)
GREEN_T = (46, 158, 108)
INK = RGBColor(0x1A, 0x23, 0x30)
MUTED = RGBColor(0x5C, 0x6B, 0x7A)
WHITE = RGBColor(0xFF, 0xFF, 0xFF)
PAPER = RGBColor(0xF4, 0xF7, 0xFA)
GOLD = RGBColor(0xC4, 0xA3, 0x5A)

W = Inches(13.333)
H = Inches(7.5)


def font(size, bold=False):
    path = r"C:\Windows\Fonts\segoeuib.ttf" if bold else r"C:\Windows\Fonts\segoeui.ttf"
    return ImageFont.truetype(path, size)


def rounded(draw, box, radius, fill, outline=None, width=2):
    draw.rounded_rectangle(box, radius=radius, fill=fill, outline=outline, width=width)


def text(draw, xy, value, face, fill=(26, 35, 48), anchor="lt"):
    draw.text(xy, value, font=face, fill=fill, anchor=anchor)


def phone(path, paint):
    width, height = 620, 1280
    image = Image.new("RGB", (width, height), (238, 241, 244))
    draw = ImageDraw.Draw(image)
    draw.rectangle((0, 0, width, 92), fill=NAVY_T)
    text(draw, (36, 28), "9:41", font(22, True), (255, 255, 255))
    paint(draw, image)
    draw.rounded_rectangle((230, 1228, 390, 1248), radius=10, fill=(180, 190, 200))
    os.makedirs(os.path.dirname(path), exist_ok=True)
    image.save(path, "PNG")
    return path


def screen_home():
    def paint(draw, image):
        text(draw, (36, 118), "Home", font(34, True), NAVY_T)
        rounded(draw, (28, 180, 430, 360), 28, NAVY_T)
        text(draw, (52, 204), "Good morning,", font(20), (220, 230, 240))
        text(draw, (52, 236), "Abdul", font(40, True), (255, 255, 255))
        text(draw, (52, 292), "FA26-BSCS-001", font(20), (220, 230, 240))
        icon = Image.open(ICON).convert("RGB").resize((120, 120))
        image.paste(icon, (470, 196))
        chips = [("BS Computer Science", 28), ("Semester 4", 250), ("Section A", 430)]
        x = 28
        for label, _ in (("BSCS", 0), ("Semester 4", 0), ("Section A", 0)):
            tw = int(draw.textlength(label, font=font(18, True))) + 36
            rounded(draw, (x, 384, x + tw, 428), 18, (255, 255, 255), (226, 231, 237))
            text(draw, (x + 18, 394), label, font(18, True), NAVY_T)
            x += tw + 12
        rounded(draw, (28, 456, 300, 640), 24, (255, 255, 255), (226, 231, 237))
        text(draw, (48, 478), "CGPA", font(18), (107, 118, 132))
        text(draw, (48, 516), "3.62", font(54, True), NAVY_T)
        text(draw, (48, 586), "out of 4.00", font(18), (107, 118, 132))
        rounded(draw, (320, 456, 592, 640), 24, (255, 255, 255), (226, 231, 237))
        text(draw, (340, 478), "Attendance", font(18), (107, 118, 132))
        text(draw, (340, 516), "86%", font(54, True), GREEN_T)
        text(draw, (340, 586), "this semester", font(18), (107, 118, 132))
        text(draw, (32, 668), "This semester", font(26, True), NAVY_T)
        courses = [("CS-401  Final Year Project", "92%"), ("CS-402  Information Security", "81%"), ("CS-403  Software Quality", "84%")]
        y = 714
        for name, mark in courses:
            rounded(draw, (28, y, 592, y + 78), 18, (255, 255, 255), (226, 231, 237))
            text(draw, (48, y + 24), name, font(20, True), (26, 35, 48))
            text(draw, (500, y + 24), mark, font(20, True), GREEN_T)
            y += 92
        text(draw, (32, 1010), "Quick actions", font(26, True), NAVY_T)
        actions = [(28, "Chat"), (220, "Documents"), (412, "Teachers")]
        for x, label in actions:
            rounded(draw, (x, 1060, x + 176, 1168), 20, (255, 255, 255), NAVY_T, 3)
            text(draw, (x + 88, 1114), label, font(20, True), NAVY_T, "mm")

    return phone(os.path.join(UI, "home.png"), paint)


def screen_chat():
    def paint(draw, image):
        text(draw, (36, 118), "New Chat", font(34, True), NAVY_T)
        text(draw, (36, 176), "UniBot", font(22, True), GREEN_T)
        suggestions = ["Where is the library?", "Navigate to the cafe", "What is my attendance?"]
        y = 220
        for line in suggestions:
            tw = int(draw.textlength(line, font=font(20))) + 40
            rounded(draw, (28, y, 28 + tw, y + 52), 26, (255, 255, 255), (226, 231, 237))
            text(draw, (48, y + 12), line, font(20), NAVY_T)
            y += 66
        rounded(draw, (160, 450, 592, 530), 22, NAVY_T)
        text(draw, (184, 472), "Where is the library?", font(22), (255, 255, 255))
        rounded(draw, (28, 560, 560, 860), 24, (255, 255, 255), (226, 231, 237))
        text(draw, (52, 588), "Central Library", font(28, True), NAVY_T)
        text(draw, (52, 636), "Monday to Thursday, 8:30 AM to 8:00 PM.", font(18), (26, 35, 48))
        text(draw, (52, 668), "Friday, 8:30 AM to 5:00 PM.", font(18), (26, 35, 48))
        rounded(draw, (52, 730, 280, 800), 18, GREEN_T)
        text(draw, (166, 765), "Show on map", font(20, True), (255, 255, 255), "mm")
        rounded(draw, (28, 1140, 592, 1210), 28, (255, 255, 255), NAVY_T, 3)
        text(draw, (56, 1162), "Ask AICC…", font(22), (140, 150, 165))

    return phone(os.path.join(UI, "chat.png"), paint)


def screen_map():
    def paint(draw, image):
        text(draw, (36, 118), "Campus map", font(34, True), NAVY_T)
        site = Image.open(SITE).convert("RGB")
        site = site.resize((564, 620))
        image.paste(site, (28, 180))
        draw.ellipse((300, 430, 328, 458), fill=GREEN_T, outline=(255, 255, 255), width=4)
        rounded(draw, (28, 820, 592, 1040), 24, (255, 255, 255), (226, 231, 237))
        text(draw, (52, 848), "LGU Cafe", font(30, True), NAVY_T)
        text(draw, (52, 896), "On campus  ·  published walkway", font(20), (107, 118, 132))
        rounded(draw, (52, 948, 280, 1010), 18, NAVY_T)
        text(draw, (166, 979), "Directions", font(22, True), (255, 255, 255), "mm")
        text(draw, (36, 1070), "Main Gate  →  South walk  →  Cafe", font(22, True), NAVY_T)
        text(draw, (36, 1110), "End route", font(20), GREEN_T)

    return phone(os.path.join(UI, "map.png"), paint)


def screen_indoor():
    def paint(draw, image):
        text(draw, (36, 118), "Block B  ·  First", font(32, True), NAVY_T)
        floor = Image.open(FLOOR).convert("RGB")
        floor = floor.resize((564, 420))
        image.paste(floor, (28, 180))
        draw.line((120, 360, 300, 360, 300, 470, 470, 470), fill=(192, 57, 43), width=8)
        rounded(draw, (28, 630, 300, 700), 20, (255, 255, 255), NAVY_T, 3)
        text(draw, (164, 665), "Prefer stairs", font(22, True), NAVY_T, "mm")
        rounded(draw, (320, 630, 592, 700), 20, NAVY_T)
        text(draw, (456, 665), "Any connector", font(22, True), (255, 255, 255), "mm")
        steps = [
            "1   Start at the Block B entrance",
            "2   Walk the corridor",
            "3   Take the stairs to the first floor",
            "4   Arrive at Classroom B-104",
        ]
        y = 740
        for step in steps:
            rounded(draw, (28, y, 592, y + 88), 18, (255, 255, 255), (226, 231, 237))
            text(draw, (52, y + 28), step, font(22), (26, 35, 48))
            y += 104

    return phone(os.path.join(UI, "indoor.png"), paint)


def set_run(run, size, bold=False, color=INK, font_name="Calibri"):
    run.font.name = font_name
    run.font.size = Pt(size)
    run.font.bold = bold
    run.font.color.rgb = color


def add_text(slide, text_value, x, y, w, h, size=20, bold=False, color=INK, align=PP_ALIGN.LEFT, anchor=MSO_ANCHOR.TOP):
    shape = slide.shapes.add_textbox(Inches(x), Inches(y), Inches(w), Inches(h))
    frame = shape.text_frame
    frame.word_wrap = True
    frame.auto_size = None
    frame.margin_left = Emu(0)
    frame.margin_right = Emu(0)
    frame.margin_top = Emu(0)
    try:
        frame._txBody.bodyPr.set("anchor", {MSO_ANCHOR.TOP: "t", MSO_ANCHOR.MIDDLE: "ctr", MSO_ANCHOR.BOTTOM: "b"}[anchor])
    except Exception:
        pass
    paragraph = frame.paragraphs[0]
    paragraph.alignment = align
    run = paragraph.add_run()
    run.text = text_value
    set_run(run, size, bold, color)
    return shape


def add_bullets(slide, items, x, y, w, h, size=18, color=INK):
    shape = slide.shapes.add_textbox(Inches(x), Inches(y), Inches(w), Inches(h))
    frame = shape.text_frame
    frame.word_wrap = True
    for index, item in enumerate(items):
        paragraph = frame.paragraphs[0] if index == 0 else frame.add_paragraph()
        paragraph.alignment = PP_ALIGN.LEFT
        paragraph.level = 0
        paragraph.space_after = Pt(10)
        run = paragraph.add_run()
        run.text = "•  " + item
        set_run(run, size, False, color)
    return shape


def rect(slide, x, y, w, h, fill):
    shape = slide.shapes.add_shape(MSO_SHAPE.RECTANGLE, Inches(x), Inches(y), Inches(w), Inches(h))
    shape.fill.solid()
    shape.fill.fore_color.rgb = fill
    shape.line.fill.background()
    # remove shadow-less
    style = shape._element.find(qn("p:style"))
    if style is not None:
        shape._element.remove(style)
    return shape


def rrect(slide, x, y, w, h, fill):
    shape = slide.shapes.add_shape(MSO_SHAPE.ROUNDED_RECTANGLE, Inches(x), Inches(y), Inches(w), Inches(h))
    shape.fill.solid()
    shape.fill.fore_color.rgb = fill
    shape.line.fill.background()
    shape.adjustments[0] = 0.08
    return shape


def picture(slide, path, x, y, w=None, h=None):
    if w and h:
        return slide.shapes.add_picture(path, Inches(x), Inches(y), Inches(w), Inches(h))
    if w:
        return slide.shapes.add_picture(path, Inches(x), Inches(y), width=Inches(w))
    return slide.shapes.add_picture(path, Inches(x), Inches(y), height=Inches(h))


def chrome(slide, chapter, title, number):
    rect(slide, 0, 0, 13.333, 7.5, PAPER)
    rect(slide, 0, 0, 0.12, 7.5, NAVY)
    rect(slide, 0, 7.22, 13.333, 0.28, NAVY)
    add_text(slide, chapter.upper(), 0.4, 0.18, 9.5, 0.32, 13, True, GREEN)
    add_text(slide, title, 0.38, 0.44, 10.2, 0.5, 28, True, NAVY)
    add_text(slide, f"AICC   ·   Lahore Garrison University   ·   {number} / 20", 0.4, 7.22, 10, 0.28, 12, False, WHITE, anchor=MSO_ANCHOR.MIDDLE)
    return slide


def new_slide(prs):
    return prs.slides.add_slide(prs.slide_layouts[6])


def build():
    os.makedirs(UI, exist_ok=True)
    home = screen_home()
    chat = screen_chat()
    campus = screen_map()
    indoor = screen_indoor()

    prs = Presentation()
    prs.slide_width = W
    prs.slide_height = H
    prs.core_properties.title = "AICC Final Year Presentation"
    prs.core_properties.subject = "AI Campus Companion"
    prs.core_properties.author = "Abdul"

    # 1 Title
    slide = new_slide(prs)
    rect(slide, 0, 0, 13.333, 7.5, NAVY)
    rect(slide, 0, 0, 0.18, 7.5, GREEN)
    picture(slide, ICON, 0.55, 0.45, 1.15, 1.15)
    add_text(slide, "FINAL YEAR PROJECT", 1.9, 0.55, 8, 0.3, 14, True, GOLD)
    add_text(slide, "AICC", 1.85, 0.9, 8, 0.7, 54, True, WHITE)
    add_text(slide, "An AI Campus Companion for Academic Assistance\nand Campus Navigation", 1.9, 1.7, 8.2, 0.9, 22, False, WHITE)
    add_text(slide, "Department of Computer Science\nLahore Garrison University\nSession 2023–2026", 1.9, 2.85, 6, 1.2, 18, False, RGBColor(0xD5, 0xE4, 0xF2))
    add_text(slide, "Submitted by  Abdul\nSupervised by  ________________", 1.9, 4.3, 6, 0.8, 18, True, WHITE)
    add_text(slide, "Chapters 1–9 of the final documentation", 1.9, 6.5, 8, 0.35, 14, False, GOLD)

    # 2 Chapters
    slide = new_slide(prs)
    chrome(slide, "Contents", "Chapters of the documentation", 2)
    chapters = [
        ("01", "Introduction"),
        ("02", "Literature Review"),
        ("03", "Problem Definition"),
        ("04", "Software Requirement Specification"),
        ("05", "Methodology"),
        ("06", "Detailed Design and Architecture"),
        ("07", "Implementation and Testing"),
        ("08", "Results and Discussion"),
        ("09", "Conclusion and Future Work"),
    ]
    for index, (num, name) in enumerate(chapters):
        col = 0 if index < 5 else 1
        row = index if index < 5 else index - 5
        x = 0.45 + col * 6.4
        y = 1.25 + row * 1.05
        rrect(slide, x, y, 6.1, 0.9, WHITE)
        add_text(slide, num, x + 0.2, y + 0.18, 0.8, 0.55, 22, True, GREEN)
        add_text(slide, f"Chapter {int(num)}", x + 1.1, y + 0.1, 4.6, 0.3, 12, True, MUTED)
        add_text(slide, name, x + 1.1, y + 0.38, 4.7, 0.4, 18, True, NAVY)

    # 3 Chapter 1
    slide = new_slide(prs)
    chrome(slide, "Chapter 1  ·  Introduction", "What the companion is for", 3)
    cards = [
        ("Orientation", "A public map reaches the gate. It does not know the walk to the library or Classroom B-104."),
        ("Trustworthy answers", "A general chatbot can sound sure about a room, a fee, or a mark that was never stored."),
        ("One place to start", "Challans, rules, teachers, and routes should begin from the same signed-in companion."),
    ]
    for index, (title, body) in enumerate(cards):
        y = 1.25 + index * 1.75
        rrect(slide, 0.45, y, 8.3, 1.6, WHITE)
        add_text(slide, title, 0.7, y + 0.2, 7.8, 0.4, 22, True, NAVY)
        add_text(slide, body, 0.7, y + 0.7, 7.8, 0.7, 16, False, INK)
    rrect(slide, 9.0, 1.25, 3.9, 5.4, NAVY)
    add_text(slide, "AIM", 9.25, 1.5, 3.4, 0.3, 14, True, GOLD)
    add_text(slide, "Answer from maintained data, show the place when one exists, and walk the university’s own paths.", 9.25, 2.05, 3.4, 2.2, 18, False, WHITE)
    add_text(slide, "Place lookup and personal records keep working when the language model is down.", 9.25, 4.4, 3.4, 1.8, 16, False, RGBColor(0xD5, 0xE4, 0xF2))

    # 4 Chapter 1 objectives
    slide = new_slide(prs)
    chrome(slide, "Chapter 1  ·  Introduction", "Objectives and scope", 4)
    add_bullets(
        slide,
        [
            "Show CGPA, courses, attendance, fee challans, and roll slips from the student record.",
            "Resolve a place from the maintained list, including aliases, before any model is called.",
            "Answer handbook questions only after passages are retrieved.",
            "Refuse what the handbook does not contain. Never invent a mark or a coordinate.",
            "Route outdoors with Dijkstra, and hand city roads to Google Maps.",
            "Route indoors with A*, including stairs and the lift, from a QR code or a chosen start.",
            "Let an administrator edit people, places, and indoor areas without an application update.",
        ],
        0.5,
        1.25,
        8.2,
        5.6,
        18,
    )
    rrect(slide, 8.9, 1.3, 4.0, 5.3, WHITE)
    add_text(slide, "Outside this delivery", 9.1, 1.5, 3.6, 0.4, 16, True, NAVY)
    add_bullets(
        slide,
        [
            "Live bus tracking",
            "Hostel booking",
            "Course registration itself",
            "A surveyed GPS-error log",
            "Official architectural sheets",
        ],
        9.1,
        2.1,
        3.6,
        4.0,
        16,
    )

    # 5 Chapter 2
    slide = new_slide(prs)
    chrome(slide, "Chapter 2  ·  Literature Review", "What was adopted, and what was not", 5)
    rows = [
        ("Retrieval-augmented generation", "Lewis et al.  Phrase a rule only after the passage is retrieved."),
        ("BM25 and embeddings", "Robertson and Zaragoza. Rank the handbook. Do not search the open web."),
        ("Dijkstra", "Non-negative walkway costs. The right search for the outdoor graph."),
        ("A*", "Hart, Nilsson, and Raphael. Straight-line distance is a safe indoor heuristic."),
        ("Indoor positioning surveys", "Radio maps work, and they need a survey. GPS indoors was rejected."),
        ("QR at a door or stair", "A start the student can see. Not a fingerprint of the corridor."),
    ]
    for index, (title, body) in enumerate(rows):
        col = index % 2
        row = index // 2
        x = 0.4 + col * 6.45
        y = 1.25 + row * 1.85
        rrect(slide, x, y, 6.2, 1.7, WHITE)
        add_text(slide, title, x + 0.25, y + 0.2, 5.7, 0.45, 18, True, NAVY)
        add_text(slide, body, x + 0.25, y + 0.75, 5.7, 0.75, 15, False, INK)

    # 6 Chapter 3
    slide = new_slide(prs)
    chrome(slide, "Chapter 3  ·  Problem Definition", "The gap this system closes", 6)
    add_text(
        slide,
        "A student who needs a place, a rule, or a document must assemble the answer from sources that do not know about each other.",
        0.5,
        1.2,
        12.3,
        0.8,
        20,
        False,
        INK,
    )
    gaps = [
        ("No shared place", "A sentence and a map pin are not the same record."),
        ("No guard on the model", "Nothing stops a fluent sentence from containing a CGPA."),
        ("No campus graph", "Internal walkways, stairs, and lifts are unpublished."),
        ("No edit path", "A changed hour should not require a new application build."),
    ]
    for index, (title, body) in enumerate(gaps):
        x = 0.4 + (index % 4) * 3.2
        rrect(slide, x, 2.3, 3.05, 2.5, WHITE)
        add_text(slide, f"0{index + 1}", x + 0.2, 2.45, 2.6, 0.4, 20, True, GREEN)
        add_text(slide, title, x + 0.2, 2.95, 2.7, 0.7, 18, True, NAVY)
        add_text(slide, body, x + 0.2, 3.7, 2.7, 0.9, 14, False, INK)
    add_text(slide, "Success means a stored card, a stored rule, a path on authored edges, and a refusal when nothing is stored.", 0.5, 5.1, 12.3, 0.7, 18, True, NAVY)
    add_text(slide, "A blank GPS-error cell is not treated as a pass.", 0.5, 5.8, 12, 0.4, 16, False, MUTED)

    # 7 Chapter 4 requirements
    slide = new_slide(prs)
    chrome(slide, "Chapter 4  ·  Software Requirement Specification", "Users and the requirements that matter", 7)
    rrect(slide, 0.4, 1.25, 6.2, 2.3, WHITE)
    add_text(slide, "Student", 0.65, 1.4, 5.7, 0.4, 22, True, NAVY)
    add_text(slide, "Reads their own record, asks questions, follows routes, and opens notices. Cannot publish a place or see the model key.", 0.65, 1.95, 5.7, 1.3, 16, False, INK)
    rrect(slide, 6.8, 1.25, 6.1, 2.3, WHITE)
    add_text(slide, "Administrator", 7.05, 1.4, 5.6, 0.4, 22, True, NAVY)
    add_text(slide, "Maintains students, teachers, places, indoor areas, and broadcasts. Signs into a separate shell.", 7.05, 1.95, 5.6, 1.3, 16, False, INK)
    add_text(slide, "Functional highlights", 0.45, 3.75, 6, 0.35, 16, True, GREEN)
    add_bullets(
        slide,
        [
            "FR-06  Place match prefers the longer name.",
            "FR-08  Open questions go to the handbook first.",
            "FR-15  On-campus route uses the published graph.",
            "FR-19  Indoor route can change floor by stairs or lift.",
        ],
        0.45,
        4.15,
        6.2,
        2.6,
        16,
    )
    add_text(slide, "Qualities", 7.0, 3.75, 5, 0.35, 16, True, GREEN)
    add_bullets(
        slide,
        [
            "NFR-01  Facts come from a store, not from model text.",
            "NFR-02  The Groq key stays on the server.",
            "NFR-10  A missing length is marked estimated.",
        ],
        7.0,
        4.15,
        5.8,
        2.4,
        16,
    )

    # 8 Chapter 4 use case
    slide = new_slide(prs)
    chrome(slide, "Chapter 4  ·  Software Requirement Specification", "Use cases", 8)
    picture(slide, os.path.join(FIG, "fig_6_1_usecase.png"), 0.3, 1.15, 8.3, 5.8)
    add_bullets(
        slide,
        [
            "UC-04  Ask where a place is.",
            "UC-05  Ask a handbook rule.",
            "UC-08  Walk on campus, or hand off outside it.",
            "UC-09  Walk inside Block B.",
            "UC-13  An administrator publishes a place.",
        ],
        8.7,
        1.4,
        4.3,
        4.5,
        16,
    )

    # 9 Chapter 5 method
    slide = new_slide(prs)
    chrome(slide, "Chapter 5  ·  Methodology", "Lookup before generation", 9)
    steps = [
        ("1", "Normalise", "Trim, lowercase, and collapse spaces."),
        ("2", "Classify", "Greeting, document, academics, faculty, or place."),
        ("3", "Match a place", "Aliases and the longer name win on the phone."),
        ("4", "Retrieve", "BM25 plus embeddings over the handbook."),
        ("5", "Phrase", "Groq may speak only the retrieved passages."),
        ("6", "Attach a card", "Only if that passage already has a place id."),
    ]
    for index, (num, title, body) in enumerate(steps):
        col = index % 3
        row = index // 3
        x = 0.4 + col * 4.25
        y = 1.3 + row * 2.7
        rrect(slide, x, y, 4.05, 2.45, WHITE)
        add_text(slide, num, x + 0.25, y + 0.25, 1, 0.5, 28, True, GREEN)
        add_text(slide, title, x + 0.25, y + 0.9, 3.5, 0.4, 20, True, NAVY)
        add_text(slide, body, x + 0.25, y + 1.4, 3.5, 0.8, 15, False, INK)

    # 10 Chapter 5 routing
    slide = new_slide(prs)
    chrome(slide, "Chapter 5  ·  Methodology", "Two graphs, two searches", 10)
    rrect(slide, 0.4, 1.25, 6.2, 5.5, WHITE)
    add_text(slide, "Outdoors  ·  Dijkstra", 0.65, 1.45, 5.7, 0.4, 22, True, NAVY)
    add_bullets(
        slide,
        [
            "Published nodes and walkways only.",
            "Missing length uses 25 metres and marks the route estimated.",
            "No straight line across buildings.",
            "Outside the campus outline, open Google Maps toward a gate.",
        ],
        0.65,
        2.05,
        5.7,
        2.4,
        16,
    )
    add_text(slide, "Indoors  ·  A*", 0.65, 4.4, 5.7, 0.35, 22, True, NAVY)
    add_text(slide, "Stairs 12 per floor. Lift 8. Preferring stairs adds 40 to each lift. A zero heuristic is Dijkstra, kept for tests.", 0.65, 4.95, 5.7, 1.4, 16, False, INK)
    picture(slide, os.path.join(FIG, "fig_6_7_state.png"), 6.8, 1.35, 6.2, 3.0)
    add_text(slide, "A route session moves from Idle to Locating, Routing, On route, and Arrived. Leaving the path recalculates.", 6.85, 4.5, 6.0, 1.5, 16, False, INK)

    # 11 Chapter 6 architecture
    slide = new_slide(prs)
    chrome(slide, "Chapter 6  ·  Detailed Design and Architecture", "System architecture", 11)
    picture(slide, os.path.join(FIG, "fig_6_3_architecture.png"), 0.35, 1.15, 8.6, 5.6)
    add_bullets(
        slide,
        [
            "The phone decides the tap, the place, and the path.",
            "The service decides which passage may be spoken.",
            "The stores decide what is true.",
            "The model is not a store.",
            "The key never ships inside the application.",
        ],
        9.1,
        1.4,
        3.9,
        5.2,
        16,
    )

    # 12 Chapter 6 behaviour
    slide = new_slide(prs)
    chrome(slide, "Chapter 6  ·  Detailed Design and Architecture", "One question, then a route", 12)
    picture(slide, os.path.join(FIG, "fig_6_4_activity.png"), 0.25, 1.15, 4.3, 5.85)
    picture(slide, os.path.join(FIG, "fig_6_5_sequence.png"), 4.6, 1.35, 8.4, 4.85)
    add_text(slide, "Activity of a question, and the sequence when “library” is a place and the next turn asks for hours.", 4.7, 6.3, 8.2, 0.6, 14, False, MUTED)

    # 13 Chapter 6 data
    slide = new_slide(prs)
    chrome(slide, "Chapter 6  ·  Detailed Design and Architecture", "Records and the navigation model", 13)
    picture(slide, os.path.join(FIG, "fig_6_10_database.png"), 0.3, 1.2, 6.5, 4.0)
    picture(slide, os.path.join(FIG, "fig_6_8_class.png"), 6.8, 1.2, 6.2, 3.8)
    add_text(slide, "Mobile Firebase holds accounts, chat, faculty, and activity. The campus service holds students, places, the walkway graph, and indoor maps. The handbook is a file, not a student-writable collection.", 0.45, 5.4, 12.4, 1.4, 16, False, INK)

    # 14 Chapter 7 home UI
    slide = new_slide(prs)
    chrome(slide, "Chapter 7  ·  Implementation and Testing", "Student home", 14)
    picture(slide, home, 0.45, 1.2, 2.85, 5.85)
    add_text(slide, "The signed-in home", 3.6, 1.3, 9, 0.45, 26, True, NAVY)
    add_bullets(
        slide,
        [
            "Welcome card uses the stored name and registration number.",
            "CGPA is the value on the student row. It is not recalculated.",
            "Attendance is the average of this semester’s courses.",
            "Quick actions open chat, documents, and teachers.",
            "The drawer also reaches history, notices, and indoor navigation.",
            "Loading, empty, and error states replace a blank screen.",
        ],
        3.6,
        2.0,
        9.2,
        4.5,
        18,
    )

    # 15 Chapter 7 chat UI
    slide = new_slide(prs)
    chrome(slide, "Chapter 7  ·  Implementation and Testing", "UniBot", 15)
    picture(slide, chat, 0.4, 1.2, 2.85, 5.85)
    add_text(slide, "A place is a card, not a guess", 3.55, 1.3, 9.2, 0.45, 26, True, NAVY)
    add_bullets(
        slide,
        [
            "“Where is the library?” matches Central Library on the phone.",
            "Hours are a handbook answer. The card is attached because the passage is tagged.",
            "“Who won the cricket world cup?” is refused. No place card.",
            "Voice is transcribed on the server, then run through the same classifier.",
            "The reply can be spoken. The model key stays on the server.",
            "History can replay or delete a session.",
        ],
        3.55,
        2.0,
        9.3,
        4.6,
        18,
    )

    # 16 Chapter 7 maps
    slide = new_slide(prs)
    chrome(slide, "Chapter 7  ·  Implementation and Testing", "Campus map and indoor floor", 16)
    picture(slide, campus, 0.35, 1.2, 2.7, 5.55)
    picture(slide, indoor, 3.2, 1.2, 2.7, 5.55)
    add_bullets(
        slide,
        [
            "The outdoor line is the Dijkstra node list.",
            "The site drawing under the pin is the packaged campus plan.",
            "Block B shows the first-floor drawing and the step list.",
            "Prefer stairs changes a cost. It does not delete the lift.",
            "A QR code can set the start when GPS is on the wrong side of a wall.",
        ],
        6.15,
        1.4,
        6.8,
        5.2,
        16,
    )

    # 17 Chapter 8 chatbot results
    slide = new_slide(prs)
    chrome(slide, "Chapter 8  ·  Results and Discussion", "Chatbot checks", 17)
    checks = [
        ("LGU", "Main campus card"),
        ("Where is LGU cafe", "Longer name wins"),
        ("Navigate to canteen", "Cafe alias"),
        ("Library kahan hai", "Central Library"),
        ("Where can I eat lunch?", "Text plus the cafe card"),
        ("When does the library open?", "Hours, not a route"),
        ("Who won the cricket world cup?", "Refusal, no card"),
        ("Admin drops a pin", "Visible after save"),
    ]
    for index, (prompt, result) in enumerate(checks):
        col = index % 2
        row = index // 2
        x = 0.4 + col * 6.45
        y = 1.25 + row * 1.4
        rrect(slide, x, y, 6.25, 1.25, WHITE)
        add_text(slide, prompt, x + 0.25, y + 0.18, 5.8, 0.4, 18, True, NAVY)
        add_text(slide, result, x + 0.25, y + 0.65, 5.8, 0.4, 16, False, INK)

    # 18 Chapter 8 navigation
    slide = new_slide(prs)
    chrome(slide, "Chapter 8  ·  Results and Discussion", "Navigation checks, stated honestly", 18)
    picture(slide, os.path.join(FIG, "fig_6_9_dfd.png"), 0.3, 1.2, 6.4, 3.7)
    add_bullets(
        slide,
        [
            "Main Gate to the cafe, the library, and the fountain follow the published graph.",
            "Classroom B-104 continues indoors by stairs or lift.",
            "Off campus, a public walking link opens toward a gate.",
            "GPS error was not surveyed. The field log stays blank.",
            "Floor art is a Block B sketch. The graph is what the router trusts.",
        ],
        6.9,
        1.3,
        6.0,
        4.4,
        16,
    )
    add_text(slide, "Say “this is the published path.” Do not say “this is a surveyed distance.”", 0.45, 5.3, 12.4, 0.7, 18, True, NAVY)

    # 19 Chapter 9 conclusion
    slide = new_slide(prs)
    chrome(slide, "Chapter 9  ·  Conclusion and Future Work", "What was delivered", 19)
    done = [
        ("Records", "Personal numbers are read, not generated."),
        ("Places", "Aliases resolve to one stored pin."),
        ("Rules", "Retrieved, then phrased, or refused."),
        ("Outdoors", "Dijkstra inside the gate. Public map outside it."),
        ("Indoors", "A* with an explicit stair and lift cost."),
        ("Administration", "People, notices, and places change without a rebuild."),
    ]
    for index, (title, body) in enumerate(done):
        col = index % 3
        row = index // 3
        x = 0.4 + col * 4.25
        y = 1.3 + row * 2.6
        rrect(slide, x, y, 4.05, 2.35, WHITE)
        add_text(slide, title, x + 0.25, y + 0.3, 3.5, 0.5, 22, True, NAVY)
        add_text(slide, body, x + 0.25, y + 1.05, 3.5, 0.9, 16, False, INK)

    # 20 Future and close
    slide = new_slide(prs)
    rect(slide, 0, 0, 13.333, 7.5, NAVY)
    rect(slide, 0, 0, 0.18, 7.5, GREEN)
    add_text(slide, "CHAPTER 9  ·  CONCLUSION AND FUTURE WORK", 0.55, 0.35, 12, 0.35, 14, True, GOLD)
    add_text(slide, "What should happen next", 0.5, 0.75, 12, 0.55, 32, True, WHITE)
    future = [
        "Survey the walkways and fill the GPS-error log.",
        "Replace the Block B sketch with cleared floor drawings.",
        "Add buildings on the same graph contract.",
        "Review handbook passages with the offices they describe.",
        "Keep places as lookups and routes as authored edges.",
    ]
    add_bullets(slide, future, 0.55, 1.6, 8.2, 4.2, 20, WHITE)
    add_text(slide, "Thank you", 9.1, 2.3, 3.8, 0.7, 36, True, WHITE)
    add_text(slide, "Questions", 9.1, 3.1, 3.8, 0.5, 22, False, GOLD)
    add_text(slide, "AICC  ·  20 / 20", 0.55, 6.85, 6, 0.35, 14, False, RGBColor(0xD5, 0xE4, 0xF2))

    prs.save(OUT)
    print(OUT)
    print("slides", len(prs.slides))


if __name__ == "__main__":
    build()
