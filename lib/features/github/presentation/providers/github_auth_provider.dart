import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/github_auth_service.dart';

/// Provider for checking the GitHub authentication status
///
/// For correct OAuth authorization:
/// 1. On iOS, the Info.plist must be configured with Universal Links
/// 2. On GitHub, the OAuth application settings must have a correct redirect URL
/// 3. Use the debug mode with messages about the authorization process
final githubAuthProvider = Provider<Future<bool>>((ref) async {
  final authService = GitHubAuthService();
  final isAuth = await authService.isAuthenticated();
  if (kDebugMode) {
    print('GitHubAuthProvider: Checking the authentication status: $isAuth');
  }
  return isAuth;
});

/// Provider for user information from GitHub
final githubUserInfoProvider = FutureProvider<Map<String, dynamic>?>((
  ref,
) async {
  final authService = GitHubAuthService();
  final isAuthenticated = await ref.watch(githubAuthProvider);
  if (kDebugMode) {
    print('GitHubUserInfoProvider: isAuthenticated = $isAuthenticated');
  }

  if (!isAuthenticated) return null;

  final userInfo = await authService.getUserInfo();
  if (kDebugMode) {
    if (userInfo != null) {
      print('GitHubUserInfoProvider: User data received: ${userInfo['login']}');
    } else {
      print('GitHubUserInfoProvider: Failed to get user data');
    }
  }
  return userInfo;
});

/// Class representing the authentication state
class GitHubAuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? errorMessage;

  const GitHubAuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.errorMessage,
  });

  GitHubAuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    String? errorMessage,
  }) {
    return GitHubAuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

/// Notifier for managing the authentication state
class GitHubAuthStateNotifier extends StateNotifier<GitHubAuthState> {
  final GitHubAuthService _authService = GitHubAuthService();

  GitHubAuthStateNotifier() : super(const GitHubAuthState()) {
    _initializeAuthState();
  }

  Future<void> _initializeAuthState() async {
    final isAuthenticated = await _authService.isAuthenticated();
    state = GitHubAuthState(isAuthenticated: isAuthenticated);
    if (kDebugMode) {
      print(
        'GitHubAuthStateNotifier: Initialization, authentication status: ${state.isAuthenticated}',
      );
    }
  }

  /// Method for setting the authentication state
  void setAuthenticated(bool value) {
    if (kDebugMode) {
      print('GitHubAuthStateNotifier: setAuthenticated($value)');
    }
    state = state.copyWith(isAuthenticated: value);
  }

  /// Method for setting the loading state
  void setLoading(bool value) {
    if (kDebugMode) {
      print('GitHubAuthStateNotifier: setLoading($value)');
    }
    state = state.copyWith(isLoading: value);
  }

  /// Method for setting the error message
  void setError(String? message) {
    if (kDebugMode && message != null) {
      print('GitHubAuthStateNotifier: setError($message)');
    }
    state = state.copyWith(errorMessage: message);
  }

  /// Method for performing authentication
  Future<bool> authenticate() async {
    if (kDebugMode) {
      print('GitHubAuthStateNotifier: Starting the authentication process');
    }

    setLoading(true);
    setError(null);

    try {
      await _authService.signInWithGitHub();
      final isAuthenticated = await _authService.isAuthenticated();

      if (kDebugMode) {
        print(
          'GitHubAuthStateNotifier: Authentication result: $isAuthenticated',
        );
      }

      setAuthenticated(isAuthenticated);

      if (!isAuthenticated) {
        if (kDebugMode) {
          print(
            'GitHubAuthStateNotifier: Authorization canceled by the user or not completed',
          );
        }
      }

      return isAuthenticated;
    } catch (e) {
      if (kDebugMode) {
        print('GitHubAuthStateNotifier: Authentication error: $e');
      }

      String errorMsg;
      final errorStr = e.toString().toLowerCase();

      if (errorStr.contains('canceled') || errorStr.contains('cancel')) {
        errorMsg = 'Authorization was canceled';
      } else if (errorStr.contains('redirect') || errorStr.contains('url')) {
        errorMsg = 'Redirect error. Check the application settings';
        if (kDebugMode) {
          print(
            'Check the URL scheme settings in Info.plist and GitHub OAuth application settings',
          );
        }
      } else if (errorStr.contains('timeout') || errorStr.contains('time')) {
        errorMsg = 'Timeout exceeded. Check the internet connection';
      } else {
        errorMsg = 'Authentication error';
      }

      setError(errorMsg);
      return false;
    } finally {
      setLoading(false);
    }
  }

  /// Method for logging out of the account
  Future<void> logout() async {
    if (kDebugMode) {
      print('GitHubAuthStateNotifier: Logging out of the account');
    }

    setLoading(true);

    try {
      await _authService.deleteAccessToken();
      setAuthenticated(false);

      if (kDebugMode) {
        print('GitHubAuthStateNotifier: Logout completed successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('GitHubAuthStateNotifier: Error logging out of the account: $e');
      }

      setError('Failed to logout of the account: ${e.toString()}');
    } finally {
      setLoading(false);
    }
  }
}

/// Provider for the authentication state
final githubAuthStateProvider =
    StateNotifierProvider<GitHubAuthStateNotifier, GitHubAuthState>((ref) {
      return GitHubAuthStateNotifier();
    });

class GitHubAuthProvider extends ChangeNotifier {
  final GitHubAuthService _authService = GitHubAuthService();

  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;

  Future<void> checkAuthStatus() async {
    _isAuthenticated = await _authService.isAuthenticated();
    notifyListeners();
  }

  Future<void> signIn() async {
    try {
      await _authService.signInWithGitHub();
      _isAuthenticated = true;
      notifyListeners();
    } catch (e) {
      _isAuthenticated = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _authService.deleteAccessToken();
      _isAuthenticated = false;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getUserInfo() async {
    return await _authService.getUserInfo();
  }
}
