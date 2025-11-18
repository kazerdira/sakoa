import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:sakoa/common/apis/chat.dart';
import 'package:sakoa/common/entities/entities.dart';
import 'package:sakoa/common/exceptions/call_exceptions.dart';
import 'package:sakoa/common/repositories/base/base_repository.dart';
import 'package:sakoa/common/store/store.dart';

/// Repository for handling all call-related operations
/// Handles voice and video calls using Agora RTC
class CallRepository extends BaseRepository {
  final FirebaseFirestore _db;

  CallRepository({
    required FirebaseFirestore db,
  }) : _db = db;

  @override
  String get repositoryName => 'CallRepository';

  String get _myToken => UserStore.to.profile.token ?? UserStore.to.token;

  // ============ CALL TOKEN MANAGEMENT ============

  /// Generate call token for Agora RTC
  /// [callRole] - "anchor" (initiator) or "audience" (receiver)
  /// [recipientToken] - Token of the other user
  Future<CallTokenResult> getCallToken({
    required String callRole,
    required String recipientToken,
  }) async {
    try {
      logDebug('Getting call token for role: $callRole');

      // Generate channel ID based on role
      final String channelId;
      if (callRole == "anchor") {
        channelId =
            md5.convert(utf8.encode("${_myToken}_$recipientToken")).toString();
      } else {
        channelId =
            md5.convert(utf8.encode("${recipientToken}_$_myToken")).toString();
      }

      logInfo('Generated channel ID: $channelId');

      // Request token from server
      final callTokenRequest = CallTokenRequestEntity();
      callTokenRequest.channel_name = channelId;

      final res = await ChatAPI.call_token(params: callTokenRequest);

      if (res.code == 0 && res.data != null && res.data!.isNotEmpty) {
        logSuccess('Call token obtained successfully');
        return CallTokenResult(
          token: res.data!,
          channelId: channelId,
        );
      }

      logError('Failed to get call token: ${res.msg}');
      throw CallTokenException(
        message: 'Server returned empty token',
        context: {
          'channelId': channelId,
          'responseCode': res.code,
          'responseMessage': res.msg,
        },
      );
    } catch (e, stack) {
      logError('Failed to get call token', e, stack);
      if (e is CallTokenException) rethrow;
      throw CallTokenException(
        message: 'Failed to generate call token',
        originalError: e,
        stackTrace: stack,
        context: {
          'callRole': callRole,
          'recipientToken': recipientToken,
        },
      );
    }
  }

  // ============ CALL NOTIFICATIONS ============

  /// Send call notification to recipient
  /// [callType] - "voice", "video", or "cancel"
  /// [recipientToken] - Token of the recipient
  /// [recipientName] - Name of the recipient
  /// [recipientAvatar] - Avatar of the recipient
  /// [docId] - Message document ID for the chat
  Future<bool> sendCallNotification({
    required String callType,
    required String recipientToken,
    required String recipientName,
    required String recipientAvatar,
    required String docId,
  }) async {
    try {
      logDebug('Sending $callType call notification to: $recipientName');

      final callRequest = CallRequestEntity();
      callRequest.call_type = callType;
      callRequest.to_token = recipientToken;
      callRequest.to_name = recipientName;
      callRequest.to_avatar = recipientAvatar;
      callRequest.doc_id = docId;

      final res = await ChatAPI.call_notifications(params: callRequest);

      if (res.code == 0) {
        logSuccess('Call notification sent successfully');
        return true;
      }

      logWarning('Call notification failed: ${res.msg}');
      return false;
    } catch (e, stack) {
      logError('Failed to send call notification', e, stack);
      throw CallNotificationException(
        message: 'Failed to send call notification',
        originalError: e,
        stackTrace: stack,
        context: {
          'callType': callType,
          'recipientToken': recipientToken,
          'recipientName': recipientName,
        },
      );
    }
  }

  // ============ CALL HISTORY ============

  /// Save call history to Firestore
  /// [callType] - "voice" or "video"
  /// [recipientToken] - Token of the other user
  /// [recipientName] - Name of the other user
  /// [recipientAvatar] - Avatar of the other user
  /// [callDuration] - Formatted call duration string (e.g., "5 m and 30 s")
  Future<void> saveCallHistory({
    required String callType,
    required String recipientToken,
    required String recipientName,
    required String recipientAvatar,
    required String callDuration,
  }) async {
    try {
      logDebug('Saving $callType call history: $callDuration');

      final profile = UserStore.to.profile;

      final callData = ChatCall(
        from_token: profile.token,
        to_token: recipientToken,
        from_name: profile.name,
        to_name: recipientName,
        from_avatar: profile.avatar,
        to_avatar: recipientAvatar,
        call_time: callDuration,
        type: callType,
        last_time: Timestamp.now(),
      );

      await _db
          .collection("chatcall")
          .withConverter(
            fromFirestore: ChatCall.fromFirestore,
            toFirestore: (ChatCall msg, options) => msg.toFirestore(),
          )
          .add(callData);

      logSuccess('Call history saved successfully');
    } catch (e, stack) {
      logError('Failed to save call history', e, stack);
      throw CallHistoryException(
        message: 'Failed to save call history',
        originalError: e,
        stackTrace: stack,
        context: {
          'callType': callType,
          'recipientToken': recipientToken,
          'callDuration': callDuration,
        },
      );
    }
  }

  /// Send call summary message to chat
  /// [docId] - Chat document ID
  /// [callDuration] - Formatted call duration
  /// [callType] - "voice" or "video"
  Future<void> sendCallSummaryMessage({
    required String docId,
    required String callDuration,
    required String callType,
  }) async {
    try {
      if (docId.isEmpty) {
        logWarning('Cannot send call summary: docId is empty');
        return;
      }

      logDebug('Sending call summary message to chat: $docId');

      final sendContent = "Call time $callDuration 【$callType】";

      final content = Msgcontent(
        token: _myToken,
        content: sendContent,
        type: "text",
        addtime: Timestamp.now(),
      );

      await _db
          .collection("message")
          .doc(docId)
          .collection("msglist")
          .withConverter(
            fromFirestore: Msgcontent.fromFirestore,
            toFirestore: (Msgcontent msgcontent, options) =>
                msgcontent.toFirestore(),
          )
          .add(content);

      // Update message metadata
      final messageDoc = await _db
          .collection("message")
          .doc(docId)
          .withConverter(
            fromFirestore: Msg.fromFirestore,
            toFirestore: (Msg msg, options) => msg.toFirestore(),
          )
          .get();

      if (messageDoc.data() != null) {
        final item = messageDoc.data()!;
        int toMsgNum = item.to_msg_num ?? 0;
        int fromMsgNum = item.from_msg_num ?? 0;

        if (item.from_token == _myToken) {
          fromMsgNum = fromMsgNum + 1;
        } else {
          toMsgNum = toMsgNum + 1;
        }

        await _db.collection("message").doc(docId).update({
          "to_msg_num": toMsgNum,
          "from_msg_num": fromMsgNum,
          "last_msg": sendContent,
          "last_time": Timestamp.now(),
        });

        logSuccess('Call summary message sent to chat');
      }
    } catch (e, stack) {
      logError('Failed to send call summary message', e, stack);
      // Don't throw - this is a non-critical operation
      // The call completed successfully even if summary fails
    }
  }

  // ============ CALL LIFECYCLE ============

  /// Complete a call and save all history
  /// This should be called when the anchor (initiator) ends the call
  /// [callType] - "voice" or "video"
  /// [recipientToken] - Token of the other user
  /// [recipientName] - Name of the other user
  /// [recipientAvatar] - Avatar of the other user
  /// [callDuration] - Formatted call duration string
  /// [docId] - Chat document ID
  Future<void> completeCall({
    required String callType,
    required String recipientToken,
    required String recipientName,
    required String recipientAvatar,
    required String callDuration,
    required String docId,
  }) async {
    try {
      logDebug('Completing $callType call with duration: $callDuration');

      // Save call history
      await saveCallHistory(
        callType: callType,
        recipientToken: recipientToken,
        recipientName: recipientName,
        recipientAvatar: recipientAvatar,
        callDuration: callDuration,
      );

      // Send summary message to chat
      await sendCallSummaryMessage(
        docId: docId,
        callDuration: callDuration,
        callType: callType,
      );

      logSuccess('Call completed and history saved');
    } catch (e, stack) {
      logError('Failed to complete call properly', e, stack);
      // Rethrow if it's a history exception
      if (e is CallHistoryException) rethrow;

      throw CallHistoryException(
        message: 'Failed to complete call',
        originalError: e,
        stackTrace: stack,
        context: {
          'callType': callType,
          'callDuration': callDuration,
        },
      );
    }
  }

  /// Initiate a call (combines token generation and notification)
  /// [callType] - "voice" or "video"
  /// [recipientToken] - Token of the recipient
  /// [recipientName] - Name of the recipient
  /// [recipientAvatar] - Avatar of the recipient
  /// [docId] - Message document ID for the chat
  /// Returns the call token result for joining the channel
  Future<CallTokenResult> initiateCall({
    required String callType,
    required String recipientToken,
    required String recipientName,
    required String recipientAvatar,
    required String docId,
  }) async {
    try {
      logDebug('Initiating $callType call to: $recipientName');

      // Get call token
      final tokenResult = await getCallToken(
        callRole: "anchor",
        recipientToken: recipientToken,
      );

      // Send notification
      await sendCallNotification(
        callType: callType,
        recipientToken: recipientToken,
        recipientName: recipientName,
        recipientAvatar: recipientAvatar,
        docId: docId,
      );

      logSuccess('Call initiated successfully');
      return tokenResult;
    } catch (e, stack) {
      logError('Failed to initiate call', e, stack);
      if (e is CallException) rethrow;

      throw CallInitiationException(
        message: 'Failed to initiate call',
        originalError: e,
        stackTrace: stack,
        context: {
          'callType': callType,
          'recipientToken': recipientToken,
        },
      );
    }
  }

  /// Join an incoming call
  /// [recipientToken] - Token of the caller
  /// Returns the call token result for joining the channel
  Future<CallTokenResult> joinCall({
    required String recipientToken,
  }) async {
    try {
      logDebug('Joining call from: $recipientToken');

      final tokenResult = await getCallToken(
        callRole: "audience",
        recipientToken: recipientToken,
      );

      logSuccess('Ready to join call');
      return tokenResult;
    } catch (e, stack) {
      logError('Failed to join call', e, stack);
      if (e is CallException) rethrow;

      throw CallJoinException(
        message: 'Failed to join call',
        originalError: e,
        stackTrace: stack,
        context: {
          'recipientToken': recipientToken,
        },
      );
    }
  }

  /// Cancel a call (send cancel notification)
  /// [recipientToken] - Token of the other user
  /// [recipientName] - Name of the other user
  /// [recipientAvatar] - Avatar of the other user
  /// [docId] - Chat document ID
  Future<void> cancelCall({
    required String recipientToken,
    required String recipientName,
    required String recipientAvatar,
    required String docId,
  }) async {
    try {
      logDebug('Canceling call to: $recipientName');

      await sendCallNotification(
        callType: "cancel",
        recipientToken: recipientToken,
        recipientName: recipientName,
        recipientAvatar: recipientAvatar,
        docId: docId,
      );

      logSuccess('Call canceled');
    } catch (e, stack) {
      logError('Failed to cancel call', e, stack);
      if (e is CallException) rethrow;

      throw CallLeaveException(
        message: 'Failed to cancel call',
        originalError: e,
        stackTrace: stack,
        context: {
          'recipientToken': recipientToken,
        },
      );
    }
  }

  // ============ CALL HISTORY QUERIES ============

  /// Get call history for the current user
  /// [limit] - Maximum number of calls to retrieve
  Future<List<ChatCall>> getCallHistory({int limit = 50}) async {
    try {
      logDebug('Loading call history (limit: $limit)');

      final snapshot = await _db
          .collection("chatcall")
          .where("from_token", isEqualTo: _myToken)
          .orderBy("last_time", descending: true)
          .limit(limit)
          .withConverter(
            fromFirestore: ChatCall.fromFirestore,
            toFirestore: (ChatCall msg, options) => msg.toFirestore(),
          )
          .get();

      final calls = snapshot.docs.map((doc) => doc.data()).toList();

      // Also get calls where I'm the recipient
      final incomingSnapshot = await _db
          .collection("chatcall")
          .where("to_token", isEqualTo: _myToken)
          .orderBy("last_time", descending: true)
          .limit(limit)
          .withConverter(
            fromFirestore: ChatCall.fromFirestore,
            toFirestore: (ChatCall msg, options) => msg.toFirestore(),
          )
          .get();

      calls.addAll(incomingSnapshot.docs.map((doc) => doc.data()));

      // Sort by last_time
      calls.sort((a, b) {
        if (a.last_time == null && b.last_time == null) return 0;
        if (a.last_time == null) return 1;
        if (b.last_time == null) return -1;
        return b.last_time!.compareTo(a.last_time!);
      });

      logSuccess('Loaded ${calls.length} call history entries');
      return calls.take(limit).toList();
    } catch (e, stack) {
      logError('Failed to load call history', e, stack);
      throw CallHistoryException(
        message: 'Failed to load call history',
        originalError: e,
        stackTrace: stack,
      );
    }
  }
}

/// Result of call token generation
class CallTokenResult {
  final String token;
  final String channelId;

  CallTokenResult({
    required this.token,
    required this.channelId,
  });
}
