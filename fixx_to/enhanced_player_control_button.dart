// 🔥 ENHANCED CONTROL BUTTON - REPLACE in voice_message_player_v9.dart (starting line ~438)
// Location: chatty/lib/pages/message/chat/widgets/voice_message_player_v9.dart

/// 🎛️ Control button with UPLOADING state support
Widget _buildControlButton() {
  final isMyMsg = widget.isMyMessage;
  final primaryColor = isMyMsg ? Colors.white : Colors.grey.shade700;
  final bgColor = isMyMsg ? primaryColor.withOpacity(0.2) : Colors.grey.shade200;

  Widget icon;
  Color iconColor = primaryColor;

  switch (_lifecycleState) {
    case PlayerLifecycleState.error:
      icon = Icon(Icons.refresh, size: 20, color: Colors.red.shade700);
      iconColor = Colors.red.shade700;
      break;

    // 🔥 NEW: Uploading state (sender's message being uploaded)
    case PlayerLifecycleState.uploading:
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
            valueColor: AlwaysStoppedAnimation(
              isMyMsg ? Color(0xFF128C7E) : Colors.grey.shade600,
            ),
          ),
        ),
      );

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

/// 📊 Enhanced waveform area with UPLOADING state
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

  // 🔥 NEW: Uploading state (for sender)
  if (_lifecycleState == PlayerLifecycleState.uploading) {
    return Text(
      'Uploading...',
      style: TextStyle(
        fontSize: 11.sp,
        fontStyle: FontStyle.italic,
        color: color.withOpacity(0.7),
      ),
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
