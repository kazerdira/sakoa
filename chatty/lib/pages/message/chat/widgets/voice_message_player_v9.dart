import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sakoa/common/services/voice_cache_manager.dart';

/// 🎵 VoiceMessagePlayerV10 - INDUSTRIAL-GRADE VOICE PLAYER
///
/// FIXES:
/// ✅ Eliminated double subscription bug
/// ✅ Proper state machine with clear transitions
/// ✅ Automatic retry on errors
/// ✅ Smart cache checking with refresh
/// ✅ Lifecycle-safe cleanup
/// ✅ Progress tracking only during actual downloads
/// ✅ Debounced play button to prevent double-taps
/// ✅ Fixed auto-play after download completion
class VoiceMessagePlayerV10 extends StatefulWidget {
  final String messageId;
  final String audioUrl;
  final bool isMyMessage;
  final String? duration;
  final bool isUploading; // 🔥 NEW: Track if message is still uploading

  const VoiceMessagePlayerV10({
    Key? key,
    required this.messageId,
    required this.audioUrl,
    required this.isMyMessage,
    this.duration,
    this.isUploading = false, // Default to false for existing messages
  }) : super(key: key);

  @override
  State<VoiceMessagePlayerV10> createState() => _VoiceMessagePlayerV10State();
}

class _VoiceMessagePlayerV10State extends State<VoiceMessagePlayerV10> {
  late final PlayerController _controller;

  // Subscriptions - CENTRALIZED cleanup
  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<Map<String, double>>? _progressSubscription;

  // State machine
  PlayerLifecycleState _lifecycleState = PlayerLifecycleState.uninitialized;
  double _downloadProgress = 0.0;
  String? _errorMessage;

  // Debouncing
  bool _isProcessingAction = false;
  DateTime? _lastActionTime;

  // Flag to track if we should auto-play after preparation
  bool _shouldAutoPlayAfterPrepare = false;

  // Cache manager
  final _cacheManager = VoiceCacheManager.to;

  // Retry tracking
  int _retryCount = 0;
  static const MAX_RETRIES = 3;

  @override
  void initState() {
    super.initState();
    _log('🎵 Initializing player');

    _controller = PlayerController();

    // Subscribe to player state changes
    _playerStateSubscription = _controller.onPlayerStateChanged.listen(
      _handlePlayerStateChange,
      onError: (error) => _log('❌ Player state error: $error'),
    );

    // Initial cache check
    _initializePlayer();
  }

  /// 🔄 State transition logger
  void _transitionTo(PlayerLifecycleState newState, [String? reason]) {
    if (_lifecycleState != newState) {
      _log(
          '🔄 State: ${_lifecycleState.name} → ${newState.name}${reason != null ? ' ($reason)' : ''}');
      if (mounted) {
        setState(() {
          _lifecycleState = newState;

          // Clear error when transitioning away from error state
          if (newState != PlayerLifecycleState.error) {
            _errorMessage = null;
          }
        });
      }
    }
  }

  /// 🚀 Initialize player - check cache and prepare if available
  Future<void> _initializePlayer() async {
    try {
      // 🔥 NEW: If message is still uploading, show spinner
      if (widget.isUploading) {
        _log('☁️ Message is uploading...');
        _transitionTo(PlayerLifecycleState.uploading, 'Upload in progress');
        return; // Don't proceed until upload completes
      }

      _transitionTo(PlayerLifecycleState.checking, 'Initial check');

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

  /// 📥 Download and prepare player
  Future<void> _downloadAndPrepare({bool autoPlay = false}) async {
    // Prevent double-execution
    if (_isProcessingAction) {
      _log('⏳ Already processing - ignoring tap');
      return;
    }

    _isProcessingAction = true;

    try {
      _transitionTo(PlayerLifecycleState.downloading, 'Starting download');

      // Set auto-play flag
      _shouldAutoPlayAfterPrepare = autoPlay;

      // Reset progress
      if (mounted) {
        setState(() {
          _downloadProgress = 0.0;
        });
      }

      // Subscribe to progress ONLY if not cached
      await _subscribeToProgress();

      // Get voice file (downloads if needed, returns immediately if cached)
      final localPath = await _cacheManager.getVoiceFile(
        messageId: widget.messageId,
        audioUrl: widget.audioUrl,
        priority: VoiceDownloadPriority.high,
      );

      // ALWAYS cleanup progress subscription
      await _cleanupProgressSubscription();

      if (localPath == null) {
        throw Exception('Download returned null');
      }

      _log('✅ Download complete: $localPath');

      // Prepare player
      await _preparePlayerFromLocalFile(localPath);

      // Reset retry count on success
      _retryCount = 0;

      // Clear action flag BEFORE returning (not in finally)
      _isProcessingAction = false;
    } catch (e) {
      await _cleanupProgressSubscription();
      _isProcessingAction = false;
      _shouldAutoPlayAfterPrepare = false; // Clear auto-play flag on error
      _handleError('Download/prepare failed', e);
    }
  }

  /// 📊 Prepare player from local file
  Future<void> _preparePlayerFromLocalFile(String localPath) async {
    try {
      _transitionTo(PlayerLifecycleState.preparing, 'Loading audio');

      await _controller.preparePlayer(
        path: localPath,
        shouldExtractWaveform: true,
        noOfSamples: 200,
      );

      await _controller.setFinishMode(finishMode: FinishMode.pause);

      _log('✅ Player prepared');

      // Don't manually transition here - let the state listener handle it
      // The listener will check _shouldAutoPlayAfterPrepare and auto-play if needed
    } catch (e) {
      _shouldAutoPlayAfterPrepare = false; // Clear auto-play flag on error
      _handleError('Prepare failed', e);
    }
  }

  /// 📊 Subscribe to download progress
  Future<void> _subscribeToProgress() async {
    // Cleanup any existing subscription first
    await _cleanupProgressSubscription();

    // Only subscribe if file is NOT cached
    if (!_cacheManager.isCached(widget.messageId)) {
      _log('📊 Subscribing to download progress');

      _progressSubscription = _cacheManager.downloadProgress.listen(
        (progressMap) {
          final progress = progressMap[widget.messageId];
          if (progress != null && mounted) {
            setState(() {
              _downloadProgress = progress;
            });
          }
        },
        onError: (error) => _log('❌ Progress stream error: $error'),
        cancelOnError: false,
      );
    } else {
      _log('⚡ File cached - skipping progress subscription');
      if (mounted) {
        setState(() {
          _downloadProgress = 1.0;
        });
      }
    }
  }

  /// 🧹 Cleanup progress subscription
  Future<void> _cleanupProgressSubscription() async {
    if (_progressSubscription != null) {
      _log('🧹 Cleaning up progress subscription');
      await _progressSubscription!.cancel();
      _progressSubscription = null;
    }
  }

  /// ▶️ Play/pause toggle
  Future<void> _togglePlayPause() async {
    _log(
        '👆 Button tapped - current state: ${_lifecycleState.name}, isProcessingAction: $_isProcessingAction');

    // Debounce rapid taps
    final now = DateTime.now();
    if (_lastActionTime != null &&
        now.difference(_lastActionTime!) < Duration(milliseconds: 500)) {
      _log('⏳ Debounced tap');
      return;
    }
    _lastActionTime = now;

    // Prevent concurrent actions
    if (_isProcessingAction) {
      _log('⏳ Action in progress - ignoring tap');
      return;
    }

    switch (_lifecycleState) {
      case PlayerLifecycleState.error:
        // Retry on error
        _log('🔄 Retrying after error');
        await _retry();
        break;

      case PlayerLifecycleState.uploading:
        // Do nothing - wait for upload to complete
        _log('☁️ Upload in progress, please wait...');
        break;

      case PlayerLifecycleState.notDownloaded:
      case PlayerLifecycleState.checking:
        // Download and prepare WITHOUT auto-play
        _log('📥 Starting download and prepare...');
        await _downloadAndPrepare(autoPlay: false);
        break;

      case PlayerLifecycleState.downloading:
      case PlayerLifecycleState.preparing:
        // Do nothing - wait for current operation
        _log('⏳ ${_lifecycleState.name} in progress');
        break;

      case PlayerLifecycleState.ready:
        // Play
        await _play();
        break;

      case PlayerLifecycleState.playing:
        // Pause
        await _pause();
        break;

      case PlayerLifecycleState.paused:
        // Resume
        await _play();
        break;

      case PlayerLifecycleState.uninitialized:
        // Re-initialize
        await _initializePlayer();
        break;
    }
  }

  /// ▶️ Play
  Future<void> _play() async {
    try {
      await _controller.startPlayer();
      _transitionTo(PlayerLifecycleState.playing, 'Playing');
    } catch (e) {
      _handleError('Play failed', e);
    }
  }

  /// ⏸️ Pause
  Future<void> _pause() async {
    try {
      await _controller.pausePlayer();
      _transitionTo(PlayerLifecycleState.paused, 'Paused');
    } catch (e) {
      _handleError('Pause failed', e);
    }
  }

  /// 🔄 Retry after error
  Future<void> _retry() async {
    if (_retryCount >= MAX_RETRIES) {
      _log('❌ Max retries reached');
      _handleError('Max retries exceeded', null);
      return;
    }

    _retryCount++;
    _log('🔄 Retry attempt $_retryCount/$MAX_RETRIES');

    // Reset state and try again with auto-play
    _transitionTo(PlayerLifecycleState.notDownloaded, 'Retrying');
    await _downloadAndPrepare(autoPlay: true);
  }

  /// ⚠️ Handle errors
  void _handleError(String message, dynamic error) {
    _log('❌ $message: $error');

    if (mounted) {
      setState(() {
        _errorMessage =
            _retryCount < MAX_RETRIES ? 'Tap to retry' : 'Download failed';
        _downloadProgress = 0.0;
      });
    }

    _transitionTo(PlayerLifecycleState.error, message);
  }

  /// 🎵 Handle player state changes
  void _handlePlayerStateChange(PlayerState state) {
    _log('🎵 Player state: $state (isPlaying: ${state.isPlaying})');

    if (!mounted) return;

    // Update lifecycle state based on player state
    if (state == PlayerState.initialized &&
        _lifecycleState == PlayerLifecycleState.preparing) {
      // Player finished preparing and is ready
      _transitionTo(PlayerLifecycleState.ready, 'Player initialized');

      // IMPORTANT: Clear the processing flag now that we're ready
      _isProcessingAction = false;
      _log('🔓 Cleared processing flag - ready for interaction');

      // Check if we should auto-play
      if (_shouldAutoPlayAfterPrepare) {
        _log('▶️ Auto-playing after preparation');
        _shouldAutoPlayAfterPrepare = false; // Reset flag
        _play(); // Auto-play
      }
    } else if (state.isPlaying) {
      _transitionTo(PlayerLifecycleState.playing);
    } else if (_lifecycleState == PlayerLifecycleState.playing) {
      // Was playing, now stopped
      _transitionTo(PlayerLifecycleState.paused);
    }
  }

  /// 📝 Logging helper
  void _log(String message) {
    print('[PlayerV10:${widget.messageId.substring(0, 8)}] $message');
  }

  @override
  void dispose() {
    _log('🗑️ Disposing');

    // Cleanup all subscriptions
    _playerStateSubscription?.cancel();
    _cleanupProgressSubscription();

    // Dispose controller
    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildControlButton(),
        const SizedBox(width: 8),
        Expanded(child: _buildWaveformArea()),
        const SizedBox(width: 8),
        _buildDuration(),
      ],
    );
  }

  /// 🎛️ Control button
  Widget _buildControlButton() {
    final isMyMsg = widget.isMyMessage;
    final primaryColor = isMyMsg ? Colors.white : Colors.grey.shade700;
    final bgColor =
        isMyMsg ? primaryColor.withOpacity(0.2) : Colors.grey.shade200;

    Widget icon;
    Color iconColor = primaryColor;

    switch (_lifecycleState) {
      case PlayerLifecycleState.error:
        icon = Icon(Icons.refresh, size: 20, color: Colors.red.shade700);
        iconColor = Colors.red.shade700;
        break;

      // 🔥 NEW: Show spinner while uploading to Firebase (sender only)
      case PlayerLifecycleState.uploading:
        return _buildLoadingIndicator(bgColor, iconColor);

      case PlayerLifecycleState.downloading:
        return _buildProgressIndicator();

      case PlayerLifecycleState.preparing:
      case PlayerLifecycleState.checking:
        return _buildLoadingIndicator(bgColor, iconColor);

      case PlayerLifecycleState.notDownloaded:
      case PlayerLifecycleState.uninitialized:
        icon = Icon(Icons.cloud_download_outlined, size: 20, color: iconColor);
        break;

      case PlayerLifecycleState.playing:
        icon = Icon(Icons.pause,
            size: 20, color: isMyMsg ? Color(0xFF128C7E) : Colors.white);
        iconColor = isMyMsg ? Color(0xFF128C7E) : Colors.white;
        break;

      case PlayerLifecycleState.ready:
      case PlayerLifecycleState.paused:
        icon = Icon(Icons.play_arrow,
            size: 20, color: isMyMsg ? Color(0xFF128C7E) : Colors.white);
        iconColor = isMyMsg ? Color(0xFF128C7E) : Colors.white;
        break;
    }

    final isPlayable = _lifecycleState == PlayerLifecycleState.ready ||
        _lifecycleState == PlayerLifecycleState.playing ||
        _lifecycleState == PlayerLifecycleState.paused;

    return GestureDetector(
      onTap: _togglePlayPause,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isPlayable ? primaryColor : bgColor,
        ),
        child: icon,
      ),
    );
  }

  /// ⏳ Progress indicator (downloading)
  Widget _buildProgressIndicator() {
    final isMyMsg = widget.isMyMessage;
    final color = isMyMsg ? Color(0xFF128C7E) : Colors.grey.shade600;

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.2),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 30,
            height: 30,
            child: CircularProgressIndicator(
              value: _downloadProgress > 0 ? _downloadProgress : null,
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation(color),
              backgroundColor: Colors.grey.shade300,
            ),
          ),
          Text(
            '${(_downloadProgress * 100).toInt()}',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// ⏳ Loading indicator (preparing/checking)
  Widget _buildLoadingIndicator(Color bgColor, Color iconColor) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bgColor,
      ),
      child: SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation(iconColor),
        ),
      ),
    );
  }

  /// 📊 Waveform area
  Widget _buildWaveformArea() {
    final isMyMsg = widget.isMyMessage;
    final color = isMyMsg ? Colors.white : Colors.grey.shade600;

    // Error state
    if (_lifecycleState == PlayerLifecycleState.error) {
      return Text(
        _errorMessage ?? 'Error',
        style: TextStyle(fontSize: 11, color: Colors.red.shade700),
      );
    }

    // Downloading state
    if (_lifecycleState == PlayerLifecycleState.downloading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Downloading... ${(_downloadProgress * 100).toStringAsFixed(0)}%',
            style: TextStyle(
                fontSize: 11.sp, fontWeight: FontWeight.w500, color: color),
          ),
          SizedBox(height: 4.w),
          LinearProgressIndicator(
            value: _downloadProgress > 0 ? _downloadProgress : null,
            minHeight: 2,
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ],
      );
    }

    // Status messages
    if (_lifecycleState == PlayerLifecycleState.preparing) {
      return Text('Preparing...', style: TextStyle(fontSize: 11, color: color));
    }

    if (_lifecycleState == PlayerLifecycleState.checking) {
      return Text('Checking...', style: TextStyle(fontSize: 11, color: color));
    }

    if (_lifecycleState == PlayerLifecycleState.notDownloaded ||
        _lifecycleState == PlayerLifecycleState.uninitialized) {
      return Text(
        'Tap to download',
        style: TextStyle(
            fontSize: 11,
            fontStyle: FontStyle.italic,
            color: color.withOpacity(0.7)),
      );
    }

    // Waveform (ready/playing/paused)
    return AudioFileWaveforms(
      size: Size(MediaQuery.of(context).size.width * 0.35, 50),
      playerController: _controller,
      waveformType: WaveformType.long,
      enableSeekGesture: true,
      playerWaveStyle: PlayerWaveStyle(
        fixedWaveColor: color.withOpacity(0.4),
        liveWaveColor: color,
        spacing: 3.0,
        scaleFactor: 150,
        waveThickness: 2.5,
        showSeekLine: true,
        seekLineColor: color,
        seekLineThickness: 2.5,
        waveCap: StrokeCap.round,
      ),
    );
  }

  /// ⏱️ Duration display
  Widget _buildDuration() {
    final isMyMsg = widget.isMyMessage;
    final color = isMyMsg ? Colors.white70 : Colors.grey.shade700;

    return Text(
      widget.duration ?? '0:00',
      style: TextStyle(fontSize: 12, color: color),
    );
  }
}

/// 🔄 Player lifecycle state machine
enum PlayerLifecycleState {
  uninitialized, // Just created
  checking, // Checking cache status
  uploading, // 🔥 NEW: Uploading to Firebase (sender only)
  notDownloaded, // Not in cache, ready to download
  downloading, // Actively downloading
  preparing, // Preparing audio file
  ready, // Ready to play
  playing, // Currently playing
  paused, // Paused
  error, // Error state
}
