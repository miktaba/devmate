import 'dart:convert';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;

import '../../data/services/github_auth_service.dart';
import '../providers/github_auth_provider.dart';
import '../../../../core/config/env.dart'; // Import environment variables

/// Page for GitHub authentication
class GitHubAuthPage extends ConsumerStatefulWidget {
  const GitHubAuthPage({Key? key}) : super(key: key);

  @override
  ConsumerState<GitHubAuthPage> createState() => _GitHubAuthPageState();
}

class _GitHubAuthPageState extends ConsumerState<GitHubAuthPage> {
  bool _isLoading = false;
  String? _errorMessage;
  int _retryCount = 0;
  final GitHubAuthService _authService = GitHubAuthService();
  bool _showWebView = false;
  String _authUrl = '';
  final WebViewController _webViewController = WebViewController();

  @override
  Widget build(BuildContext context) {
    if (_showWebView) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: const Text('GitHub authentication'),
          leading: CupertinoButton(
            padding: EdgeInsets.zero,
            child: const Text('Cancel'),
            onPressed: () {
              setState(() {
                _showWebView = false;
              });
            },
          ),
        ),
        child: SafeArea(child: WebViewWidget(controller: _webViewController)),
      );
    }

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('GitHub connection'),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // GitHub logo
              const Center(
                child: Icon(
                  CupertinoIcons.globe,
                  size: 72,
                  color: CupertinoColors.activeBlue,
                ),
              ),
              const SizedBox(height: 24),

              // Title and description
              const Text(
                'GitHub authentication',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Connect your GitHub account to access repositories '
                'and manage tasks. We only request the necessary '
                'permissions to work with your repositories.',
                style: TextStyle(
                  fontSize: 16,
                  color: CupertinoColors.systemGrey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Loading indicator or authentication button
              if (_isLoading)
                const Center(child: CupertinoActivityIndicator())
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CupertinoButton.filled(
                      onPressed: _authenticate,
                      child: const Text('Authenticate via GitHub'),
                    ),
                    const SizedBox(height: 16),
                    // Debug buttons for testing different authentication methods
                    if (kDebugMode) ...[
                      // Button to open in system browser
                      CupertinoButton(
                        color: CupertinoColors.systemGreen,
                        onPressed: _authenticateWithExternalBrowser,
                        child: const Text('Open in system browser'),
                      ),
                      const SizedBox(height: 8),
                      // Button to open in embedded WebView
                      CupertinoButton(
                        color: CupertinoColors.systemOrange,
                        onPressed: _authenticateWithWebView,
                        child: const Text('Open in WebView'),
                      ),
                      const SizedBox(height: 8),
                    ],
                    CupertinoButton(
                      onPressed: () => context.pop(),
                      child: const Text('Later'),
                    ),
                  ],
                ),

              // Display error if it exists
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: CupertinoColors.systemRed.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: CupertinoColors.destructiveRed,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (_retryCount > 0) ...[
                        const SizedBox(height: 8),
                        const Text(
                          'Try to check the URL scheme and application settings.',
                          style: TextStyle(
                            fontSize: 12,
                            color: CupertinoColors.systemGrey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Information about security
              const Text(
                'All data is stored only on your device. '
                'You can revoke access to your account at any time '
                'in GitHub settings.',
                style: TextStyle(
                  fontSize: 12,
                  color: CupertinoColors.systemGrey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Link to GitHub settings
              CupertinoButton(
                padding: EdgeInsets.zero,
                child: const Text(
                  'GitHub access management',
                  style: TextStyle(fontSize: 12),
                ),
                onPressed: () {
                  // Open GitHub settings in browser
                  launchUrl(
                    Uri.parse('https://github.com/settings/applications'),
                  );
                },
              ),

              // Debug information for developer
              if (kDebugMode) ...[
                const SizedBox(height: 16),
                const Text(
                  'Debug information:',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                ),
                const Text(
                  'URL scheme: devmate\nCallback URL: devmate://github-auth-callback',
                  style: TextStyle(fontSize: 10),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Method for authentication via system browser (for debugging)
  Future<void> _authenticateWithExternalBrowser() async {
    if (kDebugMode) {
      print('GitHubAuthPage: Start authentication via system browser');
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.signInWithGitHubExternalBrowser();
      // There is no processing of the return from the browser here
      if (kDebugMode) {
        print('Opened in system browser. Deep link processing required.');
      }
    } catch (e) {
      if (kDebugMode) {
        print('GitHubAuthPage: Error opening system browser: $e');
      }

      setState(() {
        _errorMessage = 'Error opening browser: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Method for authentication via embedded WebView
  Future<void> _authenticateWithWebView() async {
    if (kDebugMode) {
      print('GitHubAuthPage: Start authentication via WebView');
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Create request parameters manually
      final random = Random.secure();
      final values = List<int>.generate(32, (i) => random.nextInt(256));
      final state = base64Url.encode(values).replaceAll('=', '');

      // Use the environment variables from Env class
      final clientId = Env.githubClientId;
      final redirectUri = Env.githubRedirectUri;
      final scopes = Env.githubScopes;

      final url = Uri.parse(Env.githubAuthUrl).replace(
        queryParameters: {
          'client_id': clientId,
          'redirect_uri': redirectUri,
          'scope': scopes.join(' '),
          'state': state,
          'allow_signup': 'true',
        },
      );

      if (kDebugMode) {
        print('GitHub Auth URL (WebView): ${url.toString()}');
      }

      _webViewController.setJavaScriptMode(JavaScriptMode.unrestricted);
      _webViewController.setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            if (kDebugMode) {
              print('WebView navigation: ${request.url}');
            }

            // Processing of redirect
            if (request.url.startsWith(redirectUri)) {
              if (kDebugMode) {
                print('Detected redirect to callback URL: ${request.url}');
              }

              // Getting code and state from URL
              final uri = Uri.parse(request.url);
              final code = uri.queryParameters['code'];
              final returnedState = uri.queryParameters['state'];

              if (code != null && returnedState == state) {
                // Closing WebView and continuing authentication
                setState(() {
                  _showWebView = false;
                });

                // Getting token and completing authentication
                _completeAuthentication(code);
                return NavigationDecision.prevent;
              }
            }
            return NavigationDecision.navigate;
          },
        ),
      );

      // Loading URL into WebView
      await _webViewController.loadRequest(url);

      // Showing WebView
      setState(() {
        _showWebView = true;
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('GitHubAuthPage: Error initializing WebView: $e');
      }

      setState(() {
        _isLoading = false;
        _errorMessage = 'Error initializing WebView: $e';
      });
    }
  }

  /// Method for completing authentication after receiving the code
  Future<void> _completeAuthentication(String code) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Getting token directly through HTTP request using environment variables
      final clientId = Env.githubClientId;
      final clientSecret = Env.githubClientSecret;
      final redirectUri = Env.githubRedirectUri;

      final response = await http.post(
        Uri.parse(Env.githubTokenUrl),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'client_id': clientId,
          'client_secret': clientSecret,
          'code': code,
          'redirect_uri': redirectUri,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to get access token: ${response.body}');
      }

      final data = jsonDecode(response.body);
      final token = data['access_token'] as String;

      // Saving token
      await _authService.saveAccessToken(token);

      // Updating authentication state
      ref.read(githubAuthStateProvider.notifier).setAuthenticated(true);

      // Trying to get user information
      try {
        final userInfo = await _authService.getUserInfo();
        if (kDebugMode && userInfo != null) {
          print('Received user information: ${userInfo['login']}');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error getting user information: $e');
        }
      }

      // Returning to the previous page with the result
      if (mounted) {
        context.pop(true);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error completing authentication: $e');
      }

      setState(() {
        _isLoading = false;
        _errorMessage = 'Error completing authentication: $e';
      });
    }
  }

  /// Method for performing authentication
  Future<void> _authenticate() async {
    if (kDebugMode) {
      print('GitHubAuthPage: Start authentication');
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Instead of direct call of flutter_web_auth, we use our WebView approach
      // similar to the method _authenticateWithWebView

      // Getting URL for authentication
      final authUrl = await _authService.getAuthorizationUrl();

      if (kDebugMode) {
        print('GitHub Auth URL for main authentication: $authUrl');
      }

      // Configuring WebView
      _webViewController.setJavaScriptMode(JavaScriptMode.unrestricted);
      _webViewController.setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            if (kDebugMode) {
              print('WebView navigation: ${request.url}');
            }

            // Processing of redirect
            if (request.url.startsWith('devmate://callback')) {
              if (kDebugMode) {
                print('Detected redirect to callback URL: ${request.url}');
              }

              // Closing WebView and processing the result
              setState(() {
                _showWebView = false;
              });

              // Processing the authentication result
              _authService.handleAuthorizationResponse(request.url).then((
                success,
              ) {
                if (success) {
                  _onAuthenticationSuccess();
                } else {
                  _onAuthenticationError('Error during authentication');
                }
              });
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );

      // Loading URL into WebView
      await _webViewController.loadRequest(Uri.parse(authUrl));

      // Showing WebView
      setState(() {
        _showWebView = true;
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('GitHubAuthPage: Error during authentication: $e');
      }

      _onAuthenticationError(e.toString());
    }
  }

  /// Method called when authentication is successful
  void _onAuthenticationSuccess() async {
    if (kDebugMode) {
      print('GitHubAuthPage: Authentication successful');
    }

    // Updating authentication state
    ref.read(githubAuthStateProvider.notifier).setAuthenticated(true);

    // Getting user information
    try {
      final userInfo = await _authService.getUserInfo();
      if (kDebugMode && userInfo != null) {
        print('Received user information: ${userInfo['login']}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user information: $e');
      }
    }

    // Returning to the previous page with the result
    if (mounted) {
      context.pop(true);
    }
  }

  /// Method called when authentication error occurs
  void _onAuthenticationError(String error) {
    _retryCount++;

    // Simplifying the error message for the user
    String errorMsg;
    final errorStr = error.toLowerCase();

    if (errorStr.contains('canceled') || errorStr.contains('cancel')) {
      errorMsg = 'Authentication canceled. Please try again.';
    } else if (errorStr.contains('error_uri') ||
        errorStr.contains('redirect')) {
      errorMsg = 'URL redirect error. Please check the application settings.';
      if (kDebugMode) {
        print('URL error: $error');
        print(
          'Please check the OAuth settings in GitHub and the URL scheme in Info.plist',
        );
      }
    } else if (errorStr.contains('timeout') || errorStr.contains('time')) {
      errorMsg = 'Timeout exceeded. Please check the connection and try again.';
    } else {
      errorMsg = 'Authentication error. Please try again later.';
      if (kDebugMode) {
        errorMsg = 'Authentication error: $error';
      }
    }

    setState(() {
      _isLoading = false;
      _errorMessage = errorMsg;
    });
  }
}
