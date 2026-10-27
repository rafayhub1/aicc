/// Named routes for splash, sign-in, the student shell, admin, and navigation.
library;

import 'package:flutter/material.dart';

abstract final class AppRoutes {
  static const splash = '/';
  static const setup = '/setup';
  static const login = '/login';
  static const signup = '/signup';
  static const home = '/home';
  static const admin = '/admin';
  static const navigationMode = '/navigation-mode';
}

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
