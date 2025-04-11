import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/router/app_router.dart';
import '../../../../features/auth/providers/auth_provider.dart';
import '../../../../features/github/presentation/providers/github_auth_provider.dart';
import '../../../../features/github/presentation/providers/github_repositories_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get user data from Firebase Auth
    final user = ref.watch(authProvider).value;

    // Track GitHub authorization state through StateNotifier provider
    final githubAuthState = ref.watch(githubAuthStateProvider);
    final isGithubAuth = githubAuthState.isAuthenticated;

    // This will force UI to update when auth state changes
    ref.listen(githubAuthStateProvider, (previous, current) {
      if (previous?.isAuthenticated != current.isAuthenticated) {
        if (kDebugMode) {
          print('GitHub auth state changed: ${current.isAuthenticated}');
        }
        ref.invalidate(githubUserInfoProvider);
        ref.invalidate(githubRepositoriesProvider);
      }
    });

    // This will force UI to update when auth state changes
    final githubUserInfo =
        isGithubAuth ? ref.watch(githubUserInfoProvider) : null;

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('DevMate')),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // User profile (avatar and greeting)
              Row(
                children: [
                  // GitHub avatar or default avatar
                  _buildAvatar(githubUserInfo),

                  const SizedBox(width: 16),

                  // Greeting and information
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello, \n${_getUserName(user, githubUserInfo)}!',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        isGithubAuth && githubUserInfo != null
                            ? githubUserInfo.when(
                              data: (data) {
                                final login = data?['login'] as String?;
                                return Text(
                                  login != null ? '@$login' : 'Guest',
                                  style: const TextStyle(
                                    color: CupertinoColors.systemGrey,
                                    fontSize: 16,
                                  ),
                                );
                              },
                              loading:
                                  () => const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CupertinoActivityIndicator(radius: 8),
                                      SizedBox(width: 8),
                                      Text(
                                        'Loading...',
                                        style: TextStyle(
                                          color: CupertinoColors.systemGrey,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                              error:
                                  (_, __) => const Text(
                                    'Error loading data',
                                    style: TextStyle(
                                      color: CupertinoColors.destructiveRed,
                                      fontSize: 16,
                                    ),
                                  ),
                            )
                            : Text(
                              user?.email ?? 'Guest',
                              style: const TextStyle(
                                color: CupertinoColors.systemGrey,
                                fontSize: 16,
                              ),
                            ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // User statistics (if GitHub connected)
              _buildGitHubStats(isGithubAuth, githubUserInfo, ref),

              const SizedBox(height: 24),

              // Application menu
              const Text(
                'Menu',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              _buildNavigationCard(
                context,
                'Skills',
                CupertinoIcons.star,
                () => context.push(AppRoutes.skills),
              ),

              const SizedBox(height: 12),

              _buildNavigationCard(
                context,
                'GitHub Repositories',
                CupertinoIcons.cube_box,
                () => context.push(AppRoutes.githubRepositories),
              ),

              const SizedBox(height: 12),

              _buildNavigationCard(
                context,
                'All Tasks',
                CupertinoIcons.square_list,
                () => context.push(AppRoutes.githubAllTodos),
              ),

              const SizedBox(height: 12),

              _buildNavigationCard(
                context,
                'Settings',
                CupertinoIcons.settings,
                () => context.push(AppRoutes.settings),
              ),

              // GitHub profile (if connected)
              if (isGithubAuth) ...[
                const SizedBox(height: 12),
                _buildNavigationCard(
                  context,
                  'GitHub Profile',
                  CupertinoIcons.person_badge_plus,
                  () => context.push(AppRoutes.githubProfile),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Get user name from different sources
  String _getUserName(
    User? firebaseUser,
    AsyncValue<Map<String, dynamic>?>? githubUser,
  ) {
    // First try to get from GitHub
    if (githubUser != null) {
      return githubUser.when(
        data: (data) {
          if (data != null) {
            // First try name, then login
            final name = data['name'] as String?;
            final login = data['login'] as String?;
            if (name != null) return name;
            if (login != null) return login;
          }

          // If no data in GitHub, try from Firebase
          if (firebaseUser?.displayName != null) {
            return firebaseUser!.displayName!;
          }

          return 'developer';
        },
        loading: () => firebaseUser?.displayName ?? 'developer',
        error: (_, __) => firebaseUser?.displayName ?? 'developer',
      );
    }

    // If no GitHub, try from Firebase
    if (firebaseUser?.displayName != null) return firebaseUser!.displayName!;

    // Default
    return 'developer';
  }

  // Get GitHub user login
  String _getGitHubLogin(AsyncValue<Map<String, dynamic>?>? githubUser) {
    if (githubUser == null) return 'Guest';

    return githubUser.when(
      data: (data) {
        final login = data?['login'] as String?;
        return login != null ? '@$login' : 'Guest';
      },
      loading: () => 'Loading...',
      error: (_, __) => 'Error loading',
    );
  }

  // Building the avatar
  Widget _buildAvatar(AsyncValue<Map<String, dynamic>?>? githubUserInfo) {
    // If there is no GitHub user data or the user is not authorized
    if (githubUserInfo == null) {
      return _buildDefaultAvatar();
    }

    // Use when to handle different AsyncValue states
    return githubUserInfo.when(
      data: (userData) {
        if (userData == null || userData['avatar_url'] == null) {
          return _buildDefaultAvatar();
        }

        final avatarUrl = userData['avatar_url'] as String;
        return Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: DecorationImage(
              image: NetworkImage(avatarUrl),
              fit: BoxFit.cover,
            ),
          ),
        );
      },
      loading: () => _buildDefaultAvatar(),
      error: (_, __) => _buildDefaultAvatar(),
    );
  }

  // Default avatar
  Widget _buildDefaultAvatar() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey5,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        CupertinoIcons.person,
        size: 40,
        color: CupertinoColors.systemGrey,
      ),
    );
  }

  // Building GitHub statistics
  Widget _buildGitHubStats(
    bool isGithubAuth,
    AsyncValue<Map<String, dynamic>?>? githubUserInfo,
    WidgetRef ref,
  ) {
    if (!isGithubAuth || githubUserInfo == null) {
      return const SizedBox.shrink();
    }

    // Use an asynchronous provider to get the list of repositories
    final githubRepos = ref.watch(githubRepositoriesProvider);

    return githubUserInfo.when(
      data: (userData) {
        if (userData == null) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: CupertinoColors.systemGrey6,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: CupertinoColors.systemGrey5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'GitHub statistics',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              // Use data from the repositories provider instead of user data
              githubRepos.when(
                data:
                    (repos) =>
                        _buildInfoRow('Repositories', repos.length.toString()),
                loading: () => _buildInfoRow('Repositories', '...'),
                error:
                    (_, __) => _buildInfoRow(
                      'Repositories',
                      (userData['public_repos'] as int?)?.toString() ?? '0',
                    ),
              ),
              if (userData['company'] != null)
                _buildInfoRow('Company', userData['company'] as String),
              if (userData['location'] != null)
                _buildInfoRow('Location', userData['location'] as String),
            ],
          ),
        );
      },
      loading: () => const Center(child: CupertinoActivityIndicator()),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildNavigationCard(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey6,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: CupertinoColors.systemGrey5),
        ),
        child: Row(
          children: [
            Icon(icon, color: CupertinoColors.activeBlue),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            const Icon(
              CupertinoIcons.chevron_right,
              color: CupertinoColors.systemGrey,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: CupertinoColors.systemGrey),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
