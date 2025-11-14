import 'package:sakoa/common/entities/entities.dart';
import 'package:sakoa/common/entities/contact_entity.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ContactState {
  var count = 0.obs;

  // Original contact list (for backward compatibility)
  RxList<ContactItem> contactList = <ContactItem>[].obs;

  // New contact management lists
  RxList<ContactEntity> acceptedContacts = <ContactEntity>[].obs;
  RxList<ContactEntity> pendingRequests = <ContactEntity>[].obs;
  RxList<ContactEntity> sentRequests = <ContactEntity>[].obs;
  RxList<ContactEntity> blockedList = <ContactEntity>[].obs;
  RxList<UserProfile> searchResults = <UserProfile>[].obs;

  // UI state
  RxInt pendingRequestCount = 0.obs;
  RxBool isSearching = false.obs;
  RxString searchQuery = ''.obs;
  RxInt selectedTab = 0.obs; // 0=Contacts, 1=Requests, 2=Blocked

  // Real-time relationship status map: userToken -> status
  // Status: 'accepted', 'pending_sent', 'pending_received', 'blocked', 'blocked_by', null
  RxMap<String, String> relationshipStatus = <String, String>{}.obs;

  // ========== INDUSTRIAL-LEVEL PAGINATION STATE ==========

  // Pagination state for accepted contacts
  RxBool isLoadingContacts = false.obs;
  RxBool hasMoreContacts = true.obs;
  DocumentSnapshot? lastContactDoc;
  static const int CONTACTS_PAGE_SIZE = 20;

  // Pagination state for requests
  RxBool isLoadingRequests = false.obs;
  RxBool hasMoreRequests = true.obs;
  DocumentSnapshot? lastRequestDoc;
  static const int REQUESTS_PAGE_SIZE = 20;

  // Pagination state for blocked users
  RxBool isLoadingBlocked = false.obs;
  RxBool hasMoreBlocked = true.obs;
  DocumentSnapshot? lastBlockedDoc;
  static const int BLOCKED_PAGE_SIZE = 20;

  // Cache for user profiles (token -> UserProfile)
  // Reduces redundant Firestore reads
  RxMap<String, UserProfile> profileCache = <String, UserProfile>{}.obs;

  // Real-time listener for online status updates
  var onlineStatusListener;

  // Pull-to-refresh state
  RxBool isRefreshing = false.obs;
}
