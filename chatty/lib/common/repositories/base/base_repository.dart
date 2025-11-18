/// 🏗️ BASE REPOSITORY
///
/// Abstract base class for all repositories in the app.
/// Provides common structure and utilities for repository implementations.
///
/// Benefits:
/// - Consistent repository interface across domains
/// - Shared error handling patterns
/// - Easy to mock for testing
/// - Clear separation of concerns

abstract class BaseRepository {
  /// Repository name for logging and debugging
  String get repositoryName;

  /// Log a debug message
  void logDebug(String message) {
    print('[$repositoryName] 🔍 $message');
  }

  /// Log an info message
  void logInfo(String message) {
    print('[$repositoryName] ℹ️ $message');
  }

  /// Log a success message
  void logSuccess(String message) {
    print('[$repositoryName] ✅ $message');
  }

  /// Log a warning message
  void logWarning(String message) {
    print('[$repositoryName] ⚠️ $message');
  }

  /// Log an error message
  void logError(String message, [dynamic error, StackTrace? stackTrace]) {
    print('[$repositoryName] ❌ $message');
    if (error != null) {
      print('[$repositoryName] Error details: $error');
    }
    if (stackTrace != null) {
      print('[$repositoryName] Stack trace: $stackTrace');
    }
  }

  /// Handle exceptions in a consistent way
  /// Subclasses can override this for custom error handling
  Future<T> handleException<T>(
    Future<T> Function() operation, {
    required String operationName,
    T? fallbackValue,
  }) async {
    try {
      logDebug('Starting operation: $operationName');
      final result = await operation();
      logSuccess('Completed operation: $operationName');
      return result;
    } catch (e, stackTrace) {
      logError('Failed operation: $operationName', e, stackTrace);

      if (fallbackValue != null) {
        logWarning('Returning fallback value for: $operationName');
        return fallbackValue;
      }

      rethrow;
    }
  }

  /// Dispose resources (override if needed)
  void dispose() {
    logDebug('Disposing repository');
  }
}
