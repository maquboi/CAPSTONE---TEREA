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
// We will create this file in the next step!
import 'notifications_page.dart'; 

// 1. Create a Global Navigator Key so OneSignal can control screen routing
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Supabase initialization
  await Supabase.initialize(
    url: 'https://ppeptqgaroispxwvezcq.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBwZXB0cWdhcm9pc3B4d3ZlemNxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA2MDk5NzIsImV4cCI6MjA4NjE4NTk3Mn0.XfrgVO5GviO43PKU_tkGbuo0afq3J54B0tQoQXZmumo',
  );

  // 3. OneSignal Initialization
  OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
  OneSignal.initialize("d6a0d4c7-af80-4323-b9e4-dcdc447d7cde");
  OneSignal.Notifications.requestPermission(true); // Asks user for permission to show alerts

  // 4. Bind the current Supabase User to OneSignal (if they are already logged in)
  final session = Supabase.instance.client.auth.currentSession;
  if (session != null) {
    OneSignal.login(session.user.id);
  }

  // 5. Setup the Deep Link Routing (Tap on push notification)
  OneSignal.Notifications.addClickListener((event) {
    final data = event.notification.additionalData;
    
    // Check if the push notification payload tells us to go to the notifications screen
    if (data != null && data['targetScreen'] == 'notifications') {
      final currentSession = Supabase.instance.client.auth.currentSession;
      
      // Only route them to the notifications page if they are actually logged in
      if (currentSession != null) {
        navigatorKey.currentState?.pushNamed('/notifications');
      } else {
        navigatorKey.currentState?.pushNamed('/login');
      }
    }
  });

  runApp(const TereaApp());
}

class TereaApp extends StatelessWidget {
  const TereaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey, // Connect the Global Key here
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFFEFAE0),
        primaryColor: const Color(0xFF606C38),
        useMaterial3: true,
        // <-- ADDED THIS BLOCK FOR SMOOTH PAGE TRANSITIONS -->
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
        '/notifications': (context) => const NotificationsPage(), // New Route Added!
      },
    );
  }
}