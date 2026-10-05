import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'shared_widgets.dart'; // REQUIRED to access isEnglishNotifier

// --- 9. SETTINGS & PROFILE PAGE ---
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _supabase = Supabase.instance.client;

  // USER PROFILE DATA
  String _username = "Loading...";
  String _email = "";
  String? _avatarUrl;
  String _age = "";
  String _gender = "Male";
  String _barangay = "Maduya";
  String _contactNumber = "";
  bool _isLoading = true;

  // --- FORMAL CLINICAL COLOR SYSTEM ---
  static const Color primaryTeal = Color(0xFF0F766E);       // Deep Clinical Teal
  static const Color primaryDark = Color(0xFF115E59);       // Spruce Slate
  static const Color primaryDeep = Color(0xFF042F2E);       // Deepest Navy Teal
  static const Color backgroundSurface = Color(0xFFF1F5F9); // Contrast Slate Background
  static const Color cardBg = Colors.white;                // Pure White Card
  static const Color textCharcoal = Color(0xFF0F172A);      // High Contrast Text
  static const Color textMuted = Color(0xFF64748B);         // Subdued Text
  static const Color borderNeutral = Color(0xFFE2E8F0);     // Structured Border
  static const Color inputBg = Color(0xFFF8FAFC);          // Form Field Background

  // CARMONA BARANGAY RESTRICTION LIST
  final List<String> _carmonaBarangays = [
    'Bancal',
    'Cabilang Baybay',
    'Lantic',
    'Mabuhay',
    'Maduya',
    'Milagrosa',
    'Poblacion 1',
    'Poblacion 2',
    'Poblacion 3',
    'Poblacion 4',
    'Poblacion 5',
    'Poblacion 6',
    'Poblacion 7',
    'Poblacion 8',
  ];

  final List<String> _genderOptions = ['Male', 'Female', 'Other'];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  // --- DATA LOGIC ---
  Future<void> _loadUserProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        setState(() => _email = user.email ?? "");

        final data = await _supabase
            .from('profiles')
            .select()
            .eq('id', user.id)
            .single();

        setState(() {
          _username = data['full_name'] ?? "New User";
          _avatarUrl = data['avatar_url'];
          _age = data['age']?.toString() ?? "";
          _gender = data['gender'] ?? "Male";
          _barangay = data['barangay'] ?? "Maduya";
          _contactNumber = data['contact_number'] ?? "";
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
      setState(() => _isLoading = false);
    }
  }

  // --- SIGN OUT CONFIRMATION POPUP ---
  void _showSignOutDialog(bool isEnglish) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderNeutral),
        ),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626).withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: Color(0xFFDC2626),
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isEnglish ? "Confirm Sign Out" : "Kumpirmahin ang Pag-log Out",
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: textCharcoal,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isEnglish
                  ? "Are you sure you want to sign out? You will need your email and password to access your treatment portal again."
                  : "Sigurado ka bang nais mong mag-log out? Kakailanganin mo ang iyong email at password upang muling makapasok.",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w400,
                fontSize: 13,
                color: textMuted,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: borderNeutral),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      isEnglish ? "Cancel" : "Kanselahin",
                      style: GoogleFonts.inter(
                        color: textCharcoal,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () async {
                      try {
                        await _supabase.auth.signOut();
                      } catch (e) {
                        debugPrint("Sign out error: $e");
                      }
                      if (context.mounted) {
                        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                      }
                    },
                    child: Text(
                      isEnglish ? "Sign Out" : "Mag-log Out",
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- EDIT PROFILE MODAL (NAME, AGE, GENDER, BARANGAY, CONTACT) ---
  Future<void> _showEditProfileModal(bool isEnglish) async {
    final nameController = TextEditingController(text: _username);
    final ageController = TextEditingController(text: _age);
    final contactController = TextEditingController(text: _contactNumber);
    String selectedGender = _genderOptions.contains(_gender) ? _gender : _genderOptions.first;
    String selectedBarangay = _carmonaBarangays.contains(_barangay) ? _barangay : _carmonaBarangays.first;

    String? errorText;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 16,
          ),
          child: SingleChildScrollView(
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
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEnglish ? "Edit Patient Information" : "I-edit ang Impormasyon",
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: textCharcoal,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: textMuted, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  isEnglish
                      ? "Keep your clinical contact details and residency accurate for the health center."
                      : "Panatilihing tama ang iyong impormasyon para sa health center.",
                  style: GoogleFonts.inter(fontSize: 12, color: textMuted, height: 1.4),
                ),
                const SizedBox(height: 16),

                if (errorText != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                    ),
                    child: Text(
                      errorText!,
                      style: GoogleFonts.inter(color: const Color(0xFF991B1B), fontSize: 12),
                    ),
                  ),

                // 1. Full Name
                _buildModalFieldLabel(isEnglish ? "Full Name" : "Buong Pangalan"),
                const SizedBox(height: 6),
                _buildModalTextField(
                  controller: nameController,
                  hint: "e.g. Juan Dela Cruz",
                  icon: Icons.person_outline_rounded,
                ),
                const SizedBox(height: 14),

                // 2. Age & Gender in One Row
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildModalFieldLabel(isEnglish ? "Age" : "Edad"),
                          const SizedBox(height: 6),
                          _buildModalTextField(
                            controller: ageController,
                            hint: "25",
                            icon: Icons.cake_outlined,
                            keyboardType: TextInputType.number,
                            formatters: [
                              LengthLimitingTextInputFormatter(3),
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildModalFieldLabel(isEnglish ? "Gender" : "Kasarian"),
                          const SizedBox(height: 6),
                          Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: inputBg,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: borderNeutral),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedGender,
                                isExpanded: true,
                                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: textMuted, size: 20),
                                dropdownColor: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                style: GoogleFonts.inter(color: textCharcoal, fontSize: 13.5, fontWeight: FontWeight.w500),
                                items: _genderOptions.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                                onChanged: (val) {
                                  if (val != null) setModalState(() => selectedGender = val);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // 3. Barangay Residency
                _buildModalFieldLabel(isEnglish ? "Barangay Residency (Carmona)" : "Barangay (Carmona)"),
                const SizedBox(height: 6),
                Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: inputBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: borderNeutral),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_outlined, color: textMuted, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedBarangay,
                            isExpanded: true,
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: textMuted, size: 20),
                            dropdownColor: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            style: GoogleFonts.inter(color: textCharcoal, fontSize: 13.5, fontWeight: FontWeight.w500),
                            items: _carmonaBarangays.map((b) => DropdownMenuItem(value: b, child: Text("Brgy. $b"))).toList(),
                            onChanged: (val) {
                              if (val != null) setModalState(() => selectedBarangay = val);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // 4. Contact Number
                _buildModalFieldLabel(isEnglish ? "Contact Number" : "Numero ng Telepono"),
                const SizedBox(height: 6),
                _buildModalTextField(
                  controller: contactController,
                  hint: "09123456789",
                  icon: Icons.phone_android_outlined,
                  keyboardType: TextInputType.phone,
                  formatters: [
                    LengthLimitingTextInputFormatter(11),
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                ),
                const SizedBox(height: 24),

                // Save Action Button
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
                    onPressed: () async {
                      final name = nameController.text.trim();
                      final age = ageController.text.trim();
                      final contact = contactController.text.trim();

                      if (name.isEmpty) {
                        setModalState(() => errorText = "Full name cannot be empty.");
                        return;
                      }

                      if (age.isNotEmpty) {
                        final parsedAge = int.tryParse(age);
                        if (parsedAge == null || parsedAge < 1 || parsedAge > 115) {
                          setModalState(() => errorText = "Please enter a valid age (1-115).");
                          return;
                        }
                      }

                      if (contact.isNotEmpty && (!contact.startsWith('09') || contact.length != 11)) {
                        setModalState(() => errorText = "Contact must start with '09' and be 11 digits.");
                        return;
                      }

                      try {
                        final userId = _supabase.auth.currentUser!.id;
                        await _supabase.from('profiles').update({
                          'full_name': name,
                          'age': age,
                          'gender': selectedGender,
                          'barangay': selectedBarangay,
                          'contact_number': contact,
                        }).eq('id', userId);

                        setState(() {
                          _username = name;
                          _age = age;
                          _gender = selectedGender;
                          _barangay = selectedBarangay;
                          _contactNumber = contact;
                        });

                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isEnglish ? "Profile information updated successfully!" : "Na-update na ang impormasyon!",
                                style: GoogleFonts.inter(fontSize: 13),
                              ),
                              backgroundColor: primaryTeal,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          );
                        }
                      } catch (e) {
                        setModalState(() => errorText = "Failed to update profile: $e");
                      }
                    },
                    child: Text(
                      isEnglish ? "Save Changes" : "I-save ang Pagbabago",
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13.5),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _uploadPhoto(bool isEnglish) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final fileBytes = file.bytes;
      final userId = _supabase.auth.currentUser!.id;
      final fileName = '$userId/profile_${DateTime.now().millisecondsSinceEpoch}.png';

      if (fileBytes != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isEnglish ? "Uploading photo..." : "Ina-upload ang litrato...",
                style: GoogleFonts.inter(fontSize: 13),
              ),
              backgroundColor: textCharcoal,
            ),
          );
        }

        await _supabase.storage.from('avatars').uploadBinary(
          fileName,
          fileBytes,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
        );

        final String publicUrl = _supabase.storage.from('avatars').getPublicUrl(fileName);

        await _supabase.from('profiles').update({'avatar_url': publicUrl}).eq('id', userId);

        setState(() => _avatarUrl = publicUrl);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isEnglish ? "Profile photo updated!" : "Na-update na ang litrato!",
                style: GoogleFonts.inter(fontSize: 13),
              ),
              backgroundColor: primaryTeal,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Upload failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEnglish ? "Upload failed. Check storage permissions." : "Bigo ang pag-upload.",
              style: GoogleFonts.inter(fontSize: 13),
            ),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  // --- LEGAL OVERLAYS ---
  void _showPrivacyPolicy(bool isEnglish) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.9,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 30),
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(color: borderNeutral, borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Privacy Policy & Legal Framework",
              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: textCharcoal),
            ),
            const SizedBox(height: 4),
            Text(
              "In accordance with Philippine Healthcare Statutes",
              style: GoogleFonts.inter(fontSize: 12, color: textMuted, fontWeight: FontWeight.w500),
            ),
            const Divider(height: 28, color: borderNeutral),

            _buildLegalSection(
              "1. RA 10173: Data Privacy Act of 2012",
              "Tuberculosis logs, assessment diagnostics, and profile records are strictly treated as Sensitive Personal Information. TEREA employs database-level encapsulation to guarantee data isolation.",
            ),
            _buildLegalSection(
              "2. Data Minimization & Proportionality",
              "Our platform adheres to the proportionality principles of the National Privacy Commission (NPC). Users only interact with elements vital to their adherence. Row Level Security (RLS) restricts records away from unauthorized clients.",
            ),
            _buildLegalSection(
              "3. Patient Handshake Authorization",
              "A patient's diary is entirely invisible to a clinic provider until a direct handshake is performed by entering a unique Clinic Code. The patient maintains complete digital control over who oversees their lifecycle timeline.",
            ),
            _buildLegalSection(
              "4. Data Rights & Security Retention",
              "Patients hold the right to be informed and object to improper processing under the law. Regimen tracking data is held actively across the 6-month treatment lifecycle and safely archived once verified as 'Cured' by an authorized clinician.",
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryTeal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text(
                  isEnglish ? "Understand & Accept" : "Naiintindihan Ko",
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutTEREA(bool isEnglish) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 30),
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
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: primaryTeal.withOpacity(0.08), shape: BoxShape.circle),
                  child: const Icon(Icons.health_and_safety_rounded, color: primaryTeal, size: 24),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("About TEREA", style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: textCharcoal)),
                    Text("Version 1.0.0 (Clinical Care System)", style: GoogleFonts.inter(fontSize: 11.5, color: textMuted, fontWeight: FontWeight.w500)),
                  ],
                )
              ],
            ),
            const Divider(height: 30, color: borderNeutral),
            Text(
              "TEREA is designed as a localized medication adherence tracker and support utility for individuals navigating their Tuberculosis treatment journey.",
              style: GoogleFonts.inter(fontSize: 13, color: textCharcoal, height: 1.45, fontWeight: FontWeight.w400),
            ),
            const SizedBox(height: 14),
            _buildLegalSection(
              "RA 11332 Compliance Statement",
              "In strict adherence to the Law on Reporting of Notifiable Diseases (RA 11332), this platform does not replace, bypass, or conceal diagnostic cases from the Department of Health (DOH). It acts exclusively as a patient companion and healthcare worker monitoring tool. Mandated reporting to the national Integrated Tuberculosis Information System (ITIS) remains strictly executed by accredited institutional partners.",
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: borderNeutral, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  isEnglish ? "Close Window" : "Isara",
                  style: GoogleFonts.inter(color: textCharcoal, fontWeight: FontWeight.w600, fontSize: 13.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegalSection(String header, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(header, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: textCharcoal)),
          const SizedBox(height: 4),
          Text(body, style: GoogleFonts.inter(fontSize: 12, color: textMuted, height: 1.45)),
        ],
      ),
    );
  }

  // --- UI BUILD ---
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isEnglishNotifier,
      builder: (context, isEnglish, child) {
        return Scaffold(
          backgroundColor: backgroundSurface,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: textCharcoal, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              isEnglish ? 'Account & Preferences' : 'Mga Setting',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: textCharcoal, fontSize: 17),
            ),
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator(color: primaryTeal))
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  child: Column(
                    children: [
                      // Modern Profile Overview Card with Demographics
                      _buildModernProfileCard(isEnglish),

                      const SizedBox(height: 24),

                      // General Settings Group
                      _buildSettingsGroup(isEnglish ? "Personal Information" : "Impormasyon ng Pasyente", [
                        _buildSettingsTile(
                          Icons.manage_accounts_outlined,
                          isEnglish ? "Edit Profile & Demographics" : "I-edit ang Impormasyon",
                          subtext: isEnglish
                              ? "Update name, age, gender, residency & contact"
                              : "Pangalan, edad, kasarian, barangay, numero",
                          onTap: () => _showEditProfileModal(isEnglish),
                        ),
                        _buildSettingsTile(
                          Icons.translate_rounded,
                          isEnglish ? "App Language" : "Wika ng App",
                          subtext: isEnglish ? "English (Active)" : "Filipino (Aktibo)",
                          trailing: Switch(
                            value: isEnglishNotifier.value,
                            activeColor: primaryTeal,
                            activeTrackColor: primaryTeal.withOpacity(0.2),
                            inactiveThumbColor: Colors.white,
                            inactiveTrackColor: const Color(0xFFCBD5E1),
                            onChanged: (bool value) {
                              HapticFeedback.selectionClick();
                              isEnglishNotifier.value = value;
                            },
                          ),
                        ),
                      ]),

                      const SizedBox(height: 20),

                      // Legal & Support Group
                      _buildSettingsGroup(isEnglish ? "Compliance & Legal" : "Privacy at Suporta", [
                        _buildSettingsTile(
                          Icons.privacy_tip_outlined,
                          isEnglish ? "Privacy Policy (RA 10173)" : "Patakaran sa Privacy",
                          onTap: () => _showPrivacyPolicy(isEnglish),
                        ),
                        _buildSettingsTile(
                          Icons.info_outline_rounded,
                          isEnglish ? "About Platform (RA 11332)" : "Tungkol sa TEREA",
                          onTap: () => _showAboutTEREA(isEnglish),
                        ),
                      ]),

                      const SizedBox(height: 32),

                      // Sign Out Button (With Confirmation Dialog)
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: () => _showSignOutDialog(isEnglish),
                          icon: const Icon(Icons.logout_rounded, color: Color(0xFFDC2626), size: 18),
                          label: Text(
                            isEnglish ? "Sign Out of Account" : "Mag-log Out",
                            style: GoogleFonts.inter(
                              color: const Color(0xFFDC2626),
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFFECACA)),
                            backgroundColor: const Color(0xFFFEF2F2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
        );
      },
    );
  }

  // --- ENHANCED PROFILE CARD WITH DEMOGRAPHICS PREVIEW ---
  Widget _buildModernProfileCard(bool isEnglish) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderNeutral),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 10,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: primaryTeal.withOpacity(0.3), width: 1.5),
                    ),
                    child: CircleAvatar(
                      radius: 34,
                      backgroundColor: const Color(0xFFF1F5F9),
                      backgroundImage: _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
                      child: _avatarUrl == null ? const Icon(Icons.person_rounded, size: 36, color: textMuted) : null,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () => _uploadPhoto(isEnglish),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: primaryTeal,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt_rounded, size: 12, color: Colors.white),
                      ),
                    ),
                  )
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _username,
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: textCharcoal),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _email,
                      style: GoogleFonts.inter(color: textMuted, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: primaryTeal.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        "Brgy. $_barangay • Carmona",
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: primaryTeal,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),

          // Demographics quick chips row
          if (_age.isNotEmpty || _contactNumber.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(color: borderNeutral, height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                if (_age.isNotEmpty)
                  _buildProfileMetaChip(Icons.cake_outlined, "$_age yrs"),
                _buildProfileMetaChip(Icons.transgender_rounded, _gender),
                if (_contactNumber.isNotEmpty)
                  _buildProfileMetaChip(Icons.phone_outlined, _contactNumber),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProfileMetaChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: textMuted),
        const SizedBox(width: 5),
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 11.5,
            color: textCharcoal,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildModalFieldLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: textCharcoal,
      ),
    );
  }

  Widget _buildModalTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? formatters,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: inputBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderNeutral),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: formatters,
        style: GoogleFonts.inter(fontSize: 13.5, color: textCharcoal, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: textMuted, size: 18),
          hintText: hint,
          hintStyle: GoogleFonts.inter(color: Colors.black26, fontSize: 13),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(String title, List<Widget> tiles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 6, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: textMuted, letterSpacing: 1.0),
          ),
        ),
        Container(
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
          child: Column(
            children: List.generate(tiles.length, (index) {
              return Column(
                children: [
                  tiles[index],
                  if (index < tiles.length - 1)
                    const Divider(height: 1, color: borderNeutral, indent: 56, endIndent: 16),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, {String? subtext, Widget? trailing, VoidCallback? onTap}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDFA),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFCCFBF1)),
        ),
        child: Icon(icon, color: primaryTeal, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: textCharcoal, fontSize: 13.5),
      ),
      subtitle: subtext != null
          ? Text(subtext, style: GoogleFonts.inter(color: textMuted, fontSize: 11))
          : null,
      trailing: trailing ?? const Icon(Icons.chevron_right_rounded, color: textMuted, size: 20),
      onTap: onTap ?? () {},
    );
  }
}