import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart'; 

class FollowUpPage extends StatefulWidget {
  const FollowUpPage({super.key});

  @override
  State<FollowUpPage> createState() => _FollowUpPageState();
}

class _FollowUpPageState extends State<FollowUpPage> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;

  // CONNECTION & CLINICAL STATE
  String? _connectionStatus;
  String? _patientStatus;
  String? _linkedDoctorId;
  String? _doctorName;
  DateTime? _treatmentStartDate; 
  String? _tbRegimen;

  // DATA
  List<Map<String, dynamic>> _doctorNotes = [];
  List<Map<String, dynamic>> _appointments = [];
  String _noteFilterCategory = 'All';
  
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

  Future<void> _checkConnectionAndLoad() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final connectionData = await _supabase
          .from('connections')
          .select('status, doctor_id, profiles!fk_doctor(full_name)')
          .eq('patient_id', user.id)
          .maybeSingle();

      final profileData = await _supabase
          .from('profiles')
          .select('treatment_start_date, status, tb_regimen') 
          .eq('id', user.id)
          .maybeSingle(); 

      if (mounted) {
        setState(() {
          _connectionStatus = connectionData?['status'];
          _patientStatus = profileData?['status'];
          _tbRegimen = profileData?['tb_regimen'] ?? "6-Month DOTS";

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

      if (_connectionStatus == 'active' || _patientStatus == 'cured' || _patientStatus == 'treatment_completed') {
        await Future.wait([
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

  Future<void> _addNote() async {
    if (_noteController.text.isEmpty) return;
    final text = _noteController.text;
    final category = _selectedCategory;
    _noteController.clear();
    setState(() => _selectedCategory = 'Question');
    try {
      await _supabase.from('doctor_notes').insert({'note_text': text, 'category': category, 'user_id': _supabase.auth.currentUser!.id, 'is_checked': false});
      _fetchNotes();
      _showNotificationPopup("Note successfully sent to your doctor's queue.", isSuccess: true);
    } catch (e) { 
      debugPrint('Add Note Error: $e'); 
      if (mounted) _showNotificationPopup("Failed to add note: $e");
    }
  }

  Future<void> _deleteNote(String id) async { 
    try {
      await _supabase.from('doctor_notes').delete().eq('id', id); 
      _fetchNotes(); 
    } catch (e) {
      debugPrint('Delete Note Error: $e');
      if (mounted) _showNotificationPopup("Failed to delete note: $e");
    }
  }

  Future<void> _toggleNote(int index) async {
    setState(() { _doctorNotes[index]['is_checked'] = true; });
    await Future.delayed(const Duration(milliseconds: 500));
    final noteId = _doctorNotes[index]['id'];
    try {
      await _supabase.from('doctor_notes').update({'is_checked': true}).eq('id', noteId);
      if (mounted) { setState(() { _doctorNotes.removeAt(index); }); }
    } catch (e) {
      debugPrint('Toggle Note Error: $e');
      if (mounted) {
        setState(() { _doctorNotes[index]['is_checked'] = false; });
        _showNotificationPopup("Failed to update note: $e");
      }
    }
  }

  Future<void> _deleteAppointment(String id) async { 
    try {
      await _supabase.from('roadmap').delete().eq('id', id);
      _fetchAppointments(); 
    } catch (e) {
      debugPrint('Delete Appt Error: $e');
      if (mounted) _showNotificationPopup("Failed to delete appointment: $e");
    }
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
                try {
                  if (editController.text.isNotEmpty) { 
                    await _supabase.from('doctor_notes').update({'note_text': editController.text, 'category': editCategory}).eq('id', note['id']); 
                    _fetchNotes(); 
                    if (context.mounted) Navigator.pop(context); 
                  }
                } catch (e) {
                  if (context.mounted) _showNotificationPopup("Failed to save changes: $e");
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
    
    final titleController = TextEditingController(text: isEditing ? (apptToEdit['title'] ?? "") : "Follow-up Checkup");
    final locController = TextEditingController(text: isEditing ? (apptToEdit['location'] ?? "") : "Carmona Health Center");
    
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
                        'title': titleController.text,
                        'appointment_date': DateFormat('yyyy-MM-dd').format(selectedDate!), 
                        'appointment_time': timeString, 
                        'location': locController.text, 
                        'status': 'scheduled',
                        'type': isEditing ? apptToEdit['type'] : 'manual' 
                      }; 
                      if (isEditing) { await _supabase.from('roadmap').update(appointmentData).eq('id', apptToEdit['id']); } 
                      else { await _supabase.from('roadmap').insert(appointmentData); } 
                      await _fetchAppointments(); 
                      if (context.mounted) Navigator.pop(context); 
                    } catch (e) { 
                      setModalState(() => isSaving = false); 
                      if (mounted) _showNotificationPopup("Failed to save milestone: $e");
                    } 
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

  @override
  Widget build(BuildContext context) {
    bool isUnlocked = _connectionStatus == 'active' || _patientStatus == 'cured' || _patientStatus == 'treatment_completed';

    return Scaffold(
      backgroundColor: kWhite,
      appBar: AppBar(
        backgroundColor: kWhite, elevation: 0, centerTitle: true,
        leading: IconButton(icon: Icon(Icons.arrow_back_ios_new_rounded, color: kPrimaryGreen, size: 20), onPressed: () => Navigator.of(context).pop()),
        title: Text('Roadmap & Milestones', style: TextStyle(fontWeight: FontWeight.w900, color: kPrimaryGreen, fontSize: 20)),
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator(color: kSecondaryGreen)) 
        : isUnlocked ? _buildUnlockedContent() : _buildLockedState(),
    );
  }

  Widget _buildUnlockedContent() {
    bool isCured = _patientStatus == 'cured' || _patientStatus == 'treatment_completed';

    final filteredNotes = _noteFilterCategory == 'All' 
        ? _doctorNotes 
        : _doctorNotes.where((n) => (n['category'] ?? 'Question') == _noteFilterCategory).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isCured)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.only(bottom: 25),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                border: Border.all(color: Colors.green.shade200, width: 2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Icon(Icons.verified_rounded, color: Colors.green.shade700, size: 40),
                  const SizedBox(height: 10),
                  Text("POST-TREATMENT SURVEILLANCE", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.green.shade800, letterSpacing: 1.2)),
                  const SizedBox(height: 5),
                  Text("You have concluded active treatment. Please attend your scheduled 6-Month and 1-Year post-care clearances below.", textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.green.shade700)),
                ],
              ),
            )
          else
            _buildRecoveryRoadmap(), 

          const SizedBox(height: 25),
          
          // --- REPLACED STREAK WITH DOH NTP CLINICAL TRAJECTORY STEPPER ---
          if (!isCured) _buildClinicalTrajectoryCard(),
          if (!isCured) const SizedBox(height: 30),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(isCured ? "Post-Care Checkpoints" : "Roadmap Milestones", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: kPrimaryGreen)),
              if (!isCured)
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
          if (_appointments.isEmpty) _buildEmptyState(isCured ? "You have no scheduled follow-ups." : "No milestones scheduled yet."),
          
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
          
          if (!isCured) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("CONSULTATION NOTES", style: TextStyle(color: kSecondaryGreen, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                DropdownButton<String>(
                  value: _noteFilterCategory,
                  underline: const SizedBox(),
                  icon: const Icon(Icons.filter_list_rounded, size: 16),
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: kPrimaryGreen),
                  items: ['All', ..._categories].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (val) => setState(() => _noteFilterCategory = val ?? 'All'),
                )
              ],
            ),
            const SizedBox(height: 15),
            _buildNoteInputArea(), 
            const SizedBox(height: 25),
            if (filteredNotes.isEmpty) _buildEmptyState("No notes matching filter."),
            ListView.builder(
              shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredNotes.length,
              itemBuilder: (context, index) {
                final note = filteredNotes[index];
                return InkWell(onLongPress: () => _editNoteDialog(note), child: _buildNoteTile(note, index));
              },
            ),
          ],
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

  Widget _buildRecoveryRoadmap() {
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
            Text("Treatment Progress", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: kPrimaryGreen)), 
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

  // --- REPLACED STREAK CARD: MOBILE DOH NTP CLINICAL TRAJECTORY STEPPER ---
  Widget _buildClinicalTrajectoryCard() {
    final now = DateTime.now();
    final elapsedDays = _treatmentStartDate != null 
        ? now.difference(_treatmentStartDate!).inDays 
        : 0;

    final bool isIntensive = elapsedDays <= 60;
    final String currentPhaseTitle = isIntensive ? "Intensive Phase" : "Continuation Phase";
    final String currentDrugFocus = isIntensive ? "4-Drug HRZE Regimen" : "2-Drug HR Regimen";

    final steps = [
      {"title": "Day 1", "sub": "Initiation", "day": 0},
      {"title": "Mo 2", "sub": "Conversion", "day": 60},
      {"title": "Mo 5", "sub": "Mid-Check", "day": 150},
      {"title": "Mo 6", "sub": "Clearance", "day": 180},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: kSecondaryGreen.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: kSecondaryGreen.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.route_rounded, color: kSecondaryGreen, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "DOH NTP Trajectory",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: kPrimaryGreen,
                        ),
                      ),
                      Text(
                        "Clinical Care Protocol",
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isIntensive ? Colors.amber.shade50 : Colors.blue.shade50,
                  border: Border.all(color: isIntensive ? Colors.amber.shade200 : Colors.blue.shade200),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  currentPhaseTitle,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isIntensive ? Colors.amber.shade900 : Colors.blue.shade800,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Mathematically aligned horizontal stepper
          LayoutBuilder(
            builder: (context, constraints) {
              final totalWidth = constraints.maxWidth;
              final double startLine = totalWidth / 8;
              final double endLine = totalWidth * 0.75;
              final double progressPercent = (elapsedDays / 180.0).clamp(0.0, 1.0);

              return Stack(
                children: [
                  // Inactive background connecting track
                  Positioned(
                    top: 15,
                    left: startLine,
                    right: startLine,
                    child: Container(
                      height: 3,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Active filled track
                  Positioned(
                    top: 15,
                    left: startLine,
                    child: Container(
                      height: 3,
                      width: endLine * progressPercent,
                      decoration: BoxDecoration(
                        color: kSecondaryGreen,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // 4 Milestone Nodes
                  Row(
                    children: List.generate(steps.length, (idx) {
                      final s = steps[idx];
                      final stepDay = s['day'] as int;
                      final bool isDone = elapsedDays >= stepDay;
                      final bool isCurrent = elapsedDays < stepDay && (idx == 0 || elapsedDays >= (steps[idx - 1]['day'] as int));

                      return Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: isDone
                                    ? kSecondaryGreen
                                    : (isCurrent ? Colors.white : Colors.white),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDone
                                      ? kSecondaryGreen
                                      : (isCurrent ? kSecondaryGreen : Colors.grey.shade300),
                                  width: isCurrent ? 3 : 2,
                                ),
                                boxShadow: isCurrent ? [
                                  BoxShadow(
                                    color: kSecondaryGreen.withOpacity(0.3),
                                    blurRadius: 6,
                                    spreadRadius: 1,
                                  )
                                ] : [],
                              ),
                              child: Center(
                                child: isDone
                                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                                    : Text(
                                        "${idx + 1}",
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: isCurrent ? kSecondaryGreen : Colors.grey.shade400,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              s['title'] as String,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isCurrent || isDone ? FontWeight.w800 : FontWeight.w600,
                                color: isDone ? kPrimaryGreen : (isCurrent ? kSecondaryGreen : Colors.grey.shade600),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              s['sub'] as String,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 20),

          // Contextual clinical summary banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: kSoftGrey,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, color: kSecondaryGreen, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isIntensive 
                        ? "Intensive Phase active: $currentDrugFocus. Target: Month 2 Conversion Test."
                        : "Continuation Phase active: $currentDrugFocus. Target: Month 6 Cure Clearance.",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: kPrimaryGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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

  Widget _buildAppointmentCard(String title, String date, String time, String loc, String type) {
    bool isProtocol = type == 'protocol';
    bool isPostCare = type == 'post-treatment';
    
    final apptDate = DateTime.tryParse(date) ?? DateTime.now();
    final isOverdue = apptDate.isBefore(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day));

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
          color: isOverdue ? Colors.red.shade300 : (isProtocol ? kSecondaryGreen.withOpacity(0.5) : (isPostCare ? Colors.green.shade200 : kSoftGrey)), 
          width: isOverdue ? 2 : 2
        )
      ), 
      child: Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15), 
          decoration: BoxDecoration(
            color: isOverdue ? Colors.red.shade50 : (isProtocol ? kSecondaryGreen.withOpacity(0.1) : (isPostCare ? Colors.green.shade50 : kCreamAccent)), 
            borderRadius: BorderRadius.circular(15)
          ), 
          child: Column(children: [
            Text(date.split('-')[2], style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: isOverdue ? Colors.red.shade700 : (isPostCare ? Colors.green.shade800 : kPrimaryGreen))), 
            Text(DateFormat('MMM').format(DateTime.parse(date)).toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isOverdue ? Colors.red.shade600 : (isPostCare ? Colors.green.shade700 : kSecondaryGreen)))
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
                  if (isOverdue)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(6)),
                      child: Text("OVERDUE", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.red.shade900)),
                    ),
                  if (isProtocol && !isOverdue) 
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(6)),
                      child: Text("DOH Protocol", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.orange.shade900)),
                    ),
                  if (isPostCare && !isOverdue) 
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(6)),
                      child: Text("Clearance", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.green.shade800)),
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