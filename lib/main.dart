import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'startup_page.dart';
import 'login_page.dart';
import 'signup_page.dart';
import 'dashboard_page.dart';
import 'assessment_page.dart';
import 'meds_page.dart';
import 'followup_page.dart';
import 'chat_page.dart';
import 'settings_page.dart';
import 'risk_result_page.dart';
import 'facilities_page.dart';
import 'support_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // SUPABASE API INITIALIZATION
  await Supabase.initialize(
    url: 'https://ppeptqgaroispxwvezcq.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBwZXB0cWdhcm9pc3B4d3ZlemNxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA2MDk5NzIsImV4cCI6MjA4NjE4NTk3Mn0.XfrgVO5GviO43PKU_tkGbuo0afq3J54B0tQoQXZmumo',
  );

  runApp(const TereaApp());
}

class TereaApp extends StatelessWidget {
  const TereaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFFEFAE0),
        primaryColor: const Color(0xFF606C38),
        useMaterial3: true,
      ),
      // --- ROUTE NAVIGATION ---
      initialRoute: '/',
      routes: {
        '/': (context) => const StartupPage(),
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignUpPage(),
        '/dashboard': (context) => const DashboardPage(),
        '/assess': (context) => const AssessmentPage(),
        '/meds': (context) => const MedsPage(),
        '/followup': (context) => const FollowUpPage(),
        '/chat': (context) => const ChatPage(),
        '/settings': (context) => const SettingsPage(),
        '/result': (context) => const RiskResultPage(),
        '/facilities': (context) => const FacilitiesPage(),
        '/support': (context) => const SupportPage(),
      },
    );
  }
}
