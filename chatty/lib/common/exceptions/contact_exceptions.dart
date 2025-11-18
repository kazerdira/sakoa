import 'base_exception.dart';

/// Base exception for all contact-related errors
abstract class ContactException extends BaseException {
  ContactException({
    required super.message,
    required super.code,
    super.originalError,
    super.stackTrace,
    super.context,
  });
}

/// Exception thrown when fetching contacts fails
class ContactFetchException extends ContactException {
  ContactFetchException({
    String? message,
    Object? originalError,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) : super(
          message: message ?? 'Failed to fetch contacts',
          code: 'CONTACT_FETCH_ERROR',
          originalError: originalError,
          stackTrace: stackTrace,
          context: context,
        );

  @override
  String getUserMessage() => 'Unable to load contacts. Please try again.';
}

/// Exception thrown when searching users fails
class UserSearchException extends ContactException {
  UserSearchException({
    String? message,
    Object? originalError,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) : super(
          message: message ?? 'Failed to search users',
          code: 'USER_SEARCH_ERROR',
          originalError: originalError,
          stackTrace: stackTrace,
          context: context,
        );

  @override
  String getUserMessage() => 'Unable to search users. Please try again.';
}

/// Exception thrown when sending a contact request fails
class ContactRequestException extends ContactException {
  ContactRequestException({
    String? message,
    Object? originalError,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) : super(
          message: message ?? 'Failed to send contact request',
          code: 'CONTACT_REQUEST_ERROR',
          originalError: originalError,
          stackTrace: stackTrace,
          context: context,
        );

  @override
  String getUserMessage() =>
      'Unable to send contact request. Please try again.';
}

/// Exception thrown when accepting a contact request fails
class AcceptRequestException extends ContactException {
  AcceptRequestException({
    String? message,
    Object? originalError,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) : super(
          message: message ?? 'Failed to accept contact request',
          code: 'ACCEPT_REQUEST_ERROR',
          originalError: originalError,
          stackTrace: stackTrace,
          context: context,
        );

  @override
  String getUserMessage() => 'Unable to accept request. Please try again.';
}

/// Exception thrown when rejecting a contact request fails
class RejectRequestException extends ContactException {
  RejectRequestException({
    String? message,
    Object? originalError,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) : super(
          message: message ?? 'Failed to reject contact request',
          code: 'REJECT_REQUEST_ERROR',
          originalError: originalError,
          stackTrace: stackTrace,
          context: context,
        );

  @override
  String getUserMessage() => 'Unable to reject request. Please try again.';
}

/// Exception thrown when canceling a contact request fails
class CancelRequestException extends ContactException {
  CancelRequestException({
    String? message,
    Object? originalError,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) : super(
          message: message ?? 'Failed to cancel contact request',
          code: 'CANCEL_REQUEST_ERROR',
          originalError: originalError,
          stackTrace: stackTrace,
          context: context,
        );

  @override
  String getUserMessage() => 'Unable to cancel request. Please try again.';
}

/// Exception thrown when blocking a user fails
class BlockingException extends ContactException {
  BlockingException({
    String? message,
    Object? originalError,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) : super(
          message: message ?? 'Failed to block user',
          code: 'BLOCKING_ERROR',
          originalError: originalError,
          stackTrace: stackTrace,
          context: context,
        );

  @override
  String getUserMessage() => 'Unable to block user. Please try again.';
}

/// Exception thrown when unblocking a user fails
class UnblockingException extends ContactException {
  UnblockingException({
    String? message,
    Object? originalError,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) : super(
          message: message ?? 'Failed to unblock user',
          code: 'UNBLOCKING_ERROR',
          originalError: originalError,
          stackTrace: stackTrace,
          context: context,
        );

  @override
  String getUserMessage() => 'Unable to unblock user. Please try again.';
}

/// Exception thrown when checking block status fails
class BlockStatusException extends ContactException {
  BlockStatusException({
    String? message,
    Object? originalError,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) : super(
          message: message ?? 'Failed to check block status',
          code: 'BLOCK_STATUS_ERROR',
          originalError: originalError,
          stackTrace: stackTrace,
          context: context,
        );

  @override
  String getUserMessage() => 'Unable to check block status. Please try again.';
}

/// Utility class for handling contact exceptions
class ContactExceptionHandler {
  static ContactException handle(Object error, StackTrace stackTrace) {
    if (error is ContactException) {
      return error;
    }

    // Map known errors to specific exceptions
    final errorMessage = error.toString().toLowerCase();

    if (errorMessage.contains('network') ||
        errorMessage.contains('connection')) {
      return ContactFetchException(
        message: 'Network error while accessing contacts',
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    if (errorMessage.contains('permission')) {
      return ContactFetchException(
        message: 'Permission denied',
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // Default to generic contact fetch exception
    return ContactFetchException(
      originalError: error,
      stackTrace: stackTrace,
    );
  }
}
