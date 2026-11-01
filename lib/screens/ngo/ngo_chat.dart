import 'package:flutter/material.dart';

import 'package:url_launcher/url_launcher.dart';

import '../../services/api_service.dart';

import '../chat_screen.dart';

class NgoChat extends StatefulWidget {
  final String ngoId;

  const NgoChat({
    super.key,
    required this.ngoId,
  });

  @override
  State<NgoChat> createState() => _NgoChatState();
}

class _NgoChatState extends State<NgoChat> {
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
    try {
      var res = await ApiService.getChatList(widget.ngoId);

      if (!mounted) return;

      setState(() {
        chats = res;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        chats = [];
        loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to load chats"),
        ),
      );
    }
  }

  // =====================================================
  // CREATE SAFE JITSI ROOM NAME
  // =====================================================

  String createRoomName(String prefix) {
    return "${prefix}_${DateTime.now().millisecondsSinceEpoch}";
  }

  // =====================================================
  // OPEN JITSI MEETING
  // =====================================================

  Future<void> openJitsiMeeting(String roomName) async {
    final Uri url = Uri.parse(
      "https://meet.jit.si/$roomName",
    );

    bool opened = await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    );

    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Could not open Jitsi Meet"),
        ),
      );
    }
  }

  // =====================================================
  // INSTANT VIDEO MEETING
  // =====================================================

  Future<void> startInstantMeeting() async {
    String roomName = createRoomName("KindPayVideo");

    await openJitsiMeeting(roomName);
  }

  // =====================================================
  // INSTANT AUDIO MEETING
  // =====================================================

  Future<void> startAudioMeeting() async {
    String roomName = createRoomName("KindPayAudio");

    await openJitsiMeeting(roomName);
  }

  // =====================================================
  // SCHEDULE MEETING
  // =====================================================

  Future<void> scheduleMeeting() async {
    TextEditingController titleController = TextEditingController();

    DateTime? selectedDate;

    TimeOfDay? selectedTime;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              title: const Text(
                "Schedule NGO Meeting",
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        hintText: "Meeting Title",
                        prefixIcon: const Icon(Icons.title),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2030),
                          );

                          if (picked != null) {
                            setStateDialog(() {
                              selectedDate = picked;
                            });
                          }
                        },
                        icon: const Icon(Icons.date_range),
                        label: Text(
                          selectedDate == null
                              ? "Select Date"
                              : selectedDate.toString().split(" ")[0],
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          TimeOfDay? picked = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );

                          if (picked != null) {
                            setStateDialog(() {
                              selectedTime = picked;
                            });
                          }
                        },
                        icon: const Icon(Icons.access_time),
                        label: Text(
                          selectedTime == null
                              ? "Select Time"
                              : selectedTime!.format(context),
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    const Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.green,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "All registered NGOs can join this meeting from Upcoming Meetings.",
                            style: TextStyle(
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    "Cancel",
                  ),
                ),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  onPressed: () async {
                    if (titleController.text.trim().isEmpty ||
                        selectedDate == null ||
                        selectedTime == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Please enter title, date and time"),
                        ),
                      );

                      return;
                    }

                    try {
                      var res = await ApiService.createMeeting(
                        widget.ngoId,
                        titleController.text.trim(),
                        selectedDate.toString().split(" ")[0],
                        "${selectedTime!.hour}:${selectedTime!.minute}",
                      );

                      if (!mounted) return;

                      Navigator.pop(context);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor:
                              res['success'] == true ? Colors.green : Colors.red,
                          content: Text(
                            res['success'] == true
                                ? "Meeting Scheduled Successfully"
                                : "Failed to schedule meeting",
                          ),
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;

                      Navigator.pop(context);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Something went wrong"),
                        ),
                      );
                    }
                  },
                  child: const Text(
                    "Schedule",
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // =====================================================
  // SHOW UPCOMING MEETINGS
  // =====================================================

  Future<void> showMeetings() async {
    try {
      var res = await ApiService.getMeetings();

      List meetings = res['meetings'] ?? [];

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            title: const Text(
              "Upcoming NGO Meetings",
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: meetings.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(
                        child: Text("No meetings scheduled"),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: meetings.length,
                      itemBuilder: (context, index) {
                        var meeting = meetings[index];

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.green.shade100,
                              child: const Icon(
                                Icons.video_call,
                                color: Colors.green,
                              ),
                            ),
                            title: Text(
                              meeting['title']?.toString() ?? "Meeting",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              "${meeting['meeting_date']}  ${meeting['meeting_time']}\nHost: ${meeting['username'] ?? 'NGO'}",
                            ),
                            isThreeLine: true,
                            trailing: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                              onPressed: () async {
                                String roomCode =
                                    meeting['meeting_code']?.toString() ?? "";

                                if (roomCode.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Invalid meeting code"),
                                    ),
                                  );

                                  return;
                                }

                                await openJitsiMeeting(roomCode);
                              },
                              child: const Text(
                                "Join",
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  "Close",
                ),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to load meetings"),
        ),
      );
    }
  }

  // =====================================================
  // DELETE CHAT CONFIRMATION
  // =====================================================

  Future<void> deleteChatDialog(var chat) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
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
                Navigator.pop(context, false);
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
                Navigator.pop(context, true);
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
      var res = await ApiService.deleteChat(
        widget.ngoId,
        chat['id'].toString(),
      );

      if (!mounted) return;

      if (res['success'] == true) {
        loadChats();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Chat deleted"),
          ),
        );
      }
    }
  }

  // =====================================================
  // MAIN UI
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff4f6fb),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          "NGO Chats",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: "Video Meet",
            onPressed: startInstantMeeting,
            icon: const Icon(
              Icons.videocam,
              color: Colors.green,
            ),
          ),

          IconButton(
            tooltip: "Audio Meet",
            onPressed: startAudioMeeting,
            icon: const Icon(
              Icons.call,
              color: Colors.green,
            ),
          ),

          PopupMenuButton(
            icon: const Icon(
              Icons.calendar_month,
              color: Colors.black,
            ),
            itemBuilder: (context) {
              return [
                const PopupMenuItem(
                  value: "schedule",
                  child: Row(
                    children: [
                      Icon(Icons.event_available),
                      SizedBox(width: 10),
                      Text("Schedule Meeting"),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: "meetings",
                  child: Row(
                    children: [
                      Icon(Icons.video_library),
                      SizedBox(width: 10),
                      Text("Upcoming Meetings"),
                    ],
                  ),
                ),
              ];
            },
            onSelected: (value) {
              if (value == "schedule") {
                scheduleMeeting();
              } else {
                showMeetings();
              }
            },
          ),
        ],
      ),

      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
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
                    padding: const EdgeInsets.all(14),
                    itemCount: chats.length,
                    itemBuilder: (context, index) {
                      var chat = chats[index];

                      return GestureDetector(
                        onLongPress: () {
                          deleteChatDialog(chat);
                        },
                        child: Container(
                          margin: const EdgeInsets.only(
                            bottom: 14,
                          ),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Stack(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.green,
                                        Colors.teal,
                                      ],
                                    ),
                                  ),
                                  child: const CircleAvatar(
                                    radius: 28,
                                    backgroundColor: Colors.white,
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
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            title: Text(
                              chat['username'].toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(
                                top: 6,
                              ),
                              child: Text(
                                chat['role'].toString(),
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
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
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatScreen(
                                    senderId: widget.ngoId,
                                    receiverId: chat['id'].toString(),
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