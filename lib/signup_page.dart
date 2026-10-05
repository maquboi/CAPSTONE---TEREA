import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  // --- FORMAL CLINICAL COLOR SYSTEM ---
  static const Color primaryTeal = Color(0xFF0F766E);       // Deep Clinical Teal
  static const Color primaryDark = Color(0xFF115E59);       // Spruce Slate
  static const Color backgroundLight = Color(0xFFF8FAFC);   // Clean Slate Grey
  static const Color textCharcoal = Color(0xFF0F172A);      // High Contrast Text
  static const Color textMuted = Color(0xFF64748B);         // Subdued Text
  static const Color borderNeutral = Color(0xFFE2E8F0);     // Structured Border
  static const Color inputBg = Color(0xFFF1F5F9);          // Input Background

  // --- CONTROLLERS ---
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _contactController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // --- FORM SELECTIONS ---
  String? _selectedGender;
  final List<String> _genderOptions = ['Male', 'Female', 'Other'];

  String _selectedBarangay = 'Maduya';
  final List<String> _carmonaBarangays = [
    'Bancal',
    'Cabilang Baybay',
    'Lantic',
    'Mabuhay',
    'Maduya',
    'Milagrosa',
    'Poblacion 1',
    'Poblacion 2',
    'Poblacion 3',
    'Poblacion 4',
    'Poblacion 5',
    'Poblacion 6',
    'Poblacion 7',
    'Poblacion 8',
  ];

  // --- INLINE ERROR STATES ---
  String? _nameError;
  String? _ageError;
  String? _genderError;
  String? _contactError;
  String? _emailError;
  String? _passwordError;
  String? _idError;

  bool _obscurePassword = true;
  bool _isLoading = false;

  // --- ATTACHMENT & TERMS STATE ---
  XFile? _idAttachment;
  Uint8List? _idAttachmentBytes;
  bool _acceptedTerms = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _contactController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- IMAGE PICKER LOGIC WITH PREVIEW ---
  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _idAttachment = pickedFile;
          _idAttachmentBytes = bytes;
          _idError = null;
        });
      }
    } catch (e) {
      _showNotificationPopup("Failed to pick image: $e");
    }
  }

  // --- LIVE VALIDATION ON SUBMISSION ---
  bool _validateForm() {
    bool isValid = true;
    setState(() {
      // 1. Name Validation
      final name = _nameController.text.trim();
      final nameRegex = RegExp(r"^[a-zA-ZñÑáéíóúÁÉÍÓÚ\s\.\-]+$");
      if (name.isEmpty) {
        _nameError = "Full name is required";
        isValid = false;
      } else if (name.length < 2 || name.length > 60) {
        _nameError = "Name must be between 2 and 60 characters";
        isValid = false;
      } else if (!nameRegex.hasMatch(name)) {
        _nameError = "Name can only contain letters, dots, and hyphens";
        isValid = false;
      } else {
        _nameError = null;
      }

      // 2. Age Validation
      final age = int.tryParse(_ageController.text.trim());
      if (_ageController.text.trim().isEmpty) {
        _ageError = "Age required";
        isValid = false;
      } else if (age == null || age < 1 || age > 115) {
        _ageError = "1 - 115 yrs";
        isValid = false;
      } else {
        _ageError = null;
      }

      // 3. Gender Validation
      if (_selectedGender == null) {
        _genderError = "Select gender";
        isValid = false;
      } else {
        _genderError = null;
      }

      // 4. Contact Number Validation
      final contact = _contactController.text.trim();
      if (contact.isEmpty) {
        _contactError = "Contact number is required";
        isValid = false;
      } else if (!contact.startsWith('09') || contact.length != 11) {
        _contactError = "Must start with '09' and be 11 digits (e.g. 09123456789)";
        isValid = false;
      } else {
        _contactError = null;
      }

      // 5. Email Validation
      final email = _emailController.text.trim();
      final emailRegex = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$");
      if (email.isEmpty) {
        _emailError = "Email address is required";
        isValid = false;
      } else if (!emailRegex.hasMatch(email)) {
        _emailError = "Please enter a valid email format";
        isValid = false;
      } else {
        _emailError = null;
      }

      // 6. Password Validation
      final password = _passwordController.text;
      if (password.isEmpty) {
        _passwordError = "Password is required";
        isValid = false;
      } else if (password.length < 10) {
        _passwordError = "Password must be at least 10 characters long";
        isValid = false;
      } else {
        _passwordError = null;
      }

      // 7. Proof of Residence
      if (_idAttachment == null) {
        _idError = "Please attach a valid ID proving Carmona residence";
        isValid = false;
      } else {
        _idError = null;
      }

      // 8. Terms Agreement
      if (!_acceptedTerms) {
        isValid = false;
        _showNotificationPopup("Please review and agree to the Terms & Conditions to proceed.");
      }
    });

    return isValid;
  }

  // --- TERMS & CONDITIONS DIALOG ---
  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderNeutral),
        ),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            const Icon(Icons.gavel_rounded, color: primaryTeal, size: 20),
            const SizedBox(width: 10),
            Text(
              "Terms & Conditions",
              style: GoogleFonts.inter(color: textCharcoal, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            "By proceeding with this registration and attaching the requested Carmona Residency ID, I hereby certify under penalty of perjury that the information provided is true, accurate, and reflects my current legal residence within the Municipality of Carmona. I acknowledge that the document submitted is a confidential record intended solely for the purpose of eligibility verification for the TB HealthCare management system. Furthermore, I agree to a strict Non-Disclosure obligation, understanding that any unauthorized access to the system's internal protocols, or the falsification of residency data to gain such access, constitutes a breach of professional conduct and may result in the immediate termination of my account and potential legal action. I consent to the secure electronic processing of my identification data and waive any claims against the system administrators regarding the standardized verification procedures required to maintain the integrity of this localized healthcare initiative.",
            style: GoogleFonts.inter(fontSize: 13, color: textCharcoal, height: 1.6),
            textAlign: TextAlign.justify,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Close", style: GoogleFonts.inter(color: textMuted, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryTeal,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            onPressed: () {
              setState(() => _acceptedTerms = true);
              Navigator.pop(context);
            },
            child: Text("I Agree", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // --- FORMAL NOTIFICATION POPUP ---
  void _showNotificationPopup(String message) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withOpacity(0.4),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, _, __) => const SizedBox.shrink(),
      transitionBuilder: (context, a1, a2, child) {
        return FadeTransition(
          opacity: a1,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: borderNeutral),
            ),
            backgroundColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
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
                  "Registration Notice",
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
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
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

  Future<void> _handleSignUp() async {
    if (!_validateForm()) return;

    setState(() => _isLoading = true);
    try {
      final authResponse = await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (authResponse.user != null) {
        String? idUrl;
        if (_idAttachment != null && _idAttachmentBytes != null) {
          final fileExt = _idAttachment!.name.split('.').last;
          final fileName = '${authResponse.user!.id}_id.$fileExt';

          await Supabase.instance.client.storage
              .from('id_attachments')
              .uploadBinary(fileName, _idAttachmentBytes!);

          idUrl = Supabase.instance.client.storage
              .from('id_attachments')
              .getPublicUrl(fileName);
        }

        await Supabase.instance.client.from('profiles').insert({
          'id': authResponse.user!.id,
          'full_name': _nameController.text.trim(),
          'age': _ageController.text.trim(),
          'gender': _selectedGender,
          'barangay': _selectedBarangay,
          'contact_number': _contactController.text.trim(),
          'email': _emailController.text.trim(),
          'role': 'patient',
          'id_attachment_url': idUrl,
        });

        if (mounted) Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } catch (e) {
      if (mounted) {
        _showNotificationPopup("Registration Error: $e");
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: textCharcoal, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              // Top Header & Institutional Badge
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 24, left: 24, right: 24),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: primaryTeal.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: primaryTeal.withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.local_hospital_rounded, color: primaryTeal, size: 15),
                          const SizedBox(width: 8),
                          Text(
                            "Carmona Health Center",
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: primaryTeal,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildLogo(size: 68),
                    const SizedBox(height: 16),
                    Text(
                      'Create Profile',
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: textCharcoal,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Register for digital TB monitoring and clinic care',
                      style: GoogleFonts.inter(
                        color: textMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),

              // Form Card Container
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: borderNeutral, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Personal Details',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: textCharcoal,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 1. Full Name
                      _buildModernInputField(
                        label: "Full Name",
                        hint: "e.g. Juan Dela Cruz",
                        controller: _nameController,
                        icon: Icons.person_outline_rounded,
                        errorText: _nameError,
                        inputType: TextInputType.name,
                        onChanged: (val) {
                          if (_nameError != null) setState(() => _nameError = null);
                        },
                      ),
                      const SizedBox(height: 16),

                      // 2. Age & Gender in 1 Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 1,
                            child: _buildModernInputField(
                              label: "Age",
                              hint: "25",
                              controller: _ageController,
                              icon: Icons.cake_outlined,
                              errorText: _ageError,
                              inputType: TextInputType.number,
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(3),
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              onChanged: (val) {
                                if (_ageError != null) setState(() => _ageError = null);
                              },
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            flex: 1,
                            child: _buildGenderDropdown(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 3. Carmona Barangay Selector
                      _buildBarangayDropdown(),
                      const SizedBox(height: 16),

                      // 4. Contact Number
                      _buildModernInputField(
                        label: "Contact Number",
                        hint: "09123456789",
                        controller: _contactController,
                        icon: Icons.phone_android_outlined,
                        errorText: _contactError,
                        inputType: TextInputType.phone,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(11),
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onChanged: (val) {
                          if (_contactError != null) setState(() => _contactError = null);
                        },
                      ),
                      const SizedBox(height: 24),

                      Text(
                        'Account Credentials',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: textCharcoal,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 5. Email Address
                      _buildModernInputField(
                        label: "Email Address",
                        hint: "your.email@example.com",
                        controller: _emailController,
                        icon: Icons.alternate_email_rounded,
                        errorText: _emailError,
                        inputType: TextInputType.emailAddress,
                        onChanged: (val) {
                          if (_emailError != null) setState(() => _emailError = null);
                        },
                      ),
                      const SizedBox(height: 16),

                      // 6. Password with Visibility Toggle
                      _buildModernInputField(
                        label: "Password",
                        hint: "Minimum 10 characters",
                        controller: _passwordController,
                        icon: Icons.lock_outline_rounded,
                        errorText: _passwordError,
                        isPassword: true,
                        obscureText: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            color: textMuted,
                            size: 19,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        onChanged: (val) {
                          if (_passwordError != null) setState(() => _passwordError = null);
                        },
                      ),
                      const SizedBox(height: 24),

                      // 7. Proof of Residence (Carmona ID Upload)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Proof of Residence (Carmona ID)",
                            style: GoogleFonts.inter(color: textCharcoal, fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          if (_idAttachment != null)
                            GestureDetector(
                              onTap: _pickImage,
                              child: Text(
                                "Change",
                                style: GoogleFonts.inter(color: primaryTeal, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: inputBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _idError != null
                                  ? const Color(0xFFDC2626)
                                  : (_idAttachment != null ? primaryTeal : borderNeutral),
                              width: _idAttachment != null ? 1.5 : 1.0,
                            ),
                          ),
                          child: _idAttachmentBytes != null
                              ? Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.memory(
                                        _idAttachmentBytes!,
                                        width: 54,
                                        height: 54,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Document Attached",
                                            style: GoogleFonts.inter(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13,
                                              color: textCharcoal,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            "Tap to replace ID photo",
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              color: textMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.check_circle_rounded, color: primaryTeal, size: 22),
                                  ],
                                )
                              : Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: borderNeutral),
                                      ),
                                      child: const Icon(
                                        Icons.upload_file_rounded,
                                        color: primaryTeal,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Upload ID / Barangay Clearance",
                                            style: GoogleFonts.inter(
                                              color: textCharcoal,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            "JPG or PNG format",
                                            style: GoogleFonts.inter(fontSize: 11, color: textMuted),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      if (_idError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6, left: 4),
                          child: Text(
                            _idError!,
                            style: GoogleFonts.inter(color: const Color(0xFFDC2626), fontSize: 11, fontWeight: FontWeight.w500),
                          ),
                        ),
                      const SizedBox(height: 24),

                      // 8. Terms & Conditions Checkbox
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: 22,
                            width: 22,
                            child: Checkbox(
                              value: _acceptedTerms,
                              onChanged: (val) => setState(() => _acceptedTerms = val ?? false),
                              activeColor: primaryTeal,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              side: const BorderSide(color: borderNeutral, width: 1.5),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: _showTermsDialog,
                              child: RichText(
                                text: TextSpan(
                                  text: "I acknowledge the ",
                                  style: GoogleFonts.inter(fontSize: 12, color: textMuted, height: 1.5),
                                  children: const [
                                    TextSpan(
                                      text: "Terms & Conditions",
                                      style: TextStyle(color: primaryTeal, fontWeight: FontWeight.w700, decoration: TextDecoration.underline),
                                    ),
                                    TextSpan(text: " and certify under penalty of perjury that I am a resident of Carmona, Cavite."),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // Submit Button
                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryTeal,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          onPressed: _isLoading ? null : _handleSignUp,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : Text(
                                  "Register",
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      Center(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: RichText(
                            text: TextSpan(
                              text: "Already have an account? ",
                              style: GoogleFonts.inter(color: textMuted, fontSize: 13),
                              children: const [
                                TextSpan(
                                  text: "Sign In",
                                  style: TextStyle(color: primaryTeal, fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- REUSABLE MODERN INPUT FIELD ---
  Widget _buildModernInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    String? errorText,
    bool isPassword = false,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType inputType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(color: textCharcoal, fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: inputBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: errorText != null ? const Color(0xFFDC2626) : borderNeutral,
              width: errorText != null ? 1.5 : 1.0,
            ),
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword && obscureText,
            keyboardType: inputType,
            inputFormatters: inputFormatters,
            onChanged: onChanged,
            style: GoogleFonts.inter(color: textCharcoal, fontSize: 14, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.inter(fontSize: 13, color: Colors.black26),
              prefixIcon: Icon(icon, color: errorText != null ? const Color(0xFFDC2626) : textMuted, size: 19),
              suffixIcon: suffixIcon,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 5, left: 4),
            child: Text(
              errorText,
              style: GoogleFonts.inter(color: const Color(0xFFDC2626), fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ),
      ],
    );
  }

  Widget _buildGenderDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Gender",
          style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: textCharcoal, fontSize: 13),
        ),
        const SizedBox(height: 6),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: inputBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _genderError != null ? const Color(0xFFDC2626) : borderNeutral,
              width: _genderError != null ? 1.5 : 1.0,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedGender,
              hint: Text("Select", style: GoogleFonts.inter(fontSize: 13, color: Colors.black26)),
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: textMuted, size: 20),
              isExpanded: true,
              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(12),
              style: GoogleFonts.inter(color: textCharcoal, fontSize: 14, fontWeight: FontWeight.w500),
              items: _genderOptions.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedGender = newValue;
                  _genderError = null;
                });
              },
            ),
          ),
        ),
        if (_genderError != null)
          Padding(
            padding: const EdgeInsets.only(top: 5, left: 4),
            child: Text(
              _genderError!,
              style: GoogleFonts.inter(color: const Color(0xFFDC2626), fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ),
      ],
    );
  }

  Widget _buildBarangayDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              "Barangay Residency",
              style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: textCharcoal, fontSize: 13),
            ),
            const SizedBox(width: 4),
            Text(
              "(Carmona, Cavite)",
              style: GoogleFonts.inter(fontWeight: FontWeight.w400, color: textMuted, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: inputBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderNeutral),
          ),
          child: Row(
            children: [
              const Icon(Icons.location_on_outlined, color: textMuted, size: 19),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedBarangay,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: textMuted, size: 20),
                    isExpanded: true,
                    dropdownColor: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    style: GoogleFonts.inter(color: textCharcoal, fontSize: 14, fontWeight: FontWeight.w500),
                    items: _carmonaBarangays.map((String b) {
                      return DropdownMenuItem<String>(
                        value: b,
                        child: Text("Brgy. $b"),
                      );
                    }).toList(),
                    onChanged: (newBarangay) {
                      if (newBarangay != null) {
                        setState(() => _selectedBarangay = newBarangay);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLogo({required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderNeutral),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(10),
      child: Image.asset(
        'assets/LogoNoBG.png',
        fit: BoxFit.contain,
      ),
    );
  }
}