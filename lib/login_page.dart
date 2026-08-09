import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  late AnimationController _blob1Controller;
  late AnimationController _blob2Controller;

  @override
  void initState() {
    super.initState();
    _blob1Controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    _blob2Controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _blob1Controller.dispose();
    _blob2Controller.dispose();
    super.dispose();
  }

  // --- MODERN CENTERED POPUP ANIMATION ---
  void _showNotificationPopup(String message, {bool isSuccess = false}) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withOpacity(0.4),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) => const SizedBox.shrink(),
      transitionBuilder: (context, a1, a2, child) {
        final color = isSuccess ? const Color(0xFF606C38) : Colors.redAccent;
        final icon = isSuccess ? Icons.check_circle_outline_rounded : Icons.error_outline_rounded;
        
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
                      color: color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 32),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    isSuccess ? "Success" : "Notice",
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

  // --- FORGOT PASSWORD MODAL FLOW ---
  void _showForgotPasswordDialog() {
    final resetEmailController = TextEditingController();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            bool isSubmitting = false;
            String? errorMsg;
            bool success = false;

            Future<void> submitRequest() async {
              final email = resetEmailController.text.trim();
              if (email.isEmpty || !email.contains('@')) {
                setState(() => errorMsg = "Please enter a valid email address.");
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
                  'message': 'Patient requested a password reset from the TEREA Mobile App.',
                  'status': 'Pending',
                });

                setState(() {
                  success = true;
                  isSubmitting = false;
                });
              } catch (e) {
                setState(() {
                  errorMsg = "Failed to send request. Please try again.";
                  isSubmitting = false;
                });
              }
            }

            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: success 
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_outline, color: Color(0xFF606C38), size: 48),
                        const SizedBox(height: 16),
                        Text(
                          "Request Sent",
                          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF2D3B1E)),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "IT Support has received your request. You will receive an email with a secure reset link shortly.",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(color: Colors.black54, fontSize: 14),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF606C38),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: Text("Okay", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
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
                              "Reset Password",
                              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF2D3B1E)),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.black54),
                              onPressed: () => Navigator.pop(context),
                            )
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Enter the email associated with your account to request a password reset.",
                          style: GoogleFonts.poppins(color: Colors.black54, fontSize: 14),
                        ),
                        const SizedBox(height: 20),
                        if (errorMsg != null)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade100),
                            ),
                            child: Text(
                              errorMsg!,
                              style: GoogleFonts.poppins(color: Colors.red.shade700, fontSize: 12),
                            ),
                          ),
                        TextField(
                          controller: resetEmailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText: "Email Address",
                            hintStyle: GoogleFonts.poppins(color: Colors.black26),
                            filled: true,
                            fillColor: const Color(0xFFF4F7F4),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF606C38)),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF606C38),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: isSubmitting ? null : submitRequest,
                            child: isSubmitting
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : Text("Send Request", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        )
                      ],
                    ),
              ), // <-- Fixed: Added closing parenthesis for Padding
            );
          },
        );
      },
    );
  }

  Future<void> _signIn() async {
    setState(() => _isLoading = true);
    try {
      // 1. Perform the Auth Login
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (response.user != null) {
        // 2. FETCH ROLE: Check if this user is a Patient or Doctor
        final data = await Supabase.instance.client
            .from('profiles')
            .select('role')
            .eq('id', response.user!.id)
            .maybeSingle();

        String role =
            data != null && data['role'] != null ? data['role'] : 'patient';

        if (mounted) {
          // 3. ROLE GATEKEEPER
          if (role == 'doctor') {
            await Supabase.instance.client.auth.signOut();
            _showNotificationPopup("Access Denied: Doctors must use the Web Portal.");
          } else {
            OneSignal.login(response.user!.id);
            Navigator.pushReplacementNamed(context, '/dashboard');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        _showNotificationPopup("Login Failed: $e");
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
      body: Stack(
        children: [
          // --- ANIMATED BACKGROUND DECORATIONS ---
          AnimatedBuilder(
            animation: _blob1Controller,
            builder: (context, child) {
              return Positioned(
                top: -80 + (_blob1Controller.value * 20),
                right: -80 + (_blob1Controller.value * 15),
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    color: forestLight.withOpacity(0.06),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          ),
          AnimatedBuilder(
            animation: _blob2Controller,
            builder: (context, child) {
              return Positioned(
                bottom: -120 - (_blob2Controller.value * 30),
                left: -60 + (_blob2Controller.value * 20),
                child: Container(
                  width: 350,
                  height: 350,
                  decoration: BoxDecoration(
                    color: forestLight.withOpacity(0.04),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          ),

          // --- MAIN CONTENT ---
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(child: _buildLogo(size: 70)),
                    const SizedBox(height: 35),
                    
                    Text(
                      'Welcome back',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: forestDark,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sign in to your personalized tracker',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.black45,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 50),

                    // Modern Input Cards
                    Container(
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
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            _buildTextField(
                              label: "Email Address",
                              hint: "you@example.com",
                              controller: _emailController,
                              icon: Icons.alternate_email_rounded,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 24),
                            _buildTextField(
                              label: "Password",
                              hint: "••••••••",
                              isPassword: true,
                              controller: _passwordController,
                              icon: Icons.lock_outline_rounded,
                              obscureText: _obscurePassword,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: Colors.black38,
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
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
                                  style: GoogleFonts.poppins(
                                    color: forestLight,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 40),

                    _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(color: forestDark))
                        : _buildGradientButton(
                            text: "Sign in",
                            onPressed: _signIn,
                            colors: [forestLight, forestDark],
                          ),

                    const SizedBox(height: 30),
                    
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/signup'),
                      style: TextButton.styleFrom(
                        foregroundColor: forestLight,
                        splashFactory: NoSplash.splashFactory,
                      ),
                      child: RichText(
                        text: TextSpan(
                          text: "Don't have an account? ",
                          style: GoogleFonts.poppins(
                            color: Colors.black45, 
                            fontSize: 13,
                            fontWeight: FontWeight.w500
                          ),
                          children: [
                            TextSpan(
                              text: "Create an Account",
                              style: GoogleFonts.poppins(
                                color: forestDark,
                                fontWeight: FontWeight.w700,
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
          ),
        ],
      ),
    );
  }

  // Modernized Text Field
  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    bool isPassword = false,
    bool obscureText = false,
    IconData? icon,
    Widget? suffixIcon,
    TextInputType? keyboardType,
  }) {
    const Color forestDark = Color(0xFF2D3B1E);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            color: forestDark,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
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
            obscureText: isPassword ? obscureText : false,
            keyboardType: keyboardType,
            style: GoogleFonts.poppins(
              color: forestDark, 
              fontSize: 14, 
              fontWeight: FontWeight.w500
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.poppins(
                color: Colors.black26, 
                fontSize: 14
              ),
              prefixIcon: Icon(icon, color: Colors.black38, size: 20),
              suffixIcon: suffixIcon,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            ),
          ),
        ),
      ],
    );
  }

  // Modernized Pill-Shaped Button
  Widget _buildGradientButton({
    required String text,
    required VoidCallback onPressed,
    required List<Color> colors,
  }) {
    return Container(
      width: double.infinity,
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
          splashColor: Colors.white.withOpacity(0.1),
          highlightColor: Colors.transparent,
          child: Center(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 15,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Updated to load your custom logo with a modern rounded-square clipping
  Widget _buildLogo({required double size}) {
    return Container(
      width: size * 1.4,
      height: size * 1.4,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Image.asset(
          'assets/NoBackgroundLogo.png',
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}