import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; 


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
    return Scaffold(
      body: InkWell(
        onTap: () => Navigator.pushNamed(context, '/login'),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLogo(size: 100),
              const SizedBox(height: 20),
              const Text('TEREA', style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, letterSpacing: 4, color: Color(0xFF283618))),
              const Text('Tap to continue', style: TextStyle(fontStyle: FontStyle.italic, color: Color(0xFF606C38))),
            ],
          ),
        ),
      ),
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Login Failed: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 80),
        child: Column(
          children: [
            _buildLogo(size: 60),
            const SizedBox(height: 20),
            const Text('Welcome back', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF283618))),
            const Text('Sign in to continue', style: TextStyle(color: Color(0xFF606C38))),
            const SizedBox(height: 40),
            _buildTextField("Email", "you@example.com", controller: _emailController),
            const SizedBox(height: 20),
            _buildTextField("Password", "........", isPassword: true, controller: _passwordController),
            const SizedBox(height: 30),
            _isLoading 
                ? const CircularProgressIndicator()
                : _buildPrimaryButton(context, "Sign in", _signIn),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/signup'),
              child: const Text("Don't have an account? Sign up", style: TextStyle(color: Color(0xFF606C38))),
            ),
          ],
        ),
      ),
    );
  }
}

// ign Up Page natin 
class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
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
          'gender': _selectedGender, // Saves the dropdown value
          'contact_number': _contactController.text.trim(),
          'email': _emailController.text.trim(),
        });
        if (mounted) Navigator.pushNamed(context, '/home');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Registration Error: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, leading: const BackButton(color: Color(0xFF606C38))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.local_hospital, size: 50, color: Color(0xFF283618)),
                const SizedBox(width: 15),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Create account', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF283618))),
                    Text('Join TEREA today', style: TextStyle(color: Color(0xFF606C38))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 30),
            _buildTextField("Full Name", "Juan Dela Cruz", controller: _nameController),
            const SizedBox(height: 15),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: _buildTextField("Age", "25", controller: _ageController)),
                const SizedBox(width: 15),
                // --- DROPDOWN FOR GENDER ---
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Gender", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF283618))),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedGender,
                            hint: const Text("Select", style: TextStyle(fontSize: 14, color: Colors.grey)),
                            isExpanded: true,
                            items: _genderOptions.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (newValue) {
                              setState(() {
                                _selectedGender = newValue;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ), 
              ],
            ),
            const SizedBox(height: 15),
            _buildTextField("Contact Number", "+63 912 345 6789", controller: _contactController),
            const SizedBox(height: 15),
            _buildTextField("Email", "you@example.com", controller: _emailController),
            const SizedBox(height: 15),
            _buildTextField("Password", "........", isPassword: true, controller: _passwordController),
            const SizedBox(height: 30),
            _isLoading 
              ? const CircularProgressIndicator()
              : _buildPrimaryButton(context, "Create account", _handleSignUp),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String hint, {required TextEditingController controller, bool isPassword = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF283618))),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryButton(BuildContext context, String text, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF606C38),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
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

  // Fetches latest profile data (Name, Photo, and Assessment Result)
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            _buildLogo(size: 32), 
            const SizedBox(width: 10), 
            const Text('TEREA', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF283618)))
          ],
        ),
        actions: [
          // Small profile icon in top right
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFFE9EDC9),
              backgroundImage: _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
              child: _avatarUrl == null ? const Icon(Icons.person, size: 20, color: Color(0xFF606C38)) : null,
            ),
          )
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF606C38)))
        : RefreshIndicator(
            onRefresh: _fetchUserData, // Pull to refresh data
            color: const Color(0xFF606C38),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(25),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Hello, $_username', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF283618))),
                  const Text('How are you feeling today?', style: TextStyle(color: Color(0xFF606C38))),
                  const SizedBox(height: 25),
                  _buildTreatmentBanner(),
                  const SizedBox(height: 30),
                  const Text('QUICK ACTIONS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF606C38), letterSpacing: 1.2)),
                  const SizedBox(height: 15),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                    children: [
                      _buildActionCard(context, Icons.assignment_outlined, 'Risk Assessment', 'Check your TB risk', '/assess'),
                      _buildActionCard(context, Icons.medication_outlined, 'Medication Diary', 'Track your medicines', '/meds'),
                      _buildActionCard(context, Icons.calendar_today_outlined, 'Follow-up', 'Upcoming appointments', '/followup'),
                      _buildActionCard(context, Icons.chat_bubble_outline, 'Chatbot', 'Get instant help', '/chat'),
                      _buildActionCard(context, Icons.settings_outlined, 'Settings', 'Profile & preferences', '/settings'),
                    ],
                  ),
                ],
              ),
            ),
          ),
      bottomNavigationBar: _buildBottomNav(0, context),
    );
  }

  Widget _buildTreatmentBanner() {
    // Dynamic styling based on Risk Level
    Color bannerColor = const Color(0xFF606C38);
    if (_riskLevel.contains("High")) bannerColor = Colors.redAccent;
    if (_riskLevel.contains("Medium")) bannerColor = const Color(0xFFBC6C25);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: bannerColor, borderRadius: BorderRadius.circular(15)),
      child: Row(
        children: [
          const Icon(Icons.monitor_heart_outlined, color: Color(0xFFFEFAE0), size: 30),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Treatment Status', style: TextStyle(color: Color(0xFFFEFAE0), fontWeight: FontWeight.bold)),
                Text(_riskLevel, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
              ],
            ),
          )
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
  bool showResult = false;
  bool _showError = false;

  // 12 Targeted TB Screening Questions
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
      _calculateAndSaveResult();
    }
  }

  Future<void> _calculateAndSaveResult() async {
    String finalRisk = "Low Risk";
    if (riskScore >= 12) finalRisk = "High Risk";
    else if (riskScore >= 6) finalRisk = "Medium Risk";

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        // Updates the risk_level column in the profiles table
        await Supabase.instance.client
            .from('profiles')
            .update({'risk_level': finalRisk})
            .eq('id', user.id);
      }
    } catch (e) {
      debugPrint('Error updating database: $e');
    }

    if (mounted) {
      setState(() => showResult = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (showResult) return _buildResultPage();

    return Scaffold(
      backgroundColor: const Color(0xFFFEFAE0),
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        title: const Text('Assessment', style: TextStyle(color: Color(0xFF283618), fontWeight: FontWeight.bold)),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text('Question ${currentIndex + 1} of ${questions.length}', style: const TextStyle(color: Color(0xFF606C38))),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: (currentIndex + 1) / questions.length,
                minHeight: 10,
                color: const Color(0xFF606C38),
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 40),
            Text(questions[currentIndex]['q'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF283618))),
            if (_showError) const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Text("This question is required", style: TextStyle(color: Colors.redAccent, fontSize: 14, fontWeight: FontWeight.w500)),
            ),
            const SizedBox(height: 30),
            _buildHoverOption("Yes"),
            const SizedBox(height: 15),
            _buildHoverOption("No"),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF606C38), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                onPressed: _handleNext,
                child: Text(currentIndex < questions.length - 1 ? "Next →" : "See Results", style: const TextStyle(color: Colors.white, fontSize: 18)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(1, context),
    );
  }

  Widget _buildHoverOption(String text) {
    bool isSel = selected == text;
    return InkWell(
      onTap: () => setState(() => selected = text),
      borderRadius: BorderRadius.circular(15),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSel ? const Color(0xFFDDA15E).withOpacity(0.2) : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: isSel ? const Color(0xFFBC6C25) : Colors.transparent, width: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(text, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isSel ? const Color(0xFF283618) : Colors.black54)),
            if (isSel) const Icon(Icons.check_circle, color: Color(0xFF606C38))
          ],
        ),
      ),
    );
  }

  Widget _buildResultPage() {
    String riskTitle = riskScore >= 12 ? "HIGH RISK" : (riskScore >= 6 ? "MEDIUM RISK" : "LOW RISK");
    Color riskColor = riskScore >= 12 ? Colors.redAccent : (riskScore >= 6 ? const Color(0xFFBC6C25) : const Color(0xFF606C38));

    return Scaffold(
      backgroundColor: const Color(0xFFFEFAE0),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: const Text("Assessment Results", style: TextStyle(color: Color(0xFF283618))), automaticallyImplyLeading: false),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            // Header Info
            Align(alignment: Alignment.centerLeft, child: Text("Completed on ${DateFormat('MMMM d, yyyy').format(DateTime.now())}", style: const TextStyle(color: Colors.grey))),
            const SizedBox(height: 20),
            
            // Result Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: riskColor.withOpacity(0.1))),
              child: Column(
                children: [
                  Icon(Icons.report_problem_outlined, size: 64, color: riskColor),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFFDDA15E), borderRadius: BorderRadius.circular(20)),
                    child: const Text("IMPORTANT", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                  const SizedBox(height: 12),
                  Text(riskTitle, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: riskColor)),
                  const SizedBox(height: 12),
                  const Text("Some of your symptoms warrant medical attention. Schedule a check-up with a healthcare provider soon.", textAlign: TextAlign.center, style: TextStyle(color: Colors.black54, height: 1.4)),
                ],
              ),
            ),
            
            const SizedBox(height: 25),
            _buildRecommendedSection(),
            const SizedBox(height: 25),
            
            // Link Buttons
            _buildNavListTile("Return to Dashboard", Icons.dashboard_outlined, () => Navigator.pushNamed(context, '/home')),
            _buildNavListTile("Take the Test Again", Icons.restart_alt, () => setState(() { showResult = false; currentIndex = 0; riskScore = 0; selected = null; })),
            _buildNavListTile("Chat with AI Chatbot", Icons.chat_outlined, () => Navigator.pushNamed(context, '/chat')),
            _buildNavListTile("View Nearby Facilities", Icons.location_on_outlined, () {
               Navigator.push(context, MaterialPageRoute(builder: (context) => const FacilitiesPage()));
            }),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendedSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [Icon(Icons.info_outline, color: Colors.blue, size: 20), SizedBox(width: 10), Text("Recommended Actions", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))]),
          const SizedBox(height: 15),
          _bulletItem("Schedule a medical consultation within 3-5 days"),
          _bulletItem("Monitor your symptoms daily"),
          _bulletItem("Maintain good hygiene practices"),
          _bulletItem("Get adequate rest and nutrition"),
          _bulletItem("Consider getting a TB screening test"),
        ],
      ),
    );
  }

  Widget _bulletItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text("• ", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF606C38))),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 14, color: Colors.black87))),
      ]),
    );
  }

  Widget _buildNavListTile(String title, IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: const Color(0xFF606C38)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
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
  String _viewType = 'Week'; // Can be 'Day', 'Week', 'Month'

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
      'is_taken': false, // Default to not taken
    };

    try {
      if (medId == null) {
        await Supabase.instance.client.from('medications').insert(medData);
      } else {
        await Supabase.instance.client.from('medications').update(medData).eq('id', medId);
      }
      _fetchMeds(); // Refresh list after save
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

  // FIXED: The missing logic you requested
  Future<void> _toggleMed(bool currentValue, String medId) async {
    try {
      // 1. Update the database
      await Supabase.instance.client
          .from('medications')
          .update({'is_taken': !currentValue}) // Flip the value
          .eq('id', medId);
      
      // 2. Refresh the local list to show the checkmark immediately
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
          backgroundColor: const Color(0xFFFEFAE0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(existingMed == null ? "Add Medication" : "Edit Medication", 
            style: const TextStyle(color: Color(0xFF283618), fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: "Medicine Name")),
                TextField(controller: dosageController, decoration: const InputDecoration(labelText: "Dosage")),
                ListTile(
                  title: const Text("Daily Time", style: TextStyle(fontSize: 14)),
                  subtitle: Text(selectedTime),
                  trailing: const Icon(Icons.access_time),
                  onTap: () async {
                    TimeOfDay? picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                    if (picked != null) setDialogState(() => selectedTime = picked.format(context));
                  },
                ),
                ListTile(
                  title: const Text("Duration", style: TextStyle(fontSize: 14)),
                  subtitle: Text("${DateFormat('MMM d').format(startDate)} to ${DateFormat('MMM d').format(endDate)}"),
                  trailing: const Icon(Icons.date_range),
                  onTap: () async {
                    DateTimeRange? picked = await showDateRangePicker(
                      context: context, 
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
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
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF606C38)),
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
              child: const Text("Save", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // --- BUILD METHODS ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEFAE0),
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0, automaticallyImplyLeading: false,
        title: Row(children: [
          _buildLogo(size: 32), const SizedBox(width: 10), // Assumes _buildLogo exists in main.dart
          const Text('TEREA', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF283618)))
        ]),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.calendar_month, color: Color(0xFF606C38)),
            onSelected: (value) => setState(() => _viewType = value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'Day', child: Text('View By Day')),
              const PopupMenuItem(value: 'Week', child: Text('View By Week')),
              const PopupMenuItem(value: 'Month', child: Text('View By Month')),
            ],
          )
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF606C38)))
        : Column(
            children: [
              _buildHeader(),
              _buildCalendarSection(),
              const SizedBox(height: 10),
              Expanded(child: _buildMedList()),
            ],
          ),
      bottomNavigationBar: _buildBottomNav(2, context), // Assumes _buildBottomNav exists in main.dart
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Medication Diary', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF283618))),
              Text('$_viewType View • ${DateFormat('MMMM yyyy').format(_selectedDate)}', style: const TextStyle(color: Color(0xFF606C38))),
            ],
          ),
          ElevatedButton.icon(
            onPressed: () => _showMedDialog(),
            icon: const Icon(Icons.add, size: 18, color: Colors.white),
            label: const Text("Add", style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF606C38), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarSection() {
    if (_viewType == 'Month') {
      return SizedBox(height: 320, child: _buildMonthGrid());
    } else if (_viewType == 'Day') {
      return Center(child: _buildDateCard(_selectedDate, true));
    } else {
      // Default to Week view
      return SizedBox(height: 100, child: _buildWeekStrip());
    }
  }

  Widget _buildWeekStrip() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: 14, // 2 weeks range
      itemBuilder: (context, index) {
        DateTime date = DateTime.now().add(Duration(days: index - 3));
        bool isSelected = date.day == _selectedDate.day && date.month == _selectedDate.month;
        return _buildDateCard(date, isSelected);
      },
    );
  }

  Widget _buildMonthGrid() {
    // Calculate accurate days in month
    int daysInMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 0).day;
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => setState(() => _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1))),
            Text(DateFormat('MMMM yyyy').format(_selectedDate), style: const TextStyle(fontWeight: FontWeight.bold)),
            IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => setState(() => _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1))),
          ],
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
            itemCount: daysInMonth,
            itemBuilder: (context, index) {
              DateTime date = DateTime(_selectedDate.year, _selectedDate.month, index + 1);
              bool isSelected = date.day == _selectedDate.day && date.month == _selectedDate.month;
              return _buildDateCard(date, isSelected, compact: true);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDateCard(DateTime date, bool isSelected, {bool compact = false}) {
    return GestureDetector(
      onTap: () => setState(() => _selectedDate = date),
      child: Container(
        width: compact ? null : 60,
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF606C38) : Colors.white.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF606C38).withOpacity(0.1)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(DateFormat('E').format(date)[0], 
              style: TextStyle(fontSize: 10, color: isSelected ? Colors.white70 : Colors.grey)),
            Text(date.day.toString(), 
              style: TextStyle(fontSize: compact ? 14 : 18, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : const Color(0xFF283618))),
          ],
        ),
      ),
    );
  }

  Widget _buildMedList() {
    // Filter logic: Ensure we compare just the DATE part, ignoring the exact time
    final filteredMeds = myMeds.where((med) {
      DateTime start = DateTime.parse(med['start_date']);
      DateTime end = DateTime.parse(med['end_date']);
      
      // Normalize dates to midnight (00:00:00) for accurate comparison
      DateTime startDate = DateTime(start.year, start.month, start.day);
      DateTime endDate = DateTime(end.year, end.month, end.day);
      DateTime selectedDate = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);

      // Check if selectedDate is within start and end (inclusive)
      return !selectedDate.isBefore(startDate) && !selectedDate.isAfter(endDate);
    }).toList();

    if (filteredMeds.isEmpty) return const Center(child: Text("No medicines scheduled for this day."));
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      itemCount: filteredMeds.length,
      itemBuilder: (context, index) {
        final med = filteredMeds[index];
        bool isTaken = med['is_taken'] ?? false;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
          child: Row(
            children: [
              IconButton(
                // Dynamic Icon: Green Check or Grey Circle
                icon: Icon(isTaken ? Icons.check_circle : Icons.radio_button_unchecked, 
                  color: isTaken ? const Color(0xFF606C38) : Colors.grey),
                // Calls the fixed _toggleMed function
                onPressed: () => _toggleMed(isTaken, med['id'].toString()),
              ),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(med['name'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, 
                    decoration: isTaken ? TextDecoration.lineThrough : null, // Strikethrough if taken
                    color: isTaken ? Colors.grey : Colors.black
                  )),
                  Text('${med['dosage']} • Daily at ${med['time']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ]),
              ),
              IconButton(icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.blueGrey), onPressed: () => _showMedDialog(existingMed: med)),
              IconButton(icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent), onPressed: () => _deleteMed(med['id'].toString())),
            ],
          ),
        );
      },
    );
  }
}

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
      backgroundColor: const Color(0xFFFEFAE0),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 25, right: 25, top: 25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Add Appointment", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF283618))),
              TextField(controller: docController, decoration: const InputDecoration(labelText: "Doctor/Clinic")),
              TextField(controller: locController, decoration: const InputDecoration(labelText: "Location")),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  TextButton.icon(
                    onPressed: () async {
                      final pickedDate = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2030));
                      if (pickedDate != null) setModalState(() => selectedDate = pickedDate);
                    }, 
                    icon: const Icon(Icons.calendar_month), 
                    label: Text(selectedDate == null ? "Date" : DateFormat('MMM dd').format(selectedDate!))
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      final pickedTime = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                      if (pickedTime != null) setModalState(() => selectedTime = pickedTime);
                    }, 
                    icon: const Icon(Icons.access_time), 
                    label: Text(selectedTime == null ? "Time" : selectedTime!.format(context))
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF606C38), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
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
                        debugPrint('Save Appointment Error: $e');
                        setModalState(() => isSaving = false);
                      }
                    }
                  },
                  child: isSaving 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("Save Appointment", style: TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEFAE0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Row(
          children: [
            Icon(Icons.local_hospital, color: Color(0xFF283618), size: 32), 
            SizedBox(width: 10),
            Text('TEREA', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF283618)))
          ],
        ),
      ),
      body: _isLoading 
      ? const Center(child: CircularProgressIndicator(color: Color(0xFF606C38)))
      : SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Follow-up', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF283618))),
            const Text('Your progress & upcoming visits', style: TextStyle(color: Color(0xFF606C38))),
            const SizedBox(height: 20),
            _buildStreakCard(),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Appointments", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF283618))),
                IconButton(onPressed: _showAddAppointmentModal, icon: const Icon(Icons.add_circle, color: Color(0xFF606C38), size: 28)),
              ],
            ),
            const SizedBox(height: 10),
            if (_appointments.isEmpty) 
              const Padding(padding: EdgeInsets.all(10), child: Text("No appointments scheduled.", style: TextStyle(color: Colors.grey))),
            ..._appointments.map((appt) => Dismissible(
              key: Key(appt['id'].toString()),
              direction: DismissDirection.endToStart,
              onDismissed: (dir) => _deleteAppointment(appt['id'].toString()),
              background: Container(
                decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(15)),
                alignment: Alignment.centerRight, 
                padding: const EdgeInsets.only(right: 20),
                child: const Icon(Icons.delete, color: Colors.white)
              ),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildAppointmentCard(appt['doctor_name'], appt['appointment_date'], appt['appointment_time'], appt['location'] ?? ""),
              ),
            )),
            const SizedBox(height: 30),
            const Text("Ask Your Doctor", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF283618))),
            const Text("Write down questions so you don't forget.", style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _noteController,
                    decoration: InputDecoration(
                      hintText: "Type a question...",
                      filled: true, fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                FloatingActionButton.small(
                  onPressed: _addNote,
                  backgroundColor: const Color(0xFF606C38),
                  elevation: 0,
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 15),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _doctorNotes.length,
              itemBuilder: (context, index) {
                final note = _doctorNotes[index];
                bool isChecked = note['is_checked'] ?? false;
                return AnimatedOpacity(
                  duration: const Duration(milliseconds: 400),
                  opacity: isChecked ? 0.3 : 1.0,
                  child: Dismissible(
                    key: Key(note['id'].toString()),
                    direction: DismissDirection.endToStart,
                    onDismissed: (direction) => _deleteNote(note['id'].toString()),
                    background: Container(color: Colors.red, alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), child: const Icon(Icons.delete, color: Colors.white)),
                    child: Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: CheckboxListTile(
                        activeColor: const Color(0xFF606C38),
                        title: Text(note['note_text'], style: TextStyle(decoration: isChecked ? TextDecoration.lineThrough : null, color: isChecked ? Colors.grey : Colors.black87)),
                        value: isChecked,
                        onChanged: (bool? value) => _toggleNote(index, isChecked),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF606C38), Color(0xFF283618)]),
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))]
      ),
      child: Row(
        children: [
          const Icon(Icons.local_fire_department, color: Colors.orangeAccent, size: 30),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$_streakDays Day Streak!', style: const TextStyle(color: Color(0xFFFEFAE0), fontWeight: FontWeight.bold, fontSize: 18)),
              const Text('Keep up the good work!', style: TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(String title, String date, String time, String loc) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF606C38), borderRadius: BorderRadius.circular(15)),
      child: Row(
        children: [
          const Icon(Icons.calendar_month, color: Color(0xFFFEFAE0)),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                Text('$date • $time', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                if (loc.isNotEmpty) Text(loc, style: const TextStyle(color: Colors.white60, fontSize: 11)),
              ],
            ),
          ),
        ],
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

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  // Fetch data from Supabase Profiles table
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

  // Change Username Logic
  Future<void> _updateUsername() async {
    final controller = TextEditingController(text: _username);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Update Username"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Enter new username"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                await _supabase.from('profiles').update({'full_name': newName}).eq('id', _supabase.auth.currentUser!.id);
                setState(() => _username = newName);
                if (mounted) Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF606C38)),
            child: const Text("Save", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  // Upload Photo Logic
  Future<void> _uploadPhoto() async {
    try {
      // Pick the file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final fileBytes = file.bytes; // Necessary for Chrome/Web
      final userId = _supabase.auth.currentUser!.id;
      final fileName = '$userId/profile_${DateTime.now().millisecondsSinceEpoch}.png';

      if (fileBytes != null) {
        // Show a loading snackbar
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Uploading photo...")));

        // 1. Upload to Storage
        await _supabase.storage.from('avatars').uploadBinary(
          fileName,
          fileBytes,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
        );

        // 2. Get Public URL
        final String publicUrl = _supabase.storage.from('avatars').getPublicUrl(fileName);

        // 3. Update Database Profile
        await _supabase.from('profiles').update({'avatar_url': publicUrl}).eq('id', userId);

        setState(() => _avatarUrl = publicUrl);
        
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Photo updated!")));
      }
    } catch (e) {
      debugPrint('Upload failed: $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Upload failed. Check Supabase Storage permissions.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: const Color(0xFF606C38), onPressed: () => Navigator.pop(context)),
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF283618))),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF606C38)))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(25),
            child: Column(
              children: [
                _buildProfileSection(),
                const SizedBox(height: 30),
                _buildSettingsGroup("General", [
                  _buildSettingsTile(Icons.person_outline, "Edit Username", onTap: _updateUsername),
                  _buildSettingsTile(Icons.notifications_none, "Notifications", 
                      trailing: Switch(value: true, activeColor: const Color(0xFF606C38), onChanged: (v){})),
                  _buildSettingsTile(Icons.language, "Language", subtext: "English"),
                ]),
                const SizedBox(height: 20),
                _buildSettingsGroup("Privacy & Support", [
                  _buildSettingsTile(Icons.lock_outline, "Privacy Policy"),
                  _buildSettingsTile(Icons.help_outline, "Help Center"),
                  _buildSettingsTile(Icons.info_outline, "About TEREA"),
                ]),
                const SizedBox(height: 40),
                _buildPrimaryButton(context, "Log Out", () => Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false)),
              ],
            ),
          ),
    );
  }

  Widget _buildProfileSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 35, 
                backgroundColor: const Color(0xFFE9EDC9),
                backgroundImage: _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
                child: _avatarUrl == null ? const Icon(Icons.person, size: 40, color: Color(0xFF606C38)) : null,
              ),
              Positioned(
                bottom: 0, right: 0,
                child: GestureDetector(
                  onTap: _uploadPhoto,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Color(0xFF606C38), shape: BoxShape.circle),
                    child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
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
                Text(_username, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF283618))),
                Text(_email, style: const TextStyle(color: Colors.grey, fontSize: 13)),
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
          padding: const EdgeInsets.only(left: 10, bottom: 10),
          child: Text(title.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF606C38), letterSpacing: 1.2)),
        ),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
          child: Column(children: tiles),
        ),
      ],
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, {String? subtext, Widget? trailing, VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF606C38)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: subtext != null ? Text(subtext) : null,
      trailing: trailing ?? const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap ?? () {},
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
}

// --- 10. RISK RESULT PAGE ---
class RiskResultPage extends StatelessWidget {
  const RiskResultPage({super.key});

  @override
  Widget build(BuildContext context) {
    final int score = (ModalRoute.of(context)!.settings.arguments as int? ?? 0);
    
    // Updated logic to match the 12/6 assessment thresholds
    final bool isHighRisk = score >= 12;
    final bool isMediumRisk = score >= 6 && score < 12;

    String riskLabel = isHighRisk ? "HIGH RISK" : (isMediumRisk ? "MEDIUM RISK" : "LOW RISK");
    Color riskColor = isHighRisk ? Colors.redAccent : (isMediumRisk ? const Color(0xFFBC6C25) : const Color(0xFF606C38));

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isHighRisk ? Icons.warning_amber_rounded : (isMediumRisk ? Icons.info_outline : Icons.check_circle_outline),
              size: 100,
              color: riskColor,
            ),
            const SizedBox(height: 20),
            Text(
              riskLabel,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: riskColor,
              ),
            ),
            const SizedBox(height: 15),
            Text(
              isHighRisk
                  ? "Based on your symptoms ($score points), we highly recommend visiting the nearest health center for a professional check-up."
                  : (isMediumRisk 
                      ? "Your symptoms suggest a moderate risk ($score points). Please monitor your health and consider a consultation."
                      : "Your symptoms currently suggest a lower risk ($score points). However, if your condition worsens, please consult a doctor."),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 40),
            _buildPrimaryButton(context, "View Nearby Facilities", () {
              Navigator.pushNamed(context, '/facilities');
            }),
            const SizedBox(height: 15),
            OutlinedButton(
              onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 55),
                side: const BorderSide(color: Color(0xFF606C38)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Return to Dashboard", style: TextStyle(color: Color(0xFF606C38), fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

// --- 7. FACILITIES PAGE (MAP + LIST) ---
class FacilitiesPage extends StatefulWidget {
  const FacilitiesPage({super.key});

  @override
  State<FacilitiesPage> createState() => _FacilitiesPageState();
}

class _FacilitiesPageState extends State<FacilitiesPage> {
  // Center of Carmona, Cavite (Adjust as needed)
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
    final Uri url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEFAE0),
      appBar: AppBar(
        title: const Text('Nearby Facilities', style: TextStyle(color: Color(0xFF283618), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Map Section - The part that was crashing
          SizedBox(
            height: 300,
            child: GoogleMap(
              initialCameraPosition: const CameraPosition(target: _carmonaCenter, zoom: 14),
              markers: _markers,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: true,
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("Recommended centers for TB testing.", style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
          ),
          // Facilities List Section
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              children: [
                _buildFacilityCard('City Health Office - Main', '8:00 AM - 5:00 PM', '14.3122', '121.0558'),
                _buildFacilityCard('Barangay Health Center A', '9:00 AM - 4:00 PM', '14.3050', '121.0600'),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(3, context), // Assumes _buildBottomNav exists in your main.dart
    );
  }

  Widget _buildFacilityCard(String name, String hours, String lat, String lng) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 5),
          Row(children: [
            const Icon(Icons.access_time, size: 16, color: Colors.grey),
            const SizedBox(width: 5),
            Text(hours, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ]),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _launchMaps(double.parse(lat), double.parse(lng)),
                  icon: const Icon(Icons.directions, color: Colors.white),
                  label: const Text("Directions", style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF606C38)),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: () {}, // Add call logic if needed
                icon: const Icon(Icons.phone),
                label: const Text("Call"),
                style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF606C38)),
              ),
            ],
          )
        ],
      ),
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