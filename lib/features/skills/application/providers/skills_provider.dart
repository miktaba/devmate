import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/skill.dart';
import '../services/skills_service.dart';

/// Provider of a list of all user skills
final userSkillsProvider =
    StateNotifierProvider<UserSkillsNotifier, List<Skill>>((ref) {
      final skillsService = ref.watch(skillsServiceProvider);
      return UserSkillsNotifier(skillsService);
    });

/// Provider for filtering skills by category
final selectedCategoryProvider = StateProvider<SkillCategory?>((ref) => null);

/// Provider for filtered skills
final filteredSkillsProvider = Provider<List<Skill>>((ref) {
  final allSkills = ref.watch(userSkillsProvider);
  final selectedCategory = ref.watch(selectedCategoryProvider);

  if (selectedCategory == null) {
    return allSkills;
  }

  return allSkills
      .where((skill) => skill.category == selectedCategory)
      .toList();
});

/// Provider for available predefined skills for adding
final availablePredefinedSkillsProvider = Provider<List<Skill>>((ref) {
  final skillsService = ref.watch(skillsServiceProvider);
  return skillsService.getAvailablePredefinedSkills();
});

/// StateNotifier for managing user skills
class UserSkillsNotifier extends StateNotifier<List<Skill>> {
  final SkillsService _skillsService;

  UserSkillsNotifier(this._skillsService) : super([]) {
    // Load existing skills when initializing
    _loadSkills();
  }

  /// Loading all skills
  void _loadSkills() {
    state = _skillsService.getAllSkills();
  }

  /// Adding a predefined skill
  Future<void> addPredefinedSkill(String skillId) async {
    await _skillsService.addPredefinedSkill(skillId);
    _loadSkills(); // Update the state after adding
  }

  /// Adding a custom skill
  Future<void> addCustomSkill({
    required String name,
    required SkillCategory category,
    String? description,
  }) async {
    await _skillsService.addCustomSkill(
      name: name,
      category: category,
      description: description,
    );
    _loadSkills(); // Update the state after adding
  }

  /// Updating the skill level
  Future<void> updateSkillLevel(String skillId, int level) async {
    await _skillsService.updateSkillLevel(skillId, level);
    _loadSkills(); // Update the state after changing
  }

  /// Deleting the skill
  Future<void> deleteSkill(String skillId) async {
    await _skillsService.deleteSkill(skillId);
    _loadSkills(); // Update the state after deleting
  }

  /// Resetting all skills
  Future<void> resetAllSkills() async {
    await _skillsService.resetAllSkills();
    _loadSkills(); // Update the state after resetting
  }
}
