import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import '../../../../features/auth/providers/auth_provider.dart';
import '../../../profile/application/services/auth_service.dart'
    as profile_service;
import '../../../../core/router/app_router.dart';
import '../../../github/presentation/providers/github_auth_provider.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get GitHub authorization status through StateNotifier
    final githubAuthState = ref.watch(githubAuthStateProvider);
    final isGithubAuthenticated = githubAuthState.isAuthenticated;

    // Listen for authorization status changes to update UI
    ref.listen(githubAuthStateProvider, (previous, current) {
      if (previous?.isAuthenticated != current.isAuthenticated) {
        if (kDebugMode) {
          print(
            'GitHub authorization status changed: ${current.isAuthenticated}',
          );
        }
      }
    });

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('Settings')),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Application Settings',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Manage profile and application settings',
                style: TextStyle(color: CupertinoColors.systemGrey),
              ),
              const SizedBox(height: 32),

              // General settings
              _buildSection('General', [
                _buildSettingsItem(
                  context,
                  'Notifications',
                  CupertinoIcons.bell,
                  onTap: () {
                    _showAlert(
                      context,
                      'Feature in development',
                      'Notification settings will be available in the next version.',
                    );
                  },
                ),
                _buildSettingsItem(
                  context,
                  'App Theme',
                  CupertinoIcons.paintbrush,
                  onTap: () {
                    _showAlert(
                      context,
                      'Feature in development',
                      'Theme settings will be available in the next version.',
                    );
                  },
                ),
              ]),

              const SizedBox(height: 24),

              // Integrations
              _buildSection('Integrations', [
                _buildSettingsItem(
                  context,
                  isGithubAuthenticated
                      ? 'GitHub (connected)'
                      : 'Connect GitHub',
                  CupertinoIcons.square_arrow_right,
                  onTap: () {
                    // If user is already authenticated with GitHub
                    if (isGithubAuthenticated) {
                      showCupertinoDialog(
                        context: context,
                        builder:
                            (context) => CupertinoAlertDialog(
                              title: const Text('GitHub Connected'),
                              content: const Text(
                                'Do you want to disconnect GitHub integration?',
                              ),
                              actions: [
                                CupertinoDialogAction(
                                  isDestructiveAction: true,
                                  child: const Text('Disconnect'),
                                  onPressed: () async {
                                    Navigator.pop(context);
                                    // Perform GitHub logout
                                    await ref
                                        .read(githubAuthStateProvider.notifier)
                                        .logout();
                                  },
                                ),
                                CupertinoDialogAction(
                                  child: const Text('Cancel'),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ],
                            ),
                      );
                    } else {
                      // Navigate to GitHub auth page
                      context.push(AppRoutes.githubAuth);
                    }
                  },
                ),

                // Debug information for GitHub OAuth (debug mode only)
                if (kDebugMode)
                  _buildSettingsItem(
                    context,
                    'GitHub OAuth Debug',
                    CupertinoIcons.wrench,
                    onTap: () {
                      // Show dialog with debug information
                      showCupertinoDialog(
                        context: context,
                        builder:
                            (context) => CupertinoAlertDialog(
                              title: const Text('GitHub OAuth Debug'),
                              content: Column(
                                children: [
                                  const Text(
                                    'Debug actions for GitHub integration:',
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Authorization status: ${isGithubAuthenticated ? "Authorized" : "Not Authorized"}',
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'URL scheme: devmate\nCallback URL: devmate://login-callback',
                                  ),
                                ],
                              ),
                              actions: [
                                CupertinoDialogAction(
                                  isDestructiveAction: true,
                                  child: const Text('Reset Token'),
                                  onPressed: () async {
                                    await ref
                                        .read(githubAuthStateProvider.notifier)
                                        .logout();
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                      _showAlert(
                                        context,
                                        'Token Reset',
                                        'GitHub token successfully removed',
                                      );
                                    }
                                  },
                                ),
                                CupertinoDialogAction(
                                  child: const Text('Authorize'),
                                  onPressed: () {
                                    Navigator.pop(context);
                                    context.push(AppRoutes.githubAuth);
                                  },
                                ),
                                CupertinoDialogAction(
                                  child: const Text('Close'),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ],
                            ),
                      );
                    },
                  ),
              ]),

              const SizedBox(height: 24),

              // Profile settings
              _buildSection('Profile', [
                _buildSettingsItem(
                  context,
                  'Edit Profile Data',
                  CupertinoIcons.person,
                  onTap: () {
                    _showAlert(
                      context,
                      'Feature in development',
                      'Profile editing will be available in the next version.',
                    );
                  },
                ),
                _buildSettingsItem(
                  context,
                  'Change Password',
                  CupertinoIcons.lock,
                  onTap: () {
                    _showAlert(
                      context,
                      'Feature in development',
                      'Password change will be available in the next version.',
                    );
                  },
                ),
              ]),

              const SizedBox(height: 24),

              // Logout button (separate from sections)
              CupertinoButton(
                padding: const EdgeInsets.symmetric(vertical: 14),
                color: CupertinoColors.systemRed.withOpacity(0.1),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      CupertinoIcons.square_arrow_left,
                      color: CupertinoColors.destructiveRed,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Log Out',
                      style: TextStyle(
                        color: CupertinoColors.destructiveRed,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                onPressed: () async {
                  if (kDebugMode) {
                    print('Logout button pressed in settings');
                  }

                  final authService = ref.read(
                    profile_service.authServiceProvider,
                  );

                  // Show confirmation dialog
                  showCupertinoDialog(
                    context: context,
                    builder:
                        (context) => CupertinoAlertDialog(
                          title: const Text('Log Out'),
                          content: const Text(
                            'Are you sure you want to log out?',
                          ),
                          actions: [
                            CupertinoDialogAction(
                              isDestructiveAction: true,
                              child: const Text('Log Out'),
                              onPressed: () async {
                                try {
                                  Navigator.pop(context); // Close dialog

                                  // If user is authenticated with GitHub, log out from GitHub
                                  if (ref
                                      .read(githubAuthStateProvider)
                                      .isAuthenticated) {
                                    await ref
                                        .read(githubAuthStateProvider.notifier)
                                        .logout();
                                    if (kDebugMode) {
                                      print('GitHub logout completed');
                                    }
                                  }

                                  // Log out from Firebase
                                  await authService.signOut();

                                  if (kDebugMode) {
                                    print('Logout completed successfully');
                                  }

                                  // Add delay for authProvider update
                                  await Future.delayed(
                                    const Duration(milliseconds: 300),
                                  );

                                  // Navigate to login screen
                                  if (context.mounted) {
                                    context.go(AppRoutes.welcome);
                                  }
                                } catch (e) {
                                  if (kDebugMode) {
                                    print('Logout error: $e');
                                  }

                                  if (context.mounted) {
                                    _showAlert(
                                      context,
                                      'Error',
                                      'Failed to log out: $e',
                                    );
                                  }
                                }
                              },
                            ),
                            CupertinoDialogAction(
                              child: const Text('Cancel'),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                  );
                },
              ),

              const SizedBox(height: 8),

              // Delete account button (separate from sections)
              CupertinoButton(
                padding: const EdgeInsets.symmetric(vertical: 14),
                color: CupertinoColors.systemRed.withOpacity(0.1),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      CupertinoIcons.delete,
                      color: CupertinoColors.destructiveRed,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Delete Account',
                      style: TextStyle(
                        color: CupertinoColors.destructiveRed,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                onPressed: () async {
                  if (kDebugMode) {
                    print('Delete account button pressed');
                  }

                  final authService = ref.read(
                    profile_service.authServiceProvider,
                  );

                  // Show confirmation dialog with warning
                  showCupertinoDialog(
                    context: context,
                    builder:
                        (context) => CupertinoAlertDialog(
                          title: const Text('Delete Account'),
                          content: const Text(
                            'Do you really want to delete your account? This action cannot be undone. All your data will be permanently deleted.',
                          ),
                          actions: [
                            CupertinoDialogAction(
                              isDestructiveAction: true,
                              child: const Text('Delete'),
                              onPressed: () async {
                                // First close the dialog
                                Navigator.pop(context);

                                try {
                                  // Show loading indicator
                                  showCupertinoDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder:
                                        (context) => const CupertinoAlertDialog(
                                          content: Center(
                                            child: Padding(
                                              padding: EdgeInsets.all(16.0),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  CupertinoActivityIndicator(),
                                                  SizedBox(height: 16),
                                                  Text('Deleting account...'),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                  );

                                  // If user is authenticated with GitHub, log out
                                  if (ref
                                      .read(githubAuthStateProvider)
                                      .isAuthenticated) {
                                    await ref
                                        .read(githubAuthStateProvider.notifier)
                                        .logout();
                                    if (kDebugMode) {
                                      print('GitHub logout completed');
                                    }
                                  }

                                  // Delete account
                                  await authService.deleteAccount();

                                  if (kDebugMode) {
                                    print('Account successfully deleted');
                                  }

                                  // Close loading indicator if still open
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                  }

                                  // Add delay for authProvider update
                                  await Future.delayed(
                                    const Duration(milliseconds: 300),
                                  );

                                  // Navigate to welcome screen
                                  if (context.mounted) {
                                    context.go(AppRoutes.welcome);
                                  }
                                } catch (e) {
                                  if (kDebugMode) {
                                    print('Account deletion error: $e');
                                  }

                                  // Close loading indicator if open
                                  if (context.mounted) {
                                    Navigator.pop(
                                      context,
                                    ); // Close loading indicator

                                    // Show error message
                                    String errorMessage =
                                        'Failed to delete account';

                                    if (e
                                        is firebase_auth.FirebaseAuthException) {
                                      if (e.code == 'internal-error') {
                                        errorMessage =
                                            'Firebase internal error. Check your Internet connection and make sure the Firebase emulator is running.';
                                      } else if (e.code ==
                                          'requires-recent-login') {
                                        errorMessage =
                                            'For account deletion, you need to re-authenticate. Please log out and log in again.';
                                      } else {
                                        errorMessage =
                                            'Firebase error: ${e.message}';
                                      }
                                    } else {
                                      errorMessage = 'Error: $e';
                                    }

                                    _showAlert(context, 'Error', errorMessage);
                                  }
                                }
                              },
                            ),
                            CupertinoDialogAction(
                              child: const Text('Cancel'),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                  );
                },
              ),

              const Spacer(),

              // Application information
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      const Text(
                        'DevMate',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Version 1.0.0',
                        style: TextStyle(
                          fontSize: 12,
                          color: CupertinoColors.systemGrey.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: CupertinoColors.systemGrey,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: CupertinoColors.systemGrey6,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: CupertinoColors.systemGrey5),
          ),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildSettingsItem(
    BuildContext context,
    String title,
    IconData icon, {
    required Function() onTap,
    Color color = CupertinoColors.activeBlue,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: CupertinoColors.systemGrey5, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color:
                    color == CupertinoColors.activeBlue
                        ? CupertinoColors.black
                        : color,
              ),
            ),
            const Spacer(),
            const Icon(
              CupertinoIcons.chevron_right,
              size: 16,
              color: CupertinoColors.systemGrey,
            ),
          ],
        ),
      ),
    );
  }

  void _showAlert(BuildContext context, String title, String message) {
    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
    );
  }
}
