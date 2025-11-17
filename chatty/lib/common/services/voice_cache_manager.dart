import 'dart:async';
import 'dart:io';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:get_storage/get_storage.dart';

/// 🔥 SUPERNOVA-LEVEL VOICE CACHE MANAGER
/// Industrial-grade voice message caching system (Telegram/WhatsApp standard):
/// - Automatic download queue with priority
/// - LRU (Least Recently Used) cache eviction
/// - Smart pre-fetching (visible + next 10 messages)
/// - Download progress tracking (0-100%)
/// - Storage size management
/// - Offline playback support
/// - Parallel downloads (max 3 concurrent)
/// - Exponential backoff retry
class VoiceCacheManager extends GetxService {
  static VoiceCacheManager get to => Get.find();

  final Dio _dio = Dio();
  final _storage = GetStorage('voice_cache_metadata');

  // Cache directory
  late Directory _cacheDir;

  // Download queue (priority: high → low)
  final _downloadQueue = <VoiceDownloadTask>[].obs;
  final _activeDownloads = <String, CancelToken>{}; // messageId → CancelToken

  // Download progress tracking (messageId → progress 0-1.0)
  final downloadProgress = <String, double>{}.obs;

  // Download status (messageId → status)
  final downloadStatus = <String, VoiceDownloadStatus>{}.obs;

  // Cache metadata (messageId → metadata)
  final _cacheMetadata = <String, VoiceCacheEntry>{};

  // Configuration
  static const MAX_CACHE_SIZE_MB = 100; // 100 MB total cache
  static const MAX_CACHED_FILES = 50; // Keep last 50 voice messages
  static const MAX_CONCURRENT_DOWNLOADS = 3;
  static const RETRY_DELAYS = [
    Duration(seconds: 2),
    Duration(seconds: 5),
    Duration(seconds: 10),
  ];

  /// Initialize cache manager
  Future<VoiceCacheManager> init() async {
    await GetStorage.init('voice_cache_metadata');

    // Create cache directory
    final appDir = await getApplicationDocumentsDirectory();
    _cacheDir = Directory('${appDir.path}/voice_cache');
    if (!await _cacheDir.exists()) {
      await _cacheDir.create(recursive: true);
    }

    // Load cache metadata from disk
    await _loadCacheMetadata();

    // Start download worker
    _startDownloadWorker();

    // Cleanup old/corrupted files
    await _cleanupInvalidFiles();

    print(
        '[VoiceCacheManager] ✅ Initialized with ${_cacheMetadata.length} cached files');
    return this;
  }

  // ============ PUBLIC API ============

  /// Get local file path for voice message (download if not cached)
  Future<String?> getVoiceFile({
    required String messageId,
    required String audioUrl,
    VoiceDownloadPriority priority = VoiceDownloadPriority.normal,
  }) async {
    // 1. Check if already cached
    if (isCached(messageId)) {
      final cachedPath = _getCachedFilePath(messageId);
      if (await File(cachedPath).exists()) {
        // Update last accessed time (for LRU)
        await _touchCacheEntry(messageId);
        print('[VoiceCacheManager] ✅ Cache hit: $messageId');
        return cachedPath;
      } else {
        // Metadata exists but file missing → clean up
        await _removeCacheEntry(messageId);
      }
    }

    // 2. Check if already downloading
    if (isDownloading(messageId)) {
      print('[VoiceCacheManager] ⏳ Already downloading: $messageId');

      // Wait for download to complete
      await _waitForDownload(messageId);

      if (isCached(messageId)) {
        return _getCachedFilePath(messageId);
      } else {
        return null; // Download failed
      }
    }

    // 3. Queue for download
    await queueDownload(
      messageId: messageId,
      audioUrl: audioUrl,
      priority: priority,
    );

    // 4. Wait for download to complete
    await _waitForDownload(messageId);

    if (isCached(messageId)) {
      return _getCachedFilePath(messageId);
    } else {
      return null; // Download failed
    }
  }

  /// Queue a voice message for download
  Future<void> queueDownload({
    required String messageId,
    required String audioUrl,
    VoiceDownloadPriority priority = VoiceDownloadPriority.normal,
  }) async {
    // Skip if already cached or downloading
    if (isCached(messageId) || isDownloading(messageId)) {
      return;
    }

    // Add to queue
    final task = VoiceDownloadTask(
      messageId: messageId,
      audioUrl: audioUrl,
      priority: priority,
      attempts: 0,
    );

    _downloadQueue.add(task);

    // Sort by priority (high → low)
    _downloadQueue.sort((a, b) => b.priority.index.compareTo(a.priority.index));

    // Set initial status
    downloadStatus[messageId] = VoiceDownloadStatus.queued;

    print(
        '[VoiceCacheManager] 📥 Queued download: $messageId (priority: ${priority.name})');
  }

  /// Pre-fetch multiple voice messages (for chat screen)
  Future<void> prefetchVoiceMessages(
      List<VoicePrefetchRequest> requests) async {
    for (final request in requests) {
      await queueDownload(
        messageId: request.messageId,
        audioUrl: request.audioUrl,
        priority: request.priority,
      );
    }
    print(
        '[VoiceCacheManager] 🚀 Pre-fetching ${requests.length} voice messages');
  }

  /// Check if voice message is cached locally
  bool isCached(String messageId) {
    return _cacheMetadata.containsKey(messageId);
  }

  /// Check if voice message is currently downloading
  bool isDownloading(String messageId) {
    final status = downloadStatus[messageId];
    return status == VoiceDownloadStatus.downloading ||
        status == VoiceDownloadStatus.queued;
  }

  /// Get download progress (0.0 - 1.0)
  double getDownloadProgress(String messageId) {
    return downloadProgress[messageId] ?? 0.0;
  }

  /// Cancel download
  Future<void> cancelDownload(String messageId) async {
    final cancelToken = _activeDownloads[messageId];
    if (cancelToken != null) {
      cancelToken.cancel('User cancelled');
      _activeDownloads.remove(messageId);
      downloadStatus[messageId] = VoiceDownloadStatus.cancelled;
      downloadProgress[messageId] = 0.0;
      print('[VoiceCacheManager] ❌ Cancelled download: $messageId');
    }
  }

  /// Get cached file path (if exists)
  String? getCachedPath(String messageId) {
    if (isCached(messageId)) {
      return _getCachedFilePath(messageId);
    }
    return null;
  }

  /// Clear all cached voice messages
  Future<void> clearCache() async {
    try {
      // Delete all files
      if (await _cacheDir.exists()) {
        await _cacheDir.delete(recursive: true);
        await _cacheDir.create(recursive: true);
      }

      // Clear metadata
      _cacheMetadata.clear();
      await _storage.erase();

      // Reset status
      downloadProgress.clear();
      downloadStatus.clear();

      print('[VoiceCacheManager] 🗑️ Cache cleared');
    } catch (e) {
      print('[VoiceCacheManager] ❌ Failed to clear cache: $e');
    }
  }

  /// Get total cache size in bytes
  Future<int> getCacheSize() async {
    try {
      int totalSize = 0;
      if (await _cacheDir.exists()) {
        final files = _cacheDir.listSync();
        for (final file in files) {
          if (file is File) {
            totalSize += await file.length();
          }
        }
      }
      return totalSize;
    } catch (e) {
      return 0;
    }
  }

  /// Get cache size in MB
  Future<double> getCacheSizeMB() async {
    final bytes = await getCacheSize();
    return bytes / (1024 * 1024);
  }

  // ============ DOWNLOAD WORKER ============

  void _startDownloadWorker() {
    // Process download queue every 500ms
    Timer.periodic(Duration(milliseconds: 500), (_) {
      _processDownloadQueue();
    });
  }

  Future<void> _processDownloadQueue() async {
    // Skip if no tasks or max concurrent downloads reached
    if (_downloadQueue.isEmpty ||
        _activeDownloads.length >= MAX_CONCURRENT_DOWNLOADS) {
      return;
    }

    // Get next task
    final task = _downloadQueue.removeAt(0);

    // Start download
    await _downloadVoiceMessage(task);
  }

  Future<void> _downloadVoiceMessage(VoiceDownloadTask task) async {
    final messageId = task.messageId;
    final audioUrl = task.audioUrl;

    try {
      print(
          '[VoiceCacheManager] ⬇️ Downloading: $messageId (attempt ${task.attempts + 1})');

      // Update status
      downloadStatus[messageId] = VoiceDownloadStatus.downloading;
      downloadProgress[messageId] = 0.0;

      // Create cancel token
      final cancelToken = CancelToken();
      _activeDownloads[messageId] = cancelToken;

      // Download file
      final filePath = _getCachedFilePath(messageId);
      await _dio.download(
        audioUrl,
        filePath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            final progress = received / total;
            downloadProgress[messageId] = progress;
          }
        },
      );

      // Download complete
      _activeDownloads.remove(messageId);
      downloadStatus[messageId] = VoiceDownloadStatus.completed;
      downloadProgress[messageId] = 1.0;

      // Get file size
      final file = File(filePath);
      final fileSize = await file.length();

      // Save metadata
      await _addCacheEntry(
        messageId: messageId,
        audioUrl: audioUrl,
        filePath: filePath,
        fileSize: fileSize,
      );

      print(
          '[VoiceCacheManager] ✅ Downloaded: $messageId (${fileSize ~/ 1024}KB)');

      // Check cache size and evict if needed
      await _enforceStorageLimits();
    } catch (e) {
      _activeDownloads.remove(messageId);

      if (e is DioException && e.type == DioExceptionType.cancel) {
        // User cancelled
        downloadStatus[messageId] = VoiceDownloadStatus.cancelled;
        downloadProgress[messageId] = 0.0;
        print('[VoiceCacheManager] ❌ Download cancelled: $messageId');
        return;
      }

      // Download failed - retry with exponential backoff
      print('[VoiceCacheManager] ❌ Download failed: $messageId - $e');

      if (task.attempts < RETRY_DELAYS.length) {
        // Retry
        final retryDelay = RETRY_DELAYS[task.attempts];
        downloadStatus[messageId] = VoiceDownloadStatus.retrying;

        print('[VoiceCacheManager] 🔄 Retrying in ${retryDelay.inSeconds}s...');

        await Future.delayed(retryDelay);

        // Re-queue with incremented attempts
        _downloadQueue.add(VoiceDownloadTask(
          messageId: task.messageId,
          audioUrl: task.audioUrl,
          priority: task.priority,
          attempts: task.attempts + 1,
        ));
      } else {
        // Max retries reached
        downloadStatus[messageId] = VoiceDownloadStatus.failed;
        downloadProgress[messageId] = 0.0;
        print('[VoiceCacheManager] ❌ Max retries reached: $messageId');
      }
    }
  }

  // ============ CACHE MANAGEMENT ============

  Future<void> _addCacheEntry({
    required String messageId,
    required String audioUrl,
    required String filePath,
    required int fileSize,
  }) async {
    final entry = VoiceCacheEntry(
      messageId: messageId,
      audioUrl: audioUrl,
      filePath: filePath,
      fileSize: fileSize,
      cachedAt: DateTime.now(),
      lastAccessed: DateTime.now(),
    );

    _cacheMetadata[messageId] = entry;
    await _saveCacheMetadata();
  }

  Future<void> _removeCacheEntry(String messageId) async {
    final entry = _cacheMetadata[messageId];
    if (entry != null) {
      // Delete file
      final file = File(entry.filePath);
      if (await file.exists()) {
        await file.delete();
      }

      // Remove metadata
      _cacheMetadata.remove(messageId);
      await _saveCacheMetadata();

      print('[VoiceCacheManager] 🗑️ Removed cache entry: $messageId');
    }
  }

  Future<void> _touchCacheEntry(String messageId) async {
    final entry = _cacheMetadata[messageId];
    if (entry != null) {
      entry.lastAccessed = DateTime.now();
      await _saveCacheMetadata();
    }
  }

  Future<void> _enforceStorageLimits() async {
    // 1. Check total cache size
    final cacheSizeBytes = await getCacheSize();
    final cacheSizeMB = cacheSizeBytes / (1024 * 1024);

    if (cacheSizeMB > MAX_CACHE_SIZE_MB ||
        _cacheMetadata.length > MAX_CACHED_FILES) {
      print(
          '[VoiceCacheManager] 🧹 Cache limit exceeded (${cacheSizeMB.toStringAsFixed(1)}MB / ${_cacheMetadata.length} files)');
      await _evictLRU();
    }
  }

  Future<void> _evictLRU() async {
    // Sort by last accessed time (oldest first)
    final sortedEntries = _cacheMetadata.values.toList()
      ..sort((a, b) => a.lastAccessed.compareTo(b.lastAccessed));

    // Remove oldest 20% of files
    final toRemove = (sortedEntries.length * 0.2).ceil();

    print(
        '[VoiceCacheManager] 🗑️ Evicting $toRemove oldest cache entries (LRU)...');

    for (int i = 0; i < toRemove && i < sortedEntries.length; i++) {
      await _removeCacheEntry(sortedEntries[i].messageId);
    }

    print('[VoiceCacheManager] ✅ Eviction complete');
  }

  Future<void> _cleanupInvalidFiles() async {
    try {
      // Find all files in cache directory
      if (!await _cacheDir.exists()) return;

      final files = _cacheDir.listSync();
      int cleaned = 0;

      for (final file in files) {
        if (file is File) {
          final fileName = file.path.split(Platform.pathSeparator).last;
          final messageId = fileName.replaceAll('.m4a', '');

          // Check if metadata exists
          if (!_cacheMetadata.containsKey(messageId)) {
            // Orphaned file - delete
            await file.delete();
            cleaned++;
          }
        }
      }

      if (cleaned > 0) {
        print('[VoiceCacheManager] 🧹 Cleaned up $cleaned orphaned files');
      }
    } catch (e) {
      print('[VoiceCacheManager] ❌ Cleanup failed: $e');
    }
  }

  // ============ PERSISTENCE ============

  Future<void> _loadCacheMetadata() async {
    try {
      final data = _storage.read<Map<String, dynamic>>('cache_metadata');
      if (data != null) {
        data.forEach((key, value) {
          _cacheMetadata[key] =
              VoiceCacheEntry.fromJson(Map<String, dynamic>.from(value));
        });
        print(
            '[VoiceCacheManager] 📥 Loaded ${_cacheMetadata.length} cache entries');
      }
    } catch (e) {
      print('[VoiceCacheManager] ⚠️ Failed to load cache metadata: $e');
    }
  }

  Future<void> _saveCacheMetadata() async {
    try {
      final data =
          _cacheMetadata.map((key, value) => MapEntry(key, value.toJson()));
      await _storage.write('cache_metadata', data);
    } catch (e) {
      print('[VoiceCacheManager] ⚠️ Failed to save cache metadata: $e');
    }
  }

  // ============ HELPERS ============

  String _getCachedFilePath(String messageId) {
    return '${_cacheDir.path}/$messageId.m4a';
  }

  Future<void> _waitForDownload(String messageId,
      {Duration timeout = const Duration(minutes: 2)}) async {
    final startTime = DateTime.now();

    while (isDownloading(messageId)) {
      // Check timeout
      if (DateTime.now().difference(startTime) > timeout) {
        print('[VoiceCacheManager] ⏱️ Download timeout: $messageId');
        await cancelDownload(messageId);
        return;
      }

      // Wait 500ms and check again
      await Future.delayed(Duration(milliseconds: 500));
    }
  }

  @override
  void onClose() {
    print('[VoiceCacheManager] 🛑 Shutting down...');

    // Cancel all active downloads
    for (final cancelToken in _activeDownloads.values) {
      cancelToken.cancel('Service shutting down');
    }

    super.onClose();
  }
}

// ============ DATA MODELS ============

class VoiceDownloadTask {
  final String messageId;
  final String audioUrl;
  final VoiceDownloadPriority priority;
  final int attempts;

  VoiceDownloadTask({
    required this.messageId,
    required this.audioUrl,
    required this.priority,
    required this.attempts,
  });
}

enum VoiceDownloadPriority {
  high, // Visible messages
  normal, // Next 10 messages
  low, // Background pre-fetch
}

enum VoiceDownloadStatus {
  queued,
  downloading,
  retrying,
  completed,
  failed,
  cancelled,
}

class VoiceCacheEntry {
  final String messageId;
  final String audioUrl;
  final String filePath;
  final int fileSize;
  final DateTime cachedAt;
  DateTime lastAccessed;

  VoiceCacheEntry({
    required this.messageId,
    required this.audioUrl,
    required this.filePath,
    required this.fileSize,
    required this.cachedAt,
    required this.lastAccessed,
  });

  Map<String, dynamic> toJson() => {
        'messageId': messageId,
        'audioUrl': audioUrl,
        'filePath': filePath,
        'fileSize': fileSize,
        'cachedAt': cachedAt.toIso8601String(),
        'lastAccessed': lastAccessed.toIso8601String(),
      };

  factory VoiceCacheEntry.fromJson(Map<String, dynamic> json) =>
      VoiceCacheEntry(
        messageId: json['messageId'],
        audioUrl: json['audioUrl'],
        filePath: json['filePath'],
        fileSize: json['fileSize'],
        cachedAt: DateTime.parse(json['cachedAt']),
        lastAccessed: DateTime.parse(json['lastAccessed']),
      );
}

class VoicePrefetchRequest {
  final String messageId;
  final String audioUrl;
  final VoiceDownloadPriority priority;

  VoicePrefetchRequest({
    required this.messageId,
    required this.audioUrl,
    this.priority = VoiceDownloadPriority.normal,
  });
}
