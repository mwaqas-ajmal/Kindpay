import 'package:flutter/material.dart';

import '../../services/api_service.dart';

import '../chat_screen.dart';

class UserChat extends StatefulWidget {

  final String userId;

  const UserChat({

    super.key,

    required this.userId,
  });

  @override
  State<UserChat> createState() =>
      _UserChatState();
}

class _UserChatState
    extends State<UserChat> {

  List chats = [];

  bool loading = true;

  @override
  void initState() {

    super.initState();

    loadChats();
  }

  // =====================================================
  // LOAD CHATS
  // =====================================================

  Future<void> loadChats() async {

    var res =
    await ApiService.getChatList(
      widget.userId,
    );

    setState(() {

      chats = res;

      loading = false;
    });
  }

  // =====================================================
  // MAIN UI
  // =====================================================

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor:
      const Color(0xfff4f6fb),

      // =====================================================
      // APPBAR
      // =====================================================

      appBar: AppBar(

        elevation: 0,

        backgroundColor:
        Colors.white,

        centerTitle: true,

        title: const Text(

          "Messages",

          style: TextStyle(

            color: Colors.black,

            fontWeight:
            FontWeight.bold,
          ),
        ),
      ),

      // =====================================================
      // BODY
      // =====================================================

      body: loading

          ? const Center(
        child:
        CircularProgressIndicator(),
      )

          : chats.isEmpty

          ? const Center(

        child: Text(

          "No Chats Yet",

          style: TextStyle(
            fontSize: 16,
          ),
        ),
      )

          : RefreshIndicator(

        onRefresh: loadChats,

        child: ListView.builder(

          padding:
          const EdgeInsets.all(14),

          itemCount:
          chats.length,

          itemBuilder:
              (context,index){

            var chat =
            chats[index];

            return GestureDetector(

              // =====================================================
              // DELETE CHAT
              // =====================================================

              onLongPress: () async {

                bool? confirm =
                await showDialog(

                  context: context,

                  builder: (context){

                    return AlertDialog(

                      shape:
                      RoundedRectangleBorder(

                        borderRadius:
                        BorderRadius.circular(20),
                      ),

                      title: const Text(
                        "Delete Chat",
                      ),

                      content: const Text(
                        "Delete this conversation?",
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

                          style:
                          ElevatedButton.styleFrom(

                            backgroundColor:
                            Colors.red,
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

                if(confirm == true){

                  var res =
                  await ApiService.deleteChat(

                    widget.userId,

                    chat['id']
                        .toString(),
                  );

                  if(res['success'] == true){

                    loadChats();

                    ScaffoldMessenger.of(context)
                        .showSnackBar(

                      const SnackBar(

                        content: Text(
                          "Chat deleted",
                        ),
                      ),
                    );
                  }
                }
              },

              // =====================================================
              // CHAT CARD
              // =====================================================

              child: Container(

                margin:
                const EdgeInsets.only(
                  bottom: 14,
                ),

                padding:
                const EdgeInsets.all(14),

                decoration: BoxDecoration(

                  color: Colors.white,

                  borderRadius:
                  BorderRadius.circular(24),

                  boxShadow: [

                    BoxShadow(

                      color:
                      Colors.black12,

                      blurRadius: 8,

                      offset:
                      const Offset(0, 4),
                    ),
                  ],
                ),

                child: ListTile(

                  contentPadding:
                  EdgeInsets.zero,

                  // =====================================================
                  // AVATAR
                  // =====================================================

                  leading: Stack(

                    children: [

                      Container(

                        padding:
                        const EdgeInsets.all(2),

                        decoration: BoxDecoration(

                          shape:
                          BoxShape.circle,

                          gradient:
                          const LinearGradient(

                            colors: [

                              Colors.green,

                              Colors.teal,
                            ],
                          ),
                        ),

                        child: const CircleAvatar(

                          radius: 28,

                          backgroundColor:
                          Colors.white,

                          child: Icon(

                            Icons.person,

                            color: Colors.green,

                            size: 30,
                          ),
                        ),
                      ),

                      Positioned(

                        bottom: 0,
                        right: 0,

                        child: Container(

                          width: 14,
                          height: 14,

                          decoration: BoxDecoration(

                            color: Colors.green,

                            shape:
                            BoxShape.circle,

                            border: Border.all(

                              color: Colors.white,

                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // =====================================================
                  // NAME + ROLE
                  // =====================================================

                  title: Text(

                    chat['username']
                        .toString(),

                    style: const TextStyle(

                      fontWeight:
                      FontWeight.bold,

                      fontSize: 17,
                    ),
                  ),

                  subtitle: Padding(

                    padding:
                    const EdgeInsets.only(
                      top: 6,
                    ),

                    child: Text(

                      chat['role']
                          .toString(),

                      style: TextStyle(

                        color:
                        Colors.grey.shade600,
                      ),
                    ),
                  ),

                  // =====================================================
                  // TRAILING
                  // =====================================================

                  trailing: Column(

                    mainAxisAlignment:
                    MainAxisAlignment.center,

                    children: [

                      const Icon(

                        Icons.arrow_forward_ios,

                        size: 16,
                      ),

                      const SizedBox(height: 6),

                      Container(

                        width: 8,
                        height: 8,

                        decoration: const BoxDecoration(

                          color: Colors.green,

                          shape:
                          BoxShape.circle,
                        ),
                      ),
                    ],
                  ),

                  // =====================================================
                  // OPEN CHAT
                  // =====================================================

                  onTap: () {

                    Navigator.push(

                      context,

                      MaterialPageRoute(

                        builder: (_) =>

                            ChatScreen(

                              senderId:
                              widget.userId,

                              receiverId:

                              chat['id']
                                  .toString(),
                            ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}