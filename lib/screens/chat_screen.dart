import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/message.dart';
import '../services/chat_service.dart';
import '../services/auth_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String otherUserId;
  const ChatScreen({Key? key, required this.chatId, required this.otherUserId}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService chatService = ChatService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Map<String, dynamic>? otherUserData;
  String? cachedUsername;
  String? cachedProfileImagePath;
  bool _isSending = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadOtherUserData();
  }

  Future<void> _loadOtherUserData() async {
    final data = await chatService.getUserInfo(widget.otherUserId);
    if (mounted && data != null) {
      setState(() {
        otherUserData = data;
        cachedUsername = data['username'] ?? 'User';
        cachedProfileImagePath = (data['profileImagePath'] as String?)?.replaceAll('/svg?', '/png?') ?? 'https://api.dicebear.com/7.x/thumbs/png?seed=unknown';
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final userId = authService.userId;
    if (userId == null) {
      return const Center(child: Text('Not logged in'));
    }
    final username = cachedUsername ?? 'User';
    final profileImagePath = cachedProfileImagePath ?? 'https://api.dicebear.com/7.x/thumbs/png?seed=placeholder';
    return Scaffold(
      appBar: AppBar(
        elevation: 2,
        title: Row(
          children: [
            CachedNetworkImage(
              imageUrl: profileImagePath,
              imageBuilder: (context, imageProvider) => CircleAvatar(
                radius: 20,
                backgroundImage: imageProvider,
              ),
              placeholder: (context, url) => const CircleAvatar(
                radius: 20,
                backgroundImage: AssetImage('assets/logo.png'),
              ),
              errorWidget: (context, url, error) => const CircleAvatar(
                radius: 20,
                backgroundImage: AssetImage('assets/logo.png'),
              ),
            ),
            const SizedBox(width: 12),
            Text(username, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF3E5F5), Color(0xFFE1BEE7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<List<Message>>(
                stream: chatService.getChatMessages(widget.chatId),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final messages = snapshot.data!;
                  if (messages.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline, size: 64, color: Colors.deepPurple.withAlpha(120)),
                          const SizedBox(height: 16),
                          const Text('No messages yet.', style: TextStyle(fontSize: 18, color: Colors.deepPurple)),
                        ],
                      ),
                    );
                  }
                  WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
                  // Group messages by calendar day
                  List<Widget> messageWidgets = [];
                  DateTime? lastDate;
                  for (int i = 0; i < messages.length; i++) {
                    final msg = messages[i];
                    final isMe = msg.senderId == userId;
                    final msgDate = msg.timestamp.toDate();
                    final msgDay = DateTime(msgDate.year, msgDate.month, msgDate.day);
                    if (lastDate == null || !_isSameDay(msgDay, lastDate)) {
                      messageWidgets.add(
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.deepPurple.withAlpha(30),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                _formatDateSeparator(msgDay),
                                style: const TextStyle(fontSize: 13, color: Colors.deepPurple, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ),
                        ),
                      );
                      lastDate = msgDay;
                    }
                    messageWidgets.add(
                      Row(
                        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (!isMe)
                            Padding(
                              padding: const EdgeInsets.only(right: 8, bottom: 2),
                              child: CachedNetworkImage(
                                imageUrl: profileImagePath,
                                imageBuilder: (context, imageProvider) => CircleAvatar(
                                  radius: 16,
                                  backgroundImage: imageProvider,
                                ),
                                placeholder: (context, url) => const CircleAvatar(
                                  radius: 16,
                                  backgroundImage: AssetImage('assets/logo.png'),
                                ),
                                errorWidget: (context, url, error) => const CircleAvatar(
                                  radius: 16,
                                  backgroundImage: AssetImage('assets/logo.png'),
                                ),
                              ),
                            ),
                          Flexible(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              curve: Curves.easeInOut,
                              margin: EdgeInsets.only(
                                top: 2,
                                bottom: 2,
                                left: isMe ? 40 : 0,
                                right: isMe ? 0 : 40,
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: isMe ? Colors.deepPurple : Colors.white,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(18),
                                  topRight: const Radius.circular(18),
                                  bottomLeft: Radius.circular(isMe ? 18 : 4),
                                  bottomRight: Radius.circular(isMe ? 4 : 18),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.06),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                children: [
                                  if (msg.imageUrl != null && msg.imageUrl!.isNotEmpty)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: CachedNetworkImage(
                                        imageUrl: msg.imageUrl!,
                                        width: 180,
                                        height: 180,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => Container(
                                          width: 180,
                                          height: 180,
                                          color: Colors.grey[300],
                                          child: const Center(child: CircularProgressIndicator()),
                                        ),
                                        errorWidget: (context, url, error) => Container(
                                          width: 180,
                                          height: 180,
                                          color: Colors.grey[300],
                                          child: const Icon(Icons.broken_image, color: Colors.red),
                                        ),
                                      ),
                                    ),
                                  if (msg.text.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        msg.text,
                                        style: TextStyle(
                                          color: isMe ? Colors.white : Colors.deepPurple,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _formatTimestamp(msg.timestamp.toDate()),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isMe ? Colors.white70 : Colors.deepPurple.withAlpha(180),
                                        ),
                                      ),
                                      if (isMe)
                                        const Padding(
                                          padding: EdgeInsets.only(left: 4),
                                          child: Icon(Icons.check, size: 14, color: Colors.white70),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (isMe)
                            Padding(
                              padding: const EdgeInsets.only(left: 8, bottom: 2),
                              child: CachedNetworkImage(
                                imageUrl: profileImagePath,
                                imageBuilder: (context, imageProvider) => CircleAvatar(
                                  radius: 16,
                                  backgroundImage: imageProvider,
                                ),
                                placeholder: (context, url) => const CircleAvatar(
                                  radius: 16,
                                  backgroundImage: AssetImage('assets/logo.png'),
                                ),
                                errorWidget: (context, url, error) => const CircleAvatar(
                                  radius: 16,
                                  backgroundImage: AssetImage('assets/logo.png'),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  }
                  return ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    children: messageWidgets,
                  );
                },
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
              child: Material(
                elevation: 2,
                borderRadius: BorderRadius.circular(28),
                color: Colors.white,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: TextField(
                            controller: _controller,
                            decoration: const InputDecoration(
                              hintText: 'Type a message...',
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              filled: true,
                              fillColor: Colors.transparent,
                            ),
                            minLines: 1,
                            maxLines: 5,
                            textInputAction: TextInputAction.newline,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      Center(
                        child: IconButton(
                          icon: const Icon(Icons.attach_file, color: Colors.deepPurple, size: 26),
                          onPressed: () async {
                            final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
                            if (pickedFile != null) {
                              setState(() {
                                _isSending = true;
                              });
                              try {
                                await chatService.sendImageMessage(widget.chatId, userId, File(pickedFile.path));
                                _scrollToBottom();
                              } finally {
                                if (mounted) {
                                  setState(() {
                                    _isSending = false;
                                  });
                                }
                              }
                            }
                          },
                        ),
                      ),
                      Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                          child: _isSending
                              ? const SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                                    ),
                                  ),
                                )
                              : IconButton(
                                  key: const ValueKey('send'),
                                  icon: const Icon(Icons.send, color: Colors.deepPurple, size: 26),
                                  onPressed: _isSending
                                      ? null
                                      : () async {
                                          final text = _controller.text.trim();
                                          if (text.isNotEmpty) {
                                            setState(() {
                                              _isSending = true;
                                            });
                                            _controller.clear();
                                            _scrollToBottom();
                                            try {
                                              await chatService.sendMessage(widget.chatId, userId, text);
                                            } finally {
                                              if (mounted) {
                                                setState(() {
                                                  _isSending = false;
                                                });
                                              }
                                            }
                                          }
                                        },
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    if (now.difference(dateTime).inDays == 0) {
      // Today
      return "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
    } else {
      // Earlier
      return "${dateTime.day}/${dateTime.month}/${dateTime.year}";
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatDateSeparator(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    if (_isSameDay(date, today)) {
      return 'Today';
    } else if (_isSameDay(date, yesterday)) {
      return 'Yesterday';
    } else {
      return "${date.day}/${date.month}/${date.year}";
    }
  }
} 