import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_service.dart';
import 'login_screen.dart';
import '../theme/app_theme.dart';

class SignupOtpScreen extends StatefulWidget {
  final Map signupData;

  const SignupOtpScreen({
    super.key,
    required this.signupData,
  });

  @override
  State<SignupOtpScreen> createState() =>
      _SignupOtpScreenState();
}

class _SignupOtpScreenState
    extends State<SignupOtpScreen> {

  final otpController =
      TextEditingController();

  bool loading = false;

  Future<void> verifyOtp() async {

    if(otpController.text.trim().isEmpty){

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            "Enter verification code",
          ),
        ),
      );

      return;
    }

    setState(() {
      loading = true;
    });

    var res =
    await ApiService.verifySignupOtp(
      widget.signupData,
      otpController.text.trim(),
    );

    setState(() {
      loading = false;
    });

    if(res["success"] == true){

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            res["message"],
          ),
        ),
      );

      Navigator.pushAndRemoveUntil(

        context,

        MaterialPageRoute(
          builder: (_) =>
          const LoginScreen(),
        ),

            (route) => false,
      );

    }else{

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            res["message"],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text("Email Verification"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mark_email_read_rounded,
                    size: 80,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  "Verify Your Email",
                  style: GoogleFonts.outfit(
                    color: AppTheme.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "We've sent a verification code to",
                  style: GoogleFonts.outfit(
                    color: AppTheme.textSecondary,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  widget.signupData["email"],
                  style: GoogleFonts.outfit(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      TextField(
                        controller: otpController,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.outfit(
                          color: AppTheme.textPrimary,
                          fontSize: 24,
                          letterSpacing: 8,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          hintText: "000000",
                          hintStyle: GoogleFonts.outfit(
                            color: AppTheme.textSecondary.withOpacity(0.5),
                            letterSpacing: 8,
                          ),
                          filled: true,
                          fillColor: AppTheme.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 20),
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 5,
                            shadowColor: AppTheme.primary.withOpacity(0.5),
                          ),
                          onPressed: loading ? null : verifyOtp,
                          child: loading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text(
                                  "Verify & Continue",
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}