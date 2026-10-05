import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// --- SHARED UI STATE & GLOBAL NOTIFIERS ---
final ValueNotifier<bool> isEnglishNotifier = ValueNotifier<bool>(true);

// --- FORMAL CLINICAL COLOR SYSTEM ---
const Color _primaryTeal = Color(0xFF0F766E);       // Deep Clinical Teal
const Color _primaryDark = Color(0xFF115E59);       // Spruce Slate
const Color _backgroundLight = Color(0xFFF8FAFC);   // Clean Slate Grey
const Color _textCharcoal = Color(0xFF0F172A);      // High Contrast Text
const Color _textMuted = Color(0xFF64748B);         // Subdued Text
const Color _borderNeutral = Color(0xFFE2E8F0);     // Structured Border
const Color _inputBg = Color(0xFFF1F5F9);          // Input Background

Widget buildLogo({double size = 80}) {
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(size * 0.22),
      border: Border.all(color: _borderNeutral),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    padding: EdgeInsets.all(size * 0.15),
    child: Image.asset(
      'assets/LogoNoBG.png',
      fit: BoxFit.contain,
    ),
  );
}

Widget buildTextField(String label, String hint, {bool isPassword = false, TextEditingController? controller}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: _textCharcoal, fontSize: 13),
      ),
      const SizedBox(height: 6),
      TextField(
        controller: controller,
        obscureText: isPassword,
        style: GoogleFonts.inter(color: _textCharcoal, fontSize: 14, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(color: Colors.black26, fontSize: 13),
          filled: true,
          fillColor: _inputBg,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _borderNeutral)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _borderNeutral)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _primaryTeal, width: 1.5)),
          suffixIcon: isPassword ? const Icon(Icons.visibility_off_outlined, color: _textMuted, size: 19) : null,
        ),
      ),
    ],
  );
}

Widget buildPrimaryButton(BuildContext context, String text, VoidCallback onTap) {
  return SizedBox(
    width: double.infinity,
    height: 50,
    child: ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryTeal,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.2),
      ),
    ),
  );
}

Widget buildActionCard(BuildContext context, IconData icon, String title, String sub, String route) {
  return GestureDetector(
    onTap: () => Navigator.pushNamed(context, route),
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderNeutral),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _primaryTeal.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: _primaryTeal, size: 20),
          ),
          const Spacer(),
          Text(
            title,
            style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: _textCharcoal),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: GoogleFonts.inter(fontSize: 11, color: _textMuted, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    ),
  );
}

// Modernized Floating Pill-Shaped Bottom Navigation (Clinical Teal)
Widget buildBottomNav(int idx, BuildContext context) {
  final List<IconData> icons = [
    Icons.home_rounded,
    Icons.assignment_rounded,
    Icons.medication_rounded,
    Icons.calendar_month_rounded,
  ];

  return SafeArea(
    child: Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _borderNeutral),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(icons.length, (index) {
          bool isActive = idx == index;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (index == 0) Navigator.pushNamed(context, '/dashboard');
              if (index == 1) Navigator.pushNamed(context, '/assess');
              if (index == 2) Navigator.pushNamed(context, '/meds');
              if (index == 3) Navigator.pushNamed(context, '/followup');
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isActive ? _primaryTeal.withOpacity(0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icons[index],
                color: isActive ? _primaryTeal : const Color(0xFF94A3B8),
                size: 24,
              ),
            ),
          );
        }),
      ),
    ),
  );
}