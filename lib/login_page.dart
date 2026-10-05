import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _focusNodeEmail = FocusNode();
  final _focusNodePassword = FocusNode();

  bool _isLoading = false;
  bool _obscurePassword = true;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Formal Clinical Color System
  static const Color primaryTeal = Color(0xFF0F766E);       // Deep Clinical Teal
  static const Color primaryDark = Color(0xFF115E59);       // Spruce Slate
  static const Color backgroundLight = Color(0xFFF8FAFC);   // Clean Slate Grey
  static const Color textCharcoal = Color(0xFF0F172A);      // High Contrast Text
  static const Color textMuted = Color(0xFF64748B);         // Subdued Text
  static const Color borderNeutral = Color(0xFFE2E8F0);     // Structured Border
  static const Color inputBg = Color(0xFFF1F5F9);          // Input Background

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _focusNodeEmail.dispose();
    _focusNodePassword.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  // --- FORMAL ALERT DIALOG ---
  void _showNotificationPopup(String message, {bool isSuccess = false}) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withOpacity(0.4),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, _, __) => const SizedBox.shrink(),
      transitionBuilder: (context, a1, a2, child) {
        final alertColor = isSuccess ? primaryTeal : const Color(0xFFDC2626);
        final alertIcon = isSuccess ? Icons.check_circle_outline_rounded : Icons.error_outline_rounded;

        return FadeTransition(
          opacity: a1,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: borderNeutral, width: 1),
            ),
            backgroundColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: alertColor.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(alertIcon, color: alertColor, size: 28),
                ),
                const SizedBox(height: 16),
                Text(
                  isSuccess ? "Authentication Successful" : "Access Notification",
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

  // --- PASSWORD RESET MODAL ---
  void _showForgotPasswordDialog() {
    final resetEmailController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            bool isSubmitting = false;
            String? errorMsg;
            bool success = false;

            Future<void> submitRequest() async {
              final email = resetEmailController.text.trim();
              if (email.isEmpty || !email.contains('@')) {
                setState(() => errorMsg = "Please input a valid medical/patient email.");
                return;
              }

              setState(() {
                isSubmitting = true;
                errorMsg = null;
              });

              try {
                await Supabase.instance.client.from('support_tickets').insert({
                  'email': email,
                  'issue_type': 'Password Reset Request',
                  'message': 'Patient requested a password reset from TEREA Mobile App.',
                  'status': 'Pending',
                });

                setState(() {
                  success = true;
                  isSubmitting = false;
                });
              } catch (e) {
                setState(() {
                  errorMsg = "Unable to process request. Please contact clinic staff directly.";
                  isSubmitting = false;
                });
              }
            }

            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: borderNeutral),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: success
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle_outline, color: primaryTeal, size: 40),
                          const SizedBox(height: 12),
                          Text(
                            "Request Submitted",
                            style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.bold, color: textCharcoal),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "The Carmona TB-DOTS administrator has been notified. Check your email inbox for instructions.",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(color: textMuted, fontSize: 13, height: 1.4),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryTeal,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                elevation: 0,
                              ),
                              onPressed: () => Navigator.pop(context),
                              child: Text("Done", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
                            ),
                          )
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Account Recovery",
                                style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700, color: textCharcoal),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, color: textMuted, size: 20),
                                onPressed: () => Navigator.pop(context),
                              )
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Enter the registered email associated with your TB-DOTS treatment profile.",
                            style: GoogleFonts.inter(color: textMuted, fontSize: 13, height: 1.4),
                          ),
                          const SizedBox(height: 16),
                          if (errorMsg != null)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFFCA5A5)),
                              ),
                              child: Text(
                                errorMsg!,
                                style: GoogleFonts.inter(color: const Color(0xFF991B1B), fontSize: 12),
                              ),
                            ),
                          TextField(
                            controller: resetEmailController,
                            keyboardType: TextInputType.emailAddress,
                            style: GoogleFonts.inter(fontSize: 14, color: textCharcoal),
                            decoration: InputDecoration(
                              hintText: "patient@example.com",
                              hintStyle: GoogleFonts.inter(color: Colors.black38, fontSize: 13),
                              filled: true,
                              fillColor: inputBg,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: borderNeutral),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: borderNeutral),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: primaryTeal, width: 1.5),
                              ),
                              prefixIcon: const Icon(Icons.mail_outline_rounded, color: textMuted, size: 18),
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryTeal,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                elevation: 0,
                              ),
                              onPressed: isSubmitting ? null : submitRequest,
                              child: isSubmitting
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : Text("Send Recovery Link", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                            ),
                          )
                        ],
                      ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showNotificationPopup("Please enter both your registered email and password.");
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        final data = await Supabase.instance.client
            .from('profiles')
            .select('role')
            .eq('id', response.user!.id)
            .maybeSingle();

        String role = data != null && data['role'] != null ? data['role'] : 'patient';

        if (mounted) {
          if (role == 'doctor' || role == 'admin') {
            await Supabase.instance.client.auth.signOut();
            _showNotificationPopup("Access Denied: Healthcare staff and clinicians must log in through the Web Administration Portal.");
          } else {
            // Guard OneSignal for native platforms only (prevents web crash)
            if (!kIsWeb) {
              OneSignal.login(response.user!.id);
            }
            Navigator.pushReplacementNamed(context, '/dashboard');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        _showNotificationPopup("Invalid email or password. Please verify your credentials with the health center.");
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundLight,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // TOP SECTION: Institutional Badge + Header
                            Column(
                              children: [
                                const SizedBox(height: 8),
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
                                const SizedBox(height: 24),
                                _buildLogo(size: 72),
                                const SizedBox(height: 18),
                                Text(
                                  'Welcome to TEREA',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w700,
                                    color: textCharcoal,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Tuberculosis Evaluation, Risk Assessment & Adherence',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: textMuted,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // MIDDLE SECTION: Clinical Form Card
                            Container(
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
                              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildFieldLabel("Email Address"),
                                  const SizedBox(height: 8),
                                  _buildTextField(
                                    hint: "patient@gmail.com",
                                    controller: _emailController,
                                    focusNode: _focusNodeEmail,
                                    icon: Icons.alternate_email_rounded,
                                    keyboardType: TextInputType.emailAddress,
                                  ),
                                  const SizedBox(height: 20),

                                  _buildFieldLabel("Password"),
                                  const SizedBox(height: 8),
                                  _buildTextField(
                                    hint: "••••••••••••",
                                    controller: _passwordController,
                                    focusNode: _focusNodePassword,
                                    icon: Icons.lock_outline_rounded,
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
                                  ),
                                  const SizedBox(height: 12),

                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: _showForgotPasswordDialog,
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: Text(
                                        "Forgot password?",
                                        style: GoogleFonts.inter(
                                          color: primaryTeal,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 28),

                                  // Primary Button
                                  SizedBox(
                                    width: double.infinity,
                                    height: 50,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: primaryTeal,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        elevation: 0,
                                      ),
                                      onPressed: _isLoading ? null : _signIn,
                                      child: _isLoading
                                          ? const SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                            )
                                          : Text(
                                              "Log In",
                                              style: GoogleFonts.inter(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                letterSpacing: 0.2,
                                              ),
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // BOTTOM SECTION: Register Action
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Center(
                                child: TextButton(
                                  onPressed: () => Navigator.pushNamed(context, '/signup'),
                                  child: RichText(
                                    text: TextSpan(
                                      text: "First time using our app? ",
                                      style: GoogleFonts.inter(color: textMuted, fontSize: 13),
                                      children: [
                                        TextSpan(
                                          text: "Register Here",
                                          style: GoogleFonts.inter(
                                            color: primaryTeal,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.inter(
        color: textCharcoal,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
    );
  }

  Widget _buildTextField({
    required String hint,
    required TextEditingController controller,
    required FocusNode focusNode,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      obscureText: isPassword ? obscureText : false,
      keyboardType: keyboardType,
      style: GoogleFonts.inter(color: textCharcoal, fontSize: 14, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: Colors.black26, fontSize: 13),
        prefixIcon: Icon(icon, color: textMuted, size: 19),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: inputBg,
        contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: borderNeutral, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: borderNeutral, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primaryTeal, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildLogo({required double size}) {
    return Hero(
      tag: 'terea_hero_logo',
      child: Container(
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
      ),
    );
  }
}