import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

import 'user_home_feed.dart';
import 'user_chat.dart';
import 'user_wallet.dart';
import 'user_profile.dart';
import 'user_map.dart';

class UserDashboard extends StatefulWidget {

  final Map userData;

  const UserDashboard({

    super.key,

    required this.userData,
  });

  @override
  State<UserDashboard> createState() =>
      _UserDashboardState();
}

class _UserDashboardState
    extends State<UserDashboard> {

  int selectedIndex = 0;

  late List<Widget> pages;

  @override
  void initState() {

    super.initState();

    pages = [

      UserHomeFeed(

        currentUserId:

        widget.userData['id']
            .toString(),
      ),

      UserChat(

        userId:

        widget.userData['id']
            .toString(),
      ),

      UserWallet(

        userId:

        widget.userData['id']
            .toString(),
      ),

      const UserMap(),

      UserProfile(
        userData:
        widget.userData,
      ),
    ];
  }

  // =====================================================
  // CHANGE TAB
  // =====================================================

  void onItemTapped(int index){

    setState(() {

      selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      extendBody: true,

      // =====================================================
      // BODY
      // =====================================================

      body: pages[selectedIndex],

      // =====================================================
      // MODERN BOTTOM NAVBAR
      // =====================================================

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
            child: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              currentIndex: selectedIndex,
              onTap: onItemTapped,
              elevation: 0,
              selectedItemColor: AppTheme.primary,
              unselectedItemColor: AppTheme.textSecondary,
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
              items: [
                BottomNavigationBarItem(
                  icon: _navIcon(0, Icons.home_rounded),
                  label: "Home",
                ),
                BottomNavigationBarItem(
                  icon: _navIcon(1, Icons.chat_bubble_rounded),
                  label: "Chat",
                ),
                BottomNavigationBarItem(
                  icon: _navIcon(2, Icons.account_balance_wallet_rounded),
                  label: "Wallet",
                ),
                BottomNavigationBarItem(
                  icon: _navIcon(3, Icons.location_on_rounded),
                  label: "Map",
                ),
                BottomNavigationBarItem(
                  icon: _navIcon(4, Icons.person_rounded),
                  label: "Profile",
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navIcon(int index, IconData icon) {
    bool active = selectedIndex == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: active ? AppTheme.primary.withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon),
    );
  }
}