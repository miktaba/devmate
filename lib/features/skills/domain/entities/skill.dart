import 'package:hive/hive.dart';

part 'skill.g.dart';

@HiveType(typeId: 2)
enum SkillCategory {
  @HiveField(0)
  language, // Programming languages

  @HiveField(1)
  framework, // Frameworks

  @HiveField(2)
  tool, // Tools

  @HiveField(3)
  database, // Databases

  @HiveField(4)
  other, // Other
}

extension SkillCategoryExtension on SkillCategory {
  String get name {
    switch (this) {
      case SkillCategory.language:
        return 'Programming language';
      case SkillCategory.framework:
        return 'Framework';
      case SkillCategory.tool:
        return 'Tool';
      case SkillCategory.database:
        return 'Database';
      case SkillCategory.other:
        return 'Other';
    }
  }
}

@HiveType(typeId: 1)
class Skill extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final SkillCategory category;

  @HiveField(3)
  final bool isCustom; // Indicates if the skill is added by the user

  @HiveField(4)
  final int level; // Ownership level: 1-5

  @HiveField(5)
  final String? description;

  @HiveField(6)
  final String? icon; // Optional: path to the icon or icon code

  Skill({
    required this.id,
    required this.name,
    required this.category,
    this.isCustom = false,
    this.level = 1,
    this.description,
    this.icon,
  });

  Skill copyWith({
    String? id,
    String? name,
    SkillCategory? category,
    bool? isCustom,
    int? level,
    String? description,
    String? icon,
  }) {
    return Skill(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      isCustom: isCustom ?? this.isCustom,
      level: level ?? this.level,
      description: description ?? this.description,
      icon: icon ?? this.icon,
    );
  }
}

// Array of predefined skills
final List<Skill> predefinedSkills = [
  // Programming languages
  Skill(
    id: 'lang_python',
    name: 'Python',
    category: SkillCategory.language,
    description: 'High-level general-purpose programming language',
    icon: 'python',
  ),
  Skill(
    id: 'lang_javascript',
    name: 'JavaScript',
    category: SkillCategory.language,
    description: 'Multi-paradigm programming language for web development',
    icon: 'js',
  ),
  Skill(
    id: 'lang_typescript',
    name: 'TypeScript',
    category: SkillCategory.language,
    description: 'Programming language with strong typing based on JavaScript',
    icon: 'ts',
  ),
  Skill(
    id: 'lang_java',
    name: 'Java',
    category: SkillCategory.language,
    description: 'Object-oriented programming language',
    icon: 'java',
  ),
  Skill(
    id: 'lang_swift',
    name: 'Swift',
    category: SkillCategory.language,
    description:
        'Programming language for developing iOS and macOS applications',
    icon: 'swift',
  ),
  Skill(
    id: 'lang_kotlin',
    name: 'Kotlin',
    category: SkillCategory.language,
    description: 'Statically typed programming language for the JVM',
    icon: 'kotlin',
  ),
  Skill(
    id: 'lang_dart',
    name: 'Dart',
    category: SkillCategory.language,
    description:
        'Programming language for developing cross-platform applications',
    icon: 'dart',
  ),
  Skill(
    id: 'lang_csharp',
    name: 'C#',
    category: SkillCategory.language,
    description: 'Object-oriented programming language from Microsoft',
    icon: 'csharp',
  ),
  Skill(
    id: 'lang_cpp',
    name: 'C++',
    category: SkillCategory.language,
    description:
        'General-purpose programming language with support for various paradigms',
    icon: 'cpp',
  ),

  // Frameworks
  Skill(
    id: 'framework_flutter',
    name: 'Flutter',
    category: SkillCategory.framework,
    description: 'SDK for developing cross-platform applications from Google',
    icon: 'flutter',
  ),
  Skill(
    id: 'framework_react',
    name: 'React',
    category: SkillCategory.framework,
    description: 'JavaScript library for creating user interfaces',
    icon: 'react',
  ),
  Skill(
    id: 'framework_angular',
    name: 'Angular',
    category: SkillCategory.framework,
    description: 'Platform for developing web applications on TypeScript',
    icon: 'angular',
  ),
  Skill(
    id: 'framework_vue',
    name: 'Vue.js',
    category: SkillCategory.framework,
    description: 'JavaScript framework for creating user interfaces',
    icon: 'vue',
  ),
  Skill(
    id: 'framework_django',
    name: 'Django',
    category: SkillCategory.framework,
    description: 'High-level Python web framework for rapid development',
    icon: 'django',
  ),
  Skill(
    id: 'framework_spring',
    name: 'Spring',
    category: SkillCategory.framework,
    description: 'Framework for developing applications on Java',
    icon: 'spring',
  ),
  Skill(
    id: 'framework_aspnet',
    name: 'ASP.NET',
    category: SkillCategory.framework,
    description:
        'Framework for developing web applications on the .NET platform',
    icon: 'aspnet',
  ),

  // Databases
  Skill(
    id: 'db_postgresql',
    name: 'PostgreSQL',
    category: SkillCategory.database,
    description: 'Object-relational database management system',
    icon: 'postgresql',
  ),
  Skill(
    id: 'db_mysql',
    name: 'MySQL',
    category: SkillCategory.database,
    description: 'Relational database management system',
    icon: 'mysql',
  ),
  Skill(
    id: 'db_mongodb',
    name: 'MongoDB',
    category: SkillCategory.database,
    description: 'Document-oriented database management system',
    icon: 'mongodb',
  ),
  Skill(
    id: 'db_firebase',
    name: 'Firebase',
    category: SkillCategory.database,
    description: 'NoSQL cloud database for applications',
    icon: 'firebase',
  ),

  // Tools
  Skill(
    id: 'tool_git',
    name: 'Git',
    category: SkillCategory.tool,
    description: 'Distributed version control system',
    icon: 'git',
  ),
  Skill(
    id: 'tool_docker',
    name: 'Docker',
    category: SkillCategory.tool,
    description:
        'Platform for developing, delivering and running applications in containers',
    icon: 'docker',
  ),
  Skill(
    id: 'tool_kubernetes',
    name: 'Kubernetes',
    category: SkillCategory.tool,
    description: 'Container orchestration system for automating deployment',
    icon: 'kubernetes',
  ),
];
