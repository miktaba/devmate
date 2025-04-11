import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/github_repositories_provider.dart';
import '../../domain/entities/github_repository.dart';
import 'github_todo_page.dart';

/// Page for displaying tasks of GitHub repository
class GithubRepositoryTodosPage extends ConsumerWidget {
  final String owner;
  final String name;

  const GithubRepositoryTodosPage({
    Key? key,
    required this.owner,
    required this.name,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder(
      future: _getRepositoryDetails(ref),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CupertinoPageScaffold(
            navigationBar: CupertinoNavigationBar(middle: Text('Loading...')),
            child: Center(child: CupertinoActivityIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return CupertinoPageScaffold(
            navigationBar: CupertinoNavigationBar(middle: Text('Error')),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    CupertinoIcons.exclamationmark_circle,
                    color: CupertinoColors.destructiveRed,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Failed to load repository',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error?.toString() ?? 'Unknown error',
                    style: const TextStyle(color: CupertinoColors.systemGrey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  CupertinoButton.filled(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Back'),
                  ),
                ],
              ),
            ),
          );
        }

        final repository = snapshot.data!;
        return GithubTodoPage(
          repositoryId: repository.id,
          repositoryName: repository.name,
        );
      },
    );
  }

  Future<GithubRepository> _getRepositoryDetails(WidgetRef ref) async {
    final repository = ref.read(githubRepositoryServiceProvider);
    final repoDetails = await repository.getRepositoryDetails(owner, name);

    if (repoDetails == null) {
      throw Exception('Repository $owner/$name not found or unavailable');
    }

    return repoDetails;
  }
}
