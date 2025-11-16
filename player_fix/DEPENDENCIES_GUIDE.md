# 📦 REQUIRED DEPENDENCIES FOR SUPERNOVA VOICE SYSTEM

Add these to your `chatty/pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter

  # ============ EXISTING DEPENDENCIES ============
  # (Keep all your existing dependencies here)
  
  # ============ NEW: VOICE SYSTEM DEPENDENCIES ============
  
  # Caching & Storage
  crypto: ^3.0.3                  # For SHA-256 hashing of cache keys
  dio: ^5.4.0                     # High-performance HTTP client for downloads
  get_storage: ^2.1.1             # Persistent key-value storage
  
  # Audio Processing (Required)
  just_audio: ^0.9.36             # Already have this (audio playback)
  record: ^5.0.4                  # Already have this (voice recording)
  
  # File Management (Required)
  path_provider: ^2.1.1           # Already have this (cache directories)
  
  # Network Monitoring (Required)
  connectivity_plus: ^5.0.2       # Already have this (offline detection)
  
  # ============ OPTIONAL: ADVANCED FEATURES ============
  
  # For REAL FFT-based waveform extraction (RECOMMENDED for production):
  # flutter_audio_waveforms: ^1.0.0   # Native waveform extraction
  # OR
  # flutter_fft: ^2.0.0                # FFT analysis library
  
  # For advanced audio analysis:
  # flutter_sound: ^9.3.3              # Full audio processing suite
  # audio_session: ^0.1.16             # Audio session management

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^2.0.0

# ============ PLATFORM-SPECIFIC CONFIGURATION ============

# iOS Configuration (ios/Podfile)
# Add for audio recording permissions:
# post_install do |installer|
#   installer.pods_project.targets.each do |target|
#     flutter_additional_ios_build_settings(target)
#     target.build_configurations.each do |config|
#       config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
#         '$(inherited)',
#         'AUDIO_RECORDING_ENABLED=1',
#       ]
#     end
#   end
# end

# Android Configuration (android/app/build.gradle)
# Already configured for audio features

flutter:
  uses-material-design: true
  # ... rest of your flutter configuration
```

---

## 🔧 Installation Steps

### 1. Update pubspec.yaml
```bash
# Add the new dependencies listed above
# Then run:
flutter pub get
```

### 2. Verify Installation
```bash
flutter pub deps
```

Check that these packages are installed:
- ✅ crypto: ^3.0.3
- ✅ dio: ^5.4.0
- ✅ get_storage: ^2.1.1

### 3. Clean & Rebuild (Recommended)
```bash
flutter clean
flutter pub get
flutter run
```

---

## 📱 OPTIONAL: Native FFT Libraries

For **production-grade real waveform visualization**, choose ONE:

### Option A: flutter_audio_waveforms (Recommended)
```yaml
dependencies:
  flutter_audio_waveforms: ^1.0.0
```

**Pros:**
- ✅ Native C++ FFT (fastest)
- ✅ Built specifically for waveforms
- ✅ Simple API

**Cons:**
- ⚠️ Limited platform support

**Usage in `audio_waveform_analyzer.dart`:**
```dart
final extractor = AudioWaveformExtractor();
final waveform = await extractor.extractWaveform(audioFile: path);
```

---

### Option B: flutter_fft
```yaml
dependencies:
  flutter_fft: ^2.0.0
```

**Pros:**
- ✅ Full FFT analysis
- ✅ More flexible
- ✅ Better platform support

**Cons:**
- ⚠️ More complex API
- ⚠️ Requires custom processing

**Usage:**
```dart
final fft = FlutterFFT();
await fft.startRecorder();
final spectrum = fft.getFrequencySpectrum();
```

---

### Option C: flutter_sound (Full Suite)
```yaml
dependencies:
  flutter_sound: ^9.3.3
  audio_session: ^0.1.16
```

**Pros:**
- ✅ Complete audio solution
- ✅ Recording + playback + analysis
- ✅ Professional-grade

**Cons:**
- ⚠️ Large package size
- ⚠️ Complex setup
- ⚠️ Overkill if only need waveforms

---

## 🎯 Recommended Setup (Minimal)

For **immediate use** without native FFT:

```yaml
dependencies:
  # Core dependencies (REQUIRED)
  crypto: ^3.0.3
  dio: ^5.4.0
  get_storage: ^2.1.1
  
  # Your existing dependencies (keep these)
  just_audio: ^0.9.36
  record: ^5.0.4
  path_provider: ^2.1.1
  connectivity_plus: ^5.0.2
```

**Result:**
- ✅ Full caching system works
- ✅ Voice playback works perfectly
- ✅ Simulated waveforms (looks good!)
- ⏳ Real FFT waveforms (add later)

---

## 🚀 Recommended Setup (Production)

For **maximum quality** with real FFT:

```yaml
dependencies:
  # Core dependencies
  crypto: ^3.0.3
  dio: ^5.4.0
  get_storage: ^2.1.1
  
  # FFT for real waveforms
  flutter_audio_waveforms: ^1.0.0
  
  # Existing
  just_audio: ^0.9.36
  record: ^5.0.4
  path_provider: ^2.1.1
  connectivity_plus: ^5.0.2
```

**Result:**
- ✅ Everything works perfectly
- ✅ REAL waveforms from audio FFT
- ✅ Telegram-level quality

---

## 🔍 Dependency Breakdown

| Package | Purpose | Size | Required |
|---------|---------|------|----------|
| `crypto` | SHA-256 hashing for cache keys | 150KB | ✅ Yes |
| `dio` | Efficient HTTP downloads | 300KB | ✅ Yes |
| `get_storage` | Persistent cache metadata | 50KB | ✅ Yes |
| `flutter_audio_waveforms` | Native FFT waveforms | 2MB | ⏳ Optional |
| `flutter_fft` | FFT analysis | 1MB | ⏳ Optional |
| `flutter_sound` | Full audio suite | 5MB | ⏳ Optional |

**Total Additional Size:**
- Minimal: ~500KB (required only)
- Recommended: ~2.5MB (with FFT)
- Maximum: ~6MB (full suite)

---

## 🐛 Common Dependency Issues

### Issue: "crypto package not found"
```bash
flutter pub get
flutter clean
flutter pub get
```

### Issue: "Dio version conflict"
```yaml
# Use dependency_overrides if needed:
dependency_overrides:
  dio: ^5.4.0
```

### Issue: "GetStorage initialization failed"
```dart
// In main.dart, ensure initialization:
await GetStorage.init('voice_cache_metadata_v3');
```

### Issue: "FFT package not working on iOS"
```bash
cd ios
pod install
cd ..
flutter clean
flutter run
```

---

## ✅ Verification

After adding dependencies, run this test:

```dart
// In any screen
void testDependencies() {
  // Test crypto
  final hash = sha256.convert(utf8.encode('test')).toString();
  print('Crypto: $hash');
  
  // Test dio
  final dio = Dio();
  print('Dio: ${dio.options.baseUrl}');
  
  // Test get_storage
  final storage = GetStorage('test');
  storage.write('key', 'value');
  print('GetStorage: ${storage.read('key')}');
  
  print('✅ All dependencies working!');
}
```

Expected output:
```
Crypto: 9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08
Dio: 
GetStorage: value
✅ All dependencies working!
```

---

## 📦 Final pubspec.yaml (Complete Example)

```yaml
name: sakoa
description: Industrial-grade chat application
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter

  # State Management
  get: ^4.6.6
  get_storage: ^2.1.1  # 🔥 NEW: For voice cache

  # Firebase
  firebase_core: ^2.24.2
  firebase_messaging: ^14.7.9
  cloud_firestore: ^4.13.6
  firebase_storage: ^11.5.6

  # UI
  flutter_screenutil: ^5.9.0
  cached_network_image: ^3.3.0
  flutter_easyloading: ^3.0.5

  # Audio
  just_audio: ^0.9.36
  record: ^5.0.4
  path_provider: ^2.1.1

  # Network
  connectivity_plus: ^5.0.2
  dio: ^5.4.0  # 🔥 NEW: For efficient downloads
  
  # Utilities
  intl: ^0.18.1
  package_info_plus: ^5.0.1
  url_launcher: ^6.2.2
  image_picker: ^1.0.5
  shared_preferences: ^2.2.2
  crypto: ^3.0.3  # 🔥 NEW: For cache key hashing

  # Misc
  pull_to_refresh: ^2.0.0
  flutter_localizations:
    sdk: flutter

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^2.0.0

flutter:
  uses-material-design: true
  assets:
    - assets/icons/
    - assets/images/
```

---

**Status:** Ready for Integration ✅  
**Dependencies:** Minimal & Optimized 🎯  
**Size Impact:** <1MB total 📦
