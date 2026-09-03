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
  Uint8List? _idAttachmentBytes; // Web & Native compatible image preview
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
  void _showTermsDialog(Color forestDark, Color forestLight) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Icon(Icons.gavel_rounded, color: forestDark),
            const SizedBox(width: 10),
            Text(
              "Terms & Conditions", 
              style: GoogleFonts.poppins(color: forestDark, fontWeight: FontWeight.bold, fontSize: 16)
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            "By proceeding with this registration and attaching the requested Carmona Residency ID, I hereby certify under penalty of perjury that the information provided is true, accurate, and reflects my current legal residence within the Municipality of Carmona. I acknowledge that the document submitted is a confidential record intended solely for the purpose of eligibility verification for the TB HealthCare management system. Furthermore, I agree to a strict Non-Disclosure obligation, understanding that any unauthorized access to the system's internal protocols, or the falsification of residency data to gain such access, constitutes a breach of professional conduct and may result in the immediate termination of my account and potential legal action. I consent to the secure electronic processing of my identification data and waive any claims against the system administrators regarding the standardized verification procedures required to maintain the integrity of this localized healthcare initiative.",
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.black87, height: 1.6),
            textAlign: TextAlign.justify,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Close", style: GoogleFonts.poppins(color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: forestDark,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              setState(() => _acceptedTerms = true);
              Navigator.pop(context);
            },
            child: Text("I Agree", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

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
                  Text(
                    "Notice",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: const Color(0xFF2D3B1E),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
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
                      child: Text(
                        "Got it",
                        style: GoogleFonts.poppins(
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
    const Color forestDark = Color(0xFF2D3B1E);
    const Color forestLight = Color(0xFF606C38);
    const Color bgOffWhite = Color(0xFFF4F7F4);

    return Scaffold(
      backgroundColor: bgOffWhite,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: forestDark, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned(
            top: -50,
            right: -50,
            child: _buildBackgroundShape(250, forestLight.withOpacity(0.06)),
          ),
          Positioned(
            top: 250,
            left: -80,
            child: _buildBackgroundShape(200, forestLight.withOpacity(0.04)),
          ),
          
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 15, bottom: 25, left: 24, right: 24),
                    child: Column(
                      children: [
                        _buildLogo(size: 70),
                        const SizedBox(height: 16),
                        Text(
                          'Create Account',
                          style: GoogleFonts.poppins(
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            color: forestDark,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Register for Carmona TB-DOTS Care',
                          style: GoogleFonts.poppins(
                            color: Colors.black45,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Form Card
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Personal Information',
                            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: forestDark),
                          ),
                          const SizedBox(height: 20),

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
                          const SizedBox(height: 18),

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
                                child: _buildGenderDropdown(forestDark, forestLight),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),

                          // 3. Carmona Barangay Selector
                          _buildBarangayDropdown(forestDark, forestLight),
                          const SizedBox(height: 18),

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
                          const SizedBox(height: 18),

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
                          const SizedBox(height: 18),

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
                                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: Colors.black38,
                                size: 20,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            onChanged: (val) {
                              if (_passwordError != null) setState(() => _passwordError = null);
                            },
                          ),
                          const SizedBox(height: 24),

                          // 7. Proof of Residence (Carmona ID Upload with Live Preview)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Proof of Residence (Carmona ID)", 
                                style: GoogleFonts.poppins(color: forestDark, fontWeight: FontWeight.w600, fontSize: 13)
                              ),
                              if (_idAttachment != null)
                                GestureDetector(
                                  onTap: _pickImage,
                                  child: Text(
                                    "Change", 
                                    style: GoogleFonts.poppins(color: forestLight, fontWeight: FontWeight.bold, fontSize: 12)
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
                                color: const Color(0xFFF8F9FA),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: _idError != null 
                                      ? Colors.redAccent 
                                      : (_idAttachment != null ? forestLight : Colors.black.withOpacity(0.08)),
                                  width: 1.5,
                                ),
                              ),
                              child: _idAttachmentBytes != null
                                  ? Row(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(10),
                                          child: Image.memory(
                                            _idAttachmentBytes!,
                                            width: 60,
                                            height: 60,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "ID Photo Attached",
                                                style: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 13,
                                                  color: forestDark,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                "Tap to replace photo",
                                                style: GoogleFonts.poppins(
                                                  fontSize: 11,
                                                  color: Colors.black45,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Icon(Icons.check_circle_rounded, color: forestLight, size: 22),
                                      ],
                                    )
                                  : Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: Colors.black.withOpacity(0.06)),
                                          ),
                                          child: const Icon(
                                            Icons.upload_file_rounded,
                                            color: Colors.black45,
                                            size: 22,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "Upload ID / Barangay Certificate",
                                                style: GoogleFonts.poppins(
                                                  color: forestDark, 
                                                  fontSize: 13, 
                                                  fontWeight: FontWeight.w600
                                                ),
                                              ),
                                              Text(
                                                "JPG, PNG under 5MB",
                                                style: GoogleFonts.poppins(fontSize: 11, color: Colors.black38),
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
                                style: GoogleFonts.poppins(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.w500),
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
                                  activeColor: forestLight,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                  side: BorderSide(color: Colors.black.withOpacity(0.2)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => _showTermsDialog(forestDark, forestLight),
                                  child: RichText(
                                    text: TextSpan(
                                      text: "I acknowledge the ",
                                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54, height: 1.5),
                                      children: [
                                        TextSpan(
                                          text: "Terms & Conditions",
                                          style: GoogleFonts.poppins(color: forestDark, fontWeight: FontWeight.w700, decoration: TextDecoration.underline),
                                        ),
                                        const TextSpan(text: " and certify under penalty of perjury that I am a resident of Carmona, Cavite."),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),

                          // Submit Button
                          _isLoading
                              ? const Center(child: CircularProgressIndicator(color: forestDark))
                              : _buildGradientButton("Register as Patient", _handleSignUp, [forestLight, forestDark]),
                          
                          const SizedBox(height: 20),
                          
                          Center(
                            child: TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: RichText(
                                text: TextSpan(
                                  text: "Already have an account? ",
                                  style: GoogleFonts.poppins(color: Colors.black45, fontSize: 13, fontWeight: FontWeight.w500),
                                  children: [
                                    TextSpan(
                                      text: "Sign In",
                                      style: GoogleFonts.poppins(color: forestDark, fontWeight: FontWeight.w700),
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
        ],
      ),
    );
  }

  // --- REUSABLE MODERN INPUT FIELD WITH INLINE ERROR NOTIFICATION ---
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
    const Color forestDark = Color(0xFF2D3B1E);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label, 
          style: GoogleFonts.poppins(color: forestDark, fontWeight: FontWeight.w600, fontSize: 13)
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: errorText != null ? Colors.redAccent : Colors.black.withOpacity(0.08),
              width: errorText != null ? 1.5 : 1.0,
            ),
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword && obscureText,
            keyboardType: inputType,
            inputFormatters: inputFormatters,
            onChanged: onChanged,
            style: GoogleFonts.poppins(color: forestDark, fontSize: 14, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.black26),
              prefixIcon: Icon(icon, color: errorText != null ? Colors.redAccent : Colors.black38, size: 20),
              suffixIcon: suffixIcon,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 5, left: 4),
            child: Text(
              errorText,
              style: GoogleFonts.poppins(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ),
      ],
    );
  }

  Widget _buildGenderDropdown(Color forestDark, Color forestLight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Gender", 
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: forestDark, fontSize: 13)
        ),
        const SizedBox(height: 6),
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _genderError != null ? Colors.redAccent : Colors.black.withOpacity(0.08),
              width: _genderError != null ? 1.5 : 1.0,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedGender,
              hint: Text("Select", style: GoogleFonts.poppins(fontSize: 13, color: Colors.black26)),
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.black38, size: 20),
              isExpanded: true,
              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(16),
              style: GoogleFonts.poppins(color: forestDark, fontSize: 14, fontWeight: FontWeight.w500),
              items: _genderOptions.map((String value) {
                return DropdownMenuItem<String>(
                  value: value, 
                  child: Text(value)
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
              style: GoogleFonts.poppins(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ),
      ],
    );
  }

  Widget _buildBarangayDropdown(Color forestDark, Color forestLight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              "Barangay Residency", 
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: forestDark, fontSize: 13)
            ),
            const SizedBox(width: 4),
            Text(
              "(Carmona, Cavite)", 
              style: GoogleFonts.poppins(fontWeight: FontWeight.w400, color: Colors.black38, fontSize: 11)
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withOpacity(0.08)),
          ),
          child: Row(
            children: [
              const Icon(Icons.location_on_outlined, color: Colors.black38, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedBarangay,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.black38, size: 20),
                    isExpanded: true,
                    dropdownColor: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    style: GoogleFonts.poppins(color: forestDark, fontSize: 14, fontWeight: FontWeight.w600),
                    items: _carmonaBarangays.map((String b) {
                      return DropdownMenuItem<String>(
                        value: b, 
                        child: Text("Brgy. $b")
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

  Widget _buildGradientButton(String text, VoidCallback onPressed, List<Color> colors) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: colors.last.withOpacity(0.28),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(18),
          child: Center(
            child: Text(
              text, 
              style: GoogleFonts.poppins(
                color: Colors.white, 
                fontWeight: FontWeight.w600, 
                fontSize: 15,
                letterSpacing: 0.3,
              )
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo({required double size}) {
    return Container(
      width: size * 1.3,
      height: size * 1.3,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Image.asset(
          'assets/LogoNoBG.png',
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildBackgroundShape(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color, 
        shape: BoxShape.circle,
      ),
    );
  }
}