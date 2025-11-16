import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sakoa/common/values/values.dart';
import 'package:sakoa/common/services/voice_message_service.dart';
import 'package:sakoa/common/services/voice_cache_manager.dart';

/// 🎙️ INDUSTRIAL VOICE MESSAGE PLAYER V4 WITH CACHE
/// Professional voice player with industrial-grade caching:
/// - Download progress indicator (spinning circle = downloading)
/// - Instant playback from cache
/// - Smooth animations
/// - Telegram/WhatsApp standard UX
class VoiceMessagePlayerV4 extends StatefulWidget {
  final String messageId;
  final String audioUrl;
  final int durationSeconds;
  final bool isMyMessage;

  const VoiceMessagePlayerV4({
    Key? key,
    required this.messageId,
    required this.audioUrl,
    required this.durationSeconds,
    this.isMyMessage = false,
  }) : super(key: key);

  @override
  State<VoiceMessagePlayerV4> createState() => _VoiceMessagePlayerV4State();
}

class _VoiceMessagePlayerV4State extends State<VoiceMessagePlayerV4>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _speedChangeController;
  late AnimationController _downloadSpinController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _speedChangeAnimation;

  final playbackSpeeds = [1.0, 1.5, 2.0];
  int currentSpeedIndex = 0;
  bool _isDragging = false;

  String? _cachedFilePath; // Local file path after download
  bool _isInitializing = true;

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

    // Download spinner animation
    _downloadSpinController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    _downloadSpinController.repeat();

    // Initialize cache (check if already cached or start download)
    _initializeCache();
  }

  /// Check if cached, if not - queue for download
  Future<void> _initializeCache() async {
    final cacheManager = VoiceCacheManager.to;

    // Queue download with high priority (visible message)
    await cacheManager.queueDownload(
      messageId: widget.messageId,
      audioUrl: widget.audioUrl,
      priority: VoiceDownloadPriority.high,
    );

    // Try to get cached file (will wait if downloading)
    final cachedPath = await cacheManager.getVoiceFile(
      messageId: widget.messageId,
      audioUrl: widget.audioUrl,
      priority: VoiceDownloadPriority.high,
    );

    if (mounted) {
      setState(() {
        _cachedFilePath = cachedPath;
        _isInitializing = false;
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _speedChangeController.dispose();
    _downloadSpinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final voiceService = VoiceMessageService.to;
    final cacheManager = VoiceCacheManager.to;
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
          // ===== PLAY BUTTON (shows download progress if not cached) =====
          _buildPlayButton(voiceService, cacheManager, duration),

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

  /// Build play button with download progress
  Widget _buildPlayButton(
    VoiceMessageService voiceService,
    VoiceCacheManager cacheManager,
    Duration duration,
  ) {
    return Obx(() {
      // Check download status
      final downloadStatus = cacheManager.downloadStatus[widget.messageId];
      final isDownloading = downloadStatus == VoiceDownloadStatus.downloading ||
          downloadStatus == VoiceDownloadStatus.queued ||
          downloadStatus == VoiceDownloadStatus.retrying;

      final isCached = cacheManager.isCached(widget.messageId);

      // If downloading - show progress spinner
      if (isDownloading || _isInitializing) {
        final progress = cacheManager.getDownloadProgress(widget.messageId);
        return _buildDownloadingButton(progress);
      }

      // If download failed
      if (downloadStatus == VoiceDownloadStatus.failed) {
        return _buildErrorButton();
      }

      // Normal play/pause button (cached)
      final isPlaying = voiceService.isPlaying[widget.messageId] ?? false;
      final position =
          voiceService.playbackPosition[widget.messageId] ?? Duration.zero;
      final playProgress = duration.inMilliseconds > 0
          ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
          : 0.0;

      return GestureDetector(
        onTap: () async {
          if (!isCached && _cachedFilePath == null) {
            // Not cached yet - re-trigger download
            await _initializeCache();
            return;
          }

          // Play from local file
          if (_cachedFilePath != null) {
            await voiceService.playVoiceMessage(
              widget.messageId,
              _cachedFilePath!, // Play from local cache!
            );
          } else {
            await voiceService.playVoiceMessage(
              widget.messageId,
              widget.audioUrl, // Fallback to URL
            );
          }
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

                    // Circular Progress Indicator (playback)
                    if (isPlaying || playProgress > 0.01)
                      TweenAnimationBuilder<double>(
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                        tween: Tween<double>(begin: 0.0, end: playProgress),
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

                    // Play/Pause Icon
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

  /// Build downloading button with progress spinner
  Widget _buildDownloadingButton(double progress) {
    return Container(
      width: 44.w,
      height: 44.w,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Progress circle
          CircularProgressIndicator(
            value: progress > 0 ? progress : null, // null = indeterminate
            strokeWidth: 2.5.w,
            strokeCap: StrokeCap.round,
            backgroundColor: widget.isMyMessage
                ? Colors.white.withOpacity(0.2)
                : Colors.black.withOpacity(0.08),
            valueColor: AlwaysStoppedAnimation(
              widget.isMyMessage
                  ? Colors.white.withOpacity(0.7)
                  : AppColors.primaryElement.withOpacity(0.7),
            ),
          ),

          // Download icon
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
  }

  /// Build error button (download failed)
  Widget _buildErrorButton() {
    return GestureDetector(
      onTap: _initializeCache, // Retry download
      child: Container(
        width: 44.w,
        height: 44.w,
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.refresh_rounded,
          size: 24.w,
          color: Colors.red,
        ),
      ),
    );
  }

  /// Build interactive waveform (same as before)
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

  /// Build time display and speed control (same as before)
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

  /// Seek to position
  void _seekToPosition(
    double tapX,
    VoiceMessageService voiceService,
    Duration totalDuration,
  ) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final waveformWidth = renderBox.size.width - 44.w - 12.w - 14.w * 2;
    final progress = (tapX / waveformWidth).clamp(0.0, 1.0);
    final seekPosition = Duration(
      milliseconds: (totalDuration.inMilliseconds * progress).round(),
    );

    voiceService.seekTo(widget.messageId, seekPosition);
  }

  /// Toggle playback speed
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

/// Custom painter for waveform (same as before)
class WaveformPainter extends CustomPainter {
  final double progress;
  final bool isMyMessage;
  final bool isDragging;

  WaveformPainter({
    required this.progress,
    required this.isMyMessage,
    required this.isDragging,
  });

  static const waveformHeights = [
    0.3, 0.5, 0.7, 0.9, 1.0, 0.85, 0.6, 0.5, 0.65, 0.85,
    0.95, 0.8, 0.6, 0.7, 0.9, 1.0, 0.9, 0.7, 0.55, 0.75,
    0.9, 0.8, 0.6, 0.5, 0.7, 0.85, 0.95, 0.75, 0.6, 0.8,
    0.9, 0.85, 0.65, 0.5, 0.7, 0.9, 0.8, 0.6, 0.4, 0.3,
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
