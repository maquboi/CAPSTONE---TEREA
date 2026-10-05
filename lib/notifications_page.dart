import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  // --- FORMAL CLINICAL COLOR SYSTEM ---
  static const Color primaryTeal = Color(0xFF0F766E);       // Deep Clinical Teal
  static const Color backgroundSurface = Color(0xFFF1F5F9); // Contrast Slate Background
  static const Color cardBg = Colors.white;                // Pure White Card
  static const Color textCharcoal = Color(0xFF0F172A);      // High Contrast Text
  static const Color textMuted = Color(0xFF64748B);         // Subdued Text
  static const Color borderNeutral = Color(0xFFE2E8F0);     // Structured Border

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

      // 1. Fetch patient notifications
      final data = await Supabase.instance.client
          .from('notifications')
          .select('*')
          .eq('patient_id', userId)
          .eq('type', 'alert')
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
      backgroundColor: backgroundSurface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: textCharcoal, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Notifications",
          style: GoogleFonts.inter(
            color: textCharcoal,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryTeal))
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: primaryTeal.withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.notifications_none_rounded, size: 36, color: primaryTeal),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        "No Notifications",
                        style: GoogleFonts.inter(
                          color: textCharcoal,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Clinical reminders and adherence alerts will appear here.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(color: textMuted, fontSize: 13),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: primaryTeal,
                  onRefresh: _fetchNotifications,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final note = _notifications[index];
                      final isRead = note['is_read'] == true;
                      final date = DateTime.parse(note['created_at']).toLocal();

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isRead ? borderNeutral : primaryTeal.withOpacity(0.3),
                            width: isRead ? 1.0 : 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.015),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(9),
                                decoration: BoxDecoration(
                                  color: isRead
                                      ? const Color(0xFFF1F5F9)
                                      : const Color(0xFFF0FDFA),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isRead
                                        ? borderNeutral
                                        : const Color(0xFFCCFBF1),
                                  ),
                                ),
                                child: Icon(
                                  Icons.notifications_active_outlined,
                                  color: isRead ? textMuted : primaryTeal,
                                  size: 20,
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
                                            note['title'] ?? 'Clinical Alert',
                                            style: GoogleFonts.inter(
                                              fontWeight: isRead ? FontWeight.w600 : FontWeight.w700,
                                              fontSize: 14,
                                              color: textCharcoal,
                                            ),
                                          ),
                                        ),
                                        if (!isRead)
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: const BoxDecoration(
                                              color: primaryTeal,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      note['message'] ?? '',
                                      style: GoogleFonts.inter(
                                        fontSize: 12.5,
                                        color: isRead ? textMuted : const Color(0xFF334155),
                                        height: 1.4,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      "${date.month}/${date.day}/${date.year} • ${date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour)}:${date.minute.toString().padLeft(2, '0')} ${date.hour >= 12 ? 'PM' : 'AM'}",
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: textMuted.withOpacity(0.8),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
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