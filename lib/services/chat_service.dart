import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat.dart';
import '../models/message.dart';
import 'package:snowflaker/snowflaker.dart';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final Map<String, Map<String, dynamic>> _userInfoCache = {};
  final Snowflaker _snowflaker = Snowflaker(workerId: 1, datacenterId: 1);

  Stream<List<Chat>> getUserChats(String userId) {
    return _db
        .collection('chats')
        .where('participants', arrayContains: userId)
        .orderBy('lastUpdated', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Chat.fromDocument(doc)).toList());
  }

  Stream<List<Message>> getChatMessages(String chatId) {
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Message.fromDocument(doc)).toList());
  }

  Future<String> createOrGetChat(String userA, String userB, String reportId) async {
    final query = await _db
        .collection('chats')
        .where('participants', arrayContains: userA)
        .where('reportId', isEqualTo: reportId)
        .get();
    for (var doc in query.docs) {
      final participants = List<String>.from(doc['participants'] ?? []);
      if (participants.contains(userB)) {
        return doc.id;
      }
    }
    final chatId = _snowflaker.nextId().toString();
    await _db.collection('chats').doc(chatId).set({
      'participants': [userA, userB],
      'reportId': reportId,
      'lastMessage': null,
      'lastUpdated': Timestamp.now(),
    });
    return chatId;
  }

  Future<void> sendMessage(String chatId, String senderId, String text) async {
    final messageId = _snowflaker.nextId().toString();
    final message = {
      'chatId': chatId,
      'senderId': senderId,
      'text': text,
      'timestamp': Timestamp.now(),
    };
    await _db.collection('chats').doc(chatId).collection('messages').doc(messageId).set(message);
    await _db.collection('chats').doc(chatId).update({
      'lastMessage': text,
      'lastUpdated': Timestamp.now(),
    });
  }

  Future<Map<String, dynamic>?> getUserInfo(String userId) async {
    if (_userInfoCache.containsKey(userId)) {
      return _userInfoCache[userId];
    }
    final query = await _db.collection('users').where('userId', isEqualTo: userId).limit(1).get();
    if (query.docs.isNotEmpty) {
      final data = query.docs.first.data();
      _userInfoCache[userId] = data;
      return data;
    }
    return null;
  }

  Future<void> deleteChat(String chatId) async {
    // Delete all messages in the chat
    final messages = await _db.collection('chats').doc(chatId).collection('messages').get();
    for (final doc in messages.docs) {
      await doc.reference.delete();
    }
    // Delete the chat document
    await _db.collection('chats').doc(chatId).delete();
  }

  Future<void> muteChat(String chatId, bool muted) async {
    await _db.collection('chats').doc(chatId).update({'muted': muted});
  }

  Future<void> archiveChat(String chatId, bool archived) async {
    await _db.collection('chats').doc(chatId).update({'archived': archived});
  }

  Future<void> sendImageMessage(String chatId, String senderId, File imageFile) async {
    // Upload image to Zipline
    const ziplineUrl = 'https://share.p1ng.me/api/upload';
    final apiKey = dotenv.env['ZIPLINE_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('ZIPLINE_API_KEY not set in .env');
    }
    if (!imageFile.existsSync() || imageFile.lengthSync() == 0) {
      throw Exception('Image file does not exist or is empty: \\${imageFile.path}');
    }
    var request = http.MultipartRequest('POST', Uri.parse(ziplineUrl));
    request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));
    request.headers['authorization'] = apiKey;
    var response = await request.send();
    if (response.statusCode != 200) {
      throw Exception('Failed to upload image to Zipline: \\${response.statusCode}');
    }
    final respStr = await response.stream.bytesToString();
    final url = RegExp(r'"url"\s*:\s*"([^"]+)"').firstMatch(respStr)?.group(1);
    if (url == null) {
      throw Exception('Zipline upload response missing URL');
    }
    final messageId = _snowflaker.nextId().toString();
    final message = {
      'chatId': chatId,
      'senderId': senderId,
      'text': '',
      'imageUrl': url,
      'timestamp': Timestamp.now(),
    };
    await _db.collection('chats').doc(chatId).collection('messages').doc(messageId).set(message);
    await _db.collection('chats').doc(chatId).update({
      'lastMessage': '[Image]',
      'lastUpdated': Timestamp.now(),
    });
  }
} 