import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';

class ChatScreen extends StatefulWidget {

  final String senderId;

  final String receiverId;

  const ChatScreen({

    super.key,

    required this.senderId,

    required this.receiverId,
  });

  @override
  State<ChatScreen> createState() =>
      _ChatScreenState();
}

class _ChatScreenState
    extends State<ChatScreen> {

  List messages = [];

  TextEditingController controller =
  TextEditingController();

  ScrollController scrollController =
  ScrollController();

  Timer? timer;

  @override
  void initState() {

    super.initState();

    loadMessages();

    timer = Timer.periodic(

      const Duration(seconds: 2),

          (_) => loadMessages(),
    );
  }

  // =====================================================
  // LOAD MESSAGES
  // =====================================================

  Future<void> loadMessages() async {

    var res =
    await ApiService.getMessages(

      widget.senderId,

      widget.receiverId,
    );

    setState(() {

      messages = res;
    });

    Future.delayed(

      const Duration(milliseconds: 200),

          () {

        if(scrollController.hasClients){

          scrollController.jumpTo(

            scrollController.position.maxScrollExtent,
          );
        }
      },
    );
  }

  // =====================================================
  // SEND MESSAGE
  // =====================================================

  Future<void> sendMessage() async {

    if(controller.text.trim().isEmpty){
      return;
    }

    String msg =
    controller.text.trim();

    controller.clear();

    await ApiService.sendMessage(

      widget.senderId,

      widget.receiverId,

      msg,
    );

    loadMessages();
  }

  // =====================================================
  // FORMAT MESSAGE TIME
  // =====================================================

  String formatTime(String time){

    try{

      DateTime dt =
      DateTime.parse(time);

      return DateFormat(
        'hh:mm a',
      ).format(dt);

    }catch(e){

      return "";
    }
  }

  // =====================================================
  // DATE HEADER
  // =====================================================

  String getDateLabel(DateTime date){

    DateTime now = DateTime.now();

    DateTime today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    DateTime yesterday =
    today.subtract(
      const Duration(days: 1),
    );

    DateTime msgDate = DateTime(
      date.year,
      date.month,
      date.day,
    );

    if(msgDate == today){
      return "Today";
    }

    if(msgDate == yesterday){
      return "Yesterday";
    }

    return DateFormat(
      'EEEE'
    ).format(date);
  }

  @override
  void dispose() {

    timer?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AppTheme.primary, AppTheme.secondary],
                ),
              ),
              child: const CircleAvatar(
                radius: 20,
                backgroundColor: AppTheme.cardColor,
                child: Icon(
                  Icons.person_rounded,
                  color: AppTheme.primary,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Chat",
                  style: GoogleFonts.outfit(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Online",
                  style: GoogleFonts.outfit(
                    color: AppTheme.primary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // =====================================================
          // MESSAGES
          // =====================================================
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                var msg = messages[index];
                bool me = msg['sender_id'].toString() == widget.senderId;
                DateTime date = DateTime.parse(msg['created_at'].toString());
                bool showHeader = false;

                if (index == 0) {
                  showHeader = true;
                } else {
                  DateTime prev = DateTime.parse(messages[index - 1]['created_at'].toString());
                  if (prev.day != date.day) {
                    showHeader = true;
                  }
                }

                return Column(
                  children: [
                    // =====================================================
                    // DATE HEADER
                    // =====================================================
                    if (showHeader)
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.cardColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          getDateLabel(date),
                          style: GoogleFonts.outfit(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                    // =====================================================
                    // MESSAGE
                    // =====================================================
                    Align(
                      alignment: me ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        margin: const EdgeInsets.only(top: 4, bottom: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          gradient: me
                              ? const LinearGradient(
                                  colors: [AppTheme.primary, AppTheme.secondary],
                                )
                              : null,
                          color: me ? null : AppTheme.cardColor,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(20),
                            topRight: const Radius.circular(20),
                            bottomLeft: me ? const Radius.circular(20) : const Radius.circular(4),
                            bottomRight: me ? const Radius.circular(4) : const Radius.circular(20),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              msg['message'].toString(),
                              style: GoogleFonts.outfit(
                                color: me ? Colors.white : AppTheme.textPrimary,
                                fontSize: 15,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formatTime(msg['created_at'].toString()),
                              style: GoogleFonts.outfit(
                                color: me ? Colors.white70 : AppTheme.textSecondary,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // =====================================================
          // INPUT
          // =====================================================
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24), // Extra bottom padding for safe area
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                )
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: TextField(
                      controller: controller,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        hintText: "Type a message...",
                        hintStyle: TextStyle(color: AppTheme.textSecondary),
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: sendMessage,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [AppTheme.primary, AppTheme.secondary],
                      ),
                    ),
                    child: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}