// routes.dart
import 'package:flutter/material.dart';
import 'package:work_scheduler_v0/screens/login.dart';
import 'screens/homepage.dart';
import 'screens/calendar.dart';
import 'screens/registration.dart';
import 'screens/admin.dart';

const String homeRoute = '/';
const String calendarRoute = '/calendar';
const String registrationPage = '/registration';
const String adminPage = '/vfeel';
const String loginPage = '/login';

Map<String, WidgetBuilder> getApplicationRoutes() {
  return {
    homeRoute: (BuildContext context) => const HomePage(),
    calendarRoute: (BuildContext context) => CalendarPage(),
    registrationPage: (BuildContext context) => const RegistrationPage(),
    adminPage: (BuildContext context) => const AdminPage(),
    loginPage: (BuildContext context) => LoginPage(),
    // Add other routes here
  };
}
