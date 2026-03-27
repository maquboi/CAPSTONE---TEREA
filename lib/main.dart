import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; 
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // SUPABASE API ITO AHHHHH HAHAH 
  await Supabase.initialize(
    url: 'https://ppeptqgaroispxwvezcq.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBwZXB0cWdhcm9pc3B4d3ZlemNxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA2MDk5NzIsImV4cCI6MjA4NjE4NTk3Mn0.XfrgVO5GviO43PKU_tkGbuo0afq3J54B0tQoQXZmumo',
  );

  runApp(const TereaApp());
}

class Medicine {
  String name;
  String dosage;
  String time;
  bool isTaken;
  Medicine({required this.name, required this.dosage, required this.time, this.isTaken = false});
}
class ChatMessage {
  String text;
  bool isUser;
  ChatMessage({required this.text, required this.isUser});
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
      initialRoute: '/',
      routes: {
        '/': (context) => const StartupPage(),
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignUpPage(),
        '/home': (context) => const DashboardPage(),
        '/assess': (context) => const AssessmentPage(),
        '/meds': (context) => const MedsPage(),
        '/followup': (context) => const FollowUpPage(),
        '/chat': (context) => const ChatPage(),
        '/settings': (context) => const SettingsPage(),
        '/result': (context) => const RiskResultPage(),
        '/facilities': (context) => const FacilitiesPage(),
      },
    );
  }
}

//  STARTUP PAGE natin
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
              // Logo with shadow/glow
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: _buildLogo(size: 120),
              ),
              const SizedBox(height: 30),
              
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

  // FIXED: Using 'Icons.eco' which is a standard leaf icon
  Widget _buildLogo({required double size}) {
    return Icon(
      Icons.eco, // Standard Material leaf icon
      size: size, 
      color: const Color(0xFFFEFAE0),
    );
  }
}

// --- LOGIN PAGE ---
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _signIn() async {
    setState(() => _isLoading = true);
    try {
      // 1. Perform the Auth Login
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (response.user != null) {
        // 2. FETCH ROLE: Check if this user is a Patient or Doctor
        final data = await Supabase.instance.client
            .from('profiles')
            .select('role')
            .eq('id', response.user!.id)
            .maybeSingle(); // Use maybeSingle to avoid crashes if profile is missing

        String role = data != null && data['role'] != null ? data['role'] : 'patient';

        if (mounted) {
          // 3. ROLE GATEKEEPER
          if (role == 'doctor') {
            // If Doctor, deny access on Mobile
            await Supabase.instance.client.auth.signOut(); // Force sign out
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Access Denied: Doctors must use the Web Portal."),
                backgroundColor: Colors.redAccent,
                duration: Duration(seconds: 4),
              ),
            );
          } else {
            // If Patient (or null), proceed to Mobile Dashboard
            Navigator.pushNamed(context, '/home');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Login Failed: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color forestDark = Color(0xFF283618);
    const Color forestLight = Color(0xFF606C38);
    const Color bgWhite = Color(0xFFF9FAFB);

    return Scaffold(
      backgroundColor: bgWhite,
      body: Stack(
        children: [
          // --- BACKGROUND DECORATIONS ---
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                color: forestLight.withOpacity(0.12),
                borderRadius: BorderRadius.circular(80),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -40,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                color: forestDark.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // --- MAIN CONTENT ---
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(child: _buildLogo(size: 80)),
                  const SizedBox(height: 30),
                  const Text(
                    'Welcome back',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: forestDark,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in to your personalized tracker',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: forestLight.withOpacity(0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 50),

                  _buildTextField(
                    label: "Email",
                    hint: "you@example.com",
                    controller: _emailController,
                    icon: Icons.email_outlined,
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    label: "Password",
                    hint: "••••••••",
                    isPassword: true,
                    controller: _passwordController,
                    icon: Icons.lock_outline,
                  ),
                  const SizedBox(height: 40),

                  _isLoading
                      ? const Center(child: CircularProgressIndicator(color: forestDark))
                      : _buildGradientButton(
                          text: "Sign in",
                          onPressed: _signIn,
                          colors: [forestLight, forestDark],
                        ),

                  const SizedBox(height: 25),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/signup'),
                    style: TextButton.styleFrom(
                      foregroundColor: forestLight,
                    ),
                    child: RichText(
                      text: const TextSpan(
                        text: "Don't have an account? ",
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                        children: [
                          TextSpan(
                            text: "Sign up",
                            style: TextStyle(
                              color: forestDark,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    bool isPassword = false,
    IconData? icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF283618),
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.08),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              prefixIcon: Icon(icon, color: const Color(0xFF606C38).withOpacity(0.6), size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFF606C38), width: 1.5),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGradientButton({
    required String text,
    required VoidCallback onPressed,
    required List<Color> colors,
  }) {
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors.last.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo({required double size}) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF283618).withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.eco,
        size: size,
        color: const Color(0xFF283618),
      ),
    );
  }
}


class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  // --- CONTROLLERS ---
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _contactController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _selectedGender;
  final List<String> _genderOptions = ['Male', 'Female', 'Other'];
  bool _isLoading = false;

  // --- NEW ATTACHMENT & TERMS STATE (WEB SAFE) ---
  XFile? _idAttachment; 
  bool _acceptedTerms = false;
  final ImagePicker _picker = ImagePicker();

  // --- IMAGE PICKER LOGIC ---
  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _idAttachment = pickedFile;
        });
      }
    } catch (e) {
      _showSnackBar("Failed to pick image: $e");
    }
  }

  // --- TERMS & CONDITIONS DIALOG ---
  void _showTermsDialog(Color forestDark, Color forestLight) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.gavel_rounded, color: forestDark),
            const SizedBox(width: 10),
            Text("Terms & Conditions", style: TextStyle(color: forestDark, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: const SingleChildScrollView(
          child: Text(
            "By proceeding with this registration and attaching the requested Carmona Residency ID, I hereby certify under penalty of perjury that the information provided is true, accurate, and reflects my current legal residence within the Municipality of Carmona. I acknowledge that the document submitted is a confidential record intended solely for the purpose of eligibility verification for the TB HealthCare management system. Furthermore, I agree to a strict Non-Disclosure obligation, understanding that any unauthorized access to the system's internal protocols, or the falsification of residency data to gain such access, constitutes a breach of professional conduct and may result in the immediate termination of my account and potential legal action. I consent to the secure electronic processing of my identification data and waive any claims against the system administrators regarding the standardized verification procedures required to maintain the integrity of this localized healthcare initiative.",
            style: TextStyle(fontSize: 13, color: Colors.black87, height: 1.5),
            textAlign: TextAlign.justify,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Close", style: TextStyle(color: forestLight, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: forestDark,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              setState(() => _acceptedTerms = true);
              Navigator.pop(context);
            },
            child: const Text("I Agree", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- VALIDATION LOGIC ---
  bool _validateInputs() {
    final nameRegex = RegExp(r'^[a-zA-Z ]+$');
    if (_nameController.text.isEmpty ||
        _nameController.text.length > 50 ||
        !nameRegex.hasMatch(_nameController.text)) {
      _showSnackBar("Name must contain letters only and be under 50 characters.");
      return false;
    }

    final age = int.tryParse(_ageController.text);
    if (age == null || age < 1 || age > 100) {
      _showSnackBar("Age must be a valid number between 1 and 100.");
      return false;
    }

    if (!_contactController.text.startsWith('09') ||
        _contactController.text.length != 11) {
      _showSnackBar("Contact number must start with '09' and be 11 digits.");
      return false;
    }

    if (!_emailController.text.contains('@')) {
      _showSnackBar("Please enter a valid email address.");
      return false;
    }

    if (_passwordController.text.length < 10) {
      _showSnackBar("Password must be at least 10 characters long.");
      return false;
    }

    if (_selectedGender == null) {
      _showSnackBar("Please select a gender.");
      return false;
    }

    if (_idAttachment == null) {
      _showSnackBar("Please attach a valid ID to confirm your residence in Carmona.");
      return false;
    }

    if (!_acceptedTerms) {
      _showSnackBar("You must acknowledge the terms and conditions to proceed.");
      return false;
    }

    return true;
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleSignUp() async {
    if (!_validateInputs()) return;

    setState(() => _isLoading = true);
    try {
      final authResponse = await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (authResponse.user != null) {
        // --- PROCESS WORKFLOW: UPLOAD ID ATTACHMENT ---
        String? idUrl;
        if (_idAttachment != null) {
          final fileExt = _idAttachment!.name.split('.').last;
          final fileName = '${authResponse.user!.id}_id.$fileExt';
          
          final bytes = await _idAttachment!.readAsBytes();
          
          await Supabase.instance.client.storage
              .from('id_attachments')
              .uploadBinary(fileName, bytes);
              
          idUrl = Supabase.instance.client.storage
              .from('id_attachments')
              .getPublicUrl(fileName);
        }

        // --- PROCESS WORKFLOW: AUTOMATIC PATIENT ASSIGNMENT ---
        await Supabase.instance.client.from('profiles').insert({
          'id': authResponse.user!.id,
          'full_name': _nameController.text.trim(),
          'age': _ageController.text.trim(),
          'gender': _selectedGender,
          'contact_number': _contactController.text.trim(),
          'email': _emailController.text.trim(),
          'role': 'patient', 
          'id_attachment_url': idUrl, 
        });

        if (mounted) Navigator.pushNamed(context, '/home');
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar("Registration Error: $e");
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color forestDark = Color(0xFF283618);
    const Color forestLight = Color(0xFF606C38);
    const Color bgWhite = Color(0xFFF9FAFB);

    return Scaffold(
      backgroundColor: bgWhite,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // The Restored Blob Background
          Positioned(
            top: 200,
            right: -50,
            child: _buildBackgroundShape(180, forestLight.withOpacity(0.08)),
          ),
          SingleChildScrollView(
            child: Column(
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(top: 80, bottom: 40),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [forestLight, forestDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildLogo(size: 60),
                      const SizedBox(height: 20),
                      const Text(
                        'Join TB HealthCare',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Start your wellness journey today',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                // Form Card
                Padding(
                  padding: const EdgeInsets.fromLTRB(25, 30, 25, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Create Account',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: forestDark),
                      ),
                      const SizedBox(height: 25),

                      _buildTextField(
                        label: "Full Name",
                        hint: "Juan Dela Cruz",
                        controller: _nameController,
                        icon: Icons.person_outline,
                        inputType: TextInputType.name,
                        formatters: [
                          LengthLimitingTextInputFormatter(50),
                          FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z ]')),
                        ],
                      ),
                      const SizedBox(height: 20),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildTextField(
                              label: "Age",
                              hint: "25",
                              controller: _ageController,
                              icon: Icons.cake_outlined,
                              inputType: TextInputType.number,
                              formatters: [
                                LengthLimitingTextInputFormatter(3),
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(child: _buildGenderDropdown(forestDark, forestLight)),
                        ],
                      ),
                      const SizedBox(height: 20),

                      _buildTextField(
                        label: "Contact Number",
                        hint: "09123456789",
                        controller: _contactController,
                        icon: Icons.phone_android_outlined,
                        inputType: TextInputType.phone,
                        formatters: [
                          LengthLimitingTextInputFormatter(11),
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                      const SizedBox(height: 20),

                      _buildTextField(
                        label: "Email Address",
                        hint: "your.email@example.com",
                        controller: _emailController,
                        icon: Icons.mail_outline,
                        inputType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 20),

                      _buildTextField(
                        label: "Password",
                        hint: "Minimum 10 characters",
                        isPassword: true,
                        controller: _passwordController,
                        icon: Icons.lock_open_outlined,
                      ),
                      const SizedBox(height: 20),

                      // --- STYLED ID ATTACHMENT UPLOAD ---
                      const Text("Proof of Residence (Carmona ID)", style: TextStyle(color: Color(0xFF283618), fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _idAttachment != null ? forestLight : Colors.transparent, width: 1.5),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))],
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _idAttachment != null ? Icons.check_circle : Icons.upload_file, 
                                color: _idAttachment != null ? forestLight : forestLight.withOpacity(0.5), 
                                size: 20
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Text(
                                  _idAttachment != null ? "ID Attached Successfully" : "Tap to upload ID photo",
                                  style: TextStyle(
                                    color: _idAttachment != null ? forestDark : Colors.grey, 
                                    fontSize: 14,
                                    fontWeight: _idAttachment != null ? FontWeight.bold : FontWeight.normal
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // --- INTERACTIVE TERMS AND CONDITIONS CHECKBOX ---
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: 24,
                            width: 24,
                            child: Checkbox(
                              value: _acceptedTerms,
                              onChanged: (val) => setState(() => _acceptedTerms = val ?? false),
                              activeColor: forestLight,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _showTermsDialog(forestDark, forestLight),
                              child: RichText(
                                text: TextSpan(
                                  text: "I acknowledge the ",
                                  style: const TextStyle(fontSize: 13, color: Colors.grey, height: 1.4),
                                  children: [
                                    TextSpan(
                                      text: "Terms & Conditions",
                                      style: TextStyle(color: forestDark, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                                    ),
                                    const TextSpan(text: " and confirm I am a resident of Carmona."),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 35),

                      // SUBMIT BUTTON
                      _isLoading
                          ? const Center(child: CircularProgressIndicator(color: forestDark))
                          : _buildGradientButton("Create Account", _handleSignUp, [forestLight, forestDark]),
                      const SizedBox(height: 25),
                      
                      Center(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: RichText(
                            text: const TextSpan(
                              text: "Already have an account? ",
                              style: TextStyle(color: Colors.grey, fontSize: 14),
                              children: [
                                TextSpan(
                                  text: "Sign In",
                                  style: TextStyle(color: forestDark, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- UI COMPONENTS ---
  Widget _buildGenderDropdown(Color forestDark, Color forestLight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Gender", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF283618), fontSize: 14)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedGender,
              hint: Text("Select", style: TextStyle(fontSize: 14, color: forestLight.withOpacity(0.5))),
              isExpanded: true,
              items: _genderOptions.map((String value) {
                return DropdownMenuItem<String>(value: value, child: Text(value, style: const TextStyle(fontSize: 14)));
              }).toList(),
              onChanged: (newValue) => setState(() => _selectedGender = newValue),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    bool isPassword = false,
    IconData? icon,
    TextInputType inputType = TextInputType.text,
    List<TextInputFormatter>? formatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF283618), fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))],
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword,
            keyboardType: inputType,
            inputFormatters: formatters,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
              prefixIcon: Icon(icon, color: const Color(0xFF606C38).withOpacity(0.5), size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGradientButton(String text, VoidCallback onPressed, List<Color> colors) {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: colors.last.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 8))],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }

  Widget _buildLogo({required double size}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      child: Icon(Icons.favorite, size: size, color: const Color(0xFF283618)),
    );
  }

  Widget _buildBackgroundShape(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(size / 3)),
    );
  }
}



//DASHBOARD
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // --- LOGIC ---
  final _supabase = Supabase.instance.client;
  String _username = "Patient";
  String? _avatarUrl;
  String _riskLevel = "Not yet assessed";
  bool _isLoading = true;
  
  // CONNECTION TRACKING
  // null = no connection, 'pending' = waiting, 'active' = Verified
  String? _connectionStatus; 
  String? _doctorName; 
  
  final _codeController = TextEditingController();
  bool _isLinking = false;

  // Theme Palette
  final Color forestDark = const Color(0xFF283618); 
  final Color forestMed = const Color(0xFF606C38);  
  final Color mossGreen = const Color(0xFFADC178); 
  final Color paleGreen = const Color(0xFFDDE5B6); 
  final Color softWhite = const Color(0xFFF8F9FA);

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _setupRealtimeListener();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  // UPDATED: Listen to BOTH 'connections' (for Verified status) and 'profiles' (for Risk Level)
  void _setupRealtimeListener() {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    // 1. Connection Updates
    _supabase
      .channel('patient_connections')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'connections',
        filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'patient_id', value: user.id),
        callback: (payload) => _fetchUserData(),
      )
      .subscribe();

    // 2. Profile Updates (Risk Level changes)
    _supabase
      .channel('patient_profile')
      .onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'profiles',
        filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'id', value: user.id),
        callback: (payload) => _fetchUserData(),
      )
      .subscribe();
  }

  Future<void> _fetchUserData() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        // 1. Fetch Profile Data
        final profileData = await _supabase
            .from('profiles')
            .select('full_name, avatar_url, risk_level')
            .eq('id', user.id)
            .single();

        // 2. Fetch Connection Status & Doctor Name
        final connectionData = await _supabase
            .from('connections')
            .select('status, profiles!fk_doctor(full_name)') 
            .eq('patient_id', user.id)
            .maybeSingle();

        if (mounted) {
          setState(() {
            _username = profileData['full_name'] ?? "Patient";
            _avatarUrl = profileData['avatar_url'];
            _riskLevel = profileData['risk_level'] ?? "Not yet assessed";
            
            if (connectionData != null) {
              _connectionStatus = connectionData['status'];
              if (connectionData['profiles'] != null) {
                _doctorName = connectionData['profiles']['full_name'];
              }
            } else {
              _connectionStatus = null;
            }
            
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching dashboard data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- UPDATED CLINIC CODE LOGIC (Prevents Duplicates) ---
  Future<void> _submitClinicCode() async {
    if (_codeController.text.trim().isEmpty) return;

    setState(() => _isLinking = true);
    final code = _codeController.text.trim();
    final user = _supabase.auth.currentUser;

    try {
      // 1. Find Doctor by Code
      final doctor = await _supabase
          .from('profiles')
          .select('id, full_name')
          .eq('clinic_code', code)
          .eq('role', 'doctor')
          .maybeSingle();

      if (doctor == null) {
        _showToast("Invalid Clinic Code. Please check again.", Colors.redAccent);
        setState(() => _isLinking = false);
        return;
      }

      // 2. CHECK FOR EXISTING REQUEST (The Fix for Duplicates)
      final existing = await _supabase
          .from('connections')
          .select()
          .eq('patient_id', user!.id)
          .eq('doctor_id', doctor['id'])
          .maybeSingle();

      if (existing != null) {
        _showToast("You are already connected or pending with this doctor.", Colors.orange);
        setState(() => _isLinking = false);
        return;
      }

      // 3. Create Connection Request
      await _supabase.from('connections').insert({
        'patient_id': user.id,
        'doctor_id': doctor['id'],
        'status': 'pending', 
      });

      // 4. Update UI
      if (mounted) {
        setState(() {
          _connectionStatus = 'pending';
          _isLinking = false;
        });
        Navigator.pop(context); // Close dialog
        _showToast("Request sent to Dr. ${doctor['full_name']}!", const Color(0xFF606C38));
      }

    } catch (e) {
      debugPrint("Linking Error: $e");
      if (e.toString().contains("duplicate")) {
         _showToast("You have already sent a request.", Colors.orange);
      } else {
         _showToast("Error linking to clinic: $e", Colors.redAccent);
      }
      setState(() => _isLinking = false);
    }
  }

  void _showClinicCodeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Enter Clinic Code", style: TextStyle(color: Color(0xFF283618), fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Please enter the code provided by your doctor in Carmona (e.g., CMC-001).",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _codeController,
              decoration: InputDecoration(
                hintText: "Clinic Code",
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.qr_code, color: Color(0xFF606C38)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF606C38),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _isLinking ? null : _submitClinicCode,
            child: _isLinking 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text("Connect", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showToast(String msg, Color bg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: bg, behavior: SnackBarBehavior.floating),
    );
  }

  // --- UI BUILD ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.05),
        surfaceTintColor: Colors.white, 
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            _buildLogo(size: 32),
            const SizedBox(width: 10),
            Text('TEREA', 
              style: TextStyle(fontWeight: FontWeight.w900, color: forestDark, letterSpacing: 1.1)
            )
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))
                ],
                border: Border.all(color: mossGreen, width: 2),
              ),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: paleGreen,
                backgroundImage: _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
                child: _avatarUrl == null ? Icon(Icons.person, size: 20, color: forestDark) : null,
              ),
            ),
          )
        ],
      ),
      body: Stack(
        children: [
          // Background Blobs
          Positioned(top: -50, right: -30, child: _buildBlob(200, mossGreen)),
          Positioned(bottom: 100, left: -50, child: _buildBlob(250, forestMed)),
          
          _isLoading 
            ? Center(child: CircularProgressIndicator(color: forestMed))
            : RefreshIndicator(
                onRefresh: _fetchUserData,
                color: forestMed,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(25),
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello, $_username', 
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: forestDark, letterSpacing: -0.5)
                      ),
                      Text(
                        'How are you feeling today?', 
                        style: TextStyle(color: forestMed, fontSize: 16, fontWeight: FontWeight.w600)
                      ),
                      const SizedBox(height: 25),

                      // --- CONNECTION STATUS LOGIC ---
                      if (_connectionStatus == null) ...[
                        _buildConnectCard(),
                        const SizedBox(height: 20),
                      ] else if (_connectionStatus == 'pending') ...[
                        _buildPendingCard(),
                        const SizedBox(height: 20),
                      ] else if (_connectionStatus == 'active') ...[
                        _buildVerifiedCard(),
                        const SizedBox(height: 20),
                      ],
                      // -------------------------------
                      
                      _buildTreatmentBanner(),
                      
                      const SizedBox(height: 35),
                      Text(
                        'QUICK ACTIONS', 
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: forestMed, letterSpacing: 1.5)
                      ),
                      const SizedBox(height: 15),
                      
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 15,
                        mainAxisSpacing: 15,
                        children: [
                          _buildActionCard(context, Icons.assignment_rounded, 'Risk Assessment', 'Check your TB risk', '/assess', forestMed, paleGreen),
                          _buildActionCard(context, Icons.chat_bubble_rounded, 'Chatbot', 'Support', '/chat', forestMed, paleGreen),
                          _buildActionCard(context, Icons.settings_rounded, 'Settings', 'Preferences', '/settings', forestMed, paleGreen),
                          _buildActionCard(context, Icons.help_outline_rounded, 'Support', 'Contact Us', '/support', forestMed, paleGreen),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(0, context),
    );
  }

  // --- WIDGETS ---
  
  // 1. NO CONNECTION
  Widget _buildConnectCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF283618), // Dark Forest
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: const Color(0xFF283618).withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 8))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                child: const Icon(Icons.link_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Text("Verified Treatment", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            "Link with your Carmona doctor to unlock your full Medication Diary.",
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _showClinicCodeDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF283618),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Enter Clinic Code", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  // 2. PENDING
  Widget _buildPendingCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF9C74F), // Amber/Yellow
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.orange.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: const [
          Icon(Icons.hourglass_top_rounded, color: Color(0xFF283618), size: 30),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Approval Pending", style: TextStyle(color: Color(0xFF283618), fontWeight: FontWeight.bold, fontSize: 15)),
                Text("Waiting for your doctor to verify your request.", style: TextStyle(color: Color(0xFF283618), fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 3. VERIFIED / ACTIVE
  Widget _buildVerifiedCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF606C38), // Forest Medium (Success Green)
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: const Color(0xFF606C38).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 6))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
            child: const Icon(Icons.verified_user_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Verified Patient", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(
                  _doctorName != null 
                    ? "You are under the care of $_doctorName."
                    : "You are officially linked to the clinic.", 
                  style: const TextStyle(color: Colors.white70, fontSize: 12)
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- TREATMENT BANNER ---
  Widget _buildTreatmentBanner() {
    bool isNotAssessed = _riskLevel == "Not yet assessed";
    String displayText = isNotAssessed ? "Not Yet Tested" : _riskLevel;

    Color bgColor = const Color(0xFF606C38);
    if (_riskLevel.toLowerCase().contains("high")) bgColor = const Color.fromARGB(222, 203, 5, 38);
    else if (_riskLevel.toLowerCase().contains("medium")) bgColor = const Color(0xFFF9C74F);
    else if (_riskLevel.toLowerCase().contains("low")) bgColor = const Color(0xFF43AA8B);

    BoxDecoration boxDecoration;
    if (isNotAssessed) {
      boxDecoration = BoxDecoration(
        gradient: LinearGradient(
          colors: [paleGreen, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: paleGreen.withOpacity(0.5), 
            blurRadius: 20, 
            offset: const Offset(0, 10)
          )
        ],
      );
    } else {
      boxDecoration = BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: bgColor.withOpacity(0.4), 
            blurRadius: 20, 
            offset: const Offset(0, 10)
          )
        ],
      );
    }

    Color titleColor = isNotAssessed ? forestDark : Colors.white;
    Color subtitleColor = isNotAssessed ? forestDark.withOpacity(0.7) : Colors.white70;
    Color iconColor = isNotAssessed ? forestDark : Colors.white;
    Color iconBgColor = isNotAssessed ? forestDark.withOpacity(0.1) : Colors.white.withOpacity(0.25);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: boxDecoration,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: iconBgColor, shape: BoxShape.circle),
            child: Icon(Icons.monitor_heart_rounded, color: iconColor, size: 30),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Treatment Status', 
                  style: TextStyle(color: subtitleColor, fontWeight: FontWeight.bold, fontSize: 13)
                ),
                Text(displayText, 
                  style: TextStyle(color: titleColor, fontSize: 20, fontWeight: FontWeight.w900)
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, IconData icon, String title, String subtitle, String route, Color iconColor, Color bgColor) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08), 
            blurRadius: 12, 
            offset: const Offset(0, 6)
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.pushNamed(context, route),
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.6), 
                    shape: BoxShape.circle,
                    boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)
                    ]
                  ),
                  child: Icon(icon, color: iconColor, size: 26),
                ),
                const SizedBox(height: 15),
                Text(title, 
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: forestDark)
                ),
                const SizedBox(height: 4),
                Text(subtitle, 
                  style: const TextStyle(color: Colors.black54, fontSize: 11, fontWeight: FontWeight.w500, height: 1.2)
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBlob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(size / 2.5)),
    );
  }

  Widget _buildLogo({required double size}) {
    return Icon(Icons.eco_rounded, color: forestDark, size: size);
  }

  Widget _buildBottomNav(int index, BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, -5))
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: index,
        onTap: (int tappedIndex) {
          if (tappedIndex == index) return; 
          
          switch (tappedIndex) {
            case 0:
              Navigator.pushReplacementNamed(context, '/dashboard');
              break;
            case 1:
              Navigator.pushNamed(context, '/meds');
              break;
            case 2:
              Navigator.pushNamed(context, '/followup');
              break;
            case 3:
              Navigator.pushNamed(context, '/settings');
              break;
          }
        },
        selectedItemColor: forestDark,
        unselectedItemColor: Colors.grey.shade500,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.medication_rounded), label: 'Meds'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month_rounded), label: 'Roadmap'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}

// --- 5. ASSESSMENT PAGE & RESULT LOGIC ---
class AssessmentPage extends StatefulWidget {
  const AssessmentPage({super.key});

  @override
  State<AssessmentPage> createState() => _AssessmentPageState();
}

class _AssessmentPageState extends State<AssessmentPage> {
  int currentIndex = 0;
  int riskScore = 0;

  // Logic Flags to track exact variables
  bool hasRedFlag = false;
  bool isSymptomatic = false;
  bool isCloseContact = false;
  bool isVulnerable = false;

  String? selected;
  bool _showError = false;

  final List<Map<String, dynamic>> questions = [
    {"q": "Do you have a persistent cough lasting more than 2 weeks?", "weight": 3}, // Index 0: Symptom
    {"q": "Have you noticed blood in your phlegm or mucus?", "weight": 5},          // Index 1: RED FLAG
    {"q": "Have you experienced unexplained weight loss recently?", "weight": 2},  // Index 2: Symptom
    {"q": "Do you suffer from frequent night sweats?", "weight": 2},               // Index 3: Symptom
    {"q": "Do you have persistent chest pain or pain when breathing?", "weight": 2},
    {"q": "Have you been feeling unusually tired or fatigued for weeks?", "weight": 1},
    {"q": "Do you have a recurring fever (especially in the afternoon)?", "weight": 2}, // Index 6: Symptom
    {"q": "Have you lost your appetite significantly?", "weight": 1},
    {"q": "Have you lived with or cared for someone with active TB?", "weight": 4},    // Index 8: Close Contact
    {"q": "Do you have a weakened immune system (e.g., Diabetes, HIV)?", "weight": 3}, // Index 9: Vulnerable
    {"q": "Have you recently traveled to an area with high TB rates?", "weight": 2},
    {"q": "Do you smoke or have a history of heavy tobacco use?", "weight": 1},        // Index 11: Vulnerable
  ];

  // Theme Colors
  final Color forestDark = const Color(0xFF283618);
  final Color forestMed = const Color(0xFF606C38);
  final Color mossGreen = const Color(0xFFADC178);
  final Color paleGreen = const Color(0xFFDDE5B6);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showStartDialog();
    });
  }

  Future<void> _showStartDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Start Assessment', style: TextStyle(color: forestDark, fontWeight: FontWeight.bold)),
          content: const Text(
            'This assessment will ask you a series of questions to determine your risk level for Tuberculosis. Please answer honestly.',
            style: TextStyle(color: Colors.black87),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: forestMed,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Start Now', style: TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _handleNext() {
    if (selected == null) {
      setState(() => _showError = true);
      return;
    }

    if (selected == "Yes") {
      riskScore += (questions[currentIndex]['weight'] as int);

      // --- GATE LOGIC: TRACK SPECIFIC VARIABLES ---
      
      // Gate 1: Red Flag
      if (currentIndex == 1) {
        hasRedFlag = true;
      }

      // Gate 2: WHO Primary Symptoms
      if (currentIndex == 0 || currentIndex == 2 || currentIndex == 3 || currentIndex == 6) {
        isSymptomatic = true;
      }

      // Gate 3: Close Contact
      if (currentIndex == 8) {
        isCloseContact = true;
      }

      // Gate 4: Vulnerability
      if (currentIndex == 9 || currentIndex == 11) {
        isVulnerable = true;
      }
    }

    if (currentIndex < questions.length - 1) {
      setState(() {
        currentIndex++;
        selected = null;
        _showError = false;
      });
    } else {
      _showConfirmationDialog();
    }
  }

  Future<void> _showConfirmationDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Submit Assessment?', style: TextStyle(color: forestDark, fontWeight: FontWeight.bold)),
          content: const Text(
            'Are you sure your answers are accurate? This will be used to determine your risk level.',
            style: TextStyle(color: Colors.black87),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Review', style: TextStyle(color: forestMed)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: forestMed,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Submit', style: TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.of(context).pop();
                _calculateAndNavigate();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _calculateAndNavigate() async {
    String finalRisk = "Low Risk";

    // ENHANCED LOGIC: Priority-based Risk Calculation
    // High Risk if Red Flag exists OR if symptomatic with high score
    if (hasRedFlag || (isSymptomatic && riskScore >= 10) || riskScore >= 12) {
      finalRisk = "High Risk";
    } 
    // Medium Risk if symptomatic OR vulnerable/contact with moderate score
    else if (isSymptomatic || isCloseContact || isVulnerable || riskScore >= 6) {
      finalRisk = "Medium Risk";
    }

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await Supabase.instance.client
            .from('profiles')
            .update({
              'risk_level': finalRisk,
              'is_symptomatic': isSymptomatic,
              'is_close_contact': isCloseContact,
              'is_vulnerable': isVulnerable,
            })
            .eq('id', user.id);
      }
    } catch (e) {
      debugPrint('Error updating database: $e');
    }

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/result', arguments: riskScore);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(25, 50, 25, 30),
            decoration: BoxDecoration(
              color: forestDark,
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const Text('TB Risk Assessment', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 20),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                   mainAxisAlignment: MainAxisAlignment.end,
                   children: [
                      Text('Step ${currentIndex + 1}/${questions.length}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                   ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: (currentIndex + 1) / questions.length,
                  color: mossGreen,
                  backgroundColor: Colors.white24,
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(questions[currentIndex]['q'], style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: forestDark)),
                  const SizedBox(height: 30),
                  _buildOption("Yes"),
                  const SizedBox(height: 15),
                  _buildOption("No"),
                  if (_showError) Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Text("Please select an option", style: TextStyle(color: Colors.red[700])),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(25),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: forestMed, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                onPressed: _handleNext,
                child: Text(currentIndex < questions.length - 1 ? "Next Step" : "See Results", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOption(String text) {
    bool isSel = selected == text;
    return InkWell(
      onTap: () => setState(() => selected = text),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSel ? paleGreen.withOpacity(0.3) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSel ? forestMed : Colors.grey.shade200, width: 2),
        ),
        child: Row(
          children: [
            Icon(isSel ? Icons.check_circle : Icons.circle_outlined, color: isSel ? forestMed : Colors.grey),
            const SizedBox(width: 15),
            Text(text, style: TextStyle(fontSize: 18, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}

// --- 6. MEDS PAGE (STRICT UI LOCK APPLIED) ---
class MedsPage extends StatefulWidget {
  const MedsPage({super.key});

  @override
  State<MedsPage> createState() => _MedsPageState();
}

class _MedsPageState extends State<MedsPage> {
  List<dynamic> myMeds = [];
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();
  String _viewType = 'Week';
  int _selectedIndex = 2; 

  DateTime? _treatmentStartDate;
  String? _connectionStatus;
  String _riskLevel = "Not yet assessed";

  final Color primaryGreen = const Color(0xFF2D3B1E); 
  final Color accentGreen = const Color(0xFF606C38);  
  final Color lightBg = const Color(0xFFF9F9F7);      
  final Color surfaceWhite = Colors.white;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _setupRealtimeListener();
  }

  void _setupRealtimeListener() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    Supabase.instance.client
        .channel('meds_sync')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'connections',
          filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'patient_id', value: user.id),
          callback: (payload) => _fetchData(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'profiles',
          filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'id', value: user.id),
          callback: (payload) => _fetchData(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'medications',
          filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'user_id', value: user.id),
          callback: (payload) => _fetchData(),
        )
        .subscribe();
  }

  Future<void> _fetchData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final profileData = await Supabase.instance.client
          .from('profiles')
          .select('treatment_start_date, risk_level')
          .eq('id', user.id)
          .maybeSingle();

      final connectionData = await Supabase.instance.client
          .from('connections')
          .select('status')
          .eq('patient_id', user.id)
          .maybeSingle();

      final medsData = await Supabase.instance.client
          .from('medications')
          .select()
          .eq('user_id', user.id);

      if (mounted) {
        setState(() {
          _connectionStatus = connectionData?['status'];
          _riskLevel = profileData?['risk_level'] ?? "Not yet assessed";
          
          if (profileData != null && profileData['treatment_start_date'] != null) {
            _treatmentStartDate = DateTime.parse(profileData['treatment_start_date'].toString());
          }
          
          myMeds = medsData as List<dynamic>;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching data: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleAddNewMed() {
    _showMedDialog();
  }

  Future<void> _saveMed({String? medId, required String name, required String dosage, required String time, required DateTime start, required DateTime end}) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final medData = {'user_id': user.id, 'name': name, 'dosage': dosage, 'time': time, 'start_date': start.toIso8601String(), 'end_date': end.toIso8601String(), 'is_taken': false};
    try {
      if (medId == null) { await Supabase.instance.client.from('medications').insert(medData); } 
      else { await Supabase.instance.client.from('medications').update(medData).eq('id', medId); }
      _fetchData();
    } catch (e) { debugPrint("Error saving med: $e"); }
  }

  Future<void> _deleteMed(String medId) async {
    try { await Supabase.instance.client.from('medications').delete().eq('id', medId); _fetchData(); } 
    catch (e) { debugPrint("Error deleting med: $e"); }
  }

  Future<void> _toggleMed(bool currentValue, String medId) async {
    try { await Supabase.instance.client.from('medications').update({'is_taken': !currentValue}).eq('id', medId); _fetchData(); } 
    catch (e) { debugPrint("Error toggling med: $e"); }
  }

  void _showMedDialog({Map<String, dynamic>? existingMed}) async {
    final nameController = TextEditingController(text: existingMed?['name']);
    final dosageController = TextEditingController(text: existingMed?['dosage']);
    String selectedTime = existingMed?['time'] ?? "08:00 AM";
    DateTime startDate = existingMed != null ? DateTime.parse(existingMed['start_date']) : DateTime.now();
    DateTime endDate = existingMed != null ? DateTime.parse(existingMed['end_date']) : DateTime.now().add(const Duration(days: 7));
    
    showDialog(
      context: context, 
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: surfaceWhite, 
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), 
          title: Text(
            existingMed == null ? "Add Medication" : "Edit Details", 
            style: TextStyle(color: primaryGreen, fontWeight: FontWeight.w700)
          ), 
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min, 
              children: [
                TextField(
                  controller: nameController, 
                  decoration: InputDecoration(
                    labelText: "Medicine Name", 
                    labelStyle: TextStyle(color: accentGreen), 
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: accentGreen))
                  )
                ), 
                TextField(
                  controller: dosageController, 
                  decoration: InputDecoration(
                    labelText: "Dosage (e.g. 500mg)", 
                    labelStyle: TextStyle(color: accentGreen), 
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: accentGreen))
                  )
                ), 
                const SizedBox(height: 15), 
                _buildDialogTile(
                  icon: Icons.access_time_rounded, 
                  title: "Reminder Time", 
                  value: selectedTime, 
                  onTap: () async { 
                    TimeOfDay? picked = await showTimePicker(context: context, initialTime: TimeOfDay.now()); 
                    if (picked != null) setDialogState(() => selectedTime = picked.format(context)); 
                  }
                ), 
                _buildDialogTile(
                  icon: Icons.calendar_today_rounded, 
                  title: "Treatment Duration", 
                  value: "${DateFormat('MMM d').format(startDate)} - ${DateFormat('MMM d').format(endDate)}", 
                  onTap: () async { 
                    DateTimeRange? picked = await showDateRangePicker(
                      context: context, 
                      firstDate: DateTime.now().subtract(const Duration(days: 30)), 
                      lastDate: DateTime.now().add(const Duration(days: 365))
                    ); 
                    if (picked != null) { 
                      setDialogState(() { 
                        startDate = picked.start; 
                        endDate = picked.end; 
                      }); 
                    } 
                  }
                ), 
              ]
            )
          ), 
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: Text("Cancel", style: TextStyle(color: Colors.grey[600]))
            ), 
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: accentGreen, 
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), 
                elevation: 0
              ), 
              onPressed: () { 
                _saveMed(
                  medId: existingMed?['id']?.toString(), 
                  name: nameController.text, 
                  dosage: dosageController.text, 
                  time: selectedTime, 
                  start: startDate, 
                  end: endDate
                ); 
                Navigator.pop(context); 
              }, 
              child: const Text("Save Task", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600))
            )
          ]
        )
      )
    );
  }

  Widget _buildDialogTile({required IconData icon, required String title, required String value, required VoidCallback onTap}) {
    return ListTile(contentPadding: EdgeInsets.zero, leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: lightBg, borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: accentGreen, size: 20)), title: Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)), subtitle: Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: primaryGreen)), onTap: onTap);
  }

  @override
  Widget build(BuildContext context) {
    bool hasTakenAssessment = _riskLevel != "Not yet assessed";
    bool isVerifiedByDoctor = _connectionStatus == 'active';
    bool isUnlocked = hasTakenAssessment && isVerifiedByDoctor;

    return Scaffold(
      backgroundColor: lightBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent, 
        elevation: 0, 
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: primaryGreen), 
          onPressed: () => Navigator.of(context).pop()
        ), 
        title: Row(
          children: [
            Icon(Icons.favorite_rounded, color: accentGreen, size: 28), 
            const SizedBox(width: 10), 
            Text('TB HealthCare', style: TextStyle(fontWeight: FontWeight.w800, color: primaryGreen, fontSize: 20))
          ]
        ),
      ),
      
      body: _isLoading 
        ? Center(child: CircularProgressIndicator(color: accentGreen)) 
        : isUnlocked 
            ? _buildUnlockedContent() 
            : _buildLockedUI(hasTakenAssessment, isVerifiedByDoctor),

      floatingActionButton: isUnlocked 
        ? FloatingActionButton(backgroundColor: primaryGreen, onPressed: _handleAddNewMed, child: const Icon(Icons.add, color: Colors.white))
        : null,

      bottomNavigationBar: BottomNavigationBar(currentIndex: _selectedIndex, onTap: (index) { if (index == _selectedIndex) return; switch (index) { case 0: Navigator.pushReplacementNamed(context, '/dashboard'); break; case 1: Navigator.pushNamed(context, '/assess'); break; case 3: Navigator.pushNamed(context, '/followup'); break; case 4: Navigator.pushNamed(context, '/chat'); break; } setState(() => _selectedIndex = index); }, type: BottomNavigationBarType.fixed, backgroundColor: surfaceWhite, selectedItemColor: accentGreen, unselectedItemColor: Colors.grey, items: const [BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'), BottomNavigationBarItem(icon: Icon(Icons.assignment_outlined), label: 'Assess'), BottomNavigationBarItem(icon: Icon(Icons.medication_rounded), label: 'Meds'), BottomNavigationBarItem(icon: Icon(Icons.calendar_month_outlined), label: 'Follow-up'), BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline_rounded), label: 'Chat')]),
    );
  }

  Widget _buildUnlockedContent() {
    return Column(
      children: [
        _buildModernHeader(), 
        const SizedBox(height: 15), 
        _buildViewSelector(), 
        const SizedBox(height: 15), 
        _buildCalendarSection(), 
        const SizedBox(height: 20), 
        Expanded(
          child: Container(
            width: double.infinity, 
            decoration: BoxDecoration(color: surfaceWhite, borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]), 
            child: _buildMedList()
          )
        )
      ]
    );
  }

  Widget _buildViewSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 45,
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.12),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          children: ['Day', 'Week', 'Month'].map((type) {
            bool isSelected = _viewType == type;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _viewType = type),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: isSelected 
                        ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))]
                        : [],
                  ),
                  child: Center(
                    child: Text(
                      type,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        color: isSelected ? primaryGreen : Colors.grey[500],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildLockedUI(bool hasAssessed, bool isVerified) {
    String title = "Diary Locked";
    String message = "To ensure your safety, the Medication Diary is locked until you complete your assessment and link with your doctor.";
    IconData icon = Icons.lock_outline_rounded;

    if (!hasAssessed) {
      title = "Assessment Required";
      message = "Please complete the Risk Assessment first to unlock your health features.";
      icon = Icons.assignment_late_outlined;
    } else if (!isVerified) {
      title = "Verification Pending";
      message = "Assessment complete! Now, please link your account to your clinic via the Dashboard and wait for doctor approval.";
      icon = Icons.hourglass_empty_rounded;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20), 
              decoration: BoxDecoration(color: accentGreen.withOpacity(0.1), shape: BoxShape.circle), 
              child: Icon(icon, size: 50, color: primaryGreen)
            ),
            const SizedBox(height: 30),
            Text(title, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: primaryGreen)),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 40),
            ElevatedButton(
                onPressed: () => Navigator.pushReplacementNamed(context, hasAssessed ? '/dashboard' : '/assess'), 
                style: ElevatedButton.styleFrom(backgroundColor: primaryGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15)), 
                child: Text(hasAssessed ? "Go to Dashboard" : "Take Assessment", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernHeader() { 
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20), 
      padding: const EdgeInsets.all(20), 
      width: double.infinity, 
      decoration: BoxDecoration(gradient: LinearGradient(colors: [primaryGreen, accentGreen], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(24)), 
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, 
        children: [
          const Text('Medication Diary', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)), 
          const SizedBox(height: 4), 
          Text('Keep track of your TB treatment journey.', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)), 
          const SizedBox(height: 15), 
          Row(
            children: [
              const Icon(Icons.calendar_today, color: Colors.white, size: 14), 
              const SizedBox(width: 8), 
              Text(DateFormat('MMMM dd, yyyy').format(_selectedDate), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))
            ]
          )
        ]
      )
    ); 
  }

  Widget _buildCalendarSection() { 
    if (_viewType == 'Month') return SizedBox(height: 350, child: _buildMonthGrid()); 
    if (_viewType == 'Day') return Center(child: SizedBox(height: 90, child: _buildDateCard(_selectedDate, true))); 
    return SizedBox(height: 90, child: _buildWeekStrip()); 
  }

  Widget _buildWeekStrip() { 
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 15), 
      scrollDirection: Axis.horizontal, 
      itemCount: 14, 
      itemBuilder: (context, index) { 
        DateTime date = DateTime.now().add(Duration(days: index - 3)); 
        bool isSelected = date.day == _selectedDate.day && date.month == _selectedDate.month; 
        return _buildDateCard(date, isSelected); 
      }
    ); 
  }

  Widget _buildMonthGrid() { 
    int daysInMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 0).day; 
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20), 
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7, 
        mainAxisSpacing: 8, 
        crossAxisSpacing: 8,
        childAspectRatio: 0.75, 
      ), 
      itemCount: daysInMonth, 
      itemBuilder: (context, index) { 
        DateTime date = DateTime(_selectedDate.year, _selectedDate.month, index + 1); 
        bool isSelected = date.day == _selectedDate.day && date.month == _selectedDate.month; 
        return _buildDateCard(date, isSelected, compact: true); 
      }
    ); 
  }

  Widget _buildDateCard(DateTime date, bool isSelected, {bool compact = false}) { 
    return GestureDetector(
      onTap: () => setState(() => _selectedDate = date), 
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200), 
        width: compact ? null : 65, 
        margin: EdgeInsets.symmetric(horizontal: compact ? 2 : 6, vertical: compact ? 2 : 4), 
        decoration: BoxDecoration(
          color: isSelected ? accentGreen : surfaceWhite, 
          borderRadius: BorderRadius.circular(16), 
          boxShadow: isSelected ? [BoxShadow(color: accentGreen.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : [], 
          border: Border.all(color: isSelected ? accentGreen : Colors.grey.withOpacity(0.1))
        ), 
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, 
          children: [
            Text(
              DateFormat('E').format(date).toUpperCase(), 
              style: TextStyle(fontSize: compact ? 8 : 10, fontWeight: FontWeight.w800, color: isSelected ? Colors.white70 : Colors.grey)
            ), 
            const SizedBox(height: 2), 
            Text(
              date.day.toString(), 
              style: TextStyle(fontSize: compact ? 14 : 18, fontWeight: FontWeight.w700, color: isSelected ? Colors.white : primaryGreen)
            )
          ]
        )
      )
    ); 
  }

  Widget _buildMedList() { 
    final filteredMeds = myMeds.where((med) { 
      DateTime start = DateTime.parse(med['start_date']); 
      DateTime end = DateTime.parse(med['end_date']); 
      DateTime startDate = DateTime(start.year, start.month, start.day); 
      DateTime endDate = DateTime(end.year, end.month, end.day); 
      DateTime selectedDate = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day); 
      return !selectedDate.isBefore(startDate) && !selectedDate.isAfter(endDate); 
    }).toList(); 

    if (filteredMeds.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center, 
        children: [
          Icon(Icons.spa_outlined, size: 60, color: Colors.grey[300]), 
          const SizedBox(height: 10), 
          Text("Rest easy. No meds today.", style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.w500))
        ]
      ); 
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 100), 
      itemCount: filteredMeds.length, 
      itemBuilder: (context, index) { 
        final med = filteredMeds[index]; 
        bool isTaken = med['is_taken'] ?? false; 
        return Container(
          margin: const EdgeInsets.only(bottom: 16), 
          padding: const EdgeInsets.all(12), 
          decoration: BoxDecoration(
            color: isTaken ? lightBg.withOpacity(0.5) : surfaceWhite, 
            borderRadius: BorderRadius.circular(20), 
            border: Border.all(color: isTaken ? Colors.transparent : Colors.grey.withOpacity(0.1))
          ), 
          child: Row(
            children: [
              GestureDetector(
                onTap: () => _toggleMed(isTaken, med['id'].toString()), 
                child: Container(
                  padding: const EdgeInsets.all(10), 
                  decoration: BoxDecoration(color: isTaken ? accentGreen : lightBg, shape: BoxShape.circle), 
                  child: Icon(isTaken ? Icons.check : Icons.medication_rounded, color: isTaken ? Colors.white : accentGreen, size: 24)
                )
              ), 
              const SizedBox(width: 15), 
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, 
                  children: [
                    Text(med['name'], style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, decoration: isTaken ? TextDecoration.lineThrough : null, color: isTaken ? Colors.grey : primaryGreen)), 
                    Text('${med['dosage']} • ${med['time']}', style: TextStyle(fontSize: 13, color: isTaken ? Colors.grey[400] : Colors.grey[600]))
                  ]
                )
              ), 
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.grey), 
                onSelected: (value) { 
                  if (value == 'edit') _showMedDialog(existingMed: med); 
                  if (value == 'delete') _deleteMed(med['id'].toString()); 
                }, 
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')), 
                  const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red)))
                ]
              )
            ]
          )
        ); 
      }
    ); 
  }
}

//FOLLOWUP PAGE
class FollowUpPage extends StatefulWidget {
  const FollowUpPage({super.key});

  @override
  State<FollowUpPage> createState() => _FollowUpPageState();
}

class _FollowUpPageState extends State<FollowUpPage> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;

  // CONNECTION STATE
  String? _connectionStatus;
  String? _linkedDoctorId;
  String? _doctorName;
  DateTime? _treatmentStartDate; 

  // DATA
  int _streakDays = 0;
  List<Map<String, dynamic>> _doctorNotes = [];
  List<Map<String, dynamic>> _appointments = [];
  
  // CRUD INPUTS
  final TextEditingController _noteController = TextEditingController();
  String _selectedCategory = 'Question'; 
  final List<String> _categories = ['Question', 'Symptom', 'Side Effect', 'Other'];

  // THEME PALETTE
  final Color kPrimaryGreen = const Color(0xFF283618);
  final Color kSecondaryGreen = const Color(0xFF606C38);
  final Color kCreamAccent = const Color(0xFFFEFAE0);
  final Color kWhite = Colors.white;
  final Color kSoftGrey = const Color(0xFFF8F9FA);

  @override
  void initState() {
    super.initState();
    _checkConnectionAndLoad();
    _setupRealtimeListener();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  // --- REAL-TIME LISTENER ---
  void _setupRealtimeListener() {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    _supabase
      .channel('followup_sync')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'profiles',
        filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'id', value: user.id),
        callback: (payload) => _checkConnectionAndLoad(),
      )
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'connections',
        filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'patient_id', value: user.id),
        callback: (payload) => _checkConnectionAndLoad(),
      )
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'roadmap',
        filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'patient_id', value: user.id),
        callback: (payload) => _fetchAppointments(), 
      )
      .subscribe();
  }

  // --- INIT DATA ---
  Future<void> _checkConnectionAndLoad() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // 1. Check connection status (Handshake)
      final connectionData = await _supabase
          .from('connections')
          .select('status, doctor_id, profiles!fk_doctor(full_name)')
          .eq('patient_id', user.id)
          .maybeSingle();

      // 2. Check treatment dates (Prescription)
      final profileData = await _supabase
          .from('profiles')
          .select('treatment_start_date') 
          .eq('id', user.id)
          .maybeSingle(); 

      if (mounted) {
        setState(() {
          _connectionStatus = connectionData?['status'];

          if (connectionData != null) {
            _linkedDoctorId = connectionData['doctor_id'];
            final doctorProfile = connectionData['profiles'] as Map<String, dynamic>?;
            _doctorName = doctorProfile?['full_name'];
          } else {
            _linkedDoctorId = null;
            _doctorName = null;
          }

          if (profileData != null && profileData['treatment_start_date'] != null) {
             _treatmentStartDate = DateTime.tryParse(profileData['treatment_start_date'].toString());
          } else {
             _treatmentStartDate = null;
          }
        });
      }

      // 3. Load content if unlocked
      if (_connectionStatus == 'active' && _treatmentStartDate != null) {
        await Future.wait([
          _fetchStreak(),
          _fetchNotes(), 
          _fetchAppointments(),
        ]);
      }
    } catch (e) {
      debugPrint('Init Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- DATA FETCHING ---
  Future<void> _fetchStreak() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      final response = await _supabase.rpc('get_medication_streak', params: {'p_user_id': userId});
      if (mounted) setState(() => _streakDays = response as int);
    } catch (e) { debugPrint('Streak Error: $e'); }
  }

  Future<void> _fetchNotes() async {
    try {
      final data = await _supabase.from('doctor_notes')
          .select()
          .eq('user_id', _supabase.auth.currentUser!.id)
          .eq('is_checked', false) 
          .order('created_at', ascending: false);
      if (mounted) setState(() => _doctorNotes = List<Map<String, dynamic>>.from(data));
    } catch (e) { debugPrint('Notes Error: $e'); }
  }

  Future<void> _fetchAppointments() async {
    try {
      final data = await _supabase.from('roadmap')
          .select()
          .eq('patient_id', _supabase.auth.currentUser!.id)
          .neq('status', 'completed') 
          .order('appointment_date', ascending: true);
      if (mounted) setState(() => _appointments = List<Map<String, dynamic>>.from(data));
    } catch (e) { debugPrint('Appt Error: $e'); }
  }

  // --- CRUD OPERATIONS ---
  Future<void> _addNote() async {
    if (_treatmentStartDate == null) return; 
    if (_noteController.text.isEmpty) return;
    final text = _noteController.text;
    final category = _selectedCategory;
    _noteController.clear();
    setState(() => _selectedCategory = 'Question');
    try {
      await _supabase.from('doctor_notes').insert({'note_text': text, 'category': category, 'user_id': _supabase.auth.currentUser!.id, 'is_checked': false});
      _fetchNotes();
    } catch (e) { debugPrint('Add Note Error: $e'); }
  }

  Future<void> _deleteNote(String id) async { 
    if (_treatmentStartDate == null) return; 
    await _supabase.from('doctor_notes').delete().eq('id', id); 
    _fetchNotes(); 
  }

  Future<void> _toggleNote(int index) async {
    if (_treatmentStartDate == null) return; 
    setState(() { _doctorNotes[index]['is_checked'] = true; });
    await Future.delayed(const Duration(milliseconds: 500));
    final noteId = _doctorNotes[index]['id'];
    await _supabase.from('doctor_notes').update({'is_checked': true}).eq('id', noteId);
    if (mounted) { setState(() { _doctorNotes.removeAt(index); }); }
  }

  Future<void> _deleteAppointment(String id) async { 
    if (_treatmentStartDate == null) return; 
    await _supabase.from('roadmap').delete().eq('id', id);
    _fetchAppointments(); 
  }

  Future<void> _editNoteDialog(Map<String, dynamic> note) async {
    if (_treatmentStartDate == null) return; 
    final editController = TextEditingController(text: note['note_text']);
    String editCategory = note['category'] ?? 'Question';
    
    await showDialog(
      context: context, 
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), 
          title: Text("Edit Note", style: TextStyle(color: kPrimaryGreen, fontWeight: FontWeight.bold)), 
          content: Column(
            mainAxisSize: MainAxisSize.min, 
            children: [
              Wrap(
                spacing: 8, 
                children: _categories.map((cat) { 
                  final isSelected = editCategory == cat; 
                  return ChoiceChip(
                    label: Text(cat), 
                    selected: isSelected, 
                    selectedColor: kSecondaryGreen, 
                    labelStyle: TextStyle(color: isSelected ? Colors.white : kPrimaryGreen, fontSize: 12), 
                    onSelected: (val) => setDialogState(() => editCategory = cat)
                  ); 
                }).toList()
              ), 
              const SizedBox(height: 15), 
              TextField(
                controller: editController, 
                maxLines: 3, 
                decoration: InputDecoration(
                  hintText: "Update your note...", 
                  filled: true, 
                  fillColor: kSoftGrey, 
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
                )
              )
            ]
          ), 
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.grey))), 
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: kPrimaryGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), 
              onPressed: () async { 
                if (editController.text.isNotEmpty) { 
                  await _supabase.from('doctor_notes').update({'note_text': editController.text, 'category': editCategory}).eq('id', note['id']); 
                  _fetchNotes(); 
                  if (context.mounted) Navigator.pop(context); 
                } 
              }, 
              child: const Text("Save Changes", style: TextStyle(color: Colors.white))
            )
          ]
        )
      )
    );
  }

  void _showAppointmentModal({Map<String, dynamic>? apptToEdit}) { 
    if (_treatmentStartDate == null) return; 
    final isEditing = apptToEdit != null;
    
    // Changed to handle the actual title of the milestone
    final titleController = TextEditingController(text: isEditing ? (apptToEdit['title'] ?? "") : "Follow-up Checkup");
    final locController = TextEditingController(text: isEditing ? (apptToEdit['location'] ?? "") : "");
    
    DateTime? selectedDate = isEditing ? DateTime.tryParse(apptToEdit['appointment_date']) : null;
    TimeOfDay? selectedTime;
    
    if (isEditing && apptToEdit['appointment_time'] != null) { 
      final parts = apptToEdit['appointment_time'].toString().split(':'); 
      selectedTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1])); 
    } else {
      selectedTime = const TimeOfDay(hour: 8, minute: 0);
    }
    
    bool isSaving = false;
    
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: kWhite, 
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(35))), 
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 25, right: 25, top: 20), 
          child: Column(
            mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, 
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))), 
              const SizedBox(height: 25), 
              Text(isEditing ? "Edit Milestone" : "Add Roadmap Milestone", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: kPrimaryGreen)), 
              const SizedBox(height: 20), 
              _buildModernField(titleController, "Milestone Title", Icons.event_note_outlined), 
              const SizedBox(height: 15), 
              _buildModernField(locController, "Location / Goal", Icons.flag_outlined), 
              const SizedBox(height: 20), 
              Row(children: [
                Expanded(child: _buildPickerTile(
                  label: selectedDate == null ? "Select Date" : DateFormat('MMM dd, yyyy').format(selectedDate!), 
                  icon: Icons.calendar_month_rounded, 
                  onTap: () async { 
                    final picked = await showDatePicker(context: context, initialDate: selectedDate ?? DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2030)); 
                    if (picked != null) setModalState(() => selectedDate = picked); 
                  }
                )), 
                const SizedBox(width: 15), 
                Expanded(child: _buildPickerTile(
                  label: selectedTime == null ? "Select Time" : selectedTime!.format(context), 
                  icon: Icons.access_time_rounded, 
                  onTap: () async { 
                    final picked = await showTimePicker(context: context, initialTime: selectedTime ?? TimeOfDay.now()); 
                    if (picked != null) setModalState(() => selectedTime = picked); 
                  }
                ))
              ]), 
              const SizedBox(height: 30), 
              SizedBox(width: double.infinity, child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: kPrimaryGreen, padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))), 
                onPressed: isSaving ? null : () async { 
                  if (titleController.text.isNotEmpty && selectedDate != null && selectedTime != null) { 
                    setModalState(() => isSaving = true); 
                    try { 
                      final timeString = '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}:00'; 
                      final Map<String, dynamic> appointmentData = {
                        'patient_id': _supabase.auth.currentUser!.id, 
                        'doctor_id': _linkedDoctorId, 
                        'title': titleController.text, // Now correctly saving the title
                        'appointment_date': DateFormat('yyyy-MM-dd').format(selectedDate!), 
                        'appointment_time': timeString, 
                        'location': locController.text, 
                        'status': 'scheduled',
                        'type': isEditing ? apptToEdit['type'] : 'manual' // Preserve type if editing
                      }; 
                      if (isEditing) { await _supabase.from('roadmap').update(appointmentData).eq('id', apptToEdit['id']); } 
                      else { await _supabase.from('roadmap').insert(appointmentData); } 
                      await _fetchAppointments(); 
                      if (context.mounted) Navigator.pop(context); 
                    } catch (e) { setModalState(() => isSaving = false); } 
                  } 
                }, 
                child: isSaving ? const CircularProgressIndicator(color: Colors.white) : Text(isEditing ? "Update Milestone" : "Add Milestone", style: TextStyle(color: kWhite, fontWeight: FontWeight.bold))
              )), 
              const SizedBox(height: 40)
            ]
          )
        )
      )
    );
  }

  // --- UI BUILD ---
  @override
  Widget build(BuildContext context) {
    bool isUnlocked = _connectionStatus == 'active' && _treatmentStartDate != null;

    return Scaffold(
      backgroundColor: kWhite,
      appBar: AppBar(
        backgroundColor: kWhite, elevation: 0, centerTitle: true,
        leading: IconButton(icon: Icon(Icons.arrow_back_ios_new_rounded, color: kPrimaryGreen, size: 20), onPressed: () => Navigator.of(context).pop()),
        title: Text('Follow-up Care', style: TextStyle(fontWeight: FontWeight.w900, color: kPrimaryGreen, fontSize: 20)),
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator(color: kSecondaryGreen)) 
        : isUnlocked ? _buildUnlockedContent() : _buildLockedState(),
    );
  }

  Widget _buildUnlockedContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRecoveryRoadmap(), 
          const SizedBox(height: 25),
          _buildStreakCard(),
          const SizedBox(height: 35),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Roadmap Milestones", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: kPrimaryGreen)),
              GestureDetector(
                onTap: () => _showAppointmentModal(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: kSecondaryGreen, shape: BoxShape.circle),
                  child: const Icon(Icons.add, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          if (_appointments.isEmpty) _buildEmptyState("No milestones scheduled yet."),
          
          // Updated to pass the correct parameters, including title and type
          ..._appointments.map((appt) => _buildDismissibleWrapper(
            id: appt['id'].toString(), 
            onDismiss: () => _deleteAppointment(appt['id'].toString()), 
            child: GestureDetector(
              onTap: () => _showAppointmentModal(apptToEdit: appt),
              child: _buildAppointmentCard(
                appt['title'] ?? _doctorName ?? "Follow-up", 
                appt['appointment_date'], 
                appt['appointment_time'] ?? "08:00:00", 
                appt['location'] ?? "Clinic",
                appt['type'] ?? "manual"
              )
            )
          )),
          const SizedBox(height: 40),
          Text("CONSULTATION NOTES", style: TextStyle(color: kSecondaryGreen, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
          const SizedBox(height: 15),
          _buildNoteInputArea(), 
          const SizedBox(height: 25),
          if (_doctorNotes.isEmpty) _buildEmptyState("No notes added yet."),
          ListView.builder(
            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            itemCount: _doctorNotes.length,
            itemBuilder: (context, index) {
              final note = _doctorNotes[index];
              return InkWell(onLongPress: () => _editNoteDialog(note), child: _buildNoteTile(note, index));
            },
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildLockedState() {
    bool isPending = _connectionStatus == 'pending';
    bool isAwaitingPrescription = _connectionStatus == 'active' && _treatmentStartDate == null;

    return Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: kCreamAccent, shape: BoxShape.circle), 
            child: Icon(isAwaitingPrescription ? Icons.medical_services_outlined : Icons.lock_outline_rounded, size: 50, color: kPrimaryGreen)
          ),
          const SizedBox(height: 30),
          Text(isAwaitingPrescription ? "Awaiting Prescription" : (isPending ? "Waiting for Approval" : "Feature Locked"), 
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: kPrimaryGreen)),
          const SizedBox(height: 10),
          Text(isAwaitingPrescription 
            ? "Dr. ${(_doctorName ?? "your doctor")} has linked your account. Once your treatment dates are set, your roadmap will appear."
            : (isPending ? "Your request is being reviewed by the clinic." : "Link with your doctor to coordinate visits."), 
            textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(25), decoration: BoxDecoration(color: kSoftGrey, borderRadius: BorderRadius.circular(25)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("YOUR TREATMENT JOURNEY", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: kSecondaryGreen, letterSpacing: 1.2)),
              const SizedBox(height: 25),
              _buildStep("Account Created", true), 
              _buildStep("Risk Assessment", true), 
              _buildStep("Link to Clinic", isPending || isAwaitingPrescription), 
              _buildStep("Unlock Roadmap & Diary", false, isLast: true),
            ]),
          ),
          const SizedBox(height: 30),
          if (!isPending && !isAwaitingPrescription) ElevatedButton(onPressed: () => Navigator.pushReplacementNamed(context, '/dashboard'), style: ElevatedButton.styleFrom(backgroundColor: kPrimaryGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15)), child: const Text("Go to Dashboard", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  // --- UI COMPONENTS ---
  Widget _buildRecoveryRoadmap() {
    int daysPassed = 0;
    if (_treatmentStartDate != null) { daysPassed = DateTime.now().difference(_treatmentStartDate!).inDays; }
    double progress = (daysPassed / 180).clamp(0.0, 1.0); 
    int month = (daysPassed / 30).ceil().clamp(1, 6);
    return Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: kWhite, borderRadius: BorderRadius.circular(25), border: Border.all(color: kSoftGrey, width: 2)), 
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("Treatment Roadmap", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: kPrimaryGreen)), 
            Text("Started: ${DateFormat('MMM dd, yyyy').format(_treatmentStartDate ?? DateTime.now())}", style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold))
          ]), 
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: kCreamAccent, borderRadius: BorderRadius.circular(10)), child: Text("Month $month of 6", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: kSecondaryGreen)))
        ]), 
        const SizedBox(height: 15), 
        ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: progress, minHeight: 12, backgroundColor: kSoftGrey, color: kSecondaryGreen)), 
        const SizedBox(height: 10), 
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("${(progress * 100).toInt()}% Complete", style: TextStyle(fontSize: 12, color: kPrimaryGreen, fontWeight: FontWeight.bold)), Text("${180 - daysPassed} days left", style: const TextStyle(fontSize: 11, color: Colors.grey))])
      ]));
  }

  Widget _buildStep(String title, bool isActive, {bool isLast = false}) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Column(children: [
        Icon(isActive ? Icons.check_circle : Icons.circle_outlined, color: isActive ? kPrimaryGreen : Colors.grey, size: 22), 
        if (!isLast) Container(height: 30, width: 2, color: isActive ? kPrimaryGreen : Colors.grey.withOpacity(0.3))
      ]), 
      const SizedBox(width: 15), 
      Text(title, style: TextStyle(fontWeight: isActive ? FontWeight.bold : FontWeight.normal, color: isActive ? kPrimaryGreen : Colors.grey, fontSize: 15))
    ]);
  }

  Widget _buildStreakCard() {
    return Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(gradient: LinearGradient(colors: [kSecondaryGreen, kPrimaryGreen], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(30)), 
      child: Row(children: [
        Container(height: 60, width: 60, decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle), child: const Icon(Icons.bolt_rounded, color: Colors.orangeAccent, size: 35)), 
        const SizedBox(width: 20), 
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('$_streakDays Day Streak', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 26)), const Text('Keep going!', style: TextStyle(color: Colors.white70, fontSize: 14))])
      ]));
  }

  // Updated to include DOH Protocol UI styling
  Widget _buildAppointmentCard(String title, String date, String time, String loc, String type) {
    bool isProtocol = type == 'protocol';
    
    // Formatting time safely
    String displayTime = time;
    if (time.contains(':')) {
      final parts = time.split(':');
      if (parts.length >= 2) {
        final hr = int.parse(parts[0]);
        final min = parts[1];
        final period = hr >= 12 ? 'PM' : 'AM';
        final formattedHr = hr > 12 ? hr - 12 : (hr == 0 ? 12 : hr);
        displayTime = "$formattedHr:$min $period";
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 15), 
      padding: const EdgeInsets.all(20), 
      decoration: BoxDecoration(
        color: kWhite, 
        borderRadius: BorderRadius.circular(25), 
        border: Border.all(
          color: isProtocol ? kSecondaryGreen.withOpacity(0.5) : kSoftGrey, 
          width: 2
        )
      ), 
      child: Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15), 
          decoration: BoxDecoration(
            color: isProtocol ? kSecondaryGreen.withOpacity(0.1) : kCreamAccent, 
            borderRadius: BorderRadius.circular(15)
          ), 
          child: Column(children: [
            Text(date.split('-')[2], style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: kPrimaryGreen)), 
            Text(DateFormat('MMM').format(DateTime.parse(date)).toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: kSecondaryGreen))
          ])
        ), 
        const SizedBox(width: 15), 
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, 
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title, 
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: kPrimaryGreen),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    )
                  ),
                  if (isProtocol) 
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(6)),
                      child: Text("DOH Protocol", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.orange.shade900)),
                    )
                ],
              ),
              const SizedBox(height: 6),
              Text("$displayTime • $loc", style: const TextStyle(color: Colors.grey, fontSize: 12))
            ]
          )
        )
      ])
    );
  }

  Widget _buildNoteInputArea() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: _categories.map((cat) { 
        final isSelected = _selectedCategory == cat; 
        return Padding(padding: const EdgeInsets.only(right: 8.0), child: ChoiceChip(label: Text(cat), selected: isSelected, selectedColor: kPrimaryGreen, onSelected: (val) => setState(() => _selectedCategory = cat))); }).toList())), 
      const SizedBox(height: 10), 
      Container(decoration: BoxDecoration(color: kSoftGrey, borderRadius: BorderRadius.circular(20)), 
        child: TextField(controller: _noteController, decoration: InputDecoration(hintText: "Add a $_selectedCategory...", border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15), suffixIcon: IconButton(icon: CircleAvatar(backgroundColor: kPrimaryGreen, child: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 20)), onPressed: _addNote))))
    ]);
  }

  Widget _buildNoteTile(Map<String, dynamic> note, int index) {
    bool isChecked = note['is_checked'] ?? false;
    String category = note['category'] ?? 'Question';
    Color catColor = category == 'Symptom' ? const Color(0xFFE76F51) : (category == 'Question' ? const Color(0xFF2A9D8F) : const Color(0xFFE9C46A)); 
    return AnimatedOpacity(opacity: isChecked ? 0.0 : 1.0, duration: const Duration(milliseconds: 500), 
      child: _buildDismissibleWrapper(id: note['id'].toString(), onDismiss: () => _deleteNote(note['id'].toString()), 
        child: Container(margin: const EdgeInsets.only(bottom: 10), decoration: BoxDecoration(color: kWhite, borderRadius: BorderRadius.circular(18), border: Border.all(color: kSoftGrey, width: 1)), 
          child: CheckboxListTile(activeColor: kSecondaryGreen, value: isChecked, onChanged: (bool? value) => _toggleNote(index), 
            title: Row(children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: catColor.withOpacity(0.2), borderRadius: BorderRadius.circular(8)), child: Text(category, style: TextStyle(color: catColor, fontSize: 10, fontWeight: FontWeight.bold))), 
              const SizedBox(width: 8), 
              Expanded(child: Text(note['note_text'], style: TextStyle(color: kPrimaryGreen, fontWeight: FontWeight.w600, fontSize: 15)))
            ]), controlAffinity: ListTileControlAffinity.leading))));
  }

  Widget _buildDismissibleWrapper({required String id, required VoidCallback onDismiss, required Widget child}) { 
    return Dismissible(key: Key(id), direction: DismissDirection.endToStart, onDismissed: (dir) => onDismiss(), background: Container(decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(20)), alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 25), child: const Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 30)), child: child); 
  }

  Widget _buildEmptyState(String msg) { return Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 20), child: Text(msg, style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)))); }
  Widget _buildModernField(TextEditingController controller, String label, IconData icon) { return TextField(controller: controller, decoration: InputDecoration(prefixIcon: Icon(icon, color: kSecondaryGreen), labelText: label, filled: true, fillColor: kSoftGrey, border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none))); }
  Widget _buildPickerTile({required String label, required IconData icon, required VoidCallback onTap}) { return InkWell(onTap: onTap, child: Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: kSoftGrey, borderRadius: BorderRadius.circular(18)), child: Column(children: [Icon(icon, color: kSecondaryGreen), const SizedBox(height: 8), Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: kPrimaryGreen))]))); }
}



// --- 8. CHATBOT PAGE ---
class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final List<ChatMessage> _messages = [
    ChatMessage(text: "Hello! I am TEREA, your health assistant. How can I help you today?", isUser: false),
  ];
  final TextEditingController _controller = TextEditingController();

  void _sendMessage() {
    if (_controller.text.isEmpty) return;
    setState(() {
      _messages.add(ChatMessage(text: _controller.text, isUser: true));
      Future.delayed(const Duration(seconds: 1), () {
        setState(() {
          _messages.add(ChatMessage(text: "I understand. Let me look into that for you.", isUser: false));
        });
      });
    });
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(children: [_buildLogo(size: 32), const SizedBox(width: 10), const Text('TEREA Chat')]),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return Align(
                  alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                    decoration: BoxDecoration(
                      color: msg.isUser ? const Color(0xFF606C38) : Colors.white,
                      borderRadius: BorderRadius.circular(15).copyWith(
                        bottomRight: msg.isUser ? Radius.zero : const Radius.circular(15),
                        bottomLeft: msg.isUser ? const Radius.circular(15) : Radius.zero,
                      ),
                    ),
                    child: Text(msg.text, style: TextStyle(color: msg.isUser ? Colors.white : Colors.black87)),
                  ),
                );
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(4, context),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: "Ask something...",
                filled: true, fillColor: const Color(0xFFFEFAE0),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              ),
            ),
          ),
          const SizedBox(width: 10),
          CircleAvatar(
            backgroundColor: const Color(0xFF606C38),
            child: IconButton(icon: const Icon(Icons.send, color: Colors.white), onPressed: _sendMessage),
          )
        ],
      ),
    );
  }
}

// --- 9. SETTINGS PAGE ---
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _supabase = Supabase.instance.client;
  String _username = "Loading...";
  String _email = "";
  String? _avatarUrl;
  bool _isLoading = true;

  // Theme Palette
  final Color primaryGreen = const Color(0xFF2D3B1E); // Dark Forest
  final Color accentGreen = const Color(0xFF606C38);  // Olive
  final Color lightBg = const Color(0xFFF9F9F7);      // Off-white background
  final Color surfaceWhite = Colors.white;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  // --- DATA LOGIC (Unchanged) ---
  Future<void> _loadUserProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        setState(() => _email = user.email ?? "");
        
        final data = await _supabase
            .from('profiles')
            .select()
            .eq('id', user.id)
            .single();

        setState(() {
          _username = data['full_name'] ?? "New User";
          _avatarUrl = data['avatar_url'];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateUsername() async {
    final controller = TextEditingController(text: _username);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: surfaceWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text("Update Username", style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: "Enter new username",
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: accentGreen)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel", style: TextStyle(color: Colors.grey[600]))),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                await _supabase.from('profiles').update({'full_name': newName}).eq('id', _supabase.auth.currentUser!.id);
                setState(() => _username = newName);
                if (mounted) Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: accentGreen, elevation: 0),
            child: const Text("Save", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  Future<void> _uploadPhoto() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final fileBytes = file.bytes; 
      final userId = _supabase.auth.currentUser!.id;
      final fileName = '$userId/profile_${DateTime.now().millisecondsSinceEpoch}.png';

      if (fileBytes != null) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Uploading photo...")));

        await _supabase.storage.from('avatars').uploadBinary(
          fileName,
          fileBytes,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
        );

        final String publicUrl = _supabase.storage.from('avatars').getPublicUrl(fileName);

        await _supabase.from('profiles').update({'avatar_url': publicUrl}).eq('id', userId);

        setState(() => _avatarUrl = publicUrl);
        
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Photo updated!")));
      }
    } catch (e) {
      debugPrint('Upload failed: $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Upload failed. Check Storage permissions.")));
    }
  }

  // --- UI BUILD ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: primaryGreen, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Settings', style: TextStyle(fontWeight: FontWeight.w800, color: primaryGreen, fontSize: 20)),
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator(color: accentGreen))
        : SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              children: [
                _buildModernProfileCard(),
                const SizedBox(height: 30),
                _buildSettingsGroup("General", [
                  _buildSettingsTile(Icons.person_outline_rounded, "Edit Username", onTap: _updateUsername),
                  _buildSettingsTile(Icons.notifications_none_rounded, "Notifications", 
                      trailing: Switch(
                        value: true, 
                        activeColor: Colors.white, 
                        activeTrackColor: accentGreen,
                        onChanged: (v){}
                      )),
                  _buildSettingsTile(Icons.language_rounded, "Language", subtext: "English"),
                ]),
                const SizedBox(height: 25),
                _buildSettingsGroup("Privacy & Support", [
                  _buildSettingsTile(Icons.lock_outline_rounded, "Privacy Policy"),
                  _buildSettingsTile(Icons.help_outline_rounded, "Help Center"),
                  _buildSettingsTile(Icons.info_outline_rounded, "About TEREA"),
                ]),
                const SizedBox(height: 40),
                _buildPrimaryButton(context, "Log Out", () => Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false)),
                const SizedBox(height: 20),
              ],
            ),
          ),
    );
  }

  Widget _buildModernProfileCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(color: accentGreen.withOpacity(0.2), shape: BoxShape.circle),
                child: CircleAvatar(
                  radius: 40, 
                  backgroundColor: lightBg,
                  backgroundImage: _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
                  child: _avatarUrl == null ? Icon(Icons.person_rounded, size: 45, color: accentGreen) : null,
                ),
              ),
              Positioned(
                bottom: 0, right: 0,
                child: GestureDetector(
                  onTap: _uploadPhoto,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: primaryGreen, 
                      shape: BoxShape.circle,
                      border: Border.all(color: surfaceWhite, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                  ),
                ),
              )
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_username, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: primaryGreen)),
                const SizedBox(height: 2),
                Text(_email, style: TextStyle(color: Colors.grey[500], fontSize: 13, fontWeight: FontWeight.w500)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSettingsGroup(String title, List<Widget> tiles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 10, bottom: 12),
          child: Text(title.toUpperCase(), 
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: accentGreen, letterSpacing: 1.5)),
        ),
        Container(
          decoration: BoxDecoration(
            color: surfaceWhite, 
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(children: tiles),
        ),
      ],
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, {String? subtext, Widget? trailing, VoidCallback? onTap}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: lightBg, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: accentGreen, size: 22),
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: primaryGreen, fontSize: 15)),
      subtitle: subtext != null ? Text(subtext, style: TextStyle(color: Colors.grey[400], fontSize: 12)) : null,
      trailing: trailing ?? Icon(Icons.chevron_right_rounded, color: Colors.grey[300]),
      onTap: onTap ?? () {},
    );
  }

  Widget _buildPrimaryButton(BuildContext context, String text, VoidCallback onTap) {
    return Container(
      width: double.infinity,
      height: 58,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(colors: [primaryGreen, accentGreen], begin: Alignment.topLeft, end: Alignment.bottomRight),
        boxShadow: [BoxShadow(color: accentGreen.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

// --- 10. RISK RESULT PAGE ---
class RiskResultPage extends StatefulWidget {
  const RiskResultPage({super.key});

  @override
  State<RiskResultPage> createState() => _RiskResultPageState();
}

class _RiskResultPageState extends State<RiskResultPage> {
  // Theme Palette
  final Color primaryGreen = const Color(0xFF2D3B1E);
  final Color accentGreen = const Color(0xFF606C38);
  final Color lightBg = const Color(0xFFF9F9F7);
  final Color surfaceWhite = Colors.white;

  final _supabase = Supabase.instance.client;
  bool _hasSaved = false; // Prevent double saving

  @override
  void initState() {
    super.initState();
  }

  Future<void> _saveToHistory(int score, String risk) async {
    if (_hasSaved) return; // Prevent duplicates in this session
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        await _supabase.from('assessment_history').insert({
          'user_id': user.id,
          'score': score,
          'risk_level': risk,
        });
        setState(() {
          _hasSaved = true;
        });
      }
    } catch (e) {
      debugPrint("DB Error: $e");
    }
  }

  Future<void> _generatePdf(int score, String label) async {
    final pdf = pw.Document();
    pdf.addPage(pw.Page(
      build: (pw.Context context) => pw.Center(
        child: pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Text("TB Assessment Report",
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 20),
            pw.Text("Result: $label"),
            pw.Text("Score: $score"),
            pw.Text("Date: ${DateTime.now().toString().split(' ')[0]}"),
            pw.SizedBox(height: 30),
            pw.Text("Note: This is a screening tool, not a clinical diagnosis.",
                style: const pw.TextStyle(fontSize: 10)),
          ],
        ),
      ),
    ));
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  // Helper for dynamic recommendations
  Map<String, String> _getRecommendation(String risk) {
    switch (risk) {
      case "HIGH RISK":
        return {
          "title": "Immediate Action Required",
          "desc": "Please visit your nearest health center for a GeneXpert/Sputum test immediately."
        };
      case "MEDIUM RISK":
        return {
          "title": "Consultation Advised",
          "desc": "Schedule a check-up with a doctor to discuss your persistent symptoms."
        };
      default:
        return {
          "title": "Stay Vigilant",
          "desc": "Continue to monitor your health and maintain a healthy lifestyle."
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final int score = (ModalRoute.of(context)!.settings.arguments as int? ?? 0);
    String riskLabel = score >= 12 ? "HIGH RISK" : (score >= 6 ? "MEDIUM RISK" : "LOW RISK");
    Color riskColor = score >= 12
        ? const Color(0xFFD9534F) // Red for High
        : (score >= 6 ? const Color(0xFFBC6C25) : const Color(0xFF606C38)); // Orange for Med, Green for Low

    // Define Logic Flags based on Risk
    bool showFacilitiesBtn = (riskLabel == "HIGH RISK" || riskLabel == "MEDIUM RISK");

    final rec = _getRecommendation(riskLabel);

    return Scaffold(
      backgroundColor: lightBg,
      body: Stack(
        children: [
          // Background Blobs
          Positioned.fill(
            child: CustomPaint(
              painter: BlobPainter(color: accentGreen.withOpacity(0.05)),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
              child: Column(
                children: [
                  // App Bar Area
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Assessment Result",
                          style: TextStyle(
                              color: primaryGreen,
                              fontWeight: FontWeight.bold,
                              fontSize: 18)),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // Detailed Result Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: surfaceWhite,
                      borderRadius: BorderRadius.circular(35),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 30,
                            offset: const Offset(0, 15))
                      ],
                    ),
                    child: Column(
                      children: [
                        // Animated Icon Container
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: riskColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.health_and_safety_rounded,
                              size: 70, color: riskColor),
                        ),
                        const SizedBox(height: 25),
                        Text(riskLabel,
                            style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                                color: riskColor,
                                letterSpacing: 1.2)),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: lightBg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text("Total Score: $score",
                              style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: primaryGreen,
                                  fontSize: 15)),
                        ),
                        const SizedBox(height: 25),
                        
                        // Suggestion Block
                        Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: riskColor.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: riskColor.withOpacity(0.2)),
                          ),
                          child: Column(
                            children: [
                              Text(rec["title"]!, 
                                  style: TextStyle(fontWeight: FontWeight.bold, color: riskColor)),
                              const SizedBox(height: 5),
                              Text(rec["desc"]!, 
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 13, color: primaryGreen.withOpacity(0.8))),
                            ],
                          ),
                        ),

                        const SizedBox(height: 25),
                        Divider(color: Colors.grey.withOpacity(0.2)),
                        const SizedBox(height: 20),
                        Text(
                          "This assessment is based on your reported symptoms. Please consult a qualified healthcare professional for a formal medical diagnosis.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.grey[600],
                              height: 1.5,
                              fontSize: 12,
                              fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Share/PDF Row
                  Row(
                    children: [
                      Expanded(
                          child: _actionBtn(Icons.share_rounded, "Share",
                              () => Share.share("My TB Risk is $riskLabel (Score: $score)"))),
                      const SizedBox(width: 15),
                      Expanded(
                          child: _actionBtn(Icons.picture_as_pdf_rounded, "Save PDF",
                              () => _generatePdf(score, riskLabel))),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // --- CONDITIONAL BUTTON LOGIC ---
                  
                  // 1. View Nearby Facilities (Only for High/Medium Risk)
                  if (showFacilitiesBtn) ...[
                    _primaryBtn("View Nearby Facilities", () async {
                      await _saveToHistory(score, riskLabel);
                      Navigator.pushNamed(context, '/facilities');
                    }),
                    const SizedBox(height: 15),
                  ],

                  // 2. Retake Assessment (Visible for ALL risks)
                  _primaryBtn("Retake Assessment", () {
                    Navigator.pushReplacementNamed(context, '/assess');
                  }),

                  const SizedBox(height: 15),

                  // 3. Return to Dashboard (Visible for ALL risks)
                  _primaryBtn("Return to Dashboard", () async {
                    await _saveToHistory(score, riskLabel);
                    Navigator.pushNamedAndRemoveUntil(context, '/home', (r) => false);
                  }),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: surfaceWhite,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black.withOpacity(0.05)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: accentGreen, size: 20),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    color: primaryGreen, fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  // Unified Button Style: Gradient Green Background, White Text
  Widget _primaryBtn(String text, VoidCallback onTap) {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryGreen, accentGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: accentGreen.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8))
        ],
      ),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: Text(text,
            style: const TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

// Custom Painter for Background Blobs
class BlobPainter extends CustomPainter {
  final Color color;
  BlobPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;

    // Top Right Blob
    canvas.drawCircle(Offset(size.width * 0.9, size.height * 0.1), 150, paint);

    // Bottom Left Blob
    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.8), 200, paint);

    // Small Center Blob
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.5), 80, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// --- 7. FACILITIES PAGE (MAP + LIST) ---
class FacilitiesPage extends StatefulWidget {
  const FacilitiesPage({super.key});

  @override
  State<FacilitiesPage> createState() => _FacilitiesPageState();
}

class _FacilitiesPageState extends State<FacilitiesPage> {
  static const LatLng _carmonaCenter = LatLng(14.3135, 121.0574);
  late GoogleMapController mapController;

  // MARKERS: Polished coordinates for Carmona TB Centers
  final Set<Marker> _markers = {
    const Marker(
      markerId: MarkerId('rhu_dots'),
      position: LatLng(14.3121, 121.0558),
      infoWindow: InfoWindow(title: 'Rural Health Unit (RHU)', snippet: 'Primary TB-DOTS Center'),
    ),
    const Marker(
      markerId: MarkerId('super_health'),
      position: LatLng(14.3145, 121.0620),
      infoWindow: InfoWindow(title: 'Super Health Center', snippet: 'Primary Care'),
    ),
    const Marker(
      markerId: MarkerId('hospital_medical'),
      position: LatLng(14.3015, 121.0485),
      infoWindow: InfoWindow(title: 'Carmona Hospital & Medical Center', snippet: 'Diagnostics'),
    ),
    const Marker(
      markerId: MarkerId('pagamutang_bayan'),
      position: LatLng(14.3072, 121.0423),
      infoWindow: InfoWindow(title: 'Pagamutang Bayan ng Carmona', snippet: 'Public Hospital'),
    ),
  };

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  // FIXED: Standard Google Maps URL Scheme for Directions
  Future<void> _launchMaps(double lat, double lng) async {
    final String googleMapsUrl = "https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving";
    final Uri url = Uri.parse(googleMapsUrl);

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint("Maps Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color forestDark = Color(0xFF283618);
    const Color forestMed = Color(0xFF606C38);
    
    return Scaffold(
      backgroundColor: const Color(0xFFFEFAE0),
      appBar: AppBar(
        title: const Text('Nearby Facilities', style: TextStyle(color: forestDark, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: forestDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // MAP SECTION
          SizedBox(
            height: 300,
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: const CameraPosition(target: _carmonaCenter, zoom: 14),
              markers: _markers,
              myLocationButtonEnabled: true,
              zoomControlsEnabled: true,
            ),
          ),
          
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("Official TB Centers and Hospitals in Carmona.", 
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: forestDark)),
          ),
          
          // LIST SECTION
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              children: [
                _buildFacilityCard('Rural Health Unit (RHU)', 'Primary TB-DOTS Center', 'J.M. Loyola St., Brgy. 4', '14.3121', '121.0558'),
                _buildFacilityCard('Super Health Center', 'Primary Care & Consultation', 'Carmona City (New Facility)', '14.3145', '121.0620'),
                _buildFacilityCard('Hospital & Medical Center', 'Private Referral / Diagnostics', 'Sugar Road, Brgy. Maduya', '14.3015', '121.0485'),
                _buildFacilityCard('Pagamutang Bayan ng Carmona', 'Public Hospital Support', 'Brgy. Mabuhay', '14.3072', '121.0423'),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(3, context),
    );
  }

  Widget _buildFacilityCard(String name, String type, String addr, String lat, String lng) {
    const Color forestMed = Color(0xFF606C38);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text(type, style: const TextStyle(color: forestMed, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 5),
          Text(addr, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _launchMaps(double.parse(lat), double.parse(lng)),
              icon: const Icon(Icons.directions, color: Colors.white),
              label: const Text("Directions", style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: forestMed, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(int index, BuildContext context) {
    return BottomNavigationBar(
      currentIndex: index,
      selectedItemColor: const Color(0xFF283618),
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.medication_rounded), label: 'Meds'),
        BottomNavigationBarItem(icon: Icon(Icons.calendar_month_rounded), label: 'Follow-up'),
        BottomNavigationBarItem(icon: Icon(Icons.map_rounded), label: 'Facilities'),
      ],
      onTap: (i) {
        if (i == 0) Navigator.pushReplacementNamed(context, '/dashboard');
      },
    );
  }
}

// --- SHARED UI COMPONENTS ---
Widget _buildLogo({double size = 80}) {
  return Container(
    width: size, height: size,
    decoration: BoxDecoration(color: const Color(0xFF606C38), borderRadius: BorderRadius.circular(size * 0.25)),
    child: Icon(Icons.eco, size: size * 0.6, color: const Color(0xFFFEFAE0)),
  );
}

Widget _buildTextField(String label, String hint, {bool isPassword = false, TextEditingController? controller}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF283618))),
      const SizedBox(height: 8),
      TextField(
        controller: controller,
        obscureText: isPassword,
        decoration: InputDecoration(
          hintText: hint, filled: true, fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          suffixIcon: isPassword ? const Icon(Icons.visibility_off_outlined) : null,
        ),
      ),
    ],
  );
}

Widget _buildPrimaryButton(BuildContext context, String text, VoidCallback onTap) {
  return SizedBox(
    width: double.infinity, height: 55,
    child: ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF606C38), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
    ),
  );
}

Widget _buildActionCard(BuildContext context, IconData icon, String title, String sub, String route) {
  return GestureDetector(
    onTap: () => Navigator.pushNamed(context, route),
    child: Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF606C38)),
          const Spacer(),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          Text(sub, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    ),
  );
}

Widget _buildBottomNav(int idx, BuildContext context) {
  return BottomNavigationBar(
    currentIndex: idx,
    type: BottomNavigationBarType.fixed,
    selectedItemColor: const Color(0xFF606C38),
    onTap: (i) {
      if (i == 0) Navigator.pushNamed(context, '/home');
      if (i == 1) Navigator.pushNamed(context, '/assess');
      if (i == 2) Navigator.pushNamed(context, '/meds');
      if (i == 3) Navigator.pushNamed(context, '/followup');
      if (i == 4) Navigator.pushNamed(context, '/chat');
    },
    items: const [
      BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: "Home"),
      BottomNavigationBarItem(icon: Icon(Icons.assignment_outlined), label: "Assess"),
      BottomNavigationBarItem(icon: Icon(Icons.medication_outlined), label: "Meds"),
      BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), label: "Follow-up"),
      BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: "Chat"),
    ],
  );
}