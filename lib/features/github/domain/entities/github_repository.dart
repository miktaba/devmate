import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

part 'github_repository.g.dart';

@HiveType(typeId: 3)
class GithubRepository {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String? description;

  @HiveField(3)
  final String owner;

  @HiveField(4)
  final String ownerAvatarUrl;

  @HiveField(5)
  final bool isPrivate;

  @HiveField(6)
  final int starCount;

  @HiveField(7)
  final int forkCount;

  @HiveField(8)
  final String defaultBranch;

  @HiveField(9)
  final DateTime updatedAt;

  @HiveField(10)
  final String htmlUrl;

  @HiveField(11)
  final bool hasIssues;

  @HiveField(12)
  final String? language;

  @HiveField(13)
  final bool selected;

  GithubRepository({
    required this.id,
    required this.name,
    required this.owner,
    required this.ownerAvatarUrl,
    required this.isPrivate,
    required this.starCount,
    required this.forkCount,
    required this.defaultBranch,
    required this.updatedAt,
    required this.htmlUrl,
    required this.hasIssues,
    this.description,
    this.language,
    this.selected = false,
  });

  GithubRepository copyWith({
    String? id,
    String? name,
    String? description,
    String? owner,
    String? ownerAvatarUrl,
    bool? isPrivate,
    int? starCount,
    int? forkCount,
    String? defaultBranch,
    DateTime? updatedAt,
    String? htmlUrl,
    bool? hasIssues,
    String? language,
    bool? selected,
  }) {
    return GithubRepository(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      owner: owner ?? this.owner,
      ownerAvatarUrl: ownerAvatarUrl ?? this.ownerAvatarUrl,
      isPrivate: isPrivate ?? this.isPrivate,
      starCount: starCount ?? this.starCount,
      forkCount: forkCount ?? this.forkCount,
      defaultBranch: defaultBranch ?? this.defaultBranch,
      updatedAt: updatedAt ?? this.updatedAt,
      htmlUrl: htmlUrl ?? this.htmlUrl,
      hasIssues: hasIssues ?? this.hasIssues,
      language: language ?? this.language,
      selected: selected ?? this.selected,
    );
  }

  factory GithubRepository.fromJson(Map<String, dynamic> json) {
    return GithubRepository(
      id: json['id'].toString(),
      name: json['name'],
      description: json['description'],
      owner: json['owner']['login'],
      ownerAvatarUrl: json['owner']['avatar_url'],
      isPrivate: json['private'],
      starCount: json['stargazers_count'],
      forkCount: json['forks_count'],
      defaultBranch: json['default_branch'],
      updatedAt: DateTime.parse(json['updated_at']),
      htmlUrl: json['html_url'],
      hasIssues: json['has_issues'],
      language: json['language'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'owner': {'login': owner, 'avatar_url': ownerAvatarUrl},
      'private': isPrivate,
      'stargazers_count': starCount,
      'forks_count': forkCount,
      'default_branch': defaultBranch,
      'updated_at': updatedAt.toIso8601String(),
      'html_url': htmlUrl,
      'has_issues': hasIssues,
      'language': language,
      'selected': selected,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is GithubRepository &&
        other.id == id &&
        other.name == name &&
        other.owner == owner;
  }

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ owner.hashCode;

  @override
  String toString() {
    return 'GithubRepository(id: $id, name: $name, owner: $owner, isPrivate: $isPrivate, '
        'starCount: $starCount, forkCount: $forkCount, language: $language)';
  }
}
