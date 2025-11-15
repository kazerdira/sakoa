import 'package:cloud_firestore/cloud_firestore.dart';

/// 🔥 INDUSTRIAL-GRADE MESSAGE REPLY ENTITY
/// Used to store reply/quote information within messages
/// Supports replying to text, voice, image, and video messages
class MessageReply {
  final String originalMessageId; // Reference to original message
  final String originalContent; // Original message content (URL for media)
  final String originalType; // 'text', 'voice', 'image', 'video'
  final String originalSenderToken; // Who sent the original message
  final String originalSenderName; // Sender's display name
  final Timestamp? originalTimestamp; // When original was sent
  final int? voiceDuration; // Duration if original was voice message

  MessageReply({
    required this.originalMessageId,
    required this.originalContent,
    required this.originalType,
    required this.originalSenderToken,
    required this.originalSenderName,
    this.originalTimestamp,
    this.voiceDuration,
  });

  /// Factory constructor from Firestore document
  factory MessageReply.fromFirestore(Map<String, dynamic> data) {
    return MessageReply(
      originalMessageId: data['originalMessageId'] ?? '',
      originalContent: data['originalContent'] ?? '',
      originalType: data['originalType'] ?? 'text',
      originalSenderToken: data['originalSenderToken'] ?? '',
      originalSenderName: data['originalSenderName'] ?? 'Unknown',
      originalTimestamp: data['originalTimestamp'] as Timestamp?,
      voiceDuration: data['voiceDuration'] as int?,
    );
  }

  /// Factory constructor from message data (for creating replies)
  factory MessageReply.fromMessage(
    Map<String, dynamic> messageData,
    String messageId,
  ) {
    return MessageReply(
      originalMessageId: messageId,
      originalContent: messageData['content'] ?? '',
      originalType: messageData['type'] ?? 'text',
      originalSenderToken: messageData['token'] ?? '',
      originalSenderName: messageData['sender_name'] ?? 'Unknown',
      originalTimestamp: messageData['addtime'] as Timestamp?,
      voiceDuration: messageData['voice_duration'] as int?,
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    final Map<String, dynamic> data = {
      'originalMessageId': originalMessageId,
      'originalContent': originalContent,
      'originalType': originalType,
      'originalSenderToken': originalSenderToken,
      'originalSenderName': originalSenderName,
    };

    if (originalTimestamp != null) {
      data['originalTimestamp'] = originalTimestamp!;
    }

    if (voiceDuration != null) {
      data['voiceDuration'] = voiceDuration!;
    }

    return data;
  }

  /// Get display text for reply preview
  String getDisplayText() {
    switch (originalType) {
      case 'voice':
        final duration = voiceDuration ?? 0;
        final minutes = duration ~/ 60;
        final seconds = duration % 60;
        return '🎤 Voice message ${minutes}:${seconds.toString().padLeft(2, '0')}';
      case 'image':
        return '📷 Photo';
      case 'video':
        return '🎥 Video';
      case 'text':
      default:
        // Truncate long text
        if (originalContent.length > 50) {
          return '${originalContent.substring(0, 50)}...';
        }
        return originalContent;
    }
  }

  /// Check if this is my message
  bool isMyMessage(String currentUserToken) {
    return originalSenderToken == currentUserToken;
  }

  @override
  String toString() {
    return 'MessageReply(id: $originalMessageId, type: $originalType, sender: $originalSenderName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MessageReply &&
        other.originalMessageId == originalMessageId;
  }

  @override
  int get hashCode => originalMessageId.hashCode;

  /// Copy with method for immutability
  MessageReply copyWith({
    String? originalMessageId,
    String? originalContent,
    String? originalType,
    String? originalSenderToken,
    String? originalSenderName,
    Timestamp? originalTimestamp,
    int? voiceDuration,
  }) {
    return MessageReply(
      originalMessageId: originalMessageId ?? this.originalMessageId,
      originalContent: originalContent ?? this.originalContent,
      originalType: originalType ?? this.originalType,
      originalSenderToken: originalSenderToken ?? this.originalSenderToken,
      originalSenderName: originalSenderName ?? this.originalSenderName,
      originalTimestamp: originalTimestamp ?? this.originalTimestamp,
      voiceDuration: voiceDuration ?? this.voiceDuration,
    );
  }
}
