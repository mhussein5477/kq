import 'package:expressive_loading_indicator/expressive_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:kq/screens/auth/forgotPass.dart';
import 'package:kq/screens/auth/register.dart';
import 'package:kq/screens/auth/verifyOtp.dart';
import 'package:kq/services/secure_storage_service.dart';
import 'package:kq/widgets/appBarAuth.dart';
import 'package:local_auth/local_auth.dart';
import 'package:jwt_decode/jwt_decode.dart';
import 'package:kq/services/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final LocalAuthentication _localAuth = LocalAuthentication();

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _hasTriedAutoAuth = false;

  @override
  void initState() {
    super.initState();
    _checkAndTriggerBiometrics();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _checkAndTriggerBiometrics() async {
    if (_hasTriedAutoAuth) return;
    _hasTriedAutoAuth = true;

    try {
      final creds = await SecureStorageService.getCredentials();
      final email = creds['email'];
      final password = creds['password'];

      if (email == null || password == null) {
        return;
      }

      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      if (!canCheckBiometrics) {
        return;
      }

      await Future.delayed(const Duration(milliseconds: 500));
      await _handleFingerprintLogin();
    } catch (e) {
      print('Auto-auth failed: $e');
    }
  }

  Future<void> _handleFingerprintLogin() async {
    try {
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      if (!canCheckBiometrics) {
        throw Exception('Biometric authentication not available');
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to sign in',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (!authenticated) return;

      final creds = await SecureStorageService.getCredentials();
      final email = creds['email'];
      final password = creds['password'];

      if (email == null || password == null) {
        throw Exception('No saved credentials found');
      }

      setState(() {
        _emailController.text = email;
        _passwordController.text = password;
      });

      await _handleSignIn();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    }
  }

  Future<void> _handleSignIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final loginResponse = await ApiService.signIn(
        emailAddress: email,
        password: password,
      );

      print('Login Response: $loginResponse');

      final data = loginResponse['data'];
      if (data == null) throw Exception('Login data not found');

      final String mfaToken = data['mfaToken'] ?? '';
      await SecureStorageService.saveMfaToken(mfaToken);

      await SecureStorageService.saveCredentials(
        email: email,
        password: password,
      );

      if (!mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              OtpVerification(place: 'login', email: email, mfaToken: mfaToken),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      String errorMessage = e.toString().replaceAll('Exception: ', '');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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
            height: MediaQuery.of(context).size.height,
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AuthBar(),

                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      // Illustration
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE31E24).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.person,
                          size: 60,
                          color: Color(0xFFE31E24),
                        ),
                      ),

                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Welcome Back ',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                          const Text('👋', style: TextStyle(fontSize: 20)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sign in to access your pension account',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),

                      const SizedBox(height: 22),

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
                            style: TextStyle(
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                            decoration: InputDecoration(
                              prefixIcon: Icon(
                                Icons.email_outlined,
                                size: 20,
                                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                              ),
                              filled: true,
                              fillColor: isDarkMode 
                                  ? const Color(0xFF2A2A2A) 
                                  : Colors.grey[50],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: isDarkMode 
                                      ? Colors.grey[800]! 
                                      : Colors.grey[300]!,
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

                      const SizedBox(height: 15),

                      // Password field
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Password',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isDarkMode ? Colors.white70 : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: TextStyle(
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                            decoration: InputDecoration(
                              prefixIcon: Icon(
                                Icons.lock_outline,
                                size: 20,
                                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  size: 20,
                                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              filled: true,
                              fillColor: isDarkMode 
                                  ? const Color(0xFF2A2A2A) 
                                  : Colors.grey[50],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: isDarkMode 
                                      ? Colors.grey[800]! 
                                      : Colors.grey[300]!,
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

                      const SizedBox(height: 3),

                      // Forgot password
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                             Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ForgotPasswordScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(
                              color: Color(0xFFE31E24),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 4),

                      // Sign in button
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleSignIn,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE31E24),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                disabledBackgroundColor: Colors.grey[400],
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 28,
                                      child: Center(
                                        child: SizedBox(
                                          height: 30,
                                          width: 30,
                                          child: ExpressiveLoadingIndicator(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    )
                                  : const Text(
                                      'Sign In',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: isDarkMode 
                                  ? Colors.grey[800] 
                                  : Colors.grey[200],
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              onPressed: _isLoading ? null : _handleFingerprintLogin,
                              icon: Icon(
                                Icons.fingerprint,
                                size: 32,
                                color: isDarkMode ? Colors.white70 : Colors.black54,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // ----- or -----
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'or',
                              style: TextStyle(
                                color: isDarkMode 
                                    ? Colors.grey[500] 
                                    : Colors.grey[600],
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Register button (Outlined)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const Register(),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(
                              color: Color(0xFFE31E24),
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text(
                            'Register',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFE31E24),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Footer
                      Text(
                        'Powered By Deft Technologies · KE. Contact Us',
                        style: TextStyle(
                          color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                          fontSize: 11,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}