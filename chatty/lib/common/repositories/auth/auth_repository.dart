import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:sakoa/common/apis/apis.dart';
import 'package:sakoa/common/entities/entities.dart';
import 'package:sakoa/common/exceptions/auth_exceptions.dart';
import 'package:sakoa/common/repositories/base/base_repository.dart';
import 'package:sakoa/common/store/store.dart';
import 'package:sakoa/common/values/server.dart';

/// Repository for handling all authentication operations
///
/// This repository centralizes all auth-related logic including:
/// - Social sign-in (Google, Facebook, Apple)
/// - Email/password authentication
/// - Phone authentication
/// - Profile management
/// - Token management
/// - Firestore user profile sync
class AuthRepository extends BaseRepository {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  AuthRepository({
    required FirebaseAuth firebaseAuth,
    required FirebaseFirestore firestore,
    GoogleSignIn? googleSignIn,
  })  : _firebaseAuth = firebaseAuth,
        _firestore = firestore,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  @override
  String get repositoryName => 'AuthRepository';

  // ==================== SOCIAL SIGN-IN ====================

  /// Sign in with Google
  Future<UserLoginResponseEntity> signInWithGoogle() async {
    try {
      logInfo('🔑 Starting Google sign-in...');

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw SignInException(
          message: 'Google sign-in was cancelled by user',
          provider: 'google',
          code: 'SIGN_IN_CANCELLED',
        );
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _firebaseAuth.signInWithCredential(credential);

      if (userCredential.user == null) {
        throw SignInException(
          message: 'Firebase returned null user',
          provider: 'google',
          code: 'NULL_USER',
        );
      }

      final user = userCredential.user!;
      logInfo('✅ Firebase sign-in successful: ${user.uid}');

      final loginRequest = LoginRequestEntity(
        avatar: user.photoURL ?? '${SERVER_API_URL}uploads/default.png',
        name: user.displayName,
        email: user.email,
        open_id: user.uid,
        type: 2, // Google
      );

      final result = await _loginToBackend(loginRequest);
      await _updateFirestoreProfile(result.data!, loginRequest.email);

      logSuccess('🎉 Google sign-in complete for: ${result.data!.name}');
      return result;
    } catch (e, stackTrace) {
      if (e is SignInException) rethrow;

      throw SignInException(
        message: 'Google sign-in failed',
        provider: 'google',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Sign in with Facebook
  Future<UserLoginResponseEntity> signInWithFacebook() async {
    try {
      logInfo('🔑 Starting Facebook sign-in...');

      final LoginResult loginResult = await FacebookAuth.instance.login();

      if (loginResult.status != LoginStatus.success) {
        throw SignInException(
          message: 'Facebook sign-in failed: ${loginResult.status}',
          provider: 'facebook',
          code: 'FACEBOOK_LOGIN_FAILED',
        );
      }

      if (loginResult.accessToken == null) {
        throw SignInException(
          message: 'Facebook access token is null',
          provider: 'facebook',
          code: 'NULL_ACCESS_TOKEN',
        );
      }

      final OAuthCredential facebookCredential =
          FacebookAuthProvider.credential(loginResult.accessToken!.tokenString);

      final UserCredential userCredential =
          await _firebaseAuth.signInWithCredential(facebookCredential);

      if (userCredential.user == null) {
        throw SignInException(
          message: 'Firebase returned null user',
          provider: 'facebook',
          code: 'NULL_USER',
        );
      }

      final user = userCredential.user!;
      logInfo('✅ Firebase sign-in successful: ${user.uid}');

      final loginRequest = LoginRequestEntity(
        avatar: user.photoURL,
        name: user.displayName,
        email: user.email,
        open_id: user.uid,
        type: 3, // Facebook
      );

      final result = await _loginToBackend(loginRequest);
      await _updateFirestoreProfile(result.data!, loginRequest.email);

      logSuccess('🎉 Facebook sign-in complete for: ${result.data!.name}');
      return result;
    } catch (e, stackTrace) {
      if (e is SignInException) rethrow;

      throw SignInException(
        message: 'Facebook sign-in failed',
        provider: 'facebook',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Sign in with Apple
  Future<UserLoginResponseEntity> signInWithApple() async {
    try {
      logInfo('🔑 Starting Apple sign-in...');

      final appleProvider = AppleAuthProvider();
      final UserCredential userCredential =
          await _firebaseAuth.signInWithProvider(appleProvider);

      if (userCredential.user == null) {
        throw SignInException(
          message: 'Firebase returned null user',
          provider: 'apple',
          code: 'NULL_USER',
        );
      }

      final user = userCredential.user!;
      logInfo('✅ Firebase sign-in successful: ${user.uid}');

      final loginRequest = LoginRequestEntity(
        avatar: '${SERVER_API_URL}uploads/default.png',
        name: user.displayName ?? 'apple_user',
        email: user.email ?? 'apple@email.com',
        open_id: user.uid,
        type: 4, // Apple
      );

      final result = await _loginToBackend(loginRequest);
      await _updateFirestoreProfile(result.data!, loginRequest.email);

      logSuccess('🎉 Apple sign-in complete for: ${result.data!.name}');
      return result;
    } catch (e, stackTrace) {
      if (e is SignInException) rethrow;

      throw SignInException(
        message: 'Apple sign-in failed',
        provider: 'apple',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  // ==================== EMAIL/PASSWORD ====================

  /// Sign in with email and password
  Future<UserLoginResponseEntity> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      logInfo('🔑 Starting email sign-in for: $email');

      final UserCredential credential =
          await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw SignInException(
          message: 'User not found',
          provider: 'email',
          code: 'NULL_USER',
        );
      }

      final user = credential.user!;

      if (!user.emailVerified) {
        throw EmailVerificationException(
          message: 'Please verify your email address before signing in',
          code: 'EMAIL_NOT_VERIFIED',
        );
      }

      logInfo('✅ Firebase sign-in successful: ${user.uid}');

      final loginRequest = LoginRequestEntity(
        avatar: user.photoURL,
        name: user.displayName,
        email: user.email,
        open_id: user.uid,
        type: 1, // Email
      );

      final result = await _loginToBackend(loginRequest);
      await _updateFirestoreProfile(result.data!, loginRequest.email);

      logSuccess('🎉 Email sign-in complete for: ${result.data!.name}');
      return result;
    } on FirebaseAuthException catch (e, stackTrace) {
      throw AuthExceptionHandler.fromFirebaseAuthError(e,
          provider: 'email', stackTrace: stackTrace);
    } catch (e, stackTrace) {
      if (e is AuthException) rethrow;

      throw SignInException(
        message: 'Email sign-in failed',
        provider: 'email',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Sign up with email and password
  Future<void> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      logInfo('📝 Starting email sign-up for: $email');

      final UserCredential credential =
          await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw SignUpException(
          message: 'Failed to create user account',
          code: 'NULL_USER',
        );
      }

      if (displayName != null && displayName.isNotEmpty) {
        await credential.user!.updateDisplayName(displayName);
      }

      await credential.user!.sendEmailVerification();

      logSuccess(
          '✅ Email sign-up complete. Verification email sent to: $email');
    } on FirebaseAuthException catch (e, stackTrace) {
      throw AuthExceptionHandler.fromFirebaseAuthError(e,
          stackTrace: stackTrace);
    } catch (e, stackTrace) {
      if (e is AuthException) rethrow;

      throw SignUpException(
        message: 'Email sign-up failed',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Send password reset email
  Future<void> sendPasswordReset({required String email}) async {
    try {
      logInfo('🔐 Sending password reset email to: $email');

      await _firebaseAuth.sendPasswordResetEmail(email: email);

      logSuccess('✅ Password reset email sent to: $email');
    } on FirebaseAuthException catch (e, stackTrace) {
      throw AuthExceptionHandler.fromFirebaseAuthError(e,
          stackTrace: stackTrace);
    } catch (e, stackTrace) {
      throw PasswordResetException(
        message: 'Failed to send password reset email',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Send email verification
  Future<void> sendEmailVerification() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw EmailVerificationException(
          message: 'No user is currently signed in',
          code: 'NO_CURRENT_USER',
        );
      }

      logInfo('📧 Sending verification email to: ${user.email}');

      await user.sendEmailVerification();

      logSuccess('✅ Verification email sent to: ${user.email}');
    } on FirebaseAuthException catch (e, stackTrace) {
      throw AuthExceptionHandler.fromFirebaseAuthError(e,
          stackTrace: stackTrace);
    } catch (e, stackTrace) {
      if (e is AuthException) rethrow;

      throw EmailVerificationException(
        message: 'Failed to send verification email',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  // ==================== PHONE AUTHENTICATION ====================

  /// Sign in with phone number and SMS code
  Future<UserLoginResponseEntity> signInWithPhone({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      logInfo('📱 Starting phone sign-in with verification ID');

      final phoneAuthCredential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      final UserCredential userCredential =
          await _firebaseAuth.signInWithCredential(phoneAuthCredential);

      if (userCredential.user == null) {
        throw PhoneAuthException(
          message: 'Firebase returned null user',
          code: 'NULL_USER',
        );
      }

      final user = userCredential.user!;
      logInfo('✅ Firebase phone sign-in successful: ${user.uid}');

      final loginRequest = LoginRequestEntity(
        avatar: '${SERVER_API_URL}uploads/default.png',
        name: user.displayName ?? 'phone_user',
        email: user.phoneNumber ?? 'phone@email.com',
        open_id: user.uid,
        type: 5, // Phone
      );

      final result = await _loginToBackend(loginRequest);
      await _updateFirestoreProfile(result.data!, loginRequest.email);

      logSuccess('🎉 Phone sign-in complete for: ${result.data!.name}');
      return result;
    } on FirebaseAuthException catch (e, stackTrace) {
      throw AuthExceptionHandler.fromFirebaseAuthError(e,
          stackTrace: stackTrace);
    } catch (e, stackTrace) {
      if (e is AuthException) rethrow;

      throw PhoneAuthException(
        message: 'Phone sign-in failed',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  // ==================== PROFILE MANAGEMENT ====================

  /// Refresh user profile from backend
  Future<UserLoginResponseEntity> refreshProfile() async {
    try {
      logInfo('🔄 Refreshing user profile...');

      final result = await UserAPI.get_profile();

      if (result.code != 0) {
        throw TokenRefreshException(
          message: result.msg ?? 'Failed to refresh profile',
          code: 'API_ERROR',
        );
      }

      await UserStore.to.saveProfile(result.data!);

      logSuccess('✅ Profile refreshed for: ${result.data!.name}');
      return result;
    } catch (e, stackTrace) {
      if (e is AuthException) rethrow;

      throw TokenRefreshException(
        message: 'Failed to refresh profile',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Update user profile
  Future<BaseResponseEntity> updateProfile({
    required LoginRequestEntity profileData,
  }) async {
    try {
      logInfo('✏️ Updating user profile...');

      final result = await UserAPI.UpdateProfile(params: profileData);

      if (result.code != 0) {
        throw ProfileUpdateException(
          message: result.msg ?? 'Failed to update profile',
          code: 'API_ERROR',
        );
      }

      logSuccess('✅ Profile updated successfully');
      return result;
    } catch (e, stackTrace) {
      if (e is AuthException) rethrow;

      throw ProfileUpdateException(
        message: 'Failed to update profile',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  // ==================== SIGN OUT ====================

  /// Sign out current user
  Future<void> signOut() async {
    try {
      logInfo('👋 Signing out...');

      await Future.wait([
        _firebaseAuth.signOut(),
        _googleSignIn.signOut(),
        FacebookAuth.instance.logOut(),
      ]);

      logSuccess('✅ Sign out complete');
    } catch (e, stackTrace) {
      throw SignOutException(
        message: 'Sign out failed',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  // ==================== HELPER METHODS ====================

  /// Call backend login API and save profile
  Future<UserLoginResponseEntity> _loginToBackend(
      LoginRequestEntity request) async {
    logDebug('📡 Calling backend login API...');

    final result = await UserAPI.Login(params: request);

    if (result.code != 0) {
      throw SignInException(
        message: result.msg ?? 'Backend login failed',
        code: 'API_ERROR',
        context: {'api_code': result.code},
      );
    }

    await UserStore.to.saveProfile(result.data!);
    logDebug('💾 Profile saved to local storage');

    return result;
  }

  /// Update user profile in Firestore for search functionality
  Future<void> _updateFirestoreProfile(
    UserItem userData,
    String? email,
  ) async {
    try {
      logDebug('📝 Updating Firestore user_profiles...');

      final token = userData.token!;
      final name = userData.name ?? '';
      final searchName = name.toLowerCase().trim();

      await _firestore.collection('user_profiles').doc(token).set({
        'token': token,
        'name': name,
        'avatar': userData.avatar ?? '',
        'email': email ?? '',
        'online': 1,
        'search_name': searchName,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      logDebug('✅ Firestore profile updated for token: $token');
    } catch (e) {
      logError('⚠️ Failed to update Firestore profile: $e');
    }
  }

  /// Get current Firebase user
  User? get currentUser => _firebaseAuth.currentUser;

  /// Check if user is signed in
  bool get isSignedIn => _firebaseAuth.currentUser != null;

  /// Listen to auth state changes
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();
}
