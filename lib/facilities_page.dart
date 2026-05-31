import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class FacilitiesPage extends StatefulWidget {
  const FacilitiesPage({super.key});

  @override
  State<FacilitiesPage> createState() => _FacilitiesPageState();
}

class _FacilitiesPageState extends State<FacilitiesPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _facilities = [];

  @override
  void initState() {
    super.initState();
    _fetchFacilities();
  }

  // Fetch from the new Admin-controlled Supabase table
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

  // --- MODERN CENTERED POPUP ANIMATION ---
  void _showNotificationPopup(String message) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withOpacity(0.4),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) => const SizedBox.shrink(),
      transitionBuilder: (context, a1, a2, child) {
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
                      color: Colors.redAccent.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.error_outline_rounded,
                      color: Colors.redAccent,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Notice",
                    style: TextStyle(
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

  @override
  Widget build(BuildContext context) {
    const Color forestDark = Color(0xFF283618);
    const Color forestMed = Color(0xFF606C38);
    
    return Scaffold(
      backgroundColor: const Color(0xFFFEFAE0),
      appBar: AppBar(
        title: const Text('Nearby Facilities', style: TextStyle(color: forestDark, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: forestDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: forestMed))
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 10, 20, 15),
                child: Text(
                  "Official TB Centers and Hospitals. Tap 'Get Directions' to open your maps application for live routing.", 
                  style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: forestDark, height: 1.4)
                ),
              ),
              
              Expanded(
                child: _facilities.isEmpty 
                  ? const Center(child: Text("No facilities have been added by the admin yet.", style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
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
    const Color forestMed = Color(0xFF606C38);
    const Color forestDark = Color(0xFF283618);
    
    final double lat = double.tryParse(facility['latitude'].toString()) ?? 0.0;
    final double lng = double.tryParse(facility['longitude'].toString()) ?? 0.0;
    
    List<dynamic> rawServices = facility['services'] ?? [];
    List<String> services = rawServices.map((e) => e.toString()).toList();
    
    bool isPublic = facility['ownership']?.toString().toLowerCase() == 'public';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(facility['name'] ?? 'Unknown Facility', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: forestDark))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isPublic ? Colors.blue.shade50 : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8)
                ),
                child: Text(
                  facility['ownership'] ?? 'Unknown', 
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isPublic ? Colors.blue.shade700 : Colors.orange.shade800)
                ),
              )
            ],
          ),
          const SizedBox(height: 6),
          Text(facility['category'] ?? 'General', style: const TextStyle(color: forestMed, fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_rounded, size: 16, color: Colors.grey),
              const SizedBox(width: 6),
              Expanded(child: Text(facility['address'] ?? 'No address provided', style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.3))),
            ],
          ),
          
          if (facility['operating_hours'] != null || facility['contact_number'] != null) ...[
            const SizedBox(height: 8),
            if (facility['operating_hours'] != null)
              Row(
                children: [
                  const Icon(Icons.access_time_rounded, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(facility['operating_hours'], style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            if (facility['contact_number'] != null)
              Row(
                children: [
                  const Icon(Icons.phone_rounded, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(facility['contact_number'], style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
          ],
          
          if (services.isNotEmpty) ...[
            const SizedBox(height: 15),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: services.map((service) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFFEFAE0), borderRadius: BorderRadius.circular(6)),
                child: Text(service, style: const TextStyle(fontSize: 10, color: forestDark, fontWeight: FontWeight.w600)),
              )).toList(),
            ),
          ],

          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _launchMaps(lat, lng),
              icon: const Icon(Icons.directions_rounded, color: Colors.white, size: 20),
              label: const Text("Get Directions", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              style: ElevatedButton.styleFrom(
                backgroundColor: forestMed, 
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}