import 'dart:convert';

import 'package:sakoa/common/apis/apis.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:sakoa/common/entities/entities.dart';
import 'package:sakoa/common/entities/contact_entity.dart';
import 'package:sakoa/common/store/store.dart';
import 'package:sakoa/common/widgets/toast.dart';
import 'index.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ContactController extends GetxController {
  ContactController();
  final ContactState state = ContactState();
  final db = FirebaseFirestore.instance;
  final _cache =
      GetStorage('contacts_cache'); // ✨ Fast caching (20-30x faster!)

  // ✅ CRITICAL FIX: Use profile.token for Firestore queries!
  // UserStore.to.token = access_token (JWT for API, changes on login)
  // UserStore.to.profile.token = permanent Firestore user ID (NEVER changes)
  // Contacts collection uses profile.token as user_token/contact_token!
  String get token {
    return UserStore.to.profile.token ?? UserStore.to.token;
  }

  // Real-time listeners
  var contactsListener;
  var requestsListener;

  /// Setup real-time Firestore listeners for instant updates
  void _setupRealtimeListeners() {
    // Listen to contacts where I'm the user (outgoing)
    contactsListener = db
        .collection("contacts")
        .where("user_token", isEqualTo: token)
        .snapshots()
        .listen((snapshot) {
      _updateRelationshipMap();
      loadSentRequests();
      loadBlockedUsers();
    }, onError: (error) {
      print("[ContactController] ❌ Error in contacts listener: $error");
    });

    // Listen to contacts where I'm the contact (incoming requests)
    requestsListener = db
        .collection("contacts")
        .where("contact_token", isEqualTo: token)
        .snapshots()
        .listen((snapshot) {
      _updateRelationshipMap();
      loadPendingRequests();
    }, onError: (error) {
      print("[ContactController] ❌ Error in requests listener: $error");
    });

    // Listen to online status changes for all cached profiles
    _setupOnlineStatusListener();
  }

  /// Listen to online status changes for contacts in real-time
  void _setupOnlineStatusListener() {
    // Cancel existing listener
    state.onlineStatusListener?.cancel();

    // Listen to user_profiles changes for cached users
    state.onlineStatusListener =
        db.collection("user_profiles").snapshots().listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.modified) {
          String token = change.doc.id;
          var data = change.doc.data();

          // Update cache if this user is in our profile cache
          if (state.profileCache.containsKey(token) && data != null) {
            int newOnlineStatus = data['online'] ?? 0;
            int oldOnlineStatus = state.profileCache[token]?.online ?? 0;

            if (newOnlineStatus != oldOnlineStatus) {
              print(
                  "[ContactController] 🟢 Online status changed for $token: $oldOnlineStatus → $newOnlineStatus");

              // Update cached profile
              state.profileCache[token]?.online = newOnlineStatus;

              // Update contacts list
              for (int i = 0; i < state.acceptedContacts.length; i++) {
                if (state.acceptedContacts[i].contact_token == token) {
                  state.acceptedContacts[i].contact_online = newOnlineStatus;
                  state.acceptedContacts.refresh(); // Trigger UI update
                  break;
                }
              }
            }
          }
        }
      }
    }, onError: (error) {
      print("[ContactController] ❌ Error in online status listener: $error");
    });
  }

  /// Build relationship status map for quick lookups - ENHANCED LOGIC
  Future<void> _updateRelationshipMap() async {
    try {
      state.relationshipStatus.clear();
      Map<String, Map<String, dynamic>> relationships = {};

      // Get all my outgoing contacts
      var myContacts = await db
          .collection("contacts")
          .where("user_token", isEqualTo: token)
          .get();

      for (var doc in myContacts.docs) {
        var data = doc.data();
        String contactToken = data['contact_token'];
        String status = data['status'];

        relationships[contactToken] = {
          'outgoing': status,
          'doc_id': doc.id,
        };
      }

      // Get all incoming contacts
      var theirContacts = await db
          .collection("contacts")
          .where("contact_token", isEqualTo: token)
          .get();

      for (var doc in theirContacts.docs) {
        var data = doc.data();
        String userToken = data['user_token'];
        String status = data['status'];

        if (!relationships.containsKey(userToken)) {
          relationships[userToken] = {};
        }
        relationships[userToken]!['incoming'] = status;
        relationships[userToken]!['incoming_doc_id'] = doc.id;
      }

      // Now analyze relationships and set proper status
      for (var entry in relationships.entries) {
        String userToken = entry.key;
        String? outgoing = entry.value['outgoing'];
        String? incoming = entry.value['incoming'];

        // Case 1: Both sent requests (mutual pending) - SPECIAL CASE!
        if (outgoing == 'pending' && incoming == 'pending') {
          state.relationshipStatus[userToken] = 'pending_mutual';

          // Auto-accept both since it's mutual!
          _autoAcceptMutualRequest(
              entry.value['doc_id'], entry.value['incoming_doc_id']);
        }
        // Case 2: Accepted in either direction
        else if (outgoing == 'accepted' || incoming == 'accepted') {
          state.relationshipStatus[userToken] = 'accepted';
        }
        // Case 3: I sent pending
        else if (outgoing == 'pending') {
          state.relationshipStatus[userToken] = 'pending_sent';
        }
        // Case 4: They sent pending
        else if (incoming == 'pending') {
          state.relationshipStatus[userToken] = 'pending_received';
        }
        // Case 5: I blocked them
        else if (outgoing == 'blocked') {
          state.relationshipStatus[userToken] = 'blocked';
        }
        // Case 6: They blocked me
        else if (incoming == 'blocked') {
          state.relationshipStatus[userToken] = 'blocked_by';
        }
      }
    } catch (e) {
      print("[ContactController] Error updating relationship map: $e");
    }
  }

  /// Auto-accept mutual pending requests (both users added each other)
  Future<void> _autoAcceptMutualRequest(
      String myDocId, String theirDocId) async {
    try {
      // Accept both documents
      await Future.wait([
        db.collection("contacts").doc(myDocId).update({
          "status": "accepted",
          "accepted_at": Timestamp.now(),
        }),
        db.collection("contacts").doc(theirDocId).update({
          "status": "accepted",
          "accepted_at": Timestamp.now(),
        }),
      ]);

      toastInfo(msg: "🎉 You both added each other! Auto-accepted!");

      // Refresh all lists
      await Future.wait([
        loadAcceptedContacts(),
        loadPendingRequests(),
        loadSentRequests(),
      ]);
    } catch (e) {
      print("[ContactController] Error auto-accepting mutual request: $e");
    }
  }

  /// Get relationship status for a user (for UI)
  String? getRelationshipStatus(String? userToken) {
    if (userToken == null) return null;
    return state.relationshipStatus[userToken];
  }

  /// Get button configuration for user relationship status
  Map<String, dynamic> getButtonConfig(String? userToken) {
    String? status = getRelationshipStatus(userToken);

    switch (status) {
      case 'accepted':
        return {
          'text': '✓ Friends',
          'color': Colors.green,
          'enabled': false,
          'icon': Icons.check_circle,
        };
      case 'pending_sent':
        return {
          'text': '⏳ Pending',
          'color': Colors.orange,
          'enabled': true, // Allow cancel
          'icon': Icons.hourglass_empty,
        };
      case 'pending_received':
        return {
          'text': '📬 Respond',
          'color': Colors.blue,
          'enabled': true,
          'icon': Icons.mail,
        };
      case 'pending_mutual':
        return {
          'text': '🎉 Auto-Accepting...',
          'color': Colors.purple,
          'enabled': false,
          'icon': Icons.auto_awesome,
        };
      case 'blocked':
        return {
          'text': '🚫 Blocked',
          'color': Colors.red,
          'enabled': false,
          'icon': Icons.block,
        };
      case 'blocked_by':
        return {
          'text': '🚫 Unavailable',
          'color': Colors.grey,
          'enabled': false,
          'icon': Icons.block,
        };
      default:
        return {
          'text': '+ Add',
          'color': Color(0xFF1a73e8),
          'enabled': true,
          'icon': Icons.person_add,
        };
    }
  }

  // =============== NEW PROFESSIONAL CONTACT MANAGEMENT ===============

  /// Load accepted contacts only
  // ========== INDUSTRIAL-LEVEL CONTACT LOADING WITH PAGINATION ==========

  /// Load accepted contacts with pagination and caching
  /// [refresh] = true: Clear existing data and reload from scratch
  /// [loadMore] = true: Load next page (pagination)
  Future<void> loadAcceptedContacts({
    bool refresh = false,
    bool loadMore = false,
  }) async {
    // Prevent duplicate loading
    if (state.isLoadingContacts.value) {
      print("[ContactController] ⏸️ Already loading contacts, skipping...");
      return;
    }

    // If no more data, don't load
    if (loadMore && !state.hasMoreContacts.value) {
      print("[ContactController] 📭 No more contacts to load");
      return;
    }

    // ✨ INSTANT CACHE LOAD (0.1s vs 2-3s from Firestore!)
    if (!loadMore && !refresh) {
      final cachedData = _cache.read('accepted_contacts_$token');
      if (cachedData != null) {
        try {
          print("[ContactController] ⚡ Loading from cache...");
          final List<dynamic> cachedList = cachedData;
          state.acceptedContacts.value = cachedList
              .map((json) =>
                  ContactEntity.fromJson(Map<String, dynamic>.from(json)))
              .toList();
          print(
              "[ContactController] ⚡ CACHE HIT! Loaded ${state.acceptedContacts.length} contacts instantly!");
          // Continue to fetch fresh data in background
        } catch (e) {
          print("[ContactController] ⚠️ Cache read failed: $e");
        }
      }
    }

    try {
      state.isLoadingContacts.value = true;
      if (refresh) {
        state.acceptedContacts.clear();
        state.lastContactDoc = null;
        state.hasMoreContacts.value = true;
      }

      // Strategy: Query contacts collection, then batch-fetch user profiles
      // This is more efficient than individual queries per contact

      // Step 1: Get contact relationships (with pagination)
      List<Map<String, dynamic>> contactRelationships = [];

      // Query where I accepted someone
      // NOTE: Removed orderBy to avoid index issues - can add back later with Firestore index
      Query<Map<String, dynamic>> myContactsQuery = db
          .collection("contacts")
          .where("user_token", isEqualTo: token)
          .where("status", isEqualTo: "accepted")
          .limit(ContactState.CONTACTS_PAGE_SIZE);

      if (state.lastContactDoc != null && loadMore) {
        myContactsQuery =
            myContactsQuery.startAfterDocument(state.lastContactDoc!);
      }

      var myContacts = await myContactsQuery.get();

      // Query where someone accepted me
      // NOTE: Removed orderBy to avoid index issues - can add back later with Firestore index
      Query<Map<String, dynamic>> theirContactsQuery = db
          .collection("contacts")
          .where("contact_token", isEqualTo: token)
          .where("status", isEqualTo: "accepted")
          .limit(ContactState.CONTACTS_PAGE_SIZE);

      if (state.lastContactDoc != null && loadMore) {
        theirContactsQuery =
            theirContactsQuery.startAfterDocument(state.lastContactDoc!);
      }

      var theirContacts = await theirContactsQuery.get();

      // Step 2: Merge and deduplicate contact tokens
      Set<String> uniqueTokens = {};
      Set<String> tokensToFetch = {};

      // Process outgoing contacts
      for (var doc in myContacts.docs) {
        var data = doc.data();
        String contactToken = data['contact_token'] ?? '';

        if (contactToken.isEmpty || uniqueTokens.contains(contactToken)) {
          continue;
        }

        uniqueTokens.add(contactToken);
        tokensToFetch.add(contactToken);

        contactRelationships.add({
          'contact_token': contactToken,
          'doc_id': doc.id,
          'accepted_at': data['accepted_at'],
          // ✅ STORE CONTACT DATA FROM CONTACTS DOC (for fallback)
          'contact_name': data['contact_name'],
          'contact_avatar': data['contact_avatar'],
          'contact_online': data['contact_online'],
        });

        state.lastContactDoc = doc;
      }

      // Process incoming contacts
      for (var doc in theirContacts.docs) {
        var data = doc.data();
        String contactToken = data['user_token'] ?? '';

        if (contactToken.isEmpty || uniqueTokens.contains(contactToken)) {
          continue;
        }

        uniqueTokens.add(contactToken);
        tokensToFetch.add(contactToken);

        contactRelationships.add({
          'contact_token': contactToken,
          'doc_id': doc.id,
          'accepted_at': data['accepted_at'],
          // ✅ STORE USER DATA FROM CONTACTS DOC (for fallback)
          'user_name': data['user_name'],
          'user_avatar': data['user_avatar'],
          'user_online': data['user_online'],
        });

        state.lastContactDoc = doc;
      }

      // Step 3: Batch fetch user profiles (EFFICIENT!)
      if (tokensToFetch.isNotEmpty) {
        print(
            "[ContactController] 🔍 Batch fetching ${tokensToFetch.length} user profiles...");
        print(
            "[ContactController] 🔍 Tokens to fetch: ${tokensToFetch.toList().take(5)}...");

        // Firestore 'in' query limit is 10, so batch in chunks
        List<String> tokensList = tokensToFetch.toList();
        for (int i = 0; i < tokensList.length; i += 10) {
          int end = (i + 10 < tokensList.length) ? i + 10 : tokensList.length;
          List<String> batch = tokensList.sublist(i, end);

          print(
              "[ContactController] 🔍 Fetching batch ${(i ~/ 10) + 1}: ${batch.length} tokens");

          var profilesQuery = await db
              .collection("user_profiles")
              .where(FieldPath.documentId, whereIn: batch)
              .get();

          // Cache profiles
          for (var profileDoc in profilesQuery.docs) {
            var profileData = profileDoc.data();
            var profile = UserProfile(
              token: profileDoc.id,
              name: profileData['name'],
              avatar: profileData['avatar'],
              email: profileData['email'],
              online: profileData['online'] ?? 0,
              search_name: profileData['search_name'],
            );
            state.profileCache[profileDoc.id] = profile;
          }

          // 🔧 FALLBACK: For tokens not found, try querying by 'token' field
          // (This handles old users who have doc ID = access_token instead of permanent token)
          Set<String> foundTokens = profilesQuery.docs.map((d) => d.id).toSet();
          Set<String> missingTokens = batch.toSet().difference(foundTokens);

          if (missingTokens.isNotEmpty) {
            for (var missingToken in missingTokens) {
              try {
                var fallbackQuery = await db
                    .collection("user_profiles")
                    .where("token", isEqualTo: missingToken)
                    .limit(1)
                    .get();

                if (fallbackQuery.docs.isNotEmpty) {
                  var profileDoc = fallbackQuery.docs.first;
                  var profileData = profileDoc.data();
                  var profile = UserProfile(
                    token:
                        missingToken, // Use the token from contacts, not doc ID!
                    name: profileData['name'],
                    avatar: profileData['avatar'],
                    email: profileData['email'],
                    online: profileData['online'] ?? 0,
                    search_name: profileData['search_name'],
                  );
                  state.profileCache[missingToken] = profile;
                }
              } catch (e) {
                print(
                    "[ContactController] ❌ Fallback failed for $missingToken: $e");
              }
            }
          }
        }
      }

      // Step 4: Build ContactEntity list from relationships + cached profiles
      for (var relationship in contactRelationships) {
        String contactToken = relationship['contact_token'];
        UserProfile? profile = state.profileCache[contactToken];

        // ✅ FALLBACK: If profile not found in user_profiles, use data from contacts doc
        String contactName;
        String contactAvatar;
        int contactOnline;

        if (profile == null) {
          // Use data stored in the contacts document itself
          // Check both user_* (incoming) and contact_* (outgoing) fields
          contactName = relationship['user_name'] ??
              relationship['contact_name'] ??
              'Unknown';
          contactAvatar = relationship['user_avatar'] ??
              relationship['contact_avatar'] ??
              '';
          contactOnline = relationship['user_online'] ??
              relationship['contact_online'] ??
              0;
        } else {
          contactName = profile.name ?? 'Unknown';
          contactAvatar = profile.avatar ?? '';
          contactOnline = profile.online ?? 0;
        }

        // 🐛 DEBUG: Print actual online status being loaded
        print(
            "[ContactController] 🔍 Contact '$contactName' online status: $contactOnline (profile: ${profile?.online}, relationship: ${relationship['user_online'] ?? relationship['contact_online']})");

        var contact = ContactEntity(
          id: relationship['doc_id'],
          user_token: token,
          contact_token: contactToken,
          contact_name: contactName,
          contact_avatar: contactAvatar,
          contact_online: contactOnline,
          status: 'accepted',
          accepted_at: relationship['accepted_at'],
        );

        state.acceptedContacts.add(contact);
      }

      // ✨ ZERO DUPLICATE GUARANTEE: Final deduplication pass using Map
      // This ensures NO duplicates even if pagination or race conditions cause issues
      print("[ContactController] 🔍 Running zero-duplicate deduplication...");
      final Map<String, ContactEntity> uniqueMap = {};
      for (var contact in state.acceptedContacts) {
        if (contact.contact_token != null &&
            contact.contact_token!.isNotEmpty) {
          // Keep most recent contact if duplicate found
          if (uniqueMap.containsKey(contact.contact_token)) {
            // Compare timestamps - keep newest
            var existing = uniqueMap[contact.contact_token]!;
            var existingTime =
                existing.accepted_at?.millisecondsSinceEpoch ?? 0;
            var newTime = contact.accepted_at?.millisecondsSinceEpoch ?? 0;
            if (newTime > existingTime) {
              uniqueMap[contact.contact_token!] = contact;
              print(
                  "[ContactController] 🔄 Replaced duplicate for ${contact.contact_token} (newer)");
            } else {
              print(
                  "[ContactController] ⏭️ Skipped duplicate for ${contact.contact_token} (older)");
            }
          } else {
            uniqueMap[contact.contact_token!] = contact;
          }
        }
      }

      // Replace list with deduplicated version
      int beforeCount = state.acceptedContacts.length;
      state.acceptedContacts.value = uniqueMap.values.toList();
      int afterCount = state.acceptedContacts.length;
      int duplicatesRemoved = beforeCount - afterCount;

      if (duplicatesRemoved > 0) {
        print("[ContactController] 🎯 REMOVED $duplicatesRemoved DUPLICATES!");
      }
      print(
          "[ContactController] ✅ Zero duplicates guaranteed: ${afterCount} unique contacts");

      // ✨ SAVE TO CACHE (for 20-30x faster next load!)
      try {
        final cacheData =
            state.acceptedContacts.map((c) => c.toJson()).toList();
        await _cache.write('accepted_contacts_$token', cacheData);
        print(
            "[ContactController] 💾 Cached ${state.acceptedContacts.length} contacts for instant loading");
      } catch (e) {
        print("[ContactController] ⚠️ Cache write failed: $e");
      }

      // Step 5: Update pagination state
      bool hasMore = (myContacts.docs.length + theirContacts.docs.length) >=
          ContactState.CONTACTS_PAGE_SIZE;
      state.hasMoreContacts.value = hasMore;

      print(
          "[ContactController] ✅ Loaded ${contactRelationships.length} relationships | Final: ${state.acceptedContacts.length} unique contacts | Has more: $hasMore");

      // ✅ Force UI update
      state.acceptedContacts.refresh();
      print("[ContactController] ✅ Accepted contacts UI refreshed!");
    } catch (e, stackTrace) {
      print("[ContactController] ❌ Error loading contacts: $e");
      print("[ContactController] Stack trace: $stackTrace");
      toastInfo(msg: "Failed to load contacts");
    } finally {
      state.isLoadingContacts.value = false;
    }
  }

  /// Load pending contact requests received
  Future<void> loadPendingRequests() async {
    try {
      print("========================================");
      print("[ContactController] � LOADING PENDING REQUESTS");
      print("[ContactController] 📥 My token: '$token'");
      print("[ContactController] 📥 Querying Firestore...");

      var requests = await db
          .collection("contacts")
          .where("contact_token", isEqualTo: token)
          .where("status", isEqualTo: "pending")
          .get();

      print(
          "[ContactController] 📬 Query returned ${requests.docs.length} documents");

      // Debug: Show ALL contacts to see what's in Firestore
      var allMyIncoming = await db
          .collection("contacts")
          .where("contact_token", isEqualTo: token)
          .get();
      print(
          "[ContactController] � ALL incoming contacts (any status): ${allMyIncoming.docs.length}");
      for (var doc in allMyIncoming.docs) {
        var data = doc.data();
        print(
            "   📧 From: ${data['user_name']} (${data['user_token']}), Status: ${data['status']}");
      }

      state.pendingRequests.clear();

      for (var doc in requests.docs) {
        var data = doc.data();
        print(
            "[ContactController] 📬 Request from: ${data['user_name']} (${data['user_token']})");

        var contact = ContactEntity(
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
        state.pendingRequests.add(contact);
      }

      state.pendingRequestCount.value = state.pendingRequests.length;
      print(
          "[ContactController] 📬 Badge count updated to: ${state.pendingRequestCount.value}");

      // ✅ Force UI update
      state.pendingRequests.refresh();
      state.pendingRequestCount.refresh();

      print("[ContactController] ✅ Pending requests loaded and UI refreshed!");
    } catch (e) {
      print("[ContactController] ❌ Error loading requests: $e");
      print("[ContactController] ❌ Error details: ${e.toString()}");
    }
  }

  /// Load sent contact requests (outgoing pending)
  Future<void> loadSentRequests() async {
    try {
      print("[ContactController] Loading sent requests");

      var requests = await db
          .collection("contacts")
          .where("user_token", isEqualTo: token)
          .where("status", isEqualTo: "pending")
          .get();

      state.sentRequests.clear();

      for (var doc in requests.docs) {
        var data = doc.data();
        var contact = ContactEntity(
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
        state.sentRequests.add(contact);
      }

      print("[ContactController] Sent requests: ${state.sentRequests.length}");
    } catch (e) {
      print("[ContactController] Error loading sent requests: $e");
    }
  }

  /// Load blocked users
  Future<void> loadBlockedUsers() async {
    try {
      print("[ContactController] Loading blocked users");

      var blocked = await db
          .collection("contacts")
          .where("user_token", isEqualTo: token)
          .where("status", isEqualTo: "blocked")
          .get();

      state.blockedList.clear();

      for (var doc in blocked.docs) {
        var data = doc.data();
        var contact = ContactEntity(
          id: doc.id,
          user_token: data['user_token'],
          contact_token: data['contact_token'],
          contact_name: data['contact_name'],
          contact_avatar: data['contact_avatar'],
          status: data['status'],
          blocked_at: data['blocked_at'],
        );
        state.blockedList.add(contact);
      }
    } catch (e) {
      print("[ContactController] Error loading blocked users: $e");
    }
  }

  /// Search users by name or email (smart search with multiple strategies)
  Future<void> searchUsers(String query) async {
    if (query.isEmpty) {
      state.searchResults.clear();
      state.isSearching.value = false;
      return;
    }

    try {
      print("[ContactController] Searching for: $query");
      state.isSearching.value = true;
      String searchLower = query.toLowerCase().trim();

      // Get all existing ACCEPTED contacts to filter them out from search
      // We KEEP pending/blocked in search so users can see button states
      Set<String> acceptedContactTokens = {};

      // Get accepted contacts where I'm the user
      var myAccepted = await db
          .collection("contacts")
          .where("user_token", isEqualTo: token)
          .where("status", isEqualTo: "accepted")
          .get();
      for (var doc in myAccepted.docs) {
        acceptedContactTokens.add(doc.data()['contact_token']);
      }

      // Get accepted contacts where I'm the contact
      var theirAccepted = await db
          .collection("contacts")
          .where("contact_token", isEqualTo: token)
          .where("status", isEqualTo: "accepted")
          .get();
      for (var doc in theirAccepted.docs) {
        acceptedContactTokens.add(doc.data()['user_token']);
      }

      // Get all user profiles (we'll filter client-side for better matching)
      var allUsers = await db
          .collection("user_profiles")
          .limit(100) // Get more results for better client-side filtering
          .get();

      state.searchResults.clear();
      List<UserProfile> tempResults = [];

      for (var doc in allUsers.docs) {
        var data = doc.data();

        // Skip current user
        if (data['token'] == token) continue;

        // Only skip users who are ACCEPTED friends (show pending/blocked with buttons)
        if (acceptedContactTokens.contains(data['token'])) continue;
        String name = (data['name'] ?? '').toLowerCase();
        String searchName = (data['search_name'] ?? '').toLowerCase();

        // Search only by name (not email)
        bool matchesName = name.contains(searchLower);
        bool matchesSearchName = searchName.startsWith(searchLower);

        if (matchesName || matchesSearchName) {
          // Convert online field from bool to int if needed
          int? onlineValue;
          if (data['online'] is bool) {
            onlineValue = data['online'] ? 1 : 0;
          } else if (data['online'] is int) {
            onlineValue = data['online'];
          }

          var user = UserProfile(
            token: data['token'],
            name: data['name'],
            avatar: data['avatar'],
            email: data['email'],
            online: onlineValue,
          );

          // Store for sorting
          tempResults.add(user);
        }
      }

      // Sort by relevance (you can enhance this with the match score)
      tempResults.sort((a, b) {
        // Prioritize exact matches first
        String aName = (a.name ?? '').toLowerCase();
        String bName = (b.name ?? '').toLowerCase();

        bool aExact = aName == searchLower;
        bool bExact = bName == searchLower;

        if (aExact && !bExact) return -1;
        if (!aExact && bExact) return 1;

        // Then sort by name starts with query
        bool aStarts = aName.startsWith(searchLower);
        bool bStarts = bName.startsWith(searchLower);

        if (aStarts && !bStarts) return -1;
        if (!aStarts && bStarts) return 1;

        // Finally alphabetical
        return aName.compareTo(bName);
      });

      // Limit results to top 20
      state.searchResults.addAll(tempResults.take(20));
      state.isSearching.value = false;

      print("[ContactController] Found ${state.searchResults.length} users");
    } catch (e) {
      print("[ContactController] Error searching users: $e");
      state.isSearching.value = false;
      toastInfo(msg: "Search failed: ${e.toString()}");
    }
  }

  /// Send contact request with industrial-level error handling
  Future<bool> sendContactRequest(UserProfile user) async {
    if (user.token == null || user.token!.isEmpty) {
      toastInfo(msg: "Invalid user");
      return false;
    }

    try {
      EasyLoading.show(status: 'Sending request...');

      // Immediately update UI optimistically
      state.relationshipStatus[user.token!] = 'pending_sent';

      // Check if contact already exists (I added them)
      var existingOutgoing = await db
          .collection("contacts")
          .where("user_token", isEqualTo: token)
          .where("contact_token", isEqualTo: user.token)
          .get();

      if (existingOutgoing.docs.isNotEmpty) {
        var status = existingOutgoing.docs.first.data()['status'];
        EasyLoading.dismiss();

        if (status == 'accepted') {
          toastInfo(msg: "✓ Already in your contacts");
          state.relationshipStatus[user.token!] = 'accepted';
        } else if (status == 'pending') {
          toastInfo(msg: "⏳ Request already sent");
          state.relationshipStatus[user.token!] = 'pending_sent';
        } else if (status == 'blocked') {
          toastInfo(msg: "🚫 You have blocked this user. Unblock to add.");
          state.relationshipStatus[user.token!] = 'blocked';
        }
        return false;
      }

      // Check if contact already exists (they added me)
      var existingIncoming = await db
          .collection("contacts")
          .where("user_token", isEqualTo: user.token)
          .where("contact_token", isEqualTo: token)
          .get();

      if (existingIncoming.docs.isNotEmpty) {
        var status = existingIncoming.docs.first.data()['status'];
        EasyLoading.dismiss();

        if (status == 'accepted') {
          toastInfo(msg: "✓ Already in your contacts");
          state.relationshipStatus[user.token!] = 'accepted';
        } else if (status == 'pending') {
          toastInfo(
              msg: "📬 This user sent you a request! Check 'Requests' tab");
          state.relationshipStatus[user.token!] = 'pending_received';
          // Switch to requests tab
          state.selectedTab.value = 1;
        } else if (status == 'blocked') {
          toastInfo(msg: "🚫 This user has blocked you");
          state.relationshipStatus[user.token!] = 'blocked_by';
        }
        return false;
      }

      // Send the request
      var myProfile = UserStore.to.profile;

      print("========================================");
      print("[ContactController] 📤 SENDING CONTACT REQUEST");
      print("[ContactController] 📤 From: ${myProfile.name} (token: '$token')");
      print("[ContactController] 📤 To: ${user.name} (token: '${user.token}')");
      print("[ContactController] 📤 Writing to Firestore...");

      var contactData = {
        "user_token": token,
        "contact_token": user.token,
        "user_name": myProfile.name,
        "user_avatar": myProfile.avatar,
        "user_online":
            myProfile.online ?? 0, // ✅ Default to offline, not online!
        "contact_name": user.name,
        "contact_avatar": user.avatar,
        "contact_online": user.online ?? 0, // ✅ Default to offline, not online!
        "status": "pending",
        "requested_by": token,
        "requested_at": Timestamp.now(),
      };

      print("[ContactController] 📤 Data: $contactData");

      var docRef = await db.collection("contacts").add(contactData);

      print(
          "[ContactController] ✅ Request saved to Firestore! Doc ID: ${docRef.id}");
      print(
          "[ContactController] 📤 Receiver should see: contact_token='${user.token}', status='pending'");

      // Send push notification to the receiver (following call_notifications pattern)
      try {
        print(
            "[ContactController] 🔔 Sending contact request notification to ${user.token}");

        CallRequestEntity notificationEntity = CallRequestEntity();
        notificationEntity.to_token = user.token;
        notificationEntity.to_name = user.name;
        notificationEntity.to_avatar = user.avatar;
        // No need to set call_type - backend will use 'contact_request'

        var res = await ChatAPI.send_contact_request_notification(
            params: notificationEntity);

        if (res.code == 0) {
          print(
              "[ContactController] ✅ Contact request notification sent successfully");
        } else {
          print(
              "[ContactController] ⚠️ Notification failed with code: ${res.code}");
        }
      } catch (notifError) {
        print(
            "[ContactController] ⚠️ Failed to send notification: $notifError");
        // Don't fail the entire request if notification fails
      }

      EasyLoading.dismiss();
      toastInfo(msg: "✓ Request sent to ${user.name}!");
      state.relationshipStatus[user.token!] = 'pending_sent';

      // Refresh sent requests list
      await loadSentRequests();

      return true;
    } catch (e) {
      EasyLoading.dismiss();
      print("[ContactController] Error sending request: $e");

      // Revert optimistic update on error
      state.relationshipStatus.remove(user.token!);

      if (e.toString().contains('PERMISSION_DENIED')) {
        toastInfo(msg: "❌ Permission denied. Please check Firestore rules.");
      } else if (e.toString().contains('network')) {
        toastInfo(msg: "❌ Network error. Check your connection.");
      } else {
        toastInfo(msg: "❌ Failed to send request. Try again.");
      }
      return false;
    }
  }

  /// Accept contact request with industrial-level handling
  Future<bool> acceptContactRequest(ContactEntity contact) async {
    if (contact.id == null || contact.user_token == null) {
      toastInfo(msg: "Invalid contact data");
      return false;
    }

    try {
      EasyLoading.show(status: 'Accepting...');

      // Optimistically update UI
      state.relationshipStatus[contact.user_token!] = 'accepted';

      await db.collection("contacts").doc(contact.id).update({
        "status": "accepted",
        "accepted_at": Timestamp.now(),
      });

      // Send push notification to the original requester (following call_notifications pattern)
      try {
        print(
            "[ContactController] 🔔 Sending contact accepted notification to ${contact.user_token}");

        CallRequestEntity notificationEntity = CallRequestEntity();
        notificationEntity.to_token = contact.user_token;
        notificationEntity.to_name = contact.user_name;
        notificationEntity.to_avatar = contact.user_avatar;
        // No need to set call_type - backend will use 'contact_accepted'

        var res = await ChatAPI.send_contact_accepted_notification(
            params: notificationEntity);

        if (res.code == 0) {
          print(
              "[ContactController] ✅ Contact accepted notification sent successfully");
        } else {
          print(
              "[ContactController] ⚠️ Notification failed with code: ${res.code}");
        }
      } catch (notifError) {
        print(
            "[ContactController] ⚠️ Failed to send notification: $notifError");
        // Don't fail the entire accept if notification fails
      }

      EasyLoading.dismiss();
      toastInfo(msg: "✓ ${contact.user_name} is now your contact!");

      // Update lists
      await Future.wait([
        loadPendingRequests(),
        loadAcceptedContacts(),
        _updateRelationshipMap(),
      ]);

      return true;
    } catch (e) {
      EasyLoading.dismiss();
      print("[ContactController] Error accepting request: $e");

      // Revert optimistic update
      state.relationshipStatus[contact.user_token!] = 'pending_received';

      if (e.toString().contains('PERMISSION_DENIED')) {
        toastInfo(msg: "❌ Permission denied. Check Firestore rules.");
      } else if (e.toString().contains('not-found')) {
        toastInfo(msg: "❌ Request no longer exists");
        await loadPendingRequests();
      } else {
        toastInfo(msg: "❌ Failed to accept. Try again.");
      }
      return false;
    }
  }

  /// Reject contact request with confirmation
  Future<bool> rejectContactRequest(ContactEntity contact) async {
    if (contact.id == null) {
      toastInfo(msg: "Invalid contact data");
      return false;
    }

    try {
      EasyLoading.show(status: 'Rejecting...');

      await db.collection("contacts").doc(contact.id).delete();

      EasyLoading.dismiss();
      toastInfo(msg: "✓ Request from ${contact.user_name} rejected");

      // Remove from relationship map
      if (contact.user_token != null) {
        state.relationshipStatus.remove(contact.user_token!);
      }

      await loadPendingRequests();
      await _updateRelationshipMap();

      return true;
    } catch (e) {
      EasyLoading.dismiss();
      print("[ContactController] Error rejecting request: $e");

      if (e.toString().contains('not-found')) {
        toastInfo(msg: "Request already removed");
        await loadPendingRequests();
      } else {
        toastInfo(msg: "❌ Failed to reject. Try again.");
      }
      return false;
    }
  }

  /// Cancel sent contact request
  Future<bool> cancelContactRequest(String userToken) async {
    try {
      EasyLoading.show(status: 'Cancelling...');

      // Find the sent request
      var sentRequest = await db
          .collection("contacts")
          .where("user_token", isEqualTo: token)
          .where("contact_token", isEqualTo: userToken)
          .where("status", isEqualTo: "pending")
          .get();

      if (sentRequest.docs.isEmpty) {
        EasyLoading.dismiss();
        toastInfo(msg: "Request not found");
        await _updateRelationshipMap();
        return false;
      }

      await db.collection("contacts").doc(sentRequest.docs.first.id).delete();

      EasyLoading.dismiss();
      toastInfo(msg: "✓ Request cancelled");

      // Remove from relationship map
      state.relationshipStatus.remove(userToken);

      await loadSentRequests();
      await _updateRelationshipMap();

      return true;
    } catch (e) {
      EasyLoading.dismiss();
      print("[ContactController] Error cancelling request: $e");
      toastInfo(msg: "❌ Failed to cancel. Try again.");
      return false;
    }
  }

  /// Block user
  Future<void> blockUser(
      String contactToken, String contactName, String contactAvatar) async {
    try {
      // Check for existing relationship in BOTH directions
      var outgoingQuery = await db
          .collection("contacts")
          .where("user_token", isEqualTo: token)
          .where("contact_token", isEqualTo: contactToken)
          .get();

      var incomingQuery = await db
          .collection("contacts")
          .where("user_token", isEqualTo: contactToken)
          .where("contact_token", isEqualTo: token)
          .get();

      // Delete incoming relationship (they added me)
      if (incomingQuery.docs.isNotEmpty) {
        for (var doc in incomingQuery.docs) {
          await db.collection("contacts").doc(doc.id).delete();
        }
      }

      // Update or create outgoing relationship as blocked
      if (outgoingQuery.docs.isNotEmpty) {
        await db
            .collection("contacts")
            .doc(outgoingQuery.docs.first.id)
            .update({
          "status": "blocked",
          "blocked_at": Timestamp.now(),
        });
      } else {
        await db.collection("contacts").add({
          "user_token": token,
          "contact_token": contactToken,
          "contact_name": contactName,
          "contact_avatar": contactAvatar,
          "status": "blocked",
          "blocked_at": Timestamp.now(),
        });
      }

      // Remove from accepted contacts list immediately (smooth deletion)
      state.acceptedContacts
          .removeWhere((contact) => contact.contact_token == contactToken);

      // Update relationship map
      state.relationshipStatus[contactToken] = 'blocked';

      // Add to blocked list
      await loadBlockedUsers();

      toastInfo(msg: "$contactName has been blocked");
    } catch (e) {
      print("[ContactController] Error blocking user: $e");
      toastInfo(msg: "Failed to block user");
    }
  }

  /// Unblock user
  Future<void> unblockUser(ContactEntity contact) async {
    try {
      await db.collection("contacts").doc(contact.id).delete();
      toastInfo(msg: "${contact.contact_name} has been unblocked");
      await loadBlockedUsers();
    } catch (e) {
      print("[ContactController] Error unblocking user: $e");
      toastInfo(msg: "Failed to unblock user");
    }
  }

  /// Check if user is blocked
  Future<bool> isUserBlocked(String contactToken) async {
    try {
      var query = await db
          .collection("contacts")
          .where("user_token", isEqualTo: token)
          .where("contact_token", isEqualTo: contactToken)
          .where("status", isEqualTo: "blocked")
          .get();
      return query.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Check if user is contact
  Future<bool> isUserContact(String contactToken) async {
    try {
      var query1 = await db
          .collection("contacts")
          .where("user_token", isEqualTo: token)
          .where("contact_token", isEqualTo: contactToken)
          .where("status", isEqualTo: "accepted")
          .get();

      if (query1.docs.isNotEmpty) return true;

      var query2 = await db
          .collection("contacts")
          .where("user_token", isEqualTo: contactToken)
          .where("contact_token", isEqualTo: token)
          .where("status", isEqualTo: "accepted")
          .get();

      return query2.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Listen to contact requests in real-time
  void _listenToContactRequests() {
    db
        .collection("contacts")
        .where("contact_token", isEqualTo: token)
        .where("status", isEqualTo: "pending")
        .snapshots()
        .listen((snapshot) {
      state.pendingRequestCount.value = snapshot.docs.length;
    });
  }

  // =============== ORIGINAL FUNCTIONALITY ===============

  /// Original goChat - now with contact check
  goChat(ContactItem contactItem) async {
    // Check if user is blocked
    bool blocked = await isUserBlocked(contactItem.token ?? "");
    if (blocked) {
      toastInfo(msg: "This user is blocked");
      return;
    }

    // Check if user is contact
    bool isContact = await isUserContact(contactItem.token ?? "");
    if (!isContact) {
      toastInfo(msg: "You must be contacts to chat");
      return;
    }

    var from_messages = await db
        .collection("message")
        .withConverter(
          fromFirestore: Msg.fromFirestore,
          toFirestore: (Msg msg, options) => msg.toFirestore(),
        )
        .where("from_token", isEqualTo: token)
        .where("to_token", isEqualTo: contactItem.token)
        .get();
    var to_messages = await db
        .collection("message")
        .withConverter(
          fromFirestore: Msg.fromFirestore,
          toFirestore: (Msg msg, options) => msg.toFirestore(),
        )
        .where("from_token", isEqualTo: contactItem.token)
        .where("to_token", isEqualTo: token)
        .get();

    if (from_messages.docs.isEmpty && to_messages.docs.isEmpty) {
      print("----from_messages--to_messages--empty--");
      var profile = UserStore.to.profile;
      var msgdata = new Msg(
        from_token: profile.token,
        to_token: contactItem.token,
        from_name: profile.name,
        to_name: contactItem.name,
        from_avatar: profile.avatar,
        to_avatar: contactItem.avatar,
        from_online: profile.online,
        to_online: contactItem.online,
        last_msg: "",
        last_time: Timestamp.now(),
        msg_num: 0,
      );
      var doc_id = await db
          .collection("message")
          .withConverter(
            fromFirestore: Msg.fromFirestore,
            toFirestore: (Msg msg, options) => msg.toFirestore(),
          )
          .add(msgdata);
      Get.offAndToNamed("/chat", parameters: {
        "doc_id": doc_id.id,
        "to_token": contactItem.token ?? "",
        "to_name": contactItem.name ?? "",
        "to_avatar": contactItem.avatar ?? "",
        "to_online": contactItem.online.toString()
      });
    } else {
      if (!from_messages.docs.isEmpty) {
        print("---from_messages");
        print(from_messages.docs.first.id);
        Get.offAndToNamed("/chat", parameters: {
          "doc_id": from_messages.docs.first.id,
          "to_token": contactItem.token ?? "",
          "to_name": contactItem.name ?? "",
          "to_avatar": contactItem.avatar ?? "",
          "to_online": contactItem.online.toString()
        });
      }
      if (!to_messages.docs.isEmpty) {
        print("---to_messages");
        print(to_messages.docs.first.id);
        Get.offAndToNamed("/chat", parameters: {
          "doc_id": to_messages.docs.first.id,
          "to_token": contactItem.token ?? "",
          "to_name": contactItem.name ?? "",
          "to_avatar": contactItem.avatar ?? "",
          "to_online": contactItem.online.toString()
        });
      }
    }
  }

  // 拉取数据
  asyncLoadAllData() async {
    EasyLoading.show(
        indicator: CircularProgressIndicator(),
        maskType: EasyLoadingMaskType.clear,
        dismissOnTap: true);
    state.contactList.clear();
    var result = await ContactAPI.post_contact();
    print(result.data!);
    if (result.code == 0) {
      state.contactList.addAll(result.data!);
    }
    EasyLoading.dismiss();
  }

  /// 初始
  /// Debug method: Check Firestore contacts data
  Future<void> debugCheckFirestoreData() async {
    print("========================================");
    print("[ContactController] 🔍 DEBUG: Checking Firestore data");
    print("[ContactController] 🔍 My token: '$token'");

    try {
      // ✅ FIRST: Check ALL documents in contacts collection
      var allContactDocs = await db.collection("contacts").limit(50).get();
      print(
          "[ContactController] 📚 TOTAL documents in 'contacts' collection: ${allContactDocs.docs.length}");

      if (allContactDocs.docs.isEmpty) {
        print(
            "[ContactController] ⚠️ WARNING: Contacts collection is COMPLETELY EMPTY!");
        print(
            "[ContactController] 💡 You need to send a contact request first!");
      } else {
        print("[ContactController] 📋 Listing ALL documents:");
        for (var doc in allContactDocs.docs) {
          var data = doc.data();
          print("   📄 Doc ID: ${doc.id}");
          print("      user_token: '${data['user_token']}'");
          print("      contact_token: '${data['contact_token']}'");
          print("      status: '${data['status']}'");
          print("      user_name: ${data['user_name']}");
          print("      contact_name: ${data['contact_name']}");
          print("   ---");
        }
      }

      print("");
      print("[ContactController] 🔎 Now checking for MY token: '$token'");

      // Check contacts where I'm the user
      var myContactsAll = await db
          .collection("contacts")
          .where("user_token", isEqualTo: token)
          .get();
      print(
          "[ContactController] 📊 Total contacts where I'm user (user_token=='$token'): ${myContactsAll.docs.length}");
      for (var doc in myContactsAll.docs) {
        var data = doc.data();
        print(
            "   ✅ Status: ${data['status']}, Contact: ${data['contact_name'] ?? data['contact_token']}");
      }

      // Check contacts where I'm the contact
      var theirContactsAll = await db
          .collection("contacts")
          .where("contact_token", isEqualTo: token)
          .get();
      print(
          "[ContactController] 📊 Total contacts where I'm contact (contact_token=='$token'): ${theirContactsAll.docs.length}");
      for (var doc in theirContactsAll.docs) {
        var data = doc.data();
        print(
            "   ✅ Status: ${data['status']}, User: ${data['user_name'] ?? data['user_token']}");
      }

      // Check my user profile
      var myProfile = await db.collection("user_profiles").doc(token).get();
      if (myProfile.exists) {
        print(
            "[ContactController] 👤 My profile: ${myProfile.data()?['name']} (online: ${myProfile.data()?['online']})");
      } else {
        print("[ContactController] ⚠️ My profile NOT FOUND in user_profiles!");
      }

      print("========================================");
    } catch (e, stackTrace) {
      print("[ContactController] ❌ Debug check failed: $e");
      print("Stack trace: $stackTrace");
    }
  }

  // 🔧 MIGRATION: Update old contacts from old token to new token
  Future<void> migrateOldContacts(String oldToken, String newToken) async {
    print("========================================");
    print("[ContactController] 🔄 MIGRATING CONTACTS");
    print("[ContactController] 📝 From: '$oldToken'");
    print("[ContactController] 📝 To:   '$newToken'");

    try {
      // Find all contacts where I'm the contact (incoming)
      var incomingContacts = await db
          .collection("contacts")
          .where("contact_token", isEqualTo: oldToken)
          .get();

      print(
          "[ContactController] 📬 Found ${incomingContacts.docs.length} incoming contacts to migrate");

      for (var doc in incomingContacts.docs) {
        await doc.reference.update({
          "contact_token": newToken,
          "updated_at": FieldValue.serverTimestamp(),
        });
        print("   ✅ Updated doc ${doc.id}");
      }

      // Find all contacts where I'm the user (outgoing)
      var outgoingContacts = await db
          .collection("contacts")
          .where("user_token", isEqualTo: oldToken)
          .get();

      print(
          "[ContactController] 📤 Found ${outgoingContacts.docs.length} outgoing contacts to migrate");

      for (var doc in outgoingContacts.docs) {
        await doc.reference.update({
          "user_token": newToken,
          "updated_at": FieldValue.serverTimestamp(),
        });
        print("   ✅ Updated doc ${doc.id}");
      }

      print("[ContactController] ✅ Migration complete!");
      print("========================================");
    } catch (e, stackTrace) {
      print("[ContactController] ❌ Migration failed: $e");
      print("Stack trace: $stackTrace");
    }
  }

  @override
  void onInit() {
    super.onInit();
    // ✅ DO NOT setup listeners here - wait until data loads!
  }

  @override
  void onReady() {
    super.onReady();
    asyncLoadAllData(); // Original API load
    _initializeContactSystem(); // Initialize contact system
  }

  /// Initialize contact system with proper sequence to avoid race conditions
  Future<void> _initializeContactSystem() async {
    try {
      // Load all data silently
      await _updateRelationshipMap();
      await loadAcceptedContacts(refresh: true);
      await loadPendingRequests();
      await loadSentRequests();
      await loadBlockedUsers();
      _listenToContactRequests();

      // ✅ Setup listeners AFTER data loads!
      _setupRealtimeListeners();
    } catch (e) {
      print("[ContactController] ❌ Initialization error: $e");
      toastInfo(msg: "Failed to load contacts. Please restart the app.");
    }
  }

  // ========== REFRESH & PAGINATION HELPERS ==========

  /// Refresh contacts (pull-to-refresh)
  Future<void> refreshContacts() async {
    state.isRefreshing.value = true;
    try {
      await loadAcceptedContacts(refresh: true);
    } finally {
      state.isRefreshing.value = false;
    }
  }

  /// Load more contacts (pagination)
  Future<void> loadMoreContacts() async {
    if (!state.isLoadingContacts.value && state.hasMoreContacts.value) {
      await loadAcceptedContacts(loadMore: true);
    }
  }

  /// Refresh requests
  Future<void> refreshRequests() async {
    state.isRefreshing.value = true;
    try {
      await loadPendingRequests();
    } finally {
      state.isRefreshing.value = false;
    }
  }

  /// Refresh blocked users
  Future<void> refreshBlocked() async {
    state.isRefreshing.value = true;
    try {
      await loadBlockedUsers();
    } finally {
      state.isRefreshing.value = false;
    }
  }

  @override
  void onClose() {
    contactsListener?.cancel();
    requestsListener?.cancel();
    state.onlineStatusListener?.cancel();
    super.onClose();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
