import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

// --- 7. FACILITIES PAGE (MAP + LIST) ---
class FacilitiesPage extends StatefulWidget {
  const FacilitiesPage({super.key});

  @override
  State<FacilitiesPage> createState() => _FacilitiesPageState();
}

class _FacilitiesPageState extends State<FacilitiesPage> {
  static const LatLng _carmonaCenter = LatLng(14.3135, 121.0574);
  late GoogleMapController mapController;

  // MARKERS: Polished coordinates for Carmona TB Centers
  final Set<Marker> _markers = {
    const Marker(
      markerId: MarkerId('rhu_dots'),
      position: LatLng(14.3121, 121.0558),
      infoWindow: InfoWindow(title: 'Rural Health Unit (RHU)', snippet: 'Primary TB-DOTS Center'),
    ),
    const Marker(
      markerId: MarkerId('super_health'),
      position: LatLng(14.3145, 121.0620),
      infoWindow: InfoWindow(title: 'Super Health Center', snippet: 'Primary Care'),
    ),
    const Marker(
      markerId: MarkerId('hospital_medical'),
      position: LatLng(14.3015, 121.0485),
      infoWindow: InfoWindow(title: 'Carmona Hospital & Medical Center', snippet: 'Diagnostics'),
    ),
    const Marker(
      markerId: MarkerId('pagamutang_bayan'),
      position: LatLng(14.3072, 121.0423),
      infoWindow: InfoWindow(title: 'Pagamutang Bayan ng Carmona', snippet: 'Public Hospital'),
    ),
  };

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  // FIXED: Standard Google Maps URL Scheme for Directions
  Future<void> _launchMaps(double lat, double lng) async {
    final String googleMapsUrl = "https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving";
    final Uri url = Uri.parse(googleMapsUrl);

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint("Maps Error: $e");
    }
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
      body: Column(
        children: [
          // MAP SECTION
          SizedBox(
            height: 300,
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: const CameraPosition(target: _carmonaCenter, zoom: 14),
              markers: _markers,
              myLocationButtonEnabled: true,
              zoomControlsEnabled: true,
            ),
          ),
          
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("Official TB Centers and Hospitals in Carmona.", 
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: forestDark)),
          ),
          
          // LIST SECTION
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              children: [
                _buildFacilityCard('Rural Health Unit (RHU)', 'Primary TB-DOTS Center', 'J.M. Loyola St., Brgy. 4', '14.3121', '121.0558'),
                _buildFacilityCard('Super Health Center', 'Primary Care & Consultation', 'Carmona City (New Facility)', '14.3145', '121.0620'),
                _buildFacilityCard('Hospital & Medical Center', 'Private Referral / Diagnostics', 'Sugar Road, Brgy. Maduya', '14.3015', '121.0485'),
                _buildFacilityCard('Pagamutang Bayan ng Carmona', 'Public Hospital Support', 'Brgy. Mabuhay', '14.3072', '121.0423'),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(3, context),
    );
  }

  Widget _buildFacilityCard(String name, String type, String addr, String lat, String lng) {
    const Color forestMed = Color(0xFF606C38);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text(type, style: const TextStyle(color: forestMed, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 5),
          Text(addr, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _launchMaps(double.parse(lat), double.parse(lng)),
              icon: const Icon(Icons.directions, color: Colors.white),
              label: const Text("Directions", style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: forestMed, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(int index, BuildContext context) {
    return BottomNavigationBar(
      currentIndex: index,
      selectedItemColor: const Color(0xFF283618),
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.medication_rounded), label: 'Meds'),
        BottomNavigationBarItem(icon: Icon(Icons.calendar_month_rounded), label: 'Follow-up'),
        BottomNavigationBarItem(icon: Icon(Icons.map_rounded), label: 'Facilities'),
      ],
      onTap: (i) {
        if (i == 0) Navigator.pushReplacementNamed(context, '/dashboard');
      },
    );
  }
}


