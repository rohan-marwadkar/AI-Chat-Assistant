import 'package:chat_app/controller/chat_controller.dart';
import 'package:chat_app/controller/user_controller.dart';
import 'package:chat_app/services/gemini_services.dart';
import 'package:chat_app/view/login_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final ChatController _chatController = ChatController();
  final UserController _userController = UserController();
  final GeminiService _geminiService = GeminiService();

  bool _isSending = false; // ✅ disable button while sending/retrying
  bool _aiTyping = false;  // ✅ AI typing indicator

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    await _userController.loadUserData();
    if (!mounted) return;
    setState(() {});
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String formatTime(Timestamp timestamp) {
    return DateFormat('hh:mm a').format(timestamp.toDate());
  }

  bool _shouldShowSnack(String text) {
    // Adjust this list based on what GeminiService returns
    final lower = text.toLowerCase();
    return lower.contains("no internet") ||
        lower.contains("quota") ||
        lower.contains("invalid request") ||
        lower.contains("api key") ||
        lower.contains("something went wrong") ||
        lower.contains("request failed") ||
        lower.contains("error");
  }

  Future<void> _sendMessage() async {
    if (_isSending) return;

    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;

    final myUserId = _userController.userId;
    if (myUserId == null || myUserId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User not loaded. Please login again.")),
      );
      return;
    }

    setState(() {
      _isSending = true;
      _aiTyping = true;
    });

    _messageController.clear();

    // 1) Send USER message to Firestore
    final userMessage = {
      "profileImage": _userController.profileImage ?? "",
      "userId": myUserId,
      "name": _userController.name ?? "User",
      "message": messageText,
      "time": Timestamp.now(),
    };

    try {
      await _chatController.sendMessage(data: userMessage);
      _scrollToBottom();

      // 2) Get AI response
      final aiText = await _geminiService.getAIResponse(messageText);

      // If AI returned an error message → show snackbar, do NOT save bot msg
      if (_shouldShowSnack(aiText)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(aiText)),
          );
        }
        return;
      }

      // 3) Save AI message to Firestore
      final botMessage = {
        "profileImage": "",
        "userId": "AI_BOT",
        "name": "Gemini",
        "message": aiText,
        "time": Timestamp.now(),
      };

      await _chatController.sendMessage(data: botMessage);
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to send message. Try again.")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
          _aiTyping = false;
        });
      }
    }
  }

  // ✅ WhatsApp style: delete ALL chat messages
  Future<void> _deleteAllChats() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete chat?"),
        content: const Text("This will delete all chat messages."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _chatController.deleteAllMessages();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Chat deleted successfully")),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to delete chat")),
        );
      }
    }
  }

  // ✅ Optional: delete only MY messages
  Future<void> _deleteMyChats() async {
    final myUserId = _userController.userId;
    if (myUserId == null || myUserId.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete my messages?"),
        content: const Text("Only your messages will be deleted."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _chatController.deleteMessagesByUserId(myUserId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Your messages deleted")),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to delete messages")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECE5DD),
appBar: PreferredSize(
  preferredSize: const Size.fromHeight(70),
  child: Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Color(0xFF2196F3),
          Color(0xFF1976D2),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: [

            // APP LOGO
            CircleAvatar(
              radius: 22,
              backgroundColor: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(0),
                child: Image.asset(
                  "asset/chat_app.png",
                ),
              ),
            ),

            const SizedBox(width: 10),

            // TITLE + STATUS
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [

                Text(
                  "Chat App",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 2),

                Text(
                  "AI Assistant Online",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                )
              ],
            ),

            const Spacer(),

            // DELETE CHAT BUTTON
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.white),
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection("chatsData")
                    .get()
                    .then((snapshot) {
                  for (var doc in snapshot.docs) {
                    doc.reference.delete();
                  }
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Chat deleted"),
                  ),
                );
              },
            ),

            // MENU
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onSelected: (value) async {

                if (value == "logout") {
                  await FirebaseAuth.instance.signOut();

                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LoginScreen(),
                    ),
                  );
                }
              },
              itemBuilder: (context) => [

                const PopupMenuItem(
                  value: "logout",
                  child: Row(
                    children: [
                      Icon(Icons.logout),
                      SizedBox(width: 10),
                      Text("Logout"),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  ),
),
      body: Column(
        children: [
          // ================= CHAT LIST =================
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("chatsData")
                  .orderBy("time", descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(10),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final userId = (doc['userId'] ?? "").toString();
                    final message = (doc['message'] ?? "").toString();
                    final name = (doc['name'] ?? "").toString();
                    final time = doc['time'] as Timestamp?;

                    if (userId.isEmpty) return const SizedBox();

                    final myId = _userController.userId ?? "";
                    final isMe = userId == myId;

                    return _chatBubble(
                      isMe: isMe,
                      message: message,
                      name: name,
                      time: time,
                    );
                  },
                );
              },
            ),
          ),

          // ✅ AI typing indicator
          if (_aiTyping)
            Padding(
              padding: const EdgeInsets.only(left: 12, right: 12, bottom: 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    "Gemini is typing...",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ),

          // ================= INPUT FIELD =================
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    enabled: !_isSending, // ✅ Disable typing while sending
                    decoration: InputDecoration(
                      hintText: "Type a message",
                      filled: true,
                      fillColor: Colors.grey[200],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _isSending ? null : _sendMessage,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isSending ? Colors.grey : Colors.blue,
                    ),
                    child: _isSending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= WHATSAPP STYLE BUBBLE =================
  Widget _chatBubble({
    required bool isMe,
    required String message,
    required String name,
    required Timestamp? time,
  }) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFFDCF8C6) : Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            Text(message),
            const SizedBox(height: 4),
            if (time != null)
              Text(
                formatTime(time),
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }
}