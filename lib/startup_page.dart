import 'package:flutter/material.dart';

class StartupPage extends StatelessWidget {
  const StartupPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Theme colors for the "Modern Health" vibe
    const Color forestDark = Color(0xFF283618);
    const Color forestLight = Color(0xFF606C38);

    return Scaffold(
      body: InkWell(
        onTap: () => Navigator.pushNamed(context, '/login'),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [forestLight, forestDark],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // TEREA Header
              const Text(
                'TEREA',
                style: TextStyle(
                  fontSize: 52, 
                  fontWeight: FontWeight.w900, 
                  letterSpacing: 8, 
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      blurRadius: 10.0,
                      color: Colors.black26,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 10),
              
              Text(
                'Personalized TB Care'.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 2,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),

              const SizedBox(height: 80),

              // Interaction Hint
              const Column(
                children: [
                  Icon(Icons.touch_app_outlined, color: Colors.white60, size: 20),
                  SizedBox(height: 8),
                  Text(
                    'Tap anywhere to continue',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w300,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}