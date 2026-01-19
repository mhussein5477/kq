import 'package:expressive_loading_indicator/expressive_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kq/screens/auth/login.dart';
import 'package:kq/services/api_service.dart';
import 'package:kq/widgets/appBarAuth.dart';
import 'dart:async';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  // Step management
  String currentStep = 'email'; // 'email', 'otp', 'newPassword'

  // Form controllers
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // OTP controllers - 6 separate inputs
  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());

  // Token from OTP verification
  String _resetToken = '';

  // Loading states
  bool _isSubmittingEmail = false;
  bool _isVerifyingOtp = false;
  bool _isResettingPassword = false;

  // Password visibility
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  // Timer for resend OTP
  int _resendTimer = 0;
  Timer? _resendInterval;

  @override
  void dispose() {
    _emailController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    _resendInterval?.cancel();
    super.dispose();
  }

  /// Submit email to request password reset OTP
  Future<void> _submitEmail() async {
    final email = _emailController.text.trim();

    // Validate email
    if (email.isEmpty) {
      _showSnackBar('Please enter your email address', Colors.orange);
      return;
    }

    // Basic email validation
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegex.hasMatch(email)) {
      _showSnackBar('Please enter a valid email address', Colors.orange);
      return;
    }

    setState(() {
      _isSubmittingEmail = true;
    });

    try {
      await ApiService.forgotPassword(emailAddress: email);

      if (!mounted) return;

      _showSnackBar('OTP sent to your email!', Colors.green);

      setState(() {
        _isSubmittingEmail = false;
        currentStep = 'otp';
      });

      _startResendTimer();
    } catch (e) {
      if (!mounted) return;

      final errorMessage = e.toString().replaceAll('Exception: ', '');
      _showSnackBar(errorMessage, Colors.red);

      setState(() {
        _isSubmittingEmail = false;
      });
    }
  }

  /// Verify OTP
  Future<void> _verifyOtp() async {
    // Get OTP from controllers
    String otp = '';
    for (var controller in _otpControllers) {
      otp += controller.text;
    }

    // Validate OTP
    if (otp.isEmpty) {
      _showSnackBar('Please enter the OTP', Colors.orange);
      return;
    }

    if (otp.length < 4) {
      _showSnackBar('Please enter a valid OTP', Colors.orange);
      return;
    }

    setState(() {
      _isVerifyingOtp = true;
    });

    try {
      final response = await ApiService.verifyOtp(
        emailAddress: _emailController.text.trim(),
        otp: int.parse(otp),
      );

      if (!mounted) return;

      // Extract token from response
      _resetToken = response['data']?['token'] ?? response['token'] ?? '';

      if (_resetToken.isEmpty) {
        _showSnackBar('Invalid response from server. Please try again.', Colors.red);
        setState(() {
          _isVerifyingOtp = false;
        });
        return;
      }

      _showSnackBar('OTP verified successfully!', Colors.green);

      setState(() {
        _isVerifyingOtp = false;
        currentStep = 'newPassword';
      });

      _resendInterval?.cancel();
    } catch (e) {
      if (!mounted) return;

      final errorMessage = e.toString().replaceAll('Exception: ', '');
      _showSnackBar(errorMessage, Colors.red);

      setState(() {
        _isVerifyingOtp = false;
      });
    }
  }

  /// Reset password with token
  Future<void> _resetPassword() async {
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // Validate passwords
    if (newPassword.isEmpty) {
      _showSnackBar('Please enter a new password', Colors.orange);
      return;
    }

    if (newPassword.length < 6) {
      _showSnackBar('Password must be at least 6 characters', Colors.orange);
      return;
    }

    if (confirmPassword.isEmpty) {
      _showSnackBar('Please confirm your password', Colors.orange);
      return;
    }

    if (newPassword != confirmPassword) {
      _showSnackBar('Passwords do not match', Colors.orange);
      return;
    }

    setState(() {
      _isResettingPassword = true;
    });

    try {
      await ApiService.changePasswordWithToken(
        emailAddress: _emailController.text.trim(),
        password: newPassword,
        token: _resetToken,
      );

      if (!mounted) return;

      _showSnackBar('Password reset successfully!', Colors.green);

      // Navigate back to login after a short delay
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;

      final errorMessage = e.toString().replaceAll('Exception: ', '');
      _showSnackBar(errorMessage, Colors.red);

      setState(() {
        _isResettingPassword = false;
      });
    }
  }

  /// Resend OTP
  Future<void> _resendOtp() async {
    if (_resendTimer > 0) return;

    setState(() {
      _isSubmittingEmail = true;
    });

    try {
      await ApiService.forgotPassword(emailAddress: _emailController.text.trim());

      if (!mounted) return;

      _showSnackBar('OTP resent successfully!', Colors.green);

      setState(() {
        _isSubmittingEmail = false;
      });

      _startResendTimer();
    } catch (e) {
      if (!mounted) return;

      final errorMessage = e.toString().replaceAll('Exception: ', '');
      _showSnackBar(errorMessage, Colors.red);

      setState(() {
        _isSubmittingEmail = false;
      });
    }
  }

  /// Start resend timer (60 seconds)
  void _startResendTimer() {
    _resendInterval?.cancel();

    setState(() {
      _resendTimer = 60;
    });

    _resendInterval = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _resendTimer--;
        if (_resendTimer <= 0) {
          _resendInterval?.cancel();
        }
      });
    });
  }

  /// Show SnackBar
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Go back to email step
  void _goBackToEmail() {
    setState(() {
      currentStep = 'email';
      for (var controller in _otpControllers) {
        controller.clear();
      }
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      _resetToken = '';
      _resendTimer = 0;
    });
    _resendInterval?.cancel();
  }

  /// Go back to OTP step
  void _goBackToOtp() {
    setState(() {
      currentStep = 'otp';
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      _showNewPassword = false;
      _showConfirmPassword = false;
    });
  }

  /// Navigate back to login
  void _goToLogin() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  /// Get password strength
  Map<String, dynamic> _getPasswordStrength(String password) {
    if (password.isEmpty) {
      return {'text': '', 'color': Colors.grey, 'width': 0.0};
    }

    int strength = 0;
    if (password.length >= 6) strength++;
    if (password.length >= 10) strength++;
    if (RegExp(r'[a-z]').hasMatch(password) && RegExp(r'[A-Z]').hasMatch(password)) strength++;
    if (RegExp(r'\d').hasMatch(password)) strength++;
    if (RegExp(r'[^a-zA-Z\d]').hasMatch(password)) strength++;

    if (strength <= 2) {
      return {'text': 'Weak', 'color': Colors.red, 'width': 0.33};
    } else if (strength <= 4) {
      return {'text': 'Medium', 'color': Colors.orange, 'width': 0.66};
    } else {
      return {'text': 'Strong', 'color': Colors.green, 'width': 1.0};
    }
  }

  /// Handle OTP input
  void _handleOtpInput(int index, String value) {
    // Only allow numbers
    if (value.isNotEmpty && !RegExp(r'^\d$').hasMatch(value)) {
      _otpControllers[index].clear();
      return;
    }

    // Auto-focus next input
    if (value.isNotEmpty && index < 5) {
      FocusScope.of(context).nextFocus();
    }
  }

  /// Handle OTP backspace
  void _handleOtpKeydown(int index, RawKeyEvent event) {
    if (event.isKeyPressed(LogicalKeyboardKey.backspace)) {
      if (_otpControllers[index].text.isEmpty && index > 0) {
        FocusScope.of(context).previousFocus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top,
            decoration: BoxDecoration(
              color: theme.cardColor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AuthBar(),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          // STEP 1: Email Input
                          if (currentStep == 'email') ...[
                            // Back to Login
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                onPressed: _goToLogin,
                                icon: const Icon(Icons.arrow_back, size: 18),
                                label: const Text('Back to Login'),
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFFE31E24),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Icon
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE31E24).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(
                                Icons.lock_outline,
                                size: 60,
                                color: Color(0xFFE31E24),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Title
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Forgot Password? ',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: isDarkMode ? Colors.white : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Enter your email address and we\'ll send you an OTP to reset your password.',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),

                            // Email field
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Email Address',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: isDarkMode ? Colors.white70 : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  enabled: !_isSubmittingEmail,
                                  style: TextStyle(
                                    color: isDarkMode ? Colors.white : Colors.black,
                                  ),
                                  onSubmitted: (_) => _submitEmail(),
                                  decoration: InputDecoration(
                                    prefixIcon: Icon(
                                      Icons.email_outlined,
                                      size: 20,
                                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                    ),
                                    filled: true,
                                    fillColor: isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey[50],
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFE31E24),
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Submit Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isSubmittingEmail ? null : _submitEmail,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFE31E24),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  disabledBackgroundColor: Colors.grey[400],
                                ),
                                child: _isSubmittingEmail
                                    ? const SizedBox(
                                        height: 28,
                                        child: Center(
                                          child: SizedBox(
                                            height: 24,
                                            width: 24,
                                            child: ExpressiveLoadingIndicator(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      )
                                    : const Text(
                                        'Send OTP',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                          ],

                          // STEP 2: OTP Verification
                          if (currentStep == 'otp') ...[
                            // Back Button
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                onPressed: _goBackToEmail,
                                icon: const Icon(Icons.arrow_back, size: 18),
                                label: const Text('Change Email'),
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFFE31E24),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Icon
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE31E24).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(
                                Icons.mail_outline,
                                size: 60,
                                color: Color(0xFFE31E24),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Title
                            Text(
                              'Verify OTP',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'We\'ve sent a verification code to',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _emailController.text,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // OTP Input Fields
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Enter OTP Code',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: isDarkMode ? Colors.white70 : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: List.generate(
                                    6,
                                    (index) => SizedBox(
                                      width: 45,
                                      height: 50,
                                      child: TextField(
                                        controller: _otpControllers[index],
                                        textAlign: TextAlign.center,
                                        keyboardType: TextInputType.number,
                                        maxLength: 1,
                                        enabled: !_isVerifyingOtp,
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: isDarkMode ? Colors.white : Colors.black,
                                        ),
                                        onChanged: (value) => _handleOtpInput(index, value),
                                        decoration: InputDecoration(
                                          counterText: '',
                                          filled: true,
                                          fillColor: isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey[50],
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide.none,
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(
                                              color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: const BorderSide(
                                              color: Color(0xFFE31E24),
                                              width: 2,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Resend OTP
                            Center(
                              child: Column(
                                children: [
                                  Text(
                                    'Didn\'t receive the code?',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextButton(
                                    onPressed: (_resendTimer > 0 || _isSubmittingEmail) ? null : _resendOtp,
                                    child: Text(
                                      _resendTimer > 0
                                          ? 'Resend in ${_resendTimer}s'
                                          : _isSubmittingEmail
                                              ? 'Sending...'
                                              : 'Resend OTP',
                                      style: const TextStyle(
                                        color: Color(0xFFE31E24),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Verify Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: (_isVerifyingOtp || _getOtpLength() < 4) ? null : _verifyOtp,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFE31E24),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  disabledBackgroundColor: Colors.grey[400],
                                ),
                                child: _isVerifyingOtp
                                    ? const SizedBox(
                                        height: 28,
                                        child: Center(
                                          child: SizedBox(
                                            height: 24,
                                            width: 24,
                                            child: ExpressiveLoadingIndicator(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      )
                                    : const Text(
                                        'Verify OTP',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                          ],

                          // STEP 3: New Password
                          if (currentStep == 'newPassword') ...[
                            // Back Button
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                onPressed: _goBackToOtp,
                                icon: const Icon(Icons.arrow_back, size: 18),
                                label: const Text('Back'),
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFFE31E24),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Icon
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE31E24).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(
                                Icons.vpn_key_outlined,
                                size: 60,
                                color: Color(0xFFE31E24),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Title
                            Text(
                              'Create New Password',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Enter your new password below',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // New Password Field
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'New Password',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: isDarkMode ? Colors.white70 : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _newPasswordController,
                                  obscureText: !_showNewPassword,
                                  enabled: !_isResettingPassword,
                                  style: TextStyle(
                                    color: isDarkMode ? Colors.white : Colors.black,
                                  ),
                                  onChanged: (_) => setState(() {}),
                                  onSubmitted: (_) => _resetPassword(),
                                  decoration: InputDecoration(
                                    prefixIcon: Icon(
                                      Icons.lock_outline,
                                      size: 20,
                                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _showNewPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                        size: 20,
                                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                      ),
                                      onPressed: () => setState(() {
                                        _showNewPassword = !_showNewPassword;
                                      }),
                                    ),
                                    filled: true,
                                    fillColor: isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey[50],
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFE31E24),
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                                if (_newPasswordController.text.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: _getPasswordStrength(_newPasswordController.text)['width'],
                                      backgroundColor: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        _getPasswordStrength(_newPasswordController.text)['color'],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Strength: ${_getPasswordStrength(_newPasswordController.text)['text']}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _getPasswordStrength(_newPasswordController.text)['color'],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Confirm Password Field
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Confirm Password',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: isDarkMode ? Colors.white70 : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _confirmPasswordController,
                                  obscureText: !_showConfirmPassword,
                                  enabled: !_isResettingPassword,
                                  style: TextStyle(
                                    color: isDarkMode ? Colors.white : Colors.black,
                                  ),
                                  onChanged: (_) => setState(() {}),
                                  onSubmitted: (_) => _resetPassword(),
                                  decoration: InputDecoration(
                                    prefixIcon: Icon(
                                      Icons.lock_outline,
                                      size: 20,
                                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _showConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                        size: 20,
                                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                      ),
                                      onPressed: () => setState(() {
                                        _showConfirmPassword = !_showConfirmPassword;
                                      }),
                                    ),
                                    filled: true,
                                    fillColor: isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey[50],
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFE31E24),
                                        width: 2,
                                      ),
                                    ),
                                    errorBorder: _confirmPasswordController.text.isNotEmpty &&
                                            _newPasswordController.text != _confirmPasswordController.text
                                        ? OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: const BorderSide(
                                              color: Colors.red,
                                            ),
                                          )
                                        : null,
                                  ),
                                ),
                                if (_confirmPasswordController.text.isNotEmpty &&
                                    _newPasswordController.text != _confirmPasswordController.text) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.error_outline, color: Colors.red, size: 16),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Passwords do not match',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Reset Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isResettingPassword ? null : _resetPassword,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFE31E24),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  disabledBackgroundColor: Colors.grey[400],
                                ),
                                child: _isResettingPassword
                                    ? const SizedBox(
                                        height: 28,
                                        child: Center(
                                          child: SizedBox(
                                            height: 24,
                                            width: 24,
                                            child: ExpressiveLoadingIndicator(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      )
                                    : const Text(
                                        'Reset Password',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int _getOtpLength() {
    return _otpControllers.where((controller) => controller.text.isNotEmpty).length;
  }
}