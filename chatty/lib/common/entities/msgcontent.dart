import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sakoa/common/entities/message_reply_entity.dart';

/// 🔥 INDUSTRIAL-GRADE MESSAGE CONTENT ENTITY
/// Full WhatsApp-level features:
/// - Voice messages with duration
/// - Message replies/quotes
/// - Delivery status tracking (sending/sent/delivered/read/failed)
/// - Timestamps for each status transition
/// - Offline queue support
class Msgcontent {
  final String? id; // Message document ID
  final String? token; // Sender token
  final String? content; // Message content (text, URL, etc.)
  final String? type; // 'text', 'image', 'video', 'voice'
  final Timestamp? addtime; // When message was created
  final int? voice_duration; // Duration in seconds for voice messages
  final MessageReply? reply; // Reply/quote data

  // 🔥 INDUSTRIAL-GRADE DELIVERY TRACKING
  final String?
      delivery_status; // 'sending', 'sent', 'delivered', 'read', 'failed'
  final Timestamp? sent_at; // When message was uploaded to Firestore
  final Timestamp? delivered_at; // When receiver's device received it
  final Timestamp? read_at; // When receiver opened the chat
  final int? retry_count; // Number of send attempts (for failed messages)

  Msgcontent({
    this.id,
    this.token,
    this.content,
    this.type,
    this.addtime,
    this.voice_duration,
    this.reply,
    this.delivery_status,
    this.sent_at,
    this.delivered_at,
    this.read_at,
    this.retry_count,
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
      id: snapshot.id, // Get document ID
      token: data?['token'],
      content: data?['content'],
      type: data?['type'],
      addtime: data?['addtime'],
      voice_duration: data?['voice_duration'] as int?,
      reply: replyData,
      // 🔥 Delivery tracking fields
      delivery_status: data?['delivery_status'] as String?,
      sent_at: data?['sent_at'] as Timestamp?,
      delivered_at: data?['delivered_at'] as Timestamp?,
      read_at: data?['read_at'] as Timestamp?,
      retry_count: data?['retry_count'] as int?,
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

    // 🔥 INDUSTRIAL-GRADE: Add delivery tracking fields
    if (delivery_status != null) {
      data["delivery_status"] = delivery_status;
    }
    if (sent_at != null) {
      data["sent_at"] = sent_at;
    }
    if (delivered_at != null) {
      data["delivered_at"] = delivered_at;
    }
    if (read_at != null) {
      data["read_at"] = read_at;
    }
    if (retry_count != null) {
      data["retry_count"] = retry_count;
    }

    return data;
  }
}
