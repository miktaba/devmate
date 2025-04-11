import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../providers/auth_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;
  String? _errorMessage;

  // Pre-filled test data (remove in release)
  final String _testEmail = "test@example.com";
  final String _testPassword = "password123";

  @override
  void initState() {
    super.initState();

    if (kDebugMode) {
      print('LoginPage initState');
      // Check current authorization status through provider
      final authState = ref.read(authProvider);
      print('Current authorization state: $authState');

      // Get current user directly through AuthService
      final authService = ref.read(authServiceProvider);
      final currentUser = authService.getCurrentUser();
      print('Current user: ${currentUser?.email ?? 'not authorized'}');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final email = _emailController.text.trim();
        final password = _passwordController.text.trim();
        final authService = ref.read(authServiceProvider);

        if (kDebugMode) {
          print('Form submission: $_isLogin, email: $email');
        }

        if (_isLogin) {
          // Login
          final user = await authService.signInWithEmailAndPassword(
            email,
            password,
          );

          if (kDebugMode) {
            print('Successful authorization: ${user?.email}');
          }
        } else {
          // Registration
          final user = await authService.registerWithEmailAndPassword(
            email,
            password,
          );

          if (kDebugMode) {
            print('Successful registration: ${user?.email}');
          }
        }

        // After successful authorization, we DO NOT redirect here,
        // but wait for authProvider state update, which is handled in the listener below
      } catch (e) {
        setState(() {
          _errorMessage = _getErrorMessage(e.toString());
        });
        if (kDebugMode) {
          print("Authentication error: $e");
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _createTestUser() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);

      if (kDebugMode) {
        print('Creating test user: $_testEmail');
      }

      await authService.registerWithEmailAndPassword(_testEmail, _testPassword);

      // If user already exists, try to login
      if (_errorMessage?.contains('already exists') == true) {
        await authService.signInWithEmailAndPassword(_testEmail, _testPassword);
      }

      if (kDebugMode) {
        print('Test user successfully created/authorized');
      }
    } catch (e) {
      setState(() {
        _errorMessage = _getErrorMessage(e.toString());
      });
      if (kDebugMode) {
        print("Test user creation error: $e");
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getErrorMessage(String error) {
    if (error.contains('wrong-password') || error.contains('user-not-found')) {
      return 'Invalid email or password';
    } else if (error.contains('weak-password')) {
      return 'Weak password. Use at least 6 characters';
    } else if (error.contains('email-already-in-use')) {
      return 'User with this email already exists';
    } else if (error.contains('invalid-email')) {
      return 'Invalid email format';
    } else if (error.contains('network-request-failed')) {
      return 'Network problem';
    } else if (error.contains('Cleartext HTTP traffic')) {
      return 'Firebase connection problem. Restart the application';
    } else if (error.contains('reCAPTCHA')) {
      // Ignore reCAPTCHA errors in test environment
      return 'reCAPTCHA error. This is normal when using an emulator';
    } else if (error.contains('internal-error')) {
      return 'Firebase internal error. Check internet connection and try again later.';
    }
    return 'An error occurred: $error';
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Enter email';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Enter password';
    }
    if (!_isLogin && value.length < 6) {
      return 'Password must contain at least 6 characters';
    }
    return null;
  }

  void _manualNavigate() {
    if (kDebugMode) {
      print('Manual redirect to home page...');
    }
    context.go('/');
  }

  void _fillTestData() {
    _emailController.text = _testEmail;
    _passwordController.text = _testPassword;
  }

  @override
  Widget build(BuildContext context) {
    // Listen for authentication state changes through StreamProvider
    ref.listen(authProvider, (previous, next) {
      if (kDebugMode) {
        print("Previous state: $previous");
        print("Current state: $next");
      }

      next.when(
        data: (user) {
          if (kDebugMode) {
            print("User: ${user?.email}");
          }

          if (user != null) {
            if (kDebugMode) {
              print("Redirecting to home page...");
            }
            Future.microtask(() => context.go('/'));
          }
        },
        loading: () {
          if (kDebugMode) {
            print("Loading authentication state...");
          }
        },
        error: (error, stack) {
          if (kDebugMode) {
            print("Authentication error: $error");
          }
          setState(() {
            _errorMessage = _getErrorMessage(error.toString());
          });
        },
      );
    });

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(_isLogin ? 'Sign In' : 'Register'),
      ),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Avatar
                    Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        color: CupertinoColors.systemGrey5,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        CupertinoIcons.person,
                        size: 40,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Email field
                    CupertinoTextFormFieldRow(
                      controller: _emailController,
                      placeholder: 'Email',
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      padding: const EdgeInsets.symmetric(
                        vertical: 5,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: CupertinoColors.systemGrey4),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      validator: _validateEmail,
                    ),
                    const SizedBox(height: 10),

                    // Password field
                    CupertinoTextFormFieldRow(
                      controller: _passwordController,
                      placeholder: 'Password',
                      obscureText: true,
                      keyboardType: TextInputType.visiblePassword,
                      padding: const EdgeInsets.symmetric(
                        vertical: 5,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: CupertinoColors.systemGrey4),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      validator: _validatePassword,
                    ),

                    // Error message
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: CupertinoColors.destructiveRed,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                    const SizedBox(height: 24),

                    // Login/Register button
                    SizedBox(
                      width: double.infinity,
                      child: CupertinoButton.filled(
                        onPressed: _isLoading ? null : _submit,
                        child:
                            _isLoading
                                ? const CupertinoActivityIndicator()
                                : Text(_isLogin ? 'Sign In' : 'Register'),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Switch between login and registration
                    CupertinoButton(
                      onPressed:
                          _isLoading
                              ? null
                              : () {
                                setState(() {
                                  _isLogin = !_isLogin;
                                  _errorMessage = null;
                                });
                              },
                      child: Text(
                        _isLogin
                            ? 'Don\'t have an account? Register'
                            : 'Already have an account? Sign In',
                      ),
                    ),

                    // For debugging: additional buttons
                    if (kDebugMode)
                      Column(
                        children: [
                          const SizedBox(height: 8),
                          Container(
                            height: 1,
                            color: CupertinoColors.systemGrey5,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Debug functions',
                            style: TextStyle(
                              color: CupertinoColors.systemGrey,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: _manualNavigate,
                            child: const Text('Go to main page manually'),
                          ),
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: _fillTestData,
                            child: const Text('Fill with test data'),
                          ),
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: _createTestUser,
                            child: const Text('Create test user'),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
