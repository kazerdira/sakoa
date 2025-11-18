import 'base_exception.dart';

/// Base exception for all call-related errors
abstract class CallException extends BaseException {
  CallException({
    required super.message,
    required super.code,
    super.originalError,
    super.stackTrace,
    super.context,
  });
}

/// Exception thrown when initiating a call fails
class CallInitiationException extends CallException {
  CallInitiationException({
    String? message,
    Object? originalError,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) : super(
          message: message ?? 'Failed to initiate call',
          code: 'CALL_INITIATION_ERROR',
          originalError: originalError,
          stackTrace: stackTrace,
          context: context,
        );

  @override
  String getUserMessage() => 'Unable to start call. Please try again.';
}

/// Exception thrown when joining a call fails
class CallJoinException extends CallException {
  CallJoinException({
    String? message,
    Object? originalError,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) : super(
          message: message ?? 'Failed to join call',
          code: 'CALL_JOIN_ERROR',
          originalError: originalError,
          stackTrace: stackTrace,
          context: context,
        );

  @override
  String getUserMessage() =>
      'Unable to join call. Please check your connection.';
}

/// Exception thrown when leaving a call fails
class CallLeaveException extends CallException {
  CallLeaveException({
    String? message,
    Object? originalError,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) : super(
          message: message ?? 'Failed to leave call',
          code: 'CALL_LEAVE_ERROR',
          originalError: originalError,
          stackTrace: stackTrace,
          context: context,
        );

  @override
  String getUserMessage() => 'Unable to end call properly. Please try again.';
}

/// Exception thrown when getting call token fails
class CallTokenException extends CallException {
  CallTokenException({
    String? message,
    Object? originalError,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) : super(
          message: message ?? 'Failed to get call token',
          code: 'CALL_TOKEN_ERROR',
          originalError: originalError,
          stackTrace: stackTrace,
          context: context,
        );

  @override
  String getUserMessage() => 'Unable to authenticate call. Please try again.';
}

/// Exception thrown when sending call notification fails
class CallNotificationException extends CallException {
  CallNotificationException({
    String? message,
    Object? originalError,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) : super(
          message: message ?? 'Failed to send call notification',
          code: 'CALL_NOTIFICATION_ERROR',
          originalError: originalError,
          stackTrace: stackTrace,
          context: context,
        );

  @override
  String getUserMessage() =>
      'Unable to notify recipient. They may not receive the call.';
}

/// Exception thrown when saving call history fails
class CallHistoryException extends CallException {
  CallHistoryException({
    String? message,
    Object? originalError,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) : super(
          message: message ?? 'Failed to save call history',
          code: 'CALL_HISTORY_ERROR',
          originalError: originalError,
          stackTrace: stackTrace,
          context: context,
        );

  @override
  String getUserMessage() => 'Call completed but history not saved.';
}

/// Exception thrown when permission is denied (microphone/camera)
class CallPermissionException extends CallException {
  CallPermissionException({
    String? message,
    Object? originalError,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) : super(
          message: message ?? 'Call permission denied',
          code: 'CALL_PERMISSION_ERROR',
          originalError: originalError,
          stackTrace: stackTrace,
          context: context,
        );

  @override
  String getUserMessage() => 'Microphone/Camera permission required for calls.';
}

/// Exception thrown when Agora engine initialization fails
class AgoraEngineException extends CallException {
  AgoraEngineException({
    String? message,
    Object? originalError,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) : super(
          message: message ?? 'Agora engine error',
          code: 'AGORA_ENGINE_ERROR',
          originalError: originalError,
          stackTrace: stackTrace,
          context: context,
        );

  @override
  String getUserMessage() => 'Call system error. Please restart the app.';
}

/// Exception thrown when call audio/video control fails
class CallMediaException extends CallException {
  CallMediaException({
    String? message,
    Object? originalError,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) : super(
          message: message ?? 'Failed to control call media',
          code: 'CALL_MEDIA_ERROR',
          originalError: originalError,
          stackTrace: stackTrace,
          context: context,
        );

  @override
  String getUserMessage() => 'Unable to control audio/video. Please try again.';
}

/// Utility class for handling call exceptions
class CallExceptionHandler {
  static CallException handle(Object error, StackTrace stackTrace) {
    if (error is CallException) {
      return error;
    }

    // Map known errors to specific exceptions
    final errorMessage = error.toString().toLowerCase();

    if (errorMessage.contains('permission')) {
      return CallPermissionException(
        message: 'Permission denied',
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    if (errorMessage.contains('token')) {
      return CallTokenException(
        message: 'Token error',
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    if (errorMessage.contains('agora') || errorMessage.contains('rtc')) {
      return AgoraEngineException(
        message: 'Agora RTC error',
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    if (errorMessage.contains('network') ||
        errorMessage.contains('connection')) {
      return CallJoinException(
        message: 'Network error during call',
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // Default to generic call initiation exception
    return CallInitiationException(
      originalError: error,
      stackTrace: stackTrace,
    );
  }
}
