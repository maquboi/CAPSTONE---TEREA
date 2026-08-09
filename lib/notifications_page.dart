import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool _isLoading = true;
  List<dynamic> _notifications = [];

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      // 1. Fetch the history from Supabase (Filtered ONLY for Patient Alerts)
      final data = await Supabase.instance.client
          .from('notifications')
          .select('*')
          .eq('patient_id', userId)
          .eq('type', 'alert') // <-- THE FIX: Ignore 'request' types meant for doctors
          .order('created_at', ascending: false);

      setState(() {
        _notifications = data;
      });

      // 2. Automatically mark unread notifications as "read"
      final unreadIds = data
          .where((n) => n['is_read'] == false)
          .map((n) => n['id'])
          .toList();

      if (unreadIds.isNotEmpty) {
        await Supabase.instance.client
            .from('notifications')
            .update({'is_read': true})
            .inFilter('id', unreadIds);
      }
    } catch (e) {
      debugPrint("Error fetching notifications: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEFAE0),
      appBar: AppBar(
        backgroundColor: const Color(0xFF606C38),
        title: Text(
          "Notifications",
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF606C38)))
          : _notifications.isEmpty
              ? Center(
                  child: Text(
                    "No notifications yet.",
                    style: GoogleFonts.poppins(color: Colors.black54, fontSize: 16),
                  ),
                )
              : RefreshIndicator(
                  color: const Color(0xFF606C38),
                  onRefresh: _fetchNotifications,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final note = _notifications[index];
                      final isRead = note['is_read'] == true;
                      final date = DateTime.parse(note['created_at']).toLocal();
                      
                      return Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Colors.black.withOpacity(0.05)),
                        ),
                        color: isRead ? Colors.white : const Color(0xFFF4F7F4),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF606C38).withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.notifications_active_rounded, color: Color(0xFF606C38)),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      note['title'] ?? 'Alert',
                                      style: GoogleFonts.poppins(
                                        fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                                        fontSize: 15,
                                        color: const Color(0xFF2D3B1E),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      note['message'] ?? '',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      "${date.month}/${date.day}/${date.year} at ${date.hour > 12 ? date.hour - 12 : date.hour}:${date.minute.toString().padLeft(2, '0')} ${date.hour >= 12 ? 'PM' : 'AM'}",
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: Colors.black45,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (!isRead)
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: Colors.redAccent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}