import 'package:cloud_firestore/cloud_firestore.dart';

class Chat {
  final String id;
  final List<String> participants;
  final String reportId;
  final String? lastMessage;
  final Timestamp lastUpdated;
  final bool muted;

  Chat({
    required this.id,
    required this.participants,
    required this.reportId,
    this.lastMessage,
    required this.lastUpdated,
    this.muted = false,
  });

  factory Chat.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Chat(
      id: doc.id,
      participants: List<String>.from(data['participants'] ?? []),
      reportId: data['reportId'] ?? '',
      lastMessage: data['lastMessage'],
      lastUpdated: data['lastUpdated'] ?? Timestamp.now(),
      muted: data['muted'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'participants': participants,
      'reportId': reportId,
      'lastMessage': lastMessage,
      'lastUpdated': lastUpdated,
      'muted': muted,
    };
  }
} 