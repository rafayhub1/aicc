"""Department list, cohort rules, and the course template for each department and semester."""

from typing import TypedDict

class Department(TypedDict):
    code: str
    name: str


DEPARTMENTS: list[Department] = [
    {"code": "BSPSY", "name": "BS Psychology"},
    {"code": "BSCS", "name": "BS Computer Science"},
    {"code": "BBA", "name": "Bachelor of Business Administration"},
]

DEPARTMENT_CODES: tuple[str, ...] = tuple(d["code"] for d in DEPARTMENTS)
SEMESTERS: list[int] = [1, 2, 3, 4]
SECTIONS: list[str] = ["A", "B"]

INTAKE_BY_SEMESTER: dict[int, str] = {
    1: "FA26",
    2: "SP26",
    3: "FA25",
    4: "SP25",
}


def all_cohorts() -> list[dict[str, str | int]]:
    return [
        {"department": dept["code"], "semester": semester, "section": section}
        for dept in DEPARTMENTS
        for semester in SEMESTERS
        for section in SECTIONS
    ]


class CourseTemplate(TypedDict):
    courseCode: str
    courseName: str


# Five courses per (department, semester) — used by seed script and future tooling.
COURSE_CATALOG: dict[tuple[str, int], list[CourseTemplate]] = {
    ("BSCS", 1): [
        {"courseCode": "CSC101", "courseName": "Programming Fundamentals"},
        {"courseCode": "MTH104", "courseName": "Calculus and Analytical Geometry"},
        {"courseCode": "ENG101", "courseName": "English Composition"},
        {"courseCode": "PHY101", "courseName": "Applied Physics"},
        {"courseCode": "HUM111", "courseName": "Islamic Studies"},
    ],
    ("BSCS", 2): [
        {"courseCode": "CSC201", "courseName": "Object Oriented Programming"},
        {"courseCode": "CSC202", "courseName": "Digital Logic Design"},
        {"courseCode": "MTH204", "courseName": "Linear Algebra"},
        {"courseCode": "STA201", "courseName": "Statistics and Probability"},
        {"courseCode": "ENG201", "courseName": "Technical Writing"},
    ],
    ("BSCS", 3): [
        {"courseCode": "CSC301", "courseName": "Data Structures and Algorithms"},
        {"courseCode": "CSC302", "courseName": "Database Systems"},
        {"courseCode": "CSC303", "courseName": "Computer Networks"},
        {"courseCode": "CSC304", "courseName": "Operating Systems"},
        {"courseCode": "MTH301", "courseName": "Discrete Mathematics"},
    ],
    ("BSCS", 4): [
        {"courseCode": "CSC401", "courseName": "Software Engineering"},
        {"courseCode": "CSC402", "courseName": "Artificial Intelligence"},
        {"courseCode": "CSC403", "courseName": "Web Technologies"},
        {"courseCode": "CSC404", "courseName": "Final Year Project I"},
        {"courseCode": "CSC405", "courseName": "Information Security"},
    ],
    ("BBA", 1): [
        {"courseCode": "BBA101", "courseName": "Introduction to Business"},
        {"courseCode": "ACC101", "courseName": "Financial Accounting"},
        {"courseCode": "ECO101", "courseName": "Microeconomics"},
        {"courseCode": "ENG101", "courseName": "English Composition"},
        {"courseCode": "MTH101", "courseName": "Business Mathematics"},
    ],
    ("BBA", 2): [
        {"courseCode": "BBA201", "courseName": "Organizational Behavior"},
        {"courseCode": "ACC201", "courseName": "Managerial Accounting"},
        {"courseCode": "ECO201", "courseName": "Macroeconomics"},
        {"courseCode": "MKT201", "courseName": "Principles of Marketing"},
        {"courseCode": "STA201", "courseName": "Business Statistics"},
    ],
    ("BBA", 3): [
        {"courseCode": "BBA301", "courseName": "Human Resource Management"},
        {"courseCode": "FIN301", "courseName": "Corporate Finance"},
        {"courseCode": "MKT301", "courseName": "Consumer Behavior"},
        {"courseCode": "BBA302", "courseName": "Business Law"},
        {"courseCode": "BBA303", "courseName": "Operations Management"},
    ],
    ("BBA", 4): [
        {"courseCode": "BBA401", "courseName": "Strategic Management"},
        {"courseCode": "BBA402", "courseName": "Entrepreneurship"},
        {"courseCode": "BBA403", "courseName": "International Business"},
        {"courseCode": "BBA404", "courseName": "Business Research Methods"},
        {"courseCode": "BBA405", "courseName": "Final Year Project"},
    ],
    ("BSPSY", 1): [
        {"courseCode": "PSY101", "courseName": "Introduction to Psychology"},
        {"courseCode": "PSY102", "courseName": "General Psychology"},
        {"courseCode": "ENG101", "courseName": "English Composition"},
        {"courseCode": "BIO101", "courseName": "Biological Basis of Behavior"},
        {"courseCode": "STA101", "courseName": "Statistics for Psychology"},
    ],
    ("BSPSY", 2): [
        {"courseCode": "PSY201", "courseName": "Developmental Psychology"},
        {"courseCode": "PSY202", "courseName": "Social Psychology"},
        {"courseCode": "PSY203", "courseName": "Research Methods in Psychology"},
        {"courseCode": "PSY204", "courseName": "Cognitive Psychology"},
        {"courseCode": "PSY205", "courseName": "Psychological Testing"},
    ],
    ("BSPSY", 3): [
        {"courseCode": "PSY301", "courseName": "Abnormal Psychology"},
        {"courseCode": "PSY302", "courseName": "Clinical Psychology"},
        {"courseCode": "PSY303", "courseName": "Counseling Psychology"},
        {"courseCode": "PSY304", "courseName": "Neuropsychology"},
        {"courseCode": "PSY305", "courseName": "Health Psychology"},
    ],
    ("BSPSY", 4): [
        {"courseCode": "PSY401", "courseName": "Industrial Psychology"},
        {"courseCode": "PSY402", "courseName": "Forensic Psychology"},
        {"courseCode": "PSY403", "courseName": "Community Psychology"},
        {"courseCode": "PSY404", "courseName": "Psychology Internship"},
        {"courseCode": "PSY405", "courseName": "Final Year Research Project"},
    ],
}


def courses_for_department_semester(department: str, semester: int) -> list[CourseTemplate]:
    return COURSE_CATALOG[(department, semester)]
