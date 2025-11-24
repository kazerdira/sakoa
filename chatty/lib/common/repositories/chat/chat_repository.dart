import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sakoa/common/entities/entities.dart';
import 'package:sakoa/common/repositories/base/base_repository.dart';

/// 💬 CHAT REPOSITORY
///
/// Handles general chat operations (not message-type specific):
/// - Loading messages with pagination
/// - Real-time message streams
/// - Chat metadata operations
/// - Search and filtering
///
/// This repository complements the message-type repositories:
/// - TextMessageRepository (sending text messages)
/// - VoiceMessageRepository (sending voice messages)
/// - ImageMessageRepository (sending image messages)
///
/// Separation of concerns:
/// - ChatRepository → General chat operations (load, subscribe, metadata)
/// - Message repositories → Type-specific sending logic
class ChatRepository extends BaseRepository {
  final FirebaseFirestore _db;

  @override
  String get repositoryName => 'ChatRepository';

  ChatRepository({
    required FirebaseFirestore db,
  }) : _db = db;

  /// 📥 Load more messages with pagination
  ///
  /// Loads messages before a specific timestamp (cursor-based pagination).
  /// Used for "load more" functionality when scrolling up in chat.
  ///
  /// Returns list of messages ordered by addtime descending.
  Future<List<Msgcontent>> loadMoreMessages({
    required String chatDocId,
    required Timestamp beforeTimestamp,
    int limit = 10,
  }) async {
    try {
      logInfo(
          'Loading more messages (before: $beforeTimestamp, limit: $limit)');

      final snapshot = await _db
          .collection("message")
          .doc(chatDocId)
          .collection("msglist")
          .withConverter(
            fromFirestore: Msgcontent.fromFirestore,
            toFirestore: (Msgcontent msgcontent, options) =>
                msgcontent.toFirestore(),
          )
          .orderBy("addtime", descending: true)
          .where("addtime", isLessThan: beforeTimestamp)
          .limit(limit)
          .get();

      final messages = snapshot.docs.map((doc) => doc.data()).toList();
      logSuccess('Loaded ${messages.length} messages');

      return messages;
    } catch (e, stackTrace) {
      logError('Failed to load more messages', e, stackTrace);
      return [];
    }
  }

  /// 🔄 Subscribe to real-time message updates
  ///
  /// Returns a stream of message lists that updates in real-time.
  /// Used for initial message loading and live updates.
  ///
  /// Note: Stream emits DocumentSnapshot changes, not processed messages.
  /// Controller should handle:
  /// - Duplicate checking
  /// - Block filtering
  /// - Delivery status updates
  /// - UI updates
  Stream<QuerySnapshot<Msgcontent>> subscribeToMessages({
    required String chatDocId,
    int limit = 15,
  }) {
    try {
      logInfo('Subscribing to messages (limit: $limit)');

      return _db
          .collection("message")
          .doc(chatDocId)
          .collection("msglist")
          .withConverter(
            fromFirestore: Msgcontent.fromFirestore,
            toFirestore: (Msgcontent msgcontent, options) =>
                msgcontent.toFirestore(),
          )
          .orderBy("addtime", descending: true)
          .limit(limit)
          .snapshots();
    } catch (e, stackTrace) {
      logError('Failed to subscribe to messages', e, stackTrace);
      // Return empty stream on error
      return Stream.empty();
    }
  }

  /// 🔢 Clear unread message count for user
  ///
  /// Resets the message counter when user opens chat.
  /// Updates either to_msg_num or from_msg_num based on user token.
  Future<void> clearUnreadCount(String chatDocId, String userToken) async {
    try {
      logInfo('Clearing unread count for chat: $chatDocId');

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

        // Clear counter for current user
        if (item.from_token == userToken) {
          toMsgNum = 0;
        } else {
          fromMsgNum = 0;
        }

        await _db.collection("message").doc(chatDocId).update({
          "to_msg_num": toMsgNum,
          "from_msg_num": fromMsgNum,
        });

        logSuccess('Unread count cleared');
      } else {
        logWarning('Chat document not found: $chatDocId');
      }
    } catch (e, stackTrace) {
      logError('Failed to clear unread count', e, stackTrace);
      // Non-fatal: Don't throw, just log
    }
  }

  /// 📊 Get chat information
  ///
  /// Retrieves chat metadata (participants, counters, last message).
  /// Returns null if chat doesn't exist.
  Future<Msg?> getChatInfo(String chatDocId) async {
    try {
      logInfo('Getting chat info: $chatDocId');

      final doc = await _db
          .collection("message")
          .doc(chatDocId)
          .withConverter(
            fromFirestore: Msg.fromFirestore,
            toFirestore: (Msg msg, options) => msg.toFirestore(),
          )
          .get();

      if (doc.exists) {
        logSuccess('Chat info retrieved');
        return doc.data();
      } else {
        logWarning('Chat not found: $chatDocId');
        return null;
      }
    } catch (e, stackTrace) {
      logError('Failed to get chat info', e, stackTrace);
      return null;
    }
  }

  /// 🔍 Search messages in chat
  ///
  /// Searches for messages containing the query string.
  /// Note: Firestore doesn't support full-text search natively.
  /// This is a basic implementation for exact/partial matches.
  ///
  /// For production, consider using:
  /// - Algolia Search
  /// - Elasticsearch
  /// - Firebase Extensions (Typesense)
  Future<List<Msgcontent>> searchMessages({
    required String chatDocId,
    required String query,
    int limit = 50,
  }) async {
    try {
      logInfo('Searching messages: "$query"');

      // Load recent messages and filter client-side
      // (Firestore doesn't support LIKE queries)
      final snapshot = await _db
          .collection("message")
          .doc(chatDocId)
          .collection("msglist")
          .withConverter(
            fromFirestore: Msgcontent.fromFirestore,
            toFirestore: (Msgcontent msgcontent, options) =>
                msgcontent.toFirestore(),
          )
          .orderBy("addtime", descending: true)
          .limit(limit)
          .get();

      // Client-side filtering
      final results = snapshot.docs
          .map((doc) => doc.data())
          .where((msg) =>
              msg.content != null &&
              msg.content!.toLowerCase().contains(query.toLowerCase()))
          .toList();

      logSuccess('Found ${results.length} matching messages');
      return results;
    } catch (e, stackTrace) {
      logError('Failed to search messages', e, stackTrace);
      return [];
    }
  }
}
