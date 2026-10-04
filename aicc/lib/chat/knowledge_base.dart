class KnowledgeEntry {
  const KnowledgeEntry(this.keywords, this.answer);

  final List<String> keywords;
  final String answer;
}

const knowledgeBase = <KnowledgeEntry>[
  KnowledgeEntry(
    ['attendance policy', 'minimum attendance', 'attendance required', '75'],
    'You need at least 75% attendance in a course to sit its final exam. The dashboard shows your average for the current semester, and the assistant can break it down course by course.',
  ),
  KnowledgeEntry(
    ['cgpa', 'gpa calculated', 'grade point', 'how is cgpa'],
    'CGPA is the average of your grade points across completed courses, on a 4.0 scale. AICC shows the overall CGPA stored in your university record. It is not recalculated inside the app.',
  ),
  KnowledgeEntry(
    ['fee deadline', 'pay fee', 'fee payment', 'challan due', 'when is the fee'],
    'Fee challans are issued each semester. Open the challan from Notifications or ask me for your fee challan. Pay it before the date printed on the challan to avoid a late fine.',
  ),
  KnowledgeEntry(
    ['roll number slip', 'admit card', 'exam slip policy'],
    'Your roll number slip is issued when the exam office marks it ready. You need it to enter the exam hall. I can open it when the document status is ready.',
  ),
  KnowledgeEntry(
    ['library hours', 'library timing', 'library open'],
    'The central library is open Monday to Thursday, 8:30 AM to 8:00 PM, and Friday, 8:30 AM to 5:00 PM. It is closed on Saturday and Sunday.',
  ),
  KnowledgeEntry(
    ['withdraw', 'drop a course', 'course withdrawal'],
    'A course can be withdrawn before the deadline on the academic calendar, usually the end of the fourth teaching week. After that, the course stays on your transcript.',
  ),
  KnowledgeEntry(
    ['office hours', 'consultation policy', 'meet a teacher'],
    'Each teacher has consultation hours posted on their profile in Teacher Tracking. Go during those hours, or ask me where a teacher is right now.',
  ),
  KnowledgeEntry(
    ['exam rules', 'exam hall', 'unfair means'],
    'Bring your student card and roll number slip to every exam. Phones stay outside the hall. Unfair means can lead to an F grade in that course.',
  ),
  KnowledgeEntry(
    ['student id', 'id card', 'lost card'],
    'Carry your student ID on campus. If it is lost, request a replacement from the Admin Block student desk. A fee challan is issued for the replacement.',
  ),
  KnowledgeEntry(
    ['hostel', 'accommodation', 'dorm'],
    'Hostel rooms are allocated by the Admin Block. Ask the student desk for the current form and deadline. AICC does not manage hostel bookings.',
  ),
  KnowledgeEntry(
    ['registration', 'add a course', 'enroll'],
    'Course registration opens before each semester. Your registration number is the ID on your university record, for example FA26-BSCS-001. AICC uses that number to sign you in.',
  ),
  KnowledgeEntry(
    ['probation', 'warning', 'low cgpa'],
    'A CGPA below 2.00 places a student on academic warning. The department office explains the courses you need to repeat. Check your dashboard CGPA if you are unsure.',
  ),
];

String? matchKnowledge(String text) {
  String? best;
  var bestScore = 0;
  for (final entry in knowledgeBase) {
    var score = 0;
    for (final keyword in entry.keywords) {
      if (text.contains(keyword)) score += keyword.length;
    }
    if (score > bestScore) {
      bestScore = score;
      best = entry.answer;
    }
  }
  if (bestScore < 6) return null;
  return best;
}
