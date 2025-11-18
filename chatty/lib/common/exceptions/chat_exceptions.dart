/// 🚨 EXCEPTION HANDLING LAYER
///
/// Centralized exception types for the chat domain.
/// Benefits:
/// - Type-safe error handling
/// - Consistent error messages
/// - Easy to log and track
/// - Better user feedback

/// Base exception for all chat-related errors
abstract class ChatException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  final StackTrace? stackTrace;

  ChatException({
    required this.message,
    this.code,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() {
    if (code != null) {
      return 'ChatException [$code]: $message';
    }
    return 'ChatException: $message';
  }
}

/// Voice message specific exceptions
class VoiceMessageException extends ChatException {
  VoiceMessageException({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });
}

/// Upload failures
class UploadException extends ChatException {
  final String? filePath;
  final int? fileSize;

  UploadException({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
    this.filePath,
    this.fileSize,
  });
}

/// Network/connectivity issues
class NetworkException extends ChatException {
  NetworkException({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });
}

/// Permission/access issues
class PermissionException extends ChatException {
  PermissionException({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });
}

/// Cache-related failures
class CacheException extends ChatException {
  CacheException({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });
}

/// Message delivery failures
class MessageDeliveryException extends ChatException {
  final String? messageId;

  MessageDeliveryException({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
    this.messageId,
  });
}

/// Blocking/security issues
class SecurityException extends ChatException {
  SecurityException({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });
}

/// 🛠️ Exception Handler Utility
class ChatExceptionHandler {
  /// Convert generic exceptions to typed chat exceptions
  static ChatException fromException(Exception e, {StackTrace? stackTrace}) {
    if (e is ChatException) return e;

    final errorString = e.toString().toLowerCase();

    // Network errors
    if (errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('timeout')) {
      return NetworkException(
        message: 'Network connection failed',
        originalError: e,
        stackTrace: stackTrace,
      );
    }

    // Upload errors
    if (errorString.contains('upload') || errorString.contains('storage')) {
      return UploadException(
        message: 'Failed to upload file',
        originalError: e,
        stackTrace: stackTrace,
      );
    }

    // Permission errors
    if (errorString.contains('permission') || errorString.contains('denied')) {
      return PermissionException(
        message: 'Permission denied',
        originalError: e,
        stackTrace: stackTrace,
      );
    }

    // Generic chat exception - use VoiceMessageException as default
    return VoiceMessageException(
      message: e.toString(),
      originalError: e,
      stackTrace: stackTrace,
    );
  }

  /// Get user-friendly message from exception
  static String getUserMessage(ChatException e) {
    if (e is NetworkException) {
      return 'No internet connection. Please check your network.';
    }
    if (e is UploadException) {
      return 'Failed to upload. Please try again.';
    }
    if (e is PermissionException) {
      return 'Permission denied. Please check app permissions.';
    }
    if (e is VoiceMessageException) {
      return 'Failed to send voice message. Please try again.';
    }
    if (e is CacheException) {
      return 'Cache error. Message will be downloaded.';
    }
    if (e is MessageDeliveryException) {
      return 'Message not delivered. Retrying...';
    }
    if (e is SecurityException) {
      return 'Access denied. You may be blocked.';
    }

    return 'Something went wrong. Please try again.';
  }

  /// Log exception with context
  static void logException(ChatException e, {String? context}) {
    final prefix = context != null ? '[$context]' : '[ChatException]';
    print('$prefix ❌ ${e.message}');
    if (e.code != null) {
      print('$prefix Code: ${e.code}');
    }
    if (e.originalError != null) {
      print('$prefix Original: ${e.originalError}');
    }
    if (e.stackTrace != null) {
      print('$prefix Stack:\n${e.stackTrace}');
    }
  }
}
