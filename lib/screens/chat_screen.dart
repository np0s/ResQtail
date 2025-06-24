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
                backgroundImage: NetworkImage('https://api.dicebear.com/7.x/thumbs/png?seed=placeholder'),
              ),
              errorWidget: (context, url, error) => const CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage('https://api.dicebear.com/7.x/thumbs/png?seed=placeholder'),
              ),
            ),
            const SizedBox(width: 12),
            Text(username, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Column(
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
                return ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg.senderId == userId;
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      child: Column(
                        crossAxisAlignment:
                            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isMe ? Colors.blue[100] : Colors.grey[300],
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(12),
                                topRight: const Radius.circular(12),
                                bottomLeft: Radius.circular(isMe ? 12 : 0),
                                bottomRight: Radius.circular(isMe ? 0 : 12),
                              ),
                            ),
                            child: msg.imageUrl != null && msg.imageUrl!.isNotEmpty
                                ? Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      CachedNetworkImage(
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
                                      if (msg.text.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Text(msg.text),
                                      ]
                                    ],
                                  )
                                : Text(msg.text),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatTimestamp(msg.timestamp.toDate()),
                            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(hintText: 'Type a message...'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.attach_file, color: Colors.deepPurple),
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
                IconButton(
                  icon: _isSending
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                          ),
                        )
                      : const Icon(Icons.send, color: Colors.deepPurple),
                  onPressed: _isSending
                      ? null
                      : () async {
                          final text = _controller.text.trim();
                          if (text.isNotEmpty) {
                            setState(() {
                              _isSending = true;
                            });
                            _controller.clear(); // Clear immediately for instant UI feedback
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
              ],
            ),
          ),
        ],
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
} 