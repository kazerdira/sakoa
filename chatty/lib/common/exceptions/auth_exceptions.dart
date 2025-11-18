import 'package:sakoa/common/exceptions/base_exception.dart';

/// Base exception class for all authentication-related errors
abstract class AuthException extends BaseException {
  AuthException({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
    super.context,
  });
}

/// Exception thrown when sign-in fails
/// Used for: Google, Facebook, Apple, Email, Phone sign-in failures
class SignInException extends AuthException {
  final String? provider; // 'google', 'facebook', 'apple', 'email', 'phone'

  SignInException({
    required super.message,
    this.provider,
    super.code = 'SIGN_IN_ERROR',
    super.originalError,
    super.stackTrace,
    super.context,
  });

  @override
  String getUserMessage() {
    if (provider != null) {
      return 'Failed to sign in with $provider: $message';
    }
    return 'Sign in failed: $message';
  }
}

/// Exception thrown when sign-up/registration fails
/// Used for: Email registration, account creation errors
class SignUpException extends AuthException {
  SignUpException({
    required super.message,
    super.code = 'SIGN_UP_ERROR',
    super.originalError,
    super.stackTrace,
    super.context,
  });

  @override
  String getUserMessage() => 'Registration failed: $message';
}

/// Exception thrown when sign-out fails
/// Used for: Firebase sign-out, clearing local data
class SignOutException extends AuthException {
  SignOutException({
    required super.message,
    super.code = 'SIGN_OUT_ERROR',
    super.originalError,
    super.stackTrace,
    super.context,
  });

  @override
  String getUserMessage() => 'Sign out failed: $message';
}

/// Exception thrown when email verification fails
/// Used for: Sending verification emails, checking verification status
class EmailVerificationException extends AuthException {
  EmailVerificationException({
    required super.message,
    super.code = 'EMAIL_VERIFICATION_ERROR',
    super.originalError,
    super.stackTrace,
    super.context,
  });

  @override
  String getUserMessage() => 'Email verification failed: $message';
}

/// Exception thrown when password reset fails
/// Used for: Sending password reset emails
class PasswordResetException extends AuthException {
  PasswordResetException({
    required super.message,
    super.code = 'PASSWORD_RESET_ERROR',
    super.originalError,
    super.stackTrace,
    super.context,
  });

  @override
  String getUserMessage() => 'Password reset failed: $message';
}

/// Exception thrown when social authentication fails
/// Used for: Google, Facebook, Apple provider-specific errors
class SocialAuthException extends AuthException {
  final String provider; // 'google', 'facebook', 'apple'

  SocialAuthException({
    required super.message,
    required this.provider,
    super.code = 'SOCIAL_AUTH_ERROR',
    super.originalError,
    super.stackTrace,
    super.context,
  });

  @override
  String getUserMessage() => '$provider authentication failed: $message';
}

/// Exception thrown when phone authentication fails
/// Used for: Phone number verification, SMS code validation
class PhoneAuthException extends AuthException {
  final String? phoneNumber;

  PhoneAuthException({
    required super.message,
    this.phoneNumber,
    super.code = 'PHONE_AUTH_ERROR',
    super.originalError,
    super.stackTrace,
    super.context,
  });

  @override
  String getUserMessage() {
    if (phoneNumber != null) {
      return 'Phone authentication failed for $phoneNumber: $message';
    }
    return 'Phone authentication failed: $message';
  }
}

/// Exception thrown when token refresh fails
/// Used for: Refreshing access tokens, getting updated profile
class TokenRefreshException extends AuthException {
  TokenRefreshException({
    required super.message,
    super.code = 'TOKEN_REFRESH_ERROR',
    super.originalError,
    super.stackTrace,
    super.context,
  });

  @override
  String getUserMessage() => 'Token refresh failed: $message';
}

/// Exception thrown when profile update fails
/// Used for: Updating user profile, binding FCM token
class ProfileUpdateException extends AuthException {
  ProfileUpdateException({
    required super.message,
    super.code = 'PROFILE_UPDATE_ERROR',
    super.originalError,
    super.stackTrace,
    super.context,
  });

  @override
  String getUserMessage() => 'Profile update failed: $message';
}

/// Exception thrown when Firestore user profile operations fail
/// Used for: Creating/updating user document in Firestore for search
class FirestoreProfileException extends AuthException {
  FirestoreProfileException({
    required super.message,
    super.code = 'FIRESTORE_PROFILE_ERROR',
    super.originalError,
    super.stackTrace,
    super.context,
  });

  @override
  String getUserMessage() => 'Failed to update user profile: $message';
}

/// Utility class to handle common auth exception scenarios
class AuthExceptionHandler {
  /// Maps Firebase Auth error codes to user-friendly messages
  static String getFirebaseAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided for that user.';
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'The account already exists for that email.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'operation-not-allowed':
        return 'This operation is not allowed.';
      case 'too-many-requests':
        return 'Too many requests. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      case 'invalid-verification-code':
        return 'Invalid verification code.';
      case 'invalid-verification-id':
        return 'Invalid verification ID.';
      case 'credential-already-in-use':
        return 'This credential is already associated with a different user.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with the same email but different sign-in credentials.';
      default:
        return 'Authentication error: $code';
    }
  }

  /// Creates appropriate exception from Firebase Auth error
  static AuthException fromFirebaseAuthError(
    dynamic error, {
    String? provider,
    StackTrace? stackTrace,
  }) {
    String code = 'UNKNOWN_ERROR';
    String message = 'An unknown error occurred';

    if (error.toString().contains('code')) {
      final match = RegExp(r'code:\s*(\S+)').firstMatch(error.toString());
      if (match != null) {
        code = match.group(1) ?? code;
        message = getFirebaseAuthErrorMessage(code);
      }
    }

    if (provider != null) {
      return SignInException(
        message: message,
        provider: provider,
        code: code,
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    return SignInException(
      message: message,
      code: code,
      originalError: error,
      stackTrace: stackTrace,
    );
  }
}
