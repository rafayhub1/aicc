import 'package:flutter/material.dart';

import 'theme.dart';

Color categoryColor(String category) {
  return switch (category) {
    'Food' => const Color(0xFFB86E00),
    'Library' => const Color(0xFF1B5F9C),
    'Prayer' => const Color(0xFF7C3AED),
    'Labs' => const Color(0xFF0F766E),
    'Sports' => AppColors.accent,
    'Parking' => const Color(0xFF64748B),
    'Gates' => const Color(0xFFB45309),
    'Washrooms' => const Color(0xFF0369A1),
    'Admin' => AppColors.primary,
    _ => AppColors.primaryLight,
  };
}

IconData categoryIcon(String category) {
  return switch (category) {
    'Food' => Icons.restaurant_rounded,
    'Library' => Icons.local_library_rounded,
    'Prayer' => Icons.mosque_rounded,
    'Labs' => Icons.science_rounded,
    'Sports' => Icons.sports_soccer_rounded,
    'Parking' => Icons.local_parking_rounded,
    'Gates' => Icons.sensor_door_rounded,
    'Washrooms' => Icons.wc_rounded,
    'Admin' => Icons.account_balance_rounded,
    _ => Icons.school_rounded,
  };
}
