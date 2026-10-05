import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

// --- 10. RISK RESULT & CLINICAL REFERRAL PAGE ---
class RiskResultPage extends StatefulWidget {
  const RiskResultPage({super.key});

  @override
  State<RiskResultPage> createState() => _RiskResultPageState();
}

class _RiskResultPageState extends State<RiskResultPage> {
  final _supabase = Supabase.instance.client;
  bool _hasSaved = false;

  // Patient & Doctor Profile Data
  String _patientName = "Patient";
  String _patientAge = "";
  String _patientGender = "";
  String _patientBarangay = "Carmona";
  String _patientContact = "";
  String _userId = "";
  String? _doctorName;
  bool _isProfileLoading = true;

  // --- REASSURING CLINICAL COLOR SYSTEM ---
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
    _initializeUserDefaults();
    _fetchClinicalData();
  }

  // Pre-populates safe defaults from session before network request finishes
  void _initializeUserDefaults() {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      _userId = user.id;
      if (user.userMetadata != null && user.userMetadata!['full_name'] != null) {
        _patientName = _sanitize(user.userMetadata!['full_name'], "Patient");
      } else if (user.email != null && user.email!.isNotEmpty) {
        final prefix = user.email!.split('@').first;
        _patientName = prefix.isNotEmpty
            ? "${prefix[0].toUpperCase()}${prefix.substring(1)}"
            : "Patient";
      }
    }
  }

  // Sanitizes against null, empty, or literal "undefined" / "null" strings
  String _sanitize(dynamic val, String fallback) {
    if (val == null) return fallback;
    final s = val.toString().trim();
    if (s.isEmpty ||
        s.toLowerCase() == 'undefined' ||
        s.toLowerCase() == 'null' ||
        s.toLowerCase() == 'n/a') {
      return fallback;
    }
    return s;
  }

  // Prevents duplicate "Dr. Dr." prefixes
  String _formatDoctorName(String? name) {
    if (name == null || name.trim().isEmpty) return "Carmona Health Center Triage";
    final clean = name.trim().replaceFirst(RegExp(r'^(dr\.?\s*)+', caseSensitive: false), '');
    return "Dr. $clean";
  }

  Future<void> _fetchClinicalData() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        _userId = user.id;

        // 1. Fetch Patient Profile
        final profileData = await _supabase
            .from('profiles')
            .select('full_name, age, gender, barangay, contact_number')
            .eq('id', user.id)
            .maybeSingle();

        // 2. Safely Fetch Active Doctor Connection
        String? foundDoctor;
        try {
          final connectionData = await _supabase
              .from('connections')
              .select('doctor_id')
              .eq('patient_id', user.id)
              .eq('status', 'active')
              .maybeSingle();

          if (connectionData != null && connectionData['doctor_id'] != null) {
            final docProfile = await _supabase
                .from('profiles')
                .select('full_name')
                .eq('id', connectionData['doctor_id'])
                .maybeSingle();
            if (docProfile != null) {
              foundDoctor = _sanitize(docProfile['full_name'], "");
            }
          }
        } catch (e) {
          debugPrint("Doctor connection fetch error: $e");
        }

        if (mounted) {
          setState(() {
            if (profileData != null) {
              _patientName = _sanitize(profileData['full_name'], _patientName);
              _patientAge = _sanitize(profileData['age'], "");
              _patientGender = _sanitize(profileData['gender'], "");
              _patientBarangay = _sanitize(profileData['barangay'], "Carmona");
              _patientContact = _sanitize(profileData['contact_number'], "");
            }

            if (foundDoctor != null && foundDoctor.isNotEmpty) {
              _doctorName = foundDoctor;
            }

            _isProfileLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching result context: $e");
      if (mounted) setState(() => _isProfileLoading = false);
    }
  }

  Future<void> _saveToHistory(int score, String risk) async {
    if (_hasSaved) return;
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

  // --- REASSURING, PROFESSIONAL REFERRAL SLIP PDF GENERATOR ---
  Future<void> _generatePdf(String label) async {
    try {
      final pdf = pw.Document();
      final String currentDate = DateFormat('MMMM dd, yyyy').format(DateTime.now());
      final String safePatientName = _sanitize(_patientName, "Patient");
      final String safeBarangay = _sanitize(_patientBarangay, "Carmona");
      final String safeAge = _sanitize(_patientAge, "Not specified");
      final String safeGender = _sanitize(_patientGender, "Not specified");
      final String safeContact = _sanitize(_patientContact, "None on record");
      final String safeDoctor = _formatDoctorName(_doctorName);
      final String safePatientId = _userId.isNotEmpty
          ? (_userId.length >= 8 ? _userId.substring(0, 8).toUpperCase() : _userId)
          : "PENDING";

      // Safe Non-const Integer Colors
      const PdfColor brandTeal = PdfColor.fromInt(0xFF0F766E);
      const PdfColor darkSlate = PdfColor.fromInt(0xFF0F172A);
      const PdfColor mutedSlate = PdfColor.fromInt(0xFF64748B);
      const PdfColor borderGrey = PdfColor.fromInt(0xFFCBD5E1);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(36),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // 1. Institutional Header
                pw.Container(
                  padding: const pw.EdgeInsets.only(bottom: 12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border(bottom: pw.BorderSide(color: brandTeal, width: 2)),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            "REPUBLIC OF THE PHILIPPINES",
                            style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: mutedSlate),
                          ),
                          pw.Text(
                            "PROVINCE OF CAVITE - CITY OF CARMONA",
                            style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: mutedSlate),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            "CARMONA CITY HEALTH OFFICE",
                            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: darkSlate),
                          ),
                          pw.Text(
                            "National Tuberculosis Control Program (NTP) Clinical Intake",
                            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                          ),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            "TEREA HEALTHCARE",
                            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: brandTeal),
                          ),
                          pw.Text(
                            "Form NTP-01 Clinical Companion",
                            style: const pw.TextStyle(fontSize: 8.5, color: mutedSlate),
                          ),
                          pw.Text(
                            "Issued: $currentDate",
                            style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: darkSlate),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 14),

                // Title Badge
                pw.Center(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: pw.BoxDecoration(
                      color: const PdfColor.fromInt(0xFFF1F5F9),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                    ),
                    child: pw.Text(
                      "CLINICAL SCREENING SUMMARY & HEALTH CENTER REFERRAL SLIP",
                      style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: darkSlate),
                    ),
                  ),
                ),
                pw.SizedBox(height: 14),

                // 2. Patient Demographics Grid
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: borderGrey, width: 0.8),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Row(
                        children: [
                          pw.Expanded(
                            flex: 3,
                            child: _buildPdfMetaItem("PATIENT FULL NAME", safePatientName, darkSlate),
                          ),
                          pw.Expanded(
                            flex: 2,
                            child: _buildPdfMetaItem("PATIENT ID", safePatientId, brandTeal),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 8),
                      pw.Row(
                        children: [
                          pw.Expanded(
                            child: _buildPdfMetaItem("AGE / GENDER", "$safeAge | $safeGender", darkSlate),
                          ),
                          pw.Expanded(
                            child: _buildPdfMetaItem("BARANGAY RESIDENCY", "Brgy. $safeBarangay, Carmona", darkSlate),
                          ),
                          pw.Expanded(
                            child: _buildPdfMetaItem("CONTACT NUMBER", safeContact, darkSlate),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 14),

                // 3. Clinical Recommendation Box (No numerical score)
                pw.Container(
                  padding: const pw.EdgeInsets.all(14),
                  decoration: pw.BoxDecoration(
                    color: const PdfColor.fromInt(0xFFF0FDFA),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                    border: pw.Border.all(color: const PdfColor.fromInt(0xFF99F6E4), width: 1),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            "EVALUATION STATUS",
                            style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: brandTeal),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            label.toUpperCase(),
                            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: darkSlate),
                          ),
                        ],
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.white,
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                          border: pw.Border.all(color: borderGrey, width: 0.5),
                        ),
                        child: pw.Text(
                          "ASSESSMENT COMPLETE",
                          style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: brandTeal),
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 14),

                // 4. Clinical Referral Protocol & Orders
                pw.Text(
                  "RECOMMENDED CLINICAL MANAGEMENT PROTOCOL",
                  style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: darkSlate),
                ),
                pw.SizedBox(height: 6),
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: borderGrey, width: 0.8),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildPdfOrderRow(
                        "Diagnostic Sputum Evaluation:",
                        "Direct Sputum Smear Microscopy (DSSM) or GeneXpert MTB/RIF analysis at Carmona Health Center laboratory.",
                      ),
                      pw.SizedBox(height: 6),
                      _buildPdfOrderRow(
                        "Radiological Examination:",
                        "Standard Posteroanterior (PA) Chest Radiograph if clinically indicated by attending medical officer.",
                      ),
                      pw.SizedBox(height: 6),
                      _buildPdfOrderRow(
                        "Contact Investigation:",
                        "Household and close workplace contacts may undergo symptom screening in accordance with DOH NTP Circulars.",
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 14),

                // 5. Attending Clinician / Endorsement
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(10),
                        decoration: pw.BoxDecoration(
                          color: const PdfColor.fromInt(0xFFF8FAFC),
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                          border: pw.Border.all(color: borderGrey, width: 0.6),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text("ATTENDING CLINICIAN / FACILITY", style: pw.TextStyle(fontSize: 7.5, color: mutedSlate, fontWeight: pw.FontWeight.bold)),
                            pw.SizedBox(height: 2),
                            pw.Text(safeDoctor, style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold, color: darkSlate)),
                            pw.Text("Carmona Health Center - Main Clinical Desk", style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                          ],
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 14),
                    pw.Expanded(
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(10),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: borderGrey, width: 0.6),
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.center,
                          children: [
                            pw.SizedBox(height: 16),
                            pw.Container(height: 1, color: borderGrey),
                            pw.SizedBox(height: 4),
                            pw.Text("Clinician Signature & License Stamp", style: const pw.TextStyle(fontSize: 7.5, color: mutedSlate)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                pw.Spacer(),

                // 6. Legal & Statutory Footer
                pw.Container(
                  padding: const pw.EdgeInsets.only(top: 8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border(top: pw.BorderSide(color: borderGrey, width: 0.5)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        "STATUTORY LEGAL NOTICE (R.A. 10173 & R.A. 11332):",
                        style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: darkSlate),
                      ),
                      pw.Text(
                        "This document contains protected health information (PHI) governed by the Data Privacy Act of 2012. Under RA 11332, this screening serves as a public health intake instrument and does not substitute for a formal laboratory diagnosis.",
                        style: const pw.TextStyle(fontSize: 6.8, color: mutedSlate, height: 1.3),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (format) async => pdf.save(),
        name: "TEREA_Referral_${safePatientId}.pdf",
      );
    } catch (e) {
      debugPrint("PDF Generation Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to generate PDF document: $e", style: GoogleFonts.inter(fontSize: 12)),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  pw.Widget _buildPdfMetaItem(String label, String value, PdfColor textColor) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 7.5, color: PdfColor.fromInt(0xFF64748B), fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 1),
        pw.Text(value, style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: textColor)),
      ],
    );
  }

  pw.Widget _buildPdfOrderRow(String title, String desc) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: 4,
          height: 4,
          margin: const pw.EdgeInsets.only(top: 3.5, right: 6),
          decoration: const pw.BoxDecoration(color: PdfColors.black, shape: pw.BoxShape.circle),
        ),
        pw.Expanded(
          child: pw.RichText(
            text: pw.TextSpan(
              children: [
                pw.TextSpan(text: "$title ", style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF0F172A))),
                pw.TextSpan(text: desc, style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey800)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Reassuring, non-alarming clinical guidance
  Map<String, String> _getRecommendation(String risk) {
    switch (risk) {
      case "Consultation Recommended":
        return {
          "title": "Clinical Consultation Recommended",
          "desc": "Based on your self-reported responses, visiting Carmona Health Center for an evaluation is recommended. Remember: Tuberculosis is completely preventable and curable. A quick health check will give you peace of mind and appropriate medical guidance."
        };
      case "Routine Checkup Advised":
        return {
          "title": "Routine Checkup Advised",
          "desc": "You have noted persistent symptoms or shared exposure. Scheduling a routine consultation with your health center doctor will help evaluate if any general care is needed."
        };
      default:
        return {
          "title": "Routine Health Surveillance",
          "desc": "Your reported indicators currently reflect low clinical concern. Continue practicing good respiratory hygiene, maintain a balanced diet, and feel free to retake this screening if you ever develop a persistent cough."
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final int score = (ModalRoute.of(context)!.settings.arguments as int? ?? 0);

    // Reassuring, anti-panic labels
    String riskLabel = score >= 12
        ? "Consultation Recommended"
        : (score >= 6 ? "Routine Checkup Advised" : "Routine Health Monitoring");

    // Unified, calm clinical palette
    Color riskColor = primaryTeal;
    Color riskBg = const Color(0xFFF0FDFA);
    Color riskBorder = const Color(0xFFCCFBF1);
    IconData riskIcon = Icons.health_and_safety_outlined;

    if (score >= 12) {
      riskColor = const Color(0xFF0F766E); // Calm deep teal
      riskBg = const Color(0xFFF0FDFA);
      riskBorder = const Color(0xFF99F6E4);
      riskIcon = Icons.medical_services_outlined;
    } else if (score >= 6) {
      riskColor = const Color(0xFF0284C7); // Soft clinical blue
      riskBg = const Color(0xFFF0F9FF);
      riskBorder = const Color(0xFFBAE6FD);
      riskIcon = Icons.fact_check_outlined;
    } else {
      riskColor = primaryTeal;
      riskBg = const Color(0xFFF0FDFA);
      riskBorder = const Color(0xFFCCFBF1);
      riskIcon = Icons.verified_outlined;
    }

    bool showFacilitiesBtn = (score >= 6);
    final rec = _getRecommendation(riskLabel);

    return Scaffold(
      backgroundColor: backgroundSurface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text(
          "Triage Summary",
          style: GoogleFonts.inter(
            color: textCharcoal,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          child: Column(
            children: [
              // Main Clinical Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderNeutral),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Institutional Header Tag
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: primaryTeal.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: primaryTeal.withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.local_hospital_rounded, color: primaryTeal, size: 13),
                          const SizedBox(width: 6),
                          Text(
                            "Carmona Health Center - Health Screening Companion",
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: primaryTeal,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Non-alarming Medical Icon Box
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: riskBg,
                        shape: BoxShape.circle,
                        border: Border.all(color: riskBorder, width: 1.5),
                      ),
                      child: Icon(riskIcon, size: 44, color: riskColor),
                    ),
                    const SizedBox(height: 16),

                    // Reassuring Label
                    Text(
                      riskLabel,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        color: textCharcoal,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Calming Status Pill (No exam scores)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: backgroundSurface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "Assessment Completed - Protocol Evaluated",
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: textMuted,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Patient Details Strip (With robust sanitization)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: backgroundSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderNeutral),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  "Patient: $_patientName",
                                  style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700, color: textCharcoal),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                "Brgy. $_patientBarangay",
                                style: GoogleFonts.inter(fontSize: 11.5, color: textMuted, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                          if (_doctorName != null && _doctorName!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.verified_user_rounded, color: primaryTeal, size: 13),
                                const SizedBox(width: 4),
                                Text(
                                  "Attending: ${_formatDoctorName(_doctorName)}",
                                  style: GoogleFonts.inter(fontSize: 11, color: primaryTeal, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Recommendation Box
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: riskBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: riskBorder, width: 1.2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.assignment_turned_in_outlined, size: 16, color: riskColor),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  rec["title"]!,
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w700,
                                    color: textCharcoal,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            rec["desc"]!,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF334155),
                              height: 1.45,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                    const Divider(color: borderNeutral, height: 1),
                    const SizedBox(height: 14),

                    // Reassuring Guidance Disclaimer
                    Text(
                      "This screening is a supportive companion to connect you with Carmona health center workers. It does not replace a doctor's formal evaluation.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: textMuted,
                        height: 1.45,
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Export Actions (Share & Official PDF)
              Row(
                children: [
                  Expanded(
                    child: _actionButton(
                      icon: Icons.share_outlined,
                      label: "Share Summary",
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Share.share("My Tuberculosis Screening Result: $riskLabel - Carmona Health Center");
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _actionButton(
                      icon: Icons.picture_as_pdf_outlined,
                      label: "Download Slip (PDF)",
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _generatePdf(riskLabel);
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Action Buttons
              if (showFacilitiesBtn) ...[
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryTeal,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () async {
                      HapticFeedback.selectionClick();
                      await _saveToHistory(score, riskLabel);
                      if (context.mounted) {
                        Navigator.pushNamed(context, '/facilities');
                      }
                    },
                    icon: const Icon(Icons.location_on_outlined, size: 18),
                    label: Text(
                      "View Accredited Health Centers",
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],

              // Retake Assessment Button
              SizedBox(
                width: double.infinity,
                height: 46,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: borderNeutral, width: 1.5),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.pushReplacementNamed(context, '/assess');
                  },
                  child: Text(
                    "Retake Triage Screening",
                    style: GoogleFonts.inter(
                      color: textCharcoal,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Return to Dashboard Button
              TextButton(
                onPressed: () async {
                  HapticFeedback.lightImpact();
                  await _saveToHistory(score, riskLabel);
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (r) => false);
                  }
                },
                child: Text(
                  "Return to Patient Dashboard",
                  style: GoogleFonts.inter(
                    color: textMuted,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderNeutral),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.015),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: primaryTeal, size: 17),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                color: textCharcoal,
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}