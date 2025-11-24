import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sakoa/common/values/values.dart';
import 'package:sakoa/common/services/voice_message_service.dart';
import 'dart:math';

/// 🎤 PROFESSIONAL VOICE RECORDING WIDGET
/// Modern voice recording UI inspired by WhatsApp/Telegram with:
/// - Slide to cancel gesture (swipe left)
/// - Real-time waveform visualization
/// - Tap to send button
/// - Professional animations
/// - Clear visual feedback
class VoiceRecordingWidget extends StatefulWidget {
  final VoidCallback onSend;
  final VoidCallback onCancel;

  const VoiceRecordingWidget({
    Key? key,
    required this.onSend,
    required this.onCancel,
  }) : super(key: key);

  @override
  State<VoiceRecordingWidget> createState() => _VoiceRecordingWidgetState();
}

class _VoiceRecordingWidgetState extends State<VoiceRecordingWidget>
    with SingleTickerProviderStateMixin {
  double _slideOffset = 0.0;
  bool _isSending = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _handleSend() {
    if (_isSending) return;
    setState(() => _isSending = true);
    widget.onSend();
  }

  void _handleCancel() {
    if (_isSending) return;
    widget.onCancel();
  }

  @override
  Widget build(BuildContext context) {
    final voiceService = VoiceMessageService.to;

    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        if (_isSending) return;
        setState(() {
          _slideOffset += details.delta.dx;
          // Only allow left drag (negative values)
          if (_slideOffset > 0) _slideOffset = 0;
          // Trigger cancel at -100
          if (_slideOffset < -100) {
            _handleCancel();
          }
        });
      },
      onHorizontalDragEnd: (details) {
        if (_isSending) return;
        // Snap back if not cancelled
        if (_slideOffset > -100) {
          setState(() => _slideOffset = 0);
        }
      },
      child: Transform.translate(
        offset: Offset(_slideOffset, 0),
        child: AnimatedOpacity(
          opacity: _isSending ? 0.6 : 1.0,
          duration: Duration(milliseconds: 200),
          child: Container(
            width: 360.w,
            height: 70.h,
            padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 10.h),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryElement.withOpacity(0.1),
                  AppColors.primaryElement.withOpacity(0.05),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(35.h),
              border: Border.all(
                color: AppColors.primaryElement.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // ===== MICROPHONE ICON (Pulsing) =====
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        width: 45.w,
                        height: 45.w,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.4),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.mic,
                          color: Colors.white,
                          size: 22.w,
                        ),
                      ),
                    );
                  },
                ),

                SizedBox(width: 12.w),

                // ===== WAVEFORM & INFO =====
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min, // 🔧 FIX: Prevent overflow
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Duration & Slide hint
                      Flexible(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Obx(() => Text(
                                  voiceService.formatDuration(
                                      voiceService.recordingDuration.value),
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                    letterSpacing: 1.2,
                                  ),
                                )),
                            SizedBox(width: 8.w),
                            // Slide to cancel hint (fades out when sliding)
                            Flexible(
                              child: AnimatedOpacity(
                                opacity: _slideOffset < -20 ? 0.0 : 0.6,
                                duration: Duration(milliseconds: 200),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.keyboard_arrow_left,
                                      size: 14.w,
                                      color: Colors.grey,
                                    ),
                                    Flexible(
                                      child: Text(
                                        "Slide to cancel",
                                        style: TextStyle(
                                          fontSize: 10.sp,
                                          color: Colors.grey,
                                          fontStyle: FontStyle.italic,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 4.h),

                      // Waveform visualization
                      Obx(() =>
                          _buildWaveform(voiceService.currentAmplitude.value)),
                    ],
                  ),
                ),

                SizedBox(width: 12.w),

                // ===== SEND BUTTON =====
                GestureDetector(
                  onTap: _handleSend,
                  child: Container(
                    width: 50.w,
                    height: 50.w,
                    decoration: BoxDecoration(
                      color: AppColors.primaryElement,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryElement.withOpacity(0.4),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: _isSending
                        ? SizedBox(
                            width: 20.w,
                            height: 20.w,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 24.w,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build animated waveform bars
  Widget _buildWaveform(double amplitude) {
    return SizedBox(
      height: 20.h,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: List.generate(35, (index) {
          // Create wave effect using sine function
          final wave = sin((index * 0.25 + amplitude * 12)).abs();
          final height = 3.h + (wave * 14.h);

          return Padding(
            padding: EdgeInsets.only(right: 2.w),
            child: AnimatedContainer(
              duration: Duration(milliseconds: 150),
              width: 2.5.w,
              height: height,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryElement.withOpacity(0.8),
                    AppColors.primaryElement.withOpacity(0.4),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(2.w),
              ),
            ),
          );
        }),
      ),
    );
  }
}
