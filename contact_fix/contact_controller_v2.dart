import 'package:get/get.dart';
import 'package:sakoa/common/entities/entities.dart';
import 'package:sakoa/common/entities/contact_entity.dart';
import 'package:sakoa/common/store/store.dart';
import 'package:sakoa/common/widgets/toast.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'contact_repository.dart';
import 'state.dart';

/// 🚀 SUPERNOVA-LEVEL CONTACT CONTROLLER
/// Clean, reactive, performant, and delightful!
class ContactControllerV2 extends GetxController {
  final ContactStateV2 state = ContactStateV2();
  final ContactRepository _repo = Get.find<ContactRepository>();
  final db = FirebaseFirestore.instance;
  
  String get token => UserStore.to.profile.token ?? UserStore.to.token;
  
  // ============================================================
  // LIFECYCLE
  // ============================================================
  
  @override
  void onInit() {
    super.onInit();
    
    // Initialize repository
    Get.lazyPut(() => ContactRepository(), fenix: true);
  }
  
  @override
  void onReady() {
    super.onReady();
    
    // Load all data
    _initializeData();
  }
  
  @override
  void onClose() {
    _repo.dispose();
    super.onClose();
  }
  
  // ============================================================
  // INITIALIZATION
  // ============================================================
  
  Future<void> _initializeData() async {
    try {
      state.isInitializing.value = true;
      
      await _repo.initialize();
      
      // Load all lists in parallel
      await Future.wait([
        _loadAcceptedContacts(),
        _loadPendingRequests(),
        _loadSentRequests(),
        _loadBlockedUsers(),
      ]);
      
    } catch (e) {
      print('[ContactController] ❌ Initialization failed: $e');
      toastInfo(msg: 'Failed to load contacts');
    } finally {
      state.isInitializing.value = false;
    }
  }
  
  // ============================================================
  // DATA LOADING (ZERO DUPLICATES!)
  // ============================================================
  
  Future<void> _loadAcceptedContacts({bool forceRefresh = false}) async {
    if (state.isLoadingContacts.value && !forceRefresh) return;
    
    try {
      state.isLoadingContacts.value = true;
      
      final contacts = await _repo.loadAcceptedContacts(
        forceRefresh: forceRefresh,
      );
      
      state.acceptedContacts.value = contacts;
      
      // Update filtered list
      _applyFilters();
      
      print('[ContactController] ✅ Loaded ${contacts.length} unique contacts');
    } catch (e) {
      print('[ContactController] ❌ Error loading contacts: $e');
    } finally {
      state.isLoadingContacts.value = false;
    }
  }
  
  Future<void> _loadPendingRequests({bool forceRefresh = false}) async {
    try {
      final requests = await _repo.loadPendingRequests(
        forceRefresh: forceRefresh,
      );
      
      state.pendingRequests.value = requests;
      state.pendingRequestCount.value = requests.length;
      
      print('[ContactController] 📬 Loaded ${requests.length} pending requests');
    } catch (e) {
      print('[ContactController] ❌ Error loading requests: $e');
    }
  }
  
  Future<void> _loadSentRequests({bool forceRefresh = false}) async {
    try {
      final requests = await _repo.loadSentRequests(
        forceRefresh: forceRefresh,
      );
      
      state.sentRequests.value = requests;
      
      print('[ContactController] 📤 Loaded ${requests.length} sent requests');
    } catch (e) {
      print('[ContactController] ❌ Error loading sent requests: $e');
    }
  }
  
  Future<void> _loadBlockedUsers({bool forceRefresh = false}) async {
    try {
      final blocked = await _repo.loadBlockedUsers(
        forceRefresh: forceRefresh,
      );
      
      state.blockedList.value = blocked;
      
      print('[ContactController] 🚫 Loaded ${blocked.length} blocked users');
    } catch (e) {
      print('[ContactController] ❌ Error loading blocked users: $e');
    }
  }
  
  // ============================================================
  // REFRESH ACTIONS (PULL-TO-REFRESH)
  // ============================================================
  
  Future<void> refreshContacts() async {
    state.isRefreshing.value = true;
    try {
      await _loadAcceptedContacts(forceRefresh: true);
    } finally {
      state.isRefreshing.value = false;
    }
  }
  
  Future<void> refreshRequests() async {
    state.isRefreshing.value = true;
    try {
      await _loadPendingRequests(forceRefresh: true);
    } finally {
      state.isRefreshing.value = false;
    }
  }
  
  Future<void> refreshBlocked() async {
    state.isRefreshing.value = true;
    try {
      await _loadBlockedUsers(forceRefresh: true);
    } finally {
      state.isRefreshing.value = false;
    }
  }
  
  Future<void> refreshAll() async {
    state.isRefreshing.value = true;
    try {
      await Future.wait([
        _loadAcceptedContacts(forceRefresh: true),
        _loadPendingRequests(forceRefresh: true),
        _loadSentRequests(forceRefresh: true),
        _loadBlockedUsers(forceRefresh: true),
      ]);
      toastInfo(msg: '✓ Refreshed');
    } finally {
      state.isRefreshing.value = false;
    }
  }
  
  // ============================================================
  // SEARCH & FILTER
  // ============================================================
  
  Future<void> searchUsers(String query) async {
    if (query.isEmpty) {
      state.searchResults.clear();
      state.isSearching.value = false;
      return;
    }
    
    try {
      state.isSearching.value = true;
      state.searchQuery.value = query;
      
      final users = await _repo.searchUsers(query);
      
      // Get relationship status for each user
      for (var user in users) {
        if (user.token != null) {
          final status = await _repo.getRelationshipStatus(user.token!);
          state.relationshipStatus[user.token!] = status;
        }
      }
      
      state.searchResults.value = users;
      
    } catch (e) {
      print('[ContactController] ❌ Search error: $e');
      toastInfo(msg: 'Search failed');
    } finally {
      state.isSearching.value = false;
    }
  }
  
  void clearSearch() {
    state.searchQuery.value = '';
    state.searchResults.clear();
    state.isSearching.value = false;
  }
  
  /// Apply filters to contact list
  void _applyFilters() {
    var filtered = state.acceptedContacts.toList();
    
    // Filter by online status
    if (state.filterOnlineOnly.value) {
      filtered = filtered.where((c) => (c.contact_online ?? 0) == 1).toList();
    }
    
    // Sort
    switch (state.sortBy.value) {
      case ContactSortBy.name:
        filtered.sort((a, b) {
          final aName = a.contact_name?.toLowerCase() ?? '';
          final bName = b.contact_name?.toLowerCase() ?? '';
          return aName.compareTo(bName);
        });
        break;
      case ContactSortBy.recentlyAdded:
        filtered.sort((a, b) {
          final aTime = a.accepted_at ?? Timestamp.now();
          final bTime = b.accepted_at ?? Timestamp.now();
          return bTime.compareTo(aTime);
        });
        break;
      case ContactSortBy.onlineFirst:
        filtered.sort((a, b) {
          final aOnline = a.contact_online ?? 0;
          final bOnline = b.contact_online ?? 0;
          if (aOnline != bOnline) return bOnline.compareTo(aOnline);
          
          final aName = a.contact_name?.toLowerCase() ?? '';
          final bName = b.contact_name?.toLowerCase() ?? '';
          return aName.compareTo(bName);
        });
        break;
    }
    
    state.filteredContacts.value = filtered;
  }
  
  void toggleOnlineFilter() {
    state.filterOnlineOnly.value = !state.filterOnlineOnly.value;
    _applyFilters();
  }
  
  void changeSortBy(ContactSortBy sortBy) {
    state.sortBy.value = sortBy;
    _applyFilters();
  }
  
  // ============================================================
  // CONTACT OPERATIONS
  // ============================================================
  
  Future<void> sendContactRequest(UserProfile user) async {
    try {
      EasyLoading.show(status: 'Sending...');
      
      final result = await _repo.sendContactRequest(user);
      
      if (result.success) {
        toastInfo(msg: result.message);
        
        // Update relationship status
        if (user.token != null) {
          state.relationshipStatus[user.token!] = 'pending_sent';
        }
        
        await _loadSentRequests(forceRefresh: true);
      } else {
        toastInfo(msg: result.message);
        
        // Update relationship status from server
        if (user.token != null) {
          final status = await _repo.getRelationshipStatus(user.token!);
          if (status != null) {
            state.relationshipStatus[user.token!] = status;
          }
        }
      }
    } finally {
      EasyLoading.dismiss();
    }
  }
  
  Future<void> acceptContactRequest(ContactEntity contact) async {
    try {
      EasyLoading.show(status: 'Accepting...');
      
      final result = await _repo.acceptContactRequest(contact);
      
      toastInfo(msg: result.message);
      
      if (result.success) {
        // Optimistic update
        if (contact.user_token != null) {
          state.relationshipStatus[contact.user_token!] = 'accepted';
        }
        
        await Future.wait([
          _loadAcceptedContacts(forceRefresh: true),
          _loadPendingRequests(forceRefresh: true),
        ]);
      }
    } finally {
      EasyLoading.dismiss();
    }
  }
  
  Future<void> rejectContactRequest(ContactEntity contact) async {
    try {
      EasyLoading.show(status: 'Rejecting...');
      
      final result = await _repo.rejectContactRequest(contact);
      
      toastInfo(msg: result.message);
      
      if (result.success) {
        // Remove from relationship map
        if (contact.user_token != null) {
          state.relationshipStatus.remove(contact.user_token!);
        }
        
        await _loadPendingRequests(forceRefresh: true);
      }
    } finally {
      EasyLoading.dismiss();
    }
  }
  
  Future<void> cancelContactRequest(String contactToken) async {
    try {
      EasyLoading.show(status: 'Cancelling...');
      
      final result = await _repo.cancelContactRequest(contactToken);
      
      toastInfo(msg: result.message);
      
      if (result.success) {
        state.relationshipStatus.remove(contactToken);
        await _loadSentRequests(forceRefresh: true);
      }
    } finally {
      EasyLoading.dismiss();
    }
  }
  
  Future<void> blockUser(
    String contactToken,
    String contactName,
    String contactAvatar,
  ) async {
    try {
      EasyLoading.show(status: 'Blocking...');
      
      final result = await _repo.blockUser(
        contactToken,
        contactName,
        contactAvatar,
      );
      
      toastInfo(msg: result.message);
      
      if (result.success) {
        state.relationshipStatus[contactToken] = 'blocked';
        
        // Remove from accepted contacts immediately (smooth UX)
        state.acceptedContacts.removeWhere(
          (c) => c.contact_token == contactToken,
        );
        _applyFilters();
        
        await Future.wait([
          _loadAcceptedContacts(forceRefresh: true),
          _loadBlockedUsers(forceRefresh: true),
        ]);
      }
    } finally {
      EasyLoading.dismiss();
    }
  }
  
  Future<void> unblockUser(ContactEntity contact) async {
    try {
      EasyLoading.show(status: 'Unblocking...');
      
      final result = await _repo.unblockUser(contact);
      
      toastInfo(msg: result.message);
      
      if (result.success) {
        if (contact.contact_token != null) {
          state.relationshipStatus.remove(contact.contact_token!);
        }
        
        await _loadBlockedUsers(forceRefresh: true);
      }
    } finally {
      EasyLoading.dismiss();
    }
  }
  
  // ============================================================
  // NAVIGATION
  // ============================================================
  
  Future<void> goChat(ContactItem contactItem) async {
    try {
      // Check if blocked
      final status = await _repo.getRelationshipStatus(contactItem.token ?? "");
      
      if (status == 'blocked') {
        toastInfo(msg: "This user is blocked");
        return;
      }
      
      if (status != 'accepted') {
        toastInfo(msg: "You must be contacts to chat");
        return;
      }
      
      // Find or create message document
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
        var msgdata = Msg(
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
        String docId = from_messages.docs.isNotEmpty
            ? from_messages.docs.first.id
            : to_messages.docs.first.id;
        
        Get.offAndToNamed("/chat", parameters: {
          "doc_id": docId,
          "to_token": contactItem.token ?? "",
          "to_name": contactItem.name ?? "",
          "to_avatar": contactItem.avatar ?? "",
          "to_online": contactItem.online.toString()
        });
      }
    } catch (e) {
      print('[ContactController] ❌ Error navigating to chat: $e');
      toastInfo(msg: 'Failed to open chat');
    }
  }
  
  // ============================================================
  // UI HELPERS
  // ============================================================
  
  Map<String, dynamic> getButtonConfig(String? userToken) {
    if (userToken == null) {
      return _defaultButtonConfig();
    }
    
    final status = state.relationshipStatus[userToken];
    
    switch (status) {
      case 'accepted':
        return {
          'text': 'Friends',
          'icon': 'check_circle',
          'color': 'green',
          'enabled': false,
        };
      case 'pending':
      case 'pending_sent':
        return {
          'text': 'Pending',
          'icon': 'hourglass_empty',
          'color': 'orange',
          'enabled': true,
          'action': 'cancel',
        };
      case 'pending_received':
        return {
          'text': 'Respond',
          'icon': 'mail',
          'color': 'blue',
          'enabled': true,
          'action': 'view_requests',
        };
      case 'blocked':
        return {
          'text': 'Blocked',
          'icon': 'block',
          'color': 'red',
          'enabled': false,
        };
      default:
        return _defaultButtonConfig();
    }
  }
  
  Map<String, dynamic> _defaultButtonConfig() {
    return {
      'text': 'Add',
      'icon': 'person_add',
      'color': 'blue',
      'enabled': true,
      'action': 'add',
    };
  }
  
  void switchTab(int index) {
    state.selectedTab.value = index;
  }
}
