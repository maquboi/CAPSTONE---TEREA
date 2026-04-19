import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
      backgroundColor: softWhite, // Modern off-white background
      appBar: AppBar(
        backgroundColor: softWhite, // Matches scaffold
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.02), // Softer shadow
        surfaceTintColor: softWhite, 
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            buildLogo(size: 32),
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
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.9, 
                        children: const [
                          _HoverActionCard(icon: Icons.assignment_rounded, title: 'Risk\nAssessment', subtitle: 'Check your TB risk', route: '/assess'),
                          _HoverActionCard(icon: Icons.chat_bubble_rounded, title: 'TEREA\nChatbot', subtitle: '24/7 AI Support', route: '/chat'),
                          _HoverActionCard(icon: Icons.settings_rounded, title: 'Account\nSettings', subtitle: 'Preferences', route: '/settings'),
                          _HoverActionCard(icon: Icons.help_outline_rounded, title: 'Help &\nSupport', subtitle: 'Contact Us', route: '/support'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
        ],
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

  Widget _buildBlob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(size / 2.5)),
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

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        transform: Matrix4.identity()..translate(0.0, _isHovering ? -6.0 : 0.0), // Smooth lift effect
        decoration: BoxDecoration(
          color: Colors.white, // Now starkly contrasts the softWhite Scaffold
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _isHovering ? forestMed.withOpacity(0.5) : Colors.black.withOpacity(0.03), 
            width: 1.5
          ),
          boxShadow: [
            BoxShadow(
              color: forestDark.withOpacity(_isHovering ? 0.08 : 0.02),
              blurRadius: _isHovering ? 20 : 10,
              offset: Offset(0, _isHovering ? 8 : 4),
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
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      // Modernized icon background instead of the overly bright pale green
                      color: _isHovering ? forestMed : forestMed.withOpacity(0.08), 
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      widget.icon, 
                      color: _isHovering ? Colors.white : forestMed, 
                      size: 28
                    ),
                  ),
                  const Spacer(),
                  Text(widget.title, 
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: forestDark, height: 1.2)
                  ),
                  const SizedBox(height: 6),
                  Text(widget.subtitle, 
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 11, fontWeight: FontWeight.w500, height: 1.3)
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