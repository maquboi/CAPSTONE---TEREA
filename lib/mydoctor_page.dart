import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  // Colors adapted for the modern reference layout while keeping TEREA identity
  final Color _bgColor = const Color(0xFFF4F6F9); 
  final Color _primaryGreen = const Color(0xFF606C38);
  final Color _paleGreen = const Color(0xFFDDE5B6);

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
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0, top: 8.0, bottom: 8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ],
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black87, size: 20),
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.zero,
            ),
          ),
        ),
        title: const Text(
          'Doctor Detail',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w800,
            fontSize: 18,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: _primaryGreen));
    }

    if (_errorMessage != null) {
      return Center(child: Text("Error: $_errorMessage"));
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
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: _paleGreen.withOpacity(0.5), shape: BoxShape.circle),
              child: Icon(Icons.health_and_safety_outlined, size: 80, color: _primaryGreen),
            ),
            const SizedBox(height: 24),
            const Text("Not Yet Verified", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 12),
            const Text("You don't have an assigned doctor yet.", textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.black54)),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryGreen, 
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Text("Go Back", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorProfile() {
    final String fullName = _doctorData?['full_name'] ?? 'Unknown Doctor';
    final String email = _doctorData?['email'] ?? 'No email provided';
    final String phone = _doctorData?['phone_number'] ?? 'No phone provided';
    final String avatarUrl = _doctorData?['avatar_url'] ?? '';
    final String clinic = _doctorData?['clinic_name'] ?? 'Carmona TB DOTS Center';
    final String formattedName = fullName.startsWith('Dr.') ? fullName : 'Dr. $fullName';

    // Helper function to convert 24hr "17:00" to "5:00 PM" format
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
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04), 
                  blurRadius: 24, 
                  offset: const Offset(0, 8)
                )
              ],
            ),
            child: Column(
              children: [
                Container(
                  height: 240,
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: const Color(0xFFF8FAFC),
                    image: avatarUrl.isNotEmpty ? DecorationImage(image: NetworkImage(avatarUrl), fit: BoxFit.cover) : null,
                  ),
                  child: avatarUrl.isEmpty ? const Center(child: Icon(Icons.person, size: 80, color: Colors.black12)) : null,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Text(
                    formattedName, 
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.black87, letterSpacing: -0.5)
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Text("Contact & Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black87, letterSpacing: -0.5)),
          ),
          const SizedBox(height: 16),
          _buildDetailCard(statusText: 'Real-time', title: "Availability Hours", subtitle: availability, icon: Icons.access_time_rounded),
          const SizedBox(height: 12),
          _buildDetailCard(statusText: 'Primary Location', title: "Clinic Workspace", subtitle: clinic, icon: Icons.business_outlined),
          const SizedBox(height: 12),
          _buildDetailCard(statusText: 'Verified Contact', title: "Email Address", subtitle: email, icon: Icons.email_outlined),
          const SizedBox(height: 12),
          _buildDetailCard(statusText: 'Active', title: "Phone Number", subtitle: phone, icon: Icons.phone_outlined),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildDetailCard({required String statusText, required String title, required String subtitle, required IconData icon}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03), 
            blurRadius: 16, 
            offset: const Offset(0, 4)
          )
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _paleGreen.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(8)
                  ),
                  child: Text(statusText, style: TextStyle(color: _primaryGreen, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                ),
                const SizedBox(height: 12),
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87, letterSpacing: -0.3)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 14, color: Colors.black54, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(20)),
            child: Icon(icon, color: const Color(0xFF6A798A), size: 26),
          ),
        ],
      ),
    );
  }
}