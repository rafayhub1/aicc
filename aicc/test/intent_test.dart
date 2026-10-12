import 'package:aicc/chat/intent.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('routes live questions and policy questions differently', () {
    expect(classifyIntent('show my fee challan').kind, ChatIntentKind.feeChallan);
    expect(classifyIntent('open roll number slip').kind, ChatIntentKind.rollSlip);
    expect(classifyIntent('what is my attendance?').kind, ChatIntentKind.academics);
    expect(classifyIntent('what is the attendance policy').kind, ChatIntentKind.faq);
    expect(classifyIntent('where is Dr. Hamza Qureshi').kind, ChatIntentKind.faculty);
    expect(classifyIntent('hello').kind, ChatIntentKind.greeting);
    expect(classifyIntent('hi').kind, ChatIntentKind.greeting);
    expect(classifyIntent('hey!').kind, ChatIntentKind.greeting);
    expect(classifyIntent('hi, what is my attendance?').kind, ChatIntentKind.academics);
  });
}
