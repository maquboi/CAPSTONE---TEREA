import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'shared_widgets.dart'; // REQUIRED to access isEnglishNotifier

class MedsPage extends StatefulWidget {
  const MedsPage({super.key});

  @override
  State<MedsPage> createState() => _MedsPageState();
}

class _MedsPageState extends State<MedsPage> {
  List<dynamic> myMeds = [];
  List<dynamic> myMedLogs = [];
  bool _isLoading = true;
  bool _showHistoryLog = false;
  DateTime _selectedDate = DateTime.now();
  String _viewType = 'Week';

  DateTime? _treatmentStartDate;
  DateTime? _treatmentEndDate;
  String? _connectionStatus;
  String? _patientStatus;
  String _riskLevel = "Not yet assessed";
  String _userId = "";

  Map<String, dynamic>? _latestDoctorNote;

  final Map<String, bool> _fadingMedIds = {};
  final Set<String> _optimisticTakenMeds = {};

  // --- FORMAL CLINICAL COLOR SYSTEM ---
  static const Color primaryTeal = Color(0xFF0F766E);       // Deep Clinical Teal
  static const Color primaryDark = Color(0xFF115E59);       // Spruce Slate
  static const Color primaryDeep = Color(0xFF042F2E);       // Deepest Navy Teal
  static const Color backgroundSurface = Color(0xFFF1F5F9); // Contrast Slate Background
  static const Color cardBg = Colors.white;                // Crisp White Card
  static const Color textCharcoal = Color(0xFF0F172A);      // High Contrast Text
  static const Color textMuted = Color(0xFF64748B);         // Subdued Text
  static const Color borderNeutral = Color(0xFFE2E8F0);     // Clean Structured Border
  static const Color emeraldGreen = Color(0xFF059669);      // Positive Compliance
  static const Color inputBg = Color(0xFFF8FAFC);          // Form Field Background

  @override
  void initState() {
    super.initState();
    _fetchData();
    _setupRealtimeListener();
  }

  void _showNotificationPopup(String message, String titleStr, {bool isSuccess = false}) {
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
        final icon = isSuccess ? Icons.check_circle_outline_rounded : Icons.error_outline_rounded;

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
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'medication_logs',
          filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'patient_id', value: user.id),
          callback: (payload) => _fetchData(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'doctor_notes',
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
          .select('treatment_start_date, treatment_end_date, risk_level, status')
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
          .eq('user_id', user.id)
          .neq('is_archived', true);

      final logsData = await Supabase.instance.client
          .from('medication_logs')
          .select()
          .eq('patient_id', user.id)
          .order('log_date', ascending: false);

      final noteData = await Supabase.instance.client
          .from('doctor_notes')
          .select('note_text, created_at')
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      await _autoLogPastMissedDoses(medsData as List<dynamic>, logsData as List<dynamic>, user.id);

      if (mounted) {
        setState(() {
          _userId = user.id;
          _connectionStatus = connectionData?['status'];
          _patientStatus = profileData?['status'];
          _riskLevel = profileData?['risk_level'] ?? "Not yet assessed";
          _latestDoctorNote = noteData;

          if (profileData != null && profileData['treatment_start_date'] != null) {
            _treatmentStartDate = DateTime.parse(profileData['treatment_start_date'].toString());
          }
          if (profileData != null && profileData['treatment_end_date'] != null) {
            _treatmentEndDate = DateTime.parse(profileData['treatment_end_date'].toString());
          }

          myMeds = medsData;
          myMedLogs = logsData;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching data: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _autoLogPastMissedDoses(List<dynamic> meds, List<dynamic> logs, String userId) async {
    final today = DateTime.now();
    final todayDateOnly = DateTime(today.year, today.month, today.day);
    final yesterday = todayDateOnly.subtract(const Duration(days: 1));
    final yesterdayStr = DateFormat('yyyy-MM-dd').format(yesterday);

    List<Map<String, dynamic>> missedEntries = [];

    for (final med in meds) {
      if (med['start_date'] == null || med['end_date'] == null) continue;
      DateTime start = DateTime.parse(med['start_date']);
      DateTime end = DateTime.parse(med['end_date']);
      DateTime startDate = DateTime(start.year, start.month, start.day);
      DateTime endDate = DateTime(end.year, end.month, end.day);

      if (!yesterday.isBefore(startDate) && !yesterday.isAfter(endDate)) {
        final hasLog = logs.any((l) {
          String dbDate = l['log_date'].toString();
          if (dbDate.length >= 10) dbDate = dbDate.substring(0, 10);
          return dbDate == yesterdayStr && l['medication_id'].toString() == med['id'].toString();
        });

        if (!hasLog) {
          missedEntries.add({
            'medication_id': med['id'],
            'patient_id': userId,
            'log_date': yesterdayStr,
            'status': 'missed',
            'timing_status': 'missed',
          });
        }
      }
    }

    if (missedEntries.isNotEmpty) {
      try {
        await Supabase.instance.client.from('medication_logs').insert(missedEntries);
        logs.addAll(missedEntries);
      } catch (e) {
        debugPrint("Auto-sweeper caught error inserting missed logs: $e");
      }
    }
  }

  String _getCurrentPhase(bool isEnglish) {
    if (_patientStatus == 'cured' || _patientStatus == 'treatment_completed') {
      return isEnglish ? "Post-Care Surveillance" : "Post-Care Surveillance";
    }

    if (_treatmentStartDate == null) return isEnglish ? "Phase Not Set" : "Wala Pang Phase";
    final daysPassed = DateTime.now().difference(_treatmentStartDate!).inDays;
    return daysPassed <= 60
        ? (isEnglish ? "Intensive Phase (HRZE)" : "Intensive Phase (HRZE)")
        : (isEnglish ? "Continuation Phase (HR)" : "Continuation Phase (HR)");
  }

  void _handleAddNewMed(bool isEnglish) {
    _showMedDialog(isEnglish);
  }

  Future<void> _saveMed(bool isEnglish, {String? medId, required String name, required String dosage, required String time, required DateTime start, required DateTime end}) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final medData = {'user_id': user.id, 'name': name, 'dosage': dosage, 'time': time, 'start_date': start.toIso8601String(), 'end_date': end.toIso8601String(), 'is_taken': false};
    try {
      if (medId == null) {
        await Supabase.instance.client.from('medications').insert(medData);
      } else {
        await Supabase.instance.client.from('medications').update(medData).eq('id', medId);
      }
      _fetchData();
    } catch (e) {
      debugPrint("Error saving med: $e");
      if (mounted) _showNotificationPopup(isEnglish ? "Error saving medication: $e" : "Error sa pag-save: $e", "Error");
    }
  }

  Future<void> _deleteMed(String medId, bool isEnglish) async {
    try {
      await Supabase.instance.client.from('medications').update({'is_archived': true}).eq('id', medId);
      _fetchData();
    } catch (e) {
      debugPrint("Error deleting med: $e");
      if (mounted) _showNotificationPopup(isEnglish ? "Error deleting medication: $e" : "Error sa pagbura: $e", "Error");
    }
  }

  void _showAutomatedSymptomCheck(String medName, bool isEnglish) {
    final symptoms = [
      {
        "label": isEnglish ? "Blurred / Dim Vision" : "Malabong Paningin",
        "keywords": "vision blur",
        "desc": isEnglish ? "Possible Ethambutol optic reaction" : "Posibleng epekto ng Ethambutol"
      },
      {
        "label": isEnglish ? "Yellowing of Skin or Eyes (Jaundice)" : "Paninilaw ng Balat o Mata (Jaundice)",
        "keywords": "yellow jaundice",
        "desc": isEnglish ? "Possible hepatic liver stress" : "Posibleng epekto sa atay"
      },
      {
        "label": isEnglish ? "Severe Nausea / Vomiting" : "Matinding Pagsusuka o Pagkahilo",
        "keywords": "vomit nausea",
        "desc": isEnglish ? "Gastrointestinal intolerance" : "Pangangasim ng tiyan"
      },
      {
        "label": isEnglish ? "Numbness / Tingling in Hands or Feet" : "Pamamanhid o Tusok-tusok sa Kamay/Paa",
        "keywords": "numb tingling",
        "desc": isEnglish ? "Peripheral neuropathy" : "Epekto sa nerbiyos"
      },
      {
        "label": isEnglish ? "Skin Rashes / Severe Itching" : "Pantal o Matinding Pangangati ng Balat",
        "keywords": "rash itch",
        "desc": isEnglish ? "Hypersensitivity reaction" : "Reaksyon sa balat"
      },
      {
        "label": isEnglish ? "None / Feeling Well Today" : "Wala / Maayos ang Pakiramdam",
        "keywords": "none",
        "desc": isEnglish ? "Normal medication tolerance" : "Walang masamang nararamdaman"
      }
    ];

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: borderNeutral,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryTeal.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.health_and_safety_rounded, color: primaryTeal, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEnglish ? "Daily Post-Intake Check-in" : "Pang-araw-araw na Check-in",
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: textCharcoal,
                        ),
                      ),
                      Text(
                        isEnglish
                            ? "Did you experience any of these after taking $medName?"
                            : "Naramdaman mo ba ang alinman dito matapos inumin ang $medName?",
                        style: GoogleFonts.inter(fontSize: 12, color: textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: symptoms.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: borderNeutral),
                itemBuilder: (context, idx) {
                  final s = symptoms[idx];
                  final isNone = s['keywords'] == 'none';

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text(
                      s["label"]!,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isNone ? emeraldGreen : textCharcoal,
                      ),
                    ),
                    subtitle: Text(
                      s["desc"]!,
                      style: GoogleFonts.inter(fontSize: 11, color: textMuted),
                    ),
                    trailing: Icon(
                      isNone ? Icons.check_circle_outline_rounded : Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: isNone ? emeraldGreen : textMuted.withOpacity(0.5),
                    ),
                    onTap: () async {
                      Navigator.pop(ctx);
                      if (!isNone) {
                        try {
                          await Supabase.instance.client.from('doctor_notes').insert({
                            'user_id': _userId,
                            'note_text': "Patient post-intake check-in reported: ${s['label']} after taking $medName (${s['keywords']})",
                            'category': 'Adverse Event',
                            'is_checked': false,
                          });

                          _showNotificationPopup(
                            isEnglish
                                ? "Your reported symptom has been forwarded to the clinic alert feed for doctor review."
                                : "Ang iyong iniulat na sintomas ay naipadala na sa alert dashboard ng iyong doktor.",
                            isEnglish ? "Clinician Notified" : "Naabisuhan ang Doktor",
                            isSuccess: true,
                          );
                        } catch (e) {
                          debugPrint("Error auto-inserting doctor note: $e");
                        }
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleMed(bool isCurrentlyTaken, String medId, String targetTimeStr, String medName, bool isEnglish) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

    if (isCurrentlyTaken) {
      try {
        await Supabase.instance.client
            .from('medication_logs')
            .delete()
            .eq('medication_id', medId)
            .eq('log_date', dateStr);
        setState(() {
          _optimisticTakenMeds.remove('${medId}_$dateStr');
          _fadingMedIds.remove(medId);
        });
        _fetchData();
      } catch (e) {
        debugPrint("Error deleting log: $e");
        if (mounted) _showNotificationPopup(isEnglish ? "Error updating status: $e" : "Error sa pag-update: $e", "Error");
      }
    } else {
      setState(() {
        _fadingMedIds[medId] = true;
      });

      final secureNow = DateTime.now().toUtc();
      String timingStatus = 'on-time';

      try {
        final targetFormat = DateFormat("h:mm a");
        final targetTime = targetFormat.parse(targetTimeStr);
        final targetDateTime = DateTime(secureNow.year, secureNow.month, secureNow.day, targetTime.hour, targetTime.minute);

        final diffMinutes = secureNow.difference(targetDateTime).inMinutes;

        if (diffMinutes < -60) {
          timingStatus = 'early';
        } else if (diffMinutes > 60) {
          timingStatus = 'late';
        }
      } catch (e) {
        debugPrint("Error parsing time for timing check: $e");
      }

      final timeTakenStr = DateFormat('HH:mm:ss').format(secureNow);

      await Future.delayed(const Duration(milliseconds: 300));

      if (!mounted) return;

      setState(() {
        _optimisticTakenMeds.add('${medId}_$dateStr');
        _fadingMedIds.remove(medId);
      });

      try {
        await Supabase.instance.client.from('medication_logs').insert({
          'medication_id': medId,
          'patient_id': user.id,
          'log_date': dateStr,
          'time_taken': timeTakenStr,
          'status': 'taken',
          'timing_status': timingStatus,
        });

        await _fetchData();

        if (mounted) {
          _showAutomatedSymptomCheck(medName, isEnglish);
        }
      } catch (e) {
        debugPrint("Error inserting log: $e");
        if (mounted) {
          setState(() {
            _optimisticTakenMeds.remove('${medId}_$dateStr');
          });
          _showNotificationPopup(isEnglish ? "Failed to log medication: $e" : "Bigo sa pag-log ng gamot: $e", "Error");
        }
      }
    }
  }

  void _showMedDialog(bool isEnglish, {Map<String, dynamic>? existingMed}) async {
    final nameController = TextEditingController(text: existingMed?['name']);
    final dosageController = TextEditingController(text: existingMed?['dosage']);
    String selectedTime = existingMed?['time'] ?? "08:00 AM";
    DateTime startDate = existingMed != null ? DateTime.parse(existingMed['start_date']) : DateTime.now();
    DateTime endDate = existingMed != null ? DateTime.parse(existingMed['end_date']) : DateTime.now().add(const Duration(days: 7));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: borderNeutral),
          ),
          title: Text(
            existingMed == null ? (isEnglish ? "Prescribe Medication" : "Magdagdag ng Gamot") : (isEnglish ? "Edit Medication" : "I-edit ang Detalye"),
            style: GoogleFonts.inter(color: textCharcoal, fontWeight: FontWeight.w700, fontSize: 16),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildModalTextField(
                  label: isEnglish ? "Medicine Name" : "Pangalan ng Gamot",
                  hint: "e.g. HRZE Fixed Dose",
                  controller: nameController,
                ),
                const SizedBox(height: 14),
                _buildModalTextField(
                  label: isEnglish ? "Dosage" : "Dosis",
                  hint: "e.g. 3 Tablets Daily",
                  controller: dosageController,
                ),
                const SizedBox(height: 16),
                _buildDialogTile(
                  icon: Icons.access_time_rounded,
                  title: isEnglish ? "Target Reminder Time" : "Oras ng Paalala",
                  value: selectedTime,
                  onTap: () async {
                    TimeOfDay? picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                    if (picked != null) setDialogState(() => selectedTime = picked.format(context));
                  },
                ),
                const SizedBox(height: 8),
                _buildDialogTile(
                  icon: Icons.calendar_today_rounded,
                  title: isEnglish ? "Treatment Duration" : "Haba ng Gamutan",
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
              child: Text(isEnglish ? "Cancel" : "Kanselahin", style: GoogleFonts.inter(color: textMuted, fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryTeal,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onPressed: () {
                _saveMed(
                  isEnglish,
                  medId: existingMed?['id']?.toString(),
                  name: nameController.text,
                  dosage: dosageController.text,
                  time: selectedTime,
                  start: startDate,
                  end: endDate,
                );
                Navigator.pop(context);
              },
              child: Text(isEnglish ? "Save Medication" : "I-save", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModalTextField({required String label, required String hint, required TextEditingController controller}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: textCharcoal)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          style: GoogleFonts.inter(fontSize: 14, color: textCharcoal, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(color: Colors.black26, fontSize: 13),
            filled: true,
            fillColor: inputBg,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: borderNeutral)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: borderNeutral)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: primaryTeal, width: 1.5)),
          ),
        ),
      ],
    );
  }

  Widget _buildDialogTile({required IconData icon, required String title, required String value, required VoidCallback onTap}) {
    return Container(
      decoration: BoxDecoration(
        color: inputBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderNeutral),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: Icon(icon, color: primaryTeal, size: 20),
        title: Text(title, style: GoogleFonts.inter(fontSize: 11, color: textMuted)),
        subtitle: Text(value, style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w600, color: textCharcoal)),
        onTap: onTap,
      ),
    );
  }

  // --- HELPER: GROUPING BY TIME OF DAY ---
  String _getTimeBucket(String timeStr) {
    try {
      final parsed = DateFormat("h:mm a").parse(timeStr);
      if (parsed.hour < 12) return "morning";
      if (parsed.hour < 18) return "afternoon";
      return "evening";
    } catch (_) {
      return "morning";
    }
  }

  @override
  Widget build(BuildContext context) {
    bool hasTakenAssessment = _riskLevel != "Not yet assessed" && _riskLevel != "Hindi pa nasusuri";
    bool isVerifiedByDoctor = _connectionStatus == 'active';
    bool isUnlocked = hasTakenAssessment && isVerifiedByDoctor;
    bool isCured = _patientStatus == 'cured' || _patientStatus == 'treatment_completed';

    return ValueListenableBuilder<bool>(
      valueListenable: isEnglishNotifier,
      builder: (context, isEnglish, child) {
        return Scaffold(
          backgroundColor: backgroundSurface,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: textCharcoal, size: 18),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              isEnglish ? 'Medication Diary' : 'Talaan ng Gamot',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: textCharcoal, fontSize: 17),
            ),
            centerTitle: true,
            actions: [
              if (isUnlocked)
                IconButton(
                  icon: Icon(
                    _showHistoryLog ? Icons.calendar_view_day_rounded : Icons.history_rounded,
                    color: primaryTeal,
                  ),
                  tooltip: isEnglish ? "Compliance Logs" : "Kasaysayan",
                  onPressed: () => setState(() => _showHistoryLog = !_showHistoryLog),
                )
            ],
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator(color: primaryTeal))
              : isUnlocked
                  ? _showHistoryLog
                      ? _buildHistoryLogsContent(isEnglish)
                      : _buildUnlockedContent(isEnglish)
                  : _buildLockedUI(hasTakenAssessment, isVerifiedByDoctor, isEnglish),
          floatingActionButton: (isUnlocked && !_showHistoryLog && !isCured)
              ? FloatingActionButton(
                  backgroundColor: primaryTeal,
                  elevation: 2,
                  onPressed: () => _handleAddNewMed(isEnglish),
                  child: const Icon(Icons.add_rounded, color: Colors.white, size: 26),
                )
              : null,
        );
      },
    );
  }

  Widget _buildUnlockedContent(bool isEnglish) {
    return Column(
      children: [
        _buildModernHeader(isEnglish),
        if (_latestDoctorNote != null) _buildDoctorAdviceCard(isEnglish),
        const SizedBox(height: 14),
        _buildViewSelector(isEnglish),
        const SizedBox(height: 12),
        _buildCalendarSection(isEnglish),
        const SizedBox(height: 14),
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
              border: Border(top: BorderSide(color: borderNeutral, width: 1)),
            ),
            child: _buildMedList(isEnglish),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryLogsContent(bool isEnglish) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isEnglish ? "Compliance Audit History" : "Kasaysayan ng Pagsunod",
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: textCharcoal),
              ),
              TextButton.icon(
                onPressed: () => setState(() => _showHistoryLog = false),
                icon: const Icon(Icons.arrow_back, size: 15, color: primaryTeal),
                label: Text(
                  isEnglish ? "Back to Diary" : "Bumalik",
                  style: GoogleFonts.inter(color: primaryTeal, fontWeight: FontWeight.w700, fontSize: 13),
                ),
              )
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: myMedLogs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.history_edu_rounded, size: 48, color: textMuted),
                        const SizedBox(height: 10),
                        Text(
                          isEnglish ? "No recorded adherence logs yet." : "Wala pang naitalang kasaysayan.",
                          style: GoogleFonts.inter(color: textMuted, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: myMedLogs.length,
                    itemBuilder: (context, index) {
                      final log = myMedLogs[index];
                      final medMatch = myMeds.where((m) => m['id'].toString() == log['medication_id'].toString());
                      final String medName = medMatch.isNotEmpty ? medMatch.first['name'] : "Medication";
                      final String dosage = medMatch.isNotEmpty ? medMatch.first['dosage'] : "";

                      DateTime parsedDate = DateTime.parse(log['log_date']);
                      String formattedLogDay = DateFormat('EEEE, MMM d').format(parsedDate);
                      String timingStatus = log['timing_status'] ?? 'on-time';

                      Color badgeColor = emeraldGreen;
                      Color badgeBg = const Color(0xFFD1FAE5);
                      String badgeText = "ON-TIME";

                      if (log['status'] != 'taken') {
                        badgeColor = const Color(0xFFDC2626);
                        badgeBg = const Color(0xFFFEF2F2);
                        badgeText = "MISSED";
                      } else if (timingStatus == 'early') {
                        badgeColor = const Color(0xFF2563EB);
                        badgeBg = const Color(0xFFDBEAFE);
                        badgeText = "EARLY";
                      } else if (timingStatus == 'late') {
                        badgeColor = const Color(0xFFD97706);
                        badgeBg = const Color(0xFFFEF3C7);
                        badgeText = "LATE";
                      }

                      return Card(
                        color: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: const BorderSide(color: borderNeutral),
                        ),
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          leading: CircleAvatar(
                            radius: 18,
                            backgroundColor: log['status'] == 'taken' ? const Color(0xFFD1FAE5) : const Color(0xFFFEF2F2),
                            child: Icon(
                              log['status'] == 'taken' ? Icons.check_rounded : Icons.close_rounded,
                              color: log['status'] == 'taken' ? emeraldGreen : const Color(0xFFDC2626),
                              size: 20,
                            ),
                          ),
                          title: Text(
                            medName,
                            style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: textCharcoal, fontSize: 14),
                          ),
                          subtitle: Text(
                            log['status'] == 'taken'
                                ? (isEnglish ? "$dosage • Ingested at ${log['time_taken']}\n$formattedLogDay" : "$dosage • Ininom noong ${log['time_taken']}\n$formattedLogDay")
                                : (isEnglish ? "$dosage • Missed Daily Window\n$formattedLogDay" : "$dosage • Nakaligtaang Inumin\n$formattedLogDay"),
                            style: GoogleFonts.inter(fontSize: 12, color: textMuted, height: 1.3),
                          ),
                          isThreeLine: true,
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: badgeBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              badgeText,
                              style: GoogleFonts.inter(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: badgeColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorAdviceCard(bool isEnglish) {
    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.fromLTRB(18, 12, 18, 0),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDFA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFCCFBF1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: const Icon(Icons.tips_and_updates_rounded, color: primaryTeal, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEnglish ? "Attending Clinician Note" : "Payo ng Doktor",
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: primaryTeal, letterSpacing: 0.3),
                ),
                const SizedBox(height: 2),
                Text(
                  _latestDoctorNote!['note_text'],
                  style: GoogleFonts.inter(fontSize: 12.5, color: textCharcoal, fontWeight: FontWeight.w500, height: 1.3),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewSelector(bool isEnglish) {
    final List<String> types = isEnglish ? ['Day', 'Week', 'Month'] : ['Araw', 'Linggo', 'Buwan'];
    final List<String> originalTypes = ['Day', 'Week', 'Month'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(3),
        child: Row(
          children: List.generate(types.length, (index) {
            String displayType = types[index];
            String internalValue = originalTypes[index];
            bool isSelected = _viewType == internalValue;

            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _viewType = internalValue),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeInOut,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: isSelected
                        ? [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 1))]
                        : [],
                  ),
                  child: Center(
                    child: Text(
                      displayType,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? textCharcoal : textMuted,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildLockedUI(bool hasAssessed, bool isVerified, bool isEnglish) {
    String title = isEnglish ? "Medication Diary Locked" : "Naka-lock ang Talaan";
    String message = isEnglish
        ? "To ensure patient safety, the Medication Diary is restricted until you complete clinical screening and pair with your Carmona doctor."
        : "Para sa iyong kaligtasan, naka-lock ang Talaan ng Gamot hanggang makumpleto mo ang pagsusuri at makakonekta sa iyong doktor.";
    IconData icon = Icons.lock_outline_rounded;

    if (!hasAssessed) {
      title = isEnglish ? "Screening Required" : "Kailangan ng Pagsusuri";
      message = isEnglish ? "Please complete the TB Risk Assessment to unlock clinical treatment features." : "Mangyaring kumpletuhin muna ang Pagsusuri upang magamit ang iyong mga health feature.";
      icon = Icons.assignment_late_outlined;
    } else if (!isVerified) {
      title = isEnglish ? "Verification in Progress" : "Naghihintay ng Pagpapatunay";
      message = isEnglish ? "Screening complete! Show your Patient ID to the Carmona TB-DOTS staff to activate your chart." : "Tapos na ang pagsusuri! Ipakita ang iyong Patient ID sa tauhan ng klinika sa Carmona.";
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
              decoration: BoxDecoration(color: primaryTeal.withOpacity(0.08), shape: BoxShape.circle),
              child: Icon(icon, size: 44, color: primaryTeal),
            ),
            const SizedBox(height: 24),
            Text(title, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: textCharcoal)),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center, style: GoogleFonts.inter(color: textMuted, fontSize: 13, height: 1.4)),

            if (hasAssessed && !isVerified) ...[
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: borderNeutral),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    Text(isEnglish ? "YOUR PATIENT ID" : "ANG IYONG PATIENT ID", style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: textMuted, letterSpacing: 1.2)),
                    const SizedBox(height: 4),
                    SelectableText(
                      _userId.length >= 8 ? _userId.substring(0, 8).toUpperCase() : _userId,
                      style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: textCharcoal, letterSpacing: 2),
                    ),
                  ],
                ),
              )
            ],

            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pushReplacementNamed(context, hasAssessed ? '/dashboard' : '/assess'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryTeal,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                elevation: 0,
              ),
              child: Text(
                hasAssessed ? (isEnglish ? "Return to Dashboard" : "Pumunta sa Dashboard") : (isEnglish ? "Start Screening" : "Magsimula ng Pagsusuri"),
                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernHeader(bool isEnglish) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      padding: const EdgeInsets.all(18),
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primaryDeep, primaryTeal],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isEnglish ? 'Medication Diary' : 'Dayariya ng gamot',
                style: GoogleFonts.inter(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Text(
                  _getCurrentPhase(isEnglish),
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            isEnglish ? 'Log daily fixed-dose ingestion to track your treatment adherence.' : 'Itala ang pag-inom ng gamot araw-araw.',
            style: GoogleFonts.inter(color: Colors.white.withOpacity(0.85), fontSize: 12),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.event_note_rounded, color: Colors.white, size: 15),
              const SizedBox(width: 8),
              Text(
                DateFormat('MMMM dd, yyyy').format(_selectedDate),
                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildCalendarSection(bool isEnglish) {
    if (_viewType == 'Month') return SizedBox(height: 310, child: _buildMonthGrid());
    if (_viewType == 'Day') return Center(child: SizedBox(height: 78, child: _buildDateCard(_selectedDate, true)));
    return SizedBox(height: 78, child: _buildWeekStrip());
  }

  Widget _buildWeekStrip() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 14),
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
      padding: const EdgeInsets.symmetric(horizontal: 18),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.85,
      ),
      itemCount: daysInMonth,
      itemBuilder: (context, index) {
        DateTime date = DateTime(_selectedDate.year, _selectedDate.month, index + 1);
        bool isSelected = date.day == _selectedDate.day && date.month == _selectedDate.month;
        return _buildDateCard(date, isSelected, compact: true);
      },
    );
  }

  Widget _buildDateCard(DateTime date, bool isSelected, {bool compact = false}) {
    String formattedDate = DateFormat('yyyy-MM-dd').format(date);

    bool isCompletedDay = myMedLogs.any((log) {
      String dbDate = log['log_date'].toString();
      if (dbDate.length >= 10) dbDate = dbDate.substring(0, 10);
      return dbDate == formattedDate && log['status'] == 'taken';
    });

    return GestureDetector(
      onTap: () => setState(() => _selectedDate = date),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: compact ? null : 60,
        margin: EdgeInsets.symmetric(horizontal: compact ? 2 : 4, vertical: compact ? 2 : 2),
        decoration: BoxDecoration(
          color: isSelected ? primaryTeal : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [BoxShadow(color: primaryTeal.withOpacity(0.25), blurRadius: 6, offset: const Offset(0, 2))]
              : [],
          border: Border.all(
            color: isSelected
                ? primaryTeal
                : (isCompletedDay ? emeraldGreen.withOpacity(0.5) : borderNeutral),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  DateFormat('E').format(date).toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: compact ? 8.5 : 10,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white70 : textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  date.day.toString(),
                  style: GoogleFonts.inter(
                    fontSize: compact ? 13 : 16,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : textCharcoal,
                  ),
                ),
              ],
            ),
            if (isCompletedDay)
              Positioned(
                bottom: compact ? 2 : 3,
                right: compact ? 2 : 5,
                child: Icon(
                  Icons.check_circle_rounded,
                  color: isSelected ? Colors.white : emeraldGreen,
                  size: compact ? 10 : 13,
                ),
              )
          ],
        ),
      ),
    );
  }

  Widget _buildDischargedSurveillanceCard(bool isEnglish) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFBBF7D0)),
            boxShadow: [
              BoxShadow(
                color: emeraldGreen.withOpacity(0.06),
                blurRadius: 14,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFDCFCE7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.workspace_premium_rounded, color: emeraldGreen, size: 36),
              ),
              const SizedBox(height: 14),
              Text(
                isEnglish ? "Treatment Successfully Completed!" : "Tagumpay na Nakumpleto ang Gamutan!",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800, color: textCharcoal),
              ),
              const SizedBox(height: 6),
              Text(
                isEnglish
                    ? "You have completed your prescribed TB regimen. Active daily pill intake has concluded."
                    : "Natapos mo na ang itinakdang gamutan sa TB. Hindi mo na kailangang uminom ng gamot araw-araw.",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 12.5, color: textMuted, height: 1.4),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: backgroundSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderNeutral),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.shield_outlined, color: primaryTeal, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          isEnglish ? "Surveillance Surveillance Protocol" : "Aktibong Pagsubaybay",
                          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12.5, color: textCharcoal),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isEnglish
                          ? "Please keep this app installed to receive surveillance checkup reminders for your 6-Month and 1-Year follow-up visits at Carmona Health Center."
                          : "Panatilihing naka-install ang app na ito upang makatanggap ng paalala para sa iyong 6-Month at 1-Year surveillance checkup sa Carmona Health Center.",
                      style: GoogleFonts.inter(fontSize: 11.5, color: textMuted, height: 1.35),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCelebratoryCard(bool isEnglish) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                color: Color(0xFFDCFCE7),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.task_alt_rounded, size: 48, color: emeraldGreen),
            ),
            const SizedBox(height: 18),
            Text(
              isEnglish ? "All Doses Taken for Today" : "Nainom Na ang Lahat ng Gamot",
              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: textCharcoal),
            ),
            const SizedBox(height: 6),
            Text(
              isEnglish
                  ? "Great job adhering to your DOTS regimen. Stay hydrated and rest well."
                  : "Mahusay ang iyong pagsunod sa gamutan. Uminom ng tubig at magpahinga nang maayos.",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, color: textMuted, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedList(bool isEnglish) {
    final bool isCured = _patientStatus == 'cured' || _patientStatus == 'treatment_completed';

    if (isCured) {
      return _buildDischargedSurveillanceCard(isEnglish);
    }

    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

    final filteredMeds = myMeds.where((med) {
      DateTime start = DateTime.parse(med['start_date']);
      DateTime end = DateTime.parse(med['end_date']);
      DateTime startDate = DateTime(start.year, start.month, start.day);
      DateTime endDate = DateTime(end.year, end.month, end.day);
      DateTime selectedDate = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);

      bool dateInRange = !selectedDate.isBefore(startDate) && !selectedDate.isAfter(endDate);
      if (!dateInRange) return false;

      if (_optimisticTakenMeds.contains('${med['id']}_$dateStr')) return false;

      final takenLog = myMedLogs.where((l) {
        if (l['medication_id'].toString() != med['id'].toString()) return false;
        if (l['status'] != 'taken') return false;

        String dbDate = l['log_date'].toString();
        if (dbDate.length >= 10) dbDate = dbDate.substring(0, 10);

        return dbDate == dateStr;
      });

      return takenLog.isEmpty;
    }).toList();

    if (filteredMeds.isEmpty) {
      final hasLogsToday = myMedLogs.any((l) {
        String dbDate = l['log_date'].toString();
        if (dbDate.length >= 10) dbDate = dbDate.substring(0, 10);
        return dbDate == dateStr && l['status'] == 'taken';
      });

      if (hasLogsToday) {
        return _buildCelebratoryCard(isEnglish);
      }

      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.medication_liquid_outlined, size: 52, color: borderNeutral),
          const SizedBox(height: 10),
          Text(
            isEnglish ? "No medications scheduled for this date." : "Walang gamot na nakatakda para sa petsang ito.",
            style: GoogleFonts.inter(color: textMuted, fontWeight: FontWeight.w500, fontSize: 13),
          )
        ],
      );
    }

    final morningMeds = filteredMeds.where((m) => _getTimeBucket(m['time'].toString()) == 'morning').toList();
    final afternoonMeds = filteredMeds.where((m) => _getTimeBucket(m['time'].toString()) == 'afternoon').toList();
    final eveningMeds = filteredMeds.where((m) => _getTimeBucket(m['time'].toString()) == 'evening').toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 90),
      children: [
        if (morningMeds.isNotEmpty) ...[
          _buildTimeBucketHeader("🌅", isEnglish ? "Morning Schedule" : "Gamot sa Umaga", morningMeds.length),
          ...morningMeds.map((m) => _buildMedCard(m, isEnglish)),
          const SizedBox(height: 12),
        ],
        if (afternoonMeds.isNotEmpty) ...[
          _buildTimeBucketHeader("☀️", isEnglish ? "Afternoon Schedule" : "Gamot sa Hapon", afternoonMeds.length),
          ...afternoonMeds.map((m) => _buildMedCard(m, isEnglish)),
          const SizedBox(height: 12),
        ],
        if (eveningMeds.isNotEmpty) ...[
          _buildTimeBucketHeader("🌙", isEnglish ? "Evening Schedule" : "Gamot sa Gabi", eveningMeds.length),
          ...eveningMeds.map((m) => _buildMedCard(m, isEnglish)),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildTimeBucketHeader(String emoji, String title, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 15)),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: textCharcoal,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: primaryTeal.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              "$count due",
              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: primaryTeal),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMedCard(dynamic med, bool isEnglish) {
    final String medIdStr = med['id'].toString();
    final String medName = med['name'].toString();
    final bool isFading = _fadingMedIds[medIdStr] ?? false;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: isFading ? 0.0 : 1.0,
      curve: Curves.easeOut,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderNeutral),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCCFBF1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.medication_rounded, color: primaryTeal, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        med['name'],
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                          color: textCharcoal,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${med['dosage']} • Target: ${med['time']}',
                        style: GoogleFonts.inter(fontSize: 12, color: textMuted, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: textMuted, size: 19),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  onSelected: (value) {
                    if (value == 'edit') _showMedDialog(isEnglish, existingMed: med);
                    if (value == 'delete') _deleteMed(medIdStr, isEnglish);
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Text(isEnglish ? 'Edit' : 'I-edit', style: GoogleFonts.inter(fontSize: 13)),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        isEnglish ? 'Archive' : 'Burahin',
                        style: GoogleFonts.inter(color: const Color(0xFFDC2626), fontSize: 13),
                      ),
                    )
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            _SlideToTakeWidget(
              isEnglish: isEnglish,
              accentColor: primaryTeal,
              onConfirmed: () => _toggleMed(false, medIdStr, med['time'].toString(), medName, isEnglish),
            ),
          ],
        ),
      ),
    );
  }
}

// --- SLIDE TO CONFIRM INTAKE SLIDER WIDGET ---
class _SlideToTakeWidget extends StatefulWidget {
  final bool isEnglish;
  final Color accentColor;
  final VoidCallback onConfirmed;

  const _SlideToTakeWidget({
    required this.isEnglish,
    required this.accentColor,
    required this.onConfirmed,
  });

  @override
  State<_SlideToTakeWidget> createState() => _SlideToTakeWidgetState();
}

class _SlideToTakeWidgetState extends State<_SlideToTakeWidget> {
  double _dragPosition = 0.0;
  bool _isConfirmed = false;

  @override
  Widget build(BuildContext context) {
    const double barHeight = 44.0;
    const double thumbSize = 36.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxDrag = constraints.maxWidth - thumbSize - 8;

        return Container(
          height: barHeight,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              Center(
                child: Text(
                  _isConfirmed
                      ? (widget.isEnglish ? "Dose Recorded ✓" : "Naitabi Na ✓")
                      : (widget.isEnglish ? "Slide to log dose  ➔" : "I-slide upang inumin  ➔"),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _isConfirmed ? const Color(0xFF059669) : const Color(0xFF64748B),
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              Positioned(
                left: _dragPosition + 4,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    if (_isConfirmed) return;
                    setState(() {
                      _dragPosition = (_dragPosition + details.delta.dx).clamp(0.0, maxDrag);
                    });
                  },
                  onHorizontalDragEnd: (details) {
                    if (_isConfirmed) return;
                    if (_dragPosition >= maxDrag * 0.75) {
                      setState(() {
                        _dragPosition = maxDrag;
                        _isConfirmed = true;
                      });
                      widget.onConfirmed();
                    } else {
                      setState(() {
                        _dragPosition = 0.0;
                      });
                    }
                  },
                  child: Container(
                    width: thumbSize,
                    height: thumbSize,
                    decoration: BoxDecoration(
                      color: widget.accentColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: widget.accentColor.withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}