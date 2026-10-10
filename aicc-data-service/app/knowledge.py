"""Campus policies the assistant is allowed to use. Keep these aligned with
aicc/lib/chat/knowledge_base.dart so offline answers match the assistant."""

POLICIES = (
    "You need at least 75% attendance in a course to sit its final exam. The dashboard shows the average for the current semester, and the assistant can break it down course by course.",
    "CGPA is the average of grade points across completed courses, on a 4.0 scale. AICC shows the overall CGPA stored in the university record. It is not recalculated inside the app.",
    "Fee challans are issued each semester. The student can open a challan from Notifications or ask for their fee challan. They should pay it before the date printed on the challan to avoid a late fine.",
    "A roll number slip is issued when the exam office marks it ready. The student needs it to enter the exam hall. The assistant can open it when the document status is ready.",
    "The central library is open Monday to Thursday, 8:30 AM to 8:00 PM, and Friday, 8:30 AM to 5:00 PM. It is closed on Saturday and Sunday.",
    "A course can be withdrawn before the deadline on the academic calendar, usually the end of the fourth teaching week. After that, the course stays on the transcript.",
    "Each teacher has consultation hours on their profile in Teacher Tracking. Students should go during those hours, or ask where a teacher is right now.",
    "Students must bring a student card and roll number slip to every exam. Phones stay outside the hall. Unfair means can lead to an F grade in that course.",
    "Students must carry a student ID on campus. A lost card is replaced at the Admin Block student desk, and a fee challan is issued for the replacement.",
    "Hostel rooms are allocated by the Admin Block. The student desk has the current form and deadline. AICC does not manage hostel bookings.",
    "Course registration opens before each semester. The registration number is the ID on the university record, for example FA26-BSCS-001. AICC uses that number to sign the student in.",
    "A CGPA below 2.00 places a student on academic warning. The department office explains the courses to repeat. The dashboard shows the stored CGPA.",
)


def knowledge_text() -> str:
    return "\n".join(f"- {policy}" for policy in POLICIES)
