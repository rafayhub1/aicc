import 'knowledge_base.dart';

enum ChatIntentKind {
  greeting,
  faq,
  feeChallan,
  rollSlip,
  academics,
  faculty,
  unknown,
}

class ClassifiedIntent {
  const ClassifiedIntent(this.kind, {this.faqAnswer});

  final ChatIntentKind kind;
  final String? faqAnswer;
}

const suggestedQuestions = [
  'Show my fee challan',
  'Open my roll number slip',
  'What is my attendance?',
  'Where is Dr. Hamza Qureshi?',
  'What is the attendance policy?',
];

ClassifiedIntent classifyIntent(String raw) {
  final text = raw.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  if (text.isEmpty) {
    return const ClassifiedIntent(ChatIntentKind.unknown);
  }

  if (_isGreeting(text)) {
    return const ClassifiedIntent(ChatIntentKind.greeting);
  }

  if (_containsAny(text, ['fee challan', 'challan', 'fee voucher', 'my fee'])) {
    return const ClassifiedIntent(ChatIntentKind.feeChallan);
  }
  if (_containsAny(text, [
    'roll slip',
    'roll number slip',
    'roll-number',
    'admit card',
  ])) {
    return const ClassifiedIntent(ChatIntentKind.rollSlip);
  }

  if (_isFaculty(text)) {
    return const ClassifiedIntent(ChatIntentKind.faculty);
  }

  if (_isAcademics(text) && !_isPolicy(text)) {
    return const ClassifiedIntent(ChatIntentKind.academics);
  }

  final faq = matchKnowledge(text);
  if (faq != null) return ClassifiedIntent(ChatIntentKind.faq, faqAnswer: faq);

  if (_isAcademics(text)) {
    return const ClassifiedIntent(ChatIntentKind.academics);
  }

  return const ClassifiedIntent(ChatIntentKind.unknown);
}

bool _isGreeting(String text) {
  var cleaned = text
      .replaceAll(RegExp("[!?,.']"), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  for (final extra in const [' there', ' aicc']) {
    if (cleaned.endsWith(extra)) {
      cleaned = cleaned.substring(0, cleaned.length - extra.length).trim();
    }
  }
  const greetings = {
    'hi',
    'hii',
    'hiii',
    'hey',
    'heyy',
    'hello',
    'helloo',
    'helo',
    'yo',
    'howdy',
    'salam',
    'salaam',
    'aoa',
    'assalam',
    'assalamualaikum',
    'assalamu alaikum',
    'assalam o alaikum',
    'asalamualaikum',
    'good morning',
    'good afternoon',
    'good evening',
    'good night',
  };
  return greetings.contains(cleaned);
}

bool _isPolicy(String text) {
  return _containsAny(text, [
    'policy',
    'rule',
    'required',
    'minimum',
    'how is',
    'how are',
    'calculated',
    'deadline',
  ]);
}

bool _isFaculty(String text) {
  return _containsAny(text, [
    'teacher',
    'faculty',
    'professor',
    'instructor',
    'sir',
    'madam',
    'dr ',
    'dr.',
    'where is',
    'who teaches',
    'consultation',
  ]);
}

bool _isAcademics(String text) {
  return _containsAny(text, [
    'my attendance',
    'my course',
    'my courses',
    'my subject',
    'my subjects',
    'my cgpa',
    'my gpa',
    'my class',
    'my semester',
  ]);
}

bool _containsAny(String text, List<String> needles) {
  for (final needle in needles) {
    if (text.contains(needle)) return true;
  }
  return false;
}
