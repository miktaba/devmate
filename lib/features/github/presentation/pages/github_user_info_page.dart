import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../providers/github_auth_provider.dart';
import '../../data/services/github_auth_service.dart';

/// Page for displaying GitHub user information
class GitHubUserInfoPage extends ConsumerWidget {
  const GitHubUserInfoPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get user information
    final userInfoAsync = ref.watch(githubUserInfoProvider);

    // Check authorization status
    final isAuthenticatedAsync = ref.watch(githubAuthProvider);

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('GitHub Profile'),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: FutureBuilder<bool>(
            future: isAuthenticatedAsync,
            builder: (context, snapshot) {
              final isAuthenticated = snapshot.data ?? false;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Check if the user is authorized
                  if (!isAuthenticated) ...[
                    const Center(
                      child: Icon(
                        CupertinoIcons.person_crop_circle_badge_xmark,
                        size: 72,
                        color: CupertinoColors.systemRed,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Center(
                      child: Text(
                        'You are not authorized in GitHub',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: CupertinoButton.filled(
                        onPressed: () {
                          context.push(AppRoutes.githubAuth);
                        },
                        child: const Text('Authorize'),
                      ),
                    ),
                  ] else ...[
                    // Display user information depending on the state
                    userInfoAsync.when(
                      data: (userInfo) {
                        if (userInfo == null) {
                          return const Center(
                            child: Text(
                              'Failed to get user information',
                              style: TextStyle(
                                color: CupertinoColors.systemRed,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          );
                        }

                        final login = userInfo['login'] as String?;
                        final name = userInfo['name'] as String?;
                        final avatarUrl = userInfo['avatar_url'] as String?;
                        final bio = userInfo['bio'] as String?;
                        final company = userInfo['company'] as String?;
                        final location = userInfo['location'] as String?;
                        final email = userInfo['email'] as String?;
                        final publicRepos = userInfo['public_repos'] as int?;

                        // Log received data for debugging
                        if (kDebugMode) {
                          print('GitHub user data: $userInfo');
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Avatar
                            if (avatarUrl != null) ...[
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  image: DecorationImage(
                                    image: NetworkImage(avatarUrl),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ] else ...[
                              const Icon(
                                CupertinoIcons.person_crop_circle,
                                size: 120,
                                color: CupertinoColors.systemGrey,
                              ),
                              const SizedBox(height: 16),
                            ],

                            // User name
                            Text(
                              name ?? login ?? 'Unknown user',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            if (login != null)
                              Text(
                                '@$login',
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: CupertinoColors.systemGrey,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            const SizedBox(height: 16),

                            // Additional information
                            if (bio != null) ...[
                              Text(
                                bio,
                                style: const TextStyle(fontSize: 16),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Statistics
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: CupertinoColors.systemGrey6,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: CupertinoColors.systemGrey5,
                                ),
                              ),
                              child: Column(
                                children: [
                                  _buildInfoRow(
                                    'Public repositories',
                                    publicRepos?.toString() ?? 'No data',
                                  ),
                                  if (company != null)
                                    _buildInfoRow('Company', company),
                                  if (location != null)
                                    _buildInfoRow('Location', location),
                                  if (email != null)
                                    _buildInfoRow('Email', email),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Actions
                            CupertinoButton.filled(
                              onPressed: () async {
                                await ref
                                    .read(githubAuthStateProvider.notifier)
                                    .logout();
                                if (context.mounted) {
                                  context.pop();
                                }
                              },
                              child: const Text('Disconnect GitHub'),
                            ),
                            const SizedBox(height: 12),
                            CupertinoButton(
                              onPressed: () {
                                context.push(AppRoutes.githubRepositories);
                              },
                              child: const Text('View repositories'),
                            ),
                          ],
                        );
                      },
                      loading:
                          () => const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CupertinoActivityIndicator(),
                                const SizedBox(height: 16),
                                const Text('Loading data...'),
                              ],
                            ),
                          ),
                      error: (error, stackTrace) {
                        if (kDebugMode) {
                          print('Error during getting data: $error');
                          print('Stack trace: $stackTrace');
                        }
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                CupertinoIcons.exclamationmark_triangle,
                                size: 48,
                                color: CupertinoColors.systemYellow,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Error during loading data: $error',
                                style: const TextStyle(
                                  color: CupertinoColors.systemRed,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              CupertinoButton(
                                onPressed: () {
                                  ref.refresh(githubUserInfoProvider);
                                },
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],

                  // Debug information
                  if (kDebugMode) ...[
                    const SizedBox(height: 20),
                    Container(height: 1, color: CupertinoColors.systemGrey5),
                    const SizedBox(height: 16),
                    const Text(
                      'Debug information:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Authorization status: $isAuthenticated'),
                    const SizedBox(height: 8),
                    FutureBuilder<String?>(
                      future: GitHubAuthService().getAccessToken(),
                      builder: (context, snapshot) {
                        return Text(
                          'Token: ${snapshot.data ?? 'No token'}',
                          style: const TextStyle(fontSize: 12),
                        );
                      },
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: CupertinoColors.systemGrey),
          ),
          Text(value),
        ],
      ),
    );
  }
}
