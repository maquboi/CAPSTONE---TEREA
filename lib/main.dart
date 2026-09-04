import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

import 'startup_page.dart';
import 'login_page.dart';
import 'signup_page.dart';
import 'dashboard_page.dart';
import 'assessment_page.dart';
import 'meds_page.dart';
import 'followup_page.dart';
import 'faq_page.dart';
import 'settings_page.dart';
import 'risk_result_page.dart';
import 'facilities_page.dart';
import 'support_page.dart';
import 'mydoctor_page.dart';
import 'notifications_page.dart'; 

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Safe Supabase Initialization
  try {
    await Supabase.initialize(
      url: 'https://ppeptqgaroispxwvezcq.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBwZXB0cWdhcm9pc3B4d3ZlemNxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA2MDk5NzIsImV4cCI6MjA4NjE4NTk3Mn0.XfrgVO5GviO43PKU_tkGbuo0afq3J54B0tQoQXZmumo',
    );
  } catch (e) {
    debugPrint("Supabase Initialization Warning: $e");
  }

  // 2. Safe OneSignal Setup (Background Safe)
  try {
    OneSignal.Debug.setLogLevel(OSLogLevel.none); // Disable noisy logs in release
    OneSignal.initialize("d6a0d4c7-af80-4323-b9e4-dcdc447d7cde");
    
    // Deep linking handler
    OneSignal.Notifications.addClickListener((event) {
      final data = event.notification.additionalData;
      if (data != null && data['targetScreen'] == 'notifications') {
        final currentSession = Supabase.instance.client.auth.currentSession;
        if (currentSession != null) {
          navigatorKey.currentState?.pushNamed('/notifications');
        } else {
          navigatorKey.currentState?.pushNamed('/login');
        }
      }
    });
  } catch (e) {
    debugPrint("OneSignal Initialization Warning: $e");
  }

  runApp(const TereaApp());
}

class TereaApp extends StatefulWidget {
  const TereaApp({super.key});

  @override
  State<TereaApp> createState() => _TereaAppState();
}

class _TereaAppState extends State<TereaApp> {
  @override
  void initState() {
    super.initState();
    // Post-frame callback ensures the native Android Window is fully mounted before prompting permissions
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initPostLaunchServices();
    });
  }

  void _initPostLaunchServices() {
    try {
      OneSignal.Notifications.requestPermission(true);
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        OneSignal.login(session.user.id);
      }
    } catch (e) {
      debugPrint("Post-launch notification error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TEREA', // Fixes task manager / recents title
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFFEFAE0),
        primaryColor: const Color(0xFF606C38),
        useMaterial3: true,
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: ZoomPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const StartupPage(),
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignUpPage(),
        '/dashboard': (context) => const DashboardPage(),
        '/assess': (context) => const AssessmentPage(),
        '/meds': (context) => const MedsPage(),
        '/followup': (context) => const FollowUpPage(),
        '/faq': (context) => const FaqPage(),
        '/settings': (context) => const SettingsPage(),
        '/result': (context) => const RiskResultPage(),
        '/facilities': (context) => const FacilitiesPage(),
        '/support': (context) => const SupportPage(),
        '/my_doctor': (context) => const MyDoctorPage(),
        '/notifications': (context) => const NotificationsPage(),
      },
    );
  }
}