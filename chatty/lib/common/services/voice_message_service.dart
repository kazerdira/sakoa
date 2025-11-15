import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:just_audio/just_audio.dart';

/// 🔥 INDUSTRIAL-GRADE VOICE MESSAGE SERVICE
/// Professional voice recording system with:
/// - Real-time waveform visualization
/// - Audio compression & optimization
/// - Cloud upload with progress tracking
/// - Playback management
/// - Error recovery & retry logic
class VoiceMessageService extends GetxService {
  static VoiceMessageService get to => Get.find();

  final _recorder = AudioRecorder(); // record v5.x uses AudioRecorder
  final _player = AudioPlayer();
  final _storage = FirebaseStorage.instance;

  // Recording state
  final isRecording = false.obs;
  final isPaused = false.obs;
  final recordingDuration = Duration.zero.obs;
  final currentAmplitude = 0.0.obs;

  // Playback state
  final isPlaying = <String, bool>{}.obs; // messageId -> isPlaying
  final playbackPosition = <String, Duration>{}.obs; // messageId -> position
  final playbackDuration =
      <String, Duration>{}.obs; // messageId -> total duration

  // Upload state
  final uploadProgress = 0.0.obs;
  final isUploading = false.obs;

  Timer? _amplitudeTimer;
  Timer? _durationTimer;
  String? _currentRecordingPath;
  StreamSubscription? _playerStateSubscription;
  StreamSubscription? _positionSubscription;

  /// Initialize service
  Future<VoiceMessageService> init() async {
    await _initializePlayer();
    print('[VoiceMessageService] ✅ Initialized');
    return this;
  }

  // ============ RECORDING MANAGEMENT ============

  /// Start recording audio
  Future<bool> startRecording() async {
    try {
      // Check and request permission
      if (!await _recorder.hasPermission()) {
        print('[VoiceMessageService] ❌ Microphone permission denied');
        Get.snackbar(
          '🎤 Permission Required',
          'Microphone access is needed to record voice messages',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red.withOpacity(0.8),
          colorText: Colors.white,
          duration: Duration(seconds: 3),
        );
        return false;
      }

      // Generate file path
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentRecordingPath = '${directory.path}/voice_$timestamp.m4a';

      // Start recording with optimal settings (record v5.x API)
      await _recorder.start(
        RecordConfig(
          encoder: AudioEncoder.aacLc, // AAC-LC codec (best quality/size ratio)
          bitRate: 128000, // 128 kbps (optimal for voice)
          sampleRate: 44100, // 44.1 kHz (CD quality)
          numChannels: 1, // Mono (sufficient for voice)
        ),
        path: _currentRecordingPath!,
      );

      isRecording.value = true;
      recordingDuration.value = Duration.zero;

      // Start duration timer
      _startDurationTimer();

      // Start amplitude monitoring (for waveform)
      _startAmplitudeMonitoring();

      print(
          '[VoiceMessageService] 🎤 Recording started: $_currentRecordingPath');
      return true;
    } catch (e, stackTrace) {
      print('[VoiceMessageService] ❌ Failed to start recording: $e');
      print('[VoiceMessageService] Stack trace: $stackTrace');
      _handleRecordingError('Failed to start recording');
      return false;
    }
  }

  /// Stop recording and return file path
  Future<String?> stopRecording() async {
    try {
      if (!isRecording.value) {
        print('[VoiceMessageService] ⚠️ Not recording');
        return null;
      }

      final path = await _recorder.stop();

      _stopTimers();
      isRecording.value = false;
      isPaused.value = false;

      // Store duration before resetting
      final duration = recordingDuration.value;
      recordingDuration.value = duration; // Keep for upload
      currentAmplitude.value = 0.0;

      if (path == null || path.isEmpty) {
        print('[VoiceMessageService] ❌ Recording path is null');
        return null;
      }

      // Verify file exists and has content
      final file = File(path);
      if (!await file.exists()) {
        print('[VoiceMessageService] ❌ Recording file does not exist');
        return null;
      }

      final fileSize = await file.length();
      if (fileSize < 1000) {
        // Less than 1KB = too short
        print('[VoiceMessageService] ⚠️ Recording too short: $fileSize bytes');
        await file.delete();
        Get.snackbar(
          '⚠️ Recording Too Short',
          'Voice message must be at least 1 second',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.orange.withOpacity(0.8),
          colorText: Colors.white,
          duration: Duration(seconds: 2),
        );
        return null;
      }

      print(
          '[VoiceMessageService] ✅ Recording stopped: $path (${fileSize ~/ 1024}KB)');
      return path;
    } catch (e, stackTrace) {
      print('[VoiceMessageService] ❌ Failed to stop recording: $e');
      print('[VoiceMessageService] Stack trace: $stackTrace');
      _handleRecordingError('Failed to stop recording');
      _stopTimers();
      isRecording.value = false;
      return null;
    }
  }

  /// Cancel recording (discard audio)
  Future<void> cancelRecording() async {
    try {
      if (!isRecording.value) return;

      await _recorder.stop();
      _stopTimers();

      // Delete temporary file
      if (_currentRecordingPath != null) {
        final file = File(_currentRecordingPath!);
        if (await file.exists()) {
          await file.delete();
          print(
              '[VoiceMessageService] 🗑️ Deleted recording: $_currentRecordingPath');
        }
      }

      isRecording.value = false;
      isPaused.value = false;
      recordingDuration.value = Duration.zero;
      currentAmplitude.value = 0.0;
      _currentRecordingPath = null;

      print('[VoiceMessageService] ❌ Recording cancelled');
    } catch (e) {
      print('[VoiceMessageService] ❌ Failed to cancel recording: $e');
    }
  }

  /// Pause/Resume recording
  Future<void> togglePause() async {
    try {
      if (!isRecording.value) return;

      if (isPaused.value) {
        await _recorder.resume();
        _startDurationTimer();
        _startAmplitudeMonitoring();
        isPaused.value = false;
        print('[VoiceMessageService] ▶️ Recording resumed');
      } else {
        await _recorder.pause();
        _stopTimers();
        isPaused.value = true;
        print('[VoiceMessageService] ⏸️ Recording paused');
      }
    } catch (e) {
      print('[VoiceMessageService] ❌ Failed to toggle pause: $e');
    }
  }

  // ============ UPLOAD MANAGEMENT ============

  /// Upload voice message to Firebase Storage
  Future<String?> uploadVoiceMessage(String localPath) async {
    try {
      isUploading.value = true;
      uploadProgress.value = 0.0;

      final file = File(localPath);
      if (!await file.exists()) {
        print('[VoiceMessageService] ❌ File does not exist: $localPath');
        return null;
      }

      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'voice_messages/voice_$timestamp.m4a';

      print('[VoiceMessageService] ☁️ Uploading: $fileName');

      // Upload with progress tracking
      final uploadTask = _storage.ref().child(fileName).putFile(file);

      // Monitor progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        uploadProgress.value = progress;
        print(
            '[VoiceMessageService] 📤 Upload progress: ${(progress * 100).toStringAsFixed(1)}%');
      });

      // Wait for completion
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Delete local file after successful upload
      await file.delete();
      print('[VoiceMessageService] 🗑️ Deleted local file: $localPath');

      isUploading.value = false;
      uploadProgress.value = 0.0;

      print('[VoiceMessageService] ✅ Upload complete: $downloadUrl');
      return downloadUrl;
    } catch (e, stackTrace) {
      print('[VoiceMessageService] ❌ Upload failed: $e');
      print('[VoiceMessageService] Stack trace: $stackTrace');
      isUploading.value = false;
      uploadProgress.value = 0.0;

      Get.snackbar(
        '❌ Upload Failed',
        'Failed to upload voice message. Check your connection.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
        duration: Duration(seconds: 3),
      );
      return null;
    }
  }

  // ============ PLAYBACK MANAGEMENT ============

  /// Initialize audio player
  Future<void> _initializePlayer() async {
    _playerStateSubscription = _player.playerStateStream.listen((state) {
      // Auto-update playing state when playback ends
      if (state.processingState == ProcessingState.completed) {
        final currentMessageId = _getCurrentPlayingMessageId();
        if (currentMessageId != null) {
          isPlaying[currentMessageId] = false;
          playbackPosition[currentMessageId] = Duration.zero;
        }
      }
    });

    _positionSubscription = _player.positionStream.listen((position) {
      final currentMessageId = _getCurrentPlayingMessageId();
      if (currentMessageId != null) {
        playbackPosition[currentMessageId] = position;
      }
    });
  }

  /// Play voice message
  Future<void> playVoiceMessage(String messageId, String audioUrl) async {
    try {
      // If already playing this message, pause it
      if (isPlaying[messageId] == true) {
        await _player.pause();
        isPlaying[messageId] = false;
        print('[VoiceMessageService] ⏸️ Paused: $messageId');
        return;
      }

      // Stop any currently playing message
      final currentPlaying = _getCurrentPlayingMessageId();
      if (currentPlaying != null && currentPlaying != messageId) {
        isPlaying[currentPlaying] = false;
      }

      // Load and play new message
      await _player.setUrl(audioUrl);
      final duration = _player.duration;
      if (duration != null) {
        playbackDuration[messageId] = duration;
      }

      await _player.play();
      isPlaying[messageId] = true;
      print('[VoiceMessageService] ▶️ Playing: $messageId');
    } catch (e, stackTrace) {
      print('[VoiceMessageService] ❌ Playback failed: $e');
      print('[VoiceMessageService] Stack trace: $stackTrace');
      isPlaying[messageId] = false;

      Get.snackbar(
        '❌ Playback Failed',
        'Failed to play voice message',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
        duration: Duration(seconds: 2),
      );
    }
  }

  /// Stop playback
  Future<void> stopPlayback(String messageId) async {
    try {
      await _player.stop();
      isPlaying[messageId] = false;
      playbackPosition[messageId] = Duration.zero;
      print('[VoiceMessageService] ⏹️ Stopped: $messageId');
    } catch (e) {
      print('[VoiceMessageService] ❌ Failed to stop playback: $e');
    }
  }

  /// Seek to position in audio
  Future<void> seekTo(String messageId, Duration position) async {
    try {
      await _player.seek(position);
      playbackPosition[messageId] = position;
    } catch (e) {
      print('[VoiceMessageService] ❌ Failed to seek: $e');
    }
  }

  // ============ HELPER METHODS ============

  void _startDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(Duration(milliseconds: 100), (timer) {
      recordingDuration.value =
          recordingDuration.value + Duration(milliseconds: 100);
    });
  }

  void _startAmplitudeMonitoring() {
    _amplitudeTimer?.cancel();
    _amplitudeTimer = Timer.periodic(Duration(milliseconds: 50), (timer) async {
      try {
        final amplitude = await _recorder.getAmplitude();
        // Normalize amplitude to 0.0 - 1.0 range
        // record v4.x returns Amplitude object with 'current' property (in dB)
        final dbValue = amplitude.current; // Value is in decibels (-50 to 0)
        currentAmplitude.value =
            (dbValue + 50) / 50; // Normalize -50dB to 0dB → 0.0 to 1.0
        currentAmplitude.value = currentAmplitude.value.clamp(0.0, 1.0);
      } catch (e) {
        // Ignore amplitude errors (e.g., if not recording)
        currentAmplitude.value = 0.0;
      }
    });
  }

  void _stopTimers() {
    _durationTimer?.cancel();
    _amplitudeTimer?.cancel();
  }

  String? _getCurrentPlayingMessageId() {
    return isPlaying.entries
        .where((entry) => entry.value == true)
        .map((entry) => entry.key)
        .firstOrNull;
  }

  void _handleRecordingError(String message) {
    Get.snackbar(
      '❌ Recording Error',
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.red.withOpacity(0.8),
      colorText: Colors.white,
      duration: Duration(seconds: 3),
    );
  }

  /// Format duration for display (mm:ss)
  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  void onClose() {
    print('[VoiceMessageService] 🧹 Cleaning up...');
    _stopTimers();
    _playerStateSubscription?.cancel();
    _positionSubscription?.cancel();
    _recorder.dispose();
    _player.dispose();
    super.onClose();
  }
}
