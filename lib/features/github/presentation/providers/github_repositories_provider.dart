import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/github_repository.dart';
import '../../data/repositories/github_repository_impl.dart';
import '../../data/services/github_repository_service.dart';

/// Type of repository filter
enum RepositoryFilter {
  all, // All repositories
  public, // Only public
  private, // Only private
}

/// Type of repository sorting
enum RepositorySortType {
  updatedDesc, // By update date (newest first)
  updatedAsc, // By update date (oldest first)
  nameAsc, // By name (A-Z)
  nameDesc, // By name (Z-A)
}

/// Provider for tracking the type of repository filter
final repositoryFilterProvider = StateProvider<RepositoryFilter>(
  (ref) => RepositoryFilter.all,
);

/// Provider for tracking the type of repository sorting
final repositorySortTypeProvider = StateProvider<RepositorySortType>(
  (ref) => RepositorySortType.updatedDesc,
);

/// Provider for accessing GitHub repositories
final githubRepositoryServiceProvider = Provider<GitHubRepositoryService>((
  ref,
) {
  return GitHubRepositoryService();
});

/// Provider for tracking the synchronization state
final isSyncingProvider = StateProvider<bool>((ref) => false);

/// Provider for accessing the list of GitHub repositories
final githubRepositoriesProvider = FutureProvider<List<GithubRepository>>((
  ref,
) async {
  try {
    final repoService = ref.read(githubRepositoryServiceProvider);
    return await repoService.getUserRepositories();
  } catch (e) {
    if (kDebugMode) {
      print('Error during getting repositories: $e');
    }
    return [];
  }
});

/// Provider for accessing the filtered and sorted list of GitHub repositories
final filteredGithubRepositoriesProvider =
    Provider<AsyncValue<List<GithubRepository>>>((ref) {
      final repositoriesAsync = ref.watch(githubRepositoriesProvider);
      final filter = ref.watch(repositoryFilterProvider);
      final sortType = ref.watch(repositorySortTypeProvider);

      return repositoriesAsync.when(
        data: (repositories) {
          // Filtering by repository type
          List<GithubRepository> filteredRepos;
          switch (filter) {
            case RepositoryFilter.all:
              filteredRepos = repositories;
              break;
            case RepositoryFilter.public:
              filteredRepos =
                  repositories.where((repo) => !repo.isPrivate).toList();
              break;
            case RepositoryFilter.private:
              filteredRepos =
                  repositories.where((repo) => repo.isPrivate).toList();
              break;
          }

          // Sorting repositories
          switch (sortType) {
            case RepositorySortType.updatedDesc:
              filteredRepos.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
              break;
            case RepositorySortType.updatedAsc:
              filteredRepos.sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
              break;
            case RepositorySortType.nameAsc:
              filteredRepos.sort(
                (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
              );
              break;
            case RepositorySortType.nameDesc:
              filteredRepos.sort(
                (a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()),
              );
              break;
          }

          return AsyncValue.data(filteredRepos);
        },
        loading: () => const AsyncValue.loading(),
        error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
      );
    });

/// Notifier for managing the list of GitHub repositories
class GithubRepositoriesNotifier extends AsyncNotifier<List<GithubRepository>> {
  @override
  Future<List<GithubRepository>> build() async {
    try {
      final repository = ref.read(githubRepositoryServiceProvider);
      return await repository.getUserRepositories();
    } catch (e, stack) {
      if (kDebugMode) {
        print('Error during loading repositories: $e');
        print('Stack trace: $stack');
      }
      return [];
    }
  }

  /// Synchronize repositories with GitHub
  Future<void> syncRepositories() async {
    try {
      // Set the synchronization flag
      ref.read(isSyncingProvider.notifier).state = true;

      final repository = ref.read(githubRepositoryServiceProvider);
      final success = await repository.syncData();

      if (success) {
        // Update the state
        state = const AsyncValue.loading();
        state = AsyncValue.data(await repository.getUserRepositories());
      } else {
        // In case of an error, leave the current data
        if (kDebugMode) {
          print('Error during synchronization data');
        }
      }
    } catch (e, stack) {
      if (kDebugMode) {
        print('Error during synchronization repositories: $e');
        print('Stack trace: $stack');
      }
      // Leave the current state and add the error
      state = AsyncValue.error(e, stack);
    } finally {
      // Remove the synchronization flag
      ref.read(isSyncingProvider.notifier).state = false;
    }
  }

  /// Select repository (set the selected flag)
  Future<void> selectRepository(String repositoryId, bool selected) async {
    // Get the current state
    final currentState = state.value;
    if (currentState == null) return;

    try {
      // Find the repository by ID and update it
      final updatedRepositories =
          currentState.map((repo) {
            if (repo.id == repositoryId) {
              return repo.copyWith(selected: selected);
            }
            return repo;
          }).toList();

      // Update the state
      state = AsyncValue.data(updatedRepositories);

      // TODO: Save changes to local storage
    } catch (e, stack) {
      if (kDebugMode) {
        print('Error during selecting repository: $e');
        print('Stack trace: $stack');
      }
    }
  }
}
