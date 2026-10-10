import 'package:aicc/core/formatters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('signup email is the lowercase registration number', () {
    expect(
      internalEmailFor(' FA26-BSCS-001 '),
      'fa26-bscs-001@aicc-demo.local',
    );
    expect(validateRegistration('fa26-bscs-001'), isNull);
    expect(validateRegistration('not-a-number'), isNotNull);
    expect(validatePassword('12345'), isNotNull);
    expect(validatePassword('123456'), isNull);
  });
}
