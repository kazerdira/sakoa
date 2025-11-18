// 🔥 ENHANCED INITIALIZATION - REPLACE in voice_message_player_v9.dart (starting line ~94)
// Location: chatty/lib/pages/message/chat/widgets/voice_message_player_v9.dart

/// 🚀 Initialize player - check cache and prepare if available
Future<void> _initializePlayer() async {
  try {
    _transitionTo(PlayerLifecycleState.checking, 'Initial check');

    // 🔥 NEW: Check if message is currently uploading
    final uploadStatus = _cacheManager.downloadStatus[widget.messageId];
    if (uploadStatus == VoiceDownloadStatus.uploading) {
      _log('📤 Message is uploading...');
      _transitionTo(PlayerLifecycleState.uploading, 'Waiting for upload');
      
      // Subscribe to status changes to detect when upload completes
      _subscribeToUploadCompletion();
      return;
    }

    // Check if cached
    final isCached = _cacheManager.isCached(widget.messageId);

    if (isCached) {
      _log('⚡ Found in cache - preparing immediately');
      final cachedPath = _cacheManager.getCachedPath(widget.messageId);

      if (cachedPath != null) {
        await _preparePlayerFromLocalFile(cachedPath);
      } else {
        // Metadata exists but file missing
        _log('⚠️ Cached metadata but no file - will re-download');
        _transitionTo(PlayerLifecycleState.notDownloaded);
      }
    } else {
      _log('📥 Not cached - ready for download');
      _transitionTo(PlayerLifecycleState.notDownloaded);
    }
  } catch (e) {
    _handleError('Initialization failed', e);
  }
}

/// 🔥 NEW: Subscribe to upload completion
void _subscribeToUploadCompletion() {
  // Poll for upload completion (simple approach)
  Future.delayed(Duration(milliseconds: 500), () {
    if (!mounted) return;
    
    final status = _cacheManager.downloadStatus[widget.messageId];
    
    if (status == VoiceDownloadStatus.completed) {
      _log('✅ Upload completed, checking cache...');
      _initializePlayer(); // Re-initialize now that upload is done
    } else if (status == VoiceDownloadStatus.uploading) {
      // Still uploading, keep checking
      _subscribeToUploadCompletion();
    } else {
      // Upload failed or cancelled
      _log('⚠️ Upload did not complete: $status');
      _transitionTo(PlayerLifecycleState.notDownloaded);
    }
  });
}
