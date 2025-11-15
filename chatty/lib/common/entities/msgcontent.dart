import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sakoa/common/entities/message_reply_entity.dart';

/// 🔥 ENHANCED MESSAGE CONTENT ENTITY
/// Now supports: voice messages, replies, message IDs
class Msgcontent {
  final String? id; // 🔥 NEW: Message document ID
  final String? token;
  final String? content;
  final String? type; // 'text', 'image', 'video', 'voice'
  final Timestamp? addtime;
  final int? voice_duration; // 🔥 NEW: Duration in seconds for voice messages
  final MessageReply? reply; // 🔥 NEW: Reply/quote data

  Msgcontent({
    this.id,
    this.token,
    this.content,
    this.type,
    this.addtime,
    this.voice_duration,
    this.reply,
  });

  factory Msgcontent.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();

    // 🔥 Parse reply if exists
    MessageReply? replyData;
    if (data?['reply'] != null) {
      try {
        replyData =
            MessageReply.fromFirestore(data!['reply'] as Map<String, dynamic>);
      } catch (e) {
        print('[Msgcontent] ⚠️ Failed to parse reply: $e');
      }
    }

    return Msgcontent(
      id: snapshot.id, // 🔥 Get document ID
      token: data?['token'],
      content: data?['content'],
      type: data?['type'],
      addtime: data?['addtime'],
      voice_duration: data?['voice_duration'] as int?,
      reply: replyData,
    );
  }

  Map<String, dynamic> toFirestore() {
    final Map<String, dynamic> data = {};

    if (token != null) data["token"] = token;
    if (content != null) data["content"] = content;
    if (type != null) data["type"] = type;
    if (addtime != null) data["addtime"] = addtime;

    // 🔥 Add voice duration if exists
    if (voice_duration != null) {
      data["voice_duration"] = voice_duration;
    }

    // 🔥 Add reply if exists
    if (reply != null) {
      data["reply"] = reply!.toFirestore();
    }

    return data;
  }
}
