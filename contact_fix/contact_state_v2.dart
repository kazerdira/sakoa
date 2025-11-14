import 'package:get/get.dart';
import 'package:sakoa/common/entities/entities.dart';
import 'package:sakoa/common/entities/contact_entity.dart';

/// Sort options for contacts
enum ContactSortBy {
  name,
  recentlyAdded,
  onlineFirst,
}

/// 🚀 SUPERNOVA-LEVEL CONTACT STATE
/// Clean, organized, and reactive
class ContactStateV2 {
  // ============================================================
  // CONTACT LISTS
  // ============================================================
  
  /// All accepted contacts (raw list from repository)
  final acceptedContacts = <ContactEntity>[].obs;
  
  /// Filtered and sorted contacts (for display)
  final filteredContacts = <ContactEntity>[].obs;
  
  /// Pending requests (received)
  final pendingRequests = <ContactEntity>[].obs;
  
  /// Sent requests (outgoing)
  final sentRequests = <ContactEntity>[].obs;
  
  /// Blocked users
  final blockedList = <ContactEntity>[].obs;
  
  /// Search results
  final searchResults = <UserProfile>[].obs;
  
  // ============================================================
  // UI STATE
  // ============================================================
  
  /// Currently selected tab (0=Contacts, 1=Requests, 2=Blocked)
  final selectedTab = 0.obs;
  
  /// Search query
  final searchQuery = ''.obs;
  
  /// Is searching
  final isSearching = false.obs;
  
  /// Is initializing
  final isInitializing = false.obs;
  
  /// Is loading contacts
  final isLoadingContacts = false.obs;
  
  /// Is refreshing (pull-to-refresh)
  final isRefreshing = false.obs;
  
  /// Pending request count (for badge)
  final pendingRequestCount = 0.obs;
  
  // ============================================================
  // FILTERS & SORTING
  // ============================================================
  
  /// Filter: Show only online contacts
  final filterOnlineOnly = false.obs;
  
  /// Current sort method
  final sortBy = ContactSortBy.name.obs;
  
  // ============================================================
  // RELATIONSHIP STATUS MAP
  // ============================================================
  
  /// Map of userToken -> relationship status
  /// Status values:
  /// - 'accepted': Friends
  /// - 'pending_sent': Request sent by me
  /// - 'pending_received': Request received from them
  /// - 'blocked': I blocked them
  /// - 'blocked_by': They blocked me
  /// - null: No relationship
  final relationshipStatus = <String, String?>{}.obs;
  
  // ============================================================
  // FAVORITES & GROUPS (FUTURE FEATURES)
  // ============================================================
  
  /// Favorite contacts (for quick access)
  final favoriteContacts = <String>[].obs;
  
  /// Contact groups
  final contactGroups = <ContactGroup>[].obs;
  
  // ============================================================
  // COMPUTED PROPERTIES
  // ============================================================
  
  /// Get online contacts count
  int get onlineCount {
    return acceptedContacts.where((c) => (c.contact_online ?? 0) == 1).length;
  }
  
  /// Get total contacts count
  int get totalContactsCount {
    return acceptedContacts.length;
  }
  
  /// Has any contacts
  bool get hasContacts {
    return acceptedContacts.isNotEmpty;
  }
  
  /// Has pending requests
  bool get hasPendingRequests {
    return pendingRequests.isNotEmpty;
  }
  
  /// Is currently showing search results
  bool get isShowingSearchResults {
    return searchQuery.value.isNotEmpty;
  }
}

/// Contact group model (for future feature)
class ContactGroup {
  final String id;
  final String name;
  final String? icon;
  final List<String> contactTokens;
  
  ContactGroup({
    required this.id,
    required this.name,
    this.icon,
    required this.contactTokens,
  });
}
