import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' show Platform;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:github/github.dart';
import 'package:flutter_web_auth/flutter_web_auth.dart';

// Import the environment file
// Note: This import might show an error if the file doesn't exist yet,
// but it will work when the file is created according to the setup instructions
import '../../../../core/config/env.dart';

/// Service for authentication in GitHub through OAuth
class GitHubAuthService {
  /// GitHub OAuth API URL
  static const String _githubAuthUrl =
      'https://github.com/login/oauth/authorize';

  /// GitHub OAuth Token URL
  static const String _githubTokenUrl =
      'https://github.com/login/oauth/access_token';

  /// GitHub API URL
  static const String _githubApiUrl = 'https://api.github.com';

  /// Required permissions from the user
  static const List<String> _scopes = [
    'repo', // access to repositories
    'user', // access to user information
    'read:user', // reading user data
    'user:email', // access to email
  ];

  /// URL redirect after authorization
  static const String _redirectUri = 'devmate://callback';

  /// ID your application registered in GitHub OAuth
  static const String _clientId = 'Ov23li60qGcqO1UpacHF';

  /// Secret of your application registered in GitHub OAuth
  static const String _clientSecret =
      'acf9b956d36b17ef0ce107f067d72f40d0170e0b';

  final _storage = const FlutterSecureStorage();
  final _github = GitHub();

  /// Getting the token from local storage
  Future<String?> getAccessToken() async {
    return await _storage.read(key: _redirectUri);
  }

  /// Saving the token to local storage
  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _redirectUri, value: token);
  }

  /// Deleting the token from local storage
  Future<void> deleteAccessToken() async {
    await _storage.delete(key: _redirectUri);
  }

  /// Checking if the user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await getAccessToken();
    return token != null;
  }

  /// Generating a random string for the state parameter
  String _generateRandomState() {
    final random = Random.secure();
    final values = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Url.encode(values).replaceAll('=', '');
  }

  /// Initiates the GitHub authentication process
  Future<void> signInWithGitHub() async {
    try {
      final state = _generateRandomState();

      // Use environment variables when available, fall back to constants
      final url = Uri.parse(_githubAuthUrl).replace(
        queryParameters: {
          'client_id': _clientId,
          'redirect_uri': _redirectUri,
          'scope': _scopes.join(' '), // GitHub expects spaces between scopes
          'state': state,
          'allow_signup': 'true', // Allowing new user registration
        },
      );

      if (kDebugMode) {
        print('GitHub Auth URL: ${url.toString()}');
      }

      final result = await FlutterWebAuth.authenticate(
        url: url.toString(),
        callbackUrlScheme: 'devmate',
      );

      if (kDebugMode) {
        print('GitHub Auth Result: $result');
      }

      final uri = Uri.parse(result);
      final code = uri.queryParameters['code'];
      final returnedState = uri.queryParameters['state'];

      if (code == null) {
        throw Exception('Authorization code not found');
      }

      if (returnedState != state) {
        throw Exception('State parameter mismatch');
      }

      final token = await _getAccessToken(code);
      await saveAccessToken(token);
    } catch (e) {
      debugPrint('Error during authentication: $e');
      rethrow;
    }
  }

  /// Getting access token by authorization code
  Future<String> _getAccessToken(String code) async {
    try {
      final response = await http.post(
        Uri.https('github.com', '/login/oauth/access_token'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'client_id': _clientId,
          'client_secret': _clientSecret,
          'code': code,
          'redirect_uri': _redirectUri,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to get access token: ${response.body}');
      }

      final data = jsonDecode(response.body);
      return data['access_token'] as String;
    } catch (e) {
      debugPrint('Error getting the token: $e');
      rethrow;
    }
  }

  /// Getting user information
  Future<Map<String, dynamic>?> getUserInfo() async {
    final token = await getAccessToken();
    if (token == null) return null;

    try {
      _github.auth = Authentication.withToken(token);
      final response = await _github.users.getCurrentUser();
      return {
        'id': response.id,
        'login': response.login,
        'name': response.name,
        'email': response.email,
        'avatar_url': response.avatarUrl,
      };
    } catch (e) {
      throw Exception('Failed to get user info: $e');
    }
  }

  /// Opening the GitHub OAuth applications settings page
  Future<void> openGitHubSettings() async {
    const url = 'https://github.com/settings/applications';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Initiates the GitHub authentication process in the system browser
  /// Used for testing, if the built-in WebView does not work
  Future<void> signInWithGitHubExternalBrowser() async {
    try {
      final state = _generateRandomState();
      final url = Uri.parse('https://github.com/login/oauth/authorize').replace(
        queryParameters: {
          'client_id': _clientId,
          'redirect_uri': _redirectUri,
          'scope': _scopes.join(' '),
          'state': state,
          'allow_signup': 'true',
        },
      );

      if (kDebugMode) {
        print('GitHub Auth URL (External Browser): ${url.toString()}');
      }

      // Opening the URL in the system browser
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);

        // Here we need to add processing of the return through deep link
        // (this is implemented separately in the application through listening for incoming links)

        if (kDebugMode) {
          print('GitHub Auth: URL opened in the system browser');
          print(
            'To complete the authorization, you need to add processing of deep links',
          );
        }
      } else {
        throw Exception('Failed to open the URL in the browser');
      }
    } catch (e) {
      debugPrint('Error during authentication through the system browser: $e');
      rethrow;
    }
  }

  /// Initiates the GitHub authentication process, using WebView
  /// This method must be called with a callback function that will
  /// handle the authorization result
  Future<String> getAuthorizationUrl() async {
    final state = _generateRandomState();
    final url = Uri.parse('https://github.com/login/oauth/authorize').replace(
      queryParameters: {
        'client_id': _clientId,
        'redirect_uri': _redirectUri,
        'scope': _scopes.join(' '),
        'state': state,
        'allow_signup': 'true',
      },
    );

    if (kDebugMode) {
      print('GitHub Auth URL for WebView: ${url.toString()}');
    }

    // Saving state for subsequent verification
    await _storage.write(key: 'github_auth_state', value: state);

    return url.toString();
  }

  /// Handles the authorization result after redirect
  Future<bool> handleAuthorizationResponse(String redirectUrl) async {
    try {
      if (kDebugMode) {
        print('Processing redirect: $redirectUrl');
      }

      final uri = Uri.parse(redirectUrl);
      final code = uri.queryParameters['code'];
      final returnedState = uri.queryParameters['state'];
      final savedState = await _storage.read(key: 'github_auth_state');

      if (code == null) {
        throw Exception('Authorization code not found');
      }

      if (returnedState != savedState) {
        throw Exception('State parameter mismatch');
      }

      final token = await _getAccessToken(code);
      await saveAccessToken(token);

      if (kDebugMode) {
        print(
          'GitHub authentication successful! Token received: ${token.substring(0, 5)}...',
        );

        // Check if we can get user information
        try {
          final userInfo = await getUserInfo();
          print(
            'User information: ${userInfo != null ? 'received' : 'not received'}',
          );
          if (userInfo != null) {
            print('Login: ${userInfo['login']}');
            print('Name: ${userInfo['name']}');
            print(
              'Public repositories: ${userInfo['public_repos'] ?? 'no data'}',
            );
          }
        } catch (e) {
          print('Error getting user information: $e');
        }
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error processing the authorization result: $e');
      }
      return false;
    } finally {
      // Deleting the saved state
      await _storage.delete(key: 'github_auth_state');
    }
  }
}
