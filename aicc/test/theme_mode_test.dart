import 'package:aicc/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('saved appearance falls back to the device setting', () {
    expect(themeModeFromStorage(null), ThemeMode.system);
    expect(themeModeFromStorage('system'), ThemeMode.system);
    expect(themeModeFromStorage('light'), ThemeMode.light);
    expect(themeModeFromStorage('dark'), ThemeMode.dark);
    expect(themeModeToStorage(ThemeMode.system), 'system');
    expect(themeModeToStorage(ThemeMode.light), 'light');
    expect(themeModeToStorage(ThemeMode.dark), 'dark');
  });
}
