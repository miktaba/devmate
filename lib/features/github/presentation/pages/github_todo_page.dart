import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';

import '../../domain/entities/github_todo.dart';
import '../providers/github_repositories_provider.dart';
import '../providers/github_todos_provider.dart';

/// Screen for viewing and managing repository tasks
class GithubTodoPage extends ConsumerStatefulWidget {
  final String repositoryId;
  final String repositoryName;

  const GithubTodoPage({
    super.key,
    required this.repositoryId,
    required this.repositoryName,
  });

  @override
  ConsumerState<GithubTodoPage> createState() => _GithubTodoPageState();
}

class _GithubTodoPageState extends ConsumerState<GithubTodoPage> {
  @override
  void initState() {
    super.initState();
    // Make sure the general task list is loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(githubAllTodosProvider.notifier).loadTodos();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watch for task changes through provider
    final todosAsync = ref.watch(
      githubRepositoryTodosProvider(widget.repositoryId),
    );

    return Material(
      color: Colors.transparent,
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
                          githubRepositoryTodosProvider(widget.repositoryId),
                        ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
        data: (todos) {
          if (todos.isEmpty) {
            return _EmptyTodosList();
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Task List',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(CupertinoIcons.add, size: 18),
                          SizedBox(width: 4),
                          Text('Add'),
                        ],
                      ),
                      onPressed: () => _showAddTodoSheet(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _TodosList(
                  todos: todos,
                  onTodoUpdated: (todo) {
                    ref.read(githubAllTodosProvider.notifier).updateTodo(todo);
                  },
                  onTodoDeleted: (todoId) {
                    ref
                        .read(githubAllTodosProvider.notifier)
                        .deleteTodo(todoId);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddTodoSheet(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder:
          (context) => SizedBox(
            height: MediaQuery.of(context).size.height * 0.85,
            child: _AddTodoSheet(
              repositoryId: widget.repositoryId,
              onTodoAdded: () {
                // Update list when task is added
                ref.invalidate(
                  githubRepositoryTodosProvider(widget.repositoryId),
                );
              },
            ),
          ),
    );
  }
}

class _EmptyTodosList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Task List',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(CupertinoIcons.add, size: 18),
                        SizedBox(width: 4),
                        Text('Add'),
                      ],
                    ),
                    onPressed: () {
                      final ancestorWidget =
                          context
                              .findAncestorWidgetOfExactType<GithubTodoPage>();
                      if (ancestorWidget == null ||
                          ancestorWidget.repositoryId.isEmpty) {
                        if (kDebugMode) {
                          print(
                            'Error: GithubTodoPage not found or repositoryId is empty',
                          );
                        }
                        return;
                      }

                      showCupertinoModalPopup(
                        context: context,
                        builder:
                            (context) => SizedBox(
                              height: MediaQuery.of(context).size.height * 0.85,
                              child: _AddTodoSheet(
                                repositoryId: ancestorWidget.repositoryId,
                                onTodoAdded: () {
                                  final state =
                                      context
                                          .findAncestorStateOfType<
                                            _GithubTodoPageState
                                          >();
                                  if (state != null) {
                                    // Update task list through Riverpod instead of direct method call
                                    final repositoryId =
                                        context
                                            .findAncestorWidgetOfExactType<
                                              GithubTodoPage
                                            >()
                                            ?.repositoryId;
                                    if (repositoryId != null) {
                                      // Use ProviderScope to access ref
                                      final providerContainer =
                                          ProviderScope.containerOf(context);
                                      providerContainer.invalidate(
                                        githubRepositoryTodosProvider(
                                          repositoryId,
                                        ),
                                      );
                                    }
                                  }
                                },
                              ),
                            ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.square_list,
                      size: 64,
                      color: CupertinoColors.systemGrey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No tasks',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Add a new task for this repository',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: CupertinoColors.systemGrey),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodosList extends StatelessWidget {
  final List<GithubTodo> todos;
  final Function(GithubTodo) onTodoUpdated;
  final Function(String) onTodoDeleted;

  const _TodosList({
    required this.todos,
    required this.onTodoUpdated,
    required this.onTodoDeleted,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: todos.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final todo = todos[index];
        return _TodoCard(
          todo: todo,
          onTodoUpdated: onTodoUpdated,
          onTodoDeleted: onTodoDeleted,
        );
      },
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
    return GestureDetector(
      onTap: () => _showEditTodoSheet(context),
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
                // Completed check box
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: Icon(
                    todo.completed
                        ? CupertinoIcons.checkmark_circle_fill
                        : CupertinoIcons.circle,
                    color:
                        todo.completed
                            ? CupertinoColors.activeBlue
                            : CupertinoColors.systemGrey,
                  ),
                  onPressed: () {
                    onTodoUpdated(todo.copyWith(completed: !todo.completed));
                  },
                ),
              ],
            ),
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
                // Creation date
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
                  child: const Icon(
                    CupertinoIcons.delete,
                    color: CupertinoColors.systemGrey,
                    size: 20,
                  ),
                  onPressed: () {
                    _showDeleteConfirmation(context, todo);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
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

  void _showEditTodoSheet(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder:
          (context) => SizedBox(
            height: MediaQuery.of(context).size.height * 0.85,
            child: _AddTodoSheet(
              repositoryId: todo.repositoryId,
              todoToEdit: todo,
              onTodoAdded: () {
                // Nothing to do, as editing is handled through onTodoUpdated
              },
              onTodoUpdated: onTodoUpdated,
            ),
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

class _AddTodoSheet extends ConsumerStatefulWidget {
  final String repositoryId;
  final VoidCallback onTodoAdded;
  final GithubTodo? todoToEdit;
  final Function(GithubTodo)? onTodoUpdated;

  const _AddTodoSheet({
    required this.repositoryId,
    required this.onTodoAdded,
    this.todoToEdit,
    this.onTodoUpdated,
  });

  @override
  ConsumerState<_AddTodoSheet> createState() => _AddTodoSheetState();
}

class _AddTodoSheetState extends ConsumerState<_AddTodoSheet> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  TodoPriority _selectedPriority = TodoPriority.medium;
  TodoCategory _selectedCategory = TodoCategory.other;
  DateTime? _selectedDueDate;
  String? _selectedFilePath;
  bool _isCompleted = false;
  String? _todoId;

  bool get _isEditMode => widget.todoToEdit != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      _initializeFormWithTodoData();
    }
  }

  void _initializeFormWithTodoData() {
    final todo = widget.todoToEdit!;
    _titleController.text = todo.title;
    _descriptionController.text = todo.description;
    _selectedPriority = todo.priority;
    _selectedCategory = todo.category;
    _selectedDueDate = todo.dueDate;
    _selectedFilePath = todo.relatedFilePath;
    _isCompleted = todo.completed;
    _todoId = todo.id;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      supportedLocales: const [Locale('en')],
      localizationsDelegates: const [
        DefaultMaterialLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
        DefaultCupertinoLocalizations.delegate,
      ],
      home: Material(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: CupertinoColors.systemBackground,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Text('Cancel'),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Text(
                      _isEditMode ? 'Edit Task' : 'New Task',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: _isEditMode ? _updateTodo : _createTodo,
                      child: Text(_isEditMode ? 'Save' : 'Create'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Title
                CupertinoTextField(
                  controller: _titleController,
                  placeholder: 'Title',
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: CupertinoColors.systemGrey4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 12),
                // Description
                CupertinoTextField(
                  controller: _descriptionController,
                  placeholder: 'Description',
                  padding: const EdgeInsets.all(12),
                  maxLines: 4,
                  decoration: BoxDecoration(
                    border: Border.all(color: CupertinoColors.systemGrey4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 16),
                // Priority and category
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Priority',
                            style: TextStyle(
                              fontSize: 14,
                              color: CupertinoColors.systemGrey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: CupertinoColors.systemGrey4,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: _showPriorityActionSheet,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(_getPriorityName(_selectedPriority)),
                                    const Icon(
                                      CupertinoIcons.chevron_down,
                                      size: 14,
                                      color: CupertinoColors.systemGrey,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Category',
                            style: TextStyle(
                              fontSize: 14,
                              color: CupertinoColors.systemGrey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: CupertinoColors.systemGrey4,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: _showCategoryActionSheet,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(_getCategoryName(_selectedCategory)),
                                    const Icon(
                                      CupertinoIcons.chevron_down,
                                      size: 14,
                                      color: CupertinoColors.systemGrey,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Due date
                GestureDetector(
                  onTap: _showDatePicker,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: CupertinoColors.systemGrey4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedDueDate == null
                              ? 'Due date'
                              : 'Due: ${_formatDate(_selectedDueDate!)}',
                          style: TextStyle(
                            color:
                                _selectedDueDate == null
                                    ? CupertinoColors.placeholderText
                                    : CupertinoColors.label,
                          ),
                        ),
                        Icon(
                          CupertinoIcons.calendar,
                          color: CupertinoColors.systemGrey,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (_isEditMode) ...[
                  const SizedBox(height: 16),
                  // Task status (only for edit mode)
                  Row(
                    children: [
                      const Text(
                        'Task status:',
                        style: TextStyle(
                          fontSize: 16,
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
                      const SizedBox(width: 8),
                      CupertinoSwitch(
                        value: _isCompleted,
                        onChanged: (value) {
                          setState(() {
                            _isCompleted = value;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isCompleted ? 'Completed' : 'In progress',
                        style: TextStyle(
                          fontSize: 16,
                          color:
                              _isCompleted
                                  ? CupertinoColors.activeGreen
                                  : CupertinoColors.systemGrey,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                // Prevent keyboard from covering
                Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPriorityActionSheet() {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return CupertinoActionSheet(
          title: const Text('Select priority'),
          actions:
              TodoPriority.values.map((priority) {
                return CupertinoActionSheetAction(
                  onPressed: () {
                    setState(() {
                      _selectedPriority = priority;
                    });
                    Navigator.pop(context);
                  },
                  isDefaultAction: priority == _selectedPriority,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _getPriorityIcon(priority),
                        color: _getPriorityColor(priority),
                      ),
                      const SizedBox(width: 10),
                      Text(_getPriorityName(priority)),
                    ],
                  ),
                );
              }).toList(),
          cancelButton: CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
        );
      },
    );
  }

  void _showCategoryActionSheet() {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return CupertinoActionSheet(
          title: const Text('Select category'),
          actions:
              TodoCategory.values.map((category) {
                return CupertinoActionSheetAction(
                  onPressed: () {
                    setState(() {
                      _selectedCategory = category;
                    });
                    Navigator.pop(context);
                  },
                  isDefaultAction: category == _selectedCategory,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _getCategoryIcon(category),
                        color: _getCategoryColor(category),
                      ),
                      const SizedBox(width: 10),
                      Text(_getCategoryName(category)),
                    ],
                  ),
                );
              }).toList(),
          cancelButton: CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
        );
      },
    );
  }

  Future<void> _createTodoAndClose() async {
    if (_titleController.text.trim().isEmpty) {
      _showErrorMessage('Title cannot be empty');
      return;
    }

    final todo = GithubTodo(
      id: const Uuid().v4(),
      repositoryId: widget.repositoryId,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      createdAt: DateTime.now(),
      dueDate: _selectedDueDate,
      priority: _selectedPriority,
      category: _selectedCategory,
      relatedFilePath: _selectedFilePath,
      completed: false,
    );

    try {
      // Add task through provider
      await ref.read(githubAllTodosProvider.notifier).addTodo(todo);

      // Explicitly update task provider to refresh UI immediately
      ref.invalidate(githubRepositoryTodosProvider(widget.repositoryId));

      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onTodoAdded();
    } catch (error) {
      debugPrint('Error creating task: $error');
    }
  }

  Future<void> _updateTodoAndClose() async {
    if (_titleController.text.trim().isEmpty) {
      _showErrorMessage('Title cannot be empty');
      return;
    }

    if (_todoId == null || widget.todoToEdit == null) {
      _showErrorMessage('Error updating task: task data not found');
      return;
    }

    final updatedTodo = widget.todoToEdit!.copyWith(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      dueDate: _selectedDueDate,
      priority: _selectedPriority,
      category: _selectedCategory,
      relatedFilePath: _selectedFilePath,
      completed: _isCompleted,
    );

    if (widget.onTodoUpdated != null) {
      widget.onTodoUpdated!(updatedTodo);
      Navigator.of(context).pop();
    } else {
      try {
        // Update task through provider
        await ref.read(githubAllTodosProvider.notifier).updateTodo(updatedTodo);

        // Explicitly update task provider
        ref.invalidate(githubRepositoryTodosProvider(widget.repositoryId));

        if (!mounted) return;
        Navigator.of(context).pop();
        widget.onTodoAdded();
      } catch (error) {
        debugPrint('Error updating task: $error');
      }
    }
  }

  void _createTodo() {
    _createTodoAndClose();
  }

  void _updateTodo() {
    _updateTodoAndClose();
  }

  void _showErrorMessage(String message) {
    // Save current context
    final currentContext = context;
    showCupertinoDialog(
      context: currentContext,
      builder:
          (dialogContext) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text(message),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

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

  IconData _getPriorityIcon(TodoPriority priority) {
    switch (priority) {
      case TodoPriority.low:
        return CupertinoIcons.arrow_down;
      case TodoPriority.medium:
        return CupertinoIcons.minus;
      case TodoPriority.high:
        return CupertinoIcons.arrow_up;
    }
  }

  Color _getPriorityColor(TodoPriority priority) {
    switch (priority) {
      case TodoPriority.low:
        return CupertinoColors.systemGreen;
      case TodoPriority.medium:
        return CupertinoColors.systemOrange;
      case TodoPriority.high:
        return CupertinoColors.systemRed;
    }
  }

  String _getCategoryName(TodoCategory category) {
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

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }

  IconData _getCategoryIcon(TodoCategory category) {
    switch (category) {
      case TodoCategory.feature:
        return CupertinoIcons.star;
      case TodoCategory.bug:
        return CupertinoIcons.ant;
      case TodoCategory.improvement:
        return CupertinoIcons.arrow_up_circle;
      case TodoCategory.documentation:
        return CupertinoIcons.doc_text;
      case TodoCategory.other:
        return CupertinoIcons.question_circle;
    }
  }

  Color _getCategoryColor(TodoCategory category) {
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

  void _showDatePicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        DateTime tempPickedDate =
            _selectedDueDate ?? DateTime.now().add(const Duration(days: 7));

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              color: CupertinoColors.systemBackground.resolveFrom(context),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Cancel'),
                  ),
                  CupertinoButton(
                    onPressed: () {
                      setState(() {
                        _selectedDueDate = tempPickedDate;
                      });
                      Navigator.pop(context);
                    },
                    child: const Text('Done'),
                  ),
                ],
              ),
            ),
            Container(
              height: 216,
              padding: const EdgeInsets.only(top: 6),
              color: CupertinoColors.systemBackground.resolveFrom(context),
              child: SafeArea(
                top: false,
                child: CupertinoDatePicker(
                  initialDateTime: tempPickedDate,
                  mode: CupertinoDatePickerMode.date,
                  onDateTimeChanged: (DateTime newDate) {
                    tempPickedDate = newDate;
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
