import 'package:flutter/material.dart';

void main() => runApp(const TereaApp());

// --- 0. DATA MODELS ---
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

// --- 1. STARTUP PAGE ---
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

// --- 2. LOGIN PAGE ---
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

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
            _buildTextField("Email", "you@example.com"),
            const SizedBox(height: 20),
            _buildTextField("Password", "........", isPassword: true),
            const SizedBox(height: 30),
            _buildPrimaryButton(context, "Sign in", () => Navigator.pushNamed(context, '/home')),
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

// --- 3. SIGN UP PAGE ---
class SignUpPage extends StatelessWidget {
  const SignUpPage({super.key});

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
                _buildLogo(size: 50),
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
            _buildTextField("Full Name", "Juan Dela Cruz"),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(child: _buildTextField("Age", "25")),
                const SizedBox(width: 15),
                Expanded(child: _buildTextField("Gender", "Select")),
              ],
            ),
            const SizedBox(height: 15),
            _buildTextField("Contact Number", "+63 912 345 6789"),
            const SizedBox(height: 15),
            _buildTextField("Email", "you@example.com"),
            const SizedBox(height: 15),
            _buildTextField("Password", "........", isPassword: true),
            const SizedBox(height: 30),
            _buildPrimaryButton(context, "Create account", () => Navigator.pushNamed(context, '/home')),
          ],
        ),
      ),
    );
  }
}

// --- 4. DASHBOARD PAGE ---
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(children: [_buildLogo(size: 32), const SizedBox(width: 10), const Text('TEREA', style: TextStyle(fontWeight: FontWeight.bold))]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Hello, Patient', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
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
      bottomNavigationBar: _buildBottomNav(0, context),
    );
  }

  Widget _buildTreatmentBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF606C38), borderRadius: BorderRadius.circular(15)),
      child: const Row(
        children: [
          Icon(Icons.monitor_heart_outlined, color: Color(0xFFFEFAE0), size: 30),
          SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Treatment Status', style: TextStyle(color: Color(0xFFFEFAE0), fontWeight: FontWeight.bold)),
              Text('Not yet assessed', style: TextStyle(color: Colors.white70)),
            ],
          )
        ],
      ),
    );
  }
}

// --- 5. ASSESSMENT PAGE ---
class AssessmentPage extends StatefulWidget {
  const AssessmentPage({super.key});

  @override
  State<AssessmentPage> createState() => _AssessmentPageState();
}

class _AssessmentPageState extends State<AssessmentPage> {
  int currentIndex = 0;
  int yesCount = 0;
  String? selected;

  final List<String> questions = [
    "Do you have a persistent cough lasting more than 2 weeks?",
    "Have you experienced unexplained weight loss recently?",
    "Do you suffer from night sweats?",
    "Have you been feeling unusually tired or fatigued?",
    "Do you have chest pain or pain when breathing?",
    "Have you noticed blood in your phlegm or cough?",
    "Have you been in close contact with someone who has TB?"
  ];

  void _handleNext() {
    if (selected == null) return;

    if (selected == "Yes") yesCount++;

    if (currentIndex < questions.length - 1) {
      setState(() {
        currentIndex++;
        selected = null;
      });
    } else {
      Navigator.pushNamed(context, '/result', arguments: yesCount);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, title: const Text('Assessment')),
      body: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Question ${currentIndex + 1} of ${questions.length}', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: (currentIndex + 1) / questions.length, 
              color: const Color(0xFF606C38), 
              backgroundColor: Colors.white
            ),
            const SizedBox(height: 40),
            Text(questions[currentIndex], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            _buildOption("Yes"),
            const SizedBox(height: 15),
            _buildOption("No"),
            const Spacer(),
            _buildPrimaryButton(
              context, 
              currentIndex < questions.length - 1 ? "Next →" : "See Results", 
              _handleNext
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(1, context),
    );
  }

  Widget _buildOption(String text) {
    bool isSel = selected == text;
    return GestureDetector(
      onTap: () => setState(() => selected = text),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSel ? const Color(0xFFE9EDC9) : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: isSel ? const Color(0xFF606C38) : Colors.transparent),
        ),
        child: Text(text, style: TextStyle(fontWeight: FontWeight.bold, color: isSel ? const Color(0xFF283618) : Colors.black54)),
      ),
    );
  }
}

// --- 6. MEDS PAGE ---
class MedsPage extends StatefulWidget {
  const MedsPage({super.key});

  @override
  State<MedsPage> createState() => _MedsPageState();
}

class _MedsPageState extends State<MedsPage> {
  List<Medicine> myMeds = [
    Medicine(name: 'Isoniazid', dosage: '300mg', time: '08:00 AM'),
    Medicine(name: 'Rifampicin', dosage: '600mg', time: '08:00 AM', isTaken: true),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(children: [_buildLogo(size: 32), const SizedBox(width: 10), const Text('TEREA', style: TextStyle(fontWeight: FontWeight.bold))]),
      ),
      body: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Medication Diary', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF283618))),
                    Text('Track your daily medicines', style: TextStyle(color: Color(0xFF606C38))),
                  ],
                ),
                _buildAddButtonSmall(),
              ],
            ),
            const SizedBox(height: 30),
            Expanded(
              child: ListView.builder(
                itemCount: myMeds.length,
                itemBuilder: (context, index) {
                  final med = myMeds[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 15),
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: const Color(0xFF606C38).withOpacity(0.1)),
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => setState(() => med.isTaken = !med.isTaken),
                          child: Icon(
                            med.isTaken ? Icons.check_circle : Icons.radio_button_unchecked,
                            color: const Color(0xFF606C38),
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(med.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF283618), decoration: med.isTaken ? TextDecoration.lineThrough : null)),
                              Text('${med.dosage}  •  ${med.time}  •  Daily', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                        ),
                        IconButton(icon: const Icon(Icons.delete_outline, color: Colors.grey), onPressed: () => setState(() => myMeds.removeAt(index))),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(2, context),
    );
  }

  Widget _buildAddButtonSmall() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: const Color(0xFF606C38), borderRadius: BorderRadius.circular(10)),
      child: const Row(children: [Icon(Icons.add, color: Colors.white, size: 18), SizedBox(width: 5), Text('Add', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))]),
    );
  }
}

// --- 7. FOLLOW-UP PAGE ---
class FollowUpPage extends StatelessWidget {
  const FollowUpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(children: [_buildLogo(size: 32), const SizedBox(width: 10), const Text('TEREA', style: TextStyle(fontWeight: FontWeight.bold))]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Follow-up', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF283618))),
            const Text('Your upcoming medical visits', style: TextStyle(color: Color(0xFF606C38))),
            const SizedBox(height: 30),
            const Text('SCHEDULED', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF606C38), letterSpacing: 1.2)),
            const SizedBox(height: 15),
            _buildAppointmentCard("General Check-up", "Feb 24, 2026", "09:00 AM", "Health Center A", isUpcoming: true),
            const SizedBox(height: 30),
            const Text('HISTORY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF606C38), letterSpacing: 1.2)),
            const SizedBox(height: 15),
            _buildAppointmentCard("Initial Consultation", "Jan 10, 2026", "10:30 AM", "Health Center A", isUpcoming: false),
            _buildAppointmentCard("Lab Test", "Jan 15, 2026", "08:00 AM", "City Lab", isUpcoming: false),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(3, context),
    );
  }

  Widget _buildAppointmentCard(String title, String date, String time, String loc, {required bool isUpcoming}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: isUpcoming ? const Color(0xFF606C38) : Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Row(
        children: [
          Icon(Icons.calendar_month, color: isUpcoming ? const Color(0xFFFEFAE0) : const Color(0xFF606C38), size: 30),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isUpcoming ? Colors.white : const Color(0xFF283618))),
                Text('$date • $time', style: TextStyle(color: isUpcoming ? Colors.white70 : Colors.grey, fontSize: 12)),
                Text(loc, style: TextStyle(color: isUpcoming ? Colors.white70 : Colors.grey, fontSize: 12, fontStyle: FontStyle.italic)),
              ],
            ),
          ),
          if (!isUpcoming) const Icon(Icons.check_circle, color: Color(0xFF606C38), size: 20),
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
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: BackButton(color: const Color(0xFF606C38), onPressed: () => Navigator.pop(context)),
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF283618))),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            _buildProfileSection(),
            const SizedBox(height: 30),
            _buildSettingsGroup("General", [
              _buildSettingsTile(Icons.person_outline, "Edit Profile"),
              _buildSettingsTile(Icons.notifications_none, "Notifications", trailing: Switch(value: true, activeColor: const Color(0xFF606C38), onChanged: (v){})),
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
      child: const Row(
        children: [
          CircleAvatar(radius: 35, backgroundColor: Color(0xFFE9EDC9), child: Icon(Icons.person, size: 40, color: Color(0xFF606C38))),
          SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Juan Dela Cruz", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF283618))),
              Text("juan.dc@example.com", style: TextStyle(color: Colors.grey)),
            ],
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

  Widget _buildSettingsTile(IconData icon, String title, {String? subtext, Widget? trailing}) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF606C38)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: subtext != null ? Text(subtext) : null,
      trailing: trailing ?? const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: () {},
    );
  }
}

// --- 10. RISK RESULT PAGE ---
class RiskResultPage extends StatelessWidget {
  const RiskResultPage({super.key});

  @override
  Widget build(BuildContext context) {
    final int score = (ModalRoute.of(context)!.settings.arguments as int? ?? 0);
    final bool isHighRisk = score >= 3;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isHighRisk ? Icons.warning_amber_rounded : Icons.check_circle_outline,
              size: 100,
              color: isHighRisk ? Colors.redAccent : const Color(0xFF606C38),
            ),
            const SizedBox(height: 20),
            Text(
              isHighRisk ? "HIGH RISK" : "LOW RISK",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: isHighRisk ? Colors.redAccent : const Color(0xFF283618),
              ),
            ),
            const SizedBox(height: 15),
            Text(
              isHighRisk
                  ? "Based on your symptoms ($score/7), we highly recommend visiting the nearest health center for a professional check-up."
                  : "Your symptoms currently suggest a lower risk ($score/7). However, if your condition worsens, please consult a doctor.",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 40),
            // Updated Section with TWO buttons
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

// --- 11. FACILITIES PAGE ---
class FacilitiesPage extends StatelessWidget {
  const FacilitiesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text("Nearby Facilities", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text("Recommended centers for TB testing:", style: TextStyle(color: Color(0xFF606C38), fontStyle: FontStyle.italic)),
          const SizedBox(height: 20),
          _buildFacilityTile("City Health Office - Main", "1.2 km away", "8:00 AM - 5:00 PM", "0912-345-6789"),
          _buildFacilityTile("Barangay Health Center A", "2.5 km away", "9:00 AM - 4:00 PM", "0917-888-2222"),
          _buildFacilityTile("Community Medical Clinic", "3.8 km away", "24/7", "0922-333-4444"),
        ],
      ),
    );
  }

  Widget _buildFacilityTile(String name, String dist, String hours, String phone) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(dist, style: const TextStyle(color: Color(0xFF606C38), fontSize: 12)),
            ],
          ),
          const Divider(height: 20),
          Row(children: [const Icon(Icons.access_time, size: 16, color: Colors.grey), const SizedBox(width: 5), Text(hours, style: const TextStyle(color: Colors.grey))]),
          const SizedBox(height: 5),
          Row(children: [const Icon(Icons.phone, size: 16, color: Colors.grey), const SizedBox(width: 5), Text(phone, style: const TextStyle(color: Colors.grey))]),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.directions, size: 18),
                  label: const Text("Directions"),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF606C38), foregroundColor: Colors.white),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.call, size: 18),
                  label: const Text("Call"),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF606C38)), foregroundColor: const Color(0xFF606C38)),
                ),
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

Widget _buildTextField(String label, String hint, {bool isPassword = false}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF283618))),
      const SizedBox(height: 8),
      TextField(
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