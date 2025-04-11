import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../domain/entities/github_repository.dart';
import '../../domain/entities/github_todo.dart';
import '../providers/github_repositories_provider.dart';

/// Notifier for managing all tasks
class GithubAllTodosNotifier
    extends StateNotifier<AsyncValue<List<GithubTodo>>> {
  final Ref ref;

  GithubAllTodosNotifier(this.ref) : super(const AsyncValue.loading()) {
    loadTodos();
  }

  /// Loads all tasks from the repository
  Future<void> loadTodos() async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(githubRepositoryServiceProvider);
      final todos = await repository.getAllTodos();
      state = AsyncValue.data(todos);
      if (kDebugMode) {
        print('Loaded tasks: ${todos.length}');
      }
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
      if (kDebugMode) {
        print('Error loading tasks: $error');
      }
    }
  }

  /// Updates the task
  Future<void> updateTodo(GithubTodo todo) async {
    try {
      final repository = ref.read(githubRepositoryServiceProvider);
      await repository.updateTodo(todo);
      await loadTodos(); // Reload the list of tasks
    } catch (error) {
      if (kDebugMode) {
        print('Error updating task: $error');
      }
    }
  }

  /// Deletes the task
  Future<void> deleteTodo(String todoId) async {
    try {
      final repository = ref.read(githubRepositoryServiceProvider);
      await repository.deleteTodo(todoId);
      await loadTodos(); // Reload the list of tasks
    } catch (error) {
      if (kDebugMode) {
        print('Error deleting task: $error');
      }
    }
  }

  /// Adds a new task and updates the list
  Future<void> addTodo(GithubTodo todo) async {
    try {
      final repository = ref.read(githubRepositoryServiceProvider);
      await repository.createTodo(todo);
      await loadTodos(); // Reload the list of tasks
    } catch (error) {
      if (kDebugMode) {
        print('Error adding task: $error');
      }
    }
  }
}

/// Provider for managing all tasks
final githubAllTodosProvider =
    StateNotifierProvider<GithubAllTodosNotifier, AsyncValue<List<GithubTodo>>>(
      (ref) {
        return GithubAllTodosNotifier(ref);
      },
    );

/// Provider to retrieve repository tasks
final githubRepositoryTodosProvider = FutureProvider.family<
  List<GithubTodo>,
  String
>((ref, repositoryId) async {
  // Follow changes in the general tasks provider
  final allTodosState = ref.watch(githubAllTodosProvider);

  if (allTodosState is AsyncData<List<GithubTodo>>) {
    // If the tasks in the general provider are already loaded, filter them by repositoryId
    final allTodos = allTodosState.value;
    if (kDebugMode) {
      print(
        'Filtering tasks for repository $repositoryId. Total tasks: ${allTodos.length}',
      );
    }
    return allTodos.where((todo) => todo.repositoryId == repositoryId).toList();
  } else {
    // Otherwise, load tasks directly for this repository
    final repository = ref.read(githubRepositoryServiceProvider);
    return repository.getRepositoryTodos(repositoryId);
  }
});

/// Provider to retrieve repository information by its ID
final githubRepositoryByIdProvider = Provider.family<GithubRepository?, String>(
  (ref, repositoryId) {
    try {
      // Get the Box with repositories
      if (!Hive.isBoxOpen('github_repositories')) {
        if (kDebugMode) {
          print('Box github_repositories is not open');
        }
        return null;
      }

      final repositoriesBox = Hive.box<GithubRepository>('github_repositories');

      // Get the repository by ID
      final repository = repositoriesBox.get(repositoryId);
      if (repository == null && kDebugMode) {
        print('Repository with ID $repositoryId not found');
      }

      return repository;
    } catch (e) {
      if (kDebugMode) {
        print('Error retrieving repository: $e');
      }
      return null;
    }
  },
);
