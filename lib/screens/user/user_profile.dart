import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/api_service.dart';
import '../login_screen.dart';
import '../../theme/app_theme.dart';

class UserProfile extends StatefulWidget {

  final Map userData;

  const UserProfile({

    super.key,

    required this.userData,
  });

  @override
  State<UserProfile> createState() =>
      _UserProfileState();
}

class _UserProfileState
    extends State<UserProfile> {

  Map? user;

  bool loading = true;

  @override
  void initState() {

    super.initState();

    fetchUser();
  }

  Future<void> fetchUser() async {

    var res =
    await ApiService.getUser(

      widget.userData['id']
          .toString(),
    );

    if(res['success'] == true &&
        res['user'] != null){

      setState(() {

        user =
        Map<String,dynamic>.from(
          res['user'],
        );

        loading = false;
      });

    }else{

      setState(() {

        user = null;

        loading = false;
      });
    }
  }

  Widget infoTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              icon,
              color: AppTheme.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    color: AppTheme.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text("My Profile"),
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            )
          : user == null
              ? Center(
                  child: Text(
                    "No data found",
                    style: GoogleFonts.outfit(color: AppTheme.textSecondary),
                  ),
                )
              : SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 130),
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [AppTheme.primary, AppTheme.secondary],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primary.withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 3,
                                  ),
                                ),
                                child: const CircleAvatar(
                                  radius: 45,
                                  backgroundColor: AppTheme.cardColor,
                                  child: Icon(
                                    Icons.person_rounded,
                                    size: 55,
                                    color: AppTheme.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                user!['username'].toString(),
                                textAlign: TextAlign.center,
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                user!['role'].toString().toUpperCase(),
                                style: GoogleFonts.outfit(
                                  color: Colors.white70,
                                  fontSize: 15,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        infoTile(
                          icon: Icons.email_rounded,
                          title: "Email Address",
                          value: user!['email']?.toString() ?? "N/A",
                        ),
                        infoTile(
                          icon: Icons.phone_rounded,
                          title: "Phone Number",
                          value: user!['phone']?.toString() ?? "N/A",
                        ),
                        infoTile(
                          icon: Icons.verified_user_rounded,
                          title: "Account Role",
                          value: user!['role']?.toString() ?? "N/A",
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  backgroundColor: AppTheme.cardColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  title: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: AppTheme.danger.withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.logout_rounded,
                                          color: AppTheme.danger,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        "Logout",
                                        style: GoogleFonts.outfit(
                                          color: AppTheme.textPrimary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20,
                                        ),
                                      ),
                                    ],
                                  ),
                                  content: Text(
                                    "Are you sure you want to logout from your account?",
                                    style: GoogleFonts.outfit(
                                      color: AppTheme.textSecondary,
                                      fontSize: 15,
                                      height: 1.5,
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, false),
                                      child: Text(
                                        "Cancel",
                                        style: GoogleFonts.outfit(
                                          color: AppTheme.textSecondary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.danger,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                      ),
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: Text(
                                        "Yes, Logout",
                                        style: GoogleFonts.outfit(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmed != true) return;
                              SharedPreferences prefs = await SharedPreferences.getInstance();
                              // ✅ Only clear session keys, NOT request data
                              await prefs.remove('isLoggedIn');
                              await prefs.remove('id');
                              await prefs.remove('username');
                              await prefs.remove('email');
                              await prefs.remove('phone');
                              await prefs.remove('role');
                              await prefs.remove('address');
                              await prefs.remove('status');
                              if (!mounted) return;
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LoginScreen(),
                                ),
                                (route) => false,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.danger,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            icon: const Icon(Icons.logout_rounded),
                            label: Text(
                              "Logout",
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
    );
  }
}