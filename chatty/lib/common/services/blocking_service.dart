import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:sakoa/common/store/store.dart';
import 'dart:async';

/// 🔥 SUPERNOVA-LEVEL BLOCKING SERVICE
/// Advanced blocking system with granular privacy controls
/// Features:
/// - Real-time block status monitoring
/// - Granular privacy restrictions (screenshots, copy, download)
/// - Bi-directional blocking
/// - Block reason tracking
/// - Automatic chat disabling
/// - Block analytics
class BlockingService extends GetxService {
  static BlockingService get to => Get.find();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _blockCache = <String, BlockStatus>{}.obs;
  final _restrictionCache = <String, BlockRestrictions>{}.obs;

  String get myToken => UserStore.to.profile.token ?? UserStore.to.token;

  // Real-time listeners
  StreamSubscription? _blockListener;

  /// Initialize blocking service
  Future<BlockingService> init() async {
    await _loadBlockedUsers();
    _startBlockListener();
    print('[BlockingService] ✅ Initialized with real-time monitoring');
    return this;
  }

  // ============ BLOCK STATUS CHECKS ============

  /// Check if a user is blocked (either direction)
  Future<BlockStatus> getBlockStatus(String otherUserToken) async {
    if (otherUserToken.isEmpty || myToken.isEmpty) {
      return BlockStatus.notBlocked();
    }

    // Check cache first
    if (_blockCache.containsKey(otherUserToken)) {
      return _blockCache[otherUserToken]!;
    }

    // Check Firestore
    final status = await _fetchBlockStatus(otherUserToken);
    _blockCache[otherUserToken] = status;
    return status;
  }

  /// Check if user is blocked (cached - fast)
  bool isBlockedCached(String otherUserToken) {
    if (_blockCache.containsKey(otherUserToken)) {
      final status = _blockCache[otherUserToken]!;
      return status.iBlocked || status.theyBlocked;
    }
    return false;
  }

  /// Get block restrictions for a user
  Future<BlockRestrictions> getBlockRestrictions(String otherUserToken) async {
    if (_restrictionCache.containsKey(otherUserToken)) {
      return _restrictionCache[otherUserToken]!;
    }

    final restrictions = await _fetchBlockRestrictions(otherUserToken);
    _restrictionCache[otherUserToken] = restrictions;
    return restrictions;
  }

  // ============ BLOCK MANAGEMENT ============

  /// Block a user with custom restrictions
  Future<bool> blockUser({
    required String userToken,
    required String userName,
    required String userAvatar,
    String? reason,
    BlockRestrictions? restrictions,
  }) async {
    try {
      print('[BlockingService] 🚫 Blocking user: $userName');

      // Default restrictions if not provided
      final blockRestrictions = restrictions ?? BlockRestrictions.strict();

      // 1. Create block document
      await _db.collection("blocks").add({
        'blocker_token': myToken,
        'blocked_token': userToken,
        'blocked_name': userName,
        'blocked_avatar': userAvatar,
        'reason': reason,
        'blocked_at': FieldValue.serverTimestamp(),
        'restrictions': blockRestrictions.toJson(),
      });

      // 2. Update contacts collection (mark as blocked)
      final contactQuery = await _db
          .collection("contacts")
          .where("user_token", isEqualTo: myToken)
          .where("contact_token", isEqualTo: userToken)
          .get();

      if (contactQuery.docs.isNotEmpty) {
        await _db
            .collection("contacts")
            .doc(contactQuery.docs.first.id)
            .update({
          'status': 'blocked',
          'blocked_at': FieldValue.serverTimestamp(),
        });
      } else {
        // Create blocked contact entry
        await _db.collection("contacts").add({
          'user_token': myToken,
          'contact_token': userToken,
          'contact_name': userName,
          'contact_avatar': userAvatar,
          'status': 'blocked',
          'blocked_at': FieldValue.serverTimestamp(),
        });
      }

      // 3. Delete their pending request to me (if exists)
      final theirRequests = await _db
          .collection("contacts")
          .where("user_token", isEqualTo: userToken)
          .where("contact_token", isEqualTo: myToken)
          .get();

      for (var doc in theirRequests.docs) {
        await doc.reference.delete();
      }

      // 4. Update cache
      _blockCache[userToken] = BlockStatus(
        iBlocked: true,
        theyBlocked: false,
        blockedAt: Timestamp.now(),
        restrictions: blockRestrictions,
      );

      _restrictionCache[userToken] = blockRestrictions;

      print('[BlockingService] ✅ User blocked successfully');
      return true;
    } catch (e) {
      print('[BlockingService] ❌ Failed to block user: $e');
      return false;
    }
  }

  /// Unblock a user
  Future<bool> unblockUser(String userToken) async {
    try {
      print('[BlockingService] 🔓 Unblocking user: $userToken');

      // 1. Delete block document
      final blockQuery = await _db
          .collection("blocks")
          .where("blocker_token", isEqualTo: myToken)
          .where("blocked_token", isEqualTo: userToken)
          .get();

      for (var doc in blockQuery.docs) {
        await doc.reference.delete();
      }

      // 2. Delete blocked contact entry
      final contactQuery = await _db
          .collection("contacts")
          .where("user_token", isEqualTo: myToken)
          .where("contact_token", isEqualTo: userToken)
          .where("status", isEqualTo: "blocked")
          .get();

      for (var doc in contactQuery.docs) {
        await doc.reference.delete();
      }

      // 3. Update cache
      _blockCache.remove(userToken);
      _restrictionCache.remove(userToken);

      print('[BlockingService] ✅ User unblocked successfully');
      return true;
    } catch (e) {
      print('[BlockingService] ❌ Failed to unblock user: $e');
      return false;
    }
  }

  /// Update block restrictions
  Future<bool> updateBlockRestrictions({
    required String userToken,
    required BlockRestrictions restrictions,
  }) async {
    try {
      final blockQuery = await _db
          .collection("blocks")
          .where("blocker_token", isEqualTo: myToken)
          .where("blocked_token", isEqualTo: userToken)
          .get();

      if (blockQuery.docs.isEmpty) {
        return false;
      }

      await blockQuery.docs.first.reference.update({
        'restrictions': restrictions.toJson(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      _restrictionCache[userToken] = restrictions;
      return true;
    } catch (e) {
      print('[BlockingService] ❌ Failed to update restrictions: $e');
      return false;
    }
  }

  // ============ REAL-TIME MONITORING ============

  /// Start listening to block changes
  void _startBlockListener() {
    _blockListener?.cancel();

    // Listen to blocks where I'm the blocker
    _blockListener = _db
        .collection("blocks")
        .where("blocker_token", isEqualTo: myToken)
        .snapshots()
        .listen((snapshot) {
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final blockedToken = data['blocked_token'] as String;
        final restrictionsData = data['restrictions'] as Map<String, dynamic>?;

        _blockCache[blockedToken] = BlockStatus(
          iBlocked: true,
          theyBlocked: false,
          blockedAt: data['blocked_at'] as Timestamp?,
          restrictions: restrictionsData != null
              ? BlockRestrictions.fromJson(restrictionsData)
              : BlockRestrictions.standard(),
        );
      }
    }, onError: (error) {
      print('[BlockingService] ❌ Block listener error: $error');
    });

    // Listen to blocks where I'm the blocked user
    _db
        .collection("blocks")
        .where("blocked_token", isEqualTo: myToken)
        .snapshots()
        .listen((snapshot) {
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final blockerToken = data['blocker_token'] as String;

        _blockCache[blockerToken] = BlockStatus(
          iBlocked: false,
          theyBlocked: true,
          blockedAt: data['blocked_at'] as Timestamp?,
        );
      }
    }, onError: (error) {
      print('[BlockingService] ❌ Blocked listener error: $error');
    });
  }

  /// Watch block status for a specific user (real-time) - BI-DIRECTIONAL! 🔥
  Stream<BlockStatus> watchBlockStatus(String otherUserToken) {
    // We need to monitor BOTH directions:
    // 1. Did I block them? (blocker_token == myToken, blocked_token == otherUserToken)
    // 2. Did they block me? (blocker_token == otherUserToken, blocked_token == myToken)

    // Create a stream controller to manually combine both streams
    final controller = StreamController<BlockStatus>();

    bool? iBlocked;
    bool? theyBlocked;
    Map<String, dynamic>? iBlockedData;

    void emitCombined() {
      if (iBlocked == null || theyBlocked == null) return;

      if (!iBlocked! && !theyBlocked!) {
        controller.add(BlockStatus.notBlocked());
        return;
      }

      BlockRestrictions? restrictions;
      Timestamp? blockedAt;

      if (iBlocked! && iBlockedData != null) {
        final restrictionsData =
            iBlockedData!['restrictions'] as Map<String, dynamic>?;
        restrictions = restrictionsData != null
            ? BlockRestrictions.fromJson(restrictionsData)
            : BlockRestrictions.standard();
        blockedAt = iBlockedData!['blocked_at'] as Timestamp?;
      } else if (theyBlocked!) {
        blockedAt = null; // We don't have access to their block data details
      }

      controller.add(BlockStatus(
        iBlocked: iBlocked!,
        theyBlocked: theyBlocked!,
        blockedAt: blockedAt,
        restrictions: restrictions,
      ));
    }

    // Listen to "I blocked them" stream
    final sub1 = _db
        .collection("blocks")
        .where("blocker_token", isEqualTo: myToken)
        .where("blocked_token", isEqualTo: otherUserToken)
        .snapshots()
        .listen((snapshot) {
      iBlocked = snapshot.docs.isNotEmpty;
      if (iBlocked!) {
        iBlockedData = snapshot.docs.first.data();
      } else {
        iBlockedData = null;
      }
      emitCombined();
    });

    // Listen to "they blocked me" stream
    final sub2 = _db
        .collection("blocks")
        .where("blocker_token", isEqualTo: otherUserToken)
        .where("blocked_token", isEqualTo: myToken)
        .snapshots()
        .listen((snapshot) {
      theyBlocked = snapshot.docs.isNotEmpty;
      emitCombined();
    });

    // Clean up subscriptions when stream is cancelled
    controller.onCancel = () {
      sub1.cancel();
      sub2.cancel();
    };

    return controller.stream;
  }

  // ============ BATCH OPERATIONS ============

  /// Load all blocked users for current user
  Future<void> _loadBlockedUsers() async {
    try {
      // Load users I blocked
      final myBlocks = await _db
          .collection("blocks")
          .where("blocker_token", isEqualTo: myToken)
          .get();

      for (var doc in myBlocks.docs) {
        final data = doc.data();
        final blockedToken = data['blocked_token'] as String;
        final restrictionsData = data['restrictions'] as Map<String, dynamic>?;

        _blockCache[blockedToken] = BlockStatus(
          iBlocked: true,
          theyBlocked: false,
          blockedAt: data['blocked_at'] as Timestamp?,
          restrictions: restrictionsData != null
              ? BlockRestrictions.fromJson(restrictionsData)
              : BlockRestrictions.standard(),
        );
      }

      // Load users who blocked me
      final theirBlocks = await _db
          .collection("blocks")
          .where("blocked_token", isEqualTo: myToken)
          .get();

      for (var doc in theirBlocks.docs) {
        final data = doc.data();
        final blockerToken = data['blocker_token'] as String;

        _blockCache[blockerToken] = BlockStatus(
          iBlocked: false,
          theyBlocked: true,
          blockedAt: data['blocked_at'] as Timestamp?,
        );
      }

      print('[BlockingService] ✅ Loaded ${_blockCache.length} block statuses');
    } catch (e) {
      print('[BlockingService] ❌ Failed to load blocked users: $e');
    }
  }

  /// Get all blocked users
  Future<List<BlockedUser>> getBlockedUsers() async {
    try {
      final query = await _db
          .collection("blocks")
          .where("blocker_token", isEqualTo: myToken)
          .orderBy("blocked_at", descending: true)
          .get();

      return query.docs.map((doc) {
        final data = doc.data();
        return BlockedUser(
          docId: doc.id,
          blockedToken: data['blocked_token'],
          blockedName: data['blocked_name'],
          blockedAvatar: data['blocked_avatar'],
          reason: data['reason'],
          blockedAt: data['blocked_at'] as Timestamp?,
        );
      }).toList();
    } catch (e) {
      print('[BlockingService] ❌ Failed to get blocked users: $e');
      return [];
    }
  }

  // ============ PRIVATE HELPERS ============

  Future<BlockStatus> _fetchBlockStatus(String otherUserToken) async {
    try {
      // Check if I blocked them
      final iBlockedQuery = await _db
          .collection("blocks")
          .where("blocker_token", isEqualTo: myToken)
          .where("blocked_token", isEqualTo: otherUserToken)
          .limit(1)
          .get();

      if (iBlockedQuery.docs.isNotEmpty) {
        final data = iBlockedQuery.docs.first.data();
        final restrictionsData = data['restrictions'] as Map<String, dynamic>?;

        return BlockStatus(
          iBlocked: true,
          theyBlocked: false,
          blockedAt: data['blocked_at'] as Timestamp?,
          restrictions: restrictionsData != null
              ? BlockRestrictions.fromJson(restrictionsData)
              : BlockRestrictions.standard(),
        );
      }

      // Check if they blocked me
      final theyBlockedQuery = await _db
          .collection("blocks")
          .where("blocker_token", isEqualTo: otherUserToken)
          .where("blocked_token", isEqualTo: myToken)
          .limit(1)
          .get();

      if (theyBlockedQuery.docs.isNotEmpty) {
        final data = theyBlockedQuery.docs.first.data();
        return BlockStatus(
          iBlocked: false,
          theyBlocked: true,
          blockedAt: data['blocked_at'] as Timestamp?,
        );
      }

      return BlockStatus.notBlocked();
    } catch (e) {
      print('[BlockingService] ❌ Failed to fetch block status: $e');
      return BlockStatus.notBlocked();
    }
  }

  Future<BlockRestrictions> _fetchBlockRestrictions(
      String otherUserToken) async {
    try {
      final query = await _db
          .collection("blocks")
          .where("blocker_token", isEqualTo: myToken)
          .where("blocked_token", isEqualTo: otherUserToken)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        return BlockRestrictions.none();
      }

      final data = query.docs.first.data();
      final restrictionsData = data['restrictions'] as Map<String, dynamic>?;

      if (restrictionsData != null) {
        return BlockRestrictions.fromJson(restrictionsData);
      }

      return BlockRestrictions.standard();
    } catch (e) {
      print('[BlockingService] ❌ Failed to fetch restrictions: $e');
      return BlockRestrictions.none();
    }
  }

  // ============ ANALYTICS ============

  /// Get block statistics
  Future<BlockStats> getBlockStats() async {
    try {
      final blockedByMe = await _db
          .collection("blocks")
          .where("blocker_token", isEqualTo: myToken)
          .count()
          .get();

      final blockedMe = await _db
          .collection("blocks")
          .where("blocked_token", isEqualTo: myToken)
          .count()
          .get();

      return BlockStats(
        totalBlockedByMe: blockedByMe.count ?? 0,
        totalBlockedMe: blockedMe.count ?? 0,
      );
    } catch (e) {
      print('[BlockingService] ❌ Failed to get stats: $e');
      return BlockStats(totalBlockedByMe: 0, totalBlockedMe: 0);
    }
  }

  /// Clear cache
  void clearCache() {
    _blockCache.clear();
    _restrictionCache.clear();
    print('[BlockingService] 🧹 Cleared cache');
  }

  @override
  void onClose() {
    _blockListener?.cancel();
    super.onClose();
  }
}

// ============ DATA MODELS ============

/// Block status for a user
class BlockStatus {
  final bool iBlocked; // I blocked them
  final bool theyBlocked; // They blocked me
  final Timestamp? blockedAt;
  final BlockRestrictions? restrictions;

  BlockStatus({
    required this.iBlocked,
    required this.theyBlocked,
    this.blockedAt,
    this.restrictions,
  });

  bool get isBlocked => iBlocked || theyBlocked;
  bool get canChat => !isBlocked;

  factory BlockStatus.notBlocked() {
    return BlockStatus(iBlocked: false, theyBlocked: false);
  }
}

/// Granular privacy restrictions
class BlockRestrictions {
  final bool preventScreenshots;
  final bool preventCopy;
  final bool preventDownload;
  final bool preventForward;
  final bool hideOnlineStatus;
  final bool hideLastSeen;
  final bool hideReadReceipts;

  BlockRestrictions({
    this.preventScreenshots = false,
    this.preventCopy = false,
    this.preventDownload = false,
    this.preventForward = false,
    this.hideOnlineStatus = false,
    this.hideLastSeen = false,
    this.hideReadReceipts = false,
  });

  /// No restrictions (default for normal contacts)
  factory BlockRestrictions.none() {
    return BlockRestrictions();
  }

  /// Standard restrictions (balanced)
  factory BlockRestrictions.standard() {
    return BlockRestrictions(
      preventScreenshots: true,
      preventCopy: true,
      preventDownload: true,
      hideOnlineStatus: true,
    );
  }

  /// Strict restrictions (maximum privacy)
  factory BlockRestrictions.strict() {
    return BlockRestrictions(
      preventScreenshots: true,
      preventCopy: true,
      preventDownload: true,
      preventForward: true,
      hideOnlineStatus: true,
      hideLastSeen: true,
      hideReadReceipts: true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'preventScreenshots': preventScreenshots,
      'preventCopy': preventCopy,
      'preventDownload': preventDownload,
      'preventForward': preventForward,
      'hideOnlineStatus': hideOnlineStatus,
      'hideLastSeen': hideLastSeen,
      'hideReadReceipts': hideReadReceipts,
    };
  }

  factory BlockRestrictions.fromJson(Map<String, dynamic> json) {
    return BlockRestrictions(
      preventScreenshots: json['preventScreenshots'] ?? false,
      preventCopy: json['preventCopy'] ?? false,
      preventDownload: json['preventDownload'] ?? false,
      preventForward: json['preventForward'] ?? false,
      hideOnlineStatus: json['hideOnlineStatus'] ?? false,
      hideLastSeen: json['hideLastSeen'] ?? false,
      hideReadReceipts: json['hideReadReceipts'] ?? false,
    );
  }

  BlockRestrictions copyWith({
    bool? preventScreenshots,
    bool? preventCopy,
    bool? preventDownload,
    bool? preventForward,
    bool? hideOnlineStatus,
    bool? hideLastSeen,
    bool? hideReadReceipts,
  }) {
    return BlockRestrictions(
      preventScreenshots: preventScreenshots ?? this.preventScreenshots,
      preventCopy: preventCopy ?? this.preventCopy,
      preventDownload: preventDownload ?? this.preventDownload,
      preventForward: preventForward ?? this.preventForward,
      hideOnlineStatus: hideOnlineStatus ?? this.hideOnlineStatus,
      hideLastSeen: hideLastSeen ?? this.hideLastSeen,
      hideReadReceipts: hideReadReceipts ?? this.hideReadReceipts,
    );
  }
}

/// Blocked user info
class BlockedUser {
  final String docId;
  final String blockedToken;
  final String blockedName;
  final String blockedAvatar;
  final String? reason;
  final Timestamp? blockedAt;

  BlockedUser({
    required this.docId,
    required this.blockedToken,
    required this.blockedName,
    required this.blockedAvatar,
    this.reason,
    this.blockedAt,
  });
}

/// Block statistics
class BlockStats {
  final int totalBlockedByMe;
  final int totalBlockedMe;

  BlockStats({
    required this.totalBlockedByMe,
    required this.totalBlockedMe,
  });
}
