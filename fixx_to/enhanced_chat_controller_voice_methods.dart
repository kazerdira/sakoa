// 🔥 ENHANCED VOICE SENDING - REPLACE in controller.dart (starting line ~356)
// Location: chatty/lib/pages/message/chat/controller.dart

/// Stop recording and send voice message WITH OPTIMISTIC CACHING
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

    // Show uploading indicator
    EasyLoading.show(
      status: 'Uploading voice message...',
      maskType: EasyLoadingMaskType.clear,
    );

    // Upload to Firebase Storage
    print('[ChatController] ☁️ Uploading voice message...');
    final audioUrl = await _voiceService.uploadVoiceMessage(localPath);

    if (audioUrl == null) {
      EasyLoading.dismiss();
      print('[ChatController] ❌ Upload failed');
      return;
    }

    // 🔥 CRITICAL: Send message and get message ID BEFORE pre-caching
    final messageId = await sendVoiceMessageWithPreCache(
      audioUrl, 
      _voiceService.recordingDuration.value,
      localPath,
    );

    EasyLoading.dismiss();
    
    if (messageId != null) {
      print('[ChatController] ✅ Voice message sent and pre-cached successfully');
    } else {
      print('[ChatController] ⚠️ Voice message sent but pre-cache may have failed');
    }
  } catch (e, stackTrace) {
    print('[ChatController] ❌ Failed to send voice message: $e');
    print('[ChatController] Stack trace: $stackTrace');
    EasyLoading.dismiss();
    toastInfo(msg: "Failed to send voice message");
    isRecordingVoice.value = false;
  }
}

/// Send voice message to Firestore WITH OPTIMISTIC CACHING
/// Returns the message ID for pre-caching
Future<String?> sendVoiceMessageWithPreCache(
  String audioUrl, 
  Duration duration,
  String localPath,
) async {
  try {
    print('[ChatController] 📤 Sending voice message to Firestore...');

    // Create voice message content
    final content = Msgcontent(
      token: token,
      content: audioUrl,
      type: "voice",
      addtime: Timestamp.now(),
      voice_duration: duration.inSeconds,
      reply: isReplyMode.value ? replyingTo.value : null,
    );

    // 🔥 INDUSTRIAL-GRADE: Send with delivery tracking
    final result = await _deliveryService.sendMessageWithTracking(
      chatDocId: doc_id,
      content: content,
    );

    if (result.success || result.queued) {
      print('[ChatController] ✅ Voice message sent: ${result.messageId}');

      // 🔥 CRITICAL: Pre-cache the local recording for instant playback
      if (result.messageId != null && localPath.isNotEmpty) {
        print('[ChatController] 🎯 Pre-caching local recording...');
        
        final cacheManager = VoiceCacheManager.to;
        
        // Mark as uploading first (for UI)
        cacheManager.markAsUploading(result.messageId!);
        
        // Pre-cache the file
        final preCached = await cacheManager.preCacheLocalFile(
          messageId: result.messageId!,
          localFilePath: localPath,
          audioUrl: audioUrl,
        );
        
        if (preCached) {
          print('[ChatController] ✅ Sender can now play immediately!');
          cacheManager.markUploadComplete(result.messageId!);
        } else {
          print('[ChatController] ⚠️ Pre-cache failed, will download normally');
        }
      }

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

      sendNotifications("voice");
      clearReplyMode();
      
      return result.messageId;
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

// 🔥 DEPRECATED: Keep old method for backward compatibility, but redirect to new one
Future<void> sendVoiceMessage(String audioUrl, Duration duration) async {
  // This method is no longer used - stopAndSendVoiceMessage handles everything
  print('[ChatController] ⚠️ sendVoiceMessage called directly - use stopAndSendVoiceMessage instead');
}
