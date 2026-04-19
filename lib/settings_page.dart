import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';

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
  final Color primaryGreen = const Color(0xFF2D3B1E); // Dark Forest
  final Color accentGreen = const Color(0xFF606C38);  // Olive
  final Color lightBg = const Color(0xFFF9F9F7);      // Off-white background
  final Color surfaceWhite = Colors.white;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  // --- DATA LOGIC (Unchanged) ---
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

  Future<void> _updateUsername() async {
    final controller = TextEditingController(text: _username);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: surfaceWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text("Update Username", style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: "Enter new username",
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: accentGreen)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel", style: TextStyle(color: Colors.grey[600]))),
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
            child: const Text("Save", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  Future<void> _uploadPhoto() async {
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
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Uploading photo...")));

        await _supabase.storage.from('avatars').uploadBinary(
          fileName,
          fileBytes,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
        );

        final String publicUrl = _supabase.storage.from('avatars').getPublicUrl(fileName);

        await _supabase.from('profiles').update({'avatar_url': publicUrl}).eq('id', userId);

        setState(() => _avatarUrl = publicUrl);
        
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Photo updated!")));
      }
    } catch (e) {
      debugPrint('Upload failed: $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Upload failed. Check Storage permissions.")));
    }
  }

  // --- UI BUILD ---
  @override
  Widget build(BuildContext context) {
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
        title: Text('Settings', style: TextStyle(fontWeight: FontWeight.w800, color: primaryGreen, fontSize: 20)),
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator(color: accentGreen))
        : SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              children: [
                _buildModernProfileCard(),
                const SizedBox(height: 30),
                _buildSettingsGroup("General", [
                  _buildSettingsTile(Icons.person_outline_rounded, "Edit Username", onTap: _updateUsername),
                  _buildSettingsTile(Icons.notifications_none_rounded, "Notifications", 
                      trailing: Switch(
                        value: true, 
                        activeColor: Colors.white, 
                        activeTrackColor: accentGreen,
                        onChanged: (v){}
                      )),
                  _buildSettingsTile(Icons.language_rounded, "Language", subtext: "English"),
                ]),
                const SizedBox(height: 25),
                _buildSettingsGroup("Privacy & Support", [
                  _buildSettingsTile(Icons.lock_outline_rounded, "Privacy Policy"),
                  _buildSettingsTile(Icons.help_outline_rounded, "Help Center"),
                  _buildSettingsTile(Icons.info_outline_rounded, "About TEREA"),
                ]),
                const SizedBox(height: 40),
                _buildPrimaryButton(context, "Log Out", () => Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false)),
                const SizedBox(height: 20),
              ],
            ),
          ),
    );
  }

  Widget _buildModernProfileCard() {
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
                  onTap: _uploadPhoto,
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
