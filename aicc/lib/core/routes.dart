import 'package:flutter/material.dart';

abstract final class AppRoutes {
  static const splash = '/';
  static const setup = '/setup';
  static const login = '/login';
  static const signup = '/signup';
  static const home = '/home';
  static const admin = '/admin';
}

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
