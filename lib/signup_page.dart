import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Needed for TextInputFormatter
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

  String? _selectedGender;
  final List<String> _genderOptions = ['Male', 'Female', 'Other'];
  bool _isLoading = false;

  // --- NEW ATTACHMENT & TERMS STATE (WEB SAFE) ---
  XFile? _idAttachment; 
  bool _acceptedTerms = false;
  final ImagePicker _picker = ImagePicker();

  // --- IMAGE PICKER LOGIC ---
  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _idAttachment = pickedFile;
        });
      }
    } catch (e) {
      _showSnackBar("Failed to pick image: $e");
    }
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

  // --- VALIDATION LOGIC ---
  bool _validateInputs() {
    final nameRegex = RegExp(r'^[a-zA-Z ]+$');
    if (_nameController.text.isEmpty ||
        _nameController.text.length > 50 ||
        !nameRegex.hasMatch(_nameController.text)) {
      _showSnackBar("Name must contain letters only and be under 50 characters.");
      return false;
    }

    final age = int.tryParse(_ageController.text);
    if (age == null || age < 1 || age > 100) {
      _showSnackBar("Age must be a valid number between 1 and 100.");
      return false;
    }

    if (!_contactController.text.startsWith('09') ||
        _contactController.text.length != 11) {
      _showSnackBar("Contact number must start with '09' and be 11 digits.");
      return false;
    }

    if (!_emailController.text.contains('@')) {
      _showSnackBar("Please enter a valid email address.");
      return false;
    }

    if (_passwordController.text.length < 10) {
      _showSnackBar("Password must be at least 10 characters long.");
      return false;
    }

    if (_selectedGender == null) {
      _showSnackBar("Please select a gender.");
      return false;
    }

    if (_idAttachment == null) {
      _showSnackBar("Please attach a valid ID to confirm your residence in Carmona.");
      return false;
    }

    if (!_acceptedTerms) {
      _showSnackBar("You must acknowledge the terms and conditions to proceed.");
      return false;
    }

    return true;
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _handleSignUp() async {
    if (!_validateInputs()) return;

    setState(() => _isLoading = true);
    try {
      final authResponse = await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (authResponse.user != null) {
        // --- PROCESS WORKFLOW: UPLOAD ID ATTACHMENT ---
        String? idUrl;
        if (_idAttachment != null) {
          final fileExt = _idAttachment!.name.split('.').last;
          final fileName = '${authResponse.user!.id}_id.$fileExt';
          
          final bytes = await _idAttachment!.readAsBytes();
          
          await Supabase.instance.client.storage
              .from('id_attachments')
              .uploadBinary(fileName, bytes);
              
          idUrl = Supabase.instance.client.storage
              .from('id_attachments')
              .getPublicUrl(fileName);
        }

        // --- PROCESS WORKFLOW: AUTOMATIC PATIENT ASSIGNMENT ---
        await Supabase.instance.client.from('profiles').insert({
          'id': authResponse.user!.id,
          'full_name': _nameController.text.trim(),
          'age': _ageController.text.trim(),
          'gender': _selectedGender,
          'contact_number': _contactController.text.trim(),
          'email': _emailController.text.trim(),
          'role': 'patient', 
          'id_attachment_url': idUrl, 
        });

        if (mounted) Navigator.pushNamed(context, '/dashboard');
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar("Registration Error: $e");
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
          // Soft decorative background shapes
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
                  // Header Section (Modernized text, no heavy background)
                  Padding(
                    padding: const EdgeInsets.only(top: 20, bottom: 30, left: 24, right: 24),
                    child: Column(
                      children: [
                        _buildLogo(size: 50),
                        const SizedBox(height: 20),
                        Text(
                          'Join TEREA',
                          style: GoogleFonts.poppins(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: forestDark,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start your wellness journey today',
                          style: GoogleFonts.poppins(
                            color: Colors.black45,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Form Card
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
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
                            'Create Account',
                            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: forestDark),
                          ),
                          const SizedBox(height: 24),

                          _buildTextField(
                            label: "Full Name",
                            hint: "Juan Dela Cruz",
                            controller: _nameController,
                            icon: Icons.person_outline_rounded,
                            inputType: TextInputType.name,
                            formatters: [
                              LengthLimitingTextInputFormatter(50),
                              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z ]')),
                            ],
                          ),
                          const SizedBox(height: 20),

                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  label: "Age",
                                  hint: "25",
                                  controller: _ageController,
                                  icon: Icons.cake_outlined,
                                  inputType: TextInputType.number,
                                  formatters: [
                                    LengthLimitingTextInputFormatter(3),
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(child: _buildGenderDropdown(forestDark, forestLight)),
                            ],
                          ),
                          const SizedBox(height: 20),

                          _buildTextField(
                            label: "Contact Number",
                            hint: "09123456789",
                            controller: _contactController,
                            icon: Icons.phone_android_outlined,
                            inputType: TextInputType.phone,
                            formatters: [
                              LengthLimitingTextInputFormatter(11),
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                          ),
                          const SizedBox(height: 20),

                          _buildTextField(
                            label: "Email Address",
                            hint: "your.email@example.com",
                            controller: _emailController,
                            icon: Icons.alternate_email_rounded,
                            inputType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 20),

                          _buildTextField(
                            label: "Password",
                            hint: "Minimum 10 characters",
                            isPassword: true,
                            controller: _passwordController,
                            icon: Icons.lock_outline_rounded,
                          ),
                          const SizedBox(height: 24),

                          // --- STYLED ID ATTACHMENT UPLOAD ---
                          Text(
                            "Proof of Residence (Carmona ID)", 
                            style: GoogleFonts.poppins(color: forestDark, fontWeight: FontWeight.w600, fontSize: 13)
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8F9FA),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: _idAttachment != null ? forestLight : Colors.black.withOpacity(0.05), width: 1.5),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _idAttachment != null ? Icons.check_circle_rounded : Icons.upload_file_rounded, 
                                    color: _idAttachment != null ? forestLight : Colors.black38, 
                                    size: 22
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _idAttachment != null ? "ID Attached Successfully" : "Tap to upload ID photo",
                                      style: GoogleFonts.poppins(
                                        color: _idAttachment != null ? forestDark : Colors.black45, 
                                        fontSize: 13,
                                        fontWeight: _idAttachment != null ? FontWeight.w600 : FontWeight.w500
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // --- INTERACTIVE TERMS AND CONDITIONS CHECKBOX ---
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                height: 24,
                                width: 24,
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
                                        const TextSpan(text: " and confirm I am a resident of Carmona."),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),

                          // SUBMIT BUTTON
                          _isLoading
                              ? const Center(child: CircularProgressIndicator(color: forestDark))
                              : _buildGradientButton("Create Account", _handleSignUp, [forestLight, forestDark]),
                          
                          const SizedBox(height: 24),
                          
                          Center(
                            child: TextButton(
                              onPressed: () => Navigator.pop(context),
                              style: TextButton.styleFrom(splashFactory: NoSplash.splashFactory),
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

  // --- UI COMPONENTS ---
  Widget _buildGenderDropdown(Color forestDark, Color forestLight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Gender", 
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: forestDark, fontSize: 13)
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withOpacity(0.05)),
          ),
          child: Row(
            children: [
              const Icon(Icons.person_outline_rounded, color: Colors.black38, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedGender,
                    hint: Text("Select", style: GoogleFonts.poppins(fontSize: 14, color: Colors.black26)),
                    icon: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.black38, size: 20),
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
                    onChanged: (newValue) => setState(() => _selectedGender = newValue),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    bool isPassword = false,
    IconData? icon,
    TextInputType inputType = TextInputType.text,
    List<TextInputFormatter>? formatters,
  }) {
    const Color forestDark = Color(0xFF2D3B1E);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label, 
          style: GoogleFonts.poppins(color: forestDark, fontWeight: FontWeight.w600, fontSize: 13)
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withOpacity(0.05)),
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword,
            keyboardType: inputType,
            inputFormatters: formatters,
            style: GoogleFonts.poppins(color: forestDark, fontSize: 14, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.poppins(fontSize: 14, color: Colors.black26),
              prefixIcon: Icon(icon, color: Colors.black38, size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGradientButton(String text, VoidCallback onPressed, List<Color> colors) {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors.last.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(20),
          child: Center(
            child: Text(
              text, 
              style: GoogleFonts.poppins(
                color: Colors.white, 
                fontWeight: FontWeight.w600, 
                fontSize: 15,
                letterSpacing: 0.5,
              )
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo({required double size}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF606C38),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF606C38).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Icon(
        Icons.local_hospital_rounded, 
        size: size * 0.6, 
        color: Colors.white,
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