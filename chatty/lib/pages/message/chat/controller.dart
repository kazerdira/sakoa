import 'dart:io';
import 'dart:async';
import 'package:sakoa/common/apis/apis.dart';
import 'package:sakoa/common/routes/names.dart';
import 'package:sakoa/common/utils/utils.dart';
import 'package:sakoa/common/values/values.dart';
import 'package:sakoa/common/widgets/toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
// import 'package:flutter_easyloading/flutter_easyloading.dart'; // 🔥 Removed: No longer blocking UI
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'state.dart';
import 'package:sakoa/common/entities/entities.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sakoa/common/store/store.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';
import 'package:sakoa/pages/contact/index.dart';
import 'package:sakoa/common/services/blocking_service.dart';
import 'package:sakoa/common/services/chat_security_service.dart';
import 'package:sakoa/common/widgets/block_settings_dialog.dart';
import 'package:sakoa/common/services/voice_message_service.dart'; // 🔥 NEW: Voice messaging
import 'package:sakoa/common/services/message_delivery_service.dart'; // 🔥 INDUSTRIAL: Delivery tracking

class ChatController extends GetxController {
  ChatController();
  final myinputController = TextEditingController();
  ScrollController myscrollController = new ScrollController();
  ScrollController inputScrollController = new ScrollController();
  FocusNode contentFocus = FocusNode();
  final ChatState state = ChatState();
  final db = FirebaseFirestore.instance;
  bool isloadmore = true;
  double inputHeightStatus = 0;
  var listener;
  var doc_id = null;
  final token = UserStore.to.profile.token;
  File? _photo;
  final ImagePicker _picker = ImagePicker();

  // 🔥 INDUSTRIAL-GRADE BLOCKING SYSTEM
  final isBlocked = false.obs;
  final blockStatus = Rx<BlockStatus?>(null);
  StreamSubscription? _blockListener;

  // 🔥 VOICE MESSAGING & REPLY SYSTEM
  late final VoiceMessageService _voiceService;
  final replyingTo = Rx<MessageReply?>(null);
  final isReplyMode = false.obs;
  final isRecordingVoice = false.obs;
  final recordingCancelled = false.obs;

  // 🔥 INDUSTRIAL-GRADE MESSAGE DELIVERY SERVICE
  late final MessageDeliveryService _deliveryService;

  goMore() {
    state.more_status.value = state.more_status.value ? false : true;
  }

  callAudio() async {
    state.more_status.value = false;
    Get.toNamed(AppRoutes.VoiceCall, parameters: {
      "doc_id": doc_id,
      "to_token": state.to_token.value,
      "to_name": state.to_name.value,
      "to_avatar": state.to_avatar.value,
      "call_role": "anchor"
    });
  }

  callVideo() async {
    state.more_status.value = false;
    Get.toNamed(AppRoutes.VideoCall, parameters: {
      "doc_id": doc_id,
      "to_token": state.to_token.value,
      "to_name": state.to_name.value,
      "to_avatar": state.to_avatar.value,
      "call_role": "anchor"
    });
  }

  Future imgFromGallery() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      _photo = File(pickedFile.path);
      uploadFile();
    } else {
      print('No image selected.');
    }
  }

  Future imgFromCamera() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      _photo = File(pickedFile.path);
      uploadFile();
    } else {
      print('No image selected.');
    }
  }

  Future uploadFile() async {
    // if (_photo == null) return;
    // print(_photo);
    var result = await ChatAPI.upload_img(file: _photo);
    print(result.data);
    if (result.code == 0) {
      sendImageMessage(result.data!);
    } else {
      toastInfo(msg: "image error");
    }
  }

  sendMessage() async {
    print("---------------chat-----------------");

    // 🔥 BLOCKING CHECK
    if (isBlocked.value) {
      toastInfo(msg: "Cannot send message to blocked user");
      return;
    }

    String sendcontent = myinputController.text;
    if (sendcontent.isEmpty) {
      toastInfo(msg: "content not empty");
      return;
    }
    print("---------------chat--${sendcontent}-----------------");

    // 🔥 CREATE MESSAGE WITH REPLY SUPPORT
    final content = Msgcontent(
      token: token,
      content: sendcontent,
      type: "text",
      addtime: Timestamp.now(),
      reply:
          isReplyMode.value ? replyingTo.value : null, // 🔥 Add reply if exists
    );

    // 🔥 INDUSTRIAL-GRADE: Send with delivery tracking
    final result = await _deliveryService.sendMessageWithTracking(
      chatDocId: doc_id,
      content: content,
    );

    if (result.success || result.queued) {
      print(
          '[ChatController] ✅ Message sent: ${result.messageId} (queued: ${result.queued})');
      myinputController.clear();

      // Update chat metadata
      var message_res = await db
          .collection("message")
          .doc(doc_id)
          .withConverter(
            fromFirestore: Msg.fromFirestore,
            toFirestore: (Msg msg, options) => msg.toFirestore(),
          )
          .get();
      if (message_res.data() != null) {
        var item = message_res.data()!;
        int to_msg_num = item.to_msg_num == null ? 0 : item.to_msg_num!;
        int from_msg_num = item.from_msg_num == null ? 0 : item.from_msg_num!;
        if (item.from_token == token) {
          from_msg_num = from_msg_num + 1;
        } else {
          to_msg_num = to_msg_num + 1;
        }
        await db.collection("message").doc(doc_id).update({
          "to_msg_num": to_msg_num,
          "from_msg_num": from_msg_num,
          "last_msg": sendcontent,
          "last_time": Timestamp.now()
        });
      }
      sendNotifications("text");
    } else {
      print('[ChatController] ❌ Message failed: ${result.error}');
      toastInfo(msg: result.error ?? "Failed to send message");
    }

    // 🔥 CLEAR REPLY MODE after sending
    clearReplyMode();
  }

  sendImageMessage(String url) async {
    state.more_status.value = false;

    // 🔥 BLOCKING CHECK
    if (isBlocked.value) {
      toastInfo(msg: "Cannot send image to blocked user");
      return;
    }

    print("---------------chat-----------------");
    final content = Msgcontent(
      token: token,
      content: url,
      type: "image",
      addtime: Timestamp.now(),
    );

    // 🔥 INDUSTRIAL-GRADE: Send with delivery tracking
    final result = await _deliveryService.sendMessageWithTracking(
      chatDocId: doc_id,
      content: content,
    );

    if (result.success || result.queued) {
      print(
          '[ChatController] ✅ Image sent: ${result.messageId} (queued: ${result.queued})');

      // Update chat metadata
      var message_res = await db
          .collection("message")
          .doc(doc_id)
          .withConverter(
            fromFirestore: Msg.fromFirestore,
            toFirestore: (Msg msg, options) => msg.toFirestore(),
          )
          .get();
      if (message_res.data() != null) {
        var item = message_res.data()!;
        int to_msg_num = item.to_msg_num == null ? 0 : item.to_msg_num!;
        int from_msg_num = item.from_msg_num == null ? 0 : item.from_msg_num!;
        if (item.from_token == token) {
          from_msg_num = from_msg_num + 1;
        } else {
          to_msg_num = to_msg_num + 1;
        }
        await db.collection("message").doc(doc_id).update({
          "to_msg_num": to_msg_num,
          "from_msg_num": from_msg_num,
          "last_msg": "【image】",
          "last_time": Timestamp.now()
        });
      }

      sendNotifications("text");
    } else {
      print('[ChatController] ❌ Image failed: ${result.error}');
      toastInfo(msg: result.error ?? "Failed to send image");
    }
  }

  sendNotifications(String call_type) async {
    CallRequestEntity callRequestEntity = new CallRequestEntity();
    // text,voice,video,cancel
    callRequestEntity.call_type = call_type;
    callRequestEntity.to_token = state.to_token.value;
    callRequestEntity.to_avatar = state.to_avatar.value;
    callRequestEntity.doc_id = doc_id;
    callRequestEntity.to_name = state.to_name.value;
    var res = await ChatAPI.call_notifications(params: callRequestEntity);
    print(res);
    if (res.code == 0) {
      print("sendNotifications success");
    } else {
      // Get.snackbar("Tips", "Notification error!");
      // Get.offAllNamed(AppRoutes.Message);
    }
  }

  // ============ 🔥 VOICE MESSAGING METHODS ============

  /// Start recording voice message
  Future<void> startVoiceRecording() async {
    if (isBlocked.value) {
      toastInfo(msg: "Cannot send voice message to blocked user");
      return;
    }

    final success = await _voiceService.startRecording();
    if (success) {
      isRecordingVoice.value = true;
      recordingCancelled.value = false;
      state.more_status.value = false; // Hide more menu
      print('[ChatController] 🎤 Voice recording started');
    }
  }

  /// Stop recording and send voice message
  Future<void> stopAndSendVoiceMessage() async {
    try {
      if (!isRecordingVoice.value) return;

      // Check if recording was cancelled
      if (recordingCancelled.value) {
        await _voiceService.cancelRecording();
        isRecordingVoice.value = false;
        recordingCancelled.value = false;
        print('[ChatController] ❌ Voice recording cancelled by user');
        return;
      }

      print('[ChatController] 🎤 Stopping recording...');
      final localPath = await _voiceService.stopRecording();
      isRecordingVoice.value = false;

      if (localPath == null) {
        print('[ChatController] ❌ No recording file');
        return;
      }

      // 🔥 FIX: No EasyLoading to avoid blocking UI updates
      // Upload to Firebase Storage
      print('[ChatController] ☁️ Uploading voice message...');
      final audioUrl = await _voiceService.uploadVoiceMessage(localPath);

      if (audioUrl == null) {
        print('[ChatController] ❌ Upload failed');
        return;
      }

      // Send voice message to Firestore
      await sendVoiceMessage(audioUrl, _voiceService.recordingDuration.value);

      print('[ChatController] ✅ Voice message sent successfully');
    } catch (e, stackTrace) {
      print('[ChatController] ❌ Failed to send voice message: $e');
      print('[ChatController] Stack trace: $stackTrace');
      toastInfo(msg: "Failed to send voice message");
      isRecordingVoice.value = false;
    }
  }

  /// Cancel voice recording
  Future<void> cancelVoiceRecording() async {
    recordingCancelled.value = true;
    await stopAndSendVoiceMessage(); // This will handle the cancellation
  }

  /// Send voice message to Firestore
  Future<void> sendVoiceMessage(String audioUrl, Duration duration) async {
    try {
      print('[ChatController] 📤 Sending voice message to Firestore...');

      // Create voice message content
      final content = Msgcontent(
        token: token,
        content: audioUrl,
        type: "voice",
        addtime: Timestamp.now(),
        voice_duration: duration.inSeconds, // Store duration in seconds
        reply: isReplyMode.value
            ? replyingTo.value
            : null, // 🔥 Add reply if exists
      );

      // 🔥 INDUSTRIAL-GRADE: Send with delivery tracking
      final result = await _deliveryService.sendMessageWithTracking(
        chatDocId: doc_id,
        content: content,
      );

      if (result.success || result.queued) {
        print(
            '[ChatController] ✅ Voice message sent: ${result.messageId} (queued: ${result.queued})');

        // Update chat metadata
        var message_res = await db
            .collection("message")
            .doc(doc_id)
            .withConverter(
              fromFirestore: Msg.fromFirestore,
              toFirestore: (Msg msg, options) => msg.toFirestore(),
            )
            .get();

        if (message_res.data() != null) {
          var item = message_res.data()!;
          int to_msg_num = item.to_msg_num == null ? 0 : item.to_msg_num!;
          int from_msg_num = item.from_msg_num == null ? 0 : item.from_msg_num!;

          if (item.from_token == token) {
            from_msg_num = from_msg_num + 1;
          } else {
            to_msg_num = to_msg_num + 1;
          }

          await db.collection("message").doc(doc_id).update({
            "to_msg_num": to_msg_num,
            "from_msg_num": from_msg_num,
            "last_msg": "🎤 Voice message",
            "last_time": Timestamp.now()
          });
        }

        // Send notification
        sendNotifications("voice");

        // Clear reply mode
        clearReplyMode();
      } else {
        print('[ChatController] ❌ Voice message failed: ${result.error}');
        throw Exception(result.error ?? "Failed to send voice message");
      }
    } catch (e, stackTrace) {
      print('[ChatController] ❌ Failed to save voice message: $e');
      print('[ChatController] Stack trace: $stackTrace');
      throw e;
    }
  }

  // ============ 🔥 REPLY METHODS ============

  /// Set message to reply to
  void setReplyTo(Msgcontent message) {
    try {
      // Convert Msgcontent to MessageReply
      replyingTo.value = MessageReply(
        originalMessageId: message.id ?? '',
        originalContent: message.content ?? '',
        originalType: message.type ?? 'text',
        originalSenderToken: message.token ?? '',
        originalSenderName: state.to_name.value, // Assuming other user sent it
        originalTimestamp: message.addtime,
        voiceDuration: message.voice_duration,
      );
      isReplyMode.value = true;

      // Auto-focus text input
      contentFocus.requestFocus();

      print('[ChatController] 💬 Reply mode activated: ${replyingTo.value}');
    } catch (e) {
      print('[ChatController] ❌ Failed to set reply: $e');
      toastInfo(msg: "Failed to reply to message");
    }
  }

  /// Clear reply mode
  void clearReplyMode() {
    replyingTo.value = null;
    isReplyMode.value = false;
    print('[ChatController] ❌ Reply mode cleared');
  }

  /// Scroll to original message (when tapping reply preview)
  Future<void> scrollToMessage(String messageId) async {
    try {
      // Find message index in list
      final index =
          state.msgcontentList.indexWhere((msg) => msg.id == messageId);

      if (index == -1) {
        toastInfo(msg: "Original message not found");
        print('[ChatController] ⚠️ Message not found: $messageId');
        return;
      }

      // Calculate scroll position (reverse list, so index from bottom)
      final scrollPosition = index * 100.0; // Approximate height per message

      // Animate scroll
      await myscrollController.animateTo(
        scrollPosition,
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );

      print('[ChatController] 📜 Scrolled to message: $messageId');
    } catch (e) {
      print('[ChatController] ❌ Failed to scroll to message: $e');
    }
  }

  clear_msg_num(String doc_id) async {
    var message_res = await db
        .collection("message")
        .doc(doc_id)
        .withConverter(
          fromFirestore: Msg.fromFirestore,
          toFirestore: (Msg msg, options) => msg.toFirestore(),
        )
        .get();
    if (message_res.data() != null) {
      var item = message_res.data()!;
      int to_msg_num = item.to_msg_num == null ? 0 : item.to_msg_num!;
      int from_msg_num = item.from_msg_num == null ? 0 : item.from_msg_num!;
      if (item.from_token == token) {
        to_msg_num = 0;
      } else {
        from_msg_num = 0;
      }
      await db
          .collection("message")
          .doc(doc_id)
          .update({"to_msg_num": to_msg_num, "from_msg_num": from_msg_num});
    }
  }

  asyncLoadMoreData(int page) async {
    final messages = await db
        .collection("message")
        .doc(doc_id)
        .collection("msglist")
        .withConverter(
          fromFirestore: Msgcontent.fromFirestore,
          toFirestore: (Msgcontent msgcontent, options) =>
              msgcontent.toFirestore(),
        )
        .orderBy("addtime", descending: true)
        .where("addtime", isLessThan: state.msgcontentList.value.last.addtime)
        .limit(10)
        .get();
    print(state.msgcontentList.value.last.content);
    print("isGreaterThan-----");
    if (messages.docs.isNotEmpty) {
      messages.docs.forEach((element) {
        var data = element.data();
        state.msgcontentList.value.add(data);
        print(data.content);
      });

      SchedulerBinding.instance.addPostFrameCallback((_) {
        isloadmore = true;
      });
    }
    state.isloading.value = false;
  }

  close_all_pop() async {
    Get.focusScope?.unfocus();
    state.more_status.value = false;
    print("------close_all_pop");
  }

  /// 🔥 ENHANCED: Verify contact and block status before allowing chat
  Future<void> _verifyContactStatus() async {
    try {
      // Priority 1: Check BlockingService (industrial-grade)
      final blockingService = BlockingService.to;
      final status = await blockingService.getBlockStatus(state.to_token.value);

      if (status.isBlocked) {
        isBlocked.value = true;
        blockStatus.value = status;

        // Apply security restrictions if I blocked them
        if (status.iBlocked) {
          await ChatSecurityService.to.applyRestrictions(
            chatDocId: doc_id,
            otherUserToken: state.to_token.value,
          );
        }

        print(
            "[ChatController] ✅ User is blocked: iBlocked=${status.iBlocked}, theyBlocked=${status.theyBlocked}");
        return; // Allow viewing chat but disable input
      }

      // Priority 2: Check ContactController (if available)
      try {
        final contactController = Get.find<ContactController>();
        bool isContact =
            await contactController.isUserContact(state.to_token.value);
        if (!isContact) {
          print("[ChatController] ⚠️ User is not a contact");
          // Note: We allow chat even if not contact (chat was already created)
          // The contact check is more for new chats
        }
      } catch (e) {
        print("[ChatController] ⚠️ ContactController not available: $e");
        // Continue anyway - user came from an existing chat
      }

      print("[ChatController] ✅ Contact verified, not blocked");
    } catch (e) {
      print("[ChatController] ❌ Error verifying contact status: $e");
    }
  }

  /// 🔥 Start real-time block monitoring - BI-DIRECTIONAL!
  void _startBlockMonitoring() {
    _blockListener?.cancel();

    _blockListener = BlockingService.to
        .watchBlockStatus(state.to_token.value)
        .listen((status) {
      print(
          "[ChatController] 🔄 Block status changed: isBlocked=${status.isBlocked}, iBlocked=${status.iBlocked}, theyBlocked=${status.theyBlocked}");

      isBlocked.value = status.isBlocked;
      blockStatus.value = status;

      if (status.isBlocked) {
        if (status.iBlocked) {
          // I blocked them - apply MY restrictions AND disable screenshots for BOTH
          ChatSecurityService.to.applyRestrictions(
            chatDocId: doc_id,
            otherUserToken: state.to_token.value,
            forceScreenshotBlock: true, // 🔥 Always block screenshots
          );
          toastInfo(msg: "🚫 You blocked ${state.to_name.value}");
        } else if (status.theyBlocked) {
          // They blocked me - disable screenshots for BOTH (even though I'm not the blocker)
          ChatSecurityService.to.applyRestrictions(
            chatDocId: doc_id,
            otherUserToken: state.to_token.value,
            forceScreenshotBlock:
                true, // 🔥 Force screenshot block even without full restrictions
          );
          toastInfo(msg: "⛔ ${state.to_name.value} has blocked you");
        }
      } else {
        // Unblocked - clear restrictions
        ChatSecurityService.to.clearRestrictions();
        toastInfo(msg: "✅ Chat with ${state.to_name.value} unblocked");
      }
    });
  }

  /// 🔥 Block user from chat with settings dialog
  Future<void> blockUserFromChat(BuildContext context) async {
    try {
      // Show confirmation
      final confirm = await Get.dialog<bool>(
        AlertDialog(
          title: Text("Block ${state.to_name.value}?"),
          content: Text("Choose privacy restrictions for this chat."),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              child: Text("Next", style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      // Show restriction settings dialog
      final restrictions = await BlockSettingsDialog.show(
        context: context,
        userName: state.to_name.value,
      );

      if (restrictions == null) return; // User cancelled

      // Block user with selected restrictions
      final success = await BlockingService.to.blockUser(
        userToken: state.to_token.value,
        userName: state.to_name.value,
        userAvatar: state.to_avatar.value,
        restrictions: restrictions,
      );

      if (success) {
        isBlocked.value = true;
        toastInfo(msg: "${state.to_name.value} has been blocked");

        // Apply restrictions immediately
        await ChatSecurityService.to.applyRestrictions(
          chatDocId: doc_id,
          otherUserToken: state.to_token.value,
        );
      } else {
        toastInfo(msg: "Failed to block user");
      }
    } catch (e) {
      print("[ChatController] ❌ Error blocking user: $e");
      toastInfo(msg: "Failed to block user");
    }
  }

  /// 🔥 Unblock user from chat
  Future<void> unblockUserFromChat() async {
    try {
      // Show confirmation
      final confirm = await Get.dialog<bool>(
        AlertDialog(
          title: Text("Unblock ${state.to_name.value}?"),
          content: Text("This user will be able to chat with you again."),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              child: Text("Unblock", style: TextStyle(color: Colors.green)),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      // Unblock user
      final success =
          await BlockingService.to.unblockUser(state.to_token.value);

      if (success) {
        isBlocked.value = false;
        blockStatus.value = null;
        await ChatSecurityService.to.clearRestrictions();
        toastInfo(msg: "${state.to_name.value} has been unblocked");
      } else {
        toastInfo(msg: "Failed to unblock user");
      }
    } catch (e) {
      print("[ChatController] ❌ Error unblocking user: $e");
      toastInfo(msg: "Failed to unblock user");
    }
  }

  ///
  @override
  void onInit() {
    super.onInit();
    print("onInit------------");
    var data = Get.parameters;
    print(data);
    doc_id = data["doc_id"];
    state.to_token.value = data["to_token"] ?? "";
    state.to_name.value = data["to_name"] ?? "";
    state.to_avatar.value = data["to_avatar"] ?? "";
    state.to_online.value = data["to_online"] ?? "1";

    // 🔥 INDUSTRIAL-GRADE BLOCKING SYSTEM
    _verifyContactStatus(); // Enhanced with BlockingService
    _startBlockMonitoring(); // Real-time updates

    // 🔥 VOICE MESSAGING SERVICE
    _voiceService = Get.find<VoiceMessageService>();
    print('[ChatController] ✅ Voice service initialized');

    // 🔥 INDUSTRIAL-GRADE DELIVERY TRACKING
    _deliveryService = Get.find<MessageDeliveryService>();
    print('[ChatController] ✅ Delivery tracking service initialized');

    clear_msg_num(doc_id);
  }

  @override
  void onReady() {
    super.onReady();
    print("onReady------------");
    state.msgcontentList.clear();
    final messages = db
        .collection("message")
        .doc(doc_id)
        .collection("msglist")
        .withConverter(
          fromFirestore: Msgcontent.fromFirestore,
          toFirestore: (Msgcontent msgcontent, options) =>
              msgcontent.toFirestore(),
        )
        .orderBy("addtime", descending: true)
        .limit(15);

    listener = messages.snapshots().listen(
      (event) {
        print("current data: ${event.docs}");
        print("current data: ${event.metadata.hasPendingWrites}");
        List<Msgcontent> tempMsgList = <Msgcontent>[];
        for (var change in event.docChanges) {
          switch (change.type) {
            case DocumentChangeType.added:
              print("added----: ${change.doc.data()}");
              if (change.doc.data() != null) {
                final msg = change.doc.data()!;

                // 🔥 BLOCK INCOMING MESSAGES from blocked users
                if (msg.token != null && msg.token != token) {
                  // This is an incoming message - check if sender is blocked
                  if (BlockingService.to.isBlockedCached(msg.token!)) {
                    print("⛔ Blocked incoming message from ${msg.token}");
                    continue; // Skip this message
                  }

                  // 🔥 V2: Smart read receipts handled by MessageVisibilityDetector
                  // No automatic marking - only when message is actually visible
                  // Mark as delivered when received
                  if (msg.id != null && msg.delivery_status == 'sent') {
                    _deliveryService.markAsDelivered(
                      chatDocId: doc_id,
                      messageId: msg.id!,
                    );
                  }
                }

                tempMsgList.add(msg);
              }
              break;
            case DocumentChangeType.modified:
              print("Modified Message: ${change.doc.data()}");
              // 🔥 INDUSTRIAL-GRADE: Handle delivery status updates
              if (change.doc.data() != null) {
                final updatedMsg = change.doc.data()!;
                // Find and update the message in the list
                final index = state.msgcontentList
                    .indexWhere((msg) => msg.id == updatedMsg.id);
                if (index != -1) {
                  state.msgcontentList[index] = updatedMsg;
                  state.msgcontentList.refresh();
                  print(
                      '[ChatController] ✅ Updated message status: ${updatedMsg.id} -> ${updatedMsg.delivery_status}');
                }
              }
              break;
            case DocumentChangeType.removed:
              print("Removed City: ${change.doc.data()}");
              break;
          }
        }
        tempMsgList.reversed.forEach((element) {
          state.msgcontentList.value.insert(0, element);
        });
        state.msgcontentList.refresh();

        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (myscrollController.hasClients) {
            myscrollController.animateTo(
              myscrollController.position.minScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      },
      onError: (error) => print("Listen failed: $error"),
    );

    myscrollController.addListener(() {
      // print(myscrollController.offset);
      //  print(myscrollController.position.maxScrollExtent);
      if ((myscrollController.offset + 10) >
          myscrollController.position.maxScrollExtent) {
        if (isloadmore) {
          state.isloading.value = true;
          isloadmore = false;
          asyncLoadMoreData(state.msgcontentList.length);
        }
      }
    });
  }

  @override
  void onClose() {
    super.onClose();
    print("onClose-------");
    clear_msg_num(doc_id);

    // 🔥 Cleanup voice recording if active
    if (isRecordingVoice.value) {
      _voiceService.cancelRecording();
      print('[ChatController] 🎤 Cancelled active recording on close');
    }

    // 🔥 Cleanup blocking resources
    _blockListener?.cancel();
    ChatSecurityService.to.clearRestrictions();
  }

  @override
  void dispose() {
    listener.cancel();
    myinputController.dispose();
    inputScrollController.dispose();
    print("dispose-------");
    super.dispose();
  }
}
