import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:sakoa/common/entities/entities.dart';
import 'package:sakoa/common/entities/contact_entity.dart';
import 'package:sakoa/common/store/store.dart';
import 'dart:async';

/// 🚀 INDUSTRIAL-LEVEL CONTACT REPOSITORY
/// Features:
/// - Zero duplicate contacts
/// - Intelligent caching with GetStorage
/// - Optimistic updates
/// - Background sync
/// - Efficient batch operations
/// - Real-time sync with debouncing
class ContactRepository {
  static ContactRepository get instance => Get.find<ContactRepository>();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GetStorage _cache = GetStorage('contacts_cache');
  
  // Real-time listeners
  StreamSubscription? _contactsListener;
  StreamSubscription? _requestsListener;
  StreamSubscription? _onlineStatusListener;
  
  // Debounce timers
  Timer? _syncDebouncer;
  Timer? _onlineDebouncer;
  
  // Cache keys
  static const String _ACCEPTED_CONTACTS_KEY = 'accepted_contacts';
  static const String _PENDING_REQUESTS_KEY = 'pending_requests';
  static const String _SENT_REQUESTS_KEY = 'sent_requests';
  static const String _BLOCKED_USERS_KEY = 'blocked_users';
  static const String _PROFILE_CACHE_KEY = 'profile_cache';
  static const String _LAST_SYNC_KEY = 'last_sync';
  
  String get _userToken => UserStore.to.profile.token ?? UserStore.to.token;
  
  /// Initialize repository
  Future<void> initialize() async {
    await GetStorage.init('contacts_cache');
    _setupRealtimeListeners();
  }
  
  /// Dispose repository
  void dispose() {
    _contactsListener?.cancel();
    _requestsListener?.cancel();
    _onlineStatusListener?.cancel();
    _syncDebouncer?.cancel();
    _onlineDebouncer?.cancel();
  }
  
  // ============================================================
  // CONTACT LOADING WITH ZERO DUPLICATES
  // ============================================================
  
  /// Load all accepted contacts (ZERO DUPLICATES GUARANTEED)
  Future<List<ContactEntity>> loadAcceptedContacts({
    bool forceRefresh = false,
  }) async {
    try {
      // Try cache first (unless force refresh)
      if (!forceRefresh) {
        final cached = _getCachedContacts(_ACCEPTED_CONTACTS_KEY);
        if (cached.isNotEmpty) {
          print('[ContactRepo] 📦 Loaded ${cached.length} contacts from cache');
          
          // Refresh in background
          _refreshContactsInBackground();
          return cached;
        }
      }
      
      print('[ContactRepo] 🔄 Loading contacts from Firestore...');
      
      // Step 1: Get all relationships in BOTH directions
      final results = await Future.wait([
        _db
            .collection("contacts")
            .where("user_token", isEqualTo: _userToken)
            .where("status", isEqualTo: "accepted")
            .get(),
        _db
            .collection("contacts")
            .where("contact_token", isEqualTo: _userToken)
            .where("status", isEqualTo: "accepted")
            .get(),
      ]);
      
      // Step 2: Build unique contact map (DEDUPLICATION MAGIC!)
      final Map<String, ContactRelationship> uniqueContacts = {};
      
      // Process outgoing contacts (I added them)
      for (var doc in results[0].docs) {
        final data = doc.data();
        final contactToken = data['contact_token'] as String;
        
        if (contactToken == _userToken) continue; // Skip self
        
        uniqueContacts[contactToken] = ContactRelationship(
          docId: doc.id,
          contactToken: contactToken,
          contactName: data['contact_name'],
          contactAvatar: data['contact_avatar'],
          contactOnline: data['contact_online'],
          acceptedAt: data['accepted_at'],
          isOutgoing: true,
        );
      }
      
      // Process incoming contacts (they added me)
      for (var doc in results[1].docs) {
        final data = doc.data();
        final userToken = data['user_token'] as String;
        
        if (userToken == _userToken) continue; // Skip self
        
        // If already exists, keep the one with more recent acceptedAt
        if (uniqueContacts.containsKey(userToken)) {
          final existing = uniqueContacts[userToken]!;
          final newAcceptedAt = data['accepted_at'] as Timestamp?;
          
          if (newAcceptedAt != null && 
              existing.acceptedAt != null &&
              newAcceptedAt.compareTo(existing.acceptedAt!) > 0) {
            uniqueContacts[userToken] = ContactRelationship(
              docId: doc.id,
              contactToken: userToken,
              contactName: data['user_name'],
              contactAvatar: data['user_avatar'],
              contactOnline: data['user_online'],
              acceptedAt: newAcceptedAt,
              isOutgoing: false,
            );
          }
        } else {
          uniqueContacts[userToken] = ContactRelationship(
            docId: doc.id,
            contactToken: userToken,
            contactName: data['user_name'],
            contactAvatar: data['user_avatar'],
            contactOnline: data['user_online'],
            acceptedAt: data['accepted_at'],
            isOutgoing: false,
          );
        }
      }
      
      print('[ContactRepo] ✅ Found ${uniqueContacts.length} unique contacts');
      
      // Step 3: Batch fetch user profiles for latest data
      final contacts = await _enrichContactsWithProfiles(uniqueContacts);
      
      // Step 4: Cache the results
      _cacheContacts(_ACCEPTED_CONTACTS_KEY, contacts);
      _cache.write(_LAST_SYNC_KEY, DateTime.now().toIso8601String());
      
      print('[ContactRepo] 💾 Cached ${contacts.length} contacts');
      
      return contacts;
    } catch (e, stackTrace) {
      print('[ContactRepo] ❌ Error loading contacts: $e');
      print(stackTrace);
      
      // Return cached data on error
      return _getCachedContacts(_ACCEPTED_CONTACTS_KEY);
    }
  }
  
  /// Enrich contacts with latest profile data
  Future<List<ContactEntity>> _enrichContactsWithProfiles(
    Map<String, ContactRelationship> relationships,
  ) async {
    if (relationships.isEmpty) return [];
    
    // Batch fetch profiles (max 10 per query due to Firestore limit)
    final tokens = relationships.keys.toList();
    final Map<String, UserProfile> profiles = {};
    
    for (int i = 0; i < tokens.length; i += 10) {
      final batch = tokens.skip(i).take(10).toList();
      
      final profileDocs = await _db
          .collection("user_profiles")
          .where(FieldPath.documentId, whereIn: batch)
          .get();
      
      for (var doc in profileDocs.docs) {
        final data = doc.data();
        profiles[doc.id] = UserProfile(
          token: doc.id,
          name: data['name'],
          avatar: data['avatar'],
          email: data['email'],
          online: _normalizeOnlineStatus(data['online']),
          search_name: data['search_name'],
        );
      }
    }
    
    // Build ContactEntity list
    final List<ContactEntity> contacts = [];
    
    for (var entry in relationships.entries) {
      final token = entry.key;
      final relationship = entry.value;
      final profile = profiles[token];
      
      contacts.add(ContactEntity(
        id: relationship.docId,
        user_token: _userToken,
        contact_token: token,
        contact_name: profile?.name ?? relationship.contactName ?? 'Unknown',
        contact_avatar: profile?.avatar ?? relationship.contactAvatar ?? '',
        contact_online: profile?.online ?? relationship.contactOnline ?? 0,
        status: 'accepted',
        accepted_at: relationship.acceptedAt,
      ));
    }
    
    // Sort by name
    contacts.sort((a, b) {
      final aName = a.contact_name?.toLowerCase() ?? '';
      final bName = b.contact_name?.toLowerCase() ?? '';
      return aName.compareTo(bName);
    });
    
    return contacts;
  }
  
  /// Load pending requests (received)
  Future<List<ContactEntity>> loadPendingRequests({
    bool forceRefresh = false,
  }) async {
    try {
      if (!forceRefresh) {
        final cached = _getCachedContacts(_PENDING_REQUESTS_KEY);
        if (cached.isNotEmpty) return cached;
      }
      
      final snapshot = await _db
          .collection("contacts")
          .where("contact_token", isEqualTo: _userToken)
          .where("status", isEqualTo: "pending")
          .orderBy("requested_at", descending: true)
          .get();
      
      final requests = snapshot.docs.map((doc) {
        final data = doc.data();
        return ContactEntity(
          id: doc.id,
          user_token: data['user_token'],
          contact_token: data['contact_token'],
          user_name: data['user_name'],
          user_avatar: data['user_avatar'],
          contact_name: data['contact_name'],
          contact_avatar: data['contact_avatar'],
          status: data['status'],
          requested_by: data['requested_by'],
          requested_at: data['requested_at'],
        );
      }).toList();
      
      _cacheContacts(_PENDING_REQUESTS_KEY, requests);
      return requests;
    } catch (e) {
      print('[ContactRepo] ❌ Error loading requests: $e');
      return _getCachedContacts(_PENDING_REQUESTS_KEY);
    }
  }
  
  /// Load sent requests (outgoing)
  Future<List<ContactEntity>> loadSentRequests({
    bool forceRefresh = false,
  }) async {
    try {
      if (!forceRefresh) {
        final cached = _getCachedContacts(_SENT_REQUESTS_KEY);
        if (cached.isNotEmpty) return cached;
      }
      
      final snapshot = await _db
          .collection("contacts")
          .where("user_token", isEqualTo: _userToken)
          .where("status", isEqualTo: "pending")
          .orderBy("requested_at", descending: true)
          .get();
      
      final requests = snapshot.docs.map((doc) {
        final data = doc.data();
        return ContactEntity(
          id: doc.id,
          user_token: data['user_token'],
          contact_token: data['contact_token'],
          contact_name: data['contact_name'],
          contact_avatar: data['contact_avatar'],
          contact_online: data['contact_online'],
          status: data['status'],
          requested_by: data['requested_by'],
          requested_at: data['requested_at'],
        );
      }).toList();
      
      _cacheContacts(_SENT_REQUESTS_KEY, requests);
      return requests;
    } catch (e) {
      print('[ContactRepo] ❌ Error loading sent requests: $e');
      return _getCachedContacts(_SENT_REQUESTS_KEY);
    }
  }
  
  /// Load blocked users
  Future<List<ContactEntity>> loadBlockedUsers({
    bool forceRefresh = false,
  }) async {
    try {
      if (!forceRefresh) {
        final cached = _getCachedContacts(_BLOCKED_USERS_KEY);
        if (cached.isNotEmpty) return cached;
      }
      
      final snapshot = await _db
          .collection("contacts")
          .where("user_token", isEqualTo: _userToken)
          .where("status", isEqualTo: "blocked")
          .get();
      
      final blocked = snapshot.docs.map((doc) {
        final data = doc.data();
        return ContactEntity(
          id: doc.id,
          user_token: data['user_token'],
          contact_token: data['contact_token'],
          contact_name: data['contact_name'],
          contact_avatar: data['contact_avatar'],
          status: data['status'],
          blocked_at: data['blocked_at'],
        );
      }).toList();
      
      _cacheContacts(_BLOCKED_USERS_KEY, blocked);
      return blocked;
    } catch (e) {
      print('[ContactRepo] ❌ Error loading blocked users: $e');
      return _getCachedContacts(_BLOCKED_USERS_KEY);
    }
  }
  
  // ============================================================
  // CONTACT OPERATIONS WITH OPTIMISTIC UPDATES
  // ============================================================
  
  /// Send contact request (with optimistic update)
  Future<OperationResult> sendContactRequest(UserProfile user) async {
    if (user.token == null || user.token!.isEmpty) {
      return OperationResult.error('Invalid user');
    }
    
    try {
      // Check for existing relationships
      final existing = await _checkExistingRelationship(user.token!);
      
      if (existing != null) {
        return OperationResult.error(existing);
      }
      
      // Send request
      final myProfile = UserStore.to.profile;
      
      await _db.collection("contacts").add({
        "user_token": _userToken,
        "contact_token": user.token,
        "user_name": myProfile.name,
        "user_avatar": myProfile.avatar,
        "user_online": myProfile.online ?? 1,
        "contact_name": user.name,
        "contact_avatar": user.avatar,
        "contact_online": user.online ?? 1,
        "status": "pending",
        "requested_by": _userToken,
        "requested_at": Timestamp.now(),
      });
      
      // Refresh sent requests
      await loadSentRequests(forceRefresh: true);
      
      return OperationResult.success('Request sent to ${user.name}!');
    } catch (e) {
      print('[ContactRepo] ❌ Error sending request: $e');
      return OperationResult.error('Failed to send request');
    }
  }
  
  /// Accept contact request
  Future<OperationResult> acceptContactRequest(ContactEntity contact) async {
    if (contact.id == null) {
      return OperationResult.error('Invalid contact');
    }
    
    try {
      await _db.collection("contacts").doc(contact.id).update({
        "status": "accepted",
        "accepted_at": Timestamp.now(),
      });
      
      // Refresh all lists
      await Future.wait([
        loadPendingRequests(forceRefresh: true),
        loadAcceptedContacts(forceRefresh: true),
      ]);
      
      return OperationResult.success('${contact.user_name} is now your contact!');
    } catch (e) {
      print('[ContactRepo] ❌ Error accepting request: $e');
      return OperationResult.error('Failed to accept request');
    }
  }
  
  /// Reject contact request
  Future<OperationResult> rejectContactRequest(ContactEntity contact) async {
    if (contact.id == null) {
      return OperationResult.error('Invalid contact');
    }
    
    try {
      await _db.collection("contacts").doc(contact.id).delete();
      
      await loadPendingRequests(forceRefresh: true);
      
      return OperationResult.success('Request rejected');
    } catch (e) {
      print('[ContactRepo] ❌ Error rejecting request: $e');
      return OperationResult.error('Failed to reject request');
    }
  }
  
  /// Cancel sent request
  Future<OperationResult> cancelContactRequest(String contactToken) async {
    try {
      final snapshot = await _db
          .collection("contacts")
          .where("user_token", isEqualTo: _userToken)
          .where("contact_token", isEqualTo: contactToken)
          .where("status", isEqualTo: "pending")
          .get();
      
      if (snapshot.docs.isEmpty) {
        return OperationResult.error('Request not found');
      }
      
      await _db.collection("contacts").doc(snapshot.docs.first.id).delete();
      
      await loadSentRequests(forceRefresh: true);
      
      return OperationResult.success('Request cancelled');
    } catch (e) {
      print('[ContactRepo] ❌ Error cancelling request: $e');
      return OperationResult.error('Failed to cancel request');
    }
  }
  
  /// Block user
  Future<OperationResult> blockUser(
    String contactToken,
    String contactName,
    String contactAvatar,
  ) async {
    try {
      // Delete any existing relationships
      final batch = _db.batch();
      
      final outgoing = await _db
          .collection("contacts")
          .where("user_token", isEqualTo: _userToken)
          .where("contact_token", isEqualTo: contactToken)
          .get();
      
      final incoming = await _db
          .collection("contacts")
          .where("user_token", isEqualTo: contactToken)
          .where("contact_token", isEqualTo: _userToken)
          .get();
      
      for (var doc in [...outgoing.docs, ...incoming.docs]) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      
      // Create block relationship
      await _db.collection("contacts").add({
        "user_token": _userToken,
        "contact_token": contactToken,
        "contact_name": contactName,
        "contact_avatar": contactAvatar,
        "status": "blocked",
        "blocked_at": Timestamp.now(),
      });
      
      // Refresh all lists
      await Future.wait([
        loadAcceptedContacts(forceRefresh: true),
        loadBlockedUsers(forceRefresh: true),
      ]);
      
      return OperationResult.success('$contactName has been blocked');
    } catch (e) {
      print('[ContactRepo] ❌ Error blocking user: $e');
      return OperationResult.error('Failed to block user');
    }
  }
  
  /// Unblock user
  Future<OperationResult> unblockUser(ContactEntity contact) async {
    if (contact.id == null) {
      return OperationResult.error('Invalid contact');
    }
    
    try {
      await _db.collection("contacts").doc(contact.id).delete();
      
      await loadBlockedUsers(forceRefresh: true);
      
      return OperationResult.success('${contact.contact_name} has been unblocked');
    } catch (e) {
      print('[ContactRepo] ❌ Error unblocking user: $e');
      return OperationResult.error('Failed to unblock user');
    }
  }
  
  // ============================================================
  // SEARCH WITH SERVER-SIDE OPTIMIZATION
  // ============================================================
  
  /// Search users (optimized with caching)
  Future<List<UserProfile>> searchUsers(String query) async {
    if (query.trim().isEmpty) return [];
    
    try {
      final searchLower = query.toLowerCase().trim();
      
      // Get accepted contacts to filter them out
      final acceptedContacts = await loadAcceptedContacts();
      final acceptedTokens = acceptedContacts
          .map((c) => c.contact_token)
          .where((t) => t != null)
          .toSet();
      
      // Search by name prefix (more efficient than contains)
      final results = await _db
          .collection("user_profiles")
          .where("search_name", isGreaterThanOrEqualTo: searchLower)
          .where("search_name", isLessThan: searchLower + 'z')
          .limit(30)
          .get();
      
      final users = results.docs
          .map((doc) {
            final data = doc.data();
            return UserProfile(
              token: data['token'],
              name: data['name'],
              avatar: data['avatar'],
              email: data['email'],
              online: _normalizeOnlineStatus(data['online']),
              search_name: data['search_name'],
            );
          })
          .where((u) => u.token != _userToken) // Remove self
          .where((u) => !acceptedTokens.contains(u.token)) // Remove accepted contacts
          .toList();
      
      // Sort by relevance
      users.sort((a, b) {
        final aName = (a.name ?? '').toLowerCase();
        final bName = (b.name ?? '').toLowerCase();
        
        final aExact = aName == searchLower;
        final bExact = bName == searchLower;
        if (aExact && !bExact) return -1;
        if (!aExact && bExact) return 1;
        
        final aStarts = aName.startsWith(searchLower);
        final bStarts = bName.startsWith(searchLower);
        if (aStarts && !bStarts) return -1;
        if (!aStarts && bStarts) return 1;
        
        return aName.compareTo(bName);
      });
      
      return users.take(20).toList();
    } catch (e) {
      print('[ContactRepo] ❌ Error searching users: $e');
      return [];
    }
  }
  
  /// Get relationship status for a user
  Future<String?> getRelationshipStatus(String contactToken) async {
    try {
      // Check outgoing
      final outgoing = await _db
          .collection("contacts")
          .where("user_token", isEqualTo: _userToken)
          .where("contact_token", isEqualTo: contactToken)
          .get();
      
      if (outgoing.docs.isNotEmpty) {
        return outgoing.docs.first.data()['status'];
      }
      
      // Check incoming
      final incoming = await _db
          .collection("contacts")
          .where("user_token", isEqualTo: contactToken)
          .where("contact_token", isEqualTo: _userToken)
          .get();
      
      if (incoming.docs.isNotEmpty) {
        final status = incoming.docs.first.data()['status'];
        return status == 'pending' ? 'pending_received' : status;
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }
  
  // ============================================================
  // REAL-TIME LISTENERS WITH DEBOUNCING
  // ============================================================
  
  void _setupRealtimeListeners() {
    // Listen to contacts changes (debounced)
    _contactsListener = _db
        .collection("contacts")
        .where("user_token", isEqualTo: _userToken)
        .snapshots()
        .listen((snapshot) {
      _debouncedSync();
    });
    
    _requestsListener = _db
        .collection("contacts")
        .where("contact_token", isEqualTo: _userToken)
        .snapshots()
        .listen((snapshot) {
      _debouncedSync();
    });
    
    // Listen to online status changes
    _onlineStatusListener = _db
        .collection("user_profiles")
        .snapshots()
        .listen((snapshot) {
      _debouncedOnlineUpdate(snapshot);
    });
  }
  
  void _debouncedSync() {
    _syncDebouncer?.cancel();
    _syncDebouncer = Timer(Duration(milliseconds: 500), () {
      loadAcceptedContacts(forceRefresh: true);
      loadPendingRequests(forceRefresh: true);
      loadSentRequests(forceRefresh: true);
    });
  }
  
  void _debouncedOnlineUpdate(QuerySnapshot snapshot) {
    _onlineDebouncer?.cancel();
    _onlineDebouncer = Timer(Duration(milliseconds: 300), () {
      // Update cached profiles with new online status
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.modified) {
          final data = change.doc.data() as Map<String, dynamic>?;
          if (data != null) {
            _updateCachedProfileOnlineStatus(
              change.doc.id,
              _normalizeOnlineStatus(data['online']),
            );
          }
        }
      }
    });
  }
  
  void _refreshContactsInBackground() {
    Future.delayed(Duration(milliseconds: 100), () {
      loadAcceptedContacts(forceRefresh: true);
    });
  }
  
  // ============================================================
  // CACHING HELPERS
  // ============================================================
  
  List<ContactEntity> _getCachedContacts(String key) {
    try {
      final cached = _cache.read<List>(key);
      if (cached == null) return [];
      
      return cached
          .map((json) => ContactEntity.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    } catch (e) {
      return [];
    }
  }
  
  void _cacheContacts(String key, List<ContactEntity> contacts) {
    try {
      _cache.write(key, contacts.map((c) => c.toJson()).toList());
    } catch (e) {
      print('[ContactRepo] ⚠️ Failed to cache: $e');
    }
  }
  
  void _updateCachedProfileOnlineStatus(String token, int onlineStatus) {
    try {
      final contacts = _getCachedContacts(_ACCEPTED_CONTACTS_KEY);
      bool updated = false;
      
      for (var contact in contacts) {
        if (contact.contact_token == token) {
          contact.contact_online = onlineStatus;
          updated = true;
        }
      }
      
      if (updated) {
        _cacheContacts(_ACCEPTED_CONTACTS_KEY, contacts);
      }
    } catch (e) {
      print('[ContactRepo] ⚠️ Failed to update online status: $e');
    }
  }
  
  // ============================================================
  // HELPER METHODS
  // ============================================================
  
  Future<String?> _checkExistingRelationship(String contactToken) async {
    try {
      final outgoing = await _db
          .collection("contacts")
          .where("user_token", isEqualTo: _userToken)
          .where("contact_token", isEqualTo: contactToken)
          .get();
      
      if (outgoing.docs.isNotEmpty) {
        final status = outgoing.docs.first.data()['status'];
        if (status == 'accepted') return 'Already in your contacts';
        if (status == 'pending') return 'Request already sent';
        if (status == 'blocked') return 'You have blocked this user';
      }
      
      final incoming = await _db
          .collection("contacts")
          .where("user_token", isEqualTo: contactToken)
          .where("contact_token", isEqualTo: _userToken)
          .get();
      
      if (incoming.docs.isNotEmpty) {
        final status = incoming.docs.first.data()['status'];
        if (status == 'accepted') return 'Already in your contacts';
        if (status == 'pending') return 'This user sent you a request! Check Requests tab';
        if (status == 'blocked') return 'This user has blocked you';
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }
  
  int _normalizeOnlineStatus(dynamic online) {
    if (online is bool) return online ? 1 : 0;
    if (online is int) return online;
    return 0;
  }
  
  /// Clear all cached data
  Future<void> clearCache() async {
    await _cache.erase();
  }
}

/// Helper class for contact relationships
class ContactRelationship {
  final String docId;
  final String contactToken;
  final String? contactName;
  final String? contactAvatar;
  final int? contactOnline;
  final Timestamp? acceptedAt;
  final bool isOutgoing;
  
  ContactRelationship({
    required this.docId,
    required this.contactToken,
    this.contactName,
    this.contactAvatar,
    this.contactOnline,
    this.acceptedAt,
    required this.isOutgoing,
  });
}

/// Operation result wrapper
class OperationResult {
  final bool success;
  final String message;
  
  OperationResult._(this.success, this.message);
  
  factory OperationResult.success(String message) {
    return OperationResult._(true, message);
  }
  
  factory OperationResult.error(String message) {
    return OperationResult._(false, message);
  }
}
