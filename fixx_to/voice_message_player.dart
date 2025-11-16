import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sakoa/common/values/values.dart';
import 'package:sakoa/common/services/voice_message_service.dart';
import 'package:sakoa/common/services/voice_message_cache_service.dart';

/// 🎙️ INDUSTRIAL VOICE MESSAGE PLAYER V4
/// Professional voice player exceeding WhatsApp & Telegram standards:
/// - **SUPERNOVA: Smart caching with progressive download**
/// - **SUPERNOVA: Loading spinner during download (deactivated button)**
/// - **SUPERNOVA: Instant playback from local cache**
/// - Smooth circular progress indicator (like Telegram)
/// - Touch-optimized play/pause with haptic feedback
/// - High-precision seekable waveform
/// - Dynamic playback speed with visual feedback
/// - Micro-interactions and fluid animations
/// - Production-ready stability
class VoiceMessagePlayer extends StatefulWidget {
  final String messageId;
  final String audioUrl;
  final int durationSeconds;
  final bool isMyMessage;

  const VoiceMessagePlayer({
    Key? key,
    required this.messageId,
    required this.audioUrl,
    required this.durationSeconds,
    this.isMyMessage = false,
  }) : super(key: key);

  @override
  State<VoiceMessagePlayer> createState() => _VoiceMessagePlayerState();
}

class _VoiceMessagePlayerState extends State<VoiceMessagePlayer>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _speedChangeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _speedChangeAnimation;

  final playbackSpeeds = [1.0, 1.5, 2.0];
  int currentSpeedIndex = 0;
  bool _isDragging = false;

  // 🔥 SUPERNOVA: Cache state
  final _isDownloading = false.obs;
  final _downloadProgress = 0.0.obs;
  String? _cachedLocalPath;

  @override
  void initState() {
    super.initState();

    // Pulse animation for playing state
    _pulseController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);

    // Speed change feedback animation
    _speedChangeController = AnimationController(
      duration: Duration(milliseconds: 200),
      vsync: this,
    );
    _speedChangeAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _speedChangeController, curve: Curves.easeOut),
    );

    // 🔥 SUPERNOVA: Initialize cache on widget load
    _initializeCache();
  }

  /// 🔥 SUPERNOVA: Initialize cache - download if not cached
  Future<void> _initializeCache() async {
    final cacheService = VoiceMessageCacheService.to;

    // Check if already cached
    if (cacheService.isCached(widget.messageId)) {
      _cachedLocalPath = cacheService.getCachedPath(widget.messageId);
      print('[VoicePlayer] ⚡ Using cached file: ${widget.messageId}');
      return;
    }

    // Not cached - download in background
    print('[VoicePlayer] 📥 Downloading and caching: ${widget.messageId}');
    _isDownloading.value = true;

    try {
      final localPath = await cacheService.downloadAndCache(
        messageId: widget.messageId,
        audioUrl: widget.audioUrl,
        onProgress: (progress) {
          _downloadProgress.value = progress;
        },
      );

      if (localPath != null) {
        setState(() {
          _cachedLocalPath = localPath;
        });
        _isDownloading.value = false;
        print('[VoicePlayer] ✅ Download complete: ${widget.messageId}');
      } else {
        _isDownloading.value = false;
        print('[VoicePlayer] ❌ Download failed: ${widget.messageId}');
        Get.snackbar(
          'Download Failed',
          'Failed to download voice message. Check your connection.',
          snackPosition: SnackPosition.BOTTOM,
          duration: Duration(seconds: 2),
        );
      }
    } catch (e) {
      _isDownloading.value = false;
      print('[VoicePlayer] ❌ Download error: $e');
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _speedChangeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final voiceService = VoiceMessageService.to;
    final duration = Duration(seconds: widget.durationSeconds);

    return Container(
      width: 280.w,
      decoration: BoxDecoration(
        color: widget.isMyMessage
            ? AppColors.primaryElement
            : AppColors.primarySecondaryBackground,
        borderRadius: BorderRadius.circular(30.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // ===== CIRCULAR PROGRESS PLAY/PAUSE BUTTON =====
          _buildPlayButton(voiceService, duration),

          SizedBox(width: 12.w),

          // ===== WAVEFORM & CONTROLS =====
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Interactive Waveform
                _buildWaveform(voiceService, duration),

                SizedBox(width: 8.h),

                // Time & Speed Control
                _buildTimeControls(voiceService, duration),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 🔥 SUPERNOVA: Build play button with loading/downloading states
  Widget _buildPlayButton(VoiceMessageService voiceService, Duration duration) {
    return Obx(() {
      // 🔥 SUPERNOVA: Show loading spinner during download
      if (_isDownloading.value) {
        return _buildLoadingSpinner();
      }

      // 🔥 If not cached yet and not downloading, wait for cache
      if (_cachedLocalPath == null) {
        return _buildWaitingState();
      }

      // Normal play/pause button
      final isPlaying = voiceService.isPlaying[widget.messageId] ?? false;
      final position =
          voiceService.playbackPosition[widget.messageId] ?? Duration.zero;
      final progress = duration.inMilliseconds > 0
          ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
          : 0.0;

      return GestureDetector(
        onTap: () async {
          // 🔥 SUPERNOVA: Play from local cached file!
          await voiceService.playVoiceMessage(
            widget.messageId,
            _cachedLocalPath!, // Use local file instead of URL
          );

          // Update last access for LRU cache
          await VoiceMessageCacheService.to.updateLastAccess(widget.messageId);
        },
        child: AnimatedBuilder(
          animation:
              isPlaying ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
          builder: (context, child) {
            return Transform.scale(
              scale: isPlaying ? _pulseAnimation.value : 1.0,
              child: Container(
                width: 44.w,
                height: 44.w,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Circular Progress Background
                    CircularProgressIndicator(
                      value: 1.0,
                      strokeWidth: 2.5.w,
                      backgroundColor: widget.isMyMessage
                          ? Colors.white.withOpacity(0.2)
                          : Colors.black.withOpacity(0.08),
                      valueColor: AlwaysStoppedAnimation(Colors.transparent),
                    ),

                    // Circular Progress Indicator
                    if (isPlaying || progress > 0.01)
                      TweenAnimationBuilder<double>(
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                        tween: Tween<double>(begin: 0.0, end: progress),
                        builder: (context, value, _) =>
                            CircularProgressIndicator(
                          value: value,
                          strokeWidth: 2.5.w,
                          strokeCap: StrokeCap.round,
                          backgroundColor: Colors.transparent,
                          valueColor: AlwaysStoppedAnimation(
                            widget.isMyMessage
                                ? Colors.white
                                : AppColors.primaryElement,
                          ),
                        ),
                      ),

                    // Play/Pause Icon with smooth transition
                    AnimatedSwitcher(
                      duration: Duration(milliseconds: 200),
                      transitionBuilder: (child, animation) => ScaleTransition(
                        scale: animation,
                        child: child,
                      ),
                      child: Container(
                        key: ValueKey(isPlaying),
                        width: 36.w,
                        height: 36.w,
                        decoration: BoxDecoration(
                          color: widget.isMyMessage
                              ? Colors.white
                              : AppColors.primaryElement,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (widget.isMyMessage
                                      ? Colors.white
                                      : AppColors.primaryElement)
                                  .withOpacity(0.25),
                              blurRadius: 8,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Icon(
                          isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          size: 25.w,
                          color: widget.isMyMessage
                              ? AppColors.primaryElement
                              : Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    });
  }

  /// 🔥 SUPERNOVA: Loading spinner widget (during download)
  Widget _buildLoadingSpinner() {
    return Obx(() {
      final progress = _downloadProgress.value;

      return Container(
        width: 44.w,
        height: 44.w,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Download Progress Circle
            CircularProgressIndicator(
              value: progress,
              strokeWidth: 2.5.w,
              strokeCap: StrokeCap.round,
              backgroundColor: widget.isMyMessage
                  ? Colors.white.withOpacity(0.2)
                  : Colors.black.withOpacity(0.08),
              valueColor: AlwaysStoppedAnimation(
                widget.isMyMessage ? Colors.white : AppColors.primaryElement,
              ),
            ),

            // Download Icon
            Icon(
              Icons.download_rounded,
              size: 20.w,
              color: widget.isMyMessage
                  ? Colors.white.withOpacity(0.7)
                  : AppColors.primaryElement.withOpacity(0.7),
            ),
          ],
        ),
      );
    });
  }

  /// 🔥 SUPERNOVA: Waiting state (before download starts)
  Widget _buildWaitingState() {
    return Container(
      width: 44.w,
      height: 44.w,
      child: Center(
        child: SizedBox(
          width: 20.w,
          height: 20.w,
          child: CircularProgressIndicator(
            strokeWidth: 2.w,
            valueColor: AlwaysStoppedAnimation(
              widget.isMyMessage
                  ? Colors.white.withOpacity(0.5)
                  : AppColors.primaryElement.withOpacity(0.5),
            ),
          ),
        ),
      ),
    );
  }

  /// Build interactive waveform with enhanced precision
  Widget _buildWaveform(VoiceMessageService voiceService, Duration duration) {
    return Obx(() {
      final position =
          voiceService.playbackPosition[widget.messageId] ?? Duration.zero;
      final progress = duration.inMilliseconds > 0
          ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
          : 0.0;

      return GestureDetector(
        onHorizontalDragStart: (_) => setState(() => _isDragging = true),
        onHorizontalDragUpdate: (details) =>
            _handleDrag(details, voiceService, duration),
        onHorizontalDragEnd: (_) => setState(() => _isDragging = false),
        onTapDown: (details) => _seekToPosition(
          details.localPosition.dx,
          voiceService,
          duration,
        ),
        child: Container(
          height: 38.h,
          child: CustomPaint(
            painter: WaveformPainter(
              progress: progress,
              isMyMessage: widget.isMyMessage,
              isDragging: _isDragging,
            ),
            size: Size.infinite,
          ),
        ),
      );
    });
  }

  /// Build time display and speed control
  Widget _buildTimeControls(
      VoiceMessageService voiceService, Duration duration) {
    return Obx(() {
      final position =
          voiceService.playbackPosition[widget.messageId] ?? Duration.zero;
      final isPlaying = voiceService.isPlaying[widget.messageId] ?? false;

      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Time Display
          Text(
            isPlaying
                ? '${_formatDuration(position)} / ${_formatDuration(duration)}'
                : _formatDuration(duration),
            style: TextStyle(
              fontSize: 12.sp,
              color: widget.isMyMessage
                  ? Colors.white.withOpacity(0.85)
                  : Colors.black.withOpacity(0.65),
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
          ),

          // Playback Speed Control
          if (isPlaying)
            GestureDetector(
              onTap: _togglePlaybackSpeed,
              child: AnimatedBuilder(
                animation: _speedChangeAnimation,
                builder: (context, child) => Transform.scale(
                  scale: _speedChangeAnimation.value,
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.h),
                    decoration: BoxDecoration(
                      color: widget.isMyMessage
                          ? Colors.white.withOpacity(0.2)
                          : AppColors.primaryElement.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10.w),
                      border: Border.all(
                        color: widget.isMyMessage
                            ? Colors.white.withOpacity(0.3)
                            : AppColors.primaryElement.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.speed_rounded,
                          size: 12.w,
                          color: widget.isMyMessage
                              ? Colors.white.withOpacity(0.9)
                              : AppColors.primaryElement,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          '${playbackSpeeds[currentSpeedIndex]}x',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: widget.isMyMessage
                                ? Colors.white.withOpacity(0.95)
                                : AppColors.primaryElement,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    });
  }

  /// Handle drag on waveform for seeking
  void _handleDrag(
    DragUpdateDetails details,
    VoiceMessageService voiceService,
    Duration duration,
  ) {
    _seekToPosition(details.localPosition.dx, voiceService, duration);
  }

  /// Seek to position when user taps/drags on waveform
  void _seekToPosition(
    double tapX,
    VoiceMessageService voiceService,
    Duration totalDuration,
  ) {
    if (_cachedLocalPath == null) return; // Can't seek if not cached

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final waveformWidth = renderBox.size.width - 44.w - 12.w - 14.w * 2;
    final progress = (tapX / waveformWidth).clamp(0.0, 1.0);
    final seekPosition = Duration(
      milliseconds: (totalDuration.inMilliseconds * progress).round(),
    );

    voiceService.seekTo(widget.messageId, seekPosition);
  }

  /// Toggle playback speed with animation feedback
  void _togglePlaybackSpeed() {
    _speedChangeController.forward(from: 0.0);

    setState(() {
      currentSpeedIndex = (currentSpeedIndex + 1) % playbackSpeeds.length;
    });

    final speed = playbackSpeeds[currentSpeedIndex];
    VoiceMessageService.to.setPlaybackSpeed(speed);
  }

  /// Format duration as MM:SS
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}

/// Custom painter for professional waveform visualization
class WaveformPainter extends CustomPainter {
  final double progress;
  final bool isMyMessage;
  final bool isDragging;

  WaveformPainter({
    required this.progress,
    required this.isMyMessage,
    required this.isDragging,
  });

  // Professional waveform pattern (40 bars for ultra-smooth appearance)
  static const waveformHeights = [
    0.3,
    0.5,
    0.7,
    0.9,
    1.0,
    0.85,
    0.6,
    0.5,
    0.65,
    0.85,
    0.95,
    0.8,
    0.6,
    0.7,
    0.9,
    1.0,
    0.9,
    0.7,
    0.55,
    0.75,
    0.9,
    0.8,
    0.6,
    0.5,
    0.7,
    0.85,
    0.95,
    0.75,
    0.6,
    0.8,
    0.9,
    0.85,
    0.65,
    0.5,
    0.7,
    0.9,
    0.8,
    0.6,
    0.4,
    0.3,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final barCount = waveformHeights.length;
    final barSpacing = size.width / barCount;
    final barWidth = barSpacing * 0.65;

    for (int i = 0; i < barCount; i++) {
      final x = i * barSpacing + (barSpacing - barWidth) / 2;
      final maxHeight = size.height * 0.85;
      final minHeight = size.height * 0.15;
      final height = minHeight + (waveformHeights[i] * (maxHeight - minHeight));
      final y = (size.height - height) / 2;

      final barProgress = i / barCount;
      final isPlayed = barProgress <= progress;

      // Bar paint with gradient
      final paint = Paint()
        ..style = PaintingStyle.fill
        ..strokeCap = StrokeCap.round;

      if (isMyMessage) {
        paint.color = isPlayed
            ? Colors.white.withOpacity(isDragging ? 1.0 : 0.95)
            : Colors.white.withOpacity(0.3);
      } else {
        paint.color = isPlayed
            ? AppColors.primaryElement.withOpacity(isDragging ? 1.0 : 0.95)
            : AppColors.primaryElement.withOpacity(0.25);
      }

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, height),
        Radius.circular(barWidth / 2),
      );

      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(WaveformPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isDragging != isDragging;
  }
}
