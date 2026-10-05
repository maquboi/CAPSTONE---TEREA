import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

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

  // --- FORMAL CLINICAL COLOR SYSTEM ---
  static const Color primaryTeal = Color(0xFF0F766E);       // Deep Clinical Teal
  static const Color primaryDark = Color(0xFF115E59);       // Spruce Slate
  static const Color primaryDeep = Color(0xFF042F2E);       // Deepest Navy Teal
  static const Color backgroundSurface = Color(0xFFF1F5F9); // Contrast Slate Background
  static const Color cardBg = Colors.white;                // Pure White Card
  static const Color textCharcoal = Color(0xFF0F172A);      // High Contrast Text
  static const Color textMuted = Color(0xFF64748B);         // Subdued Text
  static const Color borderNeutral = Color(0xFFE2E8F0);     // Structured Border
  static const Color emeraldGreen = Color(0xFF059669);      // Positive Compliance
  static const Color inputBg = Color(0xFFF8FAFC);          // Form Field Background

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

  // Prevents duplicate "Dr. Dr." prefixes
  String _formatDoctorName(String? name) {
    if (name == null || name.trim().isEmpty) return "";
    final clean = name.trim().replaceFirst(RegExp(r'^(dr\.?\s*)+', caseSensitive: false), '');
    return "Dr. $clean";
  }

  void _showNotificationPopup(String message, {bool isSuccess = false}) {
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
                  isSuccess ? "Success" : "Notice",
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: textCharcoal,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w400,
                    fontSize: 13,
                    color: textMuted,
                    height: 1.4,
                  ),
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
                    child: Text("Got it", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
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
          _tbRegimen = profileData?['tb_regimen'] ?? "Standard Regimen";

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
      final data = await _supabase
          .from('doctor_notes')
          .select()
          .eq('user_id', _supabase.auth.currentUser!.id)
          .eq('is_checked', false)
          .order('created_at', ascending: false);
      if (mounted) setState(() => _doctorNotes = List<Map<String, dynamic>>.from(data));
    } catch (e) {
      debugPrint('Notes Error: $e');
    }
  }

  Future<void> _fetchAppointments() async {
    try {
      final data = await _supabase
          .from('roadmap')
          .select()
          .eq('patient_id', _supabase.auth.currentUser!.id)
          .neq('status', 'completed')
          .order('appointment_date', ascending: true);
      if (mounted) setState(() => _appointments = List<Map<String, dynamic>>.from(data));
    } catch (e) {
      debugPrint('Appt Error: $e');
    }
  }

  Future<void> _addNote() async {
    if (_noteController.text.trim().isEmpty) return;
    final text = _noteController.text.trim();
    final category = _selectedCategory;
    _noteController.clear();
    setState(() => _selectedCategory = 'Question');
    try {
      await _supabase.from('doctor_notes').insert({
        'note_text': text,
        'category': category,
        'user_id': _supabase.auth.currentUser!.id,
        'is_checked': false,
      });
      _fetchNotes();
      _showNotificationPopup("Note successfully forwarded to your attending clinician's queue.", isSuccess: true);
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
    setState(() {
      _doctorNotes[index]['is_checked'] = true;
    });
    await Future.delayed(const Duration(milliseconds: 300));
    final noteId = _doctorNotes[index]['id'];
    try {
      await _supabase.from('doctor_notes').update({'is_checked': true}).eq('id', noteId);
      if (mounted) {
        setState(() {
          _doctorNotes.removeAt(index);
        });
      }
    } catch (e) {
      debugPrint('Toggle Note Error: $e');
      if (mounted) {
        setState(() {
          _doctorNotes[index]['is_checked'] = false;
        });
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
      if (mounted) _showNotificationPopup("Failed to delete milestone: $e");
    }
  }

  Future<void> _editNoteDialog(Map<String, dynamic> note) async {
    final editController = TextEditingController(text: note['note_text']);
    String editCategory = note['category'] ?? 'Question';

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: borderNeutral),
          ),
          title: Text(
            "Edit Consultation Note",
            style: GoogleFonts.inter(color: textCharcoal, fontWeight: FontWeight.w700, fontSize: 16),
          ),
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
                    selectedColor: primaryTeal.withOpacity(0.12),
                    backgroundColor: inputBg,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: isSelected ? primaryTeal : borderNeutral),
                    ),
                    labelStyle: GoogleFonts.inter(
                      color: isSelected ? primaryTeal : textMuted,
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                    onSelected: (val) => setDialogState(() => editCategory = cat),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: editController,
                maxLines: 3,
                style: GoogleFonts.inter(color: textCharcoal, fontSize: 13.5),
                decoration: InputDecoration(
                  hintText: "Update your note...",
                  hintStyle: GoogleFonts.inter(color: Colors.black26, fontSize: 13),
                  filled: true,
                  fillColor: inputBg,
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: borderNeutral)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: borderNeutral)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: primaryTeal, width: 1.5)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel", style: GoogleFonts.inter(color: textMuted, fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryTeal,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onPressed: () async {
                try {
                  if (editController.text.trim().isNotEmpty) {
                    await _supabase.from('doctor_notes').update({
                      'note_text': editController.text.trim(),
                      'category': editCategory,
                    }).eq('id', note['id']);
                    _fetchNotes();
                    if (context.mounted) Navigator.pop(context);
                  }
                } catch (e) {
                  if (context.mounted) _showNotificationPopup("Failed to save changes: $e");
                }
              },
              child: Text("Save", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
            ),
          ],
        ),
      ),
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
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(color: borderNeutral, borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                isEditing ? "Edit Milestone" : "Schedule Roadmap Milestone",
                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: textCharcoal),
              ),
              const SizedBox(height: 16),
              _buildModernField(titleController, "Milestone Title", Icons.event_note_outlined),
              const SizedBox(height: 12),
              _buildModernField(locController, "Location / Facility", Icons.location_on_outlined),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildPickerTile(
                      label: selectedDate == null ? "Select Date" : DateFormat('MMM dd, yyyy').format(selectedDate!),
                      icon: Icons.calendar_month_rounded,
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate ?? DateTime.now(),
                          firstDate: DateTime.now().subtract(const Duration(days: 365)),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) setModalState(() => selectedDate = picked);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildPickerTile(
                      label: selectedTime == null ? "Select Time" : selectedTime!.format(context),
                      icon: Icons.access_time_rounded,
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: selectedTime ?? TimeOfDay.now(),
                        );
                        if (picked != null) setModalState(() => selectedTime = picked);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryTeal,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (titleController.text.trim().isNotEmpty && selectedDate != null && selectedTime != null) {
                            setModalState(() => isSaving = true);
                            try {
                              final timeString =
                                  '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}:00';
                              final Map<String, dynamic> appointmentData = {
                                'patient_id': _supabase.auth.currentUser!.id,
                                'doctor_id': _linkedDoctorId,
                                'title': titleController.text.trim(),
                                'appointment_date': DateFormat('yyyy-MM-dd').format(selectedDate!),
                                'appointment_time': timeString,
                                'location': locController.text.trim(),
                                'status': 'scheduled',
                                'type': isEditing ? apptToEdit['type'] : 'manual',
                              };
                              if (isEditing) {
                                await _supabase.from('roadmap').update(appointmentData).eq('id', apptToEdit['id']);
                              } else {
                                await _supabase.from('roadmap').insert(appointmentData);
                              }
                              await _fetchAppointments();
                              if (context.mounted) Navigator.pop(context);
                            } catch (e) {
                              setModalState(() => isSaving = false);
                              if (mounted) _showNotificationPopup("Failed to save milestone: $e");
                            }
                          }
                        },
                  child: isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(isEditing ? "Update Milestone" : "Save Milestone", style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isUnlocked = _connectionStatus == 'active' || _patientStatus == 'cured' || _patientStatus == 'treatment_completed';

    return Scaffold(
      backgroundColor: backgroundSurface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: textCharcoal, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Roadmap & Milestones',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: textCharcoal, fontSize: 17),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryTeal))
          : isUnlocked
              ? _buildUnlockedContent()
              : _buildLockedState(),
    );
  }

  Widget _buildUnlockedContent() {
    bool isCured = _patientStatus == 'cured' || _patientStatus == 'treatment_completed';

    final filteredNotes = _noteFilterCategory == 'All'
        ? _doctorNotes
        : _doctorNotes.where((n) => (n['category'] ?? 'Question') == _noteFilterCategory).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isCured)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                border: Border.all(color: const Color(0xFFBBF7D0)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(Icons.verified_rounded, color: emeraldGreen, size: 36),
                  const SizedBox(height: 8),
                  Text(
                    "POST-TREATMENT SURVEILLANCE ACTIVE",
                    style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: const Color(0xFF166534), fontSize: 12, letterSpacing: 0.8),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "You have concluded active daily intake. Please attend your scheduled 6-Month and 1-Year post-care clearances below.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 12, color: textMuted, height: 1.35),
                  ),
                ],
              ),
            )
          else
            _buildRecoveryRoadmap(),

          const SizedBox(height: 18),

          if (!isCured) _buildClinicalTrajectoryCard(),
          if (!isCured) const SizedBox(height: 24),

          // Header for Milestones
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isCured ? "Post-Care Surveillance Checkpoints" : "Roadmap Milestones",
                style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: textCharcoal),
              ),
              if (!isCured)
                GestureDetector(
                  onTap: () => _showAppointmentModal(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: primaryTeal.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add, color: primaryTeal, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          "Add Event",
                          style: GoogleFonts.inter(color: primaryTeal, fontWeight: FontWeight.w700, fontSize: 11.5),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          if (_appointments.isEmpty) _buildEmptyState(isCured ? "You have no scheduled follow-ups." : "No milestones scheduled yet."),

          ..._appointments.map((appt) => _buildDismissibleWrapper(
                id: appt['id'].toString(),
                onDismiss: () => _deleteAppointment(appt['id'].toString()),
                child: GestureDetector(
                  onTap: () => _showAppointmentModal(apptToEdit: appt),
                  child: _buildAppointmentCard(
                    appt['title'] ?? (_doctorName != null ? _formatDoctorName(_doctorName) : "Follow-up Checkup"),
                    appt['appointment_date'],
                    appt['appointment_time'] ?? "08:00:00",
                    appt['location'] ?? "Carmona Health Center",
                    appt['type'] ?? "manual",
                  ),
                ),
              )),
          const SizedBox(height: 28),

          if (!isCured) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "CONSULTATION NOTES & QUESTIONS",
                  style: GoogleFonts.inter(color: textMuted, fontSize: 11.5, fontWeight: FontWeight.w700, letterSpacing: 1.0),
                ),
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _noteFilterCategory,
                    icon: const Icon(Icons.filter_list_rounded, size: 16, color: primaryTeal),
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: primaryTeal),
                    items: ['All', ..._categories].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (val) => setState(() => _noteFilterCategory = val ?? 'All'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildNoteInputArea(),
            const SizedBox(height: 16),
            if (filteredNotes.isEmpty) _buildEmptyState("No notes matching the selected category."),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredNotes.length,
              itemBuilder: (context, index) {
                final note = filteredNotes[index];
                return InkWell(onLongPress: () => _editNoteDialog(note), child: _buildNoteTile(note, index));
              },
            ),
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildLockedState() {
    bool isPending = _connectionStatus == 'pending';
    bool isAwaitingPrescription = _connectionStatus == 'active' && _treatmentStartDate == null;
    final docDisplay = _doctorName != null ? _formatDoctorName(_doctorName) : "your doctor";

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: primaryTeal.withOpacity(0.08), shape: BoxShape.circle),
              child: Icon(
                isAwaitingPrescription ? Icons.medical_services_outlined : Icons.lock_outline_rounded,
                size: 44,
                color: primaryTeal,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isAwaitingPrescription
                  ? "Awaiting Regimen Schedule"
                  : (isPending ? "Waiting for Clinic Verification" : "Roadmap Locked"),
              style: GoogleFonts.inter(fontSize: 19, fontWeight: FontWeight.w700, color: textCharcoal),
            ),
            const SizedBox(height: 8),
            Text(
              isAwaitingPrescription
                  ? "$docDisplay has linked your account. Once your treatment timeline is set by the clinic, your trajectory milestones will appear."
                  : (isPending ? "Your link request is currently being reviewed by the health center." : "Link with your clinic doctor to coordinate your checkup schedule."),
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: textMuted, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderNeutral),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("TREATMENT PATHWAY", style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w700, color: textMuted, letterSpacing: 1.0)),
                  const SizedBox(height: 18),
                  _buildStep("Account Created", true),
                  _buildStep("Risk Assessment", true),
                  _buildStep("Link to Clinic", isPending || isAwaitingPrescription),
                  _buildStep("Unlock Roadmap & Diary", false, isLast: true),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (!isPending && !isAwaitingPrescription)
              ElevatedButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/dashboard'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryTeal,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  elevation: 0,
                ),
                child: Text("Go to Dashboard", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecoveryRoadmap() {
    if (_treatmentStartDate == null) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderNeutral),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Treatment Roadmap", style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14.5, color: textCharcoal)),
            const SizedBox(height: 6),
            Text("Treatment timeline has not been calibrated by your clinic yet.", style: GoogleFonts.inter(fontSize: 12.5, color: textMuted, fontStyle: FontStyle.italic)),
          ],
        ),
      );
    }

    int daysPassed = DateTime.now().difference(_treatmentStartDate!).inDays;
    double progress = (daysPassed / 180).clamp(0.0, 1.0);
    int month = (daysPassed / 30).ceil().clamp(1, 6);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Treatment Progress", style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14.5, color: textCharcoal)),
                  const SizedBox(height: 2),
                  Text("Initiated: ${DateFormat('MMM dd, yyyy').format(_treatmentStartDate!)}", style: GoogleFonts.inter(fontSize: 11.5, color: textMuted)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: primaryTeal.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "Month $month of 6",
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 11.5, color: primaryTeal),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: const AlwaysStoppedAnimation<Color>(primaryTeal),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("${(progress * 100).toInt()}% Complete", style: GoogleFonts.inter(fontSize: 11.5, color: textCharcoal, fontWeight: FontWeight.w700)),
              Text("${(180 - daysPassed).clamp(0, 180)} days remaining", style: GoogleFonts.inter(fontSize: 11, color: textMuted)),
            ],
          ),
        ],
      ),
    );
  }

  // --- DOH NTP CLINICAL TRAJECTORY STEPPER ---
  Widget _buildClinicalTrajectoryCard() {
    final now = DateTime.now();
    final elapsedDays = _treatmentStartDate != null ? now.difference(_treatmentStartDate!).inDays : 0;

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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
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
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: primaryTeal.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.route_rounded, color: primaryTeal, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Clinical Trajectory",
                        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: textCharcoal),
                      ),
                      Text(
                        "DOH Standard Care Protocol",
                        style: GoogleFonts.inter(fontSize: 10.5, color: textMuted),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isIntensive ? const Color(0xFFFEF3C7) : const Color(0xFFF0FDFA),
                  border: Border.all(color: isIntensive ? const Color(0xFFFDE68A) : const Color(0xFFCCFBF1)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  currentPhaseTitle,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isIntensive ? const Color(0xFFB45309) : primaryTeal,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Stepper
          LayoutBuilder(
            builder: (context, constraints) {
              final totalWidth = constraints.maxWidth;
              final double startLine = totalWidth / 8;
              final double endLine = totalWidth * 0.75;
              final double progressPercent = (elapsedDays / 180.0).clamp(0.0, 1.0);

              return Stack(
                children: [
                  Positioned(
                    top: 14,
                    left: startLine,
                    right: startLine,
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(color: borderNeutral, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  Positioned(
                    top: 14,
                    left: startLine,
                    child: Container(
                      height: 2,
                      width: endLine * progressPercent,
                      decoration: BoxDecoration(color: primaryTeal, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
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
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: isDone ? primaryTeal : Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDone ? primaryTeal : (isCurrent ? primaryTeal : borderNeutral),
                                  width: isCurrent ? 2.5 : 1.5,
                                ),
                              ),
                              child: Center(
                                child: isDone
                                    ? const Icon(Icons.check, size: 15, color: Colors.white)
                                    : Text(
                                        "${idx + 1}",
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: isCurrent ? primaryTeal : textMuted,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              s['title'] as String,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                fontWeight: isCurrent || isDone ? FontWeight.w700 : FontWeight.w500,
                                color: isDone ? textCharcoal : (isCurrent ? primaryTeal : textMuted),
                              ),
                            ),
                            Text(
                              s['sub'] as String,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: textMuted,
                                fontWeight: FontWeight.w400,
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

          const SizedBox(height: 18),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: backgroundSurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: primaryTeal, size: 15),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isIntensive
                        ? "Intensive Phase: $currentDrugFocus. Target: Month 2 Sputum Conversion."
                        : "Continuation Phase: $currentDrugFocus. Target: Month 6 Treatment Completion.",
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: textCharcoal,
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Icon(
              isActive ? Icons.check_circle_rounded : Icons.radio_button_off_rounded,
              color: isActive ? primaryTeal : textMuted.withOpacity(0.5),
              size: 20,
            ),
            if (!isLast)
              Container(
                height: 24,
                width: 1.5,
                color: isActive ? primaryTeal : borderNeutral,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.inter(
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            color: isActive ? textCharcoal : textMuted,
            fontSize: 13.5,
          ),
        ),
      ],
    );
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
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOverdue ? const Color(0xFFFCA5A5) : borderNeutral,
          width: isOverdue ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isOverdue
                  ? const Color(0xFFFEF2F2)
                  : (isPostCare ? const Color(0xFFF0FDF4) : const Color(0xFFF0FDFA)),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isOverdue
                    ? const Color(0xFFFECACA)
                    : (isPostCare ? const Color(0xFFBBF7D0) : const Color(0xFFCCFBF1)),
              ),
            ),
            child: Column(
              children: [
                Text(
                  date.split('-')[2],
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isOverdue
                        ? const Color(0xFFDC2626)
                        : (isPostCare ? const Color(0xFF16A34A) : primaryTeal),
                  ),
                ),
                Text(
                  DateFormat('MMM').format(DateTime.parse(date)).toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: isOverdue ? const Color(0xFFDC2626) : textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
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
                        style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: textCharcoal),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isOverdue)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(4)),
                        child: Text("OVERDUE", style: GoogleFonts.inter(fontSize: 8.5, fontWeight: FontWeight.w800, color: const Color(0xFF991B1B))),
                      ),
                    if (isProtocol && !isOverdue)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(4)),
                        child: Text("DOH Protocol", style: GoogleFonts.inter(fontSize: 8.5, fontWeight: FontWeight.w800, color: const Color(0xFF92400E))),
                      ),
                    if (isPostCare && !isOverdue)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(4)),
                        child: Text("Clearance", style: GoogleFonts.inter(fontSize: 8.5, fontWeight: FontWeight.w800, color: const Color(0xFF166534))),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  "$displayTime • $loc",
                  style: GoogleFonts.inter(color: textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteInputArea() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _categories.map((cat) {
              final isSelected = _selectedCategory == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Text(cat),
                  selected: isSelected,
                  selectedColor: primaryTeal.withOpacity(0.12),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: isSelected ? primaryTeal : borderNeutral),
                  ),
                  labelStyle: GoogleFonts.inter(
                    color: isSelected ? primaryTeal : textMuted,
                    fontSize: 11.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  onSelected: (val) => setState(() => _selectedCategory = cat),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderNeutral),
          ),
          child: TextField(
            controller: _noteController,
            style: GoogleFonts.inter(fontSize: 13.5, color: textCharcoal),
            decoration: InputDecoration(
              hintText: "Add a $_selectedCategory to your doctor's queue...",
              hintStyle: GoogleFonts.inter(color: Colors.black26, fontSize: 13),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              suffixIcon: IconButton(
                icon: const CircleAvatar(
                  radius: 15,
                  backgroundColor: primaryTeal,
                  child: Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 16),
                ),
                onPressed: _addNote,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoteTile(Map<String, dynamic> note, int index) {
    bool isChecked = note['is_checked'] ?? false;
    String category = note['category'] ?? 'Question';

    Color catColor = primaryTeal;
    Color catBg = const Color(0xFFF0FDFA);

    if (category == 'Symptom') {
      catColor = const Color(0xFFDC2626);
      catBg = const Color(0xFFFEF2F2);
    } else if (category == 'Side Effect') {
      catColor = const Color(0xFFD97706);
      catBg = const Color(0xFFFFFBEB);
    }

    return AnimatedOpacity(
      opacity: isChecked ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 300),
      child: _buildDismissibleWrapper(
        id: note['id'].toString(),
        onDismiss: () => _deleteNote(note['id'].toString()),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderNeutral),
          ),
          child: CheckboxListTile(
            activeColor: primaryTeal,
            checkboxShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            value: isChecked,
            onChanged: (bool? value) => _toggleNote(index),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(color: catBg, borderRadius: BorderRadius.circular(6)),
                  child: Text(
                    category,
                    style: GoogleFonts.inter(color: catColor, fontSize: 10, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    note['note_text'],
                    style: GoogleFonts.inter(color: textCharcoal, fontWeight: FontWeight.w500, fontSize: 13.5),
                  ),
                ),
              ],
            ),
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ),
      ),
    );
  }

  Widget _buildDismissibleWrapper({required String id, required VoidCallback onDismiss, required Widget child}) {
    return Dismissible(
      key: Key(id),
      direction: DismissDirection.endToStart,
      onDismissed: (dir) => onDismiss(),
      background: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFDC2626),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 24),
      ),
      child: child,
    );
  }

  Widget _buildEmptyState(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text(
          msg,
          style: GoogleFonts.inter(color: textMuted, fontStyle: FontStyle.italic, fontSize: 12.5),
        ),
      ),
    );
  }

  Widget _buildModernField(TextEditingController controller, String label, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: textCharcoal)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          style: GoogleFonts.inter(fontSize: 13.5, color: textCharcoal),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: primaryTeal, size: 18),
            hintText: "Enter $label",
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

  Widget _buildPickerTile({required String label, required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: inputBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderNeutral),
        ),
        child: Row(
          children: [
            Icon(icon, color: primaryTeal, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: textCharcoal),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}