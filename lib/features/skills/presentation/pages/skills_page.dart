import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import '../../domain/entities/skill.dart';
import '../../application/providers/skills_provider.dart';
import '../widgets/add_skill_sheet.dart';
import '../widgets/skill_card.dart';

class SkillsPage extends ConsumerWidget {
  const SkillsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userSkills = ref.watch(filteredSkillsProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('Skills')),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            // Category filters
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildCategoryFilters(context, ref, selectedCategory),
            ),
            const SizedBox(height: 16),
            // Skills list
            Expanded(
              child:
                  userSkills.isEmpty
                      ? _buildEmptyState(context)
                      : _buildSkillsList(context, ref, userSkills),
            ),
            const SizedBox(height: 16),
            // Add skill button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: CupertinoButton.filled(
                  onPressed: () => _showAddSkillSheet(context, ref),
                  child: const Text('Add Skill'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            CupertinoIcons.star,
            size: 64,
            color: CupertinoColors.systemGrey,
          ),
          const SizedBox(height: 16),
          const Text(
            'You have no skills added yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add your first skill by clicking the button below',
            textAlign: TextAlign.center,
            style: TextStyle(color: CupertinoColors.systemGrey),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSkillsList(
    BuildContext context,
    WidgetRef ref,
    List<Skill> skills,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: skills.length,
      itemBuilder: (context, index) {
        final skill = skills[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SkillCard(
            skill: skill,
            onLevelChanged: (level) {
              ref
                  .read(userSkillsProvider.notifier)
                  .updateSkillLevel(skill.id, level);
            },
            onDelete: () {
              _showDeleteConfirmation(context, ref, skill);
            },
          ),
        );
      },
    );
  }

  Widget _buildCategoryFilters(
    BuildContext context,
    WidgetRef ref,
    SkillCategory? selectedCategory,
  ) {
    return Row(
      children: [
        _buildFilterChip(context, ref, null, 'All', selectedCategory == null),
        const SizedBox(width: 8),
        _buildFilterChip(
          context,
          ref,
          SkillCategory.language,
          'Languages',
          selectedCategory == SkillCategory.language,
        ),
        const SizedBox(width: 8),
        _buildFilterChip(
          context,
          ref,
          SkillCategory.framework,
          'Frameworks',
          selectedCategory == SkillCategory.framework,
        ),
        const SizedBox(width: 8),
        _buildFilterChip(
          context,
          ref,
          SkillCategory.database,
          'Databases',
          selectedCategory == SkillCategory.database,
        ),
        const SizedBox(width: 8),
        _buildFilterChip(
          context,
          ref,
          SkillCategory.tool,
          'Tools',
          selectedCategory == SkillCategory.tool,
        ),
        const SizedBox(width: 8),
        _buildFilterChip(
          context,
          ref,
          SkillCategory.other,
          'Other',
          selectedCategory == SkillCategory.other,
        ),
      ],
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    WidgetRef ref,
    SkillCategory? category,
    String label,
    bool isSelected,
  ) {
    return GestureDetector(
      onTap: () {
        ref.read(selectedCategoryProvider.notifier).state = category;
      },
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? CupertinoColors.activeBlue
                  : CupertinoColors.systemGrey6,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                isSelected
                    ? CupertinoColors.activeBlue
                    : CupertinoColors.systemGrey4,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? CupertinoColors.white : CupertinoColors.black,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  void _showAddSkillSheet(BuildContext context, WidgetRef ref) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => const AddSkillSheet(),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    WidgetRef ref,
    Skill skill,
  ) {
    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: const Text('Delete Skill'),
            content: Text(
              'Are you sure you want to delete the skill "${skill.name}"?',
            ),
            actions: [
              CupertinoDialogAction(
                isDestructiveAction: true,
                onPressed: () {
                  ref.read(userSkillsProvider.notifier).deleteSkill(skill.id);
                  Navigator.pop(context);
                },
                child: const Text('Delete'),
              ),
              CupertinoDialogAction(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
    );
  }
}
