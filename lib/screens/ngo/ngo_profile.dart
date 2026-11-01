import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/api_service.dart';
import '../login_screen.dart';
import '../../theme/app_theme.dart';

class NgoProfile extends StatefulWidget {

  final Map userData;

  const NgoProfile({

    super.key,

    required this.userData,
  });

  @override
  State<NgoProfile> createState() =>
      _NgoProfileState();
}

class _NgoProfileState
    extends State<NgoProfile> {

  Map? user;

  List posts = [];

  bool loading = true;

  @override
  void initState() {

    super.initState();

    fetchProfile();
  }

  // =====================================================
  // FETCH PROFILE
  // =====================================================

  Future<void> fetchProfile() async {

    setState(() {
      loading = true;
    });

    try {

      // USER DATA
      var userRes =
      await ApiService.getUser(

        widget.userData['id']
            .toString(),
      );

      // POSTS
      var postRes =
      await ApiService.getPosts();

      List allPosts = [];

      if(postRes['success'] == true){

        allPosts =
        postRes['posts'] ?? [];
      }

      // FILTER NGO POSTS
      List ngoPosts =
      allPosts.where((p){

        return p['ngo_id']
            .toString()

            ==

            widget.userData['id']
                .toString();

      }).toList();

      setState(() {

        if(userRes['success'] == true){

          user =
          userRes['user'];
        }

        posts = ngoPosts;

        loading = false;
      });

    } catch(e){

      print("PROFILE ERROR => $e");

      setState(() {
        loading = false;
      });
    }
  }

  // =====================================================
  // DELETE POST
  // =====================================================

  Future<void> deletePost(
      String postId) async {

    var res =
    await ApiService.deletePost(
      postId,
    );

    if(res['success'] == true){

      fetchProfile();

      ScaffoldMessenger.of(context)
          .showSnackBar(

        const SnackBar(

          content: Text(
            "Post deleted",
          ),
        ),
      );
    }
  }

  // =====================================================
  // INFO TILE
  // =====================================================

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
        title: const Text("NGO Profile"),
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 130),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // =====================================================
                  // PROFILE CARD
                  // =====================================================
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      gradient: const LinearGradient(
                        colors: [AppTheme.primary, AppTheme.secondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
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
                              Icons.volunteer_activism_rounded,
                              size: 50,
                              color: AppTheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          user?['username']?.toString() ?? "NGO",
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          user?['email']?.toString() ?? "",
                          style: GoogleFonts.outfit(
                            color: Colors.white70,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "Status: ${user?['status'] ?? ''}".toUpperCase(),
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // =====================================================
                  // NGO DETAILS
                  // =====================================================
                  infoTile(
                    icon: Icons.email_rounded,
                    title: "Email",
                    value: user?['email']?.toString() ?? "N/A",
                  ),
                  infoTile(
                    icon: Icons.phone_rounded,
                    title: "Phone",
                    value: user?['phone']?.toString() ?? "N/A",
                  ),
                  infoTile(
                    icon: Icons.location_on_rounded,
                    title: "Address",
                    value: user?['address']?.toString() ?? "N/A",
                  ),
                  infoTile(
                    icon: Icons.verified_user_rounded,
                    title: "Verification",
                    value: user?['status']?.toString() ?? "Pending",
                  ),
                  const SizedBox(height: 32),

                  // =====================================================
                  // POSTS TITLE
                  // =====================================================
                  Text(
                    "My Posts",
                    style: GoogleFonts.outfit(
                      color: AppTheme.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // =====================================================
                  // POSTS
                  // =====================================================
                  posts.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(40),
                          child: Center(
                            child: Text(
                              "No posts yet",
                              style: GoogleFonts.outfit(
                                color: AppTheme.textSecondary,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: posts.length,
                          itemBuilder: (context, index) {
                            var post = posts[index];
                            bool isUrgent = post['urgent'].toString() == "yes";

                            return Container(
                              margin: const EdgeInsets.only(bottom: 24),
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
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                                    child: Image.network(
                                      post['image'].toString(),
                                      width: double.infinity,
                                      height: 220,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) {
                                        return Container(
                                          height: 220,
                                          color: AppTheme.background,
                                          child: const Center(
                                            child: Icon(
                                              Icons.broken_image_rounded,
                                              size: 40,
                                              color: AppTheme.textSecondary,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          post['title'].toString(),
                                          style: GoogleFonts.outfit(
                                            color: AppTheme.textPrimary,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          post['description'].toString(),
                                          style: GoogleFonts.outfit(
                                            color: AppTheme.textSecondary,
                                            height: 1.5,
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                              decoration: BoxDecoration(
                                                color: isUrgent ? AppTheme.danger.withOpacity(0.1) : AppTheme.secondary.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(30),
                                              ),
                                              child: Text(
                                                isUrgent ? "🚨 Urgent" : "Normal",
                                                style: GoogleFonts.outfit(
                                                  color: isUrgent ? AppTheme.danger : AppTheme.secondary,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            OutlinedButton.icon(
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: AppTheme.danger,
                                                side: const BorderSide(color: AppTheme.danger),
                                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                              ),
                                              onPressed: () {
                                                deletePost(post['id'].toString());
                                              },
                                              icon: const Icon(Icons.delete_outline_rounded, size: 20),
                                              label: Text("Delete", style: GoogleFonts.outfit()),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                  const SizedBox(height: 32),

                  // =====================================================
                  // LOGOUT
                  // =====================================================
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
                ],
              ),
            ),
    );
  }
}