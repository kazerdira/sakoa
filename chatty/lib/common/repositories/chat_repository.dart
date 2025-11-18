import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sakoa/common/entities/entities.dart';
import 'package:sakoa/common/services/message_delivery_service.dart';
import 'package:sakoa/common/services/voice_message_service.dart';
import 'package:sakoa/common/services/voice_cache_manager.dart';

/// 🏗️ REPOSITORY PATTERN: Business logic for chat operations
///
/// This repository orchestrates multiple services to handle complex chat operations.
/// Controllers should call repository methods instead of services directly.
///
/// Benefits:
/// - Thin controllers (only UI state management)
/// - Testable business logic
/// - Reusable operations
/// - Single source of truth for chat operations
class ChatRepository {
  final MessageDeliveryService _deliveryService;
  final VoiceMessageService _voiceService;
  final VoiceCacheManager _cacheManager;
  final FirebaseFirestore _db;

  ChatRepository({
    required MessageDeliveryService deliveryService,
    required VoiceMessageService voiceService,
    required VoiceCacheManager cacheManager,
    required FirebaseFirestore db,
  })  : _deliveryService = deliveryService,
        _voiceService = voiceService,
        _cacheManager = cacheManager,
        _db = db;

  /// 🎤 Send voice message with upload, pre-caching, and delivery tracking
  ///
  /// This method handles the entire voice message flow:
  /// 1. Copy local file for pre-caching (upload deletes original)
  /// 2. Upload to Firebase Storage
  /// 3. Send message to Firestore with delivery tracking
  /// 4. Pre-cache local file for instant sender playback
  /// 5. Update chat metadata (last message, timestamps, counters)
  ///
  /// Returns SendMessageResult with messageId or error
  Future<SendMessageResult> sendVoiceMessage({
    required String chatDocId,
    required String senderToken,
    required String localPath,
    required Duration duration,
    required Function(String messageId) onMessageAdded,
    MessageReply? reply,
  }) async {
    String? tempCopyPath;

    try {
      print('[ChatRepository] 🎤 Starting voice message send...');

      // Step 1: Copy file before upload (upload deletes it!)
      print('[ChatRepository] 📋 Copying local file for pre-caching...');
      tempCopyPath = '${localPath}_precache';
      await File(localPath).copy(tempCopyPath);

      // Step 2: Upload to Firebase Storage
      print('[ChatRepository] ☁️ Uploading to Firebase Storage...');
      final audioUrl = await _voiceService.uploadVoiceMessage(localPath);

      if (audioUrl == null) {
        throw Exception('Failed to upload voice message to Firebase Storage');
      }

      // Step 3: Create message content
      final content = Msgcontent(
        token: senderToken,
        content: audioUrl,
        type: "voice",
        addtime: Timestamp.now(),
        voice_duration: duration.inSeconds,
        reply: reply,
      );

      // Step 4: Send with delivery tracking
      print('[ChatRepository] 📤 Sending to Firestore...');
      final result = await _deliveryService.sendMessageWithTracking(
        chatDocId: chatDocId,
        content: content,
      );

      if (!result.success && !result.queued) {
        throw Exception(result.error ?? 'Failed to send message');
      }

      final messageId = result.messageId;
      print(
          '[ChatRepository] ✅ Message sent: $messageId (queued: ${result.queued})');

      // Step 5: Pre-cache for instant sender playback
      if (messageId != null && messageId.isNotEmpty) {
        try {
          print('[ChatRepository] 🎯 Pre-caching local recording...');
          final cached = await _cacheManager.preCacheLocalFile(
            messageId: messageId,
            localFilePath: tempCopyPath,
            audioUrl: audioUrl,
          );

          if (cached) {
            print('[ChatRepository] ✅ Pre-cached successfully');
          } else {
            print('[ChatRepository] ⚠️ Pre-cache returned false');
          }
        } catch (e) {
          print('[ChatRepository] ⚠️ Pre-cache error (non-fatal): $e');
          // Non-fatal: User will download normally
        }
      }

      // Step 6: Update chat metadata
      await _updateChatMetadata(
        chatDocId: chatDocId,
        senderToken: senderToken,
        lastMessage: "🎤 Voice message",
      );

      // Notify controller that message was added (for UI updates)
      if (messageId != null) {
        onMessageAdded(messageId);
      }

      return result;
    } catch (e, stackTrace) {
      print('[ChatRepository] ❌ Voice message send failed: $e');
      print('[ChatRepository] Stack trace: $stackTrace');
      return SendMessageResult.error(e.toString());
    } finally {
      // Clean up temp copy
      if (tempCopyPath != null) {
        try {
          await File(tempCopyPath).delete();
          print('[ChatRepository] 🗑️ Cleaned up temp file');
        } catch (e) {
          print('[ChatRepository] ⚠️ Failed to delete temp file: $e');
        }
      }
    }
  }

  /// 📝 Send text message with delivery tracking
  Future<SendMessageResult> sendTextMessage({
    required String chatDocId,
    required String senderToken,
    required String text,
    MessageReply? reply,
  }) async {
    try {
      print('[ChatRepository] 📝 Sending text message...');

      final content = Msgcontent(
        token: senderToken,
        content: text,
        type: "text",
        addtime: Timestamp.now(),
        reply: reply,
      );

      final result = await _deliveryService.sendMessageWithTracking(
        chatDocId: chatDocId,
        content: content,
      );

      if (result.success || result.queued) {
        await _updateChatMetadata(
          chatDocId: chatDocId,
          senderToken: senderToken,
          lastMessage: text,
        );
      }

      return result;
    } catch (e, stackTrace) {
      print('[ChatRepository] ❌ Text message send failed: $e');
      print('[ChatRepository] Stack trace: $stackTrace');
      return SendMessageResult.error(e.toString());
    }
  }

  /// 🖼️ Send image message with upload and delivery tracking
  Future<SendMessageResult> sendImageMessage({
    required String chatDocId,
    required String senderToken,
    required String imagePath,
    MessageReply? reply,
  }) async {
    try {
      print('[ChatRepository] 🖼️ Sending image message...');

      // Upload image to Firebase Storage
      // TODO: Extract to MediaService
      final imageUrl = await _uploadImage(imagePath);

      if (imageUrl == null) {
        throw Exception('Failed to upload image');
      }

      final content = Msgcontent(
        token: senderToken,
        content: imageUrl,
        type: "image",
        addtime: Timestamp.now(),
        reply: reply,
      );

      final result = await _deliveryService.sendMessageWithTracking(
        chatDocId: chatDocId,
        content: content,
      );

      if (result.success || result.queued) {
        await _updateChatMetadata(
          chatDocId: chatDocId,
          senderToken: senderToken,
          lastMessage: "📷 Image",
        );
      }

      return result;
    } catch (e, stackTrace) {
      print('[ChatRepository] ❌ Image message send failed: $e');
      print('[ChatRepository] Stack trace: $stackTrace');
      return SendMessageResult.error(e.toString());
    }
  }

  /// 🔄 Update chat metadata (last message, timestamps, counters)
  Future<void> _updateChatMetadata({
    required String chatDocId,
    required String senderToken,
    required String lastMessage,
  }) async {
    try {
      final messageDoc = await _db
          .collection("message")
          .doc(chatDocId)
          .withConverter(
            fromFirestore: Msg.fromFirestore,
            toFirestore: (Msg msg, options) => msg.toFirestore(),
          )
          .get();

      if (messageDoc.data() != null) {
        final item = messageDoc.data()!;
        int toMsgNum = item.to_msg_num ?? 0;
        int fromMsgNum = item.from_msg_num ?? 0;

        if (item.from_token == senderToken) {
          fromMsgNum++;
        } else {
          toMsgNum++;
        }

        await _db.collection("message").doc(chatDocId).update({
          "to_msg_num": toMsgNum,
          "from_msg_num": fromMsgNum,
          "last_msg": lastMessage,
          "last_time": Timestamp.now(),
        });

        print('[ChatRepository] ✅ Chat metadata updated');
      }
    } catch (e) {
      print('[ChatRepository] ⚠️ Failed to update chat metadata: $e');
      // Non-fatal: Don't throw, just log
    }
  }

  /// 🖼️ Upload image to Firebase Storage
  /// TODO: Extract to MediaService
  Future<String?> _uploadImage(String imagePath) async {
    try {
      // TODO: Implement image upload
      // For now, this is a placeholder
      print(
          '[ChatRepository] ⚠️ Image upload not yet implemented in repository');
      return null;
    } catch (e) {
      print('[ChatRepository] ❌ Image upload failed: $e');
      return null;
    }
  }
}
