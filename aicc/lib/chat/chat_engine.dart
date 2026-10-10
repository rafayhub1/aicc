import '../core/academics.dart';
import '../core/formatters.dart';
import '../models/chat_message.dart';
import '../models/faculty.dart';
import '../models/student.dart';
import '../models/student_document.dart';
import '../services/api_service.dart';
import '../services/faculty_search.dart';
import 'intent.dart';
import 'knowledge_base.dart';

class ChatAction {
  const ChatAction({required this.label, required this.url});

  final String label;
  final String url;
}

class ChatReply {
  const ChatReply(this.text, {this.action});

  final String text;
  final ChatAction? action;
}

class ChatEngine {
  ChatEngine({required this.api, required this.facultyLoader});

  final ApiService api;
  final Future<List<Faculty>> Function() facultyLoader;

  Future<ChatReply> respond({
    required String text,
    required Student? student,
    List<ChatMessage> history = const [],
  }) async {
    final intent = classifyIntent(text);
    switch (intent.kind) {
      case ChatIntentKind.greeting:
        final name = student == null ? 'there' : firstName(student.name);
        return ChatReply(
          'Hello $name. I can open your fee challan or roll number slip, check attendance, and look up a teacher.',
        );
      case ChatIntentKind.faq:
      case ChatIntentKind.unknown:
        return _groundedReply(text, intent, history);
      case ChatIntentKind.feeChallan:
        return _documentReply(
          student: student,
          docType: 'fee_challan',
          readyLabel: 'View fee challan',
          noun: 'fee challan',
        );
      case ChatIntentKind.rollSlip:
        return _documentReply(
          student: student,
          docType: 'roll_number_slip',
          readyLabel: 'View roll number slip',
          noun: 'roll number slip',
        );
      case ChatIntentKind.academics:
        return _academicsReply(text, student);
      case ChatIntentKind.faculty:
        return _facultyReply(text);
    }
  }

  Future<ChatReply> _groundedReply(
    String text,
    ClassifiedIntent intent,
    List<ChatMessage> history,
  ) async {
    try {
      final turns = <({String role, String content})>[
        for (final message in history)
          if (message.content.trim().isNotEmpty)
            (role: message.role, content: message.content),
      ];
      final answer = await api.askAssistant(text, turns);
      if (answer.trim().isNotEmpty) return ChatReply(answer.trim());
    } catch (_) {}
    if (intent.faqAnswer != null) return ChatReply(intent.faqAnswer!);
    final local = matchKnowledge(text.toLowerCase());
    if (local != null) return ChatReply(local);
    return const ChatReply(_fallback);
  }

  Future<ChatReply> _documentReply({
    required Student? student,
    required String docType,
    required String readyLabel,
    required String noun,
  }) async {
    if (student == null) {
      return const ChatReply(
        'Sign in with a university registration number so I can look up your documents.',
      );
    }
    final documents = await api.getDocuments(student.id);
    StudentDocument? match;
    for (final document in documents) {
      if (document.docType == docType) {
        match = document;
        break;
      }
    }
    if (match == null) {
      return ChatReply('I could not find a $noun on your record yet.');
    }
    if (!match.isReady) {
      return ChatReply(
        'Your $noun is still pending. I will be able to open it once the office marks it ready.',
      );
    }
    return ChatReply(
      'Your $noun is ready.',
      action: ChatAction(
        label: readyLabel,
        url: match.resolvedUrl(api.baseUrl, student.id),
      ),
    );
  }

  Future<ChatReply> _academicsReply(String text, Student? student) async {
    if (student == null) {
      return const ChatReply(
        'Sign in so I can read your courses and attendance.',
      );
    }
    final courses = await api.getCourses(student.id);
    final current = coursesForSemester(courses, student.semester);
    final asked = text.toLowerCase();
    final focused = current.where((course) {
      return asked.contains(course.courseName.toLowerCase()) ||
          asked.contains(course.courseCode.toLowerCase());
    }).toList();
    final rows = focused.isEmpty ? current : focused;
    final wantsCgpa = asked.contains('cgpa') || asked.contains('gpa');
    final wantsAttendance =
        asked.contains('attendance') || asked.contains('present');
    final wantsCourses = asked.contains('course') || asked.contains('subject');

    final buffer = StringBuffer();
    if (wantsCgpa || (!wantsAttendance && !wantsCourses)) {
      buffer.writeln(
        'Your overall CGPA is ${student.cgpaOverall.toStringAsFixed(2)}.',
      );
    }
    if (wantsAttendance || wantsCourses || (!wantsCgpa && focused.isNotEmpty)) {
      final average = averageAttendance(rows);
      if (average == null) {
        buffer.writeln('I could not find courses for this semester.');
      } else if (wantsAttendance || !wantsCourses) {
        buffer.writeln(
          'Average attendance this semester is ${average.toStringAsFixed(1)}%.',
        );
      }
      if (rows.isNotEmpty && (wantsCourses || wantsAttendance || focused.isNotEmpty)) {
        buffer.writeln('Courses:');
        for (final course in rows) {
          buffer.writeln(
            '• ${course.courseName} (${course.courseCode}) — ${course.attendancePercent.toStringAsFixed(0)}%',
          );
        }
      }
    }
    final reply = buffer.toString().trim();
    if (reply.isEmpty) {
      return ChatReply(
        'You are in semester ${student.semester}, section ${student.section}. Ask me about attendance or a course name.',
      );
    }
    return ChatReply(reply);
  }

  Future<ChatReply> _facultyReply(String text) async {
    final people = await facultyLoader();
    if (people.isEmpty) {
      return const ChatReply(
        'Teacher records are not loaded yet. Ask again after the faculty list is added.',
      );
    }
    final tokens = _nameTokens(text);
    if (tokens.isEmpty) {
      final available = people
          .where((person) => person.currentStatus == 'In Office')
          .take(5)
          .toList();
      if (available.isEmpty) {
        return const ChatReply(
          'Tell me the teacher\'s name, for example "Where is Dr. Hamza Qureshi?"',
        );
      }
      final lines = available
          .map((person) => '• ${person.fullName} — ${person.officeRoom}, ${person.officeBuilding}')
          .join('\n');
      return ChatReply('These teachers are in their offices right now:\n$lines');
    }

    final matches = filterFaculty(people, query: tokens.join(' '));
    if (matches.isEmpty) {
      return ChatReply(
        'I could not find a teacher matching "${tokens.join(' ')}". Try the full name from Teacher Tracking.',
      );
    }
    if (matches.length > 3) {
      final lines = matches
          .take(6)
          .map((person) => '• ${person.fullName} (${person.department})')
          .join('\n');
      return ChatReply('I found several people. Which one do you mean?\n$lines');
    }
    if (matches.length > 1) {
      final lines = matches.map(_facultySummary).join('\n\n');
      return ChatReply(lines);
    }
    return ChatReply(_facultySummary(matches.first));
  }

  String _facultySummary(Faculty person) {
    final days = person.daysOff.join(', ');
    return '${person.fullName} is ${person.currentStatus}. '
        '${person.designation}, ${departmentLabel(person.department)}. '
        'Subjects: ${person.subjects.join(', ')}. '
        'Classes: ${person.classSchedule}. '
        'Consultation: ${person.consultationHours}. '
        'Off: $days. '
        'Office: ${person.officeRoom}, ${person.officeBuilding}. '
        'Email ${person.email}, phone ${person.phone}.';
  }

  List<String> _nameTokens(String text) {
    const stop = {
      'where',
      'is',
      'the',
      'my',
      'a',
      'an',
      'teacher',
      'teachers',
      'faculty',
      'professor',
      'instructor',
      'sir',
      'madam',
      'miss',
      'ms',
      'mr',
      'dr',
      'dr.',
      'available',
      'availability',
      'office',
      'who',
      'teaches',
      'teach',
      'teaching',
      'class',
      'in',
      'of',
      'for',
      'me',
      'can',
      'you',
      'find',
      'show',
      'status',
      'what',
      'whats',
      'now',
      'right',
      'please',
      'tell',
      'about',
      'consultation',
      'hours',
    };
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((token) => token.length > 2 && !stop.contains(token))
        .toList();
  }
}

const _fallback =
    'I can help with your fee challan, roll number slip, courses, attendance, teachers, and campus rules. Try one of the suggestions, or ask in your own words.';
