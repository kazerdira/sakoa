import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sakoa/common/entities/entities.dart';
import 'package:sakoa/common/services/message_delivery_service.dart';
import 'package:sakoa/common/services/voice_message_service.dart';
import 'package:sakoa/common/services/voice_cache_manager.dart';
import 'package:sakoa/common/repositories/base/base_repository.dart';

/// 🎤 VOICE MESSAGE REPOSITORY
///
/// Handles all voice message operations:
/// - Recording and uploading voice messages
/// - Pre-caching for instant sender playback
/// - Delivery tracking and status updates
/// - Chat metadata updates
///
/// This repository orchestrates VoiceMessageService, MessageDeliveryService,
/// and VoiceCacheManager to provide a complete voice messaging solution.
class VoiceMessageRepository extends BaseRepository {
  final MessageDeliveryService _deliveryService;
  final VoiceMessageService _voiceService;
  final VoiceCacheManager _cacheManager;
  final FirebaseFirestore _db;

  @override
  String get repositoryName => 'VoiceMessageRepository';

  VoiceMessageRepository({
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
      logInfo('Starting voice message send...');

      // Step 1: Copy file before upload (upload deletes it!)
      logDebug('Copying local file for pre-caching...');
      tempCopyPath = '${localPath}_precache';
      await File(localPath).copy(tempCopyPath);

      // Step 2: Upload to Firebase Storage
      logDebug('Uploading to Firebase Storage...');
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
      logDebug('Sending to Firestore...');
      final result = await _deliveryService.sendMessageWithTracking(
        chatDocId: chatDocId,
        content: content,
      );

      if (!result.success && !result.queued) {
        throw Exception(result.error ?? 'Failed to send message');
      }

      final messageId = result.messageId;
      logSuccess('Message sent: $messageId (queued: ${result.queued})');

      // 🔥 CRITICAL: Update placeholder ID IMMEDIATELY (before Firestore listener fires)
      if (messageId != null) {
        onMessageAdded(messageId);
        logDebug('Notified controller: placeholder → $messageId');
      }

      // Step 5: Pre-cache for instant sender playback
      if (messageId != null && messageId.isNotEmpty) {
        try {
          logDebug('Pre-caching local recording...');
          final cached = await _cacheManager.preCacheLocalFile(
            messageId: messageId,
            localFilePath: tempCopyPath,
            audioUrl: audioUrl,
          );

          if (cached) {
            logSuccess('Pre-cached successfully');
          } else {
            logWarning('Pre-cache returned false');
          }
        } catch (e) {
          logWarning('Pre-cache error (non-fatal): $e');
          // Non-fatal: User will download normally
        }
      }

      // Step 6: Update chat metadata
      await _updateChatMetadata(
        chatDocId: chatDocId,
        senderToken: senderToken,
        lastMessage: "🎤 Voice message",
      );

      return result;
    } catch (e, stackTrace) {
      logError('Voice message send failed', e, stackTrace);
      return SendMessageResult.error(e.toString());
    } finally {
      // Clean up temp copy
      if (tempCopyPath != null) {
        try {
          await File(tempCopyPath).delete();
          logDebug('Cleaned up temp file');
        } catch (e) {
          logWarning('Failed to delete temp file: $e');
        }
      }
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

        logSuccess('Chat metadata updated');
      }
    } catch (e) {
      logWarning('Failed to update chat metadata: $e');
      // Non-fatal: Don't throw, just log
    }
  }
}
