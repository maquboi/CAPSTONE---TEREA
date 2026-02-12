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

// Login Page natin toh
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // --- LOGIC SECTION (Untouched) ---
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _signIn() async {
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (mounted) Navigator.pushNamed(context, '/home');
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
  // --------------------------------

  @override
  Widget build(BuildContext context) {
    // Theme Colors
    const Color forestDark = Color(0xFF283618);
    const Color forestLight = Color(0xFF606C38);
    const Color bgWhite = Color(0xFFF9FAFB);

    return Scaffold(
      backgroundColor: bgWhite,
      body: Stack( // Using Stack to layer background designs behind the content
        children: [
          // --- BACKGROUND DECORATIONS ---
          // Top right organic shape
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                color: forestLight.withOpacity(0.12),
                borderRadius: BorderRadius.circular(80), // Soft rounded corner look
              ),
            ),
          ),
          // Bottom left organic shape
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
                  // 1. Logo Section
                  Center(child: _buildLogo(size: 80)),
                  
                  const SizedBox(height: 30),
                  
                  // 2. Header Text
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
                      fontWeight: FontWeight.w500
                    ),
                  ),
                  
                  const SizedBox(height: 50),
                  
                  // 3. Inputs
                  _buildTextField(
                    label: "Email", 
                    hint: "you@example.com", 
                    controller: _emailController, 
                    icon: Icons.email_outlined
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    label: "Password", 
                    hint: "••••••••", 
                    isPassword: true, 
                    controller: _passwordController,
                    icon: Icons.lock_outline
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // 4. Action Button
                  _isLoading 
                    ? const Center(child: CircularProgressIndicator(color: forestDark))
                    : _buildGradientButton(
                        text: "Sign in", 
                        onPressed: _signIn,
                        colors: [forestLight, forestDark],
                      ),
                
                  const SizedBox(height: 25),
                  
                  // 5. Sign Up Link
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

  // --- UI HELPER WIDGETS ---

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

//Sign Up Page natin 
class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  // --- LOGIC SECTION (Untouched) ---
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _contactController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  String? _selectedGender; 
  final List<String> _genderOptions = ['Male', 'Female', 'Other'];
  bool _isLoading = false;

  Future<void> _handleSignUp() async {
    if (_selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a gender")),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final authResponse = await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (authResponse.user != null) {
        await Supabase.instance.client.from('profiles').insert({
          'id': authResponse.user!.id,
          'full_name': _nameController.text.trim(),
          'age': _ageController.text.trim(),
          'gender': _selectedGender,
          'contact_number': _contactController.text.trim(),
          'email': _emailController.text.trim(),
        });
        if (mounted) Navigator.pushNamed(context, '/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Registration Error: $e"), backgroundColor: Colors.redAccent)
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  // --------------------------------

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
          // 1. Background Blobs (for consistency with Login)
          Positioned(
            top: 200,
            right: -50,
            child: _buildBackgroundShape(180, forestLight.withOpacity(0.08)),
          ),

          SingleChildScrollView(
            child: Column(
              children: [
                // 2. Header Section (Gradient Background)
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

                // 3. Form Card
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
                      
                      _buildTextField(label: "Full Name", hint: "Juan Dela Cruz", controller: _nameController, icon: Icons.person_outline),
                      const SizedBox(height: 20),
                      
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildTextField(label: "Age", hint: "25", controller: _ageController, icon: Icons.cake_outlined)),
                          const SizedBox(width: 15),
                          Expanded(child: _buildGenderDropdown(forestDark, forestLight)),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      _buildTextField(label: "Contact Number", hint: "+63 912 345 6789", controller: _contactController, icon: Icons.phone_android_outlined),
                      const SizedBox(height: 20),
                      _buildTextField(label: "Email Address", hint: "your.email@example.com", controller: _emailController, icon: Icons.mail_outline),
                      const SizedBox(height: 20),
                      _buildTextField(label: "Password", hint: "Minimum 6 characters", isPassword: true, controller: _passwordController, icon: Icons.lock_open_outlined),
                      
                      const SizedBox(height: 40),
                      
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

  Widget _buildTextField({required String label, required String hint, required TextEditingController controller, bool isPassword = false, IconData? icon}) {
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

// Dashburdddd
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // --- LOGIC (Untouched) ---
  final _supabase = Supabase.instance.client;
  String _username = "Patient";
  String? _avatarUrl;
  String _riskLevel = "Not yet assessed";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        final data = await _supabase
            .from('profiles')
            .select('full_name, avatar_url, risk_level')
            .eq('id', user.id)
            .single();

        setState(() {
          _username = data['full_name'] ?? "Patient";
          _avatarUrl = data['avatar_url'];
          _riskLevel = data['risk_level'] ?? "Not yet assessed";
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching dashboard data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Enhanced Green Palette
    const Color forestDark = Color(0xFF283618); // Primary
    const Color forestMed = Color(0xFF606C38);  // Secondary
    const Color mossGreen = Color(0xFFADC178); // Accents
    const Color paleGreen = Color(0xFFDDE5B6); // Card Backgrounds
    const Color softWhite = Color(0xFFF8F9FA);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            _buildLogo(size: 32),
            const SizedBox(width: 10),
            const Text('TEREA', 
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
                child: _avatarUrl == null ? const Icon(Icons.person, size: 20, color: forestDark) : null,
              ),
            ),
          )
        ],
      ),
      body: Stack(
        children: [
          // Background Blobs for depth
          Positioned(top: -50, right: -30, child: _buildBlob(200, mossGreen)),
          Positioned(bottom: 100, left: -50, child: _buildBlob(250, forestMed)),
          
          _isLoading 
            ? const Center(child: CircularProgressIndicator(color: forestMed))
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
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: forestDark, letterSpacing: -0.5)
                      ),
                      const Text(
                        'How are you feeling today?', 
                        style: TextStyle(color: forestMed, fontSize: 16, fontWeight: FontWeight.w600)
                      ),
                      const SizedBox(height: 25),
                      
                      _buildTreatmentBanner(),
                      
                      const SizedBox(height: 35),
                      const Text(
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
                          _buildActionCard(context, Icons.medication_rounded, 'Medication Diary', 'Track your medicines', '/meds', forestMed, paleGreen),
                          _buildActionCard(context, Icons.calendar_today_rounded, 'Follow-up', 'Upcoming visits', '/followup', forestMed, paleGreen),
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

  Widget _buildTreatmentBanner() {
    Color bannerColor = const Color(0xFF606C38);
    if (_riskLevel.toLowerCase().contains("high")) bannerColor = const Color(0xFFD90429);
    if (_riskLevel.toLowerCase().contains("medium")) bannerColor = const Color(0xFFF9C74F);
    if (_riskLevel.toLowerCase().contains("low")) bannerColor = const Color(0xFF43AA8B);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: bannerColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: bannerColor.withOpacity(0.4), 
            blurRadius: 20, 
            offset: const Offset(0, 10)
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), shape: BoxShape.circle),
            child: const Icon(Icons.monitor_heart_rounded, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Treatment Status', 
                  style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13)
                ),
                Text(_riskLevel, 
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)
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
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF283618))
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
    return Icon(Icons.eco_rounded, color: const Color(0xFF283618), size: size);
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
          if (tappedIndex == index) return; // Already on this page
          
          switch (tappedIndex) {
            case 0:
              // Home is usually the current page, but can be reset here
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
        selectedItemColor: const Color(0xFF283618),
        unselectedItemColor: Colors.grey.shade500,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.medication_rounded), label: 'Meds'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month_rounded), label: 'Follow-up'),
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
  String? selected;
  bool _showError = false;

  final List<Map<String, dynamic>> questions = [
    {"q": "Do you have a persistent cough lasting more than 2 weeks?", "weight": 3},
    {"q": "Have you noticed blood in your phlegm or mucus?", "weight": 5},
    {"q": "Have you experienced unexplained weight loss recently?", "weight": 2},
    {"q": "Do you suffer from frequent night sweats?", "weight": 2},
    {"q": "Do you have persistent chest pain or pain when breathing?", "weight": 2},
    {"q": "Have you been feeling unusually tired or fatigued for weeks?", "weight": 1},
    {"q": "Do you have a recurring fever (especially in the afternoon)?", "weight": 2},
    {"q": "Have you lost your appetite significantly?", "weight": 1},
    {"q": "Have you lived with or cared for someone with active TB?", "weight": 4},
    {"q": "Do you have a weakened immune system (e.g., Diabetes, HIV)?", "weight": 3},
    {"q": "Have you recently traveled to an area with high TB rates?", "weight": 2},
    {"q": "Do you smoke or have a history of heavy tobacco use?", "weight": 1},
  ];

  void _handleNext() {
    if (selected == null) {
      setState(() => _showError = true);
      return;
    }
    if (selected == "Yes") {
      riskScore += (questions[currentIndex]['weight'] as int);
    }
    if (currentIndex < questions.length - 1) {
      setState(() {
        currentIndex++;
        selected = null;
        _showError = false;
      });
    } else {
      _calculateAndNavigate();
    }
  }

  Future<void> _calculateAndNavigate() async {
    String finalRisk = "Low Risk";
    if (riskScore >= 12) finalRisk = "High Risk";
    else if (riskScore >= 6) finalRisk = "Medium Risk";

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await Supabase.instance.client
            .from('profiles')
            .update({'risk_level': finalRisk})
            .eq('id', user.id);
      }
    } catch (e) {
      debugPrint('Error updating database: $e');
    }

    if (mounted) {
      // Navigates to the modern result page and passes the score
      Navigator.pushReplacementNamed(context, '/result', arguments: riskScore);
    }
  }

  final Color forestDark = const Color(0xFF283618);
  final Color forestMed = const Color(0xFF606C38);
  final Color mossGreen = const Color(0xFFADC178);
  final Color paleGreen = const Color(0xFFDDE5B6);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(25, 60, 25, 30),
            decoration: BoxDecoration(
              color: forestDark,
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('TB Risk Assessment', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    Text('Step ${currentIndex + 1}/${questions.length}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 20),
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

// --- 6. MEDS PAGE (CRUD + MULTI-VIEW CALENDAR) ---
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
  int _selectedIndex = 2; // Defaulting to "Meds" tab

  // Define the Theme Colors based on your screenshots
  final Color primaryGreen = const Color(0xFF2D3B1E); // Dark Forest
  final Color accentGreen = const Color(0xFF606C38);  // Olive
  final Color lightBg = const Color(0xFFF9F9F7);      // Off-white background
  final Color surfaceWhite = Colors.white;

  @override
  void initState() {
    super.initState();
    _fetchMeds();
  }

  // --- DATA FETCHING ---
  Future<void> _fetchMeds() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final data = await Supabase.instance.client
          .from('medications')
          .select()
          .eq('user_id', user.id);

      if (mounted) {
        setState(() {
          myMeds = data as List<dynamic>;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching meds: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- CRUD OPERATIONS ---
  Future<void> _saveMed({
    String? medId,
    required String name,
    required String dosage,
    required String time,
    required DateTime start,
    required DateTime end
  }) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final medData = {
      'user_id': user.id,
      'name': name,
      'dosage': dosage,
      'time': time,
      'start_date': start.toIso8601String(),
      'end_date': end.toIso8601String(),
      'is_taken': false,
    };

    try {
      if (medId == null) {
        await Supabase.instance.client.from('medications').insert(medData);
      } else {
        await Supabase.instance.client.from('medications').update(medData).eq('id', medId);
      }
      _fetchMeds();
    } catch (e) {
      debugPrint("Error saving med: $e");
    }
  }

  Future<void> _deleteMed(String medId) async {
    try {
      await Supabase.instance.client.from('medications').delete().eq('id', medId);
      _fetchMeds();
    } catch (e) {
      debugPrint("Error deleting med: $e");
    }
  }

  Future<void> _toggleMed(bool currentValue, String medId) async {
    try {
      await Supabase.instance.client
          .from('medications')
          .update({'is_taken': !currentValue})
          .eq('id', medId);
      _fetchMeds();
    } catch (e) {
      debugPrint("Error toggling med: $e");
    }
  }

  // --- DIALOGS ---
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
          title: Text(existingMed == null ? "Add Medication" : "Edit Details",
              style: TextStyle(color: primaryGreen, fontWeight: FontWeight.w700)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: "Medicine Name",
                    labelStyle: TextStyle(color: accentGreen),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: accentGreen)),
                  ),
                ),
                TextField(
                  controller: dosageController,
                  decoration: InputDecoration(
                    labelText: "Dosage (e.g. 500mg)",
                    labelStyle: TextStyle(color: accentGreen),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: accentGreen)),
                  ),
                ),
                const SizedBox(height: 15),
                _buildDialogTile(
                  icon: Icons.access_time_rounded,
                  title: "Reminder Time",
                  value: selectedTime,
                  onTap: () async {
                    TimeOfDay? picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                    if (picked != null) setDialogState(() => selectedTime = picked.format(context));
                  },
                ),
                _buildDialogTile(
                  icon: Icons.calendar_today_rounded,
                  title: "Treatment Duration",
                  value: "${DateFormat('MMM d').format(startDate)} - ${DateFormat('MMM d').format(endDate)}",
                  onTap: () async {
                    DateTimeRange? picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime.now().subtract(const Duration(days: 30)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setDialogState(() {
                        startDate = picked.start;
                        endDate = picked.end;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel", style: TextStyle(color: Colors.grey[600])),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: accentGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: () {
                _saveMed(
                  medId: existingMed?['id']?.toString(),
                  name: nameController.text,
                  dosage: dosageController.text,
                  time: selectedTime,
                  start: startDate,
                  end: endDate,
                );
                Navigator.pop(context);
              },
              child: const Text("Save Task", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogTile({required IconData icon, required String title, required String value, required VoidCallback onTap}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: lightBg, borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: accentGreen, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      subtitle: Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: primaryGreen)),
      onTap: onTap,
    );
  }

  // --- BUILD METHODS ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        // Added Return Button
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: primaryGreen),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(children: [
          Icon(Icons.favorite_rounded, color: accentGreen, size: 28),
          const SizedBox(width: 10),
          Text('TB HealthCare', style: TextStyle(fontWeight: FontWeight.w800, color: primaryGreen, fontSize: 20))
        ]),
        actions: [
          IconButton(
            icon: Icon(Icons.tune_rounded, color: primaryGreen),
            onPressed: () {
              setState(() {
                if (_viewType == 'Day') _viewType = 'Week';
                else if (_viewType == 'Week') _viewType = 'Month';
                else _viewType = 'Day';
              });
            },
          )
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: accentGreen))
          : Column(
              children: [
                _buildModernHeader(),
                const SizedBox(height: 20),
                _buildCalendarSection(),
                const SizedBox(height: 20),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: surfaceWhite,
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
                    ),
                    child: _buildMedList(),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryGreen,
        onPressed: () => _showMedDialog(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      // Added Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: surfaceWhite,
        selectedItemColor: accentGreen,
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment_outlined), label: 'Assess'),
          BottomNavigationBarItem(icon: Icon(Icons.medication_rounded), label: 'Meds'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month_outlined), label: 'Follow-up'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline_rounded), label: 'Chat'),
        ],
      ),
    );
  }

  Widget _buildModernHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [primaryGreen, accentGreen], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Medication Diary', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
            'Keep track of your TB treatment journey.',
            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              const Icon(Icons.calendar_today, color: Colors.white, size: 14),
              const SizedBox(width: 8),
              Text(
                '${DateFormat('MMMM dd, yyyy').format(_selectedDate)}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildCalendarSection() {
    if (_viewType == 'Month') {
      return SizedBox(height: 300, child: _buildMonthGrid());
    } else if (_viewType == 'Day') {
      return _buildDateCard(_selectedDate, true);
    } else {
      return SizedBox(height: 90, child: _buildWeekStrip());
    }
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
      },
    );
  }

  Widget _buildMonthGrid() {
    int daysInMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 0).day;
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisSpacing: 5, crossAxisSpacing: 5),
      itemCount: daysInMonth,
      itemBuilder: (context, index) {
        DateTime date = DateTime(_selectedDate.year, _selectedDate.month, index + 1);
        bool isSelected = date.day == _selectedDate.day && date.month == _selectedDate.month;
        return _buildDateCard(date, isSelected, compact: true);
      },
    );
  }

  Widget _buildDateCard(DateTime date, bool isSelected, {bool compact = false}) {
    return GestureDetector(
      onTap: () => setState(() => _selectedDate = date),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: compact ? null : 65,
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? accentGreen : surfaceWhite,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected ? [BoxShadow(color: accentGreen.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : [],
          border: Border.all(color: isSelected ? accentGreen : Colors.grey.withOpacity(0.1)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(DateFormat('E').format(date).toUpperCase(),
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: isSelected ? Colors.white70 : Colors.grey)),
            const SizedBox(height: 4),
            Text(date.day.toString(),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: isSelected ? Colors.white : primaryGreen)),
          ],
        ),
      ),
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
          Text("Rest easy. No meds today.", style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.w500)),
        ],
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
            border: Border.all(color: isTaken ? Colors.transparent : Colors.grey.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => _toggleMed(isTaken, med['id'].toString()),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isTaken ? accentGreen : lightBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isTaken ? Icons.check : Icons.medication_rounded,
                    color: isTaken ? Colors.white : accentGreen,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(med['name'],
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            decoration: isTaken ? TextDecoration.lineThrough : null,
                            color: isTaken ? Colors.grey : primaryGreen)),
                    Text('${med['dosage']} • ${med['time']}',
                        style: TextStyle(fontSize: 13, color: isTaken ? Colors.grey[400] : Colors.grey[600])),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.grey),
                onSelected: (value) {
                  if (value == 'edit') _showMedDialog(existingMed: med);
                  if (value == 'delete') _deleteMed(med['id'].toString());
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
//FOLLOW UP TOHHH//
class FollowUpPage extends StatefulWidget {
  const FollowUpPage({super.key});

  @override
  State<FollowUpPage> createState() => _FollowUpPageState();
}

class _FollowUpPageState extends State<FollowUpPage> {
  final _supabase = Supabase.instance.client;
  int _streakDays = 0;
  bool _isLoading = true;

  final TextEditingController _noteController = TextEditingController();

  List<Map<String, dynamic>> _doctorNotes = [];
  List<Map<String, dynamic>> _appointments = [];

  // Theme Palette
  final Color kPrimaryGreen = const Color(0xFF283618);
  final Color kSecondaryGreen = const Color(0xFF606C38);
  final Color kCreamAccent = const Color(0xFFFEFAE0);
  final Color kWhite = Colors.white;
  final Color kSoftGrey = const Color(0xFFF8F9FA);

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    try {
      await Future.wait([
        _fetchStreak(),
        _fetchNotes(),
        _fetchAppointments(),
      ]);
    } catch (e) {
      debugPrint('Initialization error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchStreak() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;
      final response = await _supabase.rpc('get_medication_streak', params: {'p_user_id': userId});
      if (mounted) setState(() => _streakDays = response as int);
    } catch (e) {
      debugPrint('Streak Error: $e');
    }
  }

  Future<void> _fetchNotes() async {
    try {
      final data = await _supabase.from('doctor_notes').select().order('created_at', ascending: false);
      if (mounted) setState(() => _doctorNotes = List<Map<String, dynamic>>.from(data));
    } catch (e) {
      debugPrint('Notes Fetch Error: $e');
    }
  }

  Future<void> _addNote() async {
    if (_noteController.text.isEmpty) return;
    final text = _noteController.text;
    _noteController.clear();
    try {
      await _supabase.from('doctor_notes').insert({
        'note_text': text,
        'user_id': _supabase.auth.currentUser!.id
      });
      _fetchNotes();
    } catch (e) {
      debugPrint('Add Note Error: $e');
    }
  }

  Future<void> _toggleNote(int index, bool currentVal) async {
    final noteId = _doctorNotes[index]['id'];
    setState(() => _doctorNotes[index]['is_checked'] = !currentVal);
    try {
      await _supabase.from('doctor_notes').update({'is_checked': !currentVal}).eq('id', noteId);
    } catch (e) {
      debugPrint('Toggle Note Error: $e');
    }
  }

  Future<void> _deleteNote(String id) async {
    try {
      await _supabase.from('doctor_notes').delete().eq('id', id);
      _fetchNotes();
    } catch (e) {
      debugPrint('Delete Note Error: $e');
    }
  }

  Future<void> _fetchAppointments() async {
    try {
      final data = await _supabase.from('appointments').select().order('appointment_date', ascending: true);
      if (mounted) setState(() => _appointments = List<Map<String, dynamic>>.from(data));
    } catch (e) {
      debugPrint('Appointments Fetch Error: $e');
    }
  }

  Future<void> _deleteAppointment(String id) async {
    try {
      await _supabase.from('appointments').delete().eq('id', id);
      _fetchAppointments();
    } catch (e) {
      debugPrint('Delete Appointment Error: $e');
    }
  }

  void _showAddAppointmentModal() {
    final docController = TextEditingController();
    final locController = TextEditingController();
    DateTime? selectedDate;
    TimeOfDay? selectedTime;
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kWhite,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(35))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 25, right: 25, top: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 25),
              Text("Schedule Visit", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: kPrimaryGreen)),
              const SizedBox(height: 20),
              _buildModernField(docController, "Doctor or Clinic Name", Icons.medical_services_outlined),
              const SizedBox(height: 15),
              _buildModernField(locController, "Location", Icons.location_on_outlined),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildPickerTile(
                      label: selectedDate == null ? "Select Date" : DateFormat('MMM dd, yyyy').format(selectedDate!),
                      icon: Icons.calendar_month_rounded,
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) setModalState(() => selectedDate = picked);
                      },
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildPickerTile(
                      label: selectedTime == null ? "Select Time" : selectedTime!.format(context),
                      icon: Icons.access_time_rounded,
                      onTap: () async {
                        final picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                        if (picked != null) setModalState(() => selectedTime = picked);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryGreen,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 5,
                    shadowColor: kPrimaryGreen.withOpacity(0.4),
                  ),
                  onPressed: isSaving ? null : () async {
                    if (docController.text.isNotEmpty && selectedDate != null && selectedTime != null) {
                      setModalState(() => isSaving = true);
                      try {
                        final timeString = '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}:00';
                        await _supabase.from('appointments').insert({
                          'user_id': _supabase.auth.currentUser!.id,
                          'doctor_name': docController.text,
                          'appointment_date': DateFormat('yyyy-MM-dd').format(selectedDate!),
                          'appointment_time': timeString,
                          'location': locController.text,
                        });
                        await _fetchAppointments();
                        if (context.mounted) Navigator.pop(context);
                      } catch (e) {
                        setModalState(() => isSaving = false);
                      }
                    }
                  },
                  child: isSaving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("Confirm Appointment", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kWhite,
      appBar: AppBar(
        backgroundColor: kWhite,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: kPrimaryGreen, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Follow-up Care', style: TextStyle(fontWeight: FontWeight.w900, color: kPrimaryGreen, fontSize: 20)),
      ),
      body: _isLoading
      ? Center(child: CircularProgressIndicator(color: kSecondaryGreen))
      : SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('YOUR PROGRESS', style: TextStyle(color: kSecondaryGreen, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
            const SizedBox(height: 12),
            _buildStreakCard(),
            const SizedBox(height: 35),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Upcoming Visits", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: kPrimaryGreen)),
                GestureDetector(
                  onTap: _showAddAppointmentModal,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: kSecondaryGreen, shape: BoxShape.circle, boxShadow: [BoxShadow(color: kSecondaryGreen.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]),
                    child: const Icon(Icons.add, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            
            if (_appointments.isEmpty) _buildEmptyState("No scheduled visits yet."),

            ..._appointments.map((appt) => _buildDismissibleWrapper(
              id: appt['id'].toString(),
              onDismiss: () => _deleteAppointment(appt['id'].toString()),
              child: _buildAppointmentCard(appt['doctor_name'], appt['appointment_date'], appt['appointment_time'], appt['location'] ?? ""),
            )),
            
            const SizedBox(height: 40),
            Text("CONSULTATION NOTES", style: TextStyle(color: kSecondaryGreen, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
            const SizedBox(height: 15),
            
            _buildNoteInput(),
            
            const SizedBox(height: 25),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _doctorNotes.length,
              itemBuilder: (context, index) {
                final note = _doctorNotes[index];
                return _buildNoteTile(note, index);
              },
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  // --- UI COMPONENT METHODS ---

  Widget _buildStreakCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [kSecondaryGreen, kPrimaryGreen], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: kPrimaryGreen.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))]
      ),
      child: Stack(
        children: [
          Positioned(right: -10, top: -10, child: Icon(Icons.favorite, color: Colors.white10, size: 100)),
          Row(
            children: [
              Container(
                height: 60, width: 60,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                child: const Icon(Icons.bolt_rounded, color: Colors.orangeAccent, size: 35),
              ),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$_streakDays Day Streak', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 26)),
                  const Text('You are doing great! Keep going.', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(String title, String date, String time, String loc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: kSoftGrey, width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))]
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
            decoration: BoxDecoration(color: kCreamAccent, borderRadius: BorderRadius.circular(15)),
            child: Column(
              children: [
                Text(date.split('-')[2], style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: kPrimaryGreen)),
                Text(DateFormat('MMM').format(DateTime.parse(date)).toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: kSecondaryGreen)),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: kPrimaryGreen)),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Icon(Icons.access_time_filled, size: 14, color: kSecondaryGreen),
                    const SizedBox(width: 5),
                    Text(time.substring(0, 5), style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(width: 15),
                    Icon(Icons.location_on, size: 14, color: kSecondaryGreen),
                    const SizedBox(width: 5),
                    Expanded(child: Text(loc, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.grey, fontSize: 13))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteInput() {
    return Container(
      decoration: BoxDecoration(
        color: kSoftGrey,
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextField(
        controller: _noteController,
        decoration: InputDecoration(
          hintText: "Add a question for your doctor...",
          hintStyle: const TextStyle(color: Colors.black26, fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          suffixIcon: IconButton(
            icon: CircleAvatar(backgroundColor: kPrimaryGreen, child: const Icon(Icons.add, color: Colors.white, size: 20)),
            onPressed: _addNote,
          ),
        ),
      ),
    );
  }

  Widget _buildNoteTile(Map<String, dynamic> note, int index) {
    bool isChecked = note['is_checked'] ?? false;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: isChecked ? 0.6 : 1.0,
      child: _buildDismissibleWrapper(
        id: note['id'].toString(),
        onDismiss: () => _deleteNote(note['id'].toString()),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: isChecked ? kSoftGrey.withOpacity(0.5) : kWhite,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: isChecked ? Colors.transparent : kSoftGrey, width: 1),
          ),
          child: CheckboxListTile(
            activeColor: kSecondaryGreen,
            checkboxShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            title: Text(note['note_text'], style: TextStyle(
              decoration: isChecked ? TextDecoration.lineThrough : null,
              color: isChecked ? Colors.grey : kPrimaryGreen,
              fontWeight: isChecked ? FontWeight.normal : FontWeight.w600,
              fontSize: 15
            )),
            value: isChecked,
            onChanged: (bool? value) => _toggleNote(index, isChecked),
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ),
      ),
    );
  }

  // --- HELPERS ---

  Widget _buildModernField(TextEditingController controller, String label, IconData icon) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: kSecondaryGreen),
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        filled: true,
        fillColor: kSoftGrey,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildPickerTile({required String label, required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: kSoftGrey, borderRadius: BorderRadius.circular(18)),
        child: Column(
          children: [
            Icon(icon, color: kSecondaryGreen),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: kPrimaryGreen)),
          ],
        ),
      ),
    );
  }

  Widget _buildDismissibleWrapper({required String id, required VoidCallback onDismiss, required Widget child}) {
    return Dismissible(
      key: Key(id),
      direction: DismissDirection.endToStart,
      onDismissed: (dir) => onDismiss(),
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(20)),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 25),
        child: const Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 30),
      ),
      child: child,
    );
  }

  Widget _buildEmptyState(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Text(msg, style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
      ),
    );
  }
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

  Future<void> _saveToHistory(int score, String risk) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        await _supabase.from('assessment_history').insert({
          'user_id': user.id,
          'score': score,
          'risk_level': risk,
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
          ],
        ),
      ),
    ));
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    final int score = (ModalRoute.of(context)!.settings.arguments as int? ?? 0);
    String riskLabel = score >= 12 ? "HIGH RISK" : (score >= 6 ? "MEDIUM RISK" : "LOW RISK");
    Color riskColor = score >= 12
        ? const Color(0xFFD9534F)
        : (score >= 6 ? const Color(0xFFBC6C25) : const Color(0xFF606C38));

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
                        Divider(color: Colors.grey.withOpacity(0.2)),
                        const SizedBox(height: 20),
                        Text(
                          "This assessment is based on your reported symptoms. Please consult a qualified healthcare professional for a formal medical diagnosis and further testing.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.grey[600],
                              height: 1.5,
                              fontSize: 13,
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

                  // Main Action: Facilities
                  _primaryBtn("View Nearby Facilities", () async {
                    await _saveToHistory(score, riskLabel);
                    Navigator.pushNamed(context, '/facilities');
                  }),
                  const SizedBox(height: 15),

                  // Secondary Action: Retake
                  _outlinedBtn("Retake Assessment", () {
                    Navigator.pushReplacementNamed(context, '/assess');
                  }, isSecondary: true),
                  
                  const SizedBox(height: 15),

                  // Final Action: Home
                  _outlinedBtn("Return to Dashboard", () async {
                    await _saveToHistory(score, riskLabel);
                    Navigator.pushNamedAndRemoveUntil(context, '/home', (r) => false);
                  }, isSecondary: false),
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

  Widget _outlinedBtn(String text, VoidCallback onTap, {required bool isSecondary}) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: isSecondary ? accentGreen : Colors.grey.shade300, width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        onPressed: onTap,
        child: Text(text,
            style: TextStyle(
                color: isSecondary ? accentGreen : Colors.grey[600],
                fontWeight: FontWeight.bold,
                fontSize: 16)),
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
  // Theme Colors
  final Color primaryGreen = const Color(0xFF283618); // Dark Forest
  final Color accentGreen = const Color(0xFF606C38);  // Moss Green
  final Color lightBg = const Color(0xFFFEFAE0);      // Cream Background
  final Color surfaceWhite = Colors.white;

  static const LatLng _carmonaCenter = LatLng(14.3135, 121.0574);

  final Set<Marker> _markers = {
    const Marker(
      markerId: MarkerId('city_health'),
      position: LatLng(14.3122, 121.0558),
      infoWindow: InfoWindow(title: 'City Health Office - Main'),
    ),
    const Marker(
      markerId: MarkerId('brgy_center'),
      position: LatLng(14.3050, 121.0600),
      infoWindow: InfoWindow(title: 'Barangay Health Center A'),
    ),
  };

  Future<void> _launchMaps(double lat, double lng) async {
    // Note: For web, you often need the direct maps link
    final String googleMapsUrl = "https://www.google.com/maps/search/?api=1&query=$lat,$lng";
    final Uri url = Uri.parse(googleMapsUrl);
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBg,
      appBar: AppBar(
        title: Text('Nearby Facilities', 
          style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold, fontSize: 22)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryGreen),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Map Section with rounded corners
          Container(
            height: 250,
            margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: GoogleMap(
                initialCameraPosition: const CameraPosition(target: _carmonaCenter, zoom: 14),
                markers: _markers,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: true,
                mapType: MapType.normal, // Ensure this is set to normal
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text("Recommended centers for TB testing", 
              style: TextStyle(fontSize: 14, color: accentGreen, fontWeight: FontWeight.w500, fontStyle: FontStyle.italic)),
          ),

          // Facilities List Section
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              children: [
                _buildFacilityCard(
                  'City Health Office - Main', 
                  'Mabuhay Road, Carmona, Cavite', 
                  '8:00 AM - 5:00 PM', 
                  '14.3122', '121.0558', 
                  '4.8', '1.2 km away'
                ),
                _buildFacilityCard(
                  'Barangay Health Center A', 
                  'Brgy. Lantic, Carmona, Cavite',
                  '9:00 AM - 4:00 PM', 
                  '14.3050', '121.0600', 
                  '4.5', '2.5 km away'
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFacilityCard(String name, String address, String hours, String lat, String lng, String rating, String distance) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: surfaceWhite,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 8))
        ],
      ),
      child: Column(
        children: [
          // Top Colored Section (Header)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryGreen, accentGreen],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(25), topRight: Radius.circular(25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)),
                      child: Text(distance, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(rating, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    )
                  ],
                ),
                const SizedBox(height: 10),
                Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
          ),

          // Details Section
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(Icons.location_on_rounded, "ADDRESS", address),
                const SizedBox(height: 12),
                _buildInfoRow(Icons.access_time_filled_rounded, "OPERATING HOURS", hours),
                
                const SizedBox(height: 15),
                const Text("AVAILABLE SERVICES", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.1)),
                const SizedBox(height: 8),
                
                Wrap(
                  spacing: 8,
                  children: [
                    _serviceChip("TB Screening", const Color(0xFF2D6A4F)),
                    _serviceChip("DOTS Program", const Color(0xFF40916C)),
                    _serviceChip("Health Education", const Color(0xFF52B788)),
                  ],
                ),
                
                const SizedBox(height: 20),

                // Buttons - Updated to Unified Green Palette
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {}, // Add phone logic if desired
                        icon: const Icon(Icons.call, size: 18, color: Colors.white),
                        label: const Text("Call Now", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen, // Using Primary Dark Green
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          elevation: 2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _launchMaps(double.parse(lat), double.parse(lng)),
                        icon: const Icon(Icons.near_me_rounded, size: 18, color: Colors.white),
                        label: const Text("Directions", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentGreen, // Using Moss Green
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          elevation: 2,
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: lightBg.withOpacity(0.5), 
        borderRadius: BorderRadius.circular(15)
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: accentGreen, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
                Text(value, style: TextStyle(fontSize: 13, color: primaryGreen, fontWeight: FontWeight.w600)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _serviceChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1), 
        borderRadius: BorderRadius.circular(8), 
        border: Border.all(color: color.withOpacity(0.2))
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
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