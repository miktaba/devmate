import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/router/app_router.dart';
import '../../domain/entities/github_repository.dart';
import '../providers/github_repositories_provider.dart';
import '../providers/github_auth_provider.dart';

class GithubRepositoriesPage extends ConsumerWidget {
  const GithubRepositoriesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Check authorization status
    final isGithubAuth = ref.watch(githubAuthStateProvider).isAuthenticated;

    // If user is not authorized, show screen with authorization button
    if (!isGithubAuth) {
      return CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
          middle: Text('GitHub Repositories'),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  CupertinoIcons.cube_box,
                  size: 80,
                  color: CupertinoColors.systemGrey,
                ),
                const SizedBox(height: 20),
                const Text(
                  'You are not logged in to GitHub',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  'To access repositories, you need to\nconnect your GitHub account',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: CupertinoColors.systemGrey),
                ),
                const SizedBox(height: 30),
                CupertinoButton.filled(
                  onPressed: () => context.push(AppRoutes.githubAuth),
                  child: const Text('Connect GitHub'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Continue with the usual page logic if the user is authorized
    final filteredRepositoriesAsync = ref.watch(
      filteredGithubRepositoriesProvider,
    );
    final filter = ref.watch(repositoryFilterProvider);
    final sortType = ref.watch(repositorySortTypeProvider);

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('GitHub repositories'),
        trailing: _SyncButton(),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            // Segmented switch for repository filtering
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: CupertinoSlidingSegmentedControl<RepositoryFilter>(
                groupValue: filter,
                onValueChanged: (value) {
                  if (value != null) {
                    ref.read(repositoryFilterProvider.notifier).state = value;
                  }
                },
                children: const {
                  RepositoryFilter.all: _SegmentedControlLabel(
                    title: 'All',
                    icon: CupertinoIcons.square_stack_3d_down_right,
                  ),
                  RepositoryFilter.public: _SegmentedControlLabel(
                    title: 'Public',
                    icon: CupertinoIcons.globe,
                  ),
                  RepositoryFilter.private: _SegmentedControlLabel(
                    title: 'Private',
                    icon: CupertinoIcons.lock,
                  ),
                },
              ),
            ),
            const SizedBox(height: 8),

            // Sorting control element
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  //const Text('Sorting:'),
                  //const SizedBox(width: 8),
                  Expanded(
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getSortIcon(sortType),
                            size: 16,
                            color: CupertinoColors.activeBlue,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getSortTitle(sortType),
                            style: const TextStyle(
                              color: CupertinoColors.activeBlue,
                            ),
                          ),
                        ],
                      ),
                      onPressed: () {
                        _showSortOptions(context, ref, sortType);
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // List of repositories
            Expanded(
              child: filteredRepositoriesAsync.when(
                data:
                    (repositories) =>
                        repositories.isEmpty
                            ? const _EmptyRepositoriesList()
                            : _RepositoriesList(repositories: repositories),
                loading:
                    () => const Center(child: CupertinoActivityIndicator()),
                error:
                    (error, stackTrace) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            CupertinoIcons.exclamationmark_circle,
                            color: CupertinoColors.destructiveRed,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error loading repositories',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            error.toString(),
                            style: TextStyle(color: CupertinoColors.systemGrey),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          CupertinoButton.filled(
                            onPressed:
                                () => ref.refresh(githubRepositoriesProvider),
                            child: const Text('Repeat'),
                          ),
                        ],
                      ),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Get the header for the current sort type
  String _getSortTitle(RepositorySortType sortType) {
    switch (sortType) {
      case RepositorySortType.updatedDesc:
        return 'Updated (new first)';
      case RepositorySortType.updatedAsc:
        return 'Updated (old first)';
      case RepositorySortType.nameAsc:
        return 'Name (A-Z)';
      case RepositorySortType.nameDesc:
        return 'Name (Z-A)';
    }
  }

  // Get the icon for the current sort type
  IconData _getSortIcon(RepositorySortType sortType) {
    switch (sortType) {
      case RepositorySortType.updatedDesc:
        return CupertinoIcons.time_solid;
      case RepositorySortType.updatedAsc:
        return CupertinoIcons.time;
      case RepositorySortType.nameAsc:
        return CupertinoIcons.arrow_up;
      case RepositorySortType.nameDesc:
        return CupertinoIcons.arrow_down;
    }
  }

  // Show the sorting options dialog
  void _showSortOptions(
    BuildContext context,
    WidgetRef ref,
    RepositorySortType currentSort,
  ) {
    showCupertinoModalPopup(
      context: context,
      builder:
          (context) => CupertinoActionSheet(
            title: const Text('Sorting repositories'),
            actions: [
              CupertinoActionSheetAction(
                onPressed: () {
                  ref.read(repositorySortTypeProvider.notifier).state =
                      RepositorySortType.updatedDesc;
                  Navigator.pop(context);
                },
                isDefaultAction: currentSort == RepositorySortType.updatedDesc,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.time_solid,
                      color:
                          currentSort == RepositorySortType.updatedDesc
                              ? CupertinoColors.activeBlue
                              : null,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Updated (new first)',
                      style: TextStyle(
                        color:
                            currentSort == RepositorySortType.updatedDesc
                                ? CupertinoColors.activeBlue
                                : null,
                      ),
                    ),
                  ],
                ),
              ),
              CupertinoActionSheetAction(
                onPressed: () {
                  ref.read(repositorySortTypeProvider.notifier).state =
                      RepositorySortType.updatedAsc;
                  Navigator.pop(context);
                },
                isDefaultAction: currentSort == RepositorySortType.updatedAsc,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.time,
                      color:
                          currentSort == RepositorySortType.updatedAsc
                              ? CupertinoColors.activeBlue
                              : null,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Updated (old first)',
                      style: TextStyle(
                        color:
                            currentSort == RepositorySortType.updatedAsc
                                ? CupertinoColors.activeBlue
                                : null,
                      ),
                    ),
                  ],
                ),
              ),
              CupertinoActionSheetAction(
                onPressed: () {
                  ref.read(repositorySortTypeProvider.notifier).state =
                      RepositorySortType.nameAsc;
                  Navigator.pop(context);
                },
                isDefaultAction: currentSort == RepositorySortType.nameAsc,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.arrow_up,
                      color:
                          currentSort == RepositorySortType.nameAsc
                              ? CupertinoColors.activeBlue
                              : null,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Name (A-Z)',
                      style: TextStyle(
                        color:
                            currentSort == RepositorySortType.nameAsc
                                ? CupertinoColors.activeBlue
                                : null,
                      ),
                    ),
                  ],
                ),
              ),
              CupertinoActionSheetAction(
                onPressed: () {
                  ref.read(repositorySortTypeProvider.notifier).state =
                      RepositorySortType.nameDesc;
                  Navigator.pop(context);
                },
                isDefaultAction: currentSort == RepositorySortType.nameDesc,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.arrow_down,
                      color:
                          currentSort == RepositorySortType.nameDesc
                              ? CupertinoColors.activeBlue
                              : null,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Name (Z-A)',
                      style: TextStyle(
                        color:
                            currentSort == RepositorySortType.nameDesc
                                ? CupertinoColors.activeBlue
                                : null,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            cancelButton: CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ),
    );
  }
}

/// Widget for displaying a label in the segmented switch
class _SegmentedControlLabel extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SegmentedControlLabel({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 16), const SizedBox(width: 6), Text(title)],
      ),
    );
  }
}

class _SyncButton extends ConsumerWidget {
  const _SyncButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSyncing = ref.watch(isSyncingProvider);

    return GestureDetector(
      onTap:
          isSyncing
              ? null
              : () async {
                // Set synchronization flag
                ref.read(isSyncingProvider.notifier).state = true;

                try {
                  // Get the repository service
                  final repoService = ref.read(githubRepositoryServiceProvider);

                  // Call synchronization
                  await repoService.syncData();

                  // Update provider data
                  ref.invalidate(githubRepositoriesProvider);
                } catch (e) {
                  if (kDebugMode) {
                    print('Error during synchronization: $e');
                  }
                } finally {
                  // Remove synchronization flag
                  ref.read(isSyncingProvider.notifier).state = false;
                }
              },
      child:
          isSyncing
              ? const CupertinoActivityIndicator()
              : const Icon(CupertinoIcons.refresh),
    );
  }
}

class _EmptyRepositoriesList extends ConsumerWidget {
  const _EmptyRepositoriesList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            CupertinoIcons.folder,
            size: 64,
            color: CupertinoColors.systemGrey,
          ),
          const SizedBox(height: 16),
          const Text(
            'No available repositories',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Connect your GitHub account or\ncreate a new repository',
            textAlign: TextAlign.center,
            style: TextStyle(color: CupertinoColors.systemGrey),
          ),
          const SizedBox(height: 24),
          CupertinoButton.filled(
            onPressed: () async {
              // Open the GitHub authorization page
              final result = await context.push('/github/auth');
              if (result == true) {
                // If authorization is successful, refresh the list of repositories
                ref.refresh(githubRepositoriesProvider);
              }
            },
            child: const Text('Connect GitHub'),
          ),
        ],
      ),
    );
  }
}

class _RepositoriesList extends StatelessWidget {
  final List<GithubRepository> repositories;

  const _RepositoriesList({required this.repositories});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: repositories.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final repo = repositories[index];
        return _RepositoryCard(repository: repo);
      },
    );
  }
}

class _RepositoryCard extends StatelessWidget {
  final GithubRepository repository;

  const _RepositoryCard({required this.repository});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Go to the repository details page
        context.push(
          '/github/repositories/${repository.owner}/${repository.name}',
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: CupertinoColors.systemGrey5),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.systemGrey.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Owner avatar
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: NetworkImage(repository.ownerAvatarUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Repository name
                Expanded(
                  child: Text(
                    repository.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Private/public indicator
                Icon(
                  repository.isPrivate
                      ? CupertinoIcons.lock_fill
                      : CupertinoIcons.globe,
                  size: 16,
                  color:
                      repository.isPrivate
                          ? CupertinoColors.systemYellow
                          : CupertinoColors.activeBlue,
                ),
              ],
            ),
            if (repository.description != null &&
                repository.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                repository.description!,
                style: const TextStyle(
                  fontSize: 14,
                  color: CupertinoColors.systemGrey,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                // Language
                if (repository.language != null) ...[
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _getLanguageColor(repository.language),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    repository.language!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                // Stars
                const Icon(
                  CupertinoIcons.star_fill,
                  size: 12,
                  color: CupertinoColors.systemYellow,
                ),
                const SizedBox(width: 4),
                Text(
                  '${repository.starCount}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
                const SizedBox(width: 16),
                // Forks
                const Icon(
                  CupertinoIcons.arrow_branch,
                  size: 12,
                  color: CupertinoColors.systemGrey,
                ),
                const SizedBox(width: 4),
                Text(
                  '${repository.forkCount}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
                const Spacer(),
                // Tasks
                Row(
                  children: [
                    const Icon(
                      CupertinoIcons.list_bullet,
                      size: 12,
                      color: CupertinoColors.systemGrey,
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () {
                        // Go to the repository details page with the active tasks tab
                        context.push(
                          '/github/repositories/${repository.owner}/${repository.name}?tab=2',
                        );
                      },
                      child: const Text(
                        'Tasks',
                        style: TextStyle(
                          fontSize: 12,
                          color: CupertinoColors.activeBlue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Update date
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                'Updated: ${_formatDate(repository.updatedAt)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: CupertinoColors.systemGrey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Formatting date to a readable view
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} min ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 30) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}.${date.month}.${date.year}';
    }
  }

  // Getting the color for the programming language
  Color _getLanguageColor(String? language) {
    if (language == null) return CupertinoColors.systemGrey;

    switch (language.toLowerCase()) {
      case 'dart':
        return const Color(0xFF00B4AB);
      case 'python':
        return const Color(0xFF3572A5);
      case 'javascript':
        return const Color(0xFFF1E05A);
      case 'typescript':
        return const Color(0xFF2B7489);
      case 'java':
        return const Color(0xFFB07219);
      case 'kotlin':
        return const Color(0xFFF18E33);
      case 'swift':
        return const Color(0xFFFFAC45);
      case 'c#':
      case 'csharp':
        return const Color(0xFF178600);
      case 'c++':
        return const Color(0xFFF34B7D);
      case 'go':
        return const Color(0xFF00ADD8);
      case 'ruby':
        return const Color(0xFF701516);
      case 'php':
        return const Color(0xFF4F5D95);
      case 'html':
        return const Color(0xFFE34C26);
      case 'css':
        return const Color(0xFF563D7C);
      default:
        return CupertinoColors.systemGrey;
    }
  }
}
