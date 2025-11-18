/// 🚨 BASE EXCEPTION LAYER
///
/// Abstract base exception for all domain-specific exceptions in the app.
/// All exceptions should extend this base class for consistent error handling.
///
/// Benefits:
/// - Centralized exception structure
/// - Consistent error information across domains
/// - Easy to catch and handle all app exceptions
/// - Better logging and debugging

abstract class BaseException implements Exception {
  /// Human-readable error message
  final String message;

  /// Optional error code for categorization (e.g., 'AUTH_001', 'CHAT_UPLOAD_FAILED')
  final String? code;

  /// Original error that caused this exception (for debugging)
  final dynamic originalError;

  /// Stack trace for debugging
  final StackTrace? stackTrace;

  /// Optional context about where/when the error occurred
  final Map<String, dynamic>? context;

  BaseException({
    required this.message,
    this.code,
    this.originalError,
    this.stackTrace,
    this.context,
  });

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.write('${runtimeType}');

    if (code != null) {
      buffer.write(' [$code]');
    }

    buffer.write(': $message');

    if (context != null && context!.isNotEmpty) {
      buffer.write('\nContext: $context');
    }

    if (originalError != null) {
      buffer.write('\nCaused by: $originalError');
    }

    return buffer.toString();
  }

  /// Get a user-friendly message (without technical details)
  String getUserMessage() {
    return message;
  }

  /// Log this exception with all details
  void log() {
    print('═══════════════════════════════════════════');
    print('🚨 ${runtimeType}');
    if (code != null) print('Code: $code');
    print('Message: $message');
    if (context != null) print('Context: $context');
    if (originalError != null) print('Original Error: $originalError');
    if (stackTrace != null) {
      print('Stack Trace:');
      print(stackTrace);
    }
    print('═══════════════════════════════════════════');
  }
}
