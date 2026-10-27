"""Request and response shapes for students, courses, notices, documents, and places."""

from typing import Literal

from pydantic import BaseModel, Field, model_validator

from app.academics import DEPARTMENT_CODES, SECTIONS

DepartmentCode = Literal[DEPARTMENT_CODES[0], DEPARTMENT_CODES[1], DEPARTMENT_CODES[2]]
Section = Literal["A", "B"]


class StudentIn(BaseModel):
    name: str = Field(min_length=1)
    registrationNumber: str = Field(min_length=1)
    department: DepartmentCode
    semester: int = Field(ge=1, le=4)
    section: Section
    cgpaOverall: float = Field(ge=0.0, le=4.0)

    @model_validator(mode="after")
    def registration_matches_department(self):
        parts = self.registrationNumber.split("-")
        if len(parts) != 3:
            raise ValueError(
                "registrationNumber must look like FA26-BSCS-014"
            )
        dept_in_reg = parts[1]
        if dept_in_reg != self.department:
            raise ValueError(
                f"registrationNumber has {dept_in_reg} but department is {self.department}"
            )
        if self.section not in SECTIONS:
            raise ValueError(f"section must be one of {SECTIONS}")
        return self


class StudentOut(StudentIn):
    id: str


class StudentUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=1)
    registrationNumber: str | None = Field(default=None, min_length=1)
    department: DepartmentCode | None = None
    semester: int | None = Field(default=None, ge=1, le=4)
    section: Section | None = None
    cgpaOverall: float | None = Field(default=None, ge=0.0, le=4.0)


NotificationType = Literal[
    "fee_challan_ready", "roll_slip_ready", "sign_in", "other"
]
DocType = Literal["fee_challan", "roll_number_slip"]
DocStatus = Literal["pending", "ready"]


class CourseIn(BaseModel):
    courseName: str = Field(min_length=1)
    courseCode: str = Field(min_length=1)
    attendancePercent: float = Field(ge=0.0, le=100.0)
    semester: int = Field(ge=1, le=4)


class CourseOut(CourseIn):
    id: str


class NotificationIn(BaseModel):
    type: NotificationType
    message: str = Field(min_length=1)
    read: bool = False


class NotificationOut(BaseModel):
    id: str
    type: NotificationType
    message: str
    timestamp: str
    read: bool


class NotificationUpdate(BaseModel):
    read: bool


class DocumentIn(BaseModel):
    docType: DocType
    status: DocStatus = "pending"
    fileUrl: str | None = None


class DocumentOut(DocumentIn):
    id: str


class DocumentUpdate(BaseModel):
    docType: DocType | None = None
    status: DocStatus | None = None
    fileUrl: str | None = None


class Entrance(BaseModel):
    lat: float = Field(ge=-90, le=90)
    lng: float = Field(ge=-180, le=180)


class PlaceIn(BaseModel):
    id: str = Field(min_length=1, max_length=80, pattern=r"^[a-z0-9][a-z0-9-]*$")
    name: str = Field(min_length=1, max_length=80)
    aliases: list[str] = Field(default_factory=list, max_length=20)
    category: str = Field(min_length=1, max_length=40)
    lat: float = Field(ge=-90, le=90)
    lng: float = Field(ge=-180, le=180)
    entrance: Entrance | None = None
    building: str = ""
    floor: str = ""
    hours: str = ""
    description: str = ""
    photoUrl: str = ""
    nodeId: str = ""
    isActive: bool = True


class PlaceUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=1, max_length=80)
    aliases: list[str] | None = None
    category: str | None = None
    lat: float | None = Field(default=None, ge=-90, le=90)
    lng: float | None = Field(default=None, ge=-180, le=180)
    entrance: Entrance | None = None
    building: str | None = None
    floor: str | None = None
    hours: str | None = None
    description: str | None = None
    photoUrl: str | None = None
    nodeId: str | None = None
    isActive: bool | None = None
