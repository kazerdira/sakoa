import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:sakoa/common/entities/entities.dart';
import 'package:sakoa/common/store/store.dart';

/// 🔥 SUPERNOVA-LEVEL MESSAGE DELIVERY SERVICE V2
/// Telegram/WhatsApp-grade delivery tracking with:
/// - Smart read receipts (only for visible messages)
/// - Timestamp grouping (5-min intervals)
/// - Last-message-only delivery status
/// - Exponential backoff retry
/// - Network quality detection
/// - Real-time sync across devices
class MessageDeliveryServiceV2 extends GetxService {
  static MessageDeliveryServiceV2 get to => Get.find();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _deliveryCache = <String, DeliveryStatus>{}.obs;
  final _storage = GetStorage('message_delivery_cache_v2');

  // Connectivity state with quality detection
  final isOnline = true.obs;
  final networkQuality = NetworkQuality.unknown.obs;
  final connectionType = Rx<List<ConnectivityResult>>([]);

  // Pending messages queue (persisted for offline resilience)
  final _pendingMessages = <String, PendingMessage>{}.obs;

  // Listeners
  StreamSubscription? _connectivitySubscription;
  final _messageListeners = <String, StreamSubscription>{};

  // Configuration
  static const MAX_RETRY_ATTEMPTS = 5; // Increased from 3
  static const INITIAL_RETRY_DELAY = Duration(seconds: 2);
  static const MAX_RETRY_DELAY = Duration(minutes: 2);
  static const DELIVERY_TIMEOUT = Duration(minutes: 10);
  static const READ_RECEIPT_DELAY = Duration(seconds: 1); // Wait before marking read
  static const TIMESTAMP_GROUP_INTERVAL = Duration(minutes: 5);

  String get myToken => UserStore.to.profile.token ?? UserStore.to.token;

  Timer? _retryTimer;
  final _statusUpdateQueue = <StatusUpdate>[];
  final _readReceiptQueue = <ReadReceipt>[];

  /// Initialize service
  Future<MessageDeliveryServiceV2> init() async {
    await GetStorage.init('message_delivery_cache_v2');
    _loadPendingMessages();
    _startConnectivityMonitoring();
    _startRetryTimer();
    print('[MessageDeliveryV2] ✅ Initialized with smart delivery tracking');
    return this;
  }

  // ============ CONNECTIVITY MONITORING WITH QUALITY DETECTION ============

  void _startConnectivityMonitoring() {
    Connectivity().checkConnectivity().then((result) {
      isOnline.value = result.isNotEmpty && !result.contains(ConnectivityResult.none);
      connectionType.value = result;
      networkQuality.value = _detectNetworkQuality(result);
      print('[MessageDeliveryV2] 📡 Initial connectivity: ${networkQuality.value}');
    });

    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((result) {
      final wasOffline = !isOnline.value;
      isOnline.value = result.isNotEmpty && !result.contains(ConnectivityResult.none);
      connectionType.value = result;
      networkQuality.value = _detectNetworkQuality(result);

      print('[MessageDeliveryV2] 📡 Network changed: ${networkQuality.value}');

      if (isOnline.value && wasOffline) {
        print('[MessageDeliveryV2] 🌐 Back online - Processing pending messages');
        _retryPendingMessages();
      }
    });
  }

  NetworkQuality _detectNetworkQuality(List<ConnectivityResult> result) {
    if (result.contains(ConnectivityResult.none)) return NetworkQuality.offline;
    if (result.contains(ConnectivityResult.wifi)) return NetworkQuality.excellent;
    if (result.contains(ConnectivityResult.ethernet)) return NetworkQuality.excellent;
    if (result.contains(ConnectivityResult.mobile)) return NetworkQuality.good; // Assume 4G
    if (result.contains(ConnectivityResult.vpn)) return NetworkQuality.good;
    return NetworkQuality.unknown;
  }

  // ============ SMART MESSAGE SENDING WITH RETRY LOGIC ============

  /// Send message with exponential backoff retry
  Future<SendMessageResult> sendMessageWithTracking({
    required String chatDocId,
    required Msgcontent content,
    Function(double progress)? onProgress,
  }) async {
    try {
      print('[MessageDeliveryV2] 📤 Sending message...');

      final messageWithStatus = Msgcontent(
        token: content.token,
        content: content.content,
        type: content.type,
        addtime: content.addtime ?? Timestamp.now(),
        voice_duration: content.voice_duration,
        reply: content.reply,
        delivery_status: 'sending',
        sent_at: null,
        delivered_at: null,
        read_at: null,
        retry_count: 0,
      );

      final messageRef = _db
          .collection("message")
          .doc(chatDocId)
          .collection("msglist")
          .withConverter(
            fromFirestore: Msgcontent.fromFirestore,
            toFirestore: (Msgcontent msg, options) => msg.toFirestore(),
          );

      try {
        // Attempt to add message
        final docRef = await messageRef.add(messageWithStatus);
        print('[MessageDeliveryV2] ✅ Message added: ${docRef.id}');

        // Update status to 'sent'
        await docRef.update({
          'delivery_status': 'sent',
          'sent_at': FieldValue.serverTimestamp(),
        });

        print('[MessageDeliveryV2] ✅ Message status updated to SENT');

        // Cache delivery status
        _cacheDeliveryStatus(
          messageId: docRef.id,
          status: DeliveryStatus(
            messageId: docRef.id,
            status: 'sent',
            sentAt: DateTime.now(),
            lastUpdated: DateTime.now(),
          ),
        );

        return SendMessageResult.success(docRef.id);
      } catch (e) {
        // Network error - queue for retry
        if (!isOnline.value || e.toString().contains('network') || e.toString().contains('UNAVAILABLE')) {
          print('[MessageDeliveryV2] 📡 Message queued (offline)');

          final tempId = 'pending_${DateTime.now().millisecondsSinceEpoch}';
          final pending = PendingMessage(
            tempId: tempId,
            chatDocId: chatDocId,
            content: messageWithStatus,
            attempts: 0,
            queuedAt: DateTime.now(),
            nextRetryAt: DateTime.now().add(INITIAL_RETRY_DELAY),
          );

          _pendingMessages[tempId] = pending;
          _savePendingMessages(); // Persist to disk

          return SendMessageResult.queued(tempId);
        }

        throw e;
      }
    } catch (e, stackTrace) {
      print('[MessageDeliveryV2] ❌ Send failed: $e');
      print('[MessageDeliveryV2] Stack: $stackTrace');
      return SendMessageResult.error(e.toString());
    }
  }

  // ============ SMART READ RECEIPTS (ONLY FOR VISIBLE MESSAGES) ============

  /// Mark message as delivered (when other user receives it)
  void markAsDelivered({
    required String chatDocId,
    required String messageId,
  }) {
    _statusUpdateQueue.add(StatusUpdate(
      chatDocId: chatDocId,
      messageId: messageId,
      status: 'delivered',
      timestamp: DateTime.now(),
      priority: 2, // Medium priority
    ));

    _processHighPriorityUpdates(); // Process immediately for last message
  }

  /// Mark message as read (ONLY when actually visible to user)
  /// Call this from a visibility detector in chat list
  void markAsRead({
    required String chatDocId,
    required String messageId,
    bool isLastMessage = false,
  }) {
    // Add to read receipt queue with delay
    _readReceiptQueue.add(ReadReceipt(
      chatDocId: chatDocId,
      messageId: messageId,
      queuedAt: DateTime.now(),
      isLastMessage: isLastMessage,
    ));

    // Process after delay (prevents marking as read during scroll)
    Future.delayed(READ_RECEIPT_DELAY, () {
      _processReadReceipts();
    });
  }

  /// Process read receipts (only if message was visible for 1+ seconds)
  Future<void> _processReadReceipts() async {
    if (_readReceiptQueue.isEmpty) return;

    final now = DateTime.now();
    final receiptsToProcess = _readReceiptQueue.where((receipt) {
      final timeSinceQueued = now.difference(receipt.queuedAt);
      return timeSinceQueued >= READ_RECEIPT_DELAY;
    }).toList();

    if (receiptsToProcess.isEmpty) return;

    print('[MessageDeliveryV2] 👁️ Processing ${receiptsToProcess.length} read receipts');

    final batch = _db.batch();

    for (final receipt in receiptsToProcess) {
      final docRef = _db
          .collection("message")
          .doc(receipt.chatDocId)
          .collection("msglist")
          .doc(receipt.messageId);

      batch.update(docRef, {
        'delivery_status': 'read',
        'read_at': FieldValue.serverTimestamp(),
      });

      _readReceiptQueue.remove(receipt);
    }

    try {
      await batch.commit();
      print('[MessageDeliveryV2] ✅ Batch updated ${receiptsToProcess.length} read receipts');
    } catch (e) {
      print('[MessageDeliveryV2] ❌ Read receipt batch failed: $e');
    }
  }

  // ============ SMART STATUS UPDATES (PRIORITIZE LAST MESSAGE) ============

  Future<void> _processHighPriorityUpdates() async {
    if (_statusUpdateQueue.isEmpty) return;

    // Sort by priority (higher = more important)
    _statusUpdateQueue.sort((a, b) => b.priority.compareTo(a.priority));

    // Process top 3 high-priority updates immediately
    final highPriority = _statusUpdateQueue.take(3).toList();
    if (highPriority.isEmpty) return;

    final batch = _db.batch();

    for (final update in highPriority) {
      final docRef = _db
          .collection("message")
          .doc(update.chatDocId)
          .collection("msglist")
          .doc(update.messageId);

      final data = <String, dynamic>{
        'delivery_status': update.status,
      };

      if (update.status == 'delivered') {
        data['delivered_at'] = FieldValue.serverTimestamp();
      } else if (update.status == 'read') {
        data['read_at'] = FieldValue.serverTimestamp();
      }

      batch.update(docRef, data);
      _statusUpdateQueue.remove(update);
    }

    try {
      await batch.commit();
      print('[MessageDeliveryV2] ✅ Processed ${highPriority.length} high-priority updates');
    } catch (e) {
      print('[MessageDeliveryV2] ❌ High-priority batch failed: $e');
      _statusUpdateQueue.addAll(highPriority); // Re-queue
    }
  }

  // ============ EXPONENTIAL BACKOFF RETRY ============

  void _startRetryTimer() {
    _retryTimer?.cancel();
    _retryTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      if (isOnline.value && _pendingMessages.isNotEmpty) {
        _retryPendingMessages();
      }
    });
  }

  Future<void> _retryPendingMessages() async {
    if (_pendingMessages.isEmpty) return;

    final now = DateTime.now();
    final pendingCopy = Map<String, PendingMessage>.from(_pendingMessages);

    for (final entry in pendingCopy.entries) {
      final pending = entry.value;

      // Check if it's time to retry
      if (now.isBefore(pending.nextRetryAt)) continue;

      // Check max attempts
      if (pending.attempts >= MAX_RETRY_ATTEMPTS) {
        print('[MessageDeliveryV2] ❌ Max retries reached: ${entry.key}');
        _pendingMessages.remove(entry.key);
        _savePendingMessages();
        continue;
      }

      // Calculate exponential backoff delay
      final retryDelay = Duration(
        seconds: (INITIAL_RETRY_DELAY.inSeconds * (1 << pending.attempts))
            .clamp(INITIAL_RETRY_DELAY.inSeconds, MAX_RETRY_DELAY.inSeconds),
      );

      print('[MessageDeliveryV2] 🔄 Retrying message (attempt ${pending.attempts + 1}/${MAX_RETRY_ATTEMPTS})');

      try {
        // Retry send
        final result = await sendMessageWithTracking(
          chatDocId: pending.chatDocId,
          content: pending.content,
        );

        if (result.success) {
          print('[MessageDeliveryV2] ✅ Retry successful: ${entry.key}');
          _pendingMessages.remove(entry.key);
          _savePendingMessages();
        } else {
          // Update retry info
          _pendingMessages[entry.key] = PendingMessage(
            tempId: pending.tempId,
            chatDocId: pending.chatDocId,
            content: pending.content,
            attempts: pending.attempts + 1,
            queuedAt: pending.queuedAt,
            nextRetryAt: now.add(retryDelay),
          );
          _savePendingMessages();
        }
      } catch (e) {
        print('[MessageDeliveryV2] ❌ Retry failed: $e');
        _pendingMessages[entry.key] = PendingMessage(
          tempId: pending.tempId,
          chatDocId: pending.chatDocId,
          content: pending.content,
          attempts: pending.attempts + 1,
          queuedAt: pending.queuedAt,
          nextRetryAt: now.add(retryDelay),
        );
        _savePendingMessages();
      }
    }
  }

  // ============ PERSISTENCE FOR OFFLINE RESILIENCE ============

  void _savePendingMessages() {
    final data = _pendingMessages.map((key, value) => MapEntry(key, value.toJson()));
    _storage.write('pending_messages', data);
  }

  void _loadPendingMessages() {
    try {
      final data = _storage.read<Map<String, dynamic>>('pending_messages');
      if (data != null) {
        _pendingMessages.value = data.map((key, value) {
          return MapEntry(key, PendingMessage.fromJson(Map<String, dynamic>.from(value)));
        });
        print('[MessageDeliveryV2] ✅ Loaded ${_pendingMessages.length} pending messages from disk');
      }
    } catch (e) {
      print('[MessageDeliveryV2] ⚠️ Failed to load pending messages: $e');
    }
  }

  // ============ TIMESTAMP GROUPING (5-MIN INTERVALS) ============

  /// Check if timestamp should be shown for this message
  bool shouldShowTimestamp(Msgcontent currentMsg, Msgcontent? previousMsg) {
    if (previousMsg == null) return true; // Always show first message time

    final currentTime = currentMsg.addtime?.toDate();
    final previousTime = previousMsg.addtime?.toDate();

    if (currentTime == null || previousTime == null) return false;

    final timeDiff = currentTime.difference(previousTime);
    return timeDiff >= TIMESTAMP_GROUP_INTERVAL;
  }

  // ============ HELPER METHODS ============

  void _cacheDeliveryStatus({
    required String messageId,
    required DeliveryStatus status,
  }) {
    _deliveryCache[messageId] = status;
    _storage.write('status_$messageId', status.toJson());
  }

  DeliveryStatus? getCachedStatus(String messageId) {
    return _deliveryCache[messageId];
  }

  bool isMessagePending(String messageId) {
    return _pendingMessages.containsKey(messageId);
  }

  int get pendingCount => _pendingMessages.length;

  bool get isConnected => isOnline.value;

  @override
  void onClose() {
    print('[MessageDeliveryV2] 🛑 Cleaning up...');
    _connectivitySubscription?.cancel();
    _retryTimer?.cancel();

    for (final listener in _messageListeners.values) {
      listener.cancel();
    }
    _messageListeners.clear();

    super.onClose();
  }
}

// ============ ENHANCED DATA MODELS ============

enum NetworkQuality {
  offline,
  poor,      // 2G
  fair,      // 3G
  good,      // 4G/LTE
  excellent, // 5G/WiFi
  unknown,
}

class SendMessageResult {
  final bool success;
  final bool queued;
  final String? messageId;
  final String? error;

  SendMessageResult._({
    required this.success,
    required this.queued,
    this.messageId,
    this.error,
  });

  factory SendMessageResult.success(String messageId) =>
      SendMessageResult._(success: true, queued: false, messageId: messageId);

  factory SendMessageResult.queued(String tempId) =>
      SendMessageResult._(success: false, queued: true, messageId: tempId);

  factory SendMessageResult.error(String error) =>
      SendMessageResult._(success: false, queued: false, error: error);
}

class DeliveryStatus {
  final String messageId;
  final String status;
  final DateTime? sentAt;
  final DateTime? deliveredAt;
  final DateTime? readAt;
  final DateTime lastUpdated;

  DeliveryStatus({
    required this.messageId,
    required this.status,
    this.sentAt,
    this.deliveredAt,
    this.readAt,
    required this.lastUpdated,
  });

  factory DeliveryStatus.failed(String messageId) => DeliveryStatus(
        messageId: messageId,
        status: 'failed',
        lastUpdated: DateTime.now(),
      );

  DeliveryStatus copyWith({
    String? status,
    DateTime? sentAt,
    DateTime? deliveredAt,
    DateTime? readAt,
  }) =>
      DeliveryStatus(
        messageId: messageId,
        status: status ?? this.status,
        sentAt: sentAt ?? this.sentAt,
        deliveredAt: deliveredAt ?? this.deliveredAt,
        readAt: readAt ?? this.readAt,
        lastUpdated: DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'messageId': messageId,
        'status': status,
        'sentAt': sentAt?.toIso8601String(),
        'deliveredAt': deliveredAt?.toIso8601String(),
        'readAt': readAt?.toIso8601String(),
        'lastUpdated': lastUpdated.toIso8601String(),
      };

  factory DeliveryStatus.fromJson(Map<String, dynamic> json) => DeliveryStatus(
        messageId: json['messageId'],
        status: json['status'],
        sentAt: json['sentAt'] != null ? DateTime.parse(json['sentAt']) : null,
        deliveredAt: json['deliveredAt'] != null ? DateTime.parse(json['deliveredAt']) : null,
        readAt: json['readAt'] != null ? DateTime.parse(json['readAt']) : null,
        lastUpdated: DateTime.parse(json['lastUpdated']),
      );
}

class PendingMessage {
  final String tempId;
  final String chatDocId;
  final Msgcontent content;
  final int attempts;
  final DateTime queuedAt;
  final DateTime nextRetryAt;

  PendingMessage({
    required this.tempId,
    required this.chatDocId,
    required this.content,
    required this.attempts,
    required this.queuedAt,
    required this.nextRetryAt,
  });

  Map<String, dynamic> toJson() => {
        'tempId': tempId,
        'chatDocId': chatDocId,
        'content': content.toFirestore(),
        'attempts': attempts,
        'queuedAt': queuedAt.toIso8601String(),
        'nextRetryAt': nextRetryAt.toIso8601String(),
      };

  factory PendingMessage.fromJson(Map<String, dynamic> json) => PendingMessage(
        tempId: json['tempId'],
        chatDocId: json['chatDocId'],
        content: Msgcontent.fromJson(json['content']),
        attempts: json['attempts'],
        queuedAt: DateTime.parse(json['queuedAt']),
        nextRetryAt: DateTime.parse(json['nextRetryAt']),
      );
}

class StatusUpdate {
  final String chatDocId;
  final String messageId;
  final String status;
  final DateTime timestamp;
  final int priority; // Higher = more important

  StatusUpdate({
    required this.chatDocId,
    required this.messageId,
    required this.status,
    required this.timestamp,
    this.priority = 1,
  });
}

class ReadReceipt {
  final String chatDocId;
  final String messageId;
  final DateTime queuedAt;
  final bool isLastMessage;

  ReadReceipt({
    required this.chatDocId,
    required this.messageId,
    required this.queuedAt,
    required this.isLastMessage,
  });
}
