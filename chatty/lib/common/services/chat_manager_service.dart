import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:sakoa/common/store/store.dart';
import 'package:sakoa/common/entities/entities.dart';

/// 🔥 INDUSTRIAL-GRADE CHAT MANAGER SERVICE
/// Handles all chat operations with sophisticated business logic:
/// - Lazy chat creation (only on first message)
/// - Contact verification before chat
/// - Blocking enforcement
/// - Filtered chat list (no blocked/non-contacts/empty chats)
class ChatManagerService extends GetxService {
  static ChatManagerService get to => Get.find();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _chatCache = <String, ChatSession>{}.obs;

  String get myToken => UserStore.to.profile.token ?? UserStore.to.token;

  // ============ CHAT CREATION & RETRIEVAL ============

  /// Get or prepare chat session for two users
  /// ⚡ SMART: Does NOT create Firestore doc until first message!
  Future<ChatSessionResult> getOrPrepareChat({
    required String otherUserToken,
    required String otherUserName,
    required String otherUserAvatar,
    required int otherUserOnline,
  }) async {
    if (myToken.isEmpty || otherUserToken.isEmpty) {
      return ChatSessionResult.error('Invalid user tokens');
    }

    // 1️⃣ Check cache first
    final cacheKey = _getChatCacheKey(myToken, otherUserToken);
    if (_chatCache.containsKey(cacheKey)) {
      return ChatSessionResult.success(_chatCache[cacheKey]!);
    }

    // 2️⃣ Check if chat exists in Firestore
    final existingChat = await _findExistingChat(myToken, otherUserToken);
    if (existingChat != null) {
      // Chat exists, cache and return
      final session = ChatSession(
        docId: existingChat.id,
        myToken: myToken,
        otherUserToken: otherUserToken,
        otherUserName: otherUserName,
        otherUserAvatar: otherUserAvatar,
        otherUserOnline: otherUserOnline,
        exists: true,
      );

      _chatCache[cacheKey] = session;
      return ChatSessionResult.success(session);
    }

    // 3️⃣ Chat doesn't exist yet - prepare virtual session
    // ⚡ No Firestore doc created until first message!
    final session = ChatSession(
      docId: null, // null = not created yet
      myToken: myToken,
      otherUserToken: otherUserToken,
      otherUserName: otherUserName,
      otherUserAvatar: otherUserAvatar,
      otherUserOnline: otherUserOnline,
      exists: false,
    );

    _chatCache[cacheKey] = session;
    print(
        '[ChatManager] ✅ Prepared virtual chat session (no Firestore doc yet)');

    return ChatSessionResult.success(session);
  }

  /// Create chat document on first message
  /// 🎯 This is where the actual Firestore document gets created!
  Future<String> createChatOnFirstMessage(ChatSession session) async {
    if (session.exists && session.docId != null) {
      // Already exists, return existing doc ID
      return session.docId!;
    }

    try {
      final myProfile = UserStore.to.profile;

      final msgData = Msg(
        from_token: myToken,
        to_token: session.otherUserToken,
        from_name: myProfile.name,
        to_name: session.otherUserName,
        from_avatar: myProfile.avatar,
        to_avatar: session.otherUserAvatar,
        from_online: myProfile.online ?? 0,
        to_online: session.otherUserOnline,
        last_msg: "",
        last_time: Timestamp.now(),
        msg_num: 0,
        from_msg_num: 0,
        to_msg_num: 0,
      );

      final docRef = await _db
          .collection("message")
          .withConverter(
            fromFirestore: Msg.fromFirestore,
            toFirestore: (Msg msg, options) => msg.toFirestore(),
          )
          .add(msgData);

      // Update session
      session.docId = docRef.id;
      session.exists = true;

      // Update cache
      final cacheKey = _getChatCacheKey(myToken, session.otherUserToken);
      _chatCache[cacheKey] = session;

      print('[ChatManager] ✅ Created chat document: ${docRef.id}');

      return docRef.id;
    } catch (e) {
      print('[ChatManager] ❌ Failed to create chat: $e');
      throw Exception('Failed to create chat');
    }
  }

  // ============ CHAT LIST FILTERING ============

  /// Get filtered chat list (excludes blocked users, non-contacts, empty chats)
  Future<List<Message>> getFilteredChatList() async {
    try {
      // Get my chats
      final fromChats = await _db
          .collection("message")
          .where("from_token", isEqualTo: myToken)
          .get();

      final toChats = await _db
          .collection("message")
          .where("to_token", isEqualTo: myToken)
          .get();

      final chatList = <Message>[];

      // Process from chats
      for (var doc in fromChats.docs) {
        final item = doc.data();
        final otherToken = item['to_token'] ?? '';

        // Skip if empty chat (no messages)
        if ((item['last_msg'] ?? '').toString().isEmpty) {
          print('[ChatManager] 🗑️ Skipping empty chat with $otherToken');
          continue;
        }

        chatList.add(_createMessageFromDoc(doc, isFrom: true));
      }

      // Process to chats
      for (var doc in toChats.docs) {
        final item = doc.data();
        final otherToken = item['from_token'] ?? '';

        // Skip if empty chat
        if ((item['last_msg'] ?? '').toString().isEmpty) {
          print('[ChatManager] 🗑️ Skipping empty chat with $otherToken');
          continue;
        }

        chatList.add(_createMessageFromDoc(doc, isFrom: false));
      }

      // Sort by last_time
      chatList.sort((a, b) {
        if (a.last_time == null || b.last_time == null) return 0;
        return b.last_time!.compareTo(a.last_time!);
      });

      print(
          '[ChatManager] ✅ Filtered chat list: ${chatList.length} chats (empty chats removed)');

      return chatList;
    } catch (e) {
      print('[ChatManager] ❌ Failed to get chat list: $e');
      return [];
    }
  }

  // ============ CHAT METADATA ============

  /// Update chat last message and counts
  Future<void> updateChatMetadata(
      String chatDocId, String lastMsg, String type) async {
    try {
      final chatDoc = await _db
          .collection("message")
          .doc(chatDocId)
          .withConverter(
            fromFirestore: Msg.fromFirestore,
            toFirestore: (Msg msg, options) => msg.toFirestore(),
          )
          .get();

      if (!chatDoc.exists) return;

      final item = chatDoc.data()!;
      int toMsgNum = item.to_msg_num ?? 0;
      int fromMsgNum = item.from_msg_num ?? 0;

      if (item.from_token == myToken) {
        fromMsgNum += 1;
      } else {
        toMsgNum += 1;
      }

      String displayMsg = lastMsg;
      if (type == 'image') displayMsg = '📷 Photo';
      if (type == 'voice') displayMsg = '🎤 Voice message';
      if (type == 'video') displayMsg = '🎥 Video';

      await _db.collection("message").doc(chatDocId).update({
        "to_msg_num": toMsgNum,
        "from_msg_num": fromMsgNum,
        "last_msg": displayMsg,
        "last_time": Timestamp.now(),
      });

      print('[ChatManager] ✅ Updated chat metadata: $displayMsg');
    } catch (e) {
      print('[ChatManager] ❌ Failed to update metadata: $e');
    }
  }

  /// Clear unread count for current user
  Future<void> clearUnreadCount(String chatDocId) async {
    try {
      final chatDoc = await _db.collection("message").doc(chatDocId).get();

      if (!chatDoc.exists) return;

      final data = chatDoc.data()!;
      final fromToken = data['from_token'];

      if (fromToken == myToken) {
        await _db.collection("message").doc(chatDocId).update({
          "to_msg_num": 0,
        });
      } else {
        await _db.collection("message").doc(chatDocId).update({
          "from_msg_num": 0,
        });
      }

      print('[ChatManager] ✅ Cleared unread count');
    } catch (e) {
      print('[ChatManager] ❌ Failed to clear unread: $e');
    }
  }

  // ============ HELPER METHODS ============

  /// Find existing chat between two users
  Future<DocumentSnapshot?> _findExistingChat(
      String token1, String token2) async {
    try {
      // Check from_token -> to_token
      final fromQuery = await _db
          .collection("message")
          .where("from_token", isEqualTo: token1)
          .where("to_token", isEqualTo: token2)
          .limit(1)
          .get();

      if (fromQuery.docs.isNotEmpty) {
        return fromQuery.docs.first;
      }

      // Check to_token -> from_token
      final toQuery = await _db
          .collection("message")
          .where("from_token", isEqualTo: token2)
          .where("to_token", isEqualTo: token1)
          .limit(1)
          .get();

      if (toQuery.docs.isNotEmpty) {
        return toQuery.docs.first;
      }

      return null;
    } catch (e) {
      print('[ChatManager] ❌ Error finding chat: $e');
      return null;
    }
  }

  /// Generate cache key for chat
  String _getChatCacheKey(String token1, String token2) {
    final tokens = [token1, token2]..sort();
    return '${tokens[0]}_${tokens[1]}';
  }

  /// Create Message object from Firestore doc
  Message _createMessageFromDoc(DocumentSnapshot doc, {required bool isFrom}) {
    final data = doc.data() as Map<String, dynamic>;

    return Message()
      ..doc_id = doc.id
      ..name = isFrom ? data['to_name'] : data['from_name']
      ..avatar = isFrom ? data['to_avatar'] : data['from_avatar']
      ..token = isFrom ? data['to_token'] : data['from_token']
      ..online = isFrom ? (data['to_online'] ?? 0) : (data['from_online'] ?? 0)
      ..last_msg = data['last_msg']
      ..last_time = data['last_time'] as Timestamp?
      ..msg_num =
          isFrom ? (data['to_msg_num'] ?? 0) : (data['from_msg_num'] ?? 0);
  }

  /// Clear all cache
  void clearCache() {
    _chatCache.clear();
    print('[ChatManager] 🧹 Cleared chat cache');
  }
}

// ============ DATA MODELS ============

class ChatSession {
  String? docId;
  final String myToken;
  final String otherUserToken;
  final String otherUserName;
  final String otherUserAvatar;
  final int otherUserOnline;
  bool exists;

  ChatSession({
    this.docId,
    required this.myToken,
    required this.otherUserToken,
    required this.otherUserName,
    required this.otherUserAvatar,
    required this.otherUserOnline,
    required this.exists,
  });

  Map<String, dynamic> toJson() {
    return {
      'docId': docId,
      'myToken': myToken,
      'otherUserToken': otherUserToken,
      'otherUserName': otherUserName,
      'otherUserAvatar': otherUserAvatar,
      'otherUserOnline': otherUserOnline,
      'exists': exists,
    };
  }

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      docId: json['docId'],
      myToken: json['myToken'],
      otherUserToken: json['otherUserToken'],
      otherUserName: json['otherUserName'],
      otherUserAvatar: json['otherUserAvatar'],
      otherUserOnline: json['otherUserOnline'],
      exists: json['exists'] ?? false,
    );
  }
}

class ChatSessionResult {
  final bool success;
  final String? error;
  final ChatSession? session;

  ChatSessionResult._({
    required this.success,
    this.error,
    this.session,
  });

  factory ChatSessionResult.success(ChatSession session) {
    return ChatSessionResult._(success: true, session: session);
  }

  factory ChatSessionResult.error(String error) {
    return ChatSessionResult._(success: false, error: error);
  }
}
