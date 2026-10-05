import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class SupportPage extends StatefulWidget {
  const SupportPage({super.key});

  @override
  State<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage> {
  final TextEditingController _messageController = TextEditingController();

  // --- FORMAL CLINICAL COLOR SYSTEM ---
  static const Color primaryTeal = Color(0xFF0F766E);       // Deep Clinical Teal
  static const Color primaryDark = Color(0xFF115E59);       // Spruce Slate
  static const Color primaryDeep = Color(0xFF042F2E);       // Deepest Navy Teal
  static const Color backgroundSurface = Color(0xFFF1F5F9); // Contrast Slate Background
  static const Color cardBg = Colors.white;                // Pure White Card
  static const Color textCharcoal = Color(0xFF0F172A);      // High Contrast Text
  static const Color textMuted = Color(0xFF64748B);         // Subdued Text
  static const Color borderNeutral = Color(0xFFE2E8F0);     // Structured Border
  static const Color inputBg = Color(0xFFF8FAFC);          // Form Field Background

  // FAQ State
  int? _expandedIndex;

  final List<Map<String, String>> _faqs = [
    {
      "question": "How do I link my account to a doctor?",
      "answer": "Go to your dashboard, click on the 'Connect to Clinic' card, and enter the unique code or scan the QR code provided by your attending healthcare provider."
    },
    {
      "question": "Why is my Medication Diary locked?",
      "answer": "The diary remains locked until you have completed your initial Risk Assessment screening and your clinic physician has verified your connection and initiated your treatment schedule."
    },
    {
      "question": "How do I edit a mistaken diary entry?",
      "answer": "Go to the Medication Diary page, select the three dots next to the entry, and choose 'Edit'. You can also toggle the slide bar to adjust the dose status."
    },
    {
      "question": "Who can see my health data?",
      "answer": "Your health data is strictly confidential under R.A. 10173 and is only shared with your assigned clinic physician to coordinate your treatment protocol."
    },
  ];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _submitTicket() {
    if (_messageController.text.trim().isEmpty) return;

    // Hide keyboard
    FocusScope.of(context).unfocus();
    HapticFeedback.lightImpact();

    // Clear the field and show confirmation
    _messageController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Message submitted! Clinical support will review your inquiry shortly.",
          style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
        ),
        backgroundColor: textCharcoal,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
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
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Help & Clinical Support',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: textCharcoal,
            fontSize: 17,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildModernHeader(),
            const SizedBox(height: 24),

            // QUICK CONTACT SECTION
            Text(
              "DIRECT INQUIRY",
              style: GoogleFonts.inter(
                color: textMuted,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            _buildContactCard(
              Icons.mail_outline_rounded,
              "Carmona Clinic Desk",
              "Expect an administrative response within 24 operational hours",
            ),
            const SizedBox(height: 28),

            // FAQ SECTION
            Text(
              "FREQUENTLY ASKED QUESTIONS",
              style: GoogleFonts.inter(
                color: textMuted,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            ...List.generate(_faqs.length, (index) => _buildFAQItem(index)),

            const SizedBox(height: 28),

            // SUBMIT A TICKET SECTION
            Text(
              "REPORT AN ISSUE OR INQUIRY",
              style: GoogleFonts.inter(
                color: textMuted,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            _buildSupportForm(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildModernHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primaryDeep, primaryTeal],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: primaryTeal.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.support_agent_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Patient Care & Support Desk',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Find answers to platform protocols below or submit a ticket directly to clinical support.',
            style: GoogleFonts.inter(
              color: Colors.white.withOpacity(0.85),
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderNeutral),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDFA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFCCFBF1)),
            ),
            child: Icon(icon, color: primaryTeal, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    color: textCharcoal,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(color: textMuted, fontSize: 11.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(int index) {
    bool isExpanded = _expandedIndex == index;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _expandedIndex = isExpanded ? null : index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isExpanded ? const Color(0xFFF0FDFA) : cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isExpanded ? const Color(0xFF99F6E4) : borderNeutral,
            width: isExpanded ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.015),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _faqs[index]["question"]!,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      color: isExpanded ? primaryDark : textCharcoal,
                      fontSize: 13.5,
                      height: 1.35,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  color: isExpanded ? primaryTeal : textMuted,
                  size: 20,
                ),
              ],
            ),
            if (isExpanded) ...[
              const SizedBox(height: 10),
              Text(
                _faqs[index]["answer"]!,
                style: GoogleFonts.inter(
                  color: const Color(0xFF334155),
                  fontSize: 12.5,
                  height: 1.5,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSupportForm() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderNeutral),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: inputBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderNeutral),
            ),
            child: TextField(
              controller: _messageController,
              maxLines: 4,
              style: GoogleFonts.inter(fontSize: 13.5, color: textCharcoal),
              decoration: InputDecoration(
                hintText: "Describe your inquiry or technical question in detail...",
                hintStyle: GoogleFonts.inter(color: Colors.black26, fontSize: 13),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryTeal,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _submitTicket,
              child: Text(
                "Submit Inquiry",
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}