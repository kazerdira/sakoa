import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sakoa/common/values/values.dart';
import 'package:sakoa/common/services/voice_message_service.dart';
import 'dart:math';

/// 🔥 INDUSTRIAL-GRADE VOICE RECORDING WIDGET
/// Professional voice recording UI with:
/// - Real-time waveform visualization
/// - Duration display
/// - Cancel & Send buttons
/// - Beautiful animations
class VoiceRecordingWidget extends StatelessWidget {
  final VoidCallback onSend;
  final VoidCallback onCancel;

  const VoiceRecordingWidget({
    Key? key,
    required this.onSend,
    required this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final voiceService = VoiceMessageService.to;

    return Container(
      width: 360.w,
      height: 80.h,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // ===== DELETE/CANCEL BUTTON =====
          GestureDetector(
            onTap: onCancel,
            child: Container(
              width: 50.w,
              height: 50.w,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.delete_outline,
                color: Colors.red,
                size: 24.w,
              ),
            ),
          ),

          SizedBox(width: 15.w),

          // ===== WAVEFORM & DURATION =====
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Duration
                Obx(() => Text(
                      voiceService
                          .formatDuration(voiceService.recordingDuration.value),
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    )),

                SizedBox(height: 5.h),

                // Waveform visualization
                Obx(() => _buildWaveform(voiceService.currentAmplitude.value)),
              ],
            ),
          ),

          SizedBox(width: 15.w),

          // ===== SEND BUTTON =====
          GestureDetector(
            onTap: onSend,
            child: Container(
              width: 50.w,
              height: 50.w,
              decoration: BoxDecoration(
                color: AppColors.primaryElement,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryElement.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                Icons.send,
                color: Colors.white,
                size: 22.w,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build animated waveform bars
  Widget _buildWaveform(double amplitude) {
    return SizedBox(
      height: 24.h,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(30, (index) {
          // Create wave effect using sine function
          final wave = sin((index * 0.2 + amplitude * 10)).abs();
          final height = 4.h + (wave * 16.h);

          return AnimatedContainer(
            duration: Duration(milliseconds: 100),
            width: 3.w,
            height: height,
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.3 + (amplitude * 0.7)),
              borderRadius: BorderRadius.circular(2.w),
            ),
          );
        }),
      ),
    );
  }
}
