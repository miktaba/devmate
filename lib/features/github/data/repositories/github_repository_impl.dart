import 'package:flutter/foundation.dart';
import 'package:github/github.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/github_repository.dart' as entities;
import '../../domain/entities/github_todo.dart';
import '../../domain/repositories/github_repository_interface.dart';

/// Repository implementation for working with GitHub API
class GithubRepositoryImpl implements IGithubRepository {
  final GitHub _github;
  final Box<entities.GithubRepository> _repositoriesBox;
  final Box<GithubTodo> _todosBox;

  static const String _boxNameRepositories = 'github_repositories';
  static const String _boxNameTodos = 'github_todos';

  GithubRepositoryImpl({GitHub? github})
    : _github = github ?? GitHub(),
      _repositoriesBox = Hive.box<entities.GithubRepository>(
        _boxNameRepositories,
      ),
      _todosBox = Hive.box<GithubTodo>(_boxNameTodos) {
    // Initializing GitHub with the saved token
    try {
      final tokenBox = Hive.box('auth_tokens');
      final token = tokenBox.get('github_token') as String?;
      if (token != null) {
        _github.auth = Authentication.withToken(token);
        if (kDebugMode) {
          print('GitHub client initialized with a token');
        }
      }

      if (kDebugMode) {
        print('GithubRepositoryImpl initialized:');
        print(
          '- Box $_boxNameRepositories opened: ${Hive.isBoxOpen(_boxNameRepositories)}',
        );
        print('- Box $_boxNameTodos opened: ${Hive.isBoxOpen(_boxNameTodos)}');
        print('- Number of repositories: ${_repositoriesBox.values.length}');
        print('- Number of tasks: ${_todosBox.values.length}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing GithubRepositoryImpl: $e');
      }
    }
  }

  /// Initialize local storage
  static Future<void> initHive() async {
    try {
      if (kDebugMode) {
        print('Starting Hive initialization for GitHub...');
      }

      // Register adapters if they are not registered yet
      if (!Hive.isAdapterRegistered(
        entities.GithubRepositoryAdapter().typeId,
      )) {
        Hive.registerAdapter(entities.GithubRepositoryAdapter());
      }
      if (!Hive.isAdapterRegistered(TodoPriorityAdapter().typeId)) {
        Hive.registerAdapter(TodoPriorityAdapter());
      }
      if (!Hive.isAdapterRegistered(TodoCategoryAdapter().typeId)) {
        Hive.registerAdapter(TodoCategoryAdapter());
      }
      if (!Hive.isAdapterRegistered(GithubTodoAdapter().typeId)) {
        Hive.registerAdapter(GithubTodoAdapter());
      }

      // Open boxes if they are not opened yet
      if (!Hive.isBoxOpen(_boxNameRepositories)) {
        await Hive.openBox<entities.GithubRepository>(_boxNameRepositories);
      }
      if (!Hive.isBoxOpen(_boxNameTodos)) {
        await Hive.openBox<GithubTodo>(_boxNameTodos);
      }

      if (kDebugMode) {
        print('Hive initialized for GitHub:');
        print(
          '- Box $_boxNameRepositories opened: ${Hive.isBoxOpen(_boxNameRepositories)}',
        );
        print('- Box $_boxNameTodos opened: ${Hive.isBoxOpen(_boxNameTodos)}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing Hive for GitHub: $e');
      }
    }
  }

  @override
  Future<bool> authenticate(String token) async {
    try {
      _github.auth = Authentication.withToken(token);

      // Checking the validity of the token by requesting user data
      final currentUser = await _github.users.getCurrentUser();
      if (kDebugMode) {
        print('Authentication successful: ${currentUser.login}');
      }

      // Saving the token to local storage
      final tokenBox = await Hive.openBox('auth_tokens');
      await tokenBox.put('github_token', token);

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Authentication error: $e');
      }
      return false;
    }
  }

  @override
  Future<GithubTodo> createTodo(GithubTodo todo) async {
    try {
      // Checking if the box for tasks is opened
      if (!Hive.isBoxOpen(_boxNameTodos)) {
        if (kDebugMode) {
          print(
            'Box $_boxNameTodos not opened when creating a task. Opening...',
          );
        }
        await Hive.openBox<GithubTodo>(_boxNameTodos);
      }

      if (kDebugMode) {
        print('Creating a new task for repository: ${todo.repositoryId}');
        print('Task title: ${todo.title}');
      }

      // Creating a new task with a unique ID
      final newTodo = todo.copyWith(
        id: const Uuid().v4(),
        createdAt: DateTime.now(),
      );

      if (kDebugMode) {
        print('Generated task ID: ${newTodo.id}');
      }

      // Saving to local storage
      await _todosBox.put(newTodo.id, newTodo);

      if (kDebugMode) {
        print('Task saved to storage');
        print('Total tasks after adding: ${_todosBox.values.length}');
      }

      return newTodo;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating a task: $e');
      }
      rethrow;
    }
  }

  @override
  Future<bool> deleteTodo(String todoId) async {
    try {
      // Deleting the task from local storage
      await _todosBox.delete(todoId);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting a task: $e');
      }
      return false;
    }
  }

  @override
  Future<String?> getFileContent(String owner, String name, String path) async {
    try {
      // Getting the file content from GitHub API
      final content = await _github.repositories.getContents(
        RepositorySlug(owner, name),
        path,
      );

      // Decoding the content from base64
      if (content.isFile && content.file != null) {
        return content.file!.text;
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting the file content: $e');
      }
      return null;
    }
  }

  @override
  String? getAuthToken() {
    try {
      final tokenBox = Hive.box('auth_tokens');
      return tokenBox.get('github_token') as String?;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting the token: $e');
      }
      return null;
    }
  }

  @override
  Future<String?> getReadmeContent(String owner, String name) async {
    try {
      // Getting the README from GitHub API
      final readme = await _github.repositories.getReadme(
        RepositorySlug(owner, name),
      );

      return readme.text;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting the README: $e');
      }
      return null;
    }
  }

  @override
  Future<entities.GithubRepository> getRepositoryDetails(
    String owner,
    String name,
  ) async {
    try {
      // Checking local storage
      final cachedRepos =
          _repositoriesBox.values
              .where((repo) => repo.owner == owner && repo.name == name)
              .toList();

      if (cachedRepos.isNotEmpty) {
        return cachedRepos.first;
      }

      // If not in cache, get from GitHub API
      final repository = await _github.repositories.getRepository(
        RepositorySlug(owner, name),
      );

      // Mapping to our model
      final repoEntity = _mapRepositoryToEntity(repository);

      // Saving to local storage
      await _repositoriesBox.put(repoEntity.id, repoEntity);

      return repoEntity;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting the repository details: $e');
      }
      rethrow;
    }
  }

  @override
  Future<List<GitHubFile>> getRepositoryContents(
    String owner,
    String name, [
    String? path,
  ]) async {
    try {
      // Getting the repository content from GitHub API
      final content = await _github.repositories.getContents(
        RepositorySlug(owner, name),
        path ?? '',
      );

      if (content.isDirectory && content.tree != null) {
        return content.tree!;
      }

      return [];
    } catch (e) {
      if (kDebugMode) {
        print('Error getting the repository content: $e');
      }
      return [];
    }
  }

  @override
  Future<List<GithubTodo>> getRepositoryTodos(String repositoryId) async {
    try {
      // Checking if the box for tasks is opened
      if (!Hive.isBoxOpen(_boxNameTodos)) {
        if (kDebugMode) {
          print('Box $_boxNameTodos not opened. Opening...');
        }
        await Hive.openBox<GithubTodo>(_boxNameTodos);
      }

      if (kDebugMode) {
        print('Getting tasks for repository with ID: $repositoryId');
        print('Total tasks in storage: ${_todosBox.values.length}');
      }

      // Getting tasks from local storage
      final todos =
          _todosBox.values
              .where((todo) => todo.repositoryId == repositoryId)
              .toList();

      if (kDebugMode) {
        print('Found tasks for repository: ${todos.length}');
      }

      return todos;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting tasks: $e');
      }
      return [];
    }
  }

  @override
  Future<List<entities.GithubRepository>> getUserRepositories() async {
    try {
      // Getting the user's repositories from GitHub API
      final repositories =
          await _github.repositories.listRepositories().toList();

      // Mapping to our model
      final repoEntities = repositories.map(_mapRepositoryToEntity).toList();

      // Saving to local storage
      for (final repo in repoEntities) {
        await _repositoriesBox.put(repo.id, repo);
      }

      return repoEntities;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting the user\'s repositories: $e');
      }

      // Returning cached data on error
      return _repositoriesBox.values.toList();
    }
  }

  @override
  Future<void> logout() async {
    try {
      // Clearing the token from local storage
      final tokenBox = Hive.box('auth_tokens');
      await tokenBox.delete('github_token');

      // Resetting the authentication
      _github.auth = Authentication.anonymous();
    } catch (e) {
      if (kDebugMode) {
        print('Error logging out: $e');
      }
    }
  }

  @override
  Future<bool> syncData() async {
    try {
      // Getting data from GitHub and updating local storage
      await getUserRepositories();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error syncing data: $e');
      }
      return false;
    }
  }

  @override
  Future<GithubTodo> updateTodo(GithubTodo todo) async {
    try {
      // Updating the task in local storage
      await _todosBox.put(todo.id, todo);
      return todo;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating the task: $e');
      }
      rethrow;
    }
  }

  /// Getting all tasks
  Future<List<GithubTodo>> getAllTodos() async {
    try {
      // Checking if the box for tasks is opened
      if (!Hive.isBoxOpen(_boxNameTodos)) {
        if (kDebugMode) {
          print('Box $_boxNameTodos not opened. Opening...');
        }
        await Hive.openBox<GithubTodo>(_boxNameTodos);
      }

      if (kDebugMode) {
        print('Getting all tasks');
        print('Total tasks in storage: ${_todosBox.values.length}');
      }

      // Getting all tasks from local storage
      final todos = _todosBox.values.toList();

      return todos;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting all tasks: $e');
      }
      return [];
    }
  }

  // Helper method for converting the GitHub API model to our model
  entities.GithubRepository _mapRepositoryToEntity(Repository repository) {
    return entities.GithubRepository(
      id: repository.id.toString(),
      name: repository.name,
      description: repository.description,
      owner: repository.owner?.login ?? 'unknown',
      ownerAvatarUrl: repository.owner?.avatarUrl ?? '',
      isPrivate: repository.isPrivate ?? false,
      starCount: repository.stargazersCount ?? 0,
      forkCount: repository.forksCount ?? 0,
      defaultBranch: repository.defaultBranch ?? 'main',
      updatedAt: repository.updatedAt ?? DateTime.now(),
      htmlUrl: repository.htmlUrl ?? '',
      hasIssues: repository.hasIssues ?? false,
      language: repository.language,
    );
  }
}
