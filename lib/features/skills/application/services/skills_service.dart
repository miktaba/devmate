import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/skill.dart';

/// Service for user skills management
class SkillsService {
  final Box<Skill> _skillsBox;

  SkillsService(this._skillsBox);

  /// Getting all user skills
  List<Skill> getAllSkills() {
    return _skillsBox.values.toList();
  }

  /// Getting skills by category
  List<Skill> getSkillsByCategory(SkillCategory category) {
    return _skillsBox.values
        .where((skill) => skill.category == category)
        .toList();
  }

  /// Getting predefined skills that are not yet added by the user
  List<Skill> getAvailablePredefinedSkills() {
    final userSkillIds = _skillsBox.values.map((skill) => skill.id).toSet();
    return predefinedSkills
        .where((skill) => !userSkillIds.contains(skill.id))
        .toList();
  }

  /// Adding a skill from predefined skills
  Future<void> addPredefinedSkill(String skillId) async {
    try {
      final skill = predefinedSkills.firstWhere((s) => s.id == skillId);
      await _skillsBox.put(skill.id, skill);
      if (kDebugMode) {
        print('Skill "${skill.name}" successfully added');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error adding skill: $e');
      }
      rethrow;
    }
  }

  /// Adding a custom skill
  Future<void> addCustomSkill({
    required String name,
    required SkillCategory category,
    String? description,
  }) async {
    try {
      final customId = 'custom_${DateTime.now().millisecondsSinceEpoch}';
      final skill = Skill(
        id: customId,
        name: name,
        category: category,
        isCustom: true,
        description: description,
      );

      await _skillsBox.put(customId, skill);
      if (kDebugMode) {
        print('User skill "${skill.name}" successfully added');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error adding user skill: $e');
      }
      rethrow;
    }
  }

  /// Updating the skill level
  Future<void> updateSkillLevel(String skillId, int level) async {
    try {
      if (level < 1 || level > 5) {
        throw ArgumentError('Skill level must be between 1 and 5');
      }

      final skill = _skillsBox.get(skillId);
      if (skill == null) {
        throw Exception('Skill with ID $skillId not found');
      }

      final updatedSkill = skill.copyWith(level: level);
      await _skillsBox.put(skillId, updatedSkill);

      if (kDebugMode) {
        print('Skill "${skill.name}" level updated to $level');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating skill level: $e');
      }
      rethrow;
    }
  }

  /// Deleting a skill
  Future<void> deleteSkill(String skillId) async {
    try {
      await _skillsBox.delete(skillId);
      if (kDebugMode) {
        print('Skill with ID $skillId successfully deleted');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting skill: $e');
      }
      rethrow;
    }
  }

  /// Resetting all skills (deleting all user skills)
  Future<void> resetAllSkills() async {
    try {
      await _skillsBox.clear();
      if (kDebugMode) {
        print('All skills successfully reset');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error resetting skills: $e');
      }
      rethrow;
    }
  }
}

/// Skills service provider
final skillsServiceProvider = Provider<SkillsService>((ref) {
  final skillsBox = Hive.box<Skill>('skills');
  return SkillsService(skillsBox);
});
