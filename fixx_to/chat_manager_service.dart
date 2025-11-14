import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:sakoa/common/store/store.dart';
import 'package:sakoa/common/entities/entities.dart';
import 'package:sakoa/pages/contact/index.dart';

/// 🔥 INDUSTRIAL-GRADE CHAT MANAGER SERVICE
/// Handles all chat operations with sophisticated business logic:
/// - Lazy chat creation (only on first message)
/// - Message delivery states (sent/delivered/read)
/// - Contact verification before chat
/// - Blocking enforcement
/// - Optimistic updates
class ChatManagerService extends GetxService {
  static ChatManagerService get to => Get.find();
  
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _chatCache = <String, ChatSession>{}.obs;
  
  String get myToken => UserStore.to.profile.token ?? UserStore.to.token;
  
  // ============ CHAT CREATION & RETRIEVAL ============
  
  /// Get or create chat document ID for two users
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
    
    // 1️⃣ Verify they are contacts
    final contactController = Get.find<ContactController>();
    final isContact = await contactController.isUserContact(otherUserToken);
    
    if (!isContact) {
      return ChatSessionResult.error('You must be contacts to chat');
    }
    
    // 2️⃣ Verify not blocked
    final isBlocked = await contactController.isUserBlocked(otherUserToken);
    if (isBlocked) {
      return ChatSessionResult.error('This user is blocked');
    }
    
    // Check if they blocked me
    final amIBlocked = await _checkIfImBlocked(otherUserToken);
    if (amIBlocked) {
      return ChatSessionResult.error('You cannot message this user');
    }
    
    // 3️⃣ Check cache first
    final cacheKey = _getChatCacheKey(myToken, otherUserToken);
    if (_chatCache.containsKey(cacheKey)) {
      return ChatSessionResult.success(_chatCache[cacheKey]!);
    }
    
    // 4️⃣ Check if chat exists in Firestore
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
    
    // 5️⃣ Chat doesn't exist yet - prepare virtual session
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
    print('[ChatManager] ✅ Prepared virtual chat session (no Firestore doc yet)');
    
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
  
  // ============ MESSAGE OPERATIONS ============
  
  /// Send a message with delivery tracking
  Future<MessageSendResult> sendMessage({
    required String chatDocId,
    required String content,
    required String type, // 'text', 'image', 'voice', 'video'
  }) async {
    if (chatDocId.isEmpty || content.isEmpty) {
      return MessageSendResult.error('Invalid message data');
    }
    
    try {
      // 1️⃣ Create message content with pending state
      final messageContent = Msgcontent(
        token: myToken,
        content: content,
        type: type,
        addtime: Timestamp.now(),
        delivery_status: 'sent', // sent -> delivered -> read
      );
      
      // 2️⃣ Add to Firestore
      final docRef = await _db
          .collection("message")
          .doc(chatDocId)
          .collection("msglist")
          .withConverter(
            fromFirestore: Msgcontent.fromFirestore,
            toFirestore: (Msgcontent msg, options) => msg.toFirestore(),
          )
          .add(messageContent);
      
      // 3️⃣ Update chat metadata
      await _updateChatMetadata(chatDocId, content, type);
      
      print('[ChatManager] ✅ Message sent: ${docRef.id}');
      
      return MessageSendResult.success(docRef.id);
    } catch (e) {
      print('[ChatManager] ❌ Failed to send message: $e');
      return MessageSendResult.error('Failed to send message');
    }
  }
  
  /// Update message delivery status
  Future<void> updateMessageDeliveryStatus({
    required String chatDocId,
    required String messageId,
    required String status, // 'delivered' or 'read'
  }) async {
    try {
      await _db
          .collection("message")
          .doc(chatDocId)
          .collection("msglist")
          .doc(messageId)
          .update({
        'delivery_status': status,
        '${status}_at': FieldValue.serverTimestamp(),
      });
      
      print('[ChatManager] ✅ Updated delivery status to: $status');
    } catch (e) {
      print('[ChatManager] ❌ Failed to update delivery status: $e');
    }
  }
  
  /// Mark all messages in chat as read
  Future<void> markChatAsRead(String chatDocId) async {
    if (chatDocId.isEmpty) return;
    
    try {
      // Get unread messages
      final unreadMessages = await _db
          .collection("message")
          .doc(chatDocId)
          .collection("msglist")
          .where('token', isNotEqualTo: myToken)
          .where('delivery_status', isNotEqualTo: 'read')
          .get();
      
      // Batch update
      final batch = _db.batch();
      for (var doc in unreadMessages.docs) {
        batch.update(doc.reference, {
          'delivery_status': 'read',
          'read_at': FieldValue.serverTimestamp(),
        });
      }
      
      await batch.commit();
      
      // Clear unread count
      await _clearUnreadCount(chatDocId);
      
      print('[ChatManager] ✅ Marked ${unreadMessages.docs.length} messages as read');
    } catch (e) {
      print('[ChatManager] ❌ Failed to mark as read: $e');
    }
  }
  
  // ============ CHAT METADATA ============
  
  /// Update chat last message and counts
  Future<void> _updateChatMetadata(String chatDocId, String lastMsg, String type) async {
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
    } catch (e) {
      print('[ChatManager] ❌ Failed to update metadata: $e');
    }
  }
  
  /// Clear unread count for current user
  Future<void> _clearUnreadCount(String chatDocId) async {
    try {
      final chatDoc = await _db
          .collection("message")
          .doc(chatDocId)
          .get();
      
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
    } catch (e) {
      print('[ChatManager] ❌ Failed to clear unread: $e');
    }
  }
  
  // ============ CHAT LIST FILTERING ============
  
  /// Get filtered chat list (excludes blocked users, empty chats)
  Future<List<Message>> getFilteredChatList() async {
    try {
      final contactController = Get.find<ContactController>();
      
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
        final item = doc.data() as Map<String, dynamic>;
        final otherToken = item['to_token'] ?? '';
        
        // Skip if blocked
        if (await contactController.isUserBlocked(otherToken)) continue;
        
        // Skip if not contact
        if (!await contactController.isUserContact(otherToken)) continue;
        
        // Skip if empty chat (no messages)
        if ((item['last_msg'] ?? '').toString().isEmpty) continue;
        
        chatList.add(_createMessageFromDoc(doc, isFrom: true));
      }
      
      // Process to chats
      for (var doc in toChats.docs) {
        final item = doc.data() as Map<String, dynamic>;
        final otherToken = item['from_token'] ?? '';
        
        // Skip if blocked
        if (await contactController.isUserBlocked(otherToken)) continue;
        
        // Skip if not contact
        if (!await contactController.isUserContact(otherToken)) continue;
        
        // Skip if empty chat
        if ((item['last_msg'] ?? '').toString().isEmpty) continue;
        
        chatList.add(_createMessageFromDoc(doc, isFrom: false));
      }
      
      // Sort by last_time
      chatList.sort((a, b) {
        if (a.last_time == null || b.last_time == null) return 0;
        return b.last_time!.compareTo(a.last_time!);
      });
      
      return chatList;
    } catch (e) {
      print('[ChatManager] ❌ Failed to get chat list: $e');
      return [];
    }
  }
  
  // ============ HELPER METHODS ============
  
  /// Find existing chat between two users
  Future<DocumentSnapshot?> _findExistingChat(String token1, String token2) async {
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
  
  /// Check if I'm blocked by the other user
  Future<bool> _checkIfImBlocked(String otherUserToken) async {
    try {
      final query = await _db
          .collection("contacts")
          .where("user_token", isEqualTo: otherUserToken)
          .where("contact_token", isEqualTo: myToken)
          .where("status", isEqualTo: "blocked")
          .limit(1)
          .get();
      
      return query.docs.isNotEmpty;
    } catch (e) {
      return false;
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
      ..msg_num = isFrom ? (data['to_msg_num'] ?? 0) : (data['from_msg_num'] ?? 0);
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

class MessageSendResult {
  final bool success;
  final String? error;
  final String? messageId;
  
  MessageSendResult._({
    required this.success,
    this.error,
    this.messageId,
  });
  
  factory MessageSendResult.success(String messageId) {
    return MessageSendResult._(success: true, messageId: messageId);
  }
  
  factory MessageSendResult.error(String error) {
    return MessageSendResult._(success: false, error: error);
  }
}
