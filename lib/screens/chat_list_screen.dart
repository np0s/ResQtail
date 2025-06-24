import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chat.dart';
import '../services/chat_service.dart';
import '../services/auth_service.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  ChatListScreen({Key? key}) : super(key: key);

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatService chatService = ChatService();
  Map<String, Map<String, dynamic>?> userInfoCache = {};
  List<Chat> currentChats = [];

  @override
  void initState() {
    super.initState();
  }

  Future<void> _preloadUserInfos(List<Chat> chats, String userId) async {
    final futures = <Future>[];
    for (final chat in chats) {
      final otherUserId = chat.participants.firstWhere((id) => id != userId, orElse: () => 'Unknown');
      if (!userInfoCache.containsKey(otherUserId)) {
        futures.add(chatService.getUserInfo(otherUserId).then((data) {
          userInfoCache[otherUserId] = data;
        }));
      }
    }
    await Future.wait(futures);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final userId = authService.userId;
    if (userId == null) {
      return Center(child: Text('Not logged in'));
    }
    return Scaffold(
      appBar: AppBar(title: Text('Chats')),
      body: StreamBuilder<List<Chat>>(
        stream: chatService.getUserChats(userId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          final chats = snapshot.data!;
          if (chats.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 64, color: Colors.deepPurple.withAlpha(120)),
                  SizedBox(height: 16),
                  Text('No chats yet.', style: TextStyle(fontSize: 18, color: Colors.deepPurple)),
                ],
              ),
            );
          }
          // Preload user info if chat list changed
          if (chats != currentChats) {
            currentChats = chats;
            _preloadUserInfos(chats, userId);
          }
          return ListView.separated(
            itemCount: chats.length,
            separatorBuilder: (context, index) => Divider(height: 1, indent: 72, endIndent: 12),
            padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
            itemBuilder: (context, index) {
              final chat = chats[index];
              final otherUserId = chat.participants.firstWhere((id) => id != userId, orElse: () => 'Unknown');
              final userData = userInfoCache[otherUserId];
              final username = userData?['username'] ?? 'User';
              final profileImagePath = (userData?['profileImagePath'] as String?)?.replaceAll('/svg?', '/png?') ?? 'https://api.dicebear.com/7.x/thumbs/png?seed=placeholder';
              final lastMessage = chat.lastMessage ?? '';
              final lastUpdated = chat.lastUpdated.toDate();
              final isUnread = false; // TODO: Replace with real unread logic if available
              final isMuted = chat.muted;
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.grey[100],
                  backgroundImage: NetworkImage(profileImagePath),
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        username,
                        style: TextStyle(
                          fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                          color: Colors.black87,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatTimestamp(lastUpdated),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                subtitle: Text(
                  lastMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'delete') {
                      await chatService.deleteChat(chat.id);
                      if (mounted) {
                        setState(() {});
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Chat deleted')),
                        );
                      }
                    } else if (value == 'mute') {
                      await chatService.muteChat(chat.id, true);
                      if (mounted) {
                        setState(() {});
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Chat muted')),
                        );
                      }
                    } else if (value == 'unmute') {
                      await chatService.muteChat(chat.id, false);
                      if (mounted) {
                        setState(() {});
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Chat unmuted')),
                        );
                      }
                    } else if (value == 'unread') {
                      // TODO: Implement mark as unread
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Marked as unread (not implemented)')),
                        );
                      }
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(value: 'unread', child: Text('Mark as Unread')),
                    if (!isMuted)
                      PopupMenuItem(value: 'mute', child: Text('Mute Notifications')),
                    if (isMuted)
                      PopupMenuItem(value: 'unmute', child: Text('Unmute')),
                    PopupMenuItem(value: 'delete', child: Text('Delete Chat', style: TextStyle(color: Colors.red))),
                  ],
                  icon: Icon(Icons.more_vert, color: Colors.grey[700]),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(chatId: chat.id, otherUserId: otherUserId),
                    ),
                  );
                },
              );
            },
          );
        },
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