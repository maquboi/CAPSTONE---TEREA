import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart'; // Needed for DateFormat

// --- 6. MEDS PAGE (STRICT UI LOCK APPLIED) ---
class MedsPage extends StatefulWidget {
  const MedsPage({super.key});

  @override
  State<MedsPage> createState() => _MedsPageState();
}

class _MedsPageState extends State<MedsPage> {
  List<dynamic> myMeds = [];
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();
  String _viewType = 'Week';

  DateTime? _treatmentStartDate;
  String? _connectionStatus;
  String _riskLevel = "Not yet assessed";
  
  // New variable for Option 4
  Map<String, dynamic>? _latestDoctorNote;

  final Color primaryGreen = const Color(0xFF2D3B1E); 
  final Color accentGreen = const Color(0xFF606C38);  
  final Color lightBg = const Color(0xFFF9F9F7);      
  final Color surfaceWhite = Colors.white;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _setupRealtimeListener();
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
        // Listener for Option 4: Doctor Notes
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
          .select('treatment_start_date, risk_level')
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
          .eq('user_id', user.id);

      // Option 4 Fetch: Get the latest note from the doctor
      final noteData = await Supabase.instance.client
          .from('doctor_notes')
          .select('note_text, created_at')
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (mounted) {
        setState(() {
          _connectionStatus = connectionData?['status'];
          _riskLevel = profileData?['risk_level'] ?? "Not yet assessed";
          _latestDoctorNote = noteData;
          
          if (profileData != null && profileData['treatment_start_date'] != null) {
            _treatmentStartDate = DateTime.parse(profileData['treatment_start_date'].toString());
          }
          
          myMeds = medsData as List<dynamic>;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching data: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Determination of Treatment Phase (Option 5)
  String _getCurrentPhase() {
    if (_treatmentStartDate == null) return "Phase Not Set";
    final daysPassed = DateTime.now().difference(_treatmentStartDate!).inDays;
    // TB Intensive Phase is usually the first 2 months (60 days)
    return daysPassed <= 60 ? "Intensive Phase" : "Continuation Phase";
  }

  void _handleAddNewMed() {
    _showMedDialog();
  }

  Future<void> _saveMed({String? medId, required String name, required String dosage, required String time, required DateTime start, required DateTime end}) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final medData = {'user_id': user.id, 'name': name, 'dosage': dosage, 'time': time, 'start_date': start.toIso8601String(), 'end_date': end.toIso8601String(), 'is_taken': false};
    try {
      if (medId == null) { await Supabase.instance.client.from('medications').insert(medData); } 
      else { await Supabase.instance.client.from('medications').update(medData).eq('id', medId); }
      _fetchData();
    } catch (e) { debugPrint("Error saving med: $e"); }
  }

  Future<void> _deleteMed(String medId) async {
    try { await Supabase.instance.client.from('medications').delete().eq('id', medId); _fetchData(); } 
    catch (e) { debugPrint("Error deleting med: $e"); }
  }

  Future<void> _toggleMed(bool currentValue, String medId) async {
    try { await Supabase.instance.client.from('medications').update({'is_taken': !currentValue}).eq('id', medId); _fetchData(); } 
    catch (e) { debugPrint("Error toggling med: $e"); }
  }

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
          backgroundColor: surfaceWhite, 
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), 
          title: Text(
            existingMed == null ? "Add Medication" : "Edit Details", 
            style: TextStyle(color: primaryGreen, fontWeight: FontWeight.w700)
          ), 
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min, 
              children: [
                TextField(
                  controller: nameController, 
                  decoration: InputDecoration(
                    labelText: "Medicine Name", 
                    labelStyle: TextStyle(color: accentGreen), 
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: accentGreen))
                  )
                ), 
                TextField(
                  controller: dosageController, 
                  decoration: InputDecoration(
                    labelText: "Dosage (e.g. 500mg)", 
                    labelStyle: TextStyle(color: accentGreen), 
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: accentGreen))
                  )
                ), 
                const SizedBox(height: 15), 
                _buildDialogTile(
                  icon: Icons.access_time_rounded, 
                  title: "Reminder Time", 
                  value: selectedTime, 
                  onTap: () async { 
                    TimeOfDay? picked = await showTimePicker(context: context, initialTime: TimeOfDay.now()); 
                    if (picked != null) setDialogState(() => selectedTime = picked.format(context)); 
                  }
                ), 
                _buildDialogTile(
                  icon: Icons.calendar_today_rounded, 
                  title: "Treatment Duration", 
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
              ]
            )
          ), 
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: Text("Cancel", style: TextStyle(color: Colors.grey[600]))
            ), 
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: accentGreen, 
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), 
                elevation: 0
              ), 
              onPressed: () { 
                _saveMed(
                  medId: existingMed?['id']?.toString(), 
                  name: nameController.text, 
                  dosage: dosageController.text, 
                  time: selectedTime, 
                  start: startDate, 
                  end: endDate
                ); 
                Navigator.pop(context); 
              }, 
              child: const Text("Save Task", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600))
            )
          ]
        )
      )
    );
  }

  Widget _buildDialogTile({required IconData icon, required String title, required String value, required VoidCallback onTap}) {
    return ListTile(contentPadding: EdgeInsets.zero, leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: lightBg, borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: accentGreen, size: 20)), title: Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)), subtitle: Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: primaryGreen)), onTap: onTap);
  }

  @override
  Widget build(BuildContext context) {
    bool hasTakenAssessment = _riskLevel != "Not yet assessed";
    bool isVerifiedByDoctor = _connectionStatus == 'active';
    bool isUnlocked = hasTakenAssessment && isVerifiedByDoctor;

    return Scaffold(
      backgroundColor: lightBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent, 
        elevation: 0, 
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: primaryGreen), 
          onPressed: () => Navigator.of(context).pop()
        ), 
        title: Row(
          children: [
            Icon(Icons.favorite_rounded, color: accentGreen, size: 28), 
            const SizedBox(width: 10), 
            Text('TB HealthCare', style: TextStyle(fontWeight: FontWeight.w800, color: primaryGreen, fontSize: 20))
          ]
        ),
      ),
      
      body: _isLoading 
        ? Center(child: CircularProgressIndicator(color: accentGreen)) 
        : isUnlocked 
            ? _buildUnlockedContent() 
            : _buildLockedUI(hasTakenAssessment, isVerifiedByDoctor),

      floatingActionButton: isUnlocked 
        ? FloatingActionButton(backgroundColor: primaryGreen, onPressed: _handleAddNewMed, child: const Icon(Icons.add, color: Colors.white))
        : null,
    );
  }

  Widget _buildUnlockedContent() {
    return Column(
      children: [
        _buildModernHeader(), 
        // Option 4: Latest Doctor's Advice Card
        if (_latestDoctorNote != null) _buildDoctorAdviceCard(),
        const SizedBox(height: 15), 
        _buildViewSelector(), 
        const SizedBox(height: 15), 
        _buildCalendarSection(), 
        const SizedBox(height: 20), 
        Expanded(
          child: Container(
            width: double.infinity, 
            decoration: BoxDecoration(color: surfaceWhite, borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]), 
            child: _buildMedList()
          )
        )
      ]
    );
  }

  // --- OPTION 4 UI COMPONENT ---
  Widget _buildDoctorAdviceCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 15, 20, 0),
      padding: const EdgeInsets.all(16),
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
                Text("Doctor's Recent Advice", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: accentGreen, letterSpacing: 0.5)),
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

  Widget _buildViewSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 45,
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.12),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          children: ['Day', 'Week', 'Month'].map((type) {
            bool isSelected = _viewType == type;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _viewType = type),
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
                      type,
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
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildLockedUI(bool hasAssessed, bool isVerified) {
    String title = "Diary Locked";
    String message = "To ensure your safety, the Medication Diary is locked until you complete your assessment and link with your doctor.";
    IconData icon = Icons.lock_outline_rounded;

    if (!hasAssessed) {
      title = "Assessment Required";
      message = "Please complete the Risk Assessment first to unlock your health features.";
      icon = Icons.assignment_late_outlined;
    } else if (!isVerified) {
      title = "Verification Pending";
      message = "Assessment complete! Now, please link your account to your clinic via the Dashboard and wait for doctor approval.";
      icon = Icons.hourglass_empty_rounded;
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
            const SizedBox(height: 40),
            ElevatedButton(
                onPressed: () => Navigator.pushReplacementNamed(context, hasAssessed ? '/dashboard' : '/assess'), 
                style: ElevatedButton.styleFrom(backgroundColor: primaryGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15)), 
                child: Text(hasAssessed ? "Go to Dashboard" : "Take Assessment", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernHeader() { 
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
              const Text('Medication Diary', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
              // Option 5: Treatment Phase Indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                child: Text(
                  _getCurrentPhase(), 
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)
                ),
              ),
            ],
          ), 
          const SizedBox(height: 4), 
          Text('Keep track of your TB treatment journey.', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)), 
          const SizedBox(height: 15), 
          Row(
            children: [
              const Icon(Icons.calendar_today, color: Colors.white, size: 14), 
              const SizedBox(width: 8), 
              Text(DateFormat('MMMM dd, yyyy').format(_selectedDate), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))
            ]
          )
        ]
      )
    ); 
  }

  Widget _buildCalendarSection() { 
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
          border: Border.all(color: isSelected ? accentGreen : Colors.grey.withOpacity(0.1))
        ), 
        child: Column(
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
          ]
        )
      )
    ); 
  }

  Widget _buildMedList() { 
    final filteredMeds = myMeds.where((med) { 
      DateTime start = DateTime.parse(med['start_date']); 
      DateTime end = DateTime.parse(med['end_date']); 
      DateTime startDate = DateTime(start.year, start.month, start.day); 
      DateTime endDate = DateTime(end.year, end.month, end.day); 
      DateTime selectedDate = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day); 
      return !selectedDate.isBefore(startDate) && !selectedDate.isAfter(endDate); 
    }).toList(); 

    if (filteredMeds.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center, 
        children: [
          Icon(Icons.spa_outlined, size: 60, color: Colors.grey[300]), 
          const SizedBox(height: 10), 
          Text("Rest easy. No meds today.", style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.w500))
        ]
      ); 
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 100), 
      itemCount: filteredMeds.length, 
      itemBuilder: (context, index) { 
        final med = filteredMeds[index]; 
        bool isTaken = med['is_taken'] ?? false; 
        return Container(
          margin: const EdgeInsets.only(bottom: 16), 
          padding: const EdgeInsets.all(12), 
          decoration: BoxDecoration(
            color: isTaken ? lightBg.withOpacity(0.5) : surfaceWhite, 
            borderRadius: BorderRadius.circular(20), 
            border: Border.all(color: isTaken ? Colors.transparent : Colors.grey.withOpacity(0.1))
          ), 
          child: Row(
            children: [
              GestureDetector(
                onTap: () => _toggleMed(isTaken, med['id'].toString()), 
                child: Container(
                  padding: const EdgeInsets.all(10), 
                  decoration: BoxDecoration(color: isTaken ? accentGreen : lightBg, shape: BoxShape.circle), 
                  child: Icon(isTaken ? Icons.check : Icons.medication_rounded, color: isTaken ? Colors.white : accentGreen, size: 24)
                )
              ), 
              const SizedBox(width: 15), 
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, 
                  children: [
                    Text(med['name'], style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, decoration: isTaken ? TextDecoration.lineThrough : null, color: isTaken ? Colors.grey : primaryGreen)), 
                    Text('${med['dosage']} • ${med['time']}', style: TextStyle(fontSize: 13, color: isTaken ? Colors.grey[400] : Colors.grey[600]))
                  ]
                )
              ), 
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.grey), 
                onSelected: (value) { 
                  if (value == 'edit') _showMedDialog(existingMed: med); 
                  if (value == 'delete') _deleteMed(med['id'].toString()); 
                }, 
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')), 
                  const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red)))
                ]
              )
            ]
          )
        ); 
      }
    ); 
  }
}