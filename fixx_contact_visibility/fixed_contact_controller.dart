import 'dart:convert';

import 'package:sakoa/common/apis/apis.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
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
  
  // CRITICAL: Use access_token, not profile.token!
  final token = UserStore.to.token;

  // Real-time listeners
  var contactsListener;
  var requestsListener;
  var onlineStatusListener;

  @override
  void onInit() {
    super.onInit();
    print("[ContactController] 🚀 Initializing with token: $token");
  }

  @override
  void onReady() {
    super.onReady();
    print("[ContactController] 🎬 onReady - Starting data load");
    
    // Load data in sequence to avoid race conditions
    _initializeData();
  }

  /// Initialize all data in proper sequence
  Future<void> _initializeData() async {
    try {
      print("[ContactController] 📊 Step 1: Building relationship map");
      await _updateRelationshipMap();
      
      print("[ContactController] 📊 Step 2: Loading accepted contacts");
      await loadAcceptedContacts(refresh: true);
      
      print("[ContactController] 📊 Step 3: Loading pending requests");
      await loadPendingRequests();
      
      print("[ContactController] 📊 Step 4: Loading sent requests");
      await loadSentRequests();
      
      print("[ContactController] 📊 Step 5: Loading blocked users");
      await loadBlockedUsers();
      
      print("[ContactController] 📊 Step 6: Setting up real-time listeners");
      _setupRealtimeListeners();
      
      print("[ContactController] ✅ Initialization complete!");
      print("[ContactController] 📈 Stats:");
      print("   - Accepted Contacts: ${state.acceptedContacts.length}");
      print("   - Pending Requests: ${state.pendingRequests.length}");
      print("   - Sent Requests: ${state.sentRequests.length}");
      print("   - Blocked Users: ${state.blockedList.length}");
      
    } catch (e, stackTrace) {
      print("[ContactController] ❌ Initialization error: $e");
      print("[ContactController] Stack: $stackTrace");
      toastInfo(msg: "Failed to load contacts. Please restart the app.");
    }
  }

  /// Setup real-time Firestore listeners for instant updates
  void _setupRealtimeListeners() {
    print("[ContactController] 🔥 Setting up real-time listeners");

    // Listen to contacts where I'm the user (outgoing)
    contactsListener = db
        .collection("contacts")
        .where("user_token", isEqualTo: token)
        .snapshots()
        .listen((snapshot) {
      print("[ContactController] 🔥 Outgoing contacts changed! Count: ${snapshot.docs.length}");
      _handleContactsUpdate();
    }, onError: (error) {
      print("[ContactController] ❌ Error in contacts listener: $error");
    });

    // Listen to contacts where I'm the contact (incoming requests)
    requestsListener = db
        .collection("contacts")
        .where("contact_token", isEqualTo: token)
        .snapshots()
        .listen((snapshot) {
      print("[ContactController] 🔥 Incoming requests changed! Count: ${snapshot.docs.length}");
      _handleRequestsUpdate();
    }, onError: (error) {
      print("[ContactController] ❌ Error in requests listener: $error");
    });

    // Listen to online status changes
    _setupOnlineStatusListener();
  }

  /// Handle real-time contact updates
  Future<void> _handleContactsUpdate() async {
    print("[ContactController] 🔄 Handling contacts update");
    await _updateRelationshipMap();
    await loadAcceptedContacts(refresh: true);
    await loadSentRequests();
    await loadBlockedUsers();
  }

  /// Handle real-time request updates
  Future<void> _handleRequestsUpdate() async {
    print("[ContactController] 🔄 Handling requests update");
    await _updateRelationshipMap();
    await loadPendingRequests();
  }

  /// Listen to online status changes for contacts in real-time
  void _setupOnlineStatusListener() {
    onlineStatusListener = db
        .collection("user_profiles")
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.modified) {
          String userToken = change.doc.id;
          var data = change.doc.data();

          if (state.profileCache.containsKey(userToken) && data != null) {
            int newOnlineStatus = data['online'] ?? 0;
            int oldOnlineStatus = state.profileCache[userToken]?.online ?? 0;

            if (newOnlineStatus != oldOnlineStatus) {
              print("[ContactController] 🟢 Online status changed for $userToken: $oldOnlineStatus → $newOnlineStatus");
              
              state.profileCache[userToken]?.online = newOnlineStatus;

              // Update contacts list
              for (int i = 0; i < state.acceptedContacts.length; i++) {
                if (state.acceptedContacts[i].contact_token == userToken) {
                  state.acceptedContacts[i].contact_online = newOnlineStatus;
                  state.acceptedContacts.refresh();
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

  /// Build relationship status map for quick lookups
  Future<void> _updateRelationshipMap() async {
    try {
      print("[ContactController] 🗺️ Building relationship map");
      state.relationshipStatus.clear();
      Map<String, Map<String, dynamic>> relationships = {};

      // Get all my outgoing contacts
      var myContacts = await db
          .collection("contacts")
          .where("user_token", isEqualTo: token)
          .get();

      print("[ContactController] 📤 Found ${myContacts.docs.length} outgoing contacts");

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

      print("[ContactController] 📥 Found ${theirContacts.docs.length} incoming contacts");

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

      // Analyze relationships and set proper status
      for (var entry in relationships.entries) {
        String userToken = entry.key;
        String? outgoing = entry.value['outgoing'];
        String? incoming = entry.value['incoming'];

        if (outgoing == 'pending' && incoming == 'pending') {
          state.relationshipStatus[userToken] = 'pending_mutual';
          _autoAcceptMutualRequest(entry.value['doc_id'], entry.value['incoming_doc_id']);
        } else if (outgoing == 'accepted' || incoming == 'accepted') {
          state.relationshipStatus[userToken] = 'accepted';
        } else if (outgoing == 'pending') {
          state.relationshipStatus[userToken] = 'pending_sent';
        } else if (incoming == 'pending') {
          state.relationshipStatus[userToken] = 'pending_received';
        } else if (outgoing == 'blocked') {
          state.relationshipStatus[userToken] = 'blocked';
        } else if (incoming == 'blocked') {
          state.relationshipStatus[userToken] = 'blocked_by';
        }
      }

      print("[ContactController] ✅ Relationship map updated: ${state.relationshipStatus.length} relationships");
    } catch (e, stackTrace) {
      print("[ContactController] ❌ Error updating relationship map: $e");
      print("[ContactController] Stack: $stackTrace");
    }
  }

  /// Auto-accept mutual pending requests
  Future<void> _autoAcceptMutualRequest(String myDocId, String theirDocId) async {
    try {
      print("[ContactController] 🤝 Auto-accepting mutual request");

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

      await Future.wait([
        loadAcceptedContacts(refresh: true),
        loadPendingRequests(),
        loadSentRequests(),
      ]);
    } catch (e) {
      print("[ContactController] ❌ Error auto-accepting mutual request: $e");
    }
  }

  /// Get relationship status for a user
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
          'enabled': true,
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

  /// Load accepted contacts - SIMPLIFIED VERSION
  Future<void> loadAcceptedContacts({bool refresh = false, bool loadMore = false}) async {
    if (state.isLoadingContacts.value) {
      print("[ContactController] ⏸️ Already loading contacts");
      return;
    }

    if (loadMore && !state.hasMoreContacts.value) {
      print("[ContactController] 📭 No more contacts to load");
      return;
    }

    try {
      state.isLoadingContacts.value = true;
      
      if (refresh) {
        print("[ContactController] 🔄 REFRESH: Clearing and reloading");
        state.acceptedContacts.clear();
        state.lastContactDoc = null;
        state.hasMoreContacts.value = true;
      }

      print("[ContactController] 📥 Loading accepted contacts for token: $token");

      // Step 1: Get contact relationships
      Set<String> contactTokens = {};
      DocumentSnapshot? lastDoc;

      // Query outgoing accepted contacts (simpler query without compound index)
      var myContactsQuery = await db
          .collection("contacts")
          .where("user_token", isEqualTo: token)
          .where("status", isEqualTo: "accepted")
          .limit(50) // Load more at once for better UX
          .get();

      print("[ContactController] 📤 Found ${myContactsQuery.docs.length} outgoing accepted");

      for (var doc in myContactsQuery.docs) {
        var data = doc.data();
        String? contactToken = data['contact_token'];
        if (contactToken != null && contactToken.isNotEmpty) {
          contactTokens.add(contactToken);
          lastDoc = doc;
        }
      }

      // Query incoming accepted contacts (simpler query without compound index)
      var theirContactsQuery = await db
          .collection("contacts")
          .where("contact_token", isEqualTo: token)
          .where("status", isEqualTo: "accepted")
          .limit(50)
          .get();

      print("[ContactController] 📥 Found ${theirContactsQuery.docs.length} incoming accepted");

      for (var doc in theirContactsQuery.docs) {
        var data = doc.data();
        String? userToken = data['user_token'];
        if (userToken != null && userToken.isNotEmpty) {
          contactTokens.add(userToken);
          lastDoc = doc;
        }
      }

      print("[ContactController] 👥 Total unique contact tokens: ${contactTokens.length}");

      if (contactTokens.isEmpty) {
        print("[ContactController] ⚠️ No contacts found!");
        state.hasMoreContacts.value = false;
        return;
      }

      // Step 2: Batch fetch user profiles
      List<String> tokensList = contactTokens.toList();
      for (int i = 0; i < tokensList.length; i += 10) {
        int end = (i + 10 < tokensList.length) ? i + 10 : tokensList.length;
        List<String> batch = tokensList.sublist(i, end);

        print("[ContactController] 🔍 Fetching batch ${(i ~/ 10) + 1}: ${batch.length} profiles");

        var profilesQuery = await db
            .collection("user_profiles")
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        print("[ContactController] 📦 Got ${profilesQuery.docs.length} profiles from batch");

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
      }

      print("[ContactController] 💾 Cached ${state.profileCache.length} profiles");

      // Step 3: Build ContactEntity list
      for (String contactToken in contactTokens) {
        UserProfile? profile = state.profileCache[contactToken];

        if (profile == null) {
          print("[ContactController] ⚠️ Profile not found for $contactToken");
          continue;
        }

        var contact = ContactEntity(
          id: "", // We don't need doc ID for display
          user_token: token,
          contact_token: contactToken,
          contact_name: profile.name,
          contact_avatar: profile.avatar,
          contact_online: profile.online ?? 0,
          status: 'accepted',
        );

        state.acceptedContacts.add(contact);
      }

      state.lastContactDoc = lastDoc;
      state.hasMoreContacts.value = false; // Disable pagination for simplicity

      print("[ContactController] ✅ Loaded ${state.acceptedContacts.length} contacts successfully");
      
      // Force UI update
      state.acceptedContacts.refresh();

    } catch (e, stackTrace) {
      print("[ContactController] ❌ Error loading contacts: $e");
      print("[ContactController] Stack: $stackTrace");
      toastInfo(msg: "Failed to load contacts: ${e.toString()}");
    } finally {
      state.isLoadingContacts.value = false;
    }
  }

  /// Load pending contact requests received - FIXED
  Future<void> loadPendingRequests() async {
    try {
      print("========================================");
      print("[ContactController] 📬 LOADING PENDING REQUESTS");
      print("[ContactController] 📥 My token: '$token'");

      var requests = await db
          .collection("contacts")
          .where("contact_token", isEqualTo: token)
          .where("status", isEqualTo: "pending")
          .get();

      print("[ContactController] 📬 Query returned ${requests.docs.length} pending requests");

      state.pendingRequests.clear();

      for (var doc in requests.docs) {
        var data = doc.data();
        print("[ContactController] 📬 Request from: ${data['user_name']} (${data['user_token']})");

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
      print("[ContactController] 📬 Badge count updated to: ${state.pendingRequestCount.value}");
      
      // Force UI update
      state.pendingRequests.refresh();
      state.pendingRequestCount.refresh();

    } catch (e, stackTrace) {
      print("[ContactController] ❌ Error loading requests: $e");
      print("[ContactController] Stack: $stackTrace");
    }
  }

  /// Load sent contact requests
  Future<void> loadSentRequests() async {
    try {
      print("[ContactController] 📤 Loading sent requests");

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

      print("[ContactController] 📤 Sent requests: ${state.sentRequests.length}");
    } catch (e) {
      print("[ContactController] ❌ Error loading sent requests: $e");
    }
  }

  /// Load blocked users
  Future<void> loadBlockedUsers() async {
    try {
      print("[ContactController] 🚫 Loading blocked users");

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

      print("[ContactController] 🚫 Blocked users: ${state.blockedList.length}");
    } catch (e) {
      print("[ContactController] ❌ Error loading blocked users: $e");
    }
  }

  /// Search users by name or email
  Future<void> searchUsers(String query) async {
    if (query.isEmpty) {
      state.searchResults.clear();
      state.isSearching.value = false;
      return;
    }

    try {
      print("[ContactController] 🔍 Searching for: $query");
      state.isSearching.value = true;
      String searchLower = query.toLowerCase().trim();

      // Get accepted contacts to filter them out
      Set<String> acceptedContactTokens = {};

      var myAccepted = await db
          .collection("contacts")
          .where("user_token", isEqualTo: token)
          .where("status", isEqualTo: "accepted")
          .get();
      
      for (var doc in myAccepted.docs) {
        acceptedContactTokens.add(doc.data()['contact_token']);
      }

      var theirAccepted = await db
          .collection("contacts")
          .where("contact_token", isEqualTo: token)
          .where("status", isEqualTo: "accepted")
          .get();
      
      for (var doc in theirAccepted.docs) {
        acceptedContactTokens.add(doc.data()['user_token']);
      }

      // Get all user profiles
      var allUsers = await db
          .collection("user_profiles")
          .limit(100)
          .get();

      state.searchResults.clear();
      List<UserProfile> tempResults = [];

      for (var doc in allUsers.docs) {
        var data = doc.data();

        if (data['token'] == token) continue;
        if (acceptedContactTokens.contains(data['token'])) continue;

        String name = (data['name'] ?? '').toLowerCase();
        String searchName = (data['search_name'] ?? '').toLowerCase();

        bool matchesName = name.contains(searchLower);
        bool matchesSearchName = searchName.startsWith(searchLower);

        if (matchesName || matchesSearchName) {
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

          tempResults.add(user);
        }
      }

      // Sort by relevance
      tempResults.sort((a, b) {
        String aName = (a.name ?? '').toLowerCase();
        String bName = (b.name ?? '').toLowerCase();

        bool aExact = aName == searchLower;
        bool bExact = bName == searchLower;

        if (aExact && !bExact) return -1;
        if (!aExact && bExact) return 1;

        bool aStarts = aName.startsWith(searchLower);
        bool bStarts = bName.startsWith(searchLower);

        if (aStarts && !bStarts) return -1;
        if (!aStarts && bStarts) return 1;

        return aName.compareTo(bName);
      });

      state.searchResults.addAll(tempResults.take(20));
      state.isSearching.value = false;

      print("[ContactController] 🔍 Found ${state.searchResults.length} users");
    } catch (e) {
      print("[ContactController] ❌ Error searching users: $e");
      state.isSearching.value = false;
      toastInfo(msg: "Search failed: ${e.toString()}");
    }
  }

  /// Send contact request
  Future<bool> sendContactRequest(UserProfile user) async {
    if (user.token == null || user.token!.isEmpty) {
      toastInfo(msg: "Invalid user");
      return false;
    }

    try {
      EasyLoading.show(status: 'Sending request...');

      state.relationshipStatus[user.token!] = 'pending_sent';

      // Check if contact already exists
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
          toastInfo(msg: "🚫 You have blocked this user");
          state.relationshipStatus[user.token!] = 'blocked';
        }
        return false;
      }

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
          toastInfo(msg: "📬 This user sent you a request! Check 'Requests' tab");
          state.relationshipStatus[user.token!] = 'pending_received';
          state.selectedTab.value = 1;
        } else if (status == 'blocked') {
          toastInfo(msg: "🚫 This user has blocked you");
          state.relationshipStatus[user.token!] = 'blocked_by';
        }
        return false;
      }

      // Send the request
      var myProfile = UserStore.to.profile;

      var contactData = {
        "user_token": token,
        "contact_token": user.token,
        "user_name": myProfile.name,
        "user_avatar": myProfile.avatar,
        "user_online": myProfile.online ?? 1,
        "contact_name": user.name,
        "contact_avatar": user.avatar,
        "contact_online": user.online ?? 1,
        "status": "pending",
        "requested_by": token,
        "requested_at": Timestamp.now(),
      };

      await db.collection("contacts").add(contactData);

      EasyLoading.dismiss();
      toastInfo(msg: "✓ Request sent to ${user.name}!");
      state.relationshipStatus[user.token!] = 'pending_sent';

      await loadSentRequests();

      return true;
    } catch (e) {
      EasyLoading.dismiss();
      print("[ContactController] ❌ Error sending request: $e");

      state.relationshipStatus.remove(user.token!);

      if (e.toString().contains('PERMISSION_DENIED')) {
        toastInfo(msg: "❌ Permission denied. Check Firestore rules.");
      } else if (e.toString().contains('network')) {
        toastInfo(msg: "❌ Network error. Check your connection.");
      } else {
        toastInfo(msg: "❌ Failed to send request. Try again.");
      }
      return false;
    }
  }

  /// Accept contact request
  Future<bool> acceptContactRequest(ContactEntity contact) async {
    if (contact.id == null || contact.user_token == null) {
      toastInfo(msg: "Invalid contact data");
      return false;
    }

    try {
      EasyLoading.show(status: 'Accepting...');

      state.relationshipStatus[contact.user_token!] = 'accepted';

      await db.collection("contacts").doc(contact.id).update({
        "status": "accepted",
        "accepted_at": Timestamp.now(),
      });

      EasyLoading.dismiss();
      toastInfo(msg: "✓ ${contact.user_name} is now your contact!");

      await Future.wait([
        loadPendingRequests(),
        loadAcceptedContacts(refresh: true),
        _updateRelationshipMap(),
      ]);

      return true;
    } catch (e) {
      EasyLoading.dismiss();
      print("[ContactController] ❌ Error accepting request: $e");

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

  /// Reject contact request
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

      if (contact.user_token != null) {
        state.relationshipStatus.remove(contact.user_token!);
      }

      await loadPendingRequests();
      await _updateRelationshipMap();

      return true;
    } catch (e) {
      EasyLoading.dismiss();
      print("[ContactController] ❌ Error rejecting request: $e");

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

      state.relationshipStatus.remove(userToken);

      await loadSentRequests();
      await _updateRelationshipMap();

      return true;
    } catch (e) {
      EasyLoading.dismiss();
      print("[ContactController] ❌ Error cancelling request: $e");
      toastInfo(msg: "❌ Failed to cancel. Try again.");
      return false;
    }
  }

  /// Block user
  Future<void> blockUser(String contactToken, String contactName, String contactAvatar) async {
    try {
      var existingQuery = await db
          .collection("contacts")
          .where("user_token", isEqualTo: token)
          .where("contact_token", isEqualTo: contactToken)
          .get();

      if (existingQuery.docs.isNotEmpty) {
        await db.collection("contacts").doc(existingQuery.docs.first.id).update({
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

      toastInfo(msg: "$contactName has been blocked");
      await loadBlockedUsers();
      await loadAcceptedContacts(refresh: true);
    } catch (e) {
      print("[ContactController] ❌ Error blocking user: $e");
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
      print("[ContactController] ❌ Error unblocking user: $e");
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

  /// Navigate to chat (original functionality)
  goChat(ContactItem contactItem) async {
    bool blocked = await isUserBlocked(contactItem.token ?? "");
    if (blocked) {
      toastInfo(msg: "This user is blocked");
      return;
    }

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
        Get.offAndToNamed("/chat", parameters: {
          "doc_id": from_messages.docs.first.id,
          "to_token": contactItem.token ?? "",
          "to_name": contactItem.name ?? "",
          "to_avatar": contactItem.avatar ?? "",
          "to_online": contactItem.online.toString()
        });
      }
      if (!to_messages.docs.isEmpty) {
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

  /// Refresh methods for pull-to-refresh
  Future<void> refreshContacts() async {
    state.isRefreshing.value = true;
    try {
      await loadAcceptedContacts(refresh: true);
    } finally {
      state.isRefreshing.value = false;
    }
  }

  Future<void> refreshRequests() async {
    state.isRefreshing.value = true;
    try {
      await loadPendingRequests();
    } finally {
      state.isRefreshing.value = false;
    }
  }

  Future<void> refreshBlocked() async {
    state.isRefreshing.value = true;
    try {
      await loadBlockedUsers();
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

  /// Original API load (backward compatibility)
  asyncLoadAllData() async {
    EasyLoading.show(
        indicator: CircularProgressIndicator(),
        maskType: EasyLoadingMaskType.clear,
        dismissOnTap: true);
    state.contactList.clear();
    var result = await ContactAPI.post_contact();
    if (result.code == 0) {
      state.contactList.addAll(result.data!);
    }
    EasyLoading.dismiss();
  }

  @override
  void onClose() {
    contactsListener?.cancel();
    requestsListener?.cancel();
    onlineStatusListener?.cancel();
    super.onClose();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
