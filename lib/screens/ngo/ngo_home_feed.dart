import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/api_service.dart';
import '../chat_screen.dart';
import 'ngo_map.dart';
import 'ngo_requests_screen.dart';
import '../../theme/app_theme.dart';

class NgoHomeFeed extends StatefulWidget {
  final String currentNgoId;

  const NgoHomeFeed({
    super.key,
    required this.currentNgoId,
  });

  @override
  State<NgoHomeFeed> createState() =>
      _NgoHomeFeedState();
}

class _NgoHomeFeedState extends State<NgoHomeFeed> {
  List posts = [];

  bool loading = true;

  Timer? timer;

  @override
  void initState() {
    super.initState();

    loadPosts();

    timer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => loadPosts(),
    );
  }

  // =====================================================
  // LOAD POSTS
  // =====================================================

  Future<void> loadPosts() async {
    try {
      var res = await ApiService.getPosts();

      if (!mounted) return;

      if (res['success'] == true) {
        setState(() {
          posts = res['posts'] ?? [];
          loading = false;
        });
      } else {
        setState(() {
          posts = [];
          loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        posts = [];
        loading = false;
      });
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  // =====================================================
  // IMAGE URL FIX
  // =====================================================

  String fixImageUrl(String image) {
    if (image.startsWith("http")) {
      return image;
    }

    return "https://digitalghallamandi.online/kind-pay/uploads/$image";
  }

  // =====================================================
  // DELETE POST
  // =====================================================

  Future<void> deletePostDialog(var post) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            "Delete Post",
          ),
          content: const Text(
            "Delete this post?",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child: const Text(
                "Cancel",
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child: const Text(
                "Delete",
              ),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await ApiService.deletePost(
        post['id'].toString(),
      );

      loadPosts();
    }
  }

  // =====================================================
  // OPEN CHAT
  // =====================================================

  Future<void> openChat(var post) async {
    await ApiService.startChat(
      widget.currentNgoId,
      post['ngo_id'].toString(),
    );

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          senderId: widget.currentNgoId,
          receiverId: post['ngo_id'].toString(),
        ),
      ),
    );
  }

  // =====================================================
  // OPEN MAP
  // =====================================================

  void openMap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const NgoMap(),
      ),
    );
  }

  // =====================================================
  // MAIN UI
  // =====================================================

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppTheme.background,

      // =====================================================
      // APPBAR WITH LOCATION BUTTON
      // =====================================================

      appBar: AppBar(
        title: const Text("NGO Feed"),
        actions: [
          IconButton(
            tooltip: "Form Requests",
            icon: Stack(
              children: [
                const Icon(
                  Icons.assignment_rounded,
                  color: AppTheme.primary,
                  size: 26,
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Color(0xFF00FF9D),
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 8,
                      minHeight: 8,
                    ),
                  ),
                ),
              ],
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => NgoRequestsScreen(
                    currentUserId: widget.currentNgoId,
                  ),
                ),
              );
            },
          ),
          IconButton(
            tooltip: "Nearby NGOs",
            icon: const Icon(
              Icons.location_on_rounded,
              color: AppTheme.primary,
            ),
            onPressed: openMap,
          ),
          const SizedBox(width: 8),
        ],
      ),

      // =====================================================
      // BODY
      // =====================================================

      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            )
          : posts.isEmpty
              ? Center(
                  child: Text(
                    "No posts found",
                    style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 18),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: loadPosts,
                  color: AppTheme.primary,
                  backgroundColor: AppTheme.cardColor,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 130), // padding for bottom nav
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      var post = posts[index];
                      bool myPost = post['ngo_id'].toString() == widget.currentNgoId;
                      String imageUrl = fixImageUrl(post['image'].toString());
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
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // =====================================================
                            // HEADER
                            // =====================================================
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: const LinearGradient(
                                        colors: [AppTheme.primary, AppTheme.secondary],
                                      ),
                                    ),
                                    child: const CircleAvatar(
                                      radius: 22,
                                      backgroundColor: AppTheme.cardColor,
                                      child: Icon(
                                        Icons.person_rounded,
                                        color: AppTheme.primary,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          post['username']?.toString() ?? "Unknown",
                                          style: GoogleFonts.outfit(
                                            color: AppTheme.textPrimary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: width * 0.045,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          isUrgent ? "🚨 Urgent Need" : "Donation Post",
                                          style: GoogleFonts.outfit(
                                            color: isUrgent ? AppTheme.danger : AppTheme.textSecondary,
                                            fontSize: width * 0.035,
                                            fontWeight: isUrgent ? FontWeight.bold : FontWeight.normal,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (myPost)
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.danger),
                                      onPressed: () {
                                        deletePostDialog(post);
                                      },
                                    ),
                                ],
                              ),
                            ),

                            // =====================================================
                            // IMAGE & TITLE
                            // =====================================================
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(bottom: Radius.zero),
                              child: Stack(
                                children: [
                                  Image.network(
                                    imageUrl,
                                    width: double.infinity,
                                    height: width < 400 ? 220 : 260,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        height: 240,
                                        color: AppTheme.background,
                                        child: const Center(
                                          child: Icon(Icons.broken_image_rounded, size: 50, color: AppTheme.textSecondary),
                                        ),
                                      );
                                    },
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.bottomCenter,
                                          end: Alignment.topCenter,
                                          colors: [
                                            Colors.black.withOpacity(0.8),
                                            Colors.transparent,
                                          ],
                                        ),
                                      ),
                                      child: Text(
                                        post['title']?.toString() ?? "",
                                        style: GoogleFonts.outfit(
                                          color: Colors.white,
                                          fontSize: width * 0.05,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // =====================================================
                            // DESCRIPTION
                            // =====================================================
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                post['description']?.toString() ?? "",
                                style: GoogleFonts.outfit(
                                  color: AppTheme.textSecondary,
                                  height: 1.5,
                                  fontSize: width * 0.038,
                                ),
                              ),
                            ),

                            // =====================================================
                            // ACTIONS
                            // =====================================================
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                      ),
                                      onPressed: () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            backgroundColor: AppTheme.secondary,
                                            content: Text(
                                              "Donation system is available from user side",
                                              style: GoogleFonts.outfit(),
                                            ),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.favorite_rounded),
                                      label: const Text("Donate"),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        side: const BorderSide(color: AppTheme.secondary),
                                      ),
                                      onPressed: () {
                                        openChat(post);
                                      },
                                      icon: const Icon(Icons.chat_bubble_outline_rounded, color: AppTheme.secondary),
                                      label: Text(
                                        "Chat",
                                        style: GoogleFonts.outfit(color: AppTheme.secondary, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}