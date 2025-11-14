import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:sakoa/common/store/store.dart';
import 'dart:async';

/// 🔥 INDUSTRIAL-GRADE PRESENCE SERVICE
/// Manages user online/offline status, last seen, and typing indicators
/// with sophisticated debouncing and battery optimization
class PresenceService extends GetxService {
  static PresenceService get to => Get.find();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _presenceCache = <String, PresenceData>{}.obs;
  final _storage = GetStorage('presence_cache');

  Timer? _heartbeatTimer;
  Timer? _cleanupTimer;

  // Configuration
  static const HEARTBEAT_INTERVAL = Duration(seconds: 30);
  static const OFFLINE_THRESHOLD = Duration(seconds: 45);
  static const TYPING_TIMEOUT = Duration(seconds: 3);
  static const CACHE_DURATION = Duration(minutes: 5);

  String get myToken => UserStore.to.profile.token ?? UserStore.to.token;

  /// Initialize presence service
  Future<PresenceService> init() async {
    await GetStorage.init('presence_cache');
    _startHeartbeat();
    _startCleanupTimer();
    await setOnline();
    print('[PresenceService] ✅ Initialized with heartbeat system');
    return this;
  }

  // ============ ONLINE/OFFLINE STATUS ============

  /// Set current user as online
  Future<void> setOnline() async {
    if (myToken.isEmpty) return;

    try {
      await _db.collection("user_profiles").doc(myToken).update({
        'online': 1,
        'last_seen': FieldValue.serverTimestamp(),
        'last_heartbeat': FieldValue.serverTimestamp(),
      });

      print('[PresenceService] ✅ Set online');
    } catch (e) {
      print('[PresenceService] ❌ Failed to set online: $e');
    }
  }

  /// Set current user as offline
  Future<void> setOffline() async {
    if (myToken.isEmpty) return;

    try {
      await _db.collection("user_profiles").doc(myToken).update({
        'online': 0,
        'last_seen': FieldValue.serverTimestamp(),
      });

      print('[PresenceService] ✅ Set offline');
    } catch (e) {
      print('[PresenceService] ❌ Failed to set offline: $e');
    }
  }

  /// Send heartbeat to maintain online status
  Future<void> _sendHeartbeat() async {
    if (myToken.isEmpty) return;

    try {
      await _db.collection("user_profiles").doc(myToken).update({
        'last_heartbeat': FieldValue.serverTimestamp(),
        'online': 1, // Ensure online during heartbeat
      });
      // print('[PresenceService] 💓 Heartbeat sent');
    } catch (e) {
      print('[PresenceService] ⚠️ Heartbeat failed: $e');
    }
  }

  /// Start periodic heartbeat
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(HEARTBEAT_INTERVAL, (_) async {
      await _sendHeartbeat();
    });
    print(
        '[PresenceService] 💓 Started heartbeat (every ${HEARTBEAT_INTERVAL.inSeconds}s)');
  }

  // ============ PRESENCE QUERIES ============

  /// Get presence data for a user (cached)
  Future<PresenceData> getPresence(String userToken) async {
    if (userToken.isEmpty) return PresenceData.offline();

    // Check memory cache first
    if (_presenceCache.containsKey(userToken)) {
      final cached = _presenceCache[userToken]!;
      if (!cached.isExpired) {
        return cached;
      }
    }

    // Check storage cache
    try {
      final stored = _storage.read('presence_$userToken');
      if (stored != null) {
        final presence =
            PresenceData.fromJson(Map<String, dynamic>.from(stored));
        if (!presence.isExpired) {
          _presenceCache[userToken] = presence;
          return presence;
        }
      }
    } catch (e) {
      // Cache read failed, continue to Firestore
    }

    // Fetch from Firestore
    try {
      final doc = await _db.collection("user_profiles").doc(userToken).get();
      if (!doc.exists) return PresenceData.offline();

      final data = doc.data()!;
      final presence = PresenceData(
        userToken: userToken,
        online: _normalizeOnlineStatus(data['online']),
        lastSeen: data['last_seen'] as Timestamp?,
        lastHeartbeat: data['last_heartbeat'] as Timestamp?,
        fetchedAt: DateTime.now(),
      );

      // Cache it
      _presenceCache[userToken] = presence;
      _storage.write('presence_$userToken', presence.toJson());

      return presence;
    } catch (e) {
      print('[PresenceService] ❌ Failed to fetch presence: $e');
      return PresenceData.offline();
    }
  }

  /// Listen to presence changes for a user (real-time)
  Stream<PresenceData> watchPresence(String userToken) {
    if (userToken.isEmpty) {
      return Stream.value(PresenceData.offline());
    }

    return _db
        .collection("user_profiles")
        .doc(userToken)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return PresenceData.offline();

      final data = doc.data()!;
      final presence = PresenceData(
        userToken: userToken,
        online: _normalizeOnlineStatus(data['online']),
        lastSeen: data['last_seen'] as Timestamp?,
        lastHeartbeat: data['last_heartbeat'] as Timestamp?,
        fetchedAt: DateTime.now(),
      );

      // Update cache
      _presenceCache[userToken] = presence;
      _storage.write('presence_$userToken', presence.toJson());

      return presence;
    });
  }

  /// Batch get presence for multiple users (optimized)
  Future<Map<String, PresenceData>> getBatchPresence(
      List<String> userTokens) async {
    if (userTokens.isEmpty) return {};

    final result = <String, PresenceData>{};
    final tokensToFetch = <String>[];

    // Check cache first
    for (var token in userTokens) {
      if (_presenceCache.containsKey(token) &&
          !_presenceCache[token]!.isExpired) {
        result[token] = _presenceCache[token]!;
      } else {
        tokensToFetch.add(token);
      }
    }

    // Fetch missing ones in batches of 10 (Firestore limit)
    for (int i = 0; i < tokensToFetch.length; i += 10) {
      final batch = tokensToFetch.skip(i).take(10).toList();

      try {
        final docs = await _db
            .collection("user_profiles")
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        for (var doc in docs.docs) {
          if (!doc.exists) continue;

          final data = doc.data();
          final presence = PresenceData(
            userToken: doc.id,
            online: _normalizeOnlineStatus(data['online']),
            lastSeen: data['last_seen'] as Timestamp?,
            lastHeartbeat: data['last_heartbeat'] as Timestamp?,
            fetchedAt: DateTime.now(),
          );

          result[doc.id] = presence;
          _presenceCache[doc.id] = presence;
          _storage.write('presence_${doc.id}', presence.toJson());
        }
      } catch (e) {
        print('[PresenceService] ❌ Batch fetch failed: $e');
      }
    }

    return result;
  }

  // ============ TYPING INDICATORS ============

  /// Set typing status for a chat
  Future<void> setTyping(String chatDocId, bool isTyping) async {
    if (myToken.isEmpty || chatDocId.isEmpty) return;

    try {
      final typingRef = _db
          .collection("message")
          .doc(chatDocId)
          .collection("typing")
          .doc(myToken);

      if (isTyping) {
        await typingRef.set({
          'user_token': myToken,
          'is_typing': true,
          'timestamp': FieldValue.serverTimestamp(),
        });

        // Auto-clear after timeout
        Future.delayed(TYPING_TIMEOUT, () async {
          try {
            await typingRef.delete();
          } catch (e) {
            // Ignore cleanup errors
          }
        });
      } else {
        await typingRef.delete();
      }
    } catch (e) {
      print('[PresenceService] ❌ Failed to set typing: $e');
    }
  }

  /// Listen to typing status in a chat
  Stream<bool> watchTyping(String chatDocId, String otherUserToken) {
    if (chatDocId.isEmpty || otherUserToken.isEmpty) {
      return Stream.value(false);
    }

    return _db
        .collection("message")
        .doc(chatDocId)
        .collection("typing")
        .doc(otherUserToken)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return false;

      final data = doc.data()!;
      final timestamp = data['timestamp'] as Timestamp?;

      if (timestamp == null) return false;

      // Check if typing is recent (within timeout)
      final isRecent =
          DateTime.now().difference(timestamp.toDate()) < TYPING_TIMEOUT;
      return data['is_typing'] == true && isRecent;
    });
  }

  // ============ CLEANUP & OPTIMIZATION ============

  /// Start cleanup timer to remove expired cache
  void _startCleanupTimer() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(Duration(minutes: 1), (_) {
      _cleanupExpiredCache();
    });
  }

  /// Remove expired entries from cache
  void _cleanupExpiredCache() {
    final beforeCount = _presenceCache.length;
    _presenceCache.removeWhere((key, value) => value.isExpired);
    final removed = beforeCount - _presenceCache.length;
    if (removed > 0) {
      print('[PresenceService] 🧹 Cleaned up $removed expired cache entries');
    }
  }

  /// Clear all cache
  void clearCache() {
    _presenceCache.clear();
    _storage.erase();
    print('[PresenceService] 🧹 Cleared all cache');
  }

  // ============ HELPERS ============

  int _normalizeOnlineStatus(dynamic online) {
    if (online is bool) return online ? 1 : 0;
    if (online is int) return online;
    return 0;
  }

  // ============ LIFECYCLE ============

  @override
  void onClose() {
    _heartbeatTimer?.cancel();
    _cleanupTimer?.cancel();
    setOffline();
    print('[PresenceService] 🛑 Stopped heartbeat and set offline');
    super.onClose();
  }
}

// ============ DATA MODELS ============

class PresenceData {
  final String userToken;
  final int online;
  final Timestamp? lastSeen;
  final Timestamp? lastHeartbeat;
  final DateTime fetchedAt;

  PresenceData({
    required this.userToken,
    required this.online,
    this.lastSeen,
    this.lastHeartbeat,
    required this.fetchedAt,
  });

  bool get isOnline => online == 1;
  bool get isExpired =>
      DateTime.now().difference(fetchedAt) > PresenceService.CACHE_DURATION;

  String get lastSeenText {
    if (isOnline) return 'Online';
    if (lastSeen == null) return 'Offline';

    final lastSeenDate = lastSeen!.toDate();
    final now = DateTime.now();
    final diff = now.difference(lastSeenDate);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    return 'Long ago';
  }

  Map<String, dynamic> toJson() {
    return {
      'userToken': userToken,
      'online': online,
      'lastSeen': lastSeen?.millisecondsSinceEpoch,
      'lastHeartbeat': lastHeartbeat?.millisecondsSinceEpoch,
      'fetchedAt': fetchedAt.toIso8601String(),
    };
  }

  factory PresenceData.fromJson(Map<String, dynamic> json) {
    return PresenceData(
      userToken: json['userToken'] ?? '',
      online: json['online'] ?? 0,
      lastSeen: json['lastSeen'] != null
          ? Timestamp.fromMillisecondsSinceEpoch(json['lastSeen'])
          : null,
      lastHeartbeat: json['lastHeartbeat'] != null
          ? Timestamp.fromMillisecondsSinceEpoch(json['lastHeartbeat'])
          : null,
      fetchedAt:
          DateTime.parse(json['fetchedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  factory PresenceData.offline() {
    return PresenceData(
      userToken: '',
      online: 0,
      fetchedAt: DateTime.now(),
    );
  }
}
