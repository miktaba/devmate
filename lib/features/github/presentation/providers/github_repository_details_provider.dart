import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:github/github.dart';

import '../../domain/entities/github_repository.dart';
import '../../data/repositories/github_repository_impl.dart';
import 'github_repositories_provider.dart';

/// Provider to retrieve GitHub repository details
final githubRepositoryDetailsProvider =
    FutureProvider.family<GithubRepository, (String, String)>((
      ref,
      params,
    ) async {
      final (owner, name) = params;
      try {
        final repository = ref.read(githubRepositoryServiceProvider);
        final repoDetails = await repository.getRepositoryDetails(owner, name);

        if (repoDetails == null) {
          throw Exception('Repository not found or unavailable');
        }

        return repoDetails;
      } catch (e) {
        if (kDebugMode) {
          print('Error retrieving repository details: $e');
        }
        rethrow;
      }
    });

/// Provider to retrieve the README file of the GitHub repository
final githubRepositoryReadmeProvider =
    FutureProvider.family<String?, (String, String)>((ref, params) async {
      final (owner, name) = params;
      try {
        final repository = ref.read(githubRepositoryServiceProvider);
        return await repository.getReadmeContent(owner, name);
      } catch (e) {
        if (kDebugMode) {
          print('Error retrieving README: $e');
        }
        return null;
      }
    });

/// Provider to retrieve the contents of the GitHub repository directory
final githubRepositoryContentsProvider =
    FutureProvider.family<List<GitHubFile>, (String, String, String)>((
      ref,
      params,
    ) async {
      final (owner, name, path) = params;
      try {
        final repository = ref.read(githubRepositoryServiceProvider);
        return await repository.getRepositoryContents(owner, name, path);
      } catch (e) {
        if (kDebugMode) {
          print('Error retrieving directory contents: $e');
        }
        return [];
      }
    });

/// Provider to retrieve the content of the GitHub repository file
final githubRepositoryFileContentProvider =
    FutureProvider.family<String?, (String, String, String)>((
      ref,
      params,
    ) async {
      final (owner, name, path) = params;
      try {
        final repository = ref.read(githubRepositoryServiceProvider);
        return await repository.getFileContent(owner, name, path);
      } catch (e) {
        if (kDebugMode) {
          print('Error retrieving file content: $e');
        }
        return null;
      }
    });
