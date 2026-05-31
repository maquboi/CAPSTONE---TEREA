import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'shared_widgets.dart';

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

  // Theme Palette (Strictly Green, White, Grey, Light Green, Forest Green, Black)
  final Color forestDark = const Color(0xFF283618);
  final Color forestMed = const Color(0xFF606C38);  
  final Color mossGreen = const Color(0xFFADC178);
  final Color paleGreen = const Color(0xFFDDE5B6);
  final Color softWhite = const Color(0xFFF9FBF9); // Clean, light background

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

  // --- MODERN CENTERED POPUP ANIMATION ---
  void _showNotificationPopup(String message, {bool isSuccess = false}) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withOpacity(0.4),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) => const SizedBox.shrink(),
      transitionBuilder: (context, a1, a2, child) {
        final color = isSuccess ? const Color(0xFF606C38) : Colors.redAccent;
        final icon = isSuccess ? Icons.check_circle_outline_rounded : Icons.error_outline_rounded;
        
        return Transform.scale(
          scale: Curves.easeOutBack.transform(a1.value),
          child: FadeTransition(
            opacity: a1,
            child: AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              backgroundColor: Colors.white,
              contentPadding: const EdgeInsets.all(24),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 32),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    isSuccess ? "Success" : "Notice",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: const Color(0xFF2D3B1E), 
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF606C38),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        "Got it",
                        style: GoogleFonts.poppins(
                          color: Colors.white, 
                          fontWeight: FontWeight.w600, 
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
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
        _showNotificationPopup("Invalid Clinic Code. Please check again.");
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
        _showNotificationPopup("You are already connected or pending with this doctor.");
        setState(() => _isLinking = false);
        return;
      }

      // 3. Create Connection Request
      await _supabase.from('connections').insert({
        'patient_id': user.id,
        'doctor_id': doctor['id'],
        'status': 'pending',
      });

      // 4. Send Notification to Doctor
      await _supabase.from('notifications').insert({
        'doctor_id': doctor['id'],
        'patient_id': user.id,
        'title': 'New Patient Request',
        'message': '$_username is waiting for verification.',
        'type': 'request'
      });

      // 5. Update UI
      if (mounted) {
        setState(() {
          _connectionStatus = 'pending';
          _isLinking = false;
        });
        Navigator.pop(context); // Close dialog
        _showNotificationPopup("Request sent to Dr. ${doctor['full_name']}!", isSuccess: true);
      }

    } catch (e) {
      debugPrint("Linking Error: $e");
      if (e.toString().contains("duplicate")) {
         _showNotificationPopup("You have already sent a request.");
      } else {
         _showNotificationPopup("Error linking to clinic: $e");
      }
      setState(() => _isLinking = false);
    }
  }

  void _showClinicCodeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Enter Clinic Code", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Please enter the code provided by your doctor in Carmona (e.g., CMC-001).",
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _codeController,
              decoration: InputDecoration(
                hintText: "Clinic Code",
                hintStyle: TextStyle(color: Colors.grey.shade400),
                filled: true,
                fillColor: softWhite,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: Icon(Icons.qr_code, color: forestMed),
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
              backgroundColor: forestMed,
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

  // --- UI BUILD ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: softWhite,
      appBar: AppBar(
        backgroundColor: softWhite,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            buildLogo(size: 32),
            const SizedBox(width: 10),
            Text('TEREA',
              style: TextStyle(fontWeight: FontWeight.w900, color: forestDark, fontSize: 22, letterSpacing: 0.5)
            )
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: paleGreen, width: 2),
              ),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white,
                backgroundImage: _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
                child: _avatarUrl == null ? Icon(Icons.person, size: 20, color: forestDark) : null,
              ),
            ),
          )
        ],
      ),
      body: _isLoading
        ? Center(child: CircularProgressIndicator(color: forestMed))
        : RefreshIndicator(
            onRefresh: _fetchUserData,
            color: forestMed,
            backgroundColor: Colors.white,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello, ${_username.split(' ')[0]}',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.black87, letterSpacing: -0.5)
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'How are you feeling today?',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 15, fontWeight: FontWeight.w500)
                  ),
                  const SizedBox(height: 30),

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
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.grey.shade500, letterSpacing: 1.5)
                  ),
                  const SizedBox(height: 16),
                  
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.95,
                    children: const [
                      _HoverActionCard(icon: Icons.medical_services_outlined, title: 'My\nDoctor', subtitle: 'View physician info', route: '/my_doctor'),
                      _HoverActionCard(icon: Icons.assignment_outlined, title: 'Risk\nAssessment', subtitle: 'Check your TB risk', route: '/assess'),
                      _HoverActionCard(icon: Icons.chat_bubble_outline, title: 'TEREA\nChatbot', subtitle: '24/7 AI Support', route: '/chat'),
                      _HoverActionCard(icon: Icons.settings_outlined, title: 'Account\nSettings', subtitle: 'Preferences', route: '/settings'),
                      _HoverActionCard(icon: Icons.help_outline_rounded, title: 'Help &\nSupport', subtitle: 'Contact Us', route: '/support'),
                    ],
                  ),
                ],
              ),
            ),
          ),
      bottomNavigationBar: buildBottomNav(0, context),
    );
  }

  // --- WIDGETS ---
  
  // 1. NO CONNECTION
  Widget _buildConnectCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: forestDark,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: forestDark.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 8))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
                child: const Icon(Icons.link_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text("Verified Treatment", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            "Link with your Carmona doctor to unlock your full Medication Diary.",
            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _showClinicCodeDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: forestDark,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text("Enter Clinic Code", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: Icon(Icons.hourglass_empty_rounded, color: Colors.grey.shade700, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Approval Pending", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Text("Waiting for your doctor to verify your request.", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
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
        color: forestMed,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: forestMed.withOpacity(0.25), blurRadius: 15, offset: const Offset(0, 8))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
            child: const Icon(Icons.verified_user_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Verified Patient", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
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

    // Updated Risk Level Colors (Muted Red, Orange, Grey)
    Color bgColor = Colors.grey.shade500; // Default (Low)
    if (_riskLevel.toLowerCase().contains("high")) {
      bgColor = const Color(0xFFD9534F); // Muted Red
    } else if (_riskLevel.toLowerCase().contains("medium")) {
      bgColor = const Color(0xFFE67E22); // Muted Orange
    } else if (_riskLevel.toLowerCase().contains("low")) {
      bgColor = Colors.grey.shade600; // Muted Grey
    }

    BoxDecoration boxDecoration;
    if (isNotAssessed) {
      boxDecoration = BoxDecoration(
        color: paleGreen.withOpacity(0.4),
        borderRadius: BorderRadius.circular(24),
      );
    } else {
      boxDecoration = BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: bgColor.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))
        ],
      );
    }

    Color titleColor = isNotAssessed ? forestDark : Colors.white;
    Color subtitleColor = isNotAssessed ? forestDark.withOpacity(0.6) : Colors.white70;
    Color iconColor = isNotAssessed ? forestMed : Colors.white;
    Color iconBgColor = isNotAssessed ? Colors.white : Colors.white.withOpacity(0.2);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: boxDecoration,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: iconBgColor, shape: BoxShape.circle),
            child: Icon(Icons.monitor_heart_rounded, color: iconColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Treatment Status',
                  style: TextStyle(color: subtitleColor, fontWeight: FontWeight.w600, fontSize: 12, letterSpacing: 0.5)
                ),
                const SizedBox(height: 4),
                Text(displayText,
                  style: TextStyle(color: titleColor, fontSize: 18, fontWeight: FontWeight.w800)
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

// --- NEW STATEFUL WIDGET FOR HOVER EFFECTS ---
class _HoverActionCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String route;

  const _HoverActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
  });

  @override
  State<_HoverActionCard> createState() => _HoverActionCardState();
}

class _HoverActionCardState extends State<_HoverActionCard> {
  bool _isHovering = false;
  final Color forestDark = const Color(0xFF283618);
  final Color forestMed = const Color(0xFF606C38);
  final Color paleGreen = const Color(0xFFDDE5B6);

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutQuart,
        transform: Matrix4.identity()..translate(0.0, _isHovering ? -4.0 : 0.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(_isHovering ? 0.08 : 0.03),
              blurRadius: _isHovering ? 20 : 10,
              offset: Offset(0, _isHovering ? 10 : 4),
            )
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => Navigator.pushNamed(context, widget.route),
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: paleGreen.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.icon,
                      color: forestMed,
                      size: 24
                    ),
                  ),
                  const Spacer(),
                  Text(widget.title,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87, height: 1.2)
                  ),
                  const SizedBox(height: 6),
                  Text(widget.subtitle,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.w500)
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}