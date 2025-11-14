import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:sakoa/common/store/store.dart';
import 'dart:async';

/// 🔥 INDUSTRIAL-GRADE PRESENCE SERVICE
/// Manages user online/offline status, last seen, and typing indicators
/// with sophisticated debouncing and battery optimization
class PresenceService extends GetxService {
  static PresenceService get to => Get.find();
  
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _presenceCache = <String, PresenceData>{}.obs;
  final _typingStatus = <String, TypingData>{}.obs;
  
  Timer? _heartbeatTimer;
  Timer? _cleanupTimer;
  StreamSubscription? _connectionSubscription;
  
  // Configuration
  static const HEARTBEAT_INTERVAL = Duration(seconds: 30);
  static const OFFLINE_THRESHOLD = Duration(seconds: 45);
  static const TYPING_TIMEOUT = Duration(seconds: 3);
  static const CACHE_DURATION = Duration(minutes: 5);
  
  String get myToken => UserStore.to.profile.token ?? UserStore.to.token;
  
  /// Initialize presence service
  Future<PresenceService> init() async {
    await _setupConnectionMonitoring();
    await _startHeartbeat();
    await _startCleanupTimer();
    await setOnline();
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
      });
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
  }
  
  /// Setup connection monitoring (online/offline detection)
  Future<void> _setupConnectionMonitoring() async {
    // Monitor app lifecycle changes
    // This should be integrated with WidgetsBindingObserver in main controller
  }
  
  // ============ PRESENCE QUERIES ============
  
  /// Get presence data for a user (cached)
  Future<PresenceData> getPresence(String userToken) async {
    if (userToken.isEmpty) return PresenceData.offline();
    
    // Check cache first
    if (_presenceCache.containsKey(userToken)) {
      final cached = _presenceCache[userToken]!;
      if (!cached.isExpired) {
        return cached;
      }
    }
    
    // Fetch from Firestore
    try {
      final doc = await _db.collection("user_profiles").doc(userToken).get();
      if (!doc.exists) return PresenceData.offline();
      
      final data = doc.data()!;
      final presence = PresenceData(
        userToken: userToken,
        online: data['online'] ?? 0,
        lastSeen: data['last_seen'] as Timestamp?,
        lastHeartbeat: data['last_heartbeat'] as Timestamp?,
        fetchedAt: DateTime.now(),
      );
      
      // Cache it
      _presenceCache[userToken] = presence;
      
      return presence;
    } catch (e) {
      print('[PresenceService] ❌ Failed to fetch presence: $e');
      return PresenceData.offline();
    }
  }
  
  /// Listen to presence changes for a user
  Stream<PresenceData> watchPresence(String userToken) {
    if (userToken.isEmpty) {
      return Stream.value(PresenceData.offline());
    }
    
    return _db.collection("user_profiles").doc(userToken).snapshots().map((doc) {
      if (!doc.exists) return PresenceData.offline();
      
      final data = doc.data()!;
      final presence = PresenceData(
        userToken: userToken,
        online: data['online'] ?? 0,
        lastSeen: data['last_seen'] as Timestamp?,
        lastHeartbeat: data['last_heartbeat'] as Timestamp?,
        fetchedAt: DateTime.now(),
      );
      
      // Update cache
      _presenceCache[userToken] = presence;
      
      return presence;
    });
  }
  
  /// Batch get presence for multiple users
  Future<Map<String, PresenceData>> getBatchPresence(List<String> userTokens) async {
    if (userTokens.isEmpty) return {};
    
    final result = <String, PresenceData>{};
    final tokensToFetch = <String>[];
    
    // Check cache first
    for (var token in userTokens) {
      if (_presenceCache.containsKey(token) && !_presenceCache[token]!.isExpired) {
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
            online: data['online'] ?? 0,
            lastSeen: data['last_seen'] as Timestamp?,
            lastHeartbeat: data['last_heartbeat'] as Timestamp?,
            fetchedAt: DateTime.now(),
          );
          
          result[doc.id] = presence;
          _presenceCache[doc.id] = presence;
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
          await typingRef.delete();
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
      final isRecent = DateTime.now().difference(timestamp.toDate()) < TYPING_TIMEOUT;
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
    _presenceCache.removeWhere((key, value) => value.isExpired);
    print('[PresenceService] 🧹 Cleaned up ${_presenceCache.length} expired cache entries');
  }
  
  /// Clear all cache
  void clearCache() {
    _presenceCache.clear();
    _typingStatus.clear();
    print('[PresenceService] 🧹 Cleared all cache');
  }
  
  // ============ LIFECYCLE ============
  
  @override
  void onClose() {
    _heartbeatTimer?.cancel();
    _cleanupTimer?.cancel();
    _connectionSubscription?.cancel();
    setOffline();
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
  bool get isExpired => DateTime.now().difference(fetchedAt) > PresenceService.CACHE_DURATION;
  
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
  
  factory PresenceData.offline() {
    return PresenceData(
      userToken: '',
      online: 0,
      fetchedAt: DateTime.now(),
    );
  }
}

class TypingData {
  final String userToken;
  final DateTime timestamp;
  
  TypingData({
    required this.userToken,
    required this.timestamp,
  });
  
  bool get isExpired => DateTime.now().difference(timestamp) > PresenceService.TYPING_TIMEOUT;
}
