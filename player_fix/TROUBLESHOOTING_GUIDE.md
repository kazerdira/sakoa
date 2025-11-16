# 🔧 TROUBLESHOOTING GUIDE - Supernova Voice System

## Quick Fixes for Common Issues

---

## 🎯 PLAYBACK ISSUES

### Issue: "Click does nothing / requires double-click"

**Symptoms:**
- First click doesn't work
- Need to tap 2-3 times to play
- Sometimes works, sometimes doesn't

**Root Cause:** Old player is still being used

**Fix:**
```dart
// 1. Check imports in chat_left_item.dart and chat_right_item.dart
import 'package:sakoa/pages/message/chat/widgets/voice_message_player_v4.dart'; // ✅

NOT:
import 'package:sakoa/pages/message/chat/widgets/voice_message_player.dart'; // ❌

// 2. Verify widget usage
VoiceMessagePlayerV4( // ✅
  messageId: item.id ?? '',
  ...
)

NOT:
VoiceMessagePlayer( // ❌
  ...
)

// 3. Hot RESTART (not hot reload)
flutter run --hot
```

---

### Issue: "Player shows loading forever"

**Symptoms:**
- Circular progress spins indefinitely
- Never starts playing
- No error message

**Root Cause:** Audio file download/cache failure

**Fix:**
```dart
// 1. Check logs for errors
flutter logs | grep "VoicePlayerV4"

// 2. Clear cache
VoiceCacheManager.to.clearAllCache();

// 3. Check network connection
final isOnline = await Connectivity().checkConnectivity();
print('Online: $isOnline');

// 4. Verify Firebase Storage rules allow read
// In Firebase Console -> Storage -> Rules:
service firebase.storage {
  match /b/{bucket}/o {
    match /voice_messages/{messageId} {
      allow read: if request.auth != null;  // ✅
    }
  }
}
```

---

### Issue: "Multiple messages play at once"

**Symptoms:**
- Click one message, another plays
- Audio overlaps from different messages
- Can't stop playback

**Root Cause:** Not using V4 player (V4 has isolated instances)

**Fix:**
```dart
// Verify EACH message has dedicated player instance
class _VoiceMessagePlayerV4State {
  late final AudioPlayer _player; // Must be instance variable!
  
  @override
  void initState() {
    _player = AudioPlayer(); // New instance per message ✅
  }
}

// NOT this (shared player):
final _player = VoiceMessageService.to._player; // ❌ WRONG!
```

---

## 🎨 WAVEFORM ISSUES

### Issue: "Waveform is flat/boring"

**Symptoms:**
- All bars same height
- No variation in waveform
- Looks artificial

**Root Cause:** Using fallback waveform (real extraction failed)

**Fix:**
```dart
// 1. Check logs
flutter logs | grep "AudioWaveformAnalyzer"

// Expected:
[AudioWaveformAnalyzer] ✅ Waveform extracted: 60 samples

// If you see:
[AudioWaveformAnalyzer] ⚠️ Waveform load failed
// Then audio file couldn't be processed

// 2. For REAL waveforms, add FFT library:
// pubspec.yaml:
dependencies:
  flutter_audio_waveforms: ^1.0.0

// 3. Uncomment native extraction in audio_waveform_analyzer.dart:
// Line ~90:
final waveformData = await extractor.extractWaveform(
  audioFile: filePath,
  sampleRate: 44100,
);
```

---

### Issue: "Waveform doesn't match audio timing"

**Symptoms:**
- Progress bar doesn't sync with waveform
- Waveform fills up too fast/slow
- Seek doesn't work correctly

**Root Cause:** Duration mismatch

**Fix:**
```dart
// 1. Verify duration is set correctly
VoiceMessagePlayerV4(
  messageId: item.id ?? '',
  audioUrl: item.content ?? '',
  durationSeconds: item.voice_duration ?? 0, // Must be accurate! ✅
  isMyMessage: false,
)

// 2. Check if voice_duration is being saved correctly
// In voice_message_service.dart:
final content = Msgcontent(
  ...
  voice_duration: duration.inSeconds, // ✅ Save duration
  ...
);

// 3. Debug duration:
print('Duration from DB: ${item.voice_duration}');
print('Actual audio duration: ${_player.duration?.inSeconds}');
// These should match!
```

---

## 💾 CACHE ISSUES

### Issue: "Audio downloads every time (no caching)"

**Symptoms:**
- Slow playback start every time
- Network usage high
- Same message takes time to load repeatedly

**Root Cause:** Cache manager not initialized or cache hit failing

**Fix:**
```dart
// 1. Verify service initialization in global.dart
await Get.putAsync(() => VoiceCacheManager().init()); // ✅

// 2. Check cache statistics
final stats = VoiceCacheManager.to.getCacheStats();
print('Cache stats: $stats');

// Expected output:
{
  totalFiles: 15,
  totalSizeMB: 23.45,
  cacheHitRate: 85.5%,  // Should be >80% after first load
  ...
}

// 3. If hit rate is 0%, check cache directory permissions:
final cacheDir = await getApplicationDocumentsDirectory();
print('Cache dir: ${cacheDir.path}/voice_cache');
// Should exist and be writable

// 4. Manual cache test:
final path = await VoiceCacheManager.to.getCachedVoiceFile(
  'https://example.com/test.m4a',
);
print('Cached path: $path'); // Should return local path on second call
```

---

### Issue: "Cache grows too large"

**Symptoms:**
- App storage shows hundreds of MB
- Disk space warnings
- Cache never cleans up

**Root Cause:** LRU eviction not working / max size too high

**Fix:**
```dart
// 1. Adjust max cache size in voice_cache_manager.dart:
static const MAX_CACHE_SIZE_MB = 200; // Reduce from 500

// 2. Force cleanup:
await VoiceCacheManager.to._enforceMaxCacheSize();

// 3. Clear old files:
await VoiceCacheManager.to._cleanupExpiredFiles();

// 4. Check current size:
print('Total cache: ${VoiceCacheManager.to.totalCacheSize.value / 1024 / 1024} MB');

// 5. Nuclear option (clear everything):
await VoiceCacheManager.to.clearAllCache();
```

---

## 🚀 PERFORMANCE ISSUES

### Issue: "UI freezes during playback"

**Symptoms:**
- App lags when playing voice messages
- Animations stuttery
- Can't scroll while playing

**Root Cause:** Heavy processing on main thread

**Fix:**
```dart
// 1. Verify waveform extraction is async
Future<void> _loadWaveform() async {
  // Must use await and async! ✅
  final waveform = await _waveformAnalyzer.extractWaveform(audioUrl);
}

// 2. Check if using simulated waveform (lighter)
// In audio_waveform_analyzer.dart, line ~150:
return _generateFallbackWaveform(sampleCount); // Fast, no FFT

// 3. Reduce waveform sample count for better performance:
final waveform = await analyzer.extractWaveform(
  audioUrl,
  sampleCount: 40, // Reduce from 60 for smoother UI
);

// 4. Profile performance:
flutter run --profile
// Then use DevTools -> Performance tab
```

---

### Issue: "Memory usage keeps increasing"

**Symptoms:**
- App gets slower over time
- Memory warning
- Eventually crashes

**Root Cause:** Player instances not disposed / cache not bounded

**Fix:**
```dart
// 1. Verify player disposal
@override
void dispose() {
  _player.dispose(); // ✅ Must dispose dedicated player!
  super.dispose();
}

// 2. Check waveform cache size
print('Waveforms cached: ${_waveformCache.length}');
// Should not exceed WAVEFORM_CACHE_SIZE (100)

// 3. Monitor memory in real-time:
flutter run --observatory-port=8888
// Then use DevTools -> Memory tab

// 4. Clear caches periodically:
Timer.periodic(Duration(minutes: 30), (_) {
  if (_waveformCache.length > 50) {
    // Clear old waveforms
  }
});
```

---

## 🔌 NETWORK ISSUES

### Issue: "Download fails / timeout errors"

**Symptoms:**
- "Failed to load audio file" error
- Timeout after several seconds
- Only happens on slow networks

**Root Cause:** Network timeout too short / retry logic not working

**Fix:**
```dart
// 1. Increase timeout in voice_cache_manager.dart:
static const DOWNLOAD_TIMEOUT = Duration(minutes: 10); // Increase if needed

// 2. Check download error logs:
flutter logs | grep "VoiceCacheManager"

// 3. Test network speed:
final dio = Dio();
final start = DateTime.now();
await dio.download('https://example.com/test.m4a', '/tmp/test');
final elapsed = DateTime.now().difference(start);
print('Download took: ${elapsed.inSeconds}s');

// 4. Enable retry logic (already implemented):
if (_pendingMessages[entry.key] != null) {
  await _retryPendingMessages(); // Auto-retry with exponential backoff
}
```

---

### Issue: "Works on WiFi but not on mobile data"

**Symptoms:**
- Voice messages load on WiFi
- Fails on 4G/5G
- Shows offline error

**Root Cause:** Firewall/VPN blocking, or storage permissions

**Fix:**
```dart
// 1. Check connectivity type:
final connectivity = await Connectivity().checkConnectivity();
print('Connection: $connectivity');

// 2. Verify Firebase Storage rules allow mobile access:
// Firebase Console -> Storage -> Rules:
allow read: if request.auth != null; // ✅ No network type restrictions

// 3. Check if VPN is interfering:
// Disable VPN and test

// 4. Test direct download:
final dio = Dio();
final response = await dio.get(audioUrl);
print('Direct download status: ${response.statusCode}');
```

---

## 🐛 ERROR MESSAGES

### Error: "Services not initialized"

**Full Error:**
```
[VERBOSE-2:dart_vm_initializer.cc(41)] Unhandled Exception:
'package:get/get_instance/src/extension_instance.dart': Failed assertion:
"Service VoiceCacheManager is not initialized"
```

**Fix:**
```dart
// 1. Ensure services are initialized in global.dart BEFORE app runs
await Get.putAsync(() => VoiceCacheManager().init()); // ✅

// 2. Verify initialization order:
class Global {
  static Future init() async {
    // ... other initialization
    
    // Voice services MUST be initialized:
    await Get.putAsync(() => VoiceCacheManager().init());
    await Get.putAsync(() => AudioWaveformAnalyzer().init());
    
    print('[Global] ✅ All services initialized');
  }
}

// 3. Hot RESTART (not hot reload) to reinitialize
flutter run --hot
```

---

### Error: "Null check operator used on null value"

**Full Error:**
```
The following _CastError was thrown building VoiceMessagePlayerV4:
Null check operator used on a null value
```

**Fix:**
```dart
// 1. Check nullable fields are handled:
VoiceMessagePlayerV4(
  messageId: item.id ?? 'unknown', // ✅ Provide default
  audioUrl: item.content ?? '',    // ✅ Provide default
  durationSeconds: item.voice_duration ?? 0, // ✅ Provide default
  isMyMessage: false,
)

// 2. Verify Msgcontent has proper defaults:
class Msgcontent {
  final String? id;
  final String? content;
  final int? voice_duration;
  // All nullable with null checks in widget ✅
}

// 3. Add null safety in player:
final duration = widget.durationSeconds > 0
    ? Duration(seconds: widget.durationSeconds)
    : _player.duration ?? Duration.zero; // ✅ Fallback
```

---

### Error: "Platform channel not found"

**Full Error:**
```
MissingPluginException(No implementation found for method setSecureFlag 
on channel com.chatty.sakoa/security)
```

**This is from ChatSecurityService**, not voice system. Safe to ignore or fix separately.

---

## 🔍 DEBUGGING TOOLS

### Enable Verbose Logging

Add to main.dart:
```dart
void main() async {
  // Enable all logs
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });
  
  await Global.init();
  runApp(MyApp());
}
```

### Test Individual Components

```dart
// Test cache manager:
void testCacheManager() async {
  final manager = VoiceCacheManager.to;
  
  // Test download
  final path = await manager.getCachedVoiceFile('https://test.com/audio.m4a');
  print('✅ Downloaded to: $path');
  
  // Test cache hit
  final path2 = await manager.getCachedVoiceFile('https://test.com/audio.m4a');
  print('✅ Cache hit: ${path == path2}');
  
  // Test stats
  print('Stats: ${manager.getCacheStats()}');
}

// Test waveform analyzer:
void testWaveformAnalyzer() async {
  final analyzer = AudioWaveformAnalyzer.to;
  
  final waveform = await analyzer.extractWaveform(
    'https://test.com/audio.m4a',
    sampleCount: 60,
  );
  
  print('✅ Waveform: ${waveform.length} samples');
  print('Min: ${waveform.reduce(min)}');
  print('Max: ${waveform.reduce(max)}');
}
```

---

## 🆘 LAST RESORT

If nothing works:

```bash
# 1. Nuclear reset
flutter clean
rm -rf ios/Pods
rm -rf ios/Podfile.lock
rm -rf pubspec.lock

# 2. Fresh dependencies
flutter pub get
cd ios && pod install && cd ..

# 3. Clear all caches
flutter pub cache repair

# 4. Rebuild from scratch
flutter run --release

# 5. If STILL not working, check:
- Is services.dart exporting new services? ✅
- Is global.dart initializing new services? ✅
- Are files in correct directories? ✅
- Did you hot RESTART (not reload)? ✅
```

---

## 📞 SUPPORT

If issue persists:

1. **Check logs** with:
   ```
   flutter logs | grep -E "VoicePlayer|VoiceCache|WaveformAnalyzer"
   ```

2. **Collect diagnostic info**:
   ```dart
   print('Flutter version: ${Platform.version}');
   print('Cache stats: ${VoiceCacheManager.to.getCacheStats()}');
   print('Services initialized: ${Get.isRegistered<VoiceCacheManager>()}');
   ```

3. **Create minimal reproduction**:
   - Single voice message
   - Single chat screen
   - Isolated test

4. **Provide**:
   - Error logs
   - Steps to reproduce
   - Flutter version
   - Device/emulator info

---

**Remember:** 90% of issues are from:
- ❌ Not using V4 player
- ❌ Not initializing services
- ❌ Hot reload instead of hot restart
- ❌ Missing dependencies

✅ **Follow the integration guide exactly and everything will work!**
