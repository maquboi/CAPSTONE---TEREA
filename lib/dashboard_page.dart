import 'dart:ui'; 
import 'package:flutter/services.dart'; 
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart'; 
import 'shared_widgets.dart'; // REQUIRED to access isEnglishNotifier
import 'qr_scanner_page.dart';

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
  String _userId = ""; 
  String? _avatarUrl;
  String _riskLevel = "Not yet assessed";
  bool _isLoading = true;
  
  // CONNECTION TRACKING
  String? _connectionStatus;
  String? _doctorName;
  
  // SMART BELL NOTIFICATION TRACKING
  bool _hasUnreadNotifications = false;

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
    _checkUnreadNotifications();
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

    _supabase
      .channel('patient_notifications')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'notifications',
        filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'patient_id', value: user.id),
        callback: (payload) => _checkUnreadNotifications(),
      )
      .subscribe();
  }

  Future<void> _checkUnreadNotifications() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final data = await _supabase
          .from('notifications')
          .select('id')
          .eq('patient_id', user.id)
          .eq('is_read', false)
          .eq('type', 'alert')
          .limit(1);

      if (mounted) {
        setState(() {
          _hasUnreadNotifications = data.isNotEmpty;
        });
      }
    } catch (e) {
      debugPrint('Error checking notifications: $e');
    }
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
            _userId = user.id; 
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

  void _showNotificationPopup(String message, String titleStr, {bool isSuccess = false, IconData? customIcon}) {
    HapticFeedback.mediumImpact(); 
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
                    titleStr,
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
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).pop();
                      },
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

  Future<void> _submitClinicCode(bool isEnglish, [String? scannedCode]) async {
    HapticFeedback.lightImpact(); 
    final code = scannedCode ?? _codeController.text.trim();
    if (code.isEmpty) return;

    setState(() => _isLinking = true);
    final user = _supabase.auth.currentUser;

    try {
      final doctor = await _supabase.from('profiles').select('id, full_name').eq('clinic_code', code).eq('role', 'doctor').maybeSingle();

      if (doctor == null) {
        _showNotificationPopup(isEnglish ? "Invalid Clinic Code. Please check again." : "Mali ang Clinic Code. Pakisuri muli.", isEnglish ? "Notice" : "Paalala");
        setState(() => _isLinking = false);
        return;
      }

      final existing = await _supabase.from('connections').select().eq('patient_id', user!.id).eq('doctor_id', doctor['id']).maybeSingle();

      if (existing != null) {
        _showNotificationPopup(isEnglish ? "You are already connected or pending with this doctor." : "Konektado ka na o naka-pending sa doktor na ito.", isEnglish ? "Notice" : "Paalala");
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
        if (scannedCode == null) Navigator.pop(context);
        _showNotificationPopup(isEnglish ? "Request sent to Dr. ${doctor['full_name']}!" : "Naipadala ang request kay Dr. ${doctor['full_name']}!", isEnglish ? "Success" : "Tagumpay", isSuccess: true);
      }
    } catch (e) {
      if (e.toString().contains("duplicate")) {
         _showNotificationPopup(isEnglish ? "You have already sent a request." : "Nakapagpadala ka na ng request.", isEnglish ? "Notice" : "Paalala");
      } else {
         _showNotificationPopup(isEnglish ? "Error linking to clinic: $e" : "Error sa pag-link sa clinic: $e", isEnglish ? "Error" : "Error");
      }
      setState(() => _isLinking = false);
    }
  }

  void _showClinicCodeDialog(bool isEnglish) {
    HapticFeedback.selectionClick(); 
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(isEnglish ? "Enter Clinic Code" : "Ilagay ang Clinic Code", style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(isEnglish ? "Please enter the code provided by your doctor in Carmona (e.g., CMC-001)." : "Ilagay ang code na ibinigay ng iyong doktor (halimbawa: CMC-001).", style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
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
          TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            }, 
            child: Text(isEnglish ? "Cancel" : "Kanselahin", style: const TextStyle(color: Colors.grey))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: forestMed, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: _isLinking ? null : () => _submitClinicCode(isEnglish),
            child: _isLinking ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text(isEnglish ? "Connect" : "Ikonekta", style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.white,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(top: kToolbarHeight + 40, left: 24, right: 24, bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 200, height: 32, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8))),
            const SizedBox(height: 8),
            Container(width: 150, height: 16, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8))),
            const SizedBox(height: 30),
            Container(width: double.infinity, height: 130, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24))),
            const SizedBox(height: 30),
            Container(width: double.infinity, height: 160, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24))),
            const SizedBox(height: 20),
            Container(width: double.infinity, height: 110, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24))),
            const SizedBox(height: 35),
            Container(width: 120, height: 16, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8))),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: Container(height: 120, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)))),
                const SizedBox(width: 16),
                Expanded(child: Container(height: 120, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)))),
              ],
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool hasAssessed = _riskLevel != "Not yet assessed" && _riskLevel != "Hindi pa nasusuri";
    bool isConnected = _connectionStatus == 'active';
    bool isPending = _connectionStatus == 'pending';

    // WRAP ENTIRE SCAFFOLD IN VALUELISTENABLEBUILDER
    return ValueListenableBuilder<bool>(
      valueListenable: isEnglishNotifier,
      builder: (context, isEnglish, child) {
        return Scaffold(
          backgroundColor: softWhite,
          extendBodyBehindAppBar: true, 
          appBar: AppBar(
            backgroundColor: softWhite.withOpacity(0.75), 
            elevation: 0,
            scrolledUnderElevation: 0,
            automaticallyImplyLeading: false,
            flexibleSpace: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12), 
                child: Container(color: Colors.transparent),
              ),
            ),
            title: Row(
              children: [
                Image.asset('assets/LogoNoBG.png', width: 32, height: 32, fit: BoxFit.contain), // Replaced placeholder
                const SizedBox(width: 10),
                Text('TEREA', style: TextStyle(fontWeight: FontWeight.w900, color: forestDark, fontSize: 22, letterSpacing: 0.5))
              ],
            ),
            actions: [
              Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.notifications_outlined, color: forestDark, size: 28),
                    onPressed: () {
                      HapticFeedback.lightImpact(); 
                      Navigator.pushNamed(context, '/notifications').then((_) {
                        _checkUnreadNotifications();
                      });
                    },
                  ),
                  if (_hasUnreadNotifications)
                    Positioned(
                      right: 12,
                      top: 12,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                          border: Border.all(color: softWhite, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 4),
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
            ? _buildSkeletonLoader() 
            : RefreshIndicator(
                onRefresh: _fetchUserData,
                color: forestMed,
                backgroundColor: Colors.white,
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(top: kToolbarHeight + MediaQuery.of(context).padding.top + 20, left: 24, right: 24, bottom: 20),
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(isEnglish ? 'Hello, ${_username.split(' ')[0]}' : 'Kamusta, ${_username.split(' ')[0]}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.black87, letterSpacing: -0.5)),
                      const SizedBox(height: 4),
                      Text(isEnglish ? 'How are you feeling today?' : 'Kamusta ang pakiramdam mo ngayon?', style: TextStyle(color: Colors.grey.shade600, fontSize: 15, fontWeight: FontWeight.w500)),
                      
                      const SizedBox(height: 30),

                      _buildTreatmentRoadmap(hasAssessed, isConnected, isPending, isEnglish),
                      
                      const SizedBox(height: 30),

                      if (_connectionStatus == null) ...[
                        _buildConnectCard(isEnglish),
                        const SizedBox(height: 20),
                      ] else if (_connectionStatus == 'pending') ...[
                        _buildPendingCard(isEnglish),
                        const SizedBox(height: 20),
                      ] else if (_connectionStatus == 'active') ...[
                        _buildVerifiedCard(isEnglish),
                        const SizedBox(height: 20),
                      ],

                      _buildTreatmentBanner(isEnglish),
                      
                      const SizedBox(height: 35),
                      Text(isEnglish ? 'QUICK ACTIONS' : 'MGA AKSYON', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.grey.shade500, letterSpacing: 1.5)),
                      const SizedBox(height: 16),
                      
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
                            title: isEnglish ? 'Risk\nAssessment' : 'Pagsusuri\nng Panganib', 
                            subtitle: hasAssessed ? (isEnglish ? 'View results' : 'Tingnan ang resulta') : (isEnglish ? 'Check TB risk' : 'Suriin ang TB risk'), 
                            route: '/assess',
                            isLocked: false,
                          ),
                          _HoverActionCard(
                            icon: Icons.medical_services_outlined, 
                            title: isEnglish ? 'My\nDoctor' : 'Aking\nDoktor', 
                            subtitle: isConnected ? (isEnglish ? 'View physician' : 'Tingnan ang doktor') : (isEnglish ? 'Requires Clinic' : 'Kailangan ng Clinic'), 
                            route: '/my_doctor',
                            isLocked: !isConnected,
                            onLockedTap: () {
                              HapticFeedback.heavyImpact(); 
                              _showNotificationPopup(
                                isEnglish ? "Please connect to a clinic first to view your doctor." : "Mangyaring kumonekta muna sa isang klinika upang makita ang iyong doktor.", 
                                isEnglish ? "Notice" : "Paalala", 
                                customIcon: Icons.lock_outline
                              );
                            },
                          ),
                          _HoverActionCard(
                            icon: Icons.medication_outlined, 
                            title: isEnglish ? 'Medication\nDiary' : 'Talaan ng\nGamot', 
                            subtitle: isConnected ? (isEnglish ? 'Track doses' : 'I-track ang gamot') : (isEnglish ? 'Requires Clinic' : 'Kailangan ng Clinic'), 
                            route: '/meds',
                            isLocked: !isConnected,
                            onLockedTap: () {
                              HapticFeedback.heavyImpact();
                              _showNotificationPopup(
                                isEnglish ? "Your doctor needs to prescribe a treatment plan before you can use the diary." : "Kailangang magreseta ang iyong doktor ng plano sa paggamot bago mo magamit ang talaan.", 
                                isEnglish ? "Notice" : "Paalala", 
                                customIcon: Icons.lock_outline
                              );
                            },
                          ),
                          _HoverActionCard(
                            icon: Icons.calendar_month_outlined, 
                            title: isEnglish ? 'Follow-Up\nCalendar' : 'Kalendaryo ng\nFollow-Up', 
                            subtitle: isEnglish ? 'View appointments' : 'Tingnan ang iskedyul', 
                            route: '/followup',
                            isLocked: !isConnected,
                            onLockedTap: () {
                              HapticFeedback.heavyImpact();
                              _showNotificationPopup(
                                isEnglish ? "Clinic verification required to view appointments." : "Kailangan ng pagpapatunay sa klinika upang makita ang mga appointment.", 
                                isEnglish ? "Notice" : "Paalala", 
                                customIcon: Icons.lock_outline
                              );
                            },
                          ),
                          _HoverActionCard(
                            icon: Icons.menu_book_rounded, 
                            title: 'FAQ', 
                            subtitle: isEnglish ? 'TB Info & Diet' : 'Impormasyon sa TB', 
                            route: '/faq',
                            isLocked: false,
                          ),
                          _HoverActionCard(
                            icon: Icons.settings_outlined, 
                            title: isEnglish ? 'Account\nSettings' : 'Mga Setting\nng Account', 
                            subtitle: isEnglish ? 'Preferences' : 'Mga Kagustuhan', 
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
    );
  }

  // --- ROADMAP WIDGET ---
  Widget _buildTreatmentRoadmap(bool hasAssessed, bool isConnected, bool isPending, bool isEnglish) {
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
          Text(isEnglish ? "Your Journey" : "Ang Iyong Paglalakbay", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: forestDark)),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildStepIndicator(
                title: isEnglish ? "Assess" : "Pagsusuri", 
                isActive: true, 
                isDone: hasAssessed, 
                icon: Icons.assignment_turned_in_outlined
              ),
              _buildLine(isActive: hasAssessed),
              _buildStepIndicator(
                title: isEnglish ? "Link" : "Ikonekta", 
                isActive: hasAssessed, 
                isDone: isConnected, 
                isPending: isPending,
                icon: Icons.domain_verification
              ),
              _buildLine(isActive: isConnected),
              _buildStepIndicator(
                title: isEnglish ? "Treat" : "Gamutan", 
                isActive: isConnected, 
                isDone: false, 
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
        margin: const EdgeInsets.only(bottom: 24), 
        height: 2,
        color: isActive ? paleGreen : Colors.grey.shade200,
      ),
    );
  }

  // --- CARDS ---
  Widget _buildConnectCard(bool isEnglish) {
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
              Text(isEnglish ? "Clinical Referral" : "Klinikal na Referral", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 16),
          Text(isEnglish ? "Link with your Carmona doctor to unlock your Medication Diary and Calendar." : "Kumonekta sa iyong doktor sa Carmona para magamit ang Talaan ng Gamot at Kalendaryo.", style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => _showClinicCodeDialog(isEnglish),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: forestDark, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    child: Text(isEnglish ? "Enter Code Manually" : "Ilagay ang Code", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 48,
                width: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    HapticFeedback.lightImpact(); 
                    final scannedCode = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const QRScannerPage()),
                    );
                    if (scannedCode != null && scannedCode is String) {
                      _submitClinicCode(isEnglish, scannedCode);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: paleGreen, 
                    foregroundColor: forestDark, 
                    elevation: 0, 
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))
                  ),
                  child: const Icon(Icons.qr_code_scanner, size: 22),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPendingCard(bool isEnglish) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.amber.shade100)),
      child: Column(
        children: [
          Row(
            children: [
              Container(padding: const EdgeInsets.all(12), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: Icon(Icons.qr_code_scanner_rounded, color: Colors.amber.shade700, size: 24)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isEnglish ? "Verification Pending" : "Naghihintay ng Pagpapatunay", style: TextStyle(color: Colors.amber.shade900, fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text(isEnglish ? "Show your Patient ID to the clinic admin to complete verification." : "Ipakita ang iyong Patient ID sa admin ng klinika upang makumpleto ang pag-verify.", style: TextStyle(color: Colors.amber.shade700, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.amber.shade200, width: 2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(isEnglish ? "YOUR PATIENT ID" : "ANG IYONG PATIENT ID", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade500, letterSpacing: 1.5)),
                const SizedBox(height: 4),
                SelectableText(
                  _userId.length >= 8 ? _userId.substring(0, 8).toUpperCase() : _userId, 
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: forestDark, letterSpacing: 2)
                ),
              ]
            )
          )
        ],
      )
    );
  }

  Widget _buildVerifiedCard(bool isEnglish) {
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
                Text(isEnglish ? "Verified Patient" : "Napatunayang Pasyente", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Text(_doctorName != null ? (isEnglish ? "You are under the care of $_doctorName." : "Ikaw ay nasa pangangalaga ni $_doctorName.") : (isEnglish ? "You are officially linked to the clinic." : "Opisyal ka nang konektado sa klinika."), style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLockedUI(bool hasAssessed, bool isVerified, bool isEnglish) {
    String title = isEnglish ? "Diary Locked" : "Naka-lock ang Talaan";
    String message = isEnglish ? "To ensure your safety, the Medication Diary is locked until you complete your assessment and link with your doctor." : "Para sa iyong kaligtasan, naka-lock ang Talaan ng Gamot hanggang makumpleto mo ang pagsusuri at makakonekta sa iyong doktor.";
    IconData icon = Icons.lock_outline_rounded;

    if (!hasAssessed) {
      title = isEnglish ? "Assessment Required" : "Kailangan ng Pagsusuri";
      message = isEnglish ? "Please complete the Risk Assessment first to unlock your health features." : "Mangyaring kumpletuhin muna ang Pagsusuri ng Panganib upang magamit ang iyong mga health feature.";
      icon = Icons.assignment_late_outlined;
    } else if (!isVerified) {
      title = isEnglish ? "Verification Pending" : "Naghihintay ng Pagpapatunay";
      message = isEnglish ? "Assessment complete! Please show your Patient ID to the clinic admin for verification." : "Tapos na ang pagsusuri! Ipakita ang iyong Patient ID sa admin ng klinika para sa pagpapatunay.";
      icon = Icons.qr_code_scanner_rounded;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20), 
              decoration: BoxDecoration(color: forestMed.withOpacity(0.1), shape: BoxShape.circle), 
              child: Icon(icon, size: 50, color: forestDark)
            ),
            const SizedBox(height: 30),
            Text(title, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: forestDark)),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 14)),
            
            if (hasAssessed && !isVerified) ...[
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: paleGreen, width: 2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(isEnglish ? "YOUR PATIENT ID" : "ANG IYONG PATIENT ID", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade500, letterSpacing: 1.5)),
                    const SizedBox(height: 4),
                    SelectableText(
                      _userId.length >= 8 ? _userId.substring(0, 8).toUpperCase() : _userId, 
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: forestDark, letterSpacing: 2)
                    ),
                  ]
                )
              )
            ],

            const SizedBox(height: 40),
            ElevatedButton(
                onPressed: () => Navigator.pushReplacementNamed(context, hasAssessed ? '/dashboard' : '/assess'), 
                style: ElevatedButton.styleFrom(backgroundColor: forestDark, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15)), 
                child: Text(hasAssessed ? (isEnglish ? "Go to Dashboard" : "Pumunta sa Dashboard") : (isEnglish ? "Take Assessment" : "Magsimula ng Pagsusuri"), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTreatmentBanner(bool isEnglish) {
    bool isNotAssessed = _riskLevel == "Not yet assessed" || _riskLevel == "Hindi pa nasusuri";
    String displayText = isNotAssessed ? (isEnglish ? "Not Yet Tested" : "Hindi Pa Nasusuri") : _riskLevel;

    Color bgColor = Colors.grey.shade500; 
    if (_riskLevel.toLowerCase().contains("high") || _riskLevel.toLowerCase().contains("mataas")) bgColor = const Color(0xFFD9534F);
    else if (_riskLevel.toLowerCase().contains("medium") || _riskLevel.toLowerCase().contains("katamtaman")) bgColor = const Color(0xFFE67E22);
    else if (_riskLevel.toLowerCase().contains("low") || _riskLevel.toLowerCase().contains("mababa")) bgColor = Colors.grey.shade600;

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
                Text(isEnglish ? 'Treatment Status' : 'Katayuan ng Gamutan', style: TextStyle(color: subtitleColor, fontWeight: FontWeight.w600, fontSize: 12, letterSpacing: 0.5)),
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

// --- HOVER ACTION CARD ---
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
            onTap: () {
              HapticFeedback.selectionClick(); 
              if (widget.isLocked && widget.onLockedTap != null) {
                widget.onLockedTap!();
              } else if (!widget.isLocked) {
                Navigator.pushNamed(context, widget.route);
              }
            },
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