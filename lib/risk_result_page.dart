import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// --- 10. RISK RESULT PAGE ---
class RiskResultPage extends StatefulWidget {
  const RiskResultPage({super.key});

  @override
  State<RiskResultPage> createState() => _RiskResultPageState();
}

class _RiskResultPageState extends State<RiskResultPage> {
  // Theme Palette
  final Color primaryGreen = const Color(0xFF2D3B1E);
  final Color accentGreen = const Color(0xFF606C38);
  final Color lightBg = const Color(0xFFF9F9F7);
  final Color surfaceWhite = Colors.white;

  final _supabase = Supabase.instance.client;
  bool _hasSaved = false; // Prevent double saving

  @override
  void initState() {
    super.initState();
  }

  Future<void> _saveToHistory(int score, String risk) async {
    if (_hasSaved) return; // Prevent duplicates in this session
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        await _supabase.from('assessment_history').insert({
          'user_id': user.id,
          'score': score,
          'risk_level': risk,
        });
        setState(() {
          _hasSaved = true;
        });
      }
    } catch (e) {
      debugPrint("DB Error: $e");
    }
  }

  Future<void> _generatePdf(int score, String label) async {
    final pdf = pw.Document();
    pdf.addPage(pw.Page(
      build: (pw.Context context) => pw.Center(
        child: pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Text("TB Assessment Report",
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 20),
            pw.Text("Result: $label"),
            pw.Text("Score: $score"),
            pw.Text("Date: ${DateTime.now().toString().split(' ')[0]}"),
            pw.SizedBox(height: 30),
            pw.Text("Note: This is a screening tool, not a clinical diagnosis.",
                style: const pw.TextStyle(fontSize: 10)),
          ],
        ),
      ),
    ));
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  // Helper for dynamic recommendations
  Map<String, String> _getRecommendation(String risk) {
    switch (risk) {
      case "HIGH RISK":
        return {
          "title": "Immediate Action Required",
          "desc": "Please visit your nearest health center for a GeneXpert/Sputum test immediately."
        };
      case "MEDIUM RISK":
        return {
          "title": "Consultation Advised",
          "desc": "Schedule a check-up with a doctor to discuss your persistent symptoms."
        };
      default:
        return {
          "title": "Stay Vigilant",
          "desc": "Continue to monitor your health and maintain a healthy lifestyle."
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final int score = (ModalRoute.of(context)!.settings.arguments as int? ?? 0);
    String riskLabel = score >= 12 ? "HIGH RISK" : (score >= 6 ? "MEDIUM RISK" : "LOW RISK");
    Color riskColor = score >= 12
        ? const Color(0xFFD9534F) // Red for High
        : (score >= 6 ? const Color(0xFFBC6C25) : const Color(0xFF606C38)); // Orange for Med, Green for Low

    // Define Logic Flags based on Risk
    bool showFacilitiesBtn = (riskLabel == "HIGH RISK" || riskLabel == "MEDIUM RISK");

    final rec = _getRecommendation(riskLabel);

    return Scaffold(
      backgroundColor: lightBg,
      body: Stack(
        children: [
          // Background Blobs
          Positioned.fill(
            child: CustomPaint(
              painter: BlobPainter(color: accentGreen.withOpacity(0.05)),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
              child: Column(
                children: [
                  // App Bar Area
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Assessment Result",
                          style: TextStyle(
                              color: primaryGreen,
                              fontWeight: FontWeight.bold,
                              fontSize: 18)),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // Detailed Result Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: surfaceWhite,
                      borderRadius: BorderRadius.circular(35),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 30,
                            offset: const Offset(0, 15))
                      ],
                    ),
                    child: Column(
                      children: [
                        // Animated Icon Container
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: riskColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.health_and_safety_rounded,
                              size: 70, color: riskColor),
                        ),
                        const SizedBox(height: 25),
                        Text(riskLabel,
                            style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                                color: riskColor,
                                letterSpacing: 1.2)),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: lightBg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text("Total Score: $score",
                              style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: primaryGreen,
                                  fontSize: 15)),
                        ),
                        const SizedBox(height: 25),
                        
                        // Suggestion Block
                        Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: riskColor.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: riskColor.withOpacity(0.2)),
                          ),
                          child: Column(
                            children: [
                              Text(rec["title"]!, 
                                  style: TextStyle(fontWeight: FontWeight.bold, color: riskColor)),
                              const SizedBox(height: 5),
                              Text(rec["desc"]!, 
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 13, color: primaryGreen.withOpacity(0.8))),
                            ],
                          ),
                        ),

                        const SizedBox(height: 25),
                        Divider(color: Colors.grey.withOpacity(0.2)),
                        const SizedBox(height: 20),
                        Text(
                          "This assessment is based on your reported symptoms. Please consult a qualified healthcare professional for a formal medical diagnosis.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.grey[600],
                              height: 1.5,
                              fontSize: 12,
                              fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Share/PDF Row
                  Row(
                    children: [
                      Expanded(
                          child: _actionBtn(Icons.share_rounded, "Share",
                              () => Share.share("My TB Risk is $riskLabel (Score: $score)"))),
                      const SizedBox(width: 15),
                      Expanded(
                          child: _actionBtn(Icons.picture_as_pdf_rounded, "Save PDF",
                              () => _generatePdf(score, riskLabel))),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // --- CONDITIONAL BUTTON LOGIC ---
                  
                  // 1. View Nearby Facilities (Only for High/Medium Risk)
                  if (showFacilitiesBtn) ...[
                    _primaryBtn("View Nearby Facilities", () async {
                      await _saveToHistory(score, riskLabel);
                      Navigator.pushNamed(context, '/facilities');
                    }),
                    const SizedBox(height: 15),
                  ],

                  // 2. Retake Assessment (Visible for ALL risks)
                  _primaryBtn("Retake Assessment", () {
                    Navigator.pushReplacementNamed(context, '/assess');
                  }),

                  const SizedBox(height: 15),

                  // 3. Return to Dashboard (Visible for ALL risks)
                  _primaryBtn("Return to Dashboard", () async {
                    await _saveToHistory(score, riskLabel);
                    Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (r) => false);
                  }),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: surfaceWhite,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black.withOpacity(0.05)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: accentGreen, size: 20),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    color: primaryGreen, fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  // Unified Button Style: Gradient Green Background, White Text
  Widget _primaryBtn(String text, VoidCallback onTap) {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryGreen, accentGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: accentGreen.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8))
        ],
      ),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: Text(text,
            style: const TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

// Custom Painter for Background Blobs
class BlobPainter extends CustomPainter {
  final Color color;
  BlobPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;

    // Top Right Blob
    canvas.drawCircle(Offset(size.width * 0.9, size.height * 0.1), 150, paint);

    // Bottom Left Blob
    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.8), 200, paint);

    // Small Center Blob
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.5), 80, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}