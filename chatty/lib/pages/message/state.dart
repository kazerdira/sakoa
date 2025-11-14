import 'package:sakoa/common/entities/entities.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  /// Map of user token -> online status (0=offline, 1=online)
  /// Updated in real-time via presence service
  RxMap<String, int> onlineStatus = <String, int>{}.obs;

  /// Map of user token -> last seen text ("5m ago", "Online", etc)
  RxMap<String, String> lastSeen = <String, String>{}.obs;

  // ============ TYPING INDICATORS ============

  /// Map of chat doc_id -> Set of typing user tokens
  RxMap<String, Set<String>> typingUsers = <String, Set<String>>{}.obs;

  // ============ UNREAD COUNTS ============

  /// Total unread message count across all chats
  RxInt totalUnreadCount = 0.obs;

  /// Map of chat doc_id -> unread count for that chat
  RxMap<String, int> unreadCounts = <String, int>{}.obs;

  // ============ FILTERS & SORTING ============

  /// Search query for filtering chats
  RxString searchQuery = ''.obs;

  /// Sort mode (by_time, by_unread, by_name)
  RxString sortMode = 'by_time'.obs;
}
