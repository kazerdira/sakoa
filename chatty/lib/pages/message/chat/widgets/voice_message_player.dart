import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sakoa/common/values/values.dart';
import 'package:sakoa/common/services/voice_message_service.dart';

/// 🔥 INDUSTRIAL-GRADE VOICE MESSAGE PLAYER
/// Professional voice player UI with:
/// - Play/pause button with smooth animation
/// - Progress visualization
/// - Duration display
/// - Waveform visualization
class VoiceMessagePlayer extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final voiceService = VoiceMessageService.to;
    final duration = Duration(seconds: durationSeconds);

    return Container(
      width: 240.w,
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: isMyMessage
            ? AppColors.primaryElement
            : AppColors.primarySecondaryBackground,
        borderRadius: BorderRadius.circular(12.w),
      ),
      child: Row(
        children: [
          // ===== PLAY/PAUSE BUTTON =====
          Obx(() {
            final isPlaying = voiceService.isPlaying[messageId] ?? false;

            return GestureDetector(
              onTap: () => voiceService.playVoiceMessage(messageId, audioUrl),
              child: AnimatedContainer(
                duration: Duration(milliseconds: 200),
                width: 36.w,
                height: 36.w,
                decoration: BoxDecoration(
                  color: isMyMessage
                      ? Colors.white.withOpacity(0.3)
                      : AppColors.primaryElement.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPlaying ? Icons.pause : Icons.play_arrow,
                  color: isMyMessage ? Colors.white : AppColors.primaryElement,
                  size: 20.w,
                ),
              ),
            );
          }),

          SizedBox(width: 8.w),

          // ===== WAVEFORM & PROGRESS =====
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Waveform visualization
                Obx(() {
                  final position =
                      voiceService.playbackPosition[messageId] ?? Duration.zero;
                  final progress = duration.inMilliseconds > 0
                      ? position.inMilliseconds / duration.inMilliseconds
                      : 0.0;

                  return _buildWaveform(progress);
                }),

                SizedBox(height: 4.h),

                // Duration & Progress
                Obx(() {
                  final position =
                      voiceService.playbackPosition[messageId] ?? Duration.zero;
                  final isPlaying = voiceService.isPlaying[messageId] ?? false;

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        voiceService
                            .formatDuration(isPlaying ? position : duration),
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: isMyMessage
                              ? Colors.white.withOpacity(0.8)
                              : Colors.black.withOpacity(0.6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        voiceService.formatDuration(duration),
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: isMyMessage
                              ? Colors.white.withOpacity(0.6)
                              : Colors.black.withOpacity(0.4),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),

          SizedBox(width: 8.w),

          // ===== MIC ICON =====
          Icon(
            Icons.mic,
            size: 18.w,
            color: isMyMessage
                ? Colors.white.withOpacity(0.6)
                : Colors.grey.withOpacity(0.6),
          ),
        ],
      ),
    );
  }

  /// Build waveform with progress indicator
  Widget _buildWaveform(double progress) {
    // Simulated waveform pattern (20 bars)
    final heights = [
      0.3,
      0.5,
      0.7,
      0.9,
      0.8,
      0.6,
      0.4,
      0.5,
      0.7,
      0.9,
      0.8,
      0.6,
      0.5,
      0.7,
      0.9,
      0.7,
      0.5,
      0.4,
      0.6,
      0.8
    ];

    return SizedBox(
      height: 20.h,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(20, (index) {
          final height = 6.h + (heights[index] * 12.h);
          final barProgress = index / 20;
          final isPlayed = barProgress <= progress;

          return AnimatedContainer(
            duration: Duration(milliseconds: 200),
            width: 2.5.w,
            height: height,
            decoration: BoxDecoration(
              color: isMyMessage
                  ? (isPlayed
                      ? Colors.white.withOpacity(0.9)
                      : Colors.white.withOpacity(0.3))
                  : (isPlayed
                      ? AppColors.primaryElement
                      : AppColors.primaryElement.withOpacity(0.2)),
              borderRadius: BorderRadius.circular(2.w),
            ),
          );
        }),
      ),
    );
  }
}
