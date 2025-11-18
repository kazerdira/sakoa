import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sakoa/common/entities/contact_entity.dart';
import 'package:sakoa/common/exceptions/contact_exceptions.dart';
import 'package:sakoa/common/repositories/base/base_repository.dart';
import 'package:sakoa/common/services/blocking_service.dart';
import 'package:sakoa/common/store/store.dart';

/// Repository for handling all contact-related operations
/// Separates contact domain logic from the controller
class ContactRepository extends BaseRepository {
  final FirebaseFirestore _db;
  final BlockingService _blockingService;

  ContactRepository({
    required FirebaseFirestore db,
    required BlockingService blockingService,
  })  : _db = db,
        _blockingService = blockingService;

  @override
  String get repositoryName => 'ContactRepository';

  String get _myToken => UserStore.to.profile.token ?? UserStore.to.token;

  // ============ CONTACT LOADING ============

  /// Load accepted contacts with pagination
  Future<List<ContactEntity>> getAcceptedContacts({
    DocumentSnapshot? lastDoc,
    int limit = 20,
  }) async {
    try {
      logDebug('Loading accepted contacts (limit: $limit)');

      Query query = _db
          .collection("contacts")
          .where("user_token", isEqualTo: _myToken)
          .where("status", isEqualTo: "accepted")
          .orderBy("accepted_at", descending: true)
          .limit(limit);

      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }

      final snapshot = await query.get();
      final contacts = snapshot.docs
          .map((doc) => ContactEntity.fromFirestore(
                doc as DocumentSnapshot<Map<String, dynamic>>,
                null,
              ))
          .toList();

      logSuccess('Loaded ${contacts.length} accepted contacts');
      return contacts;
    } catch (e, stack) {
      logError('Failed to load accepted contacts', e, stack);
      throw ContactFetchException(
        message: 'Failed to load accepted contacts',
        originalError: e,
        stackTrace: stack,
        context: {'limit': limit},
      );
    }
  }

  /// Load pending incoming contact requests
  Future<List<ContactEntity>> getPendingRequests() async {
    try {
      logDebug('Loading pending incoming requests');

      final snapshot = await _db
          .collection("contacts")
          .where("contact_token", isEqualTo: _myToken)
          .where("status", isEqualTo: "pending")
          .orderBy("requested_at", descending: true)
          .get();

      final requests = snapshot.docs
          .map((doc) => ContactEntity.fromFirestore(
                doc as DocumentSnapshot<Map<String, dynamic>>,
                null,
              ))
          .toList();

      logSuccess('Loaded ${requests.length} pending requests');
      return requests;
    } catch (e, stack) {
      logError('Failed to load pending requests', e, stack);
      throw ContactFetchException(
        message: 'Failed to load pending requests',
        originalError: e,
        stackTrace: stack,
      );
    }
  }

  /// Load sent contact requests (outgoing pending)
  Future<List<ContactEntity>> getSentRequests() async {
    try {
      logDebug('Loading sent requests');

      final snapshot = await _db
          .collection("contacts")
          .where("user_token", isEqualTo: _myToken)
          .where("status", isEqualTo: "pending")
          .orderBy("requested_at", descending: true)
          .get();

      final requests = snapshot.docs
          .map((doc) => ContactEntity.fromFirestore(
                doc as DocumentSnapshot<Map<String, dynamic>>,
                null,
              ))
          .toList();

      logSuccess('Loaded ${requests.length} sent requests');
      return requests;
    } catch (e, stack) {
      logError('Failed to load sent requests', e, stack);
      throw ContactFetchException(
        message: 'Failed to load sent requests',
        originalError: e,
        stackTrace: stack,
      );
    }
  }

  /// Load blocked users
  Future<List<ContactEntity>> getBlockedUsers() async {
    try {
      logDebug('Loading blocked users');

      final snapshot = await _db
          .collection("contacts")
          .where("user_token", isEqualTo: _myToken)
          .where("status", isEqualTo: "blocked")
          .orderBy("blocked_at", descending: true)
          .get();

      final blocked = snapshot.docs
          .map((doc) => ContactEntity.fromFirestore(
                doc as DocumentSnapshot<Map<String, dynamic>>,
                null,
              ))
          .toList();

      logSuccess('Loaded ${blocked.length} blocked users');
      return blocked;
    } catch (e, stack) {
      logError('Failed to load blocked users', e, stack);
      throw ContactFetchException(
        message: 'Failed to load blocked users',
        originalError: e,
        stackTrace: stack,
      );
    }
  }

  // ============ USER SEARCH ============

  /// Search users by name (excludes accepted contacts)
  Future<List<UserProfile>> searchUsers(String query, {int limit = 20}) async {
    try {
      logDebug('Searching users: $query');

      if (query.trim().isEmpty) {
        return [];
      }

      final searchLower = query.toLowerCase().trim();

      // Get accepted contact tokens to filter them out
      final acceptedTokens = await _getAcceptedContactTokens();

      // Get all user profiles (client-side filtering for better matching)
      final snapshot = await _db.collection("user_profiles").limit(100).get();

      final List<UserProfile> results = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final userToken = data['token'] as String?;

        // Skip current user
        if (userToken == _myToken) continue;

        // Skip accepted contacts
        if (userToken != null && acceptedTokens.contains(userToken)) continue;

        final name = (data['name'] ?? '').toLowerCase();
        final searchName = (data['search_name'] ?? '').toLowerCase();

        // Match by name
        if (name.contains(searchLower) || searchName.startsWith(searchLower)) {
          // Convert online field
          int? onlineValue;
          if (data['online'] is bool) {
            onlineValue = data['online'] ? 1 : 0;
          } else if (data['online'] is int) {
            onlineValue = data['online'];
          }

          results.add(UserProfile(
            token: userToken,
            name: data['name'],
            avatar: data['avatar'],
            email: data['email'],
            online: onlineValue,
          ));
        }
      }

      // Sort by relevance
      results.sort((a, b) {
        final aName = (a.name ?? '').toLowerCase();
        final bName = (b.name ?? '').toLowerCase();

        // Exact matches first
        final aExact = aName == searchLower;
        final bExact = bName == searchLower;
        if (aExact && !bExact) return -1;
        if (!aExact && bExact) return 1;

        // Starts with query
        final aStarts = aName.startsWith(searchLower);
        final bStarts = bName.startsWith(searchLower);
        if (aStarts && !bStarts) return -1;
        if (!aStarts && bStarts) return 1;

        // Alphabetical
        return aName.compareTo(bName);
      });

      final limitedResults = results.take(limit).toList();
      logSuccess('Found ${limitedResults.length} users matching "$query"');
      return limitedResults;
    } catch (e, stack) {
      logError('Failed to search users', e, stack);
      throw UserSearchException(
        message: 'Failed to search users',
        originalError: e,
        stackTrace: stack,
        context: {'query': query},
      );
    }
  }

  // ============ CONTACT REQUESTS ============

  /// Send contact request to a user
  Future<bool> sendContactRequest({
    required String recipientToken,
    required String recipientName,
    required String recipientAvatar,
  }) async {
    try {
      logDebug('Sending contact request to: $recipientToken');

      // Check if contact already exists (outgoing)
      final existingOutgoing = await _db
          .collection("contacts")
          .where("user_token", isEqualTo: _myToken)
          .where("contact_token", isEqualTo: recipientToken)
          .get();

      if (existingOutgoing.docs.isNotEmpty) {
        final status = existingOutgoing.docs.first.data()['status'];

        if (status == 'accepted') {
          logWarning('Already friends with user');
          return false;
        } else if (status == 'pending') {
          logWarning('Request already sent');
          return false;
        } else if (status == 'blocked') {
          logWarning('User is blocked');
          return false;
        }
      }

      // Check if they sent me a request (incoming) - mutual case
      final existingIncoming = await _db
          .collection("contacts")
          .where("user_token", isEqualTo: recipientToken)
          .where("contact_token", isEqualTo: _myToken)
          .get();

      if (existingIncoming.docs.isNotEmpty) {
        final incomingStatus = existingIncoming.docs.first.data()['status'];

        if (incomingStatus == 'pending') {
          // They already sent me a request - auto-accept both!
          logInfo('Mutual request detected - auto-accepting');
          await _autoAcceptMutualRequest(
            existingIncoming.docs.first.id,
            recipientToken,
            recipientName,
            recipientAvatar,
          );
          return true;
        }
      }

      // Create new contact request
      await _db.collection("contacts").add({
        'user_token': _myToken,
        'user_name': UserStore.to.profile.name,
        'user_avatar': UserStore.to.profile.avatar,
        'user_online': UserStore.to.profile.online ?? 0,
        'contact_token': recipientToken,
        'contact_name': recipientName,
        'contact_avatar': recipientAvatar,
        'contact_online': 0,
        'status': 'pending',
        'requested_by': _myToken,
        'requested_at': FieldValue.serverTimestamp(),
      });

      logSuccess('Contact request sent to $recipientName');
      return true;
    } catch (e, stack) {
      logError('Failed to send contact request', e, stack);
      throw ContactRequestException(
        message: 'Failed to send contact request',
        originalError: e,
        stackTrace: stack,
        context: {'recipientToken': recipientToken},
      );
    }
  }

  /// Accept an incoming contact request
  Future<bool> acceptContactRequest({
    required String contactDocId,
    required String requesterToken,
  }) async {
    try {
      logDebug('Accepting contact request from: $requesterToken');

      // Update the incoming request to accepted
      await _db.collection("contacts").doc(contactDocId).update({
        'status': 'accepted',
        'accepted_at': FieldValue.serverTimestamp(),
      });

      // Check if I also sent them a request
      final myRequest = await _db
          .collection("contacts")
          .where("user_token", isEqualTo: _myToken)
          .where("contact_token", isEqualTo: requesterToken)
          .get();

      if (myRequest.docs.isNotEmpty) {
        // Update my request to accepted as well
        await _db.collection("contacts").doc(myRequest.docs.first.id).update({
          'status': 'accepted',
          'accepted_at': FieldValue.serverTimestamp(),
        });
      }

      logSuccess('Contact request accepted');
      return true;
    } catch (e, stack) {
      logError('Failed to accept contact request', e, stack);
      throw AcceptRequestException(
        message: 'Failed to accept contact request',
        originalError: e,
        stackTrace: stack,
        context: {'contactDocId': contactDocId},
      );
    }
  }

  /// Reject an incoming contact request
  Future<bool> rejectContactRequest(String contactDocId) async {
    try {
      logDebug('Rejecting contact request: $contactDocId');

      await _db.collection("contacts").doc(contactDocId).delete();

      logSuccess('Contact request rejected');
      return true;
    } catch (e, stack) {
      logError('Failed to reject contact request', e, stack);
      throw RejectRequestException(
        message: 'Failed to reject contact request',
        originalError: e,
        stackTrace: stack,
        context: {'contactDocId': contactDocId},
      );
    }
  }

  /// Cancel a sent contact request
  Future<bool> cancelContactRequest(String recipientToken) async {
    try {
      logDebug('Canceling contact request to: $recipientToken');

      final query = await _db
          .collection("contacts")
          .where("user_token", isEqualTo: _myToken)
          .where("contact_token", isEqualTo: recipientToken)
          .where("status", isEqualTo: "pending")
          .get();

      if (query.docs.isEmpty) {
        logWarning('No pending request found to cancel');
        return false;
      }

      await _db.collection("contacts").doc(query.docs.first.id).delete();

      logSuccess('Contact request canceled');
      return true;
    } catch (e, stack) {
      logError('Failed to cancel contact request', e, stack);
      throw CancelRequestException(
        message: 'Failed to cancel contact request',
        originalError: e,
        stackTrace: stack,
        context: {'recipientToken': recipientToken},
      );
    }
  }

  // ============ BLOCKING OPERATIONS ============

  /// Block a user
  Future<bool> blockUser({
    required String userToken,
    required String userName,
    required String userAvatar,
    String? reason,
    BlockRestrictions? restrictions,
  }) async {
    try {
      logDebug('Blocking user: $userName');

      final result = await _blockingService.blockUser(
        userToken: userToken,
        userName: userName,
        userAvatar: userAvatar,
        reason: reason,
        restrictions: restrictions,
      );

      if (result) {
        logSuccess('User blocked: $userName');
      } else {
        logWarning('Failed to block user: $userName');
      }

      return result;
    } catch (e, stack) {
      logError('Failed to block user', e, stack);
      throw BlockingException(
        message: 'Failed to block user',
        originalError: e,
        stackTrace: stack,
        context: {'userToken': userToken, 'userName': userName},
      );
    }
  }

  /// Unblock a user
  Future<bool> unblockUser(String userToken) async {
    try {
      logDebug('Unblocking user: $userToken');

      final result = await _blockingService.unblockUser(userToken);

      if (result) {
        logSuccess('User unblocked');
      } else {
        logWarning('Failed to unblock user');
      }

      return result;
    } catch (e, stack) {
      logError('Failed to unblock user', e, stack);
      throw UnblockingException(
        message: 'Failed to unblock user',
        originalError: e,
        stackTrace: stack,
        context: {'userToken': userToken},
      );
    }
  }

  /// Check block status with a user
  Future<BlockStatus> getBlockStatus(String userToken) async {
    try {
      logDebug('Checking block status for: $userToken');

      final status = await _blockingService.getBlockStatus(userToken);

      logInfo(
          'Block status: iBlocked=${status.iBlocked}, theyBlocked=${status.theyBlocked}');
      return status;
    } catch (e, stack) {
      logError('Failed to check block status', e, stack);
      throw BlockStatusException(
        message: 'Failed to check block status',
        originalError: e,
        stackTrace: stack,
        context: {'userToken': userToken},
      );
    }
  }

  /// Check if user is blocked (cached - fast)
  bool isBlockedCached(String userToken) {
    return _blockingService.isBlockedCached(userToken);
  }

  /// Watch block status in real-time
  Stream<BlockStatus> watchBlockStatus(String userToken) {
    logDebug('Watching block status for: $userToken');
    return _blockingService.watchBlockStatus(userToken);
  }

  /// Get all blocked users from BlockingService
  Future<List<BlockedUser>> getBlockedUsersDetailed() async {
    try {
      logDebug('Getting detailed blocked users list');

      final blockedUsers = await _blockingService.getBlockedUsers();

      logSuccess('Retrieved ${blockedUsers.length} blocked users');
      return blockedUsers;
    } catch (e, stack) {
      logError('Failed to get blocked users', e, stack);
      throw ContactFetchException(
        message: 'Failed to get blocked users',
        originalError: e,
        stackTrace: stack,
      );
    }
  }

  // ============ RELATIONSHIP STATUS ============

  /// Build relationship status map for quick lookups
  Future<Map<String, String>> getRelationshipMap() async {
    try {
      logDebug('Building relationship status map');

      final Map<String, Map<String, dynamic>> relationships = {};

      // Get outgoing contacts
      final myContacts = await _db
          .collection("contacts")
          .where("user_token", isEqualTo: _myToken)
          .get();

      for (var doc in myContacts.docs) {
        final data = doc.data();
        final contactToken = data['contact_token'] as String;
        final status = data['status'] as String;

        relationships[contactToken] = {
          'outgoing': status,
          'doc_id': doc.id,
        };
      }

      // Get incoming contacts
      final theirContacts = await _db
          .collection("contacts")
          .where("contact_token", isEqualTo: _myToken)
          .get();

      for (var doc in theirContacts.docs) {
        final data = doc.data();
        final userToken = data['user_token'] as String;
        final status = data['status'] as String;

        if (!relationships.containsKey(userToken)) {
          relationships[userToken] = {};
        }
        relationships[userToken]!['incoming'] = status;
        relationships[userToken]!['incoming_doc_id'] = doc.id;
      }

      // Analyze relationships
      final Map<String, String> statusMap = {};

      for (var entry in relationships.entries) {
        final userToken = entry.key;
        final outgoing = entry.value['outgoing'] as String?;
        final incoming = entry.value['incoming'] as String?;

        // Mutual pending - will be auto-accepted
        if (outgoing == 'pending' && incoming == 'pending') {
          statusMap[userToken] = 'pending_mutual';
        }
        // Accepted
        else if (outgoing == 'accepted' || incoming == 'accepted') {
          statusMap[userToken] = 'accepted';
        }
        // I sent pending
        else if (outgoing == 'pending') {
          statusMap[userToken] = 'pending_sent';
        }
        // They sent pending
        else if (incoming == 'pending') {
          statusMap[userToken] = 'pending_received';
        }
        // I blocked them
        else if (outgoing == 'blocked') {
          statusMap[userToken] = 'blocked';
        }
        // They blocked me
        else if (incoming == 'blocked') {
          statusMap[userToken] = 'blocked_by';
        }
      }

      logSuccess('Built relationship map with ${statusMap.length} entries');
      return statusMap;
    } catch (e, stack) {
      logError('Failed to build relationship map', e, stack);
      throw ContactFetchException(
        message: 'Failed to build relationship map',
        originalError: e,
        stackTrace: stack,
      );
    }
  }

  // ============ PRIVATE HELPERS ============

  /// Get accepted contact tokens for filtering
  Future<Set<String>> _getAcceptedContactTokens() async {
    final Set<String> tokens = {};

    // Outgoing accepted
    final myAccepted = await _db
        .collection("contacts")
        .where("user_token", isEqualTo: _myToken)
        .where("status", isEqualTo: "accepted")
        .get();

    for (var doc in myAccepted.docs) {
      tokens.add(doc.data()['contact_token'] as String);
    }

    // Incoming accepted
    final theirAccepted = await _db
        .collection("contacts")
        .where("contact_token", isEqualTo: _myToken)
        .where("status", isEqualTo: "accepted")
        .get();

    for (var doc in theirAccepted.docs) {
      tokens.add(doc.data()['user_token'] as String);
    }

    return tokens;
  }

  /// Auto-accept mutual requests (both users added each other)
  Future<void> _autoAcceptMutualRequest(
    String theirDocId,
    String recipientToken,
    String recipientName,
    String recipientAvatar,
  ) async {
    logInfo('Auto-accepting mutual request');

    // Create my request as accepted
    await _db.collection("contacts").add({
      'user_token': _myToken,
      'user_name': UserStore.to.profile.name,
      'user_avatar': UserStore.to.profile.avatar,
      'user_online': UserStore.to.profile.online ?? 0,
      'contact_token': recipientToken,
      'contact_name': recipientName,
      'contact_avatar': recipientAvatar,
      'contact_online': 0,
      'status': 'accepted',
      'requested_by': _myToken,
      'requested_at': FieldValue.serverTimestamp(),
      'accepted_at': FieldValue.serverTimestamp(),
    });

    // Accept their request
    await _db.collection("contacts").doc(theirDocId).update({
      'status': 'accepted',
      'accepted_at': FieldValue.serverTimestamp(),
    });

    logSuccess('Mutual request auto-accepted');
  }
}
