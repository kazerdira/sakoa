import 'package:sakoa/common/entities/entities.dart';
import 'package:get/get.dart';

/// 🔥 INDUSTRIAL-GRADE MESSAGE STATE
/// Professional state management with comprehensive loading/error states
class MessageState {
  // ============ DATA ============
  
  /// Chat messages list (filtered and sorted)
  RxList<Message> msgList = <Message>[].obs;
  
  /// Call history list
  RxList<CallMessage> callList = <CallMessage>[].obs;
  
  /// User profile data
  var head_detail = UserItem().obs;
  
  // ============ UI STATE ============
  
  /// Tab selection (true = Chat, false = Call)
  RxBool tabStatus = true.obs;
  
  /// Loading state for initial load
  RxBool isLoading = false.obs;
  
  /// Refreshing state for pull-to-refresh
  RxBool isRefreshing = false.obs;
  
  /// Error state
  RxString errorMessage = ''.obs;
  
  /// Empty state
  RxBool isEmpty = true.obs;
  
  // ============ PRESENCE STATE ============
  
  /// Map of user token -> online status
  /// Updated in real-time via presence service
  RxMap<String, int> onlineStatus = <String, int>{}.obs;
  
  /// Map of user token -> last seen timestamp
  RxMap<String, String> lastSeen = <String, String>{}.obs;
  
  // ============ TYPING INDICATORS ============
  
  /// Map of chat doc_id -> typing users
  RxMap<String, Set<String>> typingUsers = <String, Set<String>>{}.obs;
  
  // ============ UNREAD COUNTS ============
  
  /// Total unread message count
  RxInt totalUnreadCount = 0.obs;
  
  /// Map of chat doc_id -> unread count
  RxMap<String, int> unreadCounts = <String, int>{}.obs;
  
  // ============ FILTERS & SORTING ============
  
  /// Search query for filtering chats
  RxString searchQuery = ''.obs;
  
  /// Sort mode (by_time, by_unread, by_name)
  RxString sortMode = 'by_time'.obs;
  
  /// Show archived chats
  RxBool showArchived = false.obs;
  
  // ============ COMPUTED PROPERTIES ============
  
  /// Get filtered and sorted chat list based on current state
  List<Message> get filteredChats {
    var chats = msgList.toList();
    
    // Apply search filter
    if (searchQuery.value.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
      chats = chats.where((chat) {
        return (chat.name?.toLowerCase().contains(query) ?? false) ||
               (chat.last_msg?.toLowerCase().contains(query) ?? false);
      }).toList();
    }
    
    // Apply sorting
    switch (sortMode.value) {
      case 'by_unread':
        chats.sort((a, b) {
          if (a.msg_num == 0 && b.msg_num == 0) {
            return (b.last_time?.compareTo(a.last_time ?? Timestamp.now()) ?? 0);
          }
          return (b.msg_num ?? 0).compareTo(a.msg_num ?? 0);
        });
        break;
        
      case 'by_name':
        chats.sort((a, b) => (a.name ?? '').compareTo(b.name ?? ''));
        break;
        
      case 'by_time':
      default:
        chats.sort((a, b) {
          if (a.last_time == null && b.last_time == null) return 0;
          if (a.last_time == null) return 1;
          if (b.last_time == null) return -1;
          return b.last_time!.compareTo(a.last_time!);
        });
        break;
    }
    
    return chats;
  }
  
  /// Update total unread count
  void updateTotalUnreadCount() {
    totalUnreadCount.value = msgList.fold(0, (sum, chat) => sum + (chat.msg_num ?? 0));
  }
  
  /// Check if chat list is empty
  void updateEmptyState() {
    isEmpty.value = msgList.isEmpty;
  }
}
