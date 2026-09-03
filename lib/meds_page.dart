import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart'; 
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

  final Color primaryGreen = const Color(0xFF2D3B1E); 
  final Color accentGreen = const Color(0xFF606C38);  
  final Color lightBg = const Color(0xFFF9F9F7);       
  final Color surfaceWhite = Colors.white;
  final Color emeraldGreen = const Color(0xFF059669); 

  @override
  void initState() {
    super.initState();
    _fetchData();
    _setupRealtimeListener();
  }

  void _showNotificationPopup(String message, String titleStr, {bool isSuccess = false}) {
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
                    titleStr,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Color(0xFF2D3B1E), 
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
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
                      child: const Text(
                        "Got it",
                        style: TextStyle(
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
    return daysPassed <= 60 ? (isEnglish ? "Intensive Phase" : "Intensive Phase") : (isEnglish ? "Continuation Phase" : "Continuation Phase");
  }

  void _handleAddNewMed(bool isEnglish) {
    _showMedDialog(isEnglish);
  }

  Future<void> _saveMed(bool isEnglish, {String? medId, required String name, required String dosage, required String time, required DateTime start, required DateTime end}) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final medData = {'user_id': user.id, 'name': name, 'dosage': dosage, 'time': time, 'start_date': start.toIso8601String(), 'end_date': end.toIso8601String(), 'is_taken': false};
    try {
      if (medId == null) { await Supabase.instance.client.from('medications').insert(medData); } 
      else { await Supabase.instance.client.from('medications').update(medData).eq('id', medId); }
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
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
                    color: accentGreen.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.health_and_safety_rounded, color: accentGreen, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEnglish ? "Daily Post-Intake Check-in" : "Pang-araw-araw na Check-in",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: primaryGreen,
                        ),
                      ),
                      Text(
                        isEnglish ? "Did you experience any of these after taking $medName?" : "Naramdaman mo ba ang alinman dito matapos inumin ang $medName?",
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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
                separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
                itemBuilder: (context, idx) {
                  final s = symptoms[idx];
                  final isNone = s['keywords'] == 'none';

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text(
                      s["label"]!,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isNone ? emeraldGreen : primaryGreen,
                      ),
                    ),
                    subtitle: Text(
                      s["desc"]!,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    ),
                    trailing: Icon(
                      isNone ? Icons.check_circle_outline_rounded : Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: isNone ? emeraldGreen : Colors.grey.shade400,
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
                                ? "Your reported symptom has been forwarded to your attending physician's clinical alert feed."
                                : "Ang iyong iniulat na sintomas ay naipadala na sa alert dashboard ng iyong doktor.",
                            isEnglish ? "Doctor Notified" : "Naabisuhan ang Doktor",
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
        
        if (diffMinutes < -60) timingStatus = 'early';
        else if (diffMinutes > 60) timingStatus = 'late';
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
          backgroundColor: surfaceWhite, 
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), 
          title: Text(
            existingMed == null ? (isEnglish ? "Add Medication" : "Magdagdag ng Gamot") : (isEnglish ? "Edit Details" : "I-edit ang Detalye"), 
            style: TextStyle(color: primaryGreen, fontWeight: FontWeight.w700)
          ), 
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min, 
              children: [
                TextField(
                  controller: nameController, 
                  decoration: InputDecoration(
                    labelText: isEnglish ? "Medicine Name" : "Pangalan ng Gamot", 
                    labelStyle: TextStyle(color: accentGreen), 
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: accentGreen))
                  )
                ), 
                TextField(
                  controller: dosageController, 
                  decoration: InputDecoration(
                    labelText: isEnglish ? "Dosage (e.g. 500mg)" : "Dosis (hal. 500mg)", 
                    labelStyle: TextStyle(color: accentGreen), 
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: accentGreen))
                  )
                ), 
                const SizedBox(height: 15), 
                _buildDialogTile(
                  icon: Icons.access_time_rounded, 
                  title: isEnglish ? "Reminder Time" : "Oras ng Paalala", 
                  value: selectedTime, 
                  onTap: () async { 
                    TimeOfDay? picked = await showTimePicker(context: context, initialTime: TimeOfDay.now()); 
                    if (picked != null) setDialogState(() => selectedTime = picked.format(context)); 
                  }
                ), 
                _buildDialogTile(
                  icon: Icons.calendar_today_rounded, 
                  title: isEnglish ? "Treatment Duration" : "Haba ng Gamutan", 
                  value: "${DateFormat('MMM d').format(startDate)} - ${DateFormat('MMM d').format(endDate)}", 
                  onTap: () async { 
                    DateTimeRange? picked = await showDateRangePicker(
                      context: context, 
                      firstDate: DateTime.now().subtract(const Duration(days: 30)), 
                      lastDate: DateTime.now().add(const Duration(days: 365))
                    ); 
                    if (picked != null) { 
                      setDialogState(() { 
                        startDate = picked.start; 
                        endDate = picked.end; 
                      }); 
                    } 
                  }
                ), 
              ],
            ),
          ), 
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: Text(isEnglish ? "Cancel" : "Kanselahin", style: TextStyle(color: Colors.grey[600]))
            ), 
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: accentGreen, 
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), 
                elevation: 0
              ), 
              onPressed: () { 
                _saveMed(
                  isEnglish,
                  medId: existingMed?['id']?.toString(), 
                  name: nameController.text, 
                  dosage: dosageController.text, 
                  time: selectedTime, 
                  start: startDate, 
                  end: endDate
                ); 
                Navigator.pop(context); 
              }, 
              child: Text(isEnglish ? "Save Task" : "I-save", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDialogTile({required IconData icon, required String title, required String value, required VoidCallback onTap}) {
    return ListTile(contentPadding: EdgeInsets.zero, leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: lightBg, borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: accentGreen, size: 20)), title: Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)), subtitle: Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: primaryGreen)), onTap: onTap);
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
          backgroundColor: lightBg,
          appBar: AppBar(
            backgroundColor: Colors.transparent, 
            elevation: 0, 
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, color: primaryGreen), 
              onPressed: () => Navigator.of(context).pop()
            ), 
            title: Text('', style: TextStyle(fontWeight: FontWeight.w800, color: primaryGreen, fontSize: 20)),
            actions: [
              if (isUnlocked)
                IconButton(
                  icon: Icon(_showHistoryLog ? Icons.assignment_rounded : Icons.history_toggle_off_rounded, color: primaryGreen),
                  tooltip: isEnglish ? "View Logs History" : "Tingnan ang Kasaysayan",
                  onPressed: () => setState(() => _showHistoryLog = !_showHistoryLog),
                )
            ],
          ),
          
          body: _isLoading 
            ? Center(child: CircularProgressIndicator(color: accentGreen)) 
            : isUnlocked 
                ? _showHistoryLog ? _buildHistoryLogsContent(isEnglish) : _buildUnlockedContent(isEnglish) 
                : _buildLockedUI(hasTakenAssessment, isVerifiedByDoctor, isEnglish),

          floatingActionButton: (isUnlocked && !_showHistoryLog && !isCured)
            ? FloatingActionButton(backgroundColor: primaryGreen, onPressed: () => _handleAddNewMed(isEnglish), child: const Icon(Icons.add, color: Colors.white))
            : null,
        );
      }
    );
  }

  Widget _buildUnlockedContent(bool isEnglish) {
    return Column(
      children: [
        _buildModernHeader(isEnglish), 
        if (_latestDoctorNote != null) _buildDoctorAdviceCard(isEnglish),
        const SizedBox(height: 15), 
        _buildViewSelector(isEnglish), 
        const SizedBox(height: 15), 
        _buildCalendarSection(isEnglish), 
        const SizedBox(height: 20), 
        Expanded(
          child: Container(
            width: double.infinity, 
            decoration: BoxDecoration(color: surfaceWhite, borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]), 
            child: _buildMedList(isEnglish)
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryLogsContent(bool isEnglish) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(isEnglish ? "Medication Compliance Logs" : "Kasaysayan ng Pag-inom ng Gamot", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryGreen)),
              TextButton.icon(
                onPressed: () => setState(() => _showHistoryLog = false),
                icon: Icon(Icons.arrow_back, size: 16, color: accentGreen),
                label: Text(isEnglish ? "Back Diary" : "Bumalik", style: TextStyle(color: accentGreen, fontWeight: FontWeight.bold)),
              )
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: myMedLogs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history_edu_rounded, size: 50, color: Colors.grey[300]),
                        const SizedBox(height: 10),
                        Text(isEnglish ? "No recorded logs history yet." : "Wala pang naitalang kasaysayan.", style: TextStyle(color: Colors.grey[500])),
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

                      return Card(
                        color: surfaceWhite,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.withOpacity(0.1))),
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: log['status'] == 'taken' ? accentGreen.withOpacity(0.1) : Colors.redAccent.withOpacity(0.1),
                            child: Icon(
                              log['status'] == 'taken' ? Icons.check_circle_rounded : Icons.cancel_rounded, 
                              color: log['status'] == 'taken' ? accentGreen : Colors.redAccent, 
                              size: 22
                            ),
                          ),
                          title: Text(medName, style: TextStyle(fontWeight: FontWeight.bold, color: primaryGreen)),
                          subtitle: Text(
                            log['status'] == 'taken'
                              ? (isEnglish ? "$dosage • Taken at ${log['time_taken']} \n$formattedLogDay" : "$dosage • Ininom noong ${log['time_taken']} \n$formattedLogDay")
                              : (isEnglish ? "$dosage • Missed Dose \n$formattedLogDay" : "$dosage • Nakaligtaang Inumin \n$formattedLogDay"), 
                            style: TextStyle(fontSize: 12, color: Colors.grey[600])
                          ),
                          isThreeLine: true,
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: log['status'] != 'taken' 
                                  ? Colors.red[50] 
                                  : (timingStatus == 'early' ? Colors.blue[50] : (timingStatus == 'late' ? Colors.orange[50] : Colors.green[50])),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              log['status'] != 'taken' ? "MISSED" : timingStatus.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: log['status'] != 'taken' 
                                    ? Colors.red[700] 
                                    : (timingStatus == 'early' ? Colors.blue[700] : (timingStatus == 'late' ? Colors.orange[700] : Colors.green[700]))
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
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.fromLTRB(20, 15, 20, 0),
      decoration: BoxDecoration(
        color: accentGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentGreen.withOpacity(0.2))
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: Icon(Icons.tips_and_updates_rounded, color: accentGreen, size: 22),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isEnglish ? "Doctor's Recent Advice" : "Payo ng Doktor", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: accentGreen, letterSpacing: 0.5)),
                const SizedBox(height: 4),
                Text(
                  _latestDoctorNote!['note_text'], 
                  style: TextStyle(fontSize: 13, color: primaryGreen, fontWeight: FontWeight.w500, height: 1.3),
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
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 45,
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.12),
          borderRadius: BorderRadius.circular(25),
        ),
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
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: isSelected 
                        ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))]
                        : [],
                  ),
                  child: Center(
                    child: Text(
                      displayType,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        color: isSelected ? primaryGreen : Colors.grey[500],
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
              decoration: BoxDecoration(color: accentGreen.withOpacity(0.1), shape: BoxShape.circle), 
              child: Icon(icon, size: 50, color: primaryGreen)
            ),
            const SizedBox(height: 30),
            Text(title, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: primaryGreen)),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 14)),
            
            if (hasAssessed && !isVerified) ...[
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFDDE5B6), width: 2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(isEnglish ? "YOUR PATIENT ID" : "ANG IYONG PATIENT ID", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade500, letterSpacing: 1.5)),
                    const SizedBox(height: 4),
                    SelectableText(
                      _userId.length >= 8 ? _userId.substring(0, 8).toUpperCase() : _userId, 
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: primaryGreen, letterSpacing: 2)
                    ),
                  ]
                )
              )
            ],

            const SizedBox(height: 40),
            ElevatedButton(
                onPressed: () => Navigator.pushReplacementNamed(context, hasAssessed ? '/dashboard' : '/assess'), 
                style: ElevatedButton.styleFrom(backgroundColor: primaryGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15)), 
                child: Text(hasAssessed ? (isEnglish ? "Go to Dashboard" : "Pumunta sa Dashboard") : (isEnglish ? "Take Assessment" : "Magsimula ng Pagsusuri"), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernHeader(bool isEnglish) { 
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20), 
      padding: const EdgeInsets.all(20), 
      width: double.infinity, 
      decoration: BoxDecoration(gradient: LinearGradient(colors: [primaryGreen, accentGreen], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(24)), 
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, 
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(isEnglish ? 'Medication Diary' : 'Talaan ng Gamot', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                child: Text(
                  _getCurrentPhase(isEnglish), 
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)
                ),
              ),
            ],
          ), 
          const SizedBox(height: 4), 
          Text(isEnglish ? 'Keep track of your TB treatment journey.' : 'Subaybayan ang iyong paggamot sa TB.', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)), 
          const SizedBox(height: 15), 
          Row(
            children: [
              const Icon(Icons.calendar_today, color: Colors.white, size: 14), 
              const SizedBox(width: 8), 
              Text(DateFormat('MMMM dd, yyyy').format(_selectedDate), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))
            ],
          )
        ],
      ),
    ); 
  }

  Widget _buildCalendarSection(bool isEnglish) { 
    if (_viewType == 'Month') return SizedBox(height: 350, child: _buildMonthGrid()); 
    if (_viewType == 'Day') return Center(child: SizedBox(height: 90, child: _buildDateCard(_selectedDate, true))); 
    return SizedBox(height: 90, child: _buildWeekStrip()); 
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
      }
    ); 
  }

  Widget _buildMonthGrid() { 
    int daysInMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 0).day; 
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20), 
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7, 
        mainAxisSpacing: 8, 
        crossAxisSpacing: 8,
        childAspectRatio: 0.75, 
      ), 
      itemCount: daysInMonth, 
      itemBuilder: (context, index) { 
        DateTime date = DateTime(_selectedDate.year, _selectedDate.month, index + 1); 
        bool isSelected = date.day == _selectedDate.day && date.month == _selectedDate.month; 
        return _buildDateCard(date, isSelected, compact: true); 
      }
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
        duration: const Duration(milliseconds: 200), 
        width: compact ? null : 65, 
        margin: EdgeInsets.symmetric(horizontal: compact ? 2 : 6, vertical: compact ? 2 : 4), 
        decoration: BoxDecoration(
          color: isSelected ? accentGreen : surfaceWhite, 
          borderRadius: BorderRadius.circular(16), 
          boxShadow: isSelected ? [BoxShadow(color: accentGreen.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : [], 
          border: Border.all(color: isSelected ? accentGreen : (isCompletedDay ? emeraldGreen.withOpacity(0.5) : Colors.grey.withOpacity(0.1))),
        ), 
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center, 
              children: [
                Text(
                  DateFormat('E').format(date).toUpperCase(), 
                  style: TextStyle(fontSize: compact ? 8 : 10, fontWeight: FontWeight.w800, color: isSelected ? Colors.white70 : Colors.grey)
                ), 
                const SizedBox(height: 2), 
                Text(
                  date.day.toString(), 
                  style: TextStyle(fontSize: compact ? 14 : 18, fontWeight: FontWeight.w700, color: isSelected ? Colors.white : primaryGreen)
                )
              ],
            ),
            if (isCompletedDay)
              Positioned(
                bottom: compact ? 2 : 4,
                right: compact ? 2 : 6,
                child: Icon(
                  Icons.check_circle_rounded, 
                  color: isSelected ? Colors.white : emeraldGreen, 
                  size: compact ? 10 : 14
                ),
              )
          ],
        ),
      ),
    ); 
  }

  // --- ITEM 5: POST-CARE SURVEILLANCE TROPHY CARD ---
  Widget _buildDischargedSurveillanceCard(bool isEnglish) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: emeraldGreen.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: emeraldGreen.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 6),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: const Text("🏆", style: TextStyle(fontSize: 40)),
              ),
              const SizedBox(height: 16),
              Text(
                isEnglish ? "Treatment Successfully Completed!" : "Tagumpay na Nakumpleto ang Gamutan!",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: primaryGreen),
              ),
              const SizedBox(height: 8),
              Text(
                isEnglish 
                  ? "You have completed your mandated TB medication protocol. Active pill intake has concluded."
                  : "Natapos mo na ang itinakdang gamutan sa TB. Hindi mo na kailangang uminom ng gamot araw-araw.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.4),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: lightBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.shield_outlined, color: emeraldGreen, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          isEnglish ? "Post-Care Surveillance Active" : "Aktibong Pagsubaybay",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: primaryGreen),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isEnglish 
                        ? "Please keep this app installed to receive automatic reminders for your scheduled 6-Month and 1-Year follow-up clearances at the Carmona TB DOTS Center."
                        : "Panatilihing naka-install ang app na ito upang makatanggap ng paalala para sa iyong 6-Month at 1-Year surveillance checkup sa Carmona TB DOTS Center.",
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.3),
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

  // --- ITEM 4: CELEBRATORY "ALL DONE FOR TODAY" CARD ---
  Widget _buildCelebratoryCard(bool isEnglish) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: emeraldGreen.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.verified_rounded, size: 56, color: emeraldGreen),
            ),
            const SizedBox(height: 20),
            Text(
              isEnglish ? "All Done for Today! 🎉" : "Tapos na para sa Araw na Ito! 🎉",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: primaryGreen),
            ),
            const SizedBox(height: 8),
            Text(
              isEnglish 
                ? "You have taken all scheduled medications for this day. Drink plenty of water and rest well."
                : "Nainom mo na ang lahat ng gamot na nakatakda para sa araw na ito. Uminom ng tubig at magpahinga.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedList(bool isEnglish) { 
    final bool isCured = _patientStatus == 'cured' || _patientStatus == 'treatment_completed';

    // Show Post-Care Surveillance Card if Cured
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

    // If all medications for today are taken, show Celebration Card
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
          Icon(Icons.spa_outlined, size: 60, color: Colors.grey[300]), 
          const SizedBox(height: 10), 
          Text(isEnglish ? "No medications scheduled for this date." : "Walang gamot na nakatakda para sa petsang ito.", style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.w500))
        ],
      ); 
    }

    // --- ITEM 2: GROUPING BY TIME OF DAY (MORNING, AFTERNOON, EVENING) ---
    final morningMeds = filteredMeds.where((m) => _getTimeBucket(m['time'].toString()) == 'morning').toList();
    final afternoonMeds = filteredMeds.where((m) => _getTimeBucket(m['time'].toString()) == 'afternoon').toList();
    final eveningMeds = filteredMeds.where((m) => _getTimeBucket(m['time'].toString()) == 'evening').toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
      children: [
        if (morningMeds.isNotEmpty) ...[
          _buildTimeBucketHeader("🌅", isEnglish ? "Morning Intake" : "Gamot sa Umaga", morningMeds.length),
          ...morningMeds.map((m) => _buildMedCard(m, isEnglish)),
          const SizedBox(height: 12),
        ],
        if (afternoonMeds.isNotEmpty) ...[
          _buildTimeBucketHeader("☀️", isEnglish ? "Afternoon Intake" : "Gamot sa Hapon", afternoonMeds.length),
          ...afternoonMeds.map((m) => _buildMedCard(m, isEnglish)),
          const SizedBox(height: 12),
        ],
        if (eveningMeds.isNotEmpty) ...[
          _buildTimeBucketHeader("🌙", isEnglish ? "Evening Intake" : "Gamot sa Gabi", eveningMeds.length),
          ...eveningMeds.map((m) => _buildMedCard(m, isEnglish)),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildTimeBucketHeader(String emoji, String title, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: primaryGreen,
              letterSpacing: 0.3,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: accentGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              "$count due",
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: accentGreen),
            ),
          )
        ],
      ),
    );
  }

  // --- ITEM 1: SLIDE TO CONFIRM INTAKE CARD ---
  Widget _buildMedCard(dynamic med, bool isEnglish) {
    final String medIdStr = med['id'].toString();
    final String medName = med['name'].toString();
    final bool isFading = _fadingMedIds[medIdStr] ?? false;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: isFading ? 0.0 : 1.0,
      curve: Curves.easeOut,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surfaceWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.withOpacity(0.12)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 3),
            )
          ]
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accentGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.medication_rounded, color: accentGreen, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        med['name'],
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: primaryGreen,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${med['dosage']} • Target: ${med['time']}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.grey, size: 20),
                  onSelected: (value) {
                    if (value == 'edit') _showMedDialog(isEnglish, existingMed: med);
                    if (value == 'delete') _deleteMed(medIdStr, isEnglish);
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(value: 'edit', child: Text(isEnglish ? 'Edit' : 'I-edit')),
                    PopupMenuItem(value: 'delete', child: Text(isEnglish ? 'Delete' : 'Burahin', style: const TextStyle(color: Colors.red)))
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Slide-To-Take Component
            _SlideToTakeWidget(
              isEnglish: isEnglish,
              accentColor: accentGreen,
              onConfirmed: () => _toggleMed(false, medIdStr, med['time'].toString(), medName, isEnglish),
            ),
          ],
        ),
      ),
    );
  }
}

// --- SLIDE TO CONFIRM INTAKE SLIDER WIDGET (0 Dependencies) ---
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
            color: const Color(0xFFF4F7F4),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              Center(
                child: Text(
                  _isConfirmed 
                    ? (widget.isEnglish ? "Intake Confirmed" : "Nainom Na")
                    : (widget.isEnglish ? "Slide to take  ➔" : "I-slide upang inumin  ➔"),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade600,
                    letterSpacing: 0.5,
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
                    if (_dragPosition >= maxDrag * 0.8) {
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
                          color: widget.accentColor.withOpacity(0.35),
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