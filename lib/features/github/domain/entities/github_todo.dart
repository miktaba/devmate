import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

part 'github_todo.g.dart';

/// Task priority
@HiveType(typeId: 4)
enum TodoPriority {
  @HiveField(0)
  low, // Low

  @HiveField(1)
  medium, // Medium

  @HiveField(2)
  high, // High
}

/// Task category
@HiveType(typeId: 5)
enum TodoCategory {
  @HiveField(0)
  feature, // New feature

  @HiveField(1)
  bug, // Bug fix

  @HiveField(2)
  improvement, // Improvement

  @HiveField(3)
  documentation, // Documentation

  @HiveField(4)
  other, // Other
}

/// Model of task for GitHub repository
@HiveType(typeId: 6)
class GithubTodo {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String repositoryId;

  @HiveField(2)
  final String title;

  @HiveField(3)
  final String description;

  @HiveField(4)
  final bool completed;

  @HiveField(5)
  final DateTime createdAt;

  @HiveField(6)
  final DateTime? dueDate;

  @HiveField(7)
  final TodoPriority priority;

  @HiveField(8)
  final TodoCategory category;

  @HiveField(9)
  final String? relatedFilePath;

  @HiveField(10)
  final int? issueNumber;

  GithubTodo({
    required this.id,
    required this.repositoryId,
    required this.title,
    required this.description,
    required this.createdAt,
    this.completed = false,
    this.dueDate,
    this.priority = TodoPriority.medium,
    this.category = TodoCategory.other,
    this.relatedFilePath,
    this.issueNumber,
  });

  GithubTodo copyWith({
    String? id,
    String? repositoryId,
    String? title,
    String? description,
    bool? completed,
    DateTime? createdAt,
    DateTime? dueDate,
    TodoPriority? priority,
    TodoCategory? category,
    String? relatedFilePath,
    int? issueNumber,
  }) {
    return GithubTodo(
      id: id ?? this.id,
      repositoryId: repositoryId ?? this.repositoryId,
      title: title ?? this.title,
      description: description ?? this.description,
      completed: completed ?? this.completed,
      createdAt: createdAt ?? this.createdAt,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      relatedFilePath: relatedFilePath ?? this.relatedFilePath,
      issueNumber: issueNumber ?? this.issueNumber,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'repositoryId': repositoryId,
      'title': title,
      'description': description,
      'completed': completed,
      'createdAt': createdAt.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'priority': priority.toString().split('.').last,
      'category': category.toString().split('.').last,
      'relatedFilePath': relatedFilePath,
      'issueNumber': issueNumber,
    };
  }

  factory GithubTodo.fromJson(Map<String, dynamic> json) {
    return GithubTodo(
      id: json['id'],
      repositoryId: json['repositoryId'],
      title: json['title'],
      description: json['description'],
      completed: json['completed'],
      createdAt: DateTime.parse(json['createdAt']),
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      priority: TodoPriority.values.firstWhere(
        (e) => e.toString().split('.').last == json['priority'],
        orElse: () => TodoPriority.medium,
      ),
      category: TodoCategory.values.firstWhere(
        (e) => e.toString().split('.').last == json['category'],
        orElse: () => TodoCategory.other,
      ),
      relatedFilePath: json['relatedFilePath'],
      issueNumber: json['issueNumber'],
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is GithubTodo &&
        other.id == id &&
        other.repositoryId == repositoryId;
  }

  @override
  int get hashCode => id.hashCode ^ repositoryId.hashCode;
}
