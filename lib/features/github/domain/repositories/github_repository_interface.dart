import 'package:github/github.dart';
import 'package:flutter/foundation.dart';

import '../entities/github_repository.dart';
import '../entities/github_todo.dart';

/// Interface for repository for working with GitHub API
abstract class IGithubRepository {
  /// Get list of user repositories
  Future<List<GithubRepository>> getUserRepositories();

  /// Get detailed information about the repository
  Future<GithubRepository> getRepositoryDetails(String owner, String name);

  /// Get content of README file of the repository
  Future<String?> getReadmeContent(String owner, String name);

  /// Get structure of files and directories of the repository
  Future<List<GitHubFile>> getRepositoryContents(
    String owner,
    String name, [
    String? path,
  ]);

  /// Get content of the file
  Future<String?> getFileContent(String owner, String name, String path);

  /// Get list of tasks for the repository
  Future<List<GithubTodo>> getRepositoryTodos(String repositoryId);

  /// Get all tasks from all repositories
  Future<List<GithubTodo>> getAllTodos();

  /// Create new task for the repository
  Future<GithubTodo> createTodo(GithubTodo todo);

  /// Update task
  Future<GithubTodo> updateTodo(GithubTodo todo);

  /// Delete task
  Future<bool> deleteTodo(String todoId);

  /// Authenticate through GitHub OAuth
  Future<bool> authenticate(String token);

  /// Get current authentication token
  String? getAuthToken();

  /// Logout from account
  Future<void> logout();

  /// Synchronize local data with GitHub
  Future<bool> syncData();
}
