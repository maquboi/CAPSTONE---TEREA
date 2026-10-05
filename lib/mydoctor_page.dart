import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class MyDoctorPage extends StatefulWidget {
  const MyDoctorPage({Key? key}) : super(key: key);

  @override
  State<MyDoctorPage> createState() => _MyDoctorPageState();
}

class _MyDoctorPageState extends State<MyDoctorPage> {
  final supabase = Supabase.instance.client;

  bool _isLoading = true;
  bool _hasDoctor = false;
  Map<String, dynamic>? _doctorData;
  String? _errorMessage;

  RealtimeChannel? _doctorSubscription;

  // --- FORMAL CLINICAL COLOR SYSTEM ---
  static const Color primaryTeal = Color(0xFF0F766E);       // Deep Clinical Teal
  static const Color primaryDark = Color(0xFF115E59);       // Spruce Slate
  static const Color backgroundSurface = Color(0xFFF1F5F9); // Slate 100
  static const Color cardBg = Colors.white;                // Pure White Card
  static const Color textCharcoal = Color(0xFF0F172A);      // High Contrast Text
  static const Color textMuted = Color(0xFF64748B);         // Subdued Slate Text
  static const Color borderNeutral = Color(0xFFE2E8F0);     // Clean Structured Border
  static const Color emeraldGreen = Color(0xFF059669);      // Active / Status Green

  @override
  void initState() {
    super.initState();
    _fetchDoctorInfo();
  }

  @override
  void dispose() {
    _doctorSubscription?.unsubscribe();
    super.dispose();
  }

  // Prevents duplicate "Dr. Dr." prefixes
  String _formatDoctorName(String? name) {
    if (name == null || name.trim().isEmpty) return "Unknown Doctor";
    final clean = name.trim().replaceFirst(RegExp(r'^(dr\.?\s*)+', caseSensitive: false), '');
    return "Dr. $clean";
  }

  Future<void> _fetchDoctorInfo() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception("User not logged in");

      final connectionResponse = await supabase
          .from('connections')
          .select('doctor_id')
          .eq('patient_id', user.id)
          .eq('status', 'active')
          .maybeSingle();

      if (connectionResponse == null) {
        if (mounted) {
          setState(() {
            _hasDoctor = false;
            _isLoading = false;
          });
        }
        return;
      }

      final doctorId = connectionResponse['doctor_id'];

      // Setup Realtime Subscription to Doctor's Profile for Live Hour Updates
      if (_doctorSubscription == null) {
        _doctorSubscription = supabase
            .channel('public:profiles:doctor_hours')
            .onPostgresChanges(
              event: PostgresChangeEvent.update,
              schema: 'public',
              table: 'profiles',
              filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'id', value: doctorId),
              callback: (payload) {
                _fetchDoctorInfo(); // Re-fetch data silently when doctor updates settings
              },
            )
            .subscribe();
      }

      final doctorProfile = await supabase
          .from('profiles')
          .select('*')
          .eq('id', doctorId)
          .single();

      if (mounted) {
        setState(() {
          _doctorData = doctorProfile;
          _hasDoctor = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundSurface,
      appBar: AppBar(
        backgroundColor: backgroundSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: textCharcoal, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Attending Clinician',
          style: GoogleFonts.inter(
            color: textCharcoal,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: primaryTeal));
    }

    if (_errorMessage != null) {
      return Center(
        child: Text(
          "Error: $_errorMessage",
          style: GoogleFonts.inter(color: const Color(0xFFDC2626), fontSize: 13),
        ),
      );
    }

    if (!_hasDoctor || _doctorData == null) {
      return _buildUnverifiedState();
    }

    return _buildDoctorProfile();
  }

  Widget _buildUnverifiedState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: primaryTeal.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.medical_information_outlined, size: 48, color: primaryTeal),
            ),
            const SizedBox(height: 20),
            Text(
              "No Assigned Clinician",
              style: GoogleFonts.inter(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: textCharcoal,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "You are not yet linked to an attending doctor. Please link with Carmona Health Center using your clinic code.",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, color: textMuted, height: 1.4),
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryTeal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text(
                "Return to Dashboard",
                style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorProfile() {
    final String rawName = _doctorData?['full_name'] ?? 'Unknown Doctor';
    final String formattedName = _formatDoctorName(rawName);
    final String email = _doctorData?['email'] ?? 'No email provided';
    final String phone = _doctorData?['phone_number'] ?? 'No phone provided';
    final String avatarUrl = _doctorData?['avatar_url'] ?? '';
    final String clinic = _doctorData?['clinic_name'] ?? 'Carmona Health Center';

    String formatTimeString(String timeStr) {
      try {
        if (timeStr.toLowerCase().contains('am') || timeStr.toLowerCase().contains('pm')) {
          return timeStr.toUpperCase();
        }

        final parts = timeStr.split(':');
        if (parts.isEmpty) return timeStr;

        int hr = int.parse(parts[0]);
        final min = parts.length > 1 ? parts[1] : '00';
        final ampm = hr >= 12 ? 'PM' : 'AM';

        hr = hr % 12;
        if (hr == 0) hr = 12;

        return '$hr:$min $ampm';
      } catch (e) {
        return timeStr;
      }
    }

    final String startHour = _doctorData?['start_hour'] ?? '08:00';
    final String endHour = _doctorData?['end_hour'] ?? '17:00';
    final String availability = '${formatTimeString(startHour)} - ${formatTimeString(endHour)}';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main Physician Identity Card
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderNeutral),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              children: [
                Container(
                  height: 200,
                  width: double.infinity,
                  margin: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: const Color(0xFFF1F5F9),
                    border: Border.all(color: borderNeutral),
                    image: avatarUrl.isNotEmpty
                        ? DecorationImage(image: NetworkImage(avatarUrl), fit: BoxFit.cover)
                        : null,
                  ),
                  child: avatarUrl.isEmpty
                      ? const Center(child: Icon(Icons.person_rounded, size: 70, color: textMuted))
                      : null,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18.0),
                  child: Column(
                    children: [
                      Text(
                        formattedName,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: textCharcoal,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: primaryTeal.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: primaryTeal.withOpacity(0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.verified_rounded, color: primaryTeal, size: 13),
                            const SizedBox(width: 6),
                            Text(
                              "Attending Physician • Carmona",
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: primaryTeal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Text(
              "CLINICAL INFORMATION & SCHEDULE",
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: textMuted,
                letterSpacing: 1.0,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Schedule Card
          _buildDetailCard(
            statusText: 'Duty Hours',
            title: "Consultation Schedule",
            subtitle: availability,
            icon: Icons.access_time_rounded,
          ),
          const SizedBox(height: 10),

          // Clinic Facility Card
          _buildDetailCard(
            statusText: 'Primary Facility',
            title: "Assigned Health Center",
            subtitle: clinic,
            icon: Icons.local_hospital_outlined,
          ),
          const SizedBox(height: 10),

          // Email Contact Card
          _buildDetailCard(
            statusText: 'Official Email',
            title: "Professional Contact",
            subtitle: email,
            icon: Icons.mail_outline_rounded,
          ),
          const SizedBox(height: 10),

          // Direct Phone Card
          _buildDetailCard(
            statusText: 'Direct Line',
            title: "Clinic Hotline / Mobile",
            subtitle: phone,
            icon: Icons.phone_outlined,
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildDetailCard({
    required String statusText,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderNeutral),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: primaryTeal.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    statusText.toUpperCase(),
                    style: GoogleFonts.inter(
                      color: primaryTeal,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: textCharcoal,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: textMuted,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDFA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFCCFBF1)),
            ),
            child: Icon(icon, color: primaryTeal, size: 20),
          ),
        ],
      ),
    );
  }
}