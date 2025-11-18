// 🔥 ENHANCED VOICE CACHE MANAGER - ADD THESE METHODS
// Location: chatty/lib/common/services/voice_cache_manager.dart
// Add these methods after the "PUBLIC API" comment (around line 64)

/// 🔥 PRE-CACHE: Cache a local file immediately (for sender's own recordings)
/// This allows instant playback of just-recorded messages without download
Future<bool> preCacheLocalFile({
  required String messageId,
  required String localFilePath,
  required String audioUrl,
}) async {
  try {
    print('[VoiceCacheManager] 🎤 Pre-caching local recording: $messageId');

    // Check if file exists
    final localFile = File(localFilePath);
    if (!await localFile.exists()) {
      print('[VoiceCacheManager] ❌ Local file not found: $localFilePath');
      return false;
    }

    // Copy to cache directory with proper name
    final cachedPath = _getCachedFilePath(messageId);
    
    // Create parent directory if it doesn't exist
    final cacheFile = File(cachedPath);
    if (!await cacheFile.parent.exists()) {
      await cacheFile.parent.create(recursive: true);
    }
    
    // Copy the file
    await localFile.copy(cachedPath);

    // Get file size
    final fileSize = await File(cachedPath).length();

    // Save metadata
    await _addCacheEntry(
      messageId: messageId,
      audioUrl: audioUrl,
      filePath: cachedPath,
      fileSize: fileSize,
    );

    // Set status as completed
    downloadStatus[messageId] = VoiceDownloadStatus.completed;
    downloadProgress[messageId] = 1.0;

    print('[VoiceCacheManager] ✅ Pre-cached successfully: $messageId (${fileSize ~/ 1024}KB)');
    return true;
  } catch (e, stackTrace) {
    print('[VoiceCacheManager] ❌ Pre-cache failed: $e');
    print('[VoiceCacheManager] Stack trace: $stackTrace');
    return false;
  }
}

/// Get cached file path (returns null if not cached)
String? getCachedPath(String messageId) {
  if (!isCached(messageId)) return null;
  final path = _getCachedFilePath(messageId);
  return File(path).existsSync() ? path : null;
}

/// 🔥 OPTIMISTIC: Mark message as uploading (for UI feedback)
void markAsUploading(String messageId) {
  downloadStatus[messageId] = VoiceDownloadStatus.uploading;
  downloadProgress[messageId] = 0.0;
  print('[VoiceCacheManager] 📤 Marked as uploading: $messageId');
}

/// 🔥 OPTIMISTIC: Mark upload as complete
void markUploadComplete(String messageId) {
  downloadStatus[messageId] = VoiceDownloadStatus.completed;
  downloadProgress[messageId] = 1.0;
  print('[VoiceCacheManager] ✅ Upload complete: $messageId');
}
