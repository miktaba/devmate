import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import '../../domain/entities/skill.dart';
import '../../application/providers/skills_provider.dart';

class AddSkillSheet extends ConsumerStatefulWidget {
  const AddSkillSheet({super.key});

  @override
  ConsumerState<AddSkillSheet> createState() => _AddSkillSheetState();
}

class _AddSkillSheetState extends ConsumerState<AddSkillSheet> {
  bool _isPredefinedTab = true;
  SkillCategory _selectedCategory = SkillCategory.language;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // For custom skill
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity! > 300) {
          Navigator.pop(context);
        }
      },
      child: Container(
        height: MediaQuery.of(context).size.height * 0.75,
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: CupertinoColors.systemBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Swipe indicator for closing
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey4,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Title
            Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.center,
                  child: const Text(
                    'Adding a skill',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(CupertinoIcons.xmark, size: 20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Tab selector between predefined and custom skills
            _buildTabSelector(),
            const SizedBox(height: 12),

            // Search (only for predefined skills)
            if (_isPredefinedTab) _buildSearchField(),

            // Content depending on the selected tab
            Expanded(
              child:
                  _isPredefinedTab
                      ? _buildPredefinedSkillsList()
                      : _buildCustomSkillForm(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: CupertinoTextField(
        controller: _searchController,
        placeholder: 'Search skills...',
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        prefix: const Padding(
          padding: EdgeInsets.only(left: 8),
          child: Icon(
            CupertinoIcons.search,
            color: CupertinoColors.systemGrey,
            size: 18,
          ),
        ),
        suffix:
            _searchQuery.isNotEmpty
                ? GestureDetector(
                  onTap: () {
                    setState(() {
                      _searchController.clear();
                      _searchQuery = '';
                    });
                  },
                  child: const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Icon(
                      CupertinoIcons.clear_circled_solid,
                      color: CupertinoColors.systemGrey,
                      size: 18,
                    ),
                  ),
                )
                : null,
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey6,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: CupertinoColors.systemGrey4),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value.trim();
          });
        },
      ),
    );
  }

  Widget _buildTabSelector() {
    return CupertinoSlidingSegmentedControl<bool>(
      groupValue: _isPredefinedTab,
      children: const {
        true: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text('Predefined skills'),
        ),
        false: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text('Custom skill'),
        ),
      },
      onValueChanged: (value) {
        if (value != null) {
          setState(() {
            _isPredefinedTab = value;
            // Reset search when switching tabs
            if (!value) {
              _searchController.clear();
              _searchQuery = '';
            }
          });
        }
      },
    );
  }

  Widget _buildPredefinedSkillsList() {
    final allAvailableSkills = ref.watch(availablePredefinedSkillsProvider);
    final filteredByCategory =
        allAvailableSkills
            .where((skill) => skill.category == _selectedCategory)
            .toList();

    // Filter by search query
    final availableSkills =
        _searchQuery.isEmpty
            ? filteredByCategory
            : filteredByCategory
                .where(
                  (skill) =>
                      skill.name.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      ) ||
                      (skill.description != null &&
                          skill.description!.toLowerCase().contains(
                            _searchQuery.toLowerCase(),
                          )),
                )
                .toList();

    if (allAvailableSkills.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.info_circle,
              size: 48,
              color: CupertinoColors.systemGrey,
            ),
            const SizedBox(height: 16),
            const Text(
              'All predefined skills are already added',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'You can add your own skill',
              style: TextStyle(fontSize: 14, color: CupertinoColors.systemGrey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            CupertinoButton(
              onPressed: () {
                setState(() {
                  _isPredefinedTab = false;
                });
              },
              child: const Text('Add your own skill'),
            ),
          ],
        ),
      );
    }

    if (availableSkills.isEmpty && _searchQuery.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.search,
              size: 48,
              color: CupertinoColors.systemGrey,
            ),
            const SizedBox(height: 16),
            Text(
              'Nothing found for the query "$_searchQuery"',
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Try changing the query or category',
              style: TextStyle(fontSize: 14, color: CupertinoColors.systemGrey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Filters by categories
        SizedBox(
          height: 36,
          child: ListView(
            padding: EdgeInsets.zero,
            scrollDirection: Axis.horizontal,
            children:
                SkillCategory.values.map((category) {
                  final isSelected = _selectedCategory == category;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      height: 32,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? CupertinoColors.activeBlue
                                : CupertinoColors.systemGrey6,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color:
                              isSelected
                                  ? CupertinoColors.activeBlue
                                  : CupertinoColors.systemGrey4,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          category.name,
                          style: TextStyle(
                            color:
                                isSelected
                                    ? CupertinoColors.white
                                    : CupertinoColors.black,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
        ),
        const SizedBox(height: 8),

        // List of available skills filtered by category and search query
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(top: 4),
            children:
                availableSkills
                    .map((skill) => _buildPredefinedSkillItem(skill))
                    .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildPredefinedSkillItem(Skill skill) {
    return GestureDetector(
      onTap: () {
        _addPredefinedSkill(skill.id);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey6,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: CupertinoColors.systemGrey5),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    skill.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (skill.description != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        skill.description!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const Icon(
              CupertinoIcons.add_circled,
              color: CupertinoColors.activeBlue,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomSkillForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Skill name',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        CupertinoTextField(
          controller: _nameController,
          placeholder: 'Enter skill name',
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: CupertinoColors.systemGrey6,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: CupertinoColors.systemGrey4),
          ),
        ),
        const SizedBox(height: 16),

        const Text(
          'Description (optional)',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        CupertinoTextField(
          controller: _descriptionController,
          placeholder: 'Enter skill description',
          padding: const EdgeInsets.all(12),
          maxLines: 3,
          decoration: BoxDecoration(
            color: CupertinoColors.systemGrey6,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: CupertinoColors.systemGrey4),
          ),
        ),
        const SizedBox(height: 16),

        const Text(
          'Category',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _buildCategoryPicker(),
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          child: CupertinoButton.filled(
            onPressed: _validateAndAddCustomSkill,
            child: const Text('Add skill'),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryPicker() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CupertinoColors.systemGrey4),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _showCategoryPicker();
          },
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _selectedCategory.name,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              const Icon(
                CupertinoIcons.chevron_down,
                size: 16,
                color: CupertinoColors.systemGrey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCategoryPicker() {
    showCupertinoModalPopup(
      context: context,
      builder:
          (context) => Container(
            height: 250,
            color: CupertinoColors.systemBackground,
            child: Column(
              children: [
                // Top bar with cancel and confirm buttons
                Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: const BoxDecoration(
                    color: CupertinoColors.systemGrey6,
                    border: Border(
                      bottom: BorderSide(
                        color: CupertinoColors.systemGrey5,
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: const Text('Cancel'),
                        onPressed: () => Navigator.pop(context),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: const Text('Done'),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                // Picker for selecting a category
                Expanded(
                  child: CupertinoPicker(
                    itemExtent: 40,
                    onSelectedItemChanged: (index) {
                      setState(() {
                        _selectedCategory = SkillCategory.values[index];
                      });
                    },
                    scrollController: FixedExtentScrollController(
                      initialItem: SkillCategory.values.indexOf(
                        _selectedCategory,
                      ),
                    ),
                    children:
                        SkillCategory.values.map((category) {
                          return Center(
                            child: Text(
                              category.name,
                              style: const TextStyle(fontSize: 16),
                            ),
                          );
                        }).toList(),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  void _addPredefinedSkill(String skillId) {
    try {
      ref.read(userSkillsProvider.notifier).addPredefinedSkill(skillId);
      Navigator.pop(context); // Close the modal window after adding

      if (kDebugMode) {
        print('Predefined skill successfully added: $skillId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error adding predefined skill: $e');
      }
      _showErrorDialog('Failed to add skill: $e');
    }
  }

  void _validateAndAddCustomSkill() {
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();

    if (name.isEmpty) {
      _showErrorDialog('Enter skill name');
      return;
    }

    try {
      ref
          .read(userSkillsProvider.notifier)
          .addCustomSkill(
            name: name,
            category: _selectedCategory,
            description: description.isNotEmpty ? description : null,
          );

      Navigator.pop(context); // Close the modal window after adding

      if (kDebugMode) {
        print('User skill successfully added: $name');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error adding user skill: $e');
      }
      _showErrorDialog('Failed to add skill: $e');
    }
  }

  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text(message),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }
}
