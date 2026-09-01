import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'shared_widgets.dart'; // REQUIRED to access isEnglishNotifier

// --- 9. SETTINGS PAGE ---
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _supabase = Supabase.instance.client;
  String _username = "Loading...";
  String _email = "";
  String? _avatarUrl;
  bool _isLoading = true;

  // Theme Palette
  final Color primaryGreen = const Color(0xFF2D3B1E); 
  final Color accentGreen = const Color(0xFF606C38);  
  final Color lightBg = const Color(0xFFF9F9F7);      
  final Color surfaceWhite = Colors.white;

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
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateUsername(bool isEnglish) async {
    final controller = TextEditingController(text: _username);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: surfaceWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(isEnglish ? "Update Username" : "I-update ang Pangalan", style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: isEnglish ? "Enter new username" : "Ilagay ang bagong pangalan",
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: accentGreen)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(isEnglish ? "Cancel" : "Kanselahin", style: TextStyle(color: Colors.grey[600]))),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                await _supabase.from('profiles').update({'full_name': newName}).eq('id', _supabase.auth.currentUser!.id);
                setState(() => _username = newName);
                if (mounted) Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: accentGreen, elevation: 0),
            child: Text(isEnglish ? "Save" : "I-save", style: const TextStyle(color: Colors.white)),
          )
        ],
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
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isEnglish ? "Uploading photo..." : "Ina-upload ang litrato...")));

        await _supabase.storage.from('avatars').uploadBinary(
          fileName,
          fileBytes,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
        );

        final String publicUrl = _supabase.storage.from('avatars').getPublicUrl(fileName);

        await _supabase.from('profiles').update({'avatar_url': publicUrl}).eq('id', userId);

        setState(() => _avatarUrl = publicUrl);
        
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isEnglish ? "Photo updated!" : "Na-update na ang litrato!")));
      }
    } catch (e) {
      debugPrint('Upload failed: $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isEnglish ? "Upload failed. Check Storage permissions." : "Bigo ang pag-upload.")));
    }
  }

  // --- LEGAL OVERLAYS ---
  void _showPrivacyPolicy(bool isEnglish) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: surfaceWhite,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.9,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 24),
            Text("Privacy Policy & Legal Framework", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: primaryGreen)),
            const SizedBox(height: 4),
            Text("In accordance with Philippine Healthcare Statutes", style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.bold)),
            const Divider(height: 30),
            
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
              "A patient’s diary is entirely invisible to a clinic provider until a direct handshake is performed by typing a unique Clinic Code. The patient maintains complete digital control over who oversees their lifecycle timeline.",
            ),
            _buildLegalSection(
              "4. Data Rights & Security Retention",
              "Patients hold the right to be informed and object to improper processing under the law. Regimen tracking data is held actively across the 6-month DOTS treatment lifecycle and safely archived once verified as 'Cured' by an authorized clinician.",
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: primaryGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), padding: const EdgeInsets.symmetric(vertical: 16)),
              child: Text(isEnglish ? "Understand & Accept" : "Naiintindihan Ko", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
      backgroundColor: surfaceWhite,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: accentGreen.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(Icons.health_and_safety_rounded, color: accentGreen, size: 30),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("About TEREA", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: primaryGreen)),
                    Text("Version 1.0.0 (Capstone Deployment)", style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500)),
                  ],
                )
              ],
            ),
            const Divider(height: 35),
            Text(
              "TEREA is designed as a localized medication adherence tracker and support utility for individuals navigating their Tuberculosis treatment journey.",
              style: TextStyle(fontSize: 14, color: primaryGreen, height: 1.4, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            _buildLegalSection(
              "RA 11332 Compliance Statement",
              "In strict adherence to the Law on Reporting of Notifiable Diseases (RA 11332), this platform does not replace, bypass, or conceal diagnostic cases from the Department of Health (DOH). It acts exclusively as a patient companion and Barangay Health Worker monitoring tool. Mandated reporting to the national Integrated Tuberculosis Information System (ITIS) remains strictly executed by accredited institutional partners.",
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(side: BorderSide(color: primaryGreen), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), padding: const EdgeInsets.symmetric(vertical: 16)),
                child: Text(isEnglish ? "Close Window" : "Isara", style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegalSection(String header, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(header, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: primaryGreen)),
          const SizedBox(height: 6),
          Text(body, style: TextStyle(fontSize: 13, color: Colors.grey[700], height: 1.4, fontWeight: FontWeight.w500)),
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
          backgroundColor: lightBg,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, color: primaryGreen, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(isEnglish ? 'Settings' : 'Mga Setting', style: TextStyle(fontWeight: FontWeight.w800, color: primaryGreen, fontSize: 20)),
          ),
          body: _isLoading 
            ? Center(child: CircularProgressIndicator(color: accentGreen))
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  children: [
                    _buildModernProfileCard(isEnglish),
                    const SizedBox(height: 30),
                    _buildSettingsGroup(isEnglish ? "General" : "Pangkalahatan", [
                      _buildSettingsTile(Icons.person_outline_rounded, isEnglish ? "Edit Username" : "I-edit ang Pangalan", onTap: () => _updateUsername(isEnglish)),
                      
                      // --- GLOBAL LANGUAGE TOGGLE ---
                      _buildSettingsTile(
                        Icons.language_rounded, 
                        isEnglish ? "Language" : "Wika", 
                        subtext: isEnglish ? "English" : "Filipino",
                        trailing: Switch(
                          value: isEnglishNotifier.value,
                          activeThumbColor: Colors.white,
                          activeTrackColor: accentGreen,
                          inactiveThumbColor: Colors.white,
                          inactiveTrackColor: Colors.grey.shade400,
                          onChanged: (bool value) {
                            // Update the global notifier
                            isEnglishNotifier.value = value;
                          },
                        ),
                      ),
                    ]),
                    const SizedBox(height: 25),
                    _buildSettingsGroup(isEnglish ? "Privacy & Support" : "Privacy at Suporta", [
                      _buildSettingsTile(Icons.lock_outline_rounded, isEnglish ? "Privacy Policy" : "Patakaran sa Privacy", onTap: () => _showPrivacyPolicy(isEnglish)),
                      _buildSettingsTile(Icons.info_outline_rounded, isEnglish ? "About TEREA" : "Tungkol sa TEREA", onTap: () => _showAboutTEREA(isEnglish)),
                    ]),
                    const SizedBox(height: 40),
                    _buildPrimaryButton(context, isEnglish ? "Log Out" : "Mag-log Out", () => Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false)),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
        );
      }
    );
  }

  Widget _buildModernProfileCard(bool isEnglish) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(color: accentGreen.withOpacity(0.2), shape: BoxShape.circle),
                child: CircleAvatar(
                  radius: 40, 
                  backgroundColor: lightBg,
                  backgroundImage: _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
                  child: _avatarUrl == null ? Icon(Icons.person_rounded, size: 45, color: accentGreen) : null,
                ),
              ),
              Positioned(
                bottom: 0, right: 0,
                child: GestureDetector(
                  onTap: () => _uploadPhoto(isEnglish),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: primaryGreen, 
                      shape: BoxShape.circle,
                      border: Border.all(color: surfaceWhite, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                  ),
                ),
              )
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_username, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: primaryGreen)),
                const SizedBox(height: 2),
                Text(_email, style: TextStyle(color: Colors.grey[500], fontSize: 13, fontWeight: FontWeight.w500)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSettingsGroup(String title, List<Widget> tiles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 10, bottom: 12),
          child: Text(title.toUpperCase(), 
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: accentGreen, letterSpacing: 1.5)),
        ),
        Container(
          decoration: BoxDecoration(
            color: surfaceWhite, 
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(children: tiles),
        ),
      ],
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, {String? subtext, Widget? trailing, VoidCallback? onTap}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: lightBg, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: accentGreen, size: 22),
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: primaryGreen, fontSize: 15)),
      subtitle: subtext != null ? Text(subtext, style: TextStyle(color: Colors.grey[400], fontSize: 12)) : null,
      trailing: trailing ?? Icon(Icons.chevron_right_rounded, color: Colors.grey[300]),
      onTap: onTap ?? () {},
    );
  }

  Widget _buildPrimaryButton(BuildContext context, String text, VoidCallback onTap) {
    return Container(
      width: double.infinity,
      height: 58,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(colors: [primaryGreen, accentGreen], begin: Alignment.topLeft, end: Alignment.bottomRight),
        boxShadow: [BoxShadow(color: accentGreen.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
      ),
    );
  }
}