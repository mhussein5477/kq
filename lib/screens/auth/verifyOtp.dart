import 'package:expressive_loading_indicator/expressive_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jwt_decode/jwt_decode.dart';
import 'dart:async';

import 'package:kq/screens/auth/completeRegistration.dart';
import 'package:kq/screens/home/homePage.dart';
import 'package:kq/services/api_service.dart';
import 'package:kq/services/secure_storage_service.dart';

class OtpVerification extends StatefulWidget {
  final String place, email, mfaToken;
  const OtpVerification({
    super.key,
    required this.place,
    required this.email,
    required this.mfaToken,
  });

  @override
  State<OtpVerification> createState() => _OtpVerificationState();
}

class _OtpVerificationState extends State<OtpVerification> {
  final List<TextEditingController> _otpControllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());

  int _seconds = 152; // 2:32 in seconds
  Timer? _timer;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_seconds > 0) {
        setState(() {
          _seconds--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  String get _timerText {
    int minutes = _seconds ~/ 60;
    int seconds = _seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  int _getOtp() {
    final otpString = _otpControllers.map((c) => c.text).join();

    if (otpString.length != 4) {
      throw Exception('Enter complete 4-digit code');
    }

    return int.parse(otpString);
  }

  bool _isResending = false;

  Future<void> _resendOtp() async {
    setState(() {
      _isResending = true;
    });

    try {
      await ApiService.verifyMember(emailAddress: widget.email);

      // reset timer
      setState(() {
        _seconds = 152;
      });

      _startTimer();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    } finally {
      setState(() {
        _isResending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const SizedBox(height: 60),

                // Shield Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8E5F5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.shield_outlined,
                    size: 40,
                    color: Color(0xFF6C5DD3),
                  ),
                ),

                const SizedBox(height: 32),

                // Title
                const Text(
                  'Enter Verification Code',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 12),

                // Subtitle
                Text(
                  "We've sent a 4-digit code to your email",
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 40),

                // OTP Input Boxes (4 fields)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      child: SizedBox(
                        width: 45,
                        height: 55,
                        child: TextField(
                          controller: _otpControllers[index],
                          focusNode: _focusNodes[index],
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          maxLength: 1,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          decoration: InputDecoration(
                            counterText: '',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey[300]!,
                                width: 1.5,
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
                              vertical: 16,
                            ),
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          onChanged: (value) {
                            if (value.isNotEmpty && index < 3) {
                              _focusNodes[index + 1].requestFocus();
                            } else if (value.isEmpty && index > 0) {
                              _focusNodes[index - 1].requestFocus();
                            }
                          },
                        ),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 16),

                // Timer + Resend
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _timerText,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFFFA726),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: (_seconds == 0 && !_isResending)
                          ? _resendOtp
                          : null,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: _isResending
                          ? const SizedBox(
                              height: 14,
                              width: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              'Resend?',
                              style: TextStyle(
                                fontSize: 14,
                                color: _seconds == 0
                                    ? const Color(0xFFE31E24)
                                    : Colors.grey[400],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                    ),
                  ],
                ),

                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ),

                const SizedBox(height: 32),

                // Verify Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () async {
                            setState(() {
                              _isLoading = true;
                              _errorMessage = null;
                            });

                            try {
                              final otp = _getOtp();

                              // ✅ OTP verified
                              if (widget.place == 'login') {
                                final response = await ApiService.verifyMfa(
                                  emailAddress: widget.email,
                                  otp: otp,
                                  mfaToken: widget.mfaToken,
                                );

                                final data = response['data'];

                                if (data == null)
                                  throw Exception('MFA verification failed');

                                // 1️⃣ Save Access token with details
                                final accessTokenData = data['accessToken'];
                                if (accessTokenData != null) {
                                  final token =
                                      accessTokenData['access_token'] ?? '';
                                  final type =
                                      accessTokenData['token_type'] ?? 'Bearer';
                                  final expiresIn =
                                      accessTokenData['expires_in'] ?? 3600;

                                  await SecureStorageService.saveAccessToken(
                                    accessToken: token,
                                    tokenType: type,
                                    expiresIn: expiresIn,
                                  );
                                }

                                // 2️⃣ Save USER token (contains member details)
                                final String userToken =
                                    data['userToken'] ?? '';
                                await SecureStorageService.saveUserToken(
                                  userToken,
                                );

                                if (userToken.isNotEmpty) {
                                  Map<String, dynamic> decodedToken =
                                      Jwt.parseJwt(userToken);
                                  final user = decodedToken['user'] ?? {};
                                  if (user.isNotEmpty) {
                                    await SecureStorageService.saveMemberDetails(
                                      user,
                                    );
                                  }
                                }

                                // ✅ MFA token is single-use — remove it
                                await SecureStorageService.deleteMfaToken();

                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(
                                    builder: (_) => const HomePage(),
                                  ),
                                  (route) => false,
                                );
                              } else {
                                await ApiService.verifyMemberOTP(
                                  emailAddress: widget.email,
                                  otp: otp,
                                );

                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => CompleteRegistration(
                                      email: widget.email,
                                    ),
                                  ),
                                );
                              }
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
                            'Verify & Continue',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 24),

                // Info Box
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F4FD),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "Didn't receive the code? Check your spam folder or try a different method.",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 100),

                // Footer
                Text(
                  'Powered By Deft Technologies · KE. Contact Us',
                  style: TextStyle(color: Colors.grey[600], fontSize: 11),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
