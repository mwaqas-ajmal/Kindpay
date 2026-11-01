import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

import 'ngo_home_feed.dart';
import 'ngo_chat.dart';
import 'ngo_wallet.dart';
import 'ngo_profile.dart';
import 'ngo_create_post.dart';
import 'ngo_requests_screen.dart';

class NgoDashboard extends StatefulWidget {
  final Map userData;
  final String status;

  const NgoDashboard({
    super.key,
    required this.userData,
    required this.status,
  });

  @override
  State<NgoDashboard> createState() =>
      _NgoDashboardState();
}

class _NgoDashboardState extends State<NgoDashboard> {
  int selectedIndex = 0;



  void onItemTapped(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  /// Builds the current page. NgoRequestsScreen gets a fresh key each time
  /// the Requests tab (index 1) is activated so it always reloads local data.
  Widget _buildPage() {
    switch (selectedIndex) {
      case 0:
        return NgoHomeFeed(currentNgoId: widget.userData['id'].toString());
      case 1:
        // Fresh key = fresh initState = fresh fetchRequests every time tab is tapped
        return NgoRequestsScreen(
          key: ValueKey('requests_$selectedIndex'),
          currentUserId: widget.userData['id'].toString(),
        );
      case 2:
        return NgoChat(ngoId: widget.userData['id'].toString());
      case 3:
        return NgoWallet(ngoId: widget.userData['id'].toString());
      case 4:
        return NgoProfile(userData: widget.userData);
      default:
        return NgoHomeFeed(currentNgoId: widget.userData['id'].toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,

      body: Column(
        children: [
          if (widget.status != "approved")
            Container(
              width: double.infinity,
              color: Colors.orange,
              padding: const EdgeInsets.all(14),
              child: const SafeArea(
                child: Text(
                  "⏳ NGO verification pending. Approval may take up to 24 hours.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

          Expanded(
            child: _buildPage(),
          ),
        ],
      ),

      floatingActionButton: widget.status == "approved"
          ? FloatingActionButton(
              backgroundColor: const Color(0xff00b09b),
              elevation: 6,
              child: const Icon(
                Icons.add,
                color: Colors.white,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NgoCreatePost(
                      ngoId: widget.userData['id'].toString(),
                    ),
                  ),
                );
              },
            )
          : FloatingActionButton(
              backgroundColor: Colors.grey,
              elevation: 3,
              child: const Icon(
                Icons.lock,
                color: Colors.white,
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Your NGO verification is pending.\nApproval may take up to 24 hours.",
                    ),
                  ),
                );
              },
            ),

      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: Container(
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        decoration: BoxDecoration(
          color: AppTheme.cardColor.withOpacity(0.85),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: BottomAppBar(
              shape: const CircularNotchedRectangle(),
              notchMargin: 8,
              color: Colors.transparent,
              elevation: 0,
              child: SizedBox(
                height: 70,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    navItem(0, Icons.home_rounded),
                    navItem(1, Icons.assignment_rounded),
                    const SizedBox(width: 30), // FAB
                    navItem(2, Icons.chat_bubble_rounded),
                    navItem(3, Icons.account_balance_wallet_rounded),
                    navItem(4, Icons.person_rounded),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget navItem(int index, IconData icon) {
    bool active = selectedIndex == index;

    return GestureDetector(
      onTap: () {
        onItemTapped(index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: active ? AppTheme.primary.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          icon,
          color: active ? AppTheme.primary : AppTheme.textSecondary,
        ),
      ),
    );
  }
}