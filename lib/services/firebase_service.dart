import 'package:flutter/foundation.dart' show kIsWeb;

class FirebaseService {
  static Future<void> initialize() async {
    if (!kIsWeb) {
      // Only import and initialize on mobile
      await _initializeMobile();
    }
  }

  static Future<void> _initializeMobile() async {
    // This will only run on Android/iOS
    // ignore: unused_element
    await Future.delayed(Duration.zero);
    print('Firebase initialized on mobile');
  }
}