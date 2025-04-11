import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'dart:async';
import '../../profile/domain/entities/user.dart' as app_user;
import 'package:hive_flutter/hive_flutter.dart';
import '../../../main.dart';
import '../data/mock/mock_user.dart';

/// Provider for managing authentication state
final authProvider = StreamProvider<User?>((ref) {
  // Get the current app mode
  final mode = ref.watch(appModeProvider);

  if (kDebugMode) {
    print('Initializing authProvider in mode: $mode');
  }

  // If in offline mode, use local authentication simulation
  if (mode == AppMode.offline) {
    return OfflineAuthService().authStateChanges();
  }

  // Otherwise, use Firebase Auth
  return FirebaseAuth.instance.authStateChanges().map((user) {
    if (kDebugMode) {
      print(
        'Authentication state change: ${user?.email ?? 'not authenticated'}',
      );
    }
    return user;
  });
});

/// Interface for authentication services
abstract class BaseAuthService {
  /// Getting the current user
  User? getCurrentUser();

  /// Registering a user with email and password
  Future<User?> registerWithEmailAndPassword(String email, String password);

  /// Signing in a user with email and password
  Future<User?> signInWithEmailAndPassword(String email, String password);

  /// Signingnout a user
  Future<void> signOut();

  /// Getting the stream of authentication state changes
  Stream<User?> authStateChanges();
}

/// Service for working with FirebaseAuth
class FirebaseAuthService implements BaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Stream<User?> authStateChanges() {
    return _auth.authStateChanges();
  }

  @override
  Future<User?> registerWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      if (kDebugMode) {
        print('[Firebase] Attempting to register with email: $email');
        _checkConnection();
      }

      // Check if the email is valid
      if (!_isEmailValid(email)) {
        throw 'Invalid email format';
      }

      // Check if the password is strong
      if (password.length < 6) {
        throw 'Password must be at least 6 characters long';
      }

      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = result.user;

      if (kDebugMode) {
        print('[Firebase] Successful registration: ${user?.email}');
        print('[Firebase] UID: ${user?.uid}');
      }

      return user;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('[Firebase] Registration error: ${e.code}');
        print('[Firebase] Message: ${e.message}');
        if (e.code == 'internal-error') {
          print('[Firebase] Details of internal-error: ${e.stackTrace}');
          _checkConnection();
        }
      }

      String errorMessage;
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = 'This email is already in use by another account';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email format';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Registration with email and password is not allowed';
          break;
        case 'weak-password':
          errorMessage = 'Password is too simple';
          break;
        case 'internal-error':
          errorMessage =
              'Internal Firebase error. Check your internet connection and try again later.';
          break;
        default:
          errorMessage = 'An error occurred: ${e.message}';
      }

      throw errorMessage;
    } catch (e) {
      if (kDebugMode) {
        print('[Firebase] Unknown registration error: $e');
      }
      throw 'An unknown error occurred during registration';
    }
  }

  @override
  Future<User?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      if (kDebugMode) {
        print('[Firebase] Attempting to sign in with email: $email');
        _checkConnection();
      }

      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = result.user;

      if (kDebugMode) {
        print('[Firebase] Successful sign in: ${user?.email}');
        print('[Firebase] UID: ${user?.uid}');
      }

      return user;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('[Firebase] Sign in error: ${e.code}');
        print('[Firebase] Message: ${e.message}');
        if (e.code == 'internal-error') {
          print('[Firebase] Details of internal-error: ${e.stackTrace}');
          _checkConnection();
        }
      }

      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'User with this email not found';
          break;
        case 'wrong-password':
          errorMessage = 'Wrong password';
          break;
        case 'user-disabled':
          errorMessage = 'This account has been disabled';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email format';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many login attempts. Please try again later';
          break;
        case 'internal-error':
          errorMessage =
              'Internal Firebase error. Check your internet connection and try again later.';
          break;
        default:
          errorMessage = 'An error occurred: ${e.message}';
      }

      throw errorMessage;
    } catch (e) {
      if (kDebugMode) {
        print('[Firebase] Unknown sign in error: $e');
      }
      throw 'An unknown error occurred during sign in';
    }
  }

  @override
  Future<void> signOut() async {
    try {
      if (kDebugMode) {
        print('[Firebase] Signing out');
      }

      await _auth.signOut();

      if (kDebugMode) {
        print('[Firebase] Sign out successful');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[Firebase] Sign out error: $e');
      }
      throw 'An error occurred during sign out';
    }
  }

  @override
  User? getCurrentUser() {
    final user = _auth.currentUser;
    if (kDebugMode) {
      print('[Firebase] Current user: ${user?.email ?? 'not authenticated'}');
    }
    return user;
  }

  /// Checking for internet connection
  Future<void> _checkConnection() async {
    try {
      final result = await InternetAddress.lookup('firebase.google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        print('[Firebase] Connection to Firebase: Available');
      }
    } on SocketException catch (_) {
      print('[Firebase] Connection to Firebase: Not available');
    }
  }

  /// Checking for valid email
  bool _isEmailValid(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}

/// Service for simulating authentication in offline mode
class OfflineAuthService implements BaseAuthService {
  // Users storage using Hive
  final Box<app_user.User> _usersBox = Hive.box<app_user.User>('users');

  // Controller for simulating authentication state stream
  final StreamController<User?> _authStateController =
      StreamController<User?>.broadcast();

  // Current user
  MockUser? _currentUser;

  // Checking for valid email
  bool _isEmailValid(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  @override
  User? getCurrentUser() {
    return _currentUser;
  }

  @override
  Stream<User?> authStateChanges() {
    return _authStateController.stream;
  }

  @override
  Future<User?> registerWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      if (kDebugMode) {
        print('[Offline] Attempting to register with email: $email');
      }

      // Checking for valid email
      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
        throw 'Invalid email format';
      }

      // Checking for password strength
      if (password.length < 6) {
        throw 'Password must contain at least 6 characters';
      }

      // Checking if a user with this email already exists
      final existingUsers =
          _usersBox.values.where((user) => user.email == email).toList();
      if (existingUsers.isNotEmpty) {
        throw 'This email is already in use by another account';
      }

      // Creating a new user
      final newUser = app_user.User(
        id: 'offline-${DateTime.now().millisecondsSinceEpoch}',
        email: email,
        displayName: email.split('@')[0],
      );

      // Saving the user to Hive
      await _usersBox.add(newUser);

      // Creating a mock-user for simulating Firebase User
      _currentUser = MockUser(
        uid: newUser.id,
        email: newUser.email,
        displayName: newUser.displayName,
      );

      // Notifying subscribers about the state change
      _authStateController.add(_currentUser);

      if (kDebugMode) {
        print('[Offline] Successful registration: ${_currentUser?.email}');
        print('[Offline] UID: ${_currentUser?.uid}');
      }

      return _currentUser;
    } catch (e) {
      if (kDebugMode) {
        print('[Offline] Registration error: $e');
      }
      throw e.toString();
    }
  }

  @override
  Future<User?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      if (kDebugMode) {
        print('[Offline] Attempting to sign in with email: $email');
      }

      // Searching for a user with this email
      final foundUsers =
          _usersBox.values.where((user) => user.email == email).toList();

      if (foundUsers.isEmpty) {
        throw 'User with this email not found';
      }

      // In a real application, here would be a password check

      // Creating a mock-user for simulating Firebase User
      _currentUser = MockUser(
        uid: foundUsers[0].id,
        email: foundUsers[0].email,
        displayName: foundUsers[0].displayName,
      );

      // Notifying subscribers about the state change
      _authStateController.add(_currentUser);

      if (kDebugMode) {
        print('[Offline] Successful sign in: ${_currentUser?.email}');
        print('[Offline] UID: ${_currentUser?.uid}');
      }

      return _currentUser;
    } catch (e) {
      if (kDebugMode) {
        print('[Offline] Sign in error: $e');
      }
      throw e.toString();
    }
  }

  @override
  Future<void> signOut() async {
    try {
      if (kDebugMode) {
        print('[Offline] Signing out');
      }

      _currentUser = null;

      // Notifying subscribers about the state change
      _authStateController.add(null);

      if (kDebugMode) {
        print('[Offline] Sign out successful');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[Offline] Sign out error: $e');
      }
      throw 'An error occurred during sign out';
    }
  }

  // Closing the controller when the service is destroyed
  void dispose() {
    _authStateController.close();
  }
}

/// Provider for the authentication service
final authServiceProvider = Provider<BaseAuthService>((ref) {
  final mode = ref.watch(appModeProvider);

  if (mode == AppMode.offline) {
    return OfflineAuthService();
  }

  return FirebaseAuthService();
});
