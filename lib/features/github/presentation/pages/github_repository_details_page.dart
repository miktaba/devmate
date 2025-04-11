import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:github/github.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

import '../../domain/entities/github_repository.dart';
import '../../domain/entities/github_todo.dart';
import '../providers/github_repositories_provider.dart';
import '../providers/github_repository_details_provider.dart';
import '../pages/github_todo_page.dart';

// Provider for retrieving repository tasks
final githubRepositoryTodosProvider =
    FutureProvider.family<List<GithubTodo>, String>((ref, repositoryId) async {
      final repository = ref.read(githubRepositoryServiceProvider);
      return repository.getRepositoryTodos(repositoryId);
    });

class GithubRepositoryDetailsPage extends ConsumerStatefulWidget {
  final String owner;
  final String name;
  final int initialTabIndex;

  const GithubRepositoryDetailsPage({
    super.key,
    required this.owner,
    required this.name,
    this.initialTabIndex = 0,
  });

  @override
  ConsumerState<GithubRepositoryDetailsPage> createState() =>
      _GithubRepositoryDetailsPageState();
}

class _GithubRepositoryDetailsPageState
    extends ConsumerState<GithubRepositoryDetailsPage> {
  late int _selectedTabIndex;
  String? _currentPath;

  @override
  void initState() {
    super.initState();
    _selectedTabIndex = widget.initialTabIndex;
    _currentPath = '';
  }

  @override
  Widget build(BuildContext context) {
    // Getting asynchronous data about the repository
    final repositoryDetailsAsync = ref.watch(
      githubRepositoryDetailsProvider((widget.owner, widget.name)),
    );

    // Getting readme file
    final readmeAsync = ref.watch(
      githubRepositoryReadmeProvider((widget.owner, widget.name)),
    );

    // Getting content of the current directory
    final contentsAsync = ref.watch(
      githubRepositoryContentsProvider((
        widget.owner,
        widget.name,
        _currentPath ?? '',
      )),
    );

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('${widget.owner}/${widget.name}'),
        leading: CupertinoNavigationBarBackButton(
          onPressed: () => context.pop(),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Section for switching between tabs (README, Files, ...)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: CupertinoColors.systemBackground,
                border: Border(
                  bottom: BorderSide(
                    color: CupertinoColors.systemGrey5,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildTabItem(0, 'README'),
                  _buildTabItem(1, 'Files'),
                  _buildTabItem(2, 'Tasks'),
                ],
              ),
            ),

            // Main content
            Expanded(
              child: repositoryDetailsAsync.when(
                data:
                    (repository) =>
                        _buildContent(repository, readmeAsync, contentsAsync),
                loading:
                    () => const Center(child: CupertinoActivityIndicator()),
                error:
                    (error, stack) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
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
                              'Error loading repository',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              error.toString(),
                              style: const TextStyle(
                                color: CupertinoColors.systemGrey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            CupertinoButton.filled(
                              onPressed:
                                  () => ref.refresh(
                                    githubRepositoryDetailsProvider((
                                      widget.owner,
                                      widget.name,
                                    )),
                                  ),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Building the tab item
  Widget _buildTabItem(int index, String title) {
    final isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? CupertinoColors.systemBlue.withOpacity(0.1)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          title,
          style: TextStyle(
            color:
                isSelected ? CupertinoColors.systemBlue : CupertinoColors.label,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // Building the main content depending on the selected tab
  Widget _buildContent(
    GithubRepository repository,
    AsyncValue<String?> readmeAsync,
    AsyncValue<List<GitHubFile>> contentsAsync,
  ) {
    switch (_selectedTabIndex) {
      case 0:
        return _buildReadmeTab(repository, readmeAsync);
      case 1:
        return _buildFilesTab(repository, contentsAsync);
      case 2:
        return GithubTodoPage(
          repositoryId: repository.id,
          repositoryName: repository.name,
        );
      default:
        return const Center(child: Text('Tab not found'));
    }
  }

  // README tab
  Widget _buildReadmeTab(
    GithubRepository repository,
    AsyncValue<String?> readmeAsync,
  ) {
    return readmeAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error:
          (error, stackTrace) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Failed to load README',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  error.toString(),
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    ref.refresh(
                      githubRepositoryReadmeProvider((
                        widget.owner,
                        widget.name,
                      )),
                    );
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
      data: (readmeContent) {
        if (readmeContent == null || readmeContent.isEmpty) {
          return const Center(
            child: Text('No README file found', style: TextStyle(fontSize: 18)),
          );
        }

        // Determine if the content contains HTML tags or is pure markdown
        final bool containsHtmlTags =
            readmeContent.contains('<') &&
            readmeContent.contains('>') &&
            (readmeContent.contains('<p>') ||
                readmeContent.contains('<div>') ||
                readmeContent.contains('<h1>'));

        final String htmlContent =
            containsHtmlTags
                ? readmeContent
                : md.markdownToHtml(
                  readmeContent,
                  extensionSet: md.ExtensionSet.gitHubWeb,
                );

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Html(
              data: htmlContent,
              style: {
                "body": Style(
                  fontSize: FontSize(16),
                  lineHeight: LineHeight(1.5),
                ),
                "h1": Style(
                  fontSize: FontSize(24),
                  fontWeight: FontWeight.bold,
                  margin: Margins.only(top: 16, bottom: 8),
                ),
                "h2": Style(
                  fontSize: FontSize(22),
                  fontWeight: FontWeight.bold,
                  margin: Margins.only(top: 14, bottom: 6),
                ),
                "h3": Style(
                  fontSize: FontSize(20),
                  fontWeight: FontWeight.bold,
                  margin: Margins.only(top: 12, bottom: 4),
                ),
                "p": Style(margin: Margins.only(top: 8, bottom: 8)),
                "a": Style(color: Theme.of(context).colorScheme.primary),
                "code": Style(
                  backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                  padding: HtmlPaddings.symmetric(horizontal: 4, vertical: 2),
                  fontFamily: 'monospace',
                  fontSize: FontSize(14),
                ),
                "pre": Style(
                  backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                  padding: HtmlPaddings.all(8),
                  margin: Margins.symmetric(vertical: 8),
                  fontFamily: 'monospace',
                  fontSize: FontSize(14),
                  whiteSpace: WhiteSpace.pre,
                ),
                "ul, ol": Style(
                  margin: Margins.only(left: 16, top: 8, bottom: 8),
                ),
                "li": Style(margin: Margins.only(bottom: 4)),
                "img": Style(margin: Margins.symmetric(vertical: 8)),
                "blockquote": Style(
                  border: Border(
                    left: BorderSide(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.5),
                      width: 4,
                    ),
                  ),
                  padding: HtmlPaddings.only(left: 12),
                  margin: Margins.symmetric(vertical: 8),
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.8),
                ),
                "table": Style(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                    width: 1,
                  ),
                  margin: Margins.symmetric(vertical: 8),
                ),
                "th, td": Style(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                    width: 1,
                  ),
                  padding: HtmlPaddings.all(8),
                ),
              },
              onLinkTap: (String? url, _, __) {
                if (url != null) {
                  _launchUrl(url);
                }
              },
            ),
          ),
        );
      },
    );
  }

  // Helper method for opening URL
  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (await url_launcher.canLaunchUrl(url)) {
      await url_launcher.launchUrl(
        url,
        mode: url_launcher.LaunchMode.externalApplication,
      );
    }
  }

  // Method for determining the presence of HTML tags in the text
  bool _containsHtmlTags(String text) {
    return text.contains('<') &&
        text.contains('>') &&
        (text.contains('<p>') ||
            text.contains('<div>') ||
            text.contains('<h1>'));
  }

  // Files tab
  Widget _buildFilesTab(
    GithubRepository repository,
    AsyncValue<List<GitHubFile>> contentsAsync,
  ) {
    return Material(
      color: Colors.transparent,
      child: Column(
        children: [
          // Path to the current directory
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Icon(
                  CupertinoIcons.folder,
                  color: CupertinoColors.systemBlue,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  _currentPath == '' ? '/' : _currentPath!,
                  style: const TextStyle(
                    color: CupertinoColors.systemBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Back button (if not in the root directory)
          if (_currentPath != null && _currentPath!.isNotEmpty)
            GestureDetector(
              onTap: () {
                setState(() {
                  final parts = _currentPath!.split('/');
                  parts.removeLast();
                  _currentPath = parts.join('/');
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: CupertinoColors.systemGrey5),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      CupertinoIcons.arrow_left,
                      color: CupertinoColors.systemBlue,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Back',
                      style: TextStyle(color: CupertinoColors.systemBlue),
                    ),
                  ],
                ),
              ),
            ),

          // List of files and directories
          Expanded(
            child: contentsAsync.when(
              data: (contents) {
                if (contents.isEmpty) {
                  return const Center(
                    child: Text(
                      'Empty directory',
                      style: TextStyle(color: CupertinoColors.systemGrey),
                    ),
                  );
                }

                // Sorting the content: first directories, then files
                final sortedContents = [...contents];
                sortedContents.sort((a, b) {
                  if (a.type == 'dir' && b.type != 'dir') return -1;
                  if (a.type != 'dir' && b.type == 'dir') return 1;
                  return a.name!.compareTo(b.name!);
                });

                return ListView.builder(
                  itemCount: sortedContents.length,
                  itemBuilder: (context, index) {
                    final item = sortedContents[index];
                    final isDirectory = item.type == 'dir';

                    return GestureDetector(
                      onTap: () {
                        if (isDirectory) {
                          // Transition to the directory
                          setState(() {
                            _currentPath =
                                _currentPath == ''
                                    ? item.name!
                                    : '$_currentPath/${item.name}';
                          });
                        } else {
                          // Opening the file (will be implemented in the next step)
                          _showFileContent(item);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: CupertinoColors.systemGrey5,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isDirectory
                                  ? CupertinoIcons.folder_fill
                                  : _getFileIcon(item.name!),
                              color:
                                  isDirectory
                                      ? CupertinoColors.systemBlue
                                      : CupertinoColors.systemGrey,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item.name!,
                                style: TextStyle(
                                  color:
                                      isDirectory
                                          ? CupertinoColors.systemBlue
                                          : CupertinoColors.label,
                                  fontWeight:
                                      isDirectory
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                ),
                              ),
                            ),
                            if (isDirectory)
                              const Icon(
                                CupertinoIcons.chevron_right,
                                color: CupertinoColors.systemGrey,
                                size: 16,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CupertinoActivityIndicator()),
              error:
                  (error, stack) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Error loading files',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            error.toString(),
                            style: const TextStyle(
                              color: CupertinoColors.systemGrey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          CupertinoButton(
                            onPressed:
                                () => ref.refresh(
                                  githubRepositoryContentsProvider((
                                    widget.owner,
                                    widget.name,
                                    _currentPath ?? '',
                                  )),
                                ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
            ),
          ),
        ],
      ),
    );
  }

  // Tasks tab
  Widget _buildTodosTab(GithubRepository repository) {
    // Getting the list of repository tasks
    final todosAsync = ref.watch(githubRepositoryTodosProvider(repository.id));

    return todosAsync.when(
      loading: () => const Center(child: CupertinoActivityIndicator()),
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
                const Text(
                  'Error loading tasks',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: const TextStyle(color: CupertinoColors.systemGrey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                CupertinoButton.filled(
                  onPressed:
                      () => ref.invalidate(
                        githubRepositoryTodosProvider(repository.id),
                      ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
      data: (todos) {
        // If there are no tasks, show a placeholder
        if (todos.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  CupertinoIcons.square_list,
                  size: 64,
                  color: CupertinoColors.systemGrey,
                ),
                const SizedBox(height: 16),
                const Text(
                  'No tasks',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Add a new task for this repository',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: CupertinoColors.systemGrey),
                ),
                const SizedBox(height: 24),
                CupertinoButton.filled(
                  onPressed: () {
                    setState(() {
                      _selectedTabIndex = 2; // Switching to the tasks tab
                    });
                  },
                  child: const Text('Go to tasks'),
                ),
              ],
            ),
          );
        }

        // If there are tasks, show their statistics and a button to view them in detail
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tasks statistics
              Row(
                children: [
                  _buildTodoStat(
                    'Total tasks',
                    todos.length.toString(),
                    CupertinoIcons.list_bullet,
                    CupertinoColors.activeBlue,
                  ),
                  const SizedBox(width: 16),
                  _buildTodoStat(
                    'Completed',
                    todos.where((todo) => todo.completed).length.toString(),
                    CupertinoIcons.checkmark_circle,
                    CupertinoColors.activeGreen,
                  ),
                  const SizedBox(width: 16),
                  _buildTodoStat(
                    'In progress',
                    todos.where((todo) => !todo.completed).length.toString(),
                    CupertinoIcons.circle,
                    CupertinoColors.systemOrange,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Show task categories
              const Text(
                'Task categories',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                height: 120,
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _buildCategoriesGrid(todos),
              ),

              const SizedBox(height: 24),

              // Show task priorities
              const Text(
                'Priorities',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                height: 80,
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _buildPrioritiesGrid(todos),
              ),

              const SizedBox(height: 32),

              // Button to go to the full list of tasks
              Center(
                child: CupertinoButton.filled(
                  onPressed: () {
                    setState(() {
                      _selectedTabIndex = 2; // Switching to the tasks tab
                    });
                  },
                  child: const Text('Task management'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Widget for displaying task statistics
  Widget _buildTodoStat(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: color,
              ),
            ),
            Text(label, style: TextStyle(fontSize: 12, color: color)),
          ],
        ),
      ),
    );
  }

  // Widget for displaying task categories
  Widget _buildCategoriesGrid(List<GithubTodo> todos) {
    final categories = TodoCategory.values;
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 2.0,
      ),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final count = todos.where((todo) => todo.category == category).length;

        Color color;
        switch (category) {
          case TodoCategory.feature:
            color = CupertinoColors.activeBlue;
            break;
          case TodoCategory.bug:
            color = CupertinoColors.destructiveRed;
            break;
          case TodoCategory.improvement:
            color = CupertinoColors.activeGreen;
            break;
          case TodoCategory.documentation:
            color = CupertinoColors.systemOrange;
            break;
          case TodoCategory.other:
            color = CupertinoColors.systemGrey;
            break;
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3), width: 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                count.toString(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _getCategoryName(category),
                style: TextStyle(fontSize: 12, color: color),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  // Widget for displaying task priorities
  Widget _buildPrioritiesGrid(List<GithubTodo> todos) {
    final priorities = TodoPriority.values;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children:
          priorities.map((priority) {
            final count =
                todos.where((todo) => todo.priority == priority).length;

            Color color;
            switch (priority) {
              case TodoPriority.low:
                color = CupertinoColors.systemGreen;
                break;
              case TodoPriority.medium:
                color = CupertinoColors.systemOrange;
                break;
              case TodoPriority.high:
                color = CupertinoColors.systemRed;
                break;
            }

            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withOpacity(0.3), width: 1),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      count.toString(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _getPriorityName(priority),
                      style: TextStyle(fontSize: 12, color: color),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
    );
  }

  // Getting the name of the category
  String _getCategoryName(TodoCategory category) {
    switch (category) {
      case TodoCategory.feature:
        return 'Function';
      case TodoCategory.bug:
        return 'Error';
      case TodoCategory.improvement:
        return 'Improvement';
      case TodoCategory.documentation:
        return 'Documentation';
      case TodoCategory.other:
        return 'Other';
    }
  }

  // Getting the name of the priority
  String _getPriorityName(TodoPriority priority) {
    switch (priority) {
      case TodoPriority.low:
        return 'Low';
      case TodoPriority.medium:
        return 'Medium';
      case TodoPriority.high:
        return 'High';
    }
  }

  // Displaying the repository header
  Widget _buildRepositoryHeader(GithubRepository repository) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Repository information
        Row(
          children: [
            // Owner avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: NetworkImage(repository.ownerAvatarUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Repository name
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          repository.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
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
                  Text(
                    repository.owner,
                    style: const TextStyle(
                      fontSize: 14,
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Repository description
        if (repository.description != null &&
            repository.description!.isNotEmpty)
          Text(repository.description!, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 16),
        // Statistics
        Row(
          children: [
            // Language
            if (repository.language != null) ...[
              _buildStatItem(CupertinoIcons.circle_fill, repository.language!),
              const SizedBox(width: 16),
            ],
            // Stars
            _buildStatItem(CupertinoIcons.star_fill, '${repository.starCount}'),
            const SizedBox(width: 16),
            // Forks
            _buildStatItem(
              CupertinoIcons.arrow_branch,
              '${repository.forkCount}',
            ),
          ],
        ),
      ],
    );
  }

  // Statistics item
  Widget _buildStatItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: CupertinoColors.systemGrey),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            color: CupertinoColors.systemGrey,
          ),
        ),
      ],
    );
  }

  // Getting the icon for the file depending on the extension
  IconData _getFileIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();

    switch (extension) {
      case 'dart':
      case 'java':
      case 'kt':
      case 'swift':
      case 'js':
      case 'ts':
      case 'py':
      case 'rb':
      case 'php':
      case 'c':
      case 'cpp':
      case 'cs':
      case 'go':
        return CupertinoIcons.doc_text_fill;
      case 'md':
        return CupertinoIcons.doc_plaintext;
      case 'json':
      case 'yaml':
      case 'yml':
      case 'xml':
      case 'plist':
        return CupertinoIcons.doc_text;
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'gif':
      case 'webp':
      case 'svg':
        return CupertinoIcons.photo;
      case 'mp4':
      case 'mov':
      case 'avi':
        return CupertinoIcons.film;
      case 'mp3':
      case 'wav':
      case 'm4a':
        return CupertinoIcons.music_note;
      case 'pdf':
        return CupertinoIcons.doc_fill;
      case 'zip':
      case 'rar':
      case 'tar':
      case 'gz':
        return CupertinoIcons.archivebox_fill;
      default:
        return CupertinoIcons.doc;
    }
  }

  // Displaying the file content
  void _showFileContent(GitHubFile file) {
    // Getting the file content and displaying it in a modal window
    ref
        .read(
          githubRepositoryFileContentProvider((
            widget.owner,
            widget.name,
            _currentPath == '' ? file.name! : '$_currentPath/${file.name}',
          )).future,
        )
        .then((content) {
          // Displaying the content in a modal window
          if (content != null) {
            showCupertinoModalPopup(
              context: context,
              builder:
                  (context) =>
                      _FileContentModal(fileName: file.name!, content: content),
            );
          } else {
            // Displaying an error message
            showCupertinoDialog(
              context: context,
              builder:
                  (context) => CupertinoAlertDialog(
                    title: const Text('Error'),
                    content: const Text(
                      'Failed to load file content. The file may be too large or have a binary format.',
                    ),
                    actions: [
                      CupertinoDialogAction(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
            );
          }
        });
  }
}

// Modal window for displaying file content
class _FileContentModal extends StatelessWidget {
  final String fileName;
  final String content;

  const _FileContentModal({required this.fileName, required this.content});

  @override
  Widget build(BuildContext context) {
    final extension = fileName.split('.').last.toLowerCase();
    final isMarkdown = extension == 'md';

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // Modal window header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: CupertinoColors.systemGrey5),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  fileName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(
                    CupertinoIcons.xmark_circle_fill,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
              ],
            ),
          ),
          // File content
          Expanded(
            child:
                isMarkdown
                    ? Markdown(data: content)
                    : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: SelectableText(
                        content,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 14,
                        ),
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}
