import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';

class FacilitiesPage extends StatefulWidget {
  const FacilitiesPage({super.key});

  @override
  State<FacilitiesPage> createState() => _FacilitiesPageState();
}

class _FacilitiesPageState extends State<FacilitiesPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _facilities = [];

  // --- FORMAL CLINICAL COLOR SYSTEM ---
  static const Color primaryTeal = Color(0xFF0F766E);       // Deep Clinical Teal
  static const Color primaryDark = Color(0xFF115E59);       // Spruce Slate
  static const Color backgroundSurface = Color(0xFFF1F5F9); // Contrast Slate Background
  static const Color cardBg = Colors.white;                // Pure White Card
  static const Color textCharcoal = Color(0xFF0F172A);      // High Contrast Text
  static const Color textMuted = Color(0xFF64748B);         // Subdued Text
  static const Color borderNeutral = Color(0xFFE2E8F0);     // Structured Border

  @override
  void initState() {
    super.initState();
    _fetchFacilities();
  }

  // Fetch from the Admin-controlled Supabase table
  Future<void> _fetchFacilities() async {
    try {
      final data = await Supabase.instance.client
          .from('facilities')
          .select()
          .order('name', ascending: true);

      if (mounted) {
        setState(() {
          _facilities = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching facilities: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        _showNotificationPopup("Failed to load facilities: $e");
      }
    }
  }

  Future<void> _launchMaps(double lat, double lng) async {
    final String googleMapsUrl = "https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving";
    final Uri url = Uri.parse(googleMapsUrl);

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) _showNotificationPopup("Could not open the maps application.");
      }
    } catch (e) {
      debugPrint("Maps Error: $e");
    }
  }

  void _showNotificationPopup(String message) {
    HapticFeedback.mediumImpact();
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withOpacity(0.45),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) => const SizedBox.shrink(),
      transitionBuilder: (context, a1, a2, child) {
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
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626).withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error_outline_rounded,
                    color: Color(0xFFDC2626),
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "Notice",
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
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      "Acknowledge",
                      style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
          'Healthcare Facilities',
          style: GoogleFonts.inter(
            color: textCharcoal,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryTeal))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Institutional Guidance Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 14),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: borderNeutral),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primaryTeal.withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.location_on_outlined, color: primaryTeal, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Accredited Health Centers & Clinics",
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: textCharcoal,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "Tap 'Get Directions' to launch real-time GPS navigation to the clinic.",
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  color: textMuted,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                Expanded(
                  child: _facilities.isEmpty
                      ? Center(
                          child: Text(
                            "No clinical facilities listed yet.",
                            style: GoogleFonts.inter(color: textMuted, fontStyle: FontStyle.italic, fontSize: 13),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          itemCount: _facilities.length,
                          itemBuilder: (context, index) {
                            final facility = _facilities[index];
                            return _buildFacilityCard(facility);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildFacilityCard(Map<String, dynamic> facility) {
    final double lat = double.tryParse(facility['latitude'].toString()) ?? 0.0;
    final double lng = double.tryParse(facility['longitude'].toString()) ?? 0.0;

    List<dynamic> rawServices = facility['services'] ?? [];
    List<String> services = rawServices.map((e) => e.toString()).toList();

    bool isPublic = facility['ownership']?.toString().toLowerCase() == 'public';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  facility['name'] ?? 'Unknown Facility',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: textCharcoal,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isPublic ? const Color(0xFFF0FDFA) : const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isPublic ? const Color(0xFFCCFBF1) : const Color(0xFFFDE68A),
                  ),
                ),
                child: Text(
                  (facility['ownership'] ?? 'Public').toString().toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: isPublic ? primaryTeal : const Color(0xFFB45309),
                    letterSpacing: 0.4,
                  ),
                ),
              )
            ],
          ),
          const SizedBox(height: 4),
          Text(
            facility['category'] ?? 'Health Center',
            style: GoogleFonts.inter(color: primaryTeal, fontSize: 12.5, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),

          // Address
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_outlined, size: 16, color: textMuted),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  facility['address'] ?? 'No address provided',
                  style: GoogleFonts.inter(color: textMuted, fontSize: 12.5, height: 1.35),
                ),
              ),
            ],
          ),

          // Operating Hours & Contact
          if (facility['operating_hours'] != null || facility['contact_number'] != null) ...[
            const SizedBox(height: 8),
            if (facility['operating_hours'] != null)
              Row(
                children: [
                  const Icon(Icons.access_time_rounded, size: 16, color: textMuted),
                  const SizedBox(width: 8),
                  Text(
                    facility['operating_hours'],
                    style: GoogleFonts.inter(color: textMuted, fontSize: 12),
                  ),
                ],
              ),
            if (facility['contact_number'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Row(
                  children: [
                    const Icon(Icons.phone_outlined, size: 16, color: textMuted),
                    const SizedBox(width: 8),
                    Text(
                      facility['contact_number'],
                      style: GoogleFonts.inter(color: textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
          ],

          // Services Tags
          if (services.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: services.map((service) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDFA),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFCCFBF1)),
                ),
                child: Text(
                  service,
                  style: GoogleFonts.inter(fontSize: 10.5, color: primaryTeal, fontWeight: FontWeight.w600),
                ),
              )).toList(),
            ),
          ],

          const SizedBox(height: 16),

          // Direction Action Button
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.selectionClick();
                _launchMaps(lat, lng);
              },
              icon: const Icon(Icons.directions_outlined, color: Colors.white, size: 18),
              label: Text(
                "Get Directions",
                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13, letterSpacing: 0.2),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryTeal,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}