import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart'; // Needed for DateFormat

//FOLLOWUP PAGE
class FollowUpPage extends StatefulWidget {
  const FollowUpPage({super.key});

  @override
  State<FollowUpPage> createState() => _FollowUpPageState();
}

class _FollowUpPageState extends State<FollowUpPage> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;

  // CONNECTION STATE
  String? _connectionStatus;
  String? _linkedDoctorId;
  String? _doctorName;
  DateTime? _treatmentStartDate; 

  // DATA
  int _streakDays = 0;
  List<Map<String, dynamic>> _doctorNotes = [];
  List<Map<String, dynamic>> _appointments = [];
  
  // CRUD INPUTS
  final TextEditingController _noteController = TextEditingController();
  String _selectedCategory = 'Question'; 
  final List<String> _categories = ['Question', 'Symptom', 'Side Effect', 'Other'];

  // THEME PALETTE
  final Color kPrimaryGreen = const Color(0xFF283618);
  final Color kSecondaryGreen = const Color(0xFF606C38);
  final Color kCreamAccent = const Color(0xFFFEFAE0);
  final Color kWhite = Colors.white;
  final Color kSoftGrey = const Color(0xFFF8F9FA);

  @override
  void initState() {
    super.initState();
    _checkConnectionAndLoad();
    _setupRealtimeListener();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  // --- REAL-TIME LISTENER ---
  void _setupRealtimeListener() {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    _supabase
      .channel('followup_sync')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'profiles',
        filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'id', value: user.id),
        callback: (payload) => _checkConnectionAndLoad(),
      )
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'connections',
        filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'patient_id', value: user.id),
        callback: (payload) => _checkConnectionAndLoad(),
      )
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'roadmap',
        filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'patient_id', value: user.id),
        callback: (payload) => _fetchAppointments(), 
      )
      .subscribe();
  }

  // --- INIT DATA ---
  Future<void> _checkConnectionAndLoad() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // 1. Check connection status (Handshake)
      final connectionData = await _supabase
          .from('connections')
          .select('status, doctor_id, profiles!fk_doctor(full_name)')
          .eq('patient_id', user.id)
          .maybeSingle();

      // 2. Check treatment dates (Prescription)
      final profileData = await _supabase
          .from('profiles')
          .select('treatment_start_date') 
          .eq('id', user.id)
          .maybeSingle(); 

      if (mounted) {
        setState(() {
          _connectionStatus = connectionData?['status'];

          if (connectionData != null) {
            _linkedDoctorId = connectionData['doctor_id'];
            final doctorProfile = connectionData['profiles'] as Map<String, dynamic>?;
            _doctorName = doctorProfile?['full_name'];
          } else {
            _linkedDoctorId = null;
            _doctorName = null;
          }

          if (profileData != null && profileData['treatment_start_date'] != null) {
             _treatmentStartDate = DateTime.tryParse(profileData['treatment_start_date'].toString());
          } else {
             _treatmentStartDate = null;
          }
        });
      }

      // 3. Load content if unlocked (now only requires active connection)
      if (_connectionStatus == 'active') {
        await Future.wait([
          _fetchStreak(),
          _fetchNotes(), 
          _fetchAppointments(),
        ]);
      }
    } catch (e) {
      debugPrint('Init Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- DATA FETCHING ---
  Future<void> _fetchStreak() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      final response = await _supabase.rpc('get_medication_streak', params: {'p_user_id': userId});
      if (mounted) setState(() => _streakDays = response as int);
    } catch (e) { debugPrint('Streak Error: $e'); }
  }

  Future<void> _fetchNotes() async {
    try {
      final data = await _supabase.from('doctor_notes')
          .select()
          .eq('user_id', _supabase.auth.currentUser!.id)
          .eq('is_checked', false) 
          .order('created_at', ascending: false);
      if (mounted) setState(() => _doctorNotes = List<Map<String, dynamic>>.from(data));
    } catch (e) { debugPrint('Notes Error: $e'); }
  }

  Future<void> _fetchAppointments() async {
    try {
      final data = await _supabase.from('roadmap')
          .select()
          .eq('patient_id', _supabase.auth.currentUser!.id)
          .neq('status', 'completed') 
          .order('appointment_date', ascending: true);
      if (mounted) setState(() => _appointments = List<Map<String, dynamic>>.from(data));
    } catch (e) { debugPrint('Appt Error: $e'); }
  }

  // --- CRUD OPERATIONS ---
  Future<void> _addNote() async {
    if (_noteController.text.isEmpty) return;
    final text = _noteController.text;
    final category = _selectedCategory;
    _noteController.clear();
    setState(() => _selectedCategory = 'Question');
    try {
      await _supabase.from('doctor_notes').insert({'note_text': text, 'category': category, 'user_id': _supabase.auth.currentUser!.id, 'is_checked': false});
      _fetchNotes();
    } catch (e) { debugPrint('Add Note Error: $e'); }
  }

  Future<void> _deleteNote(String id) async { 
    await _supabase.from('doctor_notes').delete().eq('id', id); 
    _fetchNotes(); 
  }

  Future<void> _toggleNote(int index) async {
    setState(() { _doctorNotes[index]['is_checked'] = true; });
    await Future.delayed(const Duration(milliseconds: 500));
    final noteId = _doctorNotes[index]['id'];
    await _supabase.from('doctor_notes').update({'is_checked': true}).eq('id', noteId);
    if (mounted) { setState(() { _doctorNotes.removeAt(index); }); }
  }

  Future<void> _deleteAppointment(String id) async { 
    await _supabase.from('roadmap').delete().eq('id', id);
    _fetchAppointments(); 
  }

  Future<void> _editNoteDialog(Map<String, dynamic> note) async {
    final editController = TextEditingController(text: note['note_text']);
    String editCategory = note['category'] ?? 'Question';
    
    await showDialog(
      context: context, 
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), 
          title: Text("Edit Note", style: TextStyle(color: kPrimaryGreen, fontWeight: FontWeight.bold)), 
          content: Column(
            mainAxisSize: MainAxisSize.min, 
            children: [
              Wrap(
                spacing: 8, 
                children: _categories.map((cat) { 
                  final isSelected = editCategory == cat; 
                  return ChoiceChip(
                    label: Text(cat), 
                    selected: isSelected, 
                    selectedColor: kSecondaryGreen, 
                    labelStyle: TextStyle(color: isSelected ? Colors.white : kPrimaryGreen, fontSize: 12), 
                    onSelected: (val) => setDialogState(() => editCategory = cat)
                  ); 
                }).toList()
              ), 
              const SizedBox(height: 15), 
              TextField(
                controller: editController, 
                maxLines: 3, 
                decoration: InputDecoration(
                  hintText: "Update your note...", 
                  filled: true, 
                  fillColor: kSoftGrey, 
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
                )
              )
            ]
          ), 
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.grey))), 
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: kPrimaryGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), 
              onPressed: () async { 
                if (editController.text.isNotEmpty) { 
                  await _supabase.from('doctor_notes').update({'note_text': editController.text, 'category': editCategory}).eq('id', note['id']); 
                  _fetchNotes(); 
                  if (context.mounted) Navigator.pop(context); 
                } 
              }, 
              child: const Text("Save Changes", style: TextStyle(color: Colors.white))
            )
          ]
        )
      )
    );
  }

  void _showAppointmentModal({Map<String, dynamic>? apptToEdit}) { 
    final isEditing = apptToEdit != null;
    
    // Changed to handle the actual title of the milestone
    final titleController = TextEditingController(text: isEditing ? (apptToEdit['title'] ?? "") : "Follow-up Checkup");
    final locController = TextEditingController(text: isEditing ? (apptToEdit['location'] ?? "") : "");
    
    DateTime? selectedDate = isEditing ? DateTime.tryParse(apptToEdit['appointment_date']) : null;
    TimeOfDay? selectedTime;
    
    if (isEditing && apptToEdit['appointment_time'] != null) { 
      final parts = apptToEdit['appointment_time'].toString().split(':'); 
      selectedTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1])); 
    } else {
      selectedTime = const TimeOfDay(hour: 8, minute: 0);
    }
    
    bool isSaving = false;
    
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: kWhite, 
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(35))), 
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 25, right: 25, top: 20), 
          child: Column(
            mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, 
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))), 
              const SizedBox(height: 25), 
              Text(isEditing ? "Edit Milestone" : "Add Roadmap Milestone", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: kPrimaryGreen)), 
              const SizedBox(height: 20), 
              _buildModernField(titleController, "Milestone Title", Icons.event_note_outlined), 
              const SizedBox(height: 15), 
              _buildModernField(locController, "Location / Goal", Icons.flag_outlined), 
              const SizedBox(height: 20), 
              Row(children: [
                Expanded(child: _buildPickerTile(
                  label: selectedDate == null ? "Select Date" : DateFormat('MMM dd, yyyy').format(selectedDate!), 
                  icon: Icons.calendar_month_rounded, 
                  onTap: () async { 
                    final picked = await showDatePicker(context: context, initialDate: selectedDate ?? DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2030)); 
                    if (picked != null) setModalState(() => selectedDate = picked); 
                  }
                )), 
                const SizedBox(width: 15), 
                Expanded(child: _buildPickerTile(
                  label: selectedTime == null ? "Select Time" : selectedTime!.format(context), 
                  icon: Icons.access_time_rounded, 
                  onTap: () async { 
                    final picked = await showTimePicker(context: context, initialTime: selectedTime ?? TimeOfDay.now()); 
                    if (picked != null) setModalState(() => selectedTime = picked); 
                  }
                ))
              ]), 
              const SizedBox(height: 30), 
              SizedBox(width: double.infinity, child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: kPrimaryGreen, padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))), 
                onPressed: isSaving ? null : () async { 
                  if (titleController.text.isNotEmpty && selectedDate != null && selectedTime != null) { 
                    setModalState(() => isSaving = true); 
                    try { 
                      final timeString = '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}:00'; 
                      final Map<String, dynamic> appointmentData = {
                        'patient_id': _supabase.auth.currentUser!.id, 
                        'doctor_id': _linkedDoctorId, 
                        'title': titleController.text, // Now correctly saving the title
                        'appointment_date': DateFormat('yyyy-MM-dd').format(selectedDate!), 
                        'appointment_time': timeString, 
                        'location': locController.text, 
                        'status': 'scheduled',
                        'type': isEditing ? apptToEdit['type'] : 'manual' // Preserve type if editing
                      }; 
                      if (isEditing) { await _supabase.from('roadmap').update(appointmentData).eq('id', apptToEdit['id']); } 
                      else { await _supabase.from('roadmap').insert(appointmentData); } 
                      await _fetchAppointments(); 
                      if (context.mounted) Navigator.pop(context); 
                    } catch (e) { setModalState(() => isSaving = false); } 
                  } 
                }, 
                child: isSaving ? const CircularProgressIndicator(color: Colors.white) : Text(isEditing ? "Update Milestone" : "Add Milestone", style: TextStyle(color: kWhite, fontWeight: FontWeight.bold))
              )), 
              const SizedBox(height: 40)
            ]
          )
        )
      )
    );
  }

  // --- UI BUILD ---
  @override
  Widget build(BuildContext context) {
    // Page is now unlocked immediately when connection is active
    bool isUnlocked = _connectionStatus == 'active';

    return Scaffold(
      backgroundColor: kWhite,
      appBar: AppBar(
        backgroundColor: kWhite, elevation: 0, centerTitle: true,
        leading: IconButton(icon: Icon(Icons.arrow_back_ios_new_rounded, color: kPrimaryGreen, size: 20), onPressed: () => Navigator.of(context).pop()),
        title: Text('Roadmap Milestone', style: TextStyle(fontWeight: FontWeight.w900, color: kPrimaryGreen, fontSize: 20)),
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator(color: kSecondaryGreen)) 
        : isUnlocked ? _buildUnlockedContent() : _buildLockedState(),
    );
  }

  Widget _buildUnlockedContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRecoveryRoadmap(), 
          const SizedBox(height: 25),
          _buildStreakCard(),
          const SizedBox(height: 35),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Roadmap Milestones", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: kPrimaryGreen)),
              GestureDetector(
                onTap: () => _showAppointmentModal(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: kSecondaryGreen, shape: BoxShape.circle),
                  child: const Icon(Icons.add, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          if (_appointments.isEmpty) _buildEmptyState("No milestones scheduled yet."),
          
          // Updated to pass the correct parameters, including title and type
          ..._appointments.map((appt) => _buildDismissibleWrapper(
            id: appt['id'].toString(), 
            onDismiss: () => _deleteAppointment(appt['id'].toString()), 
            child: GestureDetector(
              onTap: () => _showAppointmentModal(apptToEdit: appt),
              child: _buildAppointmentCard(
                appt['title'] ?? _doctorName ?? "Follow-up", 
                appt['appointment_date'], 
                appt['appointment_time'] ?? "08:00:00", 
                appt['location'] ?? "Clinic",
                appt['type'] ?? "manual"
              )
            )
          )),
          const SizedBox(height: 40),
          Text("CONSULTATION NOTES", style: TextStyle(color: kSecondaryGreen, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
          const SizedBox(height: 15),
          _buildNoteInputArea(), 
          const SizedBox(height: 25),
          if (_doctorNotes.isEmpty) _buildEmptyState("No notes added yet."),
          ListView.builder(
            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            itemCount: _doctorNotes.length,
            itemBuilder: (context, index) {
              final note = _doctorNotes[index];
              return InkWell(onLongPress: () => _editNoteDialog(note), child: _buildNoteTile(note, index));
            },
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildLockedState() {
    bool isPending = _connectionStatus == 'pending';
    bool isAwaitingPrescription = _connectionStatus == 'active' && _treatmentStartDate == null;

    return Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: kCreamAccent, shape: BoxShape.circle), 
            child: Icon(isAwaitingPrescription ? Icons.medical_services_outlined : Icons.lock_outline_rounded, size: 50, color: kPrimaryGreen)
          ),
          const SizedBox(height: 30),
          Text(isAwaitingPrescription ? "Awaiting Prescription" : (isPending ? "Waiting for Approval" : "Feature Locked"), 
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: kPrimaryGreen)),
          const SizedBox(height: 10),
          Text(isAwaitingPrescription 
            ? "Dr. ${(_doctorName ?? "your doctor")} has linked your account. Once your treatment dates are set, your roadmap will appear."
            : (isPending ? "Your request is being reviewed by the clinic." : "Link with your doctor to coordinate visits."), 
            textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(25), decoration: BoxDecoration(color: kSoftGrey, borderRadius: BorderRadius.circular(25)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("YOUR TREATMENT JOURNEY", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: kSecondaryGreen, letterSpacing: 1.2)),
              const SizedBox(height: 25),
              _buildStep("Account Created", true), 
              _buildStep("Risk Assessment", true), 
              _buildStep("Link to Clinic", isPending || isAwaitingPrescription), 
              _buildStep("Unlock Roadmap & Diary", false, isLast: true),
            ]),
          ),
          const SizedBox(height: 30),
          if (!isPending && !isAwaitingPrescription) ElevatedButton(onPressed: () => Navigator.pushReplacementNamed(context, '/dashboard'), style: ElevatedButton.styleFrom(backgroundColor: kPrimaryGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15)), child: const Text("Go to Dashboard", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  // --- UI COMPONENTS ---
  Widget _buildRecoveryRoadmap() {
    // Specific message if Roadmap is not yet set
    if (_treatmentStartDate == null) {
      return Container(
        padding: const EdgeInsets.all(20), 
        decoration: BoxDecoration(color: kWhite, borderRadius: BorderRadius.circular(25), border: Border.all(color: kSoftGrey, width: 2)), 
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, 
          children: [
            Text("Treatment Roadmap", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: kPrimaryGreen)), 
            const SizedBox(height: 10),
            const Text("Roadmap hasn't been set by your doctor yet.", style: TextStyle(fontSize: 14, color: Colors.grey, fontStyle: FontStyle.italic)),
          ]
        )
      );
    }

    int daysPassed = DateTime.now().difference(_treatmentStartDate!).inDays;
    double progress = (daysPassed / 180).clamp(0.0, 1.0); 
    int month = (daysPassed / 30).ceil().clamp(1, 6);
    
    return Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: kWhite, borderRadius: BorderRadius.circular(25), border: Border.all(color: kSoftGrey, width: 2)), 
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("Treatment Roadmap", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: kPrimaryGreen)), 
            Text("Started: ${DateFormat('MMM dd, yyyy').format(_treatmentStartDate!)}", style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold))
          ]), 
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: kCreamAccent, borderRadius: BorderRadius.circular(10)), child: Text("Month $month of 6", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: kSecondaryGreen)))
        ]), 
        const SizedBox(height: 15), 
        ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: progress, minHeight: 12, backgroundColor: kSoftGrey, color: kSecondaryGreen)), 
        const SizedBox(height: 10), 
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("${(progress * 100).toInt()}% Complete", style: TextStyle(fontSize: 12, color: kPrimaryGreen, fontWeight: FontWeight.bold)), Text("${180 - daysPassed} days left", style: const TextStyle(fontSize: 11, color: Colors.grey))])
      ]));
  }

  Widget _buildStep(String title, bool isActive, {bool isLast = false}) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Column(children: [
        Icon(isActive ? Icons.check_circle : Icons.circle_outlined, color: isActive ? kPrimaryGreen : Colors.grey, size: 22), 
        if (!isLast) Container(height: 30, width: 2, color: isActive ? kPrimaryGreen : Colors.grey.withOpacity(0.3))
      ]), 
      const SizedBox(width: 15), 
      Text(title, style: TextStyle(fontWeight: isActive ? FontWeight.bold : FontWeight.normal, color: isActive ? kPrimaryGreen : Colors.grey, fontSize: 15))
    ]);
  }

  Widget _buildStreakCard() {
    return Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(gradient: LinearGradient(colors: [kSecondaryGreen, kPrimaryGreen], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(30)), 
      child: Row(children: [
        Container(height: 60, width: 60, decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle), child: const Icon(Icons.bolt_rounded, color: Colors.orangeAccent, size: 35)), 
        const SizedBox(width: 20), 
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('$_streakDays Day Streak', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 26)), const Text('Keep going!', style: TextStyle(color: Colors.white70, fontSize: 14))])
      ]));
  }

  // Updated to include DOH Protocol UI styling
  Widget _buildAppointmentCard(String title, String date, String time, String loc, String type) {
    bool isProtocol = type == 'protocol';
    
    // Formatting time safely
    String displayTime = time;
    if (time.contains(':')) {
      final parts = time.split(':');
      if (parts.length >= 2) {
        final hr = int.parse(parts[0]);
        final min = parts[1];
        final period = hr >= 12 ? 'PM' : 'AM';
        final formattedHr = hr > 12 ? hr - 12 : (hr == 0 ? 12 : hr);
        displayTime = "$formattedHr:$min $period";
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 15), 
      padding: const EdgeInsets.all(20), 
      decoration: BoxDecoration(
        color: kWhite, 
        borderRadius: BorderRadius.circular(25), 
        border: Border.all(
          color: isProtocol ? kSecondaryGreen.withOpacity(0.5) : kSoftGrey, 
          width: 2
        )
      ), 
      child: Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15), 
          decoration: BoxDecoration(
            color: isProtocol ? kSecondaryGreen.withOpacity(0.1) : kCreamAccent, 
            borderRadius: BorderRadius.circular(15)
          ), 
          child: Column(children: [
            Text(date.split('-')[2], style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: kPrimaryGreen)), 
            Text(DateFormat('MMM').format(DateTime.parse(date)).toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: kSecondaryGreen))
          ])
        ), 
        const SizedBox(width: 15), 
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, 
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title, 
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: kPrimaryGreen),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    )
                  ),
                  if (isProtocol) 
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(6)),
                      child: Text("DOH Protocol", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.orange.shade900)),
                    )
                ],
              ),
              const SizedBox(height: 6),
              Text("$displayTime • $loc", style: const TextStyle(color: Colors.grey, fontSize: 12))
            ]
          )
        )
      ])
    );
  }

  Widget _buildNoteInputArea() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: _categories.map((cat) { 
        final isSelected = _selectedCategory == cat; 
        return Padding(padding: const EdgeInsets.only(right: 8.0), child: ChoiceChip(label: Text(cat), selected: isSelected, selectedColor: kPrimaryGreen, onSelected: (val) => setState(() => _selectedCategory = cat))); }).toList())), 
      const SizedBox(height: 10), 
      Container(decoration: BoxDecoration(color: kSoftGrey, borderRadius: BorderRadius.circular(20)), 
        child: TextField(controller: _noteController, decoration: InputDecoration(hintText: "Add a $_selectedCategory...", border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15), suffixIcon: IconButton(icon: CircleAvatar(backgroundColor: kPrimaryGreen, child: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 20)), onPressed: _addNote))))
    ]);
  }

  Widget _buildNoteTile(Map<String, dynamic> note, int index) {
    bool isChecked = note['is_checked'] ?? false;
    String category = note['category'] ?? 'Question';
    Color catColor = category == 'Symptom' ? const Color(0xFFE76F51) : (category == 'Question' ? const Color(0xFF2A9D8F) : const Color(0xFFE9C46A)); 
    return AnimatedOpacity(opacity: isChecked ? 0.0 : 1.0, duration: const Duration(milliseconds: 500), 
      child: _buildDismissibleWrapper(id: note['id'].toString(), onDismiss: () => _deleteNote(note['id'].toString()), 
        child: Container(margin: const EdgeInsets.only(bottom: 10), decoration: BoxDecoration(color: kWhite, borderRadius: BorderRadius.circular(18), border: Border.all(color: kSoftGrey, width: 1)), 
          child: CheckboxListTile(activeColor: kSecondaryGreen, value: isChecked, onChanged: (bool? value) => _toggleNote(index), 
            title: Row(children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: catColor.withOpacity(0.2), borderRadius: BorderRadius.circular(8)), child: Text(category, style: TextStyle(color: catColor, fontSize: 10, fontWeight: FontWeight.bold))), 
              const SizedBox(width: 8), 
              Expanded(child: Text(note['note_text'], style: TextStyle(color: kPrimaryGreen, fontWeight: FontWeight.w600, fontSize: 15)))
            ]), controlAffinity: ListTileControlAffinity.leading))));
  }

  Widget _buildDismissibleWrapper({required String id, required VoidCallback onDismiss, required Widget child}) { 
    return Dismissible(key: Key(id), direction: DismissDirection.endToStart, onDismissed: (dir) => onDismiss(), background: Container(decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(20)), alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 25), child: const Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 30)), child: child); 
  }

  Widget _buildEmptyState(String msg) { return Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 20), child: Text(msg, style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)))); }
  Widget _buildModernField(TextEditingController controller, String label, IconData icon) { return TextField(controller: controller, decoration: InputDecoration(prefixIcon: Icon(icon, color: kSecondaryGreen), labelText: label, filled: true, fillColor: kSoftGrey, border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none))); }
  Widget _buildPickerTile({required String label, required IconData icon, required VoidCallback onTap}) { return InkWell(onTap: onTap, child: Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: kSoftGrey, borderRadius: BorderRadius.circular(18)), child: Column(children: [Icon(icon, color: kSecondaryGreen), const SizedBox(height: 8), Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: kPrimaryGreen))]))); }
}
