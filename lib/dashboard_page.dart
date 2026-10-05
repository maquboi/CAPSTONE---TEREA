import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'shared_widgets.dart'; // REQUIRED to access isEnglishNotifier
import 'qr_scanner_page.dart';

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

  // --- REFINED CLINICAL COLOR SYSTEM ---
  static const Color primaryTeal = Color(0xFF0F766E);       // Deep Clinical Teal
  static const Color primaryDark = Color(0xFF115E59);       // Spruce Slate
  static const Color primaryDeep = Color(0xFF042F2E);       // Deepest Navy Teal
  static const Color backgroundSurface = Color(0xFFF1F5F9); // Slate 100
  static const Color textCharcoal = Color(0xFF0F172A);      // High Contrast Text
  static const Color textMuted = Color(0xFF64748B);         // Subdued Slate Text
  static const Color borderNeutral = Color(0xFFE2E8F0);     // Clean Structured Border
  static const Color cardBg = Colors.white;                // Pure White Card

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

  // Prevents "Dr. Dr." duplicate prefixes
  String _formatDoctorName(String? name) {
    if (name == null || name.trim().isEmpty) return "";
    final clean = name.trim().replaceFirst(RegExp(r'^(dr\.?\s*)+', caseSensitive: false), '');
    return "Dr. $clean";
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
      barrierColor: Colors.black.withOpacity(0.45),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) => const SizedBox.shrink(),
      transitionBuilder: (context, a1, a2, child) {
        final color = isSuccess ? primaryTeal : const Color(0xFFDC2626);
        final icon = customIcon ?? (isSuccess ? Icons.check_circle_outline_rounded : Icons.error_outline_rounded);

        return FadeTransition(
          opacity: a1,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: borderNeutral),
            ),
            backgroundColor: Colors.white,
            contentPadding: const EdgeInsets.all(24),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(height: 16),
                Text(
                  titleStr,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: textCharcoal),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w400, fontSize: 13, color: textMuted, height: 1.4),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryTeal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                    ),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.of(context).pop();
                    },
                    child: Text("Acknowledge", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                ),
              ],
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
        _showNotificationPopup(isEnglish ? "Invalid Clinic Code. Please verify with Carmona Health Center." : "Mali ang Clinic Code. Pakisuri muli sa Carmona Health Center.", isEnglish ? "Notice" : "Paalala");
        setState(() => _isLinking = false);
        return;
      }

      final existing = await _supabase.from('connections').select().eq('patient_id', user!.id).eq('doctor_id', doctor['id']).maybeSingle();

      if (existing != null) {
        _showNotificationPopup(isEnglish ? "You are already linked or pending verification with this clinic." : "Konektado ka na o naka-pending sa klinika na ito.", isEnglish ? "Notice" : "Paalala");
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
        final docDisplay = _formatDoctorName(doctor['full_name']);
        _showNotificationPopup(isEnglish ? "Request sent to $docDisplay!" : "Naipadala ang request kay $docDisplay!", isEnglish ? "Success" : "Tagumpay", isSuccess: true);
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: borderNeutral)),
        title: Text(
          isEnglish ? "Connect to Clinic" : "Ilagay ang Clinic Code",
          style: GoogleFonts.inter(color: textCharcoal, fontWeight: FontWeight.w700, fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEnglish ? "Enter the unique clinic code provided by your Carmona health worker." : "Ilagay ang code na ibinigay ng iyong health worker sa Carmona (halimbawa: CMC-001).",
              style: GoogleFonts.inter(fontSize: 13, color: textMuted, height: 1.4),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _codeController,
              style: GoogleFonts.inter(color: textCharcoal, fontSize: 14, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: "e.g. CMC-001",
                hintStyle: GoogleFonts.inter(color: Colors.black26, fontSize: 13),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: borderNeutral)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: borderNeutral)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: primaryTeal, width: 1.5)),
                prefixIcon: const Icon(Icons.domain_verification, color: primaryTeal, size: 20),
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
            child: Text(isEnglish ? "Cancel" : "Kanselahin", style: GoogleFonts.inter(color: textMuted, fontWeight: FontWeight.w600, fontSize: 13)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryTeal,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: _isLinking ? null : () => _submitClinicCode(isEnglish),
            child: _isLinking
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(isEnglish ? "Connect" : "Ikonekta", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE2E8F0),
      highlightColor: const Color(0xFFF8FAFC),
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(top: kToolbarHeight + 40, left: 20, right: 20, bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 180, height: 28, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8))),
            const SizedBox(height: 8),
            Container(width: 130, height: 14, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8))),
            const SizedBox(height: 28),
            Container(width: double.infinity, height: 120, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16))),
            const SizedBox(height: 24),
            Container(width: double.infinity, height: 140, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16))),
            const SizedBox(height: 20),
            Container(width: double.infinity, height: 90, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16))),
            const SizedBox(height: 32),
            Container(width: 110, height: 14, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8))),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: Container(height: 120, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)))),
                const SizedBox(width: 14),
                Expanded(child: Container(height: 120, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)))),
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

    return ValueListenableBuilder<bool>(
      valueListenable: isEnglishNotifier,
      builder: (context, isEnglish, child) {
        return Scaffold(
          backgroundColor: backgroundSurface,
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: backgroundSurface.withOpacity(0.9),
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
                Image.asset('assets/LogoNoBG.png', width: 28, height: 28, fit: BoxFit.contain),
                const SizedBox(width: 10),
                Text(
                  'TEREA',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w800,
                    color: textCharcoal,
                    fontSize: 20,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            actions: [
              Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined, color: textCharcoal, size: 24),
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
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: const Color(0xFFDC2626),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(right: 18),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: primaryTeal.withOpacity(0.3), width: 1.5),
                  ),
                  child: CircleAvatar(
                    radius: 17,
                    backgroundColor: Colors.white,
                    backgroundImage: _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
                    child: _avatarUrl == null ? const Icon(Icons.person, size: 18, color: textMuted) : null,
                  ),
                ),
              )
            ],
          ),
          body: _isLoading
              ? _buildSkeletonLoader()
              : RefreshIndicator(
                  onRefresh: _fetchUserData,
                  color: primaryTeal,
                  backgroundColor: Colors.white,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(
                      top: kToolbarHeight + MediaQuery.of(context).padding.top + 12,
                      left: 18,
                      right: 18,
                      bottom: 24,
                    ),
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- 1. HERO PATIENT SUMMARY CARD ---
                        _buildHeroGreetingCard(isEnglish),

                        const SizedBox(height: 18),

                        // --- 2. TREATMENT ROADMAP PROGRESS ---
                        _buildTreatmentRoadmap(hasAssessed, isConnected, isPending, isEnglish),

                        const SizedBox(height: 18),

                        // --- 3. CONNECTION CARD ---
                        if (_connectionStatus == null) ...[
                          _buildConnectCard(isEnglish),
                          const SizedBox(height: 16),
                        ] else if (_connectionStatus == 'pending') ...[
                          _buildPendingCard(isEnglish),
                          const SizedBox(height: 16),
                        ] else if (_connectionStatus == 'active') ...[
                          _buildVerifiedCard(isEnglish),
                          const SizedBox(height: 16),
                        ],

                        // --- 4. TREATMENT RISK STATUS (Reassuring Non-Alarming Banner) ---
                        _buildTreatmentBanner(isEnglish),

                        const SizedBox(height: 26),

                        // --- 5. QUICK ACTIONS WITH UNIFIED CLINICAL BADGES ---
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isEnglish ? 'CLINICAL SERVICES' : 'MGA SERBISYONG KLINIKAL',
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: textMuted,
                                letterSpacing: 1.2,
                              ),
                            ),
                            Text(
                              'Carmona Health Center',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: primaryTeal,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.98,
                          children: [
                            // 1. Risk Assessment (Clinical Triage & Evaluation)
                            _HoverActionCard(
                              icon: Icons.fact_check_outlined,
                              title: isEnglish ? 'Risk\nAssessment' : 'Pagsusuri\nng Panganib',
                              subtitle: hasAssessed ? (isEnglish ? 'View results' : 'Tingnan ang resulta') : (isEnglish ? 'Check TB risk' : 'Suriin ang TB risk'),
                              route: '/assess',
                              isLocked: false,
                            ),

                            // 2. My Doctor (Physician Credentials & Chart)
                            _HoverActionCard(
                              icon: Icons.medical_information_outlined,
                              title: isEnglish ? 'My\nDoctor' : 'Aking\nDoktor',
                              subtitle: isConnected ? (isEnglish ? 'View physician' : 'Tingnan ang doktor') : (isEnglish ? 'Requires Clinic' : 'Kailangan ng Clinic'),
                              route: '/my_doctor',
                              isLocked: !isConnected,
                              onLockedTap: () {
                                HapticFeedback.heavyImpact();
                                _showNotificationPopup(
                                  isEnglish ? "Please connect to a clinic first to view your assigned physician." : "Mangyaring kumonekta muna sa isang klinika upang makita ang iyong doktor.",
                                  isEnglish ? "Clinic Required" : "Paalala",
                                  customIcon: Icons.lock_outline,
                                );
                              },
                            ),

                            // 3. Medication Diary (Directly Observed Daily Regimen)
                            _HoverActionCard(
                              icon: Icons.medication_outlined,
                              title: isEnglish ? 'Medication\nDiary' : 'Talaan ng\nGamot',
                              subtitle: isConnected ? (isEnglish ? 'Track doses' : 'I-track ang gamot') : (isEnglish ? 'Requires Clinic' : 'Kailangan ng Clinic'),
                              route: '/meds',
                              isLocked: !isConnected,
                              onLockedTap: () {
                                HapticFeedback.heavyImpact();
                                _showNotificationPopup(
                                  isEnglish ? "Your doctor needs to prescribe a treatment plan before you can access the diary." : "Kailangang magreseta ang iyong doktor ng plano sa paggamot bago mo magamit ang talaan.",
                                  isEnglish ? "Prescription Required" : "Paalala",
                                  customIcon: Icons.lock_outline,
                                );
                              },
                            ),

                            // 4. Follow-Up Calendar (Smear & Consultation Schedule)
                            _HoverActionCard(
                              icon: Icons.event_repeat_rounded,
                              title: isEnglish ? 'Follow-Up\nCalendar' : 'Kalendaryo ng\nFollow-Up',
                              subtitle: isEnglish ? 'Appointments' : 'Iskedyul',
                              route: '/followup',
                              isLocked: !isConnected,
                              onLockedTap: () {
                                HapticFeedback.heavyImpact();
                                _showNotificationPopup(
                                  isEnglish ? "Clinic verification is required to view follow-up appointments." : "Kailangan ng pagpapatunay sa klinika upang makita ang mga appointment.",
                                  isEnglish ? "Clinic Required" : "Paalala",
                                  customIcon: Icons.lock_outline,
                                );
                              },
                            ),

                            // 5. TB Info & Nutrition (Educational Health Guide)
                            _HoverActionCard(
                              icon: Icons.auto_stories_outlined,
                              title: 'TB Info\n& Nutrition',
                              subtitle: isEnglish ? 'Health Guide' : 'Gabay Pangkalusugan',
                              route: '/faq',
                              isLocked: false,
                            ),

                            // 6. Account Settings (Patient Identity & Preferences)
                            _HoverActionCard(
                              icon: Icons.manage_accounts_outlined,
                              title: isEnglish ? 'Account\nSettings' : 'Mga Setting\nng Account',
                              subtitle: isEnglish ? 'Preferences' : 'Kagustuhan',
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
      },
    );
  }

  // --- HERO PATIENT GREETING CARD ---
  Widget _buildHeroGreetingCard(bool isEnglish) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primaryDeep, primaryTeal],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: primaryTeal.withOpacity(0.25),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.local_hospital_rounded, color: Colors.white, size: 12),
                    const SizedBox(width: 6),
                    Text(
                      "Carmona Health Center",
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "ACTIVE",
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            isEnglish ? 'Hello, ${_username.split(' ')[0]}' : 'Kamusta, ${_username.split(' ')[0]}',
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isEnglish
                ? 'Welcome to your personalized tuberculosis care portal.'
                : 'Maligayang pagdating sa iyong personalized TB tracker.',
            style: GoogleFonts.inter(
              color: Colors.white.withOpacity(0.85),
              fontSize: 12.5,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  // --- ROADMAP WIDGET ---
  Widget _buildTreatmentRoadmap(bool hasAssessed, bool isConnected, bool isPending, bool isEnglish) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderNeutral),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isEnglish ? "Care Protocol Milestones" : "Yugto ng Gamutan",
                style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13.5, color: textCharcoal),
              ),
              Text(
                isEnglish ? "Step by Step" : "Hakbang",
                style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 11, color: textMuted),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStepIndicator(
                title: isEnglish ? "Screen" : "Suriin",
                isActive: true,
                isDone: hasAssessed,
                icon: Icons.assignment_turned_in_outlined,
              ),
              _buildLine(isActive: hasAssessed),
              _buildStepIndicator(
                title: isEnglish ? "Enroll" : "Ikonekta",
                isActive: hasAssessed,
                isDone: isConnected,
                isPending: isPending,
                icon: Icons.domain_verification,
              ),
              _buildLine(isActive: isConnected),
              _buildStepIndicator(
                title: isEnglish ? "Treatment" : "Gamutan",
                isActive: isConnected,
                isDone: false,
                icon: Icons.healing_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator({
    required String title,
    required bool isActive,
    required bool isDone,
    bool isPending = false,
    required IconData icon,
  }) {
    Color indicatorColor = isDone
        ? primaryTeal
        : (isActive ? (isPending ? const Color(0xFFD97706) : primaryTeal) : textMuted.withOpacity(0.4));
    Color bgColor = isDone
        ? const Color(0xFFCCFBF1)
        : (isActive ? (isPending ? const Color(0xFFFEF3C7) : const Color(0xFFE6FFFA)) : const Color(0xFFF1F5F9));

    return Expanded(
      child: Column(
        children: [
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: bgColor,
              border: Border.all(color: indicatorColor, width: isActive && !isDone ? 1.5 : 1),
            ),
            child: Icon(
              isDone ? Icons.check_rounded : icon,
              color: isDone || isActive ? indicatorColor : textMuted.withOpacity(0.5),
              size: 18,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              color: isActive ? textCharcoal : textMuted,
            ),
          )
        ],
      ),
    );
  }

  Widget _buildLine({required bool isActive}) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        height: 2,
        color: isActive ? primaryTeal : borderNeutral,
      ),
    );
  }

  // --- CLINICAL STATUS CARDS ---
  Widget _buildConnectCard(bool isEnglish) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: primaryTeal,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryTeal.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), shape: BoxShape.circle),
                child: const Icon(Icons.link_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                isEnglish ? "Clinic Binding Required" : "Klinikal na Pag-ugnay",
                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14.5),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isEnglish
                ? "Link with your Carmona health worker to access your daily Medication Diary and lab schedule."
                : "Kumonekta sa iyong health worker sa Carmona upang magamit ang Talaan ng Gamot at iskedyul ng lab.",
            style: GoogleFonts.inter(color: Colors.white70, fontSize: 12.5, height: 1.4),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: ElevatedButton(
                    onPressed: () => _showClinicCodeDialog(isEnglish),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: primaryTeal,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(
                      isEnglish ? "Enter Clinic Code" : "Ilagay ang Code",
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 42,
                width: 42,
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
                    backgroundColor: primaryDark,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Icon(Icons.qr_code_scanner_rounded, size: 20),
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.schedule_rounded, color: Color(0xFFD97706), size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEnglish ? "Verification in Progress" : "Naghihintay ng Pagpapatunay",
                      style: GoogleFonts.inter(color: const Color(0xFF92400E), fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isEnglish ? "Provide your Patient ID to the Carmona clinic staff." : "Ipakita ang iyong Patient ID sa tauhan ng klinika sa Carmona.",
                      style: GoogleFonts.inter(color: const Color(0xFFB45309), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFFCD34D)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  isEnglish ? "OFFICIAL PATIENT ID" : "ANG IYONG PATIENT ID",
                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: textMuted, letterSpacing: 1.2),
                ),
                const SizedBox(height: 2),
                SelectableText(
                  _userId.length >= 8 ? _userId.substring(0, 8).toUpperCase() : _userId,
                  style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: textCharcoal, letterSpacing: 2),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildVerifiedCard(bool isEnglish) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBBF7D0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(color: Color(0xFFDCFCE7), shape: BoxShape.circle),
            child: const Icon(Icons.verified_user_rounded, color: Color(0xFF16A34A), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEnglish ? "Enrolled Patient" : "Napatunayang Pasyente",
                  style: GoogleFonts.inter(color: const Color(0xFF15803D), fontWeight: FontWeight.w700, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  _doctorName != null
                      ? (isEnglish ? "Assigned Clinician: ${_formatDoctorName(_doctorName)}" : "Nakatagang Doktor: ${_formatDoctorName(_doctorName)}")
                      : (isEnglish ? "Officially connected with Carmona Health Center." : "Konektado sa Carmona Health Center."),
                  style: GoogleFonts.inter(color: const Color(0xFF166534), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- REASSURING, NON-PANICKING STATUS BANNER ---
  Widget _buildTreatmentBanner(bool isEnglish) {
    final lower = _riskLevel.toLowerCase();
    bool isNotAssessed = lower.contains("not yet") || lower.contains("hindi pa") || lower.isEmpty;

    String displayText;
    String helperText;
    Color badgeColor = const Color(0xFF475569);
    Color bannerBg = const Color(0xFFF8FAFC);
    Color borderColor = const Color(0xFFCBD5E1);
    IconData statusIcon = Icons.fact_check_outlined;

    if (isNotAssessed) {
      displayText = isEnglish ? "Screening Pending" : "Kailangang Sumailalim sa Pagsusuri";
      helperText = isEnglish
          ? "Complete the triage protocol to evaluate symptoms"
          : "Kumpletuhin ang pagsusuri upang malaman ang kalagayan";
      badgeColor = const Color(0xFF475569);
      bannerBg = const Color(0xFFF8FAFC);
      borderColor = const Color(0xFFCBD5E1);
      statusIcon = Icons.assignment_outlined;
    } else if (lower.contains("high") || lower.contains("priority") || lower.contains("mataas")) {
      // Reassuring priority terminology instead of "High Risk"
      displayText = isEnglish ? "Priority Consultation Recommended" : "Inirerekomendang Magpatingin Agad";
      helperText = isEnglish
          ? "A routine clinic consultation is advised for peace of mind"
          : "Pumunta sa health center para sa kumpirmasyon at gabay";
      badgeColor = const Color(0xFFDC2626);
      bannerBg = const Color(0xFFFEF2F2);
      borderColor = const Color(0xFFFECACA);
      statusIcon = Icons.medical_services_outlined;
    } else if (lower.contains("medium") || lower.contains("moderate") || lower.contains("advised") || lower.contains("checkup") || lower.contains("katamtaman")) {
      // Calming checkup terminology instead of "Medium Risk"
      displayText = isEnglish ? "Routine Checkup Advised" : "Ipinapayong Magpa-checkup";
      helperText = isEnglish
          ? "Consider discussing your symptoms with your clinic doctor"
          : "Mag-iskedyul ng karaniwang konsultasyon sa doktor";
      badgeColor = const Color(0xFFD97706);
      bannerBg = const Color(0xFFFFFBEB);
      borderColor = const Color(0xFFFDE68A);
      statusIcon = Icons.health_and_safety_outlined;
    } else {
      // Reassuring monitoring terminology instead of "Low Risk"
      displayText = isEnglish ? "Routine Health Monitoring" : "Maayos / Karaniwang Pagsubaybay";
      helperText = isEnglish
          ? "Low clinical indicators reported - maintain healthy habits"
          : "Mababang banta - panatilihin ang malusog na pamumuhay";
      badgeColor = const Color(0xFF0F766E);
      bannerBg = const Color(0xFFF0FDFA);
      borderColor = const Color(0xFFCCFBF1);
      statusIcon = Icons.verified_outlined;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bannerBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: borderColor)),
            child: Icon(statusIcon, color: badgeColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEnglish ? 'Screening & Triage Status' : 'Katayuan ng Pagsusuri',
                  style: GoogleFonts.inter(color: textMuted, fontWeight: FontWeight.w600, fontSize: 11),
                ),
                const SizedBox(height: 2),
                Text(
                  displayText,
                  style: GoogleFonts.inter(color: textCharcoal, fontSize: 14, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  helperText,
                  style: GoogleFonts.inter(color: textMuted, fontSize: 11, fontWeight: FontWeight.w400),
                ),
              ],
            ),
          ),
          if (isNotAssessed)
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/assess'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryTeal,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
              child: Text(
                isEnglish ? "Start" : "Simulan",
                style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}

// --- UNIFIED CLINICAL ACTION CARD ---
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

  static const Color primaryTeal = Color(0xFF0F766E);
  static const Color textCharcoal = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color borderNeutral = Color(0xFFE2E8F0);

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => !widget.isLocked ? setState(() => _isHovering = true) : null,
      onExit: (_) => !widget.isLocked ? setState(() => _isHovering = false) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        transform: Matrix4.identity()..translate(0.0, _isHovering ? -2.0 : 0.0),
        decoration: BoxDecoration(
          color: widget.isLocked ? const Color(0xFFF8FAFC) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.isLocked
                ? borderNeutral
                : (_isHovering ? primaryTeal.withOpacity(0.5) : borderNeutral),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: primaryTeal.withOpacity(_isHovering ? 0.08 : 0.02),
              blurRadius: _isHovering ? 12 : 6,
              offset: const Offset(0, 2),
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
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Monochromatic Clinical Icon Badge
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: widget.isLocked
                              ? const Color(0xFFE2E8F0)
                              : const Color(0xFFF0FDFA),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: widget.isLocked
                                ? borderNeutral
                                : const Color(0xFFCCFBF1),
                            width: 1.0,
                          ),
                        ),
                        child: Icon(
                          widget.icon,
                          color: widget.isLocked
                              ? const Color(0xFF94A3B8)
                              : primaryTeal,
                          size: 20,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        widget.title,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                          color: widget.isLocked ? const Color(0xFF94A3B8) : textCharcoal,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        widget.subtitle,
                        style: GoogleFonts.inter(
                          color: widget.isLocked ? const Color(0xFFDC2626).withOpacity(0.7) : textMuted,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  if (widget.isLocked)
                    const Positioned(
                      top: 0,
                      right: 0,
                      child: Icon(Icons.lock_outline_rounded, color: Color(0xFFCBD5E1), size: 18),
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