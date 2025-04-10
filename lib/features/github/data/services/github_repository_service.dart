import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:devmate/features/github/domain/entities/github_repository.dart';
import 'package:devmate/features/github/data/services/github_auth_service.dart';
import 'package:devmate/features/github/domain/entities/github_todo.dart';
import 'package:github/github.dart';
import '../repositories/github_repository_impl.dart';

/// Service for working with GitHub repositories
class GitHubRepositoryService {
  /// GitHub API URL
  static const String _githubApiUrl = 'https://api.github.com';
  final GitHubAuthService _authService = GitHubAuthService();

  /// Getting a list of user repositories
  Future<List<GithubRepository>> getUserRepositories({
    int page = 1,
    int perPage = 30,
    String sort = 'updated',
    String direction = 'desc',
  }) async {
    final token = await _authService.getAccessToken();
    if (token == null) {
      if (kDebugMode) {
        print('GitHub token not found.');
      }
      return [];
    }

    try {
      if (kDebugMode) {
        print(
          'Getting GitHub repositories, token: ${token.substring(0, 5)}...',
        );
      }

      final response = await http.get(
        Uri.parse('$_githubApiUrl/user/repos').replace(
          queryParameters: {
            'page': page.toString(),
            'per_page': perPage.toString(),
            'sort': sort,
            'direction': direction,
          },
        ),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'token $token',
        },
      );

      if (kDebugMode) {
        print('GitHub response code: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (kDebugMode) {
          print('Received repositories: ${data.length}');
        }

        final repos =
            data
                .map(
                  (item) =>
                      GithubRepository.fromJson(item as Map<String, dynamic>),
                )
                .toList();

        return repos;
      } else if (kDebugMode) {
        print(
          'Error during request: [${response.statusCode}] ${response.body}',
        );

        // Check for typical errors
        if (response.statusCode == 401) {
          print('Authorization error. Check the token.');
        } else if (response.statusCode == 403) {
          print(
            'Access denied. The request limit may have been exceeded or the necessary permissions are missing.',
          );
        } else if (response.statusCode == 404) {
          print('Resource not found. Check the URL and request parameters.');
        }
      }

      return [];
    } catch (e) {
      if (kDebugMode) {
        print('Error during getting repositories: $e');
      }
      return [];
    }
  }

  /// Search repositories by query
  Future<List<GithubRepository>> searchRepositories(
    String query, {
    int page = 1,
    int perPage = 30,
    String sort = 'stars',
    String order = 'desc',
  }) async {
    final token = await _authService.getAccessToken();
    if (token == null) return [];

    try {
      final response = await http.get(
        Uri.parse('$_githubApiUrl/search/repositories').replace(
          queryParameters: {
            'q': query,
            'page': page.toString(),
            'per_page': perPage.toString(),
            'sort': sort,
            'order': order,
          },
        ),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'token $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> items = data['items'] as List<dynamic>;
        return items
            .map(
              (item) => GithubRepository.fromJson(item as Map<String, dynamic>),
            )
            .toList();
      }

      return [];
    } catch (e) {
      if (kDebugMode) {
        print('Error during searching repositories: $e');
      }
      return [];
    }
  }

  /// Getting detailed information about a repository
  Future<GithubRepository?> getRepositoryDetails(
    String owner,
    String repo,
  ) async {
    final token = await _authService.getAccessToken();
    if (token == null) return null;

    try {
      final response = await http.get(
        Uri.parse('$_githubApiUrl/repos/$owner/$repo'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'token $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return GithubRepository.fromJson(data);
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error during getting repository details: $e');
      }
      return null;
    }
  }

  /// Synchronizes data with GitHub
  Future<bool> syncData() async {
    try {
      // Get the list of repositories and update the cache
      await getUserRepositories();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error during synchronizing data: $e');
      }
      return false;
    }
  }

  /// Creating a new repository
  Future<GithubRepository?> createRepository({
    required String name,
    String? description,
    bool isPrivate = false,
    bool hasIssues = true,
    bool hasProjects = true,
    bool hasWiki = true,
    String? defaultBranch,
  }) async {
    final token = await _authService.getAccessToken();
    if (token == null) return null;

    try {
      final response = await http.post(
        Uri.parse('$_githubApiUrl/user/repos'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'token $token',
        },
        body: json.encode({
          'name': name,
          'description': description,
          'private': isPrivate,
          'has_issues': hasIssues,
          'has_projects': hasProjects,
          'has_wiki': hasWiki,
          'default_branch': defaultBranch,
        }),
      );

      if (response.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(response.body);
        return GithubRepository.fromJson(data);
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error during creating repository: $e');
      }
      return null;
    }
  }

  /// Getting tasks for a specific repository
  Future<List<GithubTodo>> getRepositoryTodos(String repositoryId) async {
    try {
      // Get a repository instance and request tasks
      final repositoryImpl = GithubRepositoryImpl();
      final todos = await repositoryImpl.getRepositoryTodos(repositoryId);

      if (kDebugMode) {
        print('Received ${todos.length} tasks for repository $repositoryId');
      }

      return todos;
    } catch (e) {
      if (kDebugMode) {
        print('Error during getting tasks for repository: $e');
      }
      return [];
    }
  }

  /// Getting README file for a repository
  Future<String?> getReadmeContent(String owner, String name) async {
    final token = await _authService.getAccessToken();
    if (token == null) return null;

    try {
      final response = await http.get(
        Uri.parse('$_githubApiUrl/repos/$owner/$name/readme'),
        headers: {
          'Accept': 'application/vnd.github.raw+json',
          'Authorization': 'token $token',
        },
      );

      if (response.statusCode == 200) {
        return response.body;
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error during getting README: $e');
      }
      return null;
    }
  }

  /// Getting the contents of a repository directory
  Future<List<GitHubFile>> getRepositoryContents(
    String owner,
    String name,
    String path,
  ) async {
    final token = await _authService.getAccessToken();
    if (token == null) return [];

    try {
      final response = await http.get(
        Uri.parse('$_githubApiUrl/repos/$owner/$name/contents/$path'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'token $token',
        },
      );

      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('Received response with a list of files');
        }

        final body = response.body;
        List<dynamic> data;

        // Check if the response is an array (directory) or an object (file)
        try {
          data = json.decode(body) as List<dynamic>;
        } catch (e) {
          // If it's not a list, it's probably a file content
          if (kDebugMode) {
            print('Response is not a list, probably a file: $e');
          }
          return [];
        }

        // Convert the JSON response to GitHubFile objects
        final List<GitHubFile> files = [];
        for (final item in data) {
          final file = GitHubFile();
          file.name = item['name'];
          file.path = item['path'];
          file.sha = item['sha'];
          file.size = item['size'];
          file.type = item['type'];
          files.add(file);
        }

        if (kDebugMode) {
          print('Processed ${files.length} files/directories');
        }

        return files;
      } else {
        if (kDebugMode) {
          print('Error response: ${response.statusCode} - ${response.body}');
        }
      }

      return [];
    } catch (e) {
      if (kDebugMode) {
        print('Error during getting directory contents: $e');
      }
      return [];
    }
  }

  /// Getting the content of a file
  Future<String?> getFileContent(String owner, String name, String path) async {
    final token = await _authService.getAccessToken();
    if (token == null) return null;

    try {
      final response = await http.get(
        Uri.parse('$_githubApiUrl/repos/$owner/$name/contents/$path'),
        headers: {
          'Accept': 'application/vnd.github.raw+json',
          'Authorization': 'token $token',
        },
      );

      if (response.statusCode == 200) {
        return response.body;
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error during getting file content: $e');
      }
      return null;
    }
  }

  /// Getting all tasks
  Future<List<GithubTodo>> getAllTodos() async {
    try {
      // Get an instance of the repository and request all tasks
      final repositoryImpl = GithubRepositoryImpl();
      final todos = await repositoryImpl.getAllTodos();

      if (kDebugMode) {
        print('Received ${todos.length} tasks');
      }

      return todos;
    } catch (e) {
      if (kDebugMode) {
        print('Error during getting all tasks: $e');
      }
      return [];
    }
  }

  /// Updating a task
  Future<GithubTodo> updateTodo(GithubTodo todo) async {
    try {
      final repositoryImpl = GithubRepositoryImpl();
      final updatedTodo = await repositoryImpl.updateTodo(todo);

      if (kDebugMode) {
        print('Task updated: ${updatedTodo.id}');
      }

      return updatedTodo;
    } catch (e) {
      if (kDebugMode) {
        print('Error during updating task: $e');
      }
      rethrow;
    }
  }

  /// Deleting a task
  Future<bool> deleteTodo(String todoId) async {
    try {
      final repositoryImpl = GithubRepositoryImpl();
      final result = await repositoryImpl.deleteTodo(todoId);

      if (kDebugMode) {
        print('Task deleted: $todoId');
      }

      return result;
    } catch (e) {
      if (kDebugMode) {
        print('Error during deleting task: $e');
      }
      return false;
    }
  }

  /// Creating a new task
  Future<GithubTodo> createTodo(GithubTodo todo) async {
    try {
      final repositoryImpl = GithubRepositoryImpl();
      final newTodo = await repositoryImpl.createTodo(todo);

      if (kDebugMode) {
        print('Task created: ${newTodo.id}');
      }

      return newTodo;
    } catch (e) {
      if (kDebugMode) {
        print('Error during creating task: $e');
      }
      rethrow; // Pass the error further for processing in the UI
    }
  }
}
