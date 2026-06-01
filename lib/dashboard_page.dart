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

  // Theme Palette
  final Color forestDark = const Color(0xFF283618);
  final Color forestMed = const Color(0xFF606C38);  
  final Color mossGreen = const Color(0xFFADC178);
  final Color paleGreen = const Color(0xFFDDE5B6);
  final Color softWhite = const Color(0xFFF9FBF9);

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

  void _setupRealtimeListener() {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

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
        final profileData = await _supabase
            .from('profiles')
            .select('full_name, avatar_url, risk_level')
            .eq('id', user.id)
            .single();

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

  void _showNotificationPopup(String message, {bool isSuccess = false, IconData? customIcon}) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withOpacity(0.4),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) => const SizedBox.shrink(),
      transitionBuilder: (context, a1, a2, child) {
        final color = isSuccess ? const Color(0xFF606C38) : Colors.redAccent;
        final icon = customIcon ?? (isSuccess ? Icons.check_circle_outline_rounded : Icons.error_outline_rounded);
        
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
                    decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                    child: Icon(icon, color: color, size: 32),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    isSuccess ? "Success" : "Notice",
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18, color: const Color(0xFF2D3B1E)),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 14, color: Colors.black87),
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
                      child: Text("Got it", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
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

  Future<void> _submitClinicCode() async {
    // ... [KEEP YOUR EXISTING CODE LOGIC HERE] ...
    if (_codeController.text.trim().isEmpty) return;

    setState(() => _isLinking = true);
    final code = _codeController.text.trim();
    final user = _supabase.auth.currentUser;

    try {
      final doctor = await _supabase.from('profiles').select('id, full_name').eq('clinic_code', code).eq('role', 'doctor').maybeSingle();

      if (doctor == null) {
        _showNotificationPopup("Invalid Clinic Code. Please check again.");
        setState(() => _isLinking = false);
        return;
      }

      final existing = await _supabase.from('connections').select().eq('patient_id', user!.id).eq('doctor_id', doctor['id']).maybeSingle();

      if (existing != null) {
        _showNotificationPopup("You are already connected or pending with this doctor.");
        setState(() => _isLinking = false);
        return;
      }

      await _supabase.from('connections').insert({'patient_id': user.id, 'doctor_id': doctor['id'], 'status': 'pending'});
      await _supabase.from('notifications').insert({'doctor_id': doctor['id'], 'patient_id': user.id, 'title': 'New Patient Request', 'message': '$_username is waiting for verification.', 'type': 'request'});

      if (mounted) {
        setState(() {
          _connectionStatus = 'pending';
          _isLinking = false;
        });
        Navigator.pop(context);
        _showNotificationPopup("Request sent to Dr. ${doctor['full_name']}!", isSuccess: true);
      }
    } catch (e) {
      if (e.toString().contains("duplicate")) {
         _showNotificationPopup("You have already sent a request.");
      } else {
         _showNotificationPopup("Error linking to clinic: $e");
      }
      setState(() => _isLinking = false);
    }
  }

  void _showClinicCodeDialog() {
    // ... [KEEP YOUR EXISTING DIALOG LOGIC HERE] ...
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Enter Clinic Code", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Please enter the code provided by your doctor in Carmona (e.g., CMC-001).", style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
            const SizedBox(height: 20),
            TextField(
              controller: _codeController,
              decoration: InputDecoration(
                hintText: "Clinic Code",
                hintStyle: TextStyle(color: Colors.grey.shade400),
                filled: true,
                fillColor: softWhite,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                prefixIcon: Icon(Icons.qr_code, color: forestMed),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: forestMed, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: _isLinking ? null : _submitClinicCode,
            child: _isLinking ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text("Connect", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool hasAssessed = _riskLevel != "Not yet assessed";
    bool isConnected = _connectionStatus == 'active';
    bool isPending = _connectionStatus == 'pending';

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
            Text('TEREA', style: TextStyle(fontWeight: FontWeight.w900, color: forestDark, fontSize: 22, letterSpacing: 0.5))
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Container(
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: paleGreen, width: 2)),
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
                  Text('Hello, ${_username.split(' ')[0]}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.black87, letterSpacing: -0.5)),
                  const SizedBox(height: 4),
                  Text('How are you feeling today?', style: TextStyle(color: Colors.grey.shade600, fontSize: 15, fontWeight: FontWeight.w500)),
                  
                  const SizedBox(height: 30),

                  // 1. DYNAMIC ROADMAP
                  _buildTreatmentRoadmap(hasAssessed, isConnected, isPending),
                  
                  const SizedBox(height: 30),

                  // 2. CONNECT / PENDING / ACTIVE CARDS
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

                  _buildTreatmentBanner(),
                  
                  const SizedBox(height: 35),
                  Text('QUICK ACTIONS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.grey.shade500, letterSpacing: 1.5)),
                  const SizedBox(height: 16),
                  
                  // 3. ACTIONS GRID WITH LOCKS
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.95,
                    children: [
                      _HoverActionCard(
                        icon: Icons.assignment_outlined, 
                        title: 'Risk\nAssessment', 
                        subtitle: hasAssessed ? 'View results' : 'Check TB risk', 
                        route: '/assess',
                        isLocked: false,
                      ),
                      _HoverActionCard(
                        icon: Icons.medical_services_outlined, 
                        title: 'My\nDoctor', 
                        subtitle: isConnected ? 'View physician' : 'Requires Clinic', 
                        route: '/my_doctor',
                        isLocked: !isConnected,
                        onLockedTap: () => _showNotificationPopup("Please connect to a clinic first to view your doctor.", customIcon: Icons.lock_outline),
                      ),
                      _HoverActionCard(
                        icon: Icons.medication_outlined, 
                        title: 'Medication\nDiary', 
                        subtitle: isConnected ? 'Track doses' : 'Requires Clinic', 
                        route: '/meds',
                        isLocked: !isConnected,
                        onLockedTap: () => _showNotificationPopup("Your doctor needs to prescribe a treatment plan before you can use the diary.", customIcon: Icons.lock_outline),
                      ),
                      _HoverActionCard(
                        icon: Icons.calendar_month_outlined, 
                        title: 'Follow-Up\nCalendar', 
                        subtitle: 'View appointments', 
                        route: '/followup',
                        isLocked: !isConnected,
                        onLockedTap: () => _showNotificationPopup("Clinic verification required to view appointments.", customIcon: Icons.lock_outline),
                      ),
                      _HoverActionCard(
                        icon: Icons.chat_bubble_outline, 
                        title: 'TEREA\nChatbot', 
                        subtitle: '24/7 AI Support', 
                        route: '/chat',
                        isLocked: false,
                      ),
                      _HoverActionCard(
                        icon: Icons.settings_outlined, 
                        title: 'Account\nSettings', 
                        subtitle: 'Preferences', 
                        route: '/settings',
                        isLocked: false,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      bottomNavigationBar: buildBottomNav(0, context),
    );
  }

  // --- NEW: ROADMAP WIDGET ---
  Widget _buildTreatmentRoadmap(bool hasAssessed, bool isConnected, bool isPending) {
    int currentStep = isConnected ? 3 : (hasAssessed ? 2 : 1);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Your Journey", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: forestDark)),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildStepIndicator(
                title: "Assess", 
                isActive: true, 
                isDone: hasAssessed, 
                icon: Icons.assignment_turned_in_outlined
              ),
              _buildLine(isActive: hasAssessed),
              _buildStepIndicator(
                title: "Link", 
                isActive: hasAssessed, 
                isDone: isConnected, 
                isPending: isPending,
                icon: Icons.domain_verification
              ),
              _buildLine(isActive: isConnected),
              _buildStepIndicator(
                title: "Treat", 
                isActive: isConnected, 
                isDone: false, // Completes at end of program
                icon: Icons.healing
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator({required String title, required bool isActive, required bool isDone, bool isPending = false, required IconData icon}) {
    Color color = isDone ? forestMed : (isActive ? (isPending ? Colors.amber.shade600 : forestMed) : Colors.grey.shade300);
    Color bgColor = isDone ? paleGreen.withOpacity(0.5) : (isActive ? (isPending ? Colors.amber.shade100 : Colors.transparent) : Colors.transparent);
    
    return Expanded(
      child: Column(
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: bgColor,
              border: Border.all(color: color, width: isActive && !isDone ? 2 : 0),
            ),
            child: Icon(
              isDone ? Icons.check : icon,
              color: isDone || isActive ? color : Colors.grey.shade400,
              size: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? forestDark : Colors.grey.shade500,
            ),
          )
        ],
      ),
    );
  }

  Widget _buildLine({required bool isActive}) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(bottom: 24), // visually align with center of circles
        height: 2,
        color: isActive ? paleGreen : Colors.grey.shade200,
      ),
    );
  }

  // --- WIDGETS ---
  Widget _buildConnectCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: forestDark,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: forestDark.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle), child: const Icon(Icons.link_rounded, color: Colors.white, size: 20)),
              const SizedBox(width: 12),
              const Text("Clinical Referral", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 16),
          const Text("Link with your Carmona doctor to unlock your Medication Diary and Calendar.", style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4)),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity, height: 48,
            child: ElevatedButton(
              onPressed: _showClinicCodeDialog,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: forestDark, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              child: const Text("Enter Clinic Code", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.amber.shade100)),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(12), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: Icon(Icons.hourglass_empty_rounded, color: Colors.amber.shade700, size: 24)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Approval Pending", style: TextStyle(color: Colors.amber.shade900, fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Text("Waiting for your clinic to verify your request.", style: TextStyle(color: Colors.amber.shade700, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifiedCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: forestMed,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: forestMed.withOpacity(0.25), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle), child: const Icon(Icons.verified_user_rounded, color: Colors.white, size: 24)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Verified Patient", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Text(_doctorName != null ? "You are under the care of $_doctorName." : "You are officially linked to the clinic.", style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTreatmentBanner() {
    bool isNotAssessed = _riskLevel == "Not yet assessed";
    String displayText = isNotAssessed ? "Not Yet Tested" : _riskLevel;

    Color bgColor = Colors.grey.shade500; 
    if (_riskLevel.toLowerCase().contains("high")) bgColor = const Color(0xFFD9534F);
    else if (_riskLevel.toLowerCase().contains("medium")) bgColor = const Color(0xFFE67E22);
    else if (_riskLevel.toLowerCase().contains("low")) bgColor = Colors.grey.shade600;

    BoxDecoration boxDecoration = isNotAssessed 
      ? BoxDecoration(color: paleGreen.withOpacity(0.4), borderRadius: BorderRadius.circular(24))
      : BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: bgColor.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))]);

    Color titleColor = isNotAssessed ? forestDark : Colors.white;
    Color subtitleColor = isNotAssessed ? forestDark.withOpacity(0.6) : Colors.white70;
    Color iconColor = isNotAssessed ? forestMed : Colors.white;
    Color iconBgColor = isNotAssessed ? Colors.white : Colors.white.withOpacity(0.2);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: boxDecoration,
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: iconBgColor, shape: BoxShape.circle), child: Icon(Icons.monitor_heart_rounded, color: iconColor, size: 28)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Treatment Status', style: TextStyle(color: subtitleColor, fontWeight: FontWeight.w600, fontSize: 12, letterSpacing: 0.5)),
                const SizedBox(height: 4),
                Text(displayText, style: TextStyle(color: titleColor, fontSize: 18, fontWeight: FontWeight.w800)),
              ],
            ),
          )
        ],
      ),
    );
  }
}

// --- HOVER ACTION CARD (UPDATED WITH LOCK) ---
class _HoverActionCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String route;
  final bool isLocked;
  final VoidCallback? onLockedTap;

  const _HoverActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
    this.isLocked = false,
    this.onLockedTap,
  });

  @override
  State<_HoverActionCard> createState() => _HoverActionCardState();
}

class _HoverActionCardState extends State<_HoverActionCard> {
  bool _isHovering = false;
  final Color forestMed = const Color(0xFF606C38);
  final Color paleGreen = const Color(0xFFDDE5B6);

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => !widget.isLocked ? setState(() => _isHovering = true) : null,
      onExit: (_) => !widget.isLocked ? setState(() => _isHovering = false) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutQuart,
        transform: Matrix4.identity()..translate(0.0, _isHovering ? -4.0 : 0.0),
        decoration: BoxDecoration(
          color: widget.isLocked ? Colors.grey.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: widget.isLocked ? Border.all(color: Colors.grey.shade200) : null,
          boxShadow: widget.isLocked ? [] : [
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
            onTap: widget.isLocked 
                ? widget.onLockedTap 
                : () => Navigator.pushNamed(context, widget.route),
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: widget.isLocked ? Colors.grey.shade200 : paleGreen.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          widget.icon,
                          color: widget.isLocked ? Colors.grey.shade400 : forestMed,
                          size: 24
                        ),
                      ),
                      const Spacer(),
                      Text(widget.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold, 
                          fontSize: 15, 
                          color: widget.isLocked ? Colors.grey.shade500 : Colors.black87, 
                          height: 1.2
                        )
                      ),
                      const SizedBox(height: 6),
                      Text(widget.subtitle,
                        style: TextStyle(
                          color: widget.isLocked ? Colors.red.shade300 : Colors.grey.shade500, 
                          fontSize: 11, 
                          fontWeight: FontWeight.w500
                        )
                      ),
                    ],
                  ),
                  if (widget.isLocked)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Icon(Icons.lock, color: Colors.grey.shade300, size: 20),
                    )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}