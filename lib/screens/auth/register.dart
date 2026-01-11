import 'package:expressive_loading_indicator/expressive_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:kq/screens/auth/verifyOtp.dart';
import 'package:kq/services/api_service.dart';
import 'package:kq/widgets/appBarAuth.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  bool _isLoading = false;
  String? _errorMessage;

  final TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            height: MediaQuery.of(context).size.height,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Red header with logo
                AuthBar(),

                // Form content
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      // Illustration
                      Container(
                        width: MediaQuery.of(context).size.width * 0.5,
                        height: MediaQuery.of(context).size.height * 0.2,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Image.asset(
                          'assets/images/register.png',
                          fit: BoxFit.contain,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Welcome text
                      const Text(
                        "We'll verify your email to get you started.",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Enter your email address to check your membership, receive an OTP for verification, and securely set your password.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 32),

                      // Email field
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Email Address',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              hintText: 'johnDoe@gmail.com',
                              hintStyle: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 14,
                              ),
                              prefixIcon: Icon(
                                Icons.email_outlined,
                                size: 20,
                                color: Colors.grey[600],
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE31E24),
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 13,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                      // Verify button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading
                              ? null
                              : () async {
                                  final email = _emailController.text.trim();

                                  if (email.isEmpty) {
                                    setState(() {
                                      _errorMessage =
                                          'Email address is required';
                                    });
                                    return;
                                  }

                                  setState(() {
                                    _isLoading = true;
                                    _errorMessage = null;
                                  });

                                  try {
                                    final response =
                                        await ApiService.verifyMember(
                                          emailAddress: email,
                                        );

                                    // ✅ OTP sent successfully
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => OtpVerification(
                                          place: 'register',
                                          email: email,
                                          mfaToken: '', // pass email forward
                                        ),
                                      ),
                                    );
                                  } catch (e) {
                                    setState(() {
                                      _errorMessage = e.toString().replaceAll(
                                        'Exception: ',
                                        '',
                                      );
                                    });
                                  } finally {
                                    setState(() {
                                      _isLoading = false;
                                    });
                                  }
                                },

                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE31E24),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 28,
                                  child: Center(
                                    child: SizedBox(
                                      height: 30,
                                      width: 30,
                                      child: ExpressiveLoadingIndicator(
                                        color: Colors.red,
                                      ),
                                    ),
                                  ),
                                )
                              : const Text(
                                  'Verify',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 80),

                      // Footer
                      Text(
                        'Powered By Deft Technologies · KE. Contact Us',
                        style: TextStyle(color: Colors.grey[600], fontSize: 11),
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
