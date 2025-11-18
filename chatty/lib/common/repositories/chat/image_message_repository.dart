import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sakoa/common/entities/entities.dart';
import 'package:sakoa/common/services/message_delivery_service.dart';
import 'package:sakoa/common/repositories/base/base_repository.dart';

/// 🖼️ IMAGE MESSAGE REPOSITORY
///
/// Handles all image message operations:
/// - Sending image messages (URL already uploaded)
/// - Delivery tracking and status updates
/// - Chat metadata updates
///
/// Note: Image upload to storage should happen before calling this repository.
/// This repository only handles sending the message with the image URL.
class ImageMessageRepository extends BaseRepository {
  final MessageDeliveryService _deliveryService;
  final FirebaseFirestore _db;

  @override
  String get repositoryName => 'ImageMessageRepository';

  ImageMessageRepository({
    required MessageDeliveryService deliveryService,
    required FirebaseFirestore db,
  })  : _deliveryService = deliveryService,
        _db = db;

  /// 🖼️ Send image message with delivery tracking
  ///
  /// This method handles the image message flow:
  /// 1. Create message content with image URL
  /// 2. Send to Firestore with delivery tracking
  /// 3. Update chat metadata (last message, timestamps, counters)
  ///
  /// Note: The imageUrl should be a Firebase Storage URL obtained
  /// from uploading the image file first.
  ///
  /// Returns SendMessageResult with messageId or error
  Future<SendMessageResult> sendImageMessage({
    required String chatDocId,
    required String senderToken,
    required String imageUrl,
    MessageReply? reply,
  }) async {
    try {
      logInfo('Sending image message...');

      // Step 1: Create message content
      final content = Msgcontent(
        token: senderToken,
        content: imageUrl,
        type: "image",
        addtime: Timestamp.now(),
        reply: reply,
      );

      // Step 2: Send with delivery tracking
      logDebug('Sending to Firestore...');
      final result = await _deliveryService.sendMessageWithTracking(
        chatDocId: chatDocId,
        content: content,
      );

      // Step 3: Update chat metadata on success
      if (result.success || result.queued) {
        await _updateChatMetadata(
          chatDocId: chatDocId,
          senderToken: senderToken,
          lastMessage: "📷 Image",
        );
        logSuccess(
            'Image message sent: ${result.messageId} (queued: ${result.queued})');
      } else {
        logWarning('Image message failed: ${result.error}');
      }

      return result;
    } catch (e, stackTrace) {
      logError('Image message send failed', e, stackTrace);
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

        logSuccess('Chat metadata updated');
      }
    } catch (e) {
      logWarning('Failed to update chat metadata: $e');
      // Non-fatal: Don't throw, just log
    }
  }
}
