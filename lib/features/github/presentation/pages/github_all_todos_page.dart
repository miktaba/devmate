import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/github_todo.dart';
import '../providers/github_repositories_provider.dart';
import '../providers/github_todos_provider.dart';

/// Page for displaying all tasks from all repositories
class GithubAllTodosPage extends ConsumerStatefulWidget {
  const GithubAllTodosPage({super.key});

  @override
  ConsumerState<GithubAllTodosPage> createState() => _GithubAllTodosPageState();
}

class _GithubAllTodosPageState extends ConsumerState<GithubAllTodosPage> {
  @override
  Widget build(BuildContext context) {
    final todosAsync = ref.watch(githubAllTodosProvider);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('All tasks'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Debug information about the number of tasks
            todosAsync.maybeWhen(
              data:
                  (todos) => Text(
                    '${todos.length}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: CupertinoColors.activeBlue,
                    ),
                  ),
              orElse: () => const SizedBox.shrink(),
            ),
            const SizedBox(width: 8),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed:
                  () => ref.read(githubAllTodosProvider.notifier).loadTodos(),
              child: const Icon(CupertinoIcons.refresh),
            ),
          ],
        ),
      ),
      child: SafeArea(
        child: todosAsync.when(
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
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      style: const TextStyle(color: CupertinoColors.systemGrey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    CupertinoButton.filled(
                      onPressed: () => ref.refresh(githubAllTodosProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
          data: (todos) {
            if (todos.isEmpty) {
              return _buildEmptyState();
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: todos.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final todo = todos[index];
                return _TodoCard(
                  todo: todo,
                  onTodoUpdated: _updateTodo,
                  onTodoDeleted: _deleteTodo,
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _updateTodo(GithubTodo todo) {
    // Using provider to update task
    ref.read(githubAllTodosProvider.notifier).updateTodo(todo);
  }

  void _deleteTodo(String todoId) {
    // Using provider to delete task
    ref.read(githubAllTodosProvider.notifier).deleteTodo(todoId);
  }

  Widget _buildEmptyState() {
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
            'Tasks are not created in any repository yet',
            textAlign: TextAlign.center,
            style: TextStyle(color: CupertinoColors.systemGrey),
          ),
        ],
      ),
    );
  }
}

class _TodoCard extends StatelessWidget {
  final GithubTodo todo;
  final Function(GithubTodo) onTodoUpdated;
  final Function(String) onTodoDeleted;

  const _TodoCard({
    required this.todo,
    required this.onTodoUpdated,
    required this.onTodoDeleted,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        // Getting information about the repository
        final repository = ref.watch(
          githubRepositoryByIdProvider(todo.repositoryId),
        );

        return Container(
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
                  // Task category
                  _CategoryBadge(category: todo.category),
                  const SizedBox(width: 8),
                  // Priority
                  _PriorityIndicator(priority: todo.priority),
                  const SizedBox(width: 8),
                  // Title
                  Expanded(
                    child: Text(
                      todo.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        decoration:
                            todo.completed ? TextDecoration.lineThrough : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Completed checkbox
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      onTodoUpdated(todo.copyWith(completed: !todo.completed));
                    },
                    child: Icon(
                      todo.completed
                          ? CupertinoIcons.checkmark_circle_fill
                          : CupertinoIcons.circle,
                      color:
                          todo.completed
                              ? CupertinoColors.activeBlue
                              : CupertinoColors.systemGrey,
                    ),
                  ),
                ],
              ),

              // Information about the repository
              if (repository != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      CupertinoIcons.folder,
                      size: 12,
                      color: CupertinoColors.systemGrey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${repository.owner}/${repository.name}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: CupertinoColors.activeBlue,
                      ),
                    ),
                  ],
                ),
              ],

              if (todo.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  todo.description,
                  style: const TextStyle(
                    color: CupertinoColors.systemGrey,
                    fontSize: 14,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Created date
                  Text(
                    'Created: ${_formatDate(todo.createdAt)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                  // Due date
                  if (todo.dueDate != null)
                    Text(
                      'Due: ${_formatDate(todo.dueDate!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            _isDueDatePassed(todo.dueDate!)
                                ? CupertinoColors.destructiveRed
                                : CupertinoColors.systemGrey,
                        fontWeight:
                            _isDueDatePassed(todo.dueDate!)
                                ? FontWeight.bold
                                : FontWeight.normal,
                      ),
                    ),
                  // Delete button
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      _showDeleteConfirmation(context, todo);
                    },
                    child: const Icon(
                      CupertinoIcons.delete,
                      color: CupertinoColors.systemGrey,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context, GithubTodo todo) {
    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: const Text('Delete task?'),
            content: const Text('This action cannot be undone.'),
            actions: [
              CupertinoDialogAction(
                child: const Text('Cancel'),
                onPressed: () => Navigator.of(context).pop(),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                onPressed: () {
                  Navigator.of(context).pop();
                  onTodoDeleted(todo.id);
                },
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }

  bool _isDueDatePassed(DateTime dueDate) {
    final now = DateTime.now();
    return dueDate.isBefore(now);
  }
}

class _CategoryBadge extends StatelessWidget {
  final TodoCategory category;

  const _CategoryBadge({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getCategoryColor(),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _getCategoryName(),
        style: const TextStyle(
          color: CupertinoColors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getCategoryColor() {
    switch (category) {
      case TodoCategory.feature:
        return CupertinoColors.activeBlue;
      case TodoCategory.bug:
        return CupertinoColors.destructiveRed;
      case TodoCategory.improvement:
        return CupertinoColors.activeGreen;
      case TodoCategory.documentation:
        return CupertinoColors.systemOrange;
      case TodoCategory.other:
        return CupertinoColors.systemGrey;
    }
  }

  String _getCategoryName() {
    switch (category) {
      case TodoCategory.feature:
        return 'Feature';
      case TodoCategory.bug:
        return 'Bug';
      case TodoCategory.improvement:
        return 'Improvement';
      case TodoCategory.documentation:
        return 'Documentation';
      case TodoCategory.other:
        return 'Other';
    }
  }
}

class _PriorityIndicator extends StatelessWidget {
  final TodoPriority priority;

  const _PriorityIndicator({required this.priority});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String tooltip;

    switch (priority) {
      case TodoPriority.low:
        color = CupertinoColors.systemGreen;
        tooltip = 'Low';
        break;
      case TodoPriority.medium:
        color = CupertinoColors.systemOrange;
        tooltip = 'Medium';
        break;
      case TodoPriority.high:
        color = CupertinoColors.systemRed;
        tooltip = 'High';
        break;
    }

    return Tooltip(
      message: tooltip,
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
