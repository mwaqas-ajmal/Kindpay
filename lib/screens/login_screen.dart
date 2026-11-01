import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_service.dart';
import 'signup_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../utils/glass_card.dart';
import '../utils/gradient_button.dart';

import 'user/user_dashboard.dart';
import 'ngo/ngo_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  bool loading = false;
  bool obscure = true;

  // =====================================================
  // 🔐 LOGIN
  // =====================================================

  Future<void> loginUser() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      var res = await ApiService.login(
        emailController.text.trim(),
        passwordController.text.trim(),
      );

      print("LOGIN RESPONSE: $res");

      if (res['success'] == true) {
        // 🔥 SAFE USER DATA
        Map userData = {
          "id": res['id']?.toString() ?? "",
          "username": res['username']?.toString() ?? "",
          "email": res['email']?.toString() ?? "",
          "phone": res['phone']?.toString() ?? "",
          "role": res['role']?.toString() ?? "",
          "address": res['address']?.toString() ?? "",
        };

        // =====================================================
        // SAVE LOGIN SESSION
        // =====================================================
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool("isLoggedIn", true);
        await prefs.setString("id", userData['id']);
        await prefs.setString("username", userData['username']);
        await prefs.setString("email", userData['email']);
        await prefs.setString("phone", userData['phone']);
        await prefs.setString("role", userData['role']);
        await prefs.setString("address", userData['address']);
        await prefs.setString("status", res['status']?.toString() ?? "approved");

        if (!mounted) return;

        // 👤 USER LOGIN
        if (res['role'] == "user") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => UserDashboard(userData: userData),
            ),
          );
        }
        // 🏢 NGO LOGIN
        else if (res['role'] == "ngo") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => NgoDashboard(
                userData: userData,
                status: res['status']?.toString() ?? "pending",
              ),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? "Invalid Login")),
        );
      }
    } catch (e) {
      print("LOGIN ERROR => $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Network error")),
      );
    }

    setState(() {
      loading = false;
    });
  }

  // =====================================================
  // 🔥 UI
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // 🌟 MODERN BACKGROUND ACCENTS
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.primary.withOpacity(0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            right: -50,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.secondary.withOpacity(0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GlassCard(
                opacity: 0.05,
                blur: 20,
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 🌟 LOGO
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primary.withOpacity(0.2),
                            AppTheme.secondary.withOpacity(0.2),
                          ],
                        ),
                      ),
                      child: const Icon(
                        Icons.volunteer_activism_rounded,
                        size: 64,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 24),

                    Text(
                      "KindPay",
                      style: GoogleFonts.outfit(
                        color: AppTheme.textPrimary,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Text(
                      "Helping Humanity Together",
                      style: GoogleFonts.outfit(
                        color: AppTheme.textSecondary,
                        fontSize: 16,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // 📧 EMAIL
                    TextField(
                      controller: emailController,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        hintText: "Email Address",
                        prefixIcon: const Icon(Icons.email_outlined, color: AppTheme.textSecondary),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 🔒 PASSWORD
                    TextField(
                      controller: passwordController,
                      obscureText: obscure,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        hintText: "Password",
                        prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppTheme.textSecondary),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: AppTheme.textSecondary,
                          ),
                          onPressed: () {
                            setState(() {
                              obscure = !obscure;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // 🔥 LOGIN BUTTON
                    GradientButton(
                      text: "Sign In",
                      onPressed: loading ? null : loginUser,
                      isLoading: loading,
                    ),
                    const SizedBox(height: 24),

                    // 🔥 SIGNUP
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account?",
                          style: GoogleFonts.outfit(color: AppTheme.textSecondary),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const SignupScreen()),
                            );
                          },
                          child: Text(
                            "Sign Up",
                            style: GoogleFonts.outfit(
                              color: AppTheme.secondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      ],
                    )
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}