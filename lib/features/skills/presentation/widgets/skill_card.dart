import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/skill.dart';

class SkillCard extends StatelessWidget {
  final Skill skill;
  final Function(int) onLevelChanged;
  final VoidCallback onDelete;

  const SkillCard({
    super.key,
    required this.skill,
    required this.onLevelChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CupertinoColors.systemGrey5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Skill icon (if exists) or category
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getCategoryColor(skill.category).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    _getCategoryIcon(skill.category),
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Name and description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            skill.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        // Delete button
                        GestureDetector(
                          onTap: onDelete,
                          child: const Icon(
                            CupertinoIcons.delete,
                            size: 20,
                            color: CupertinoColors.systemGrey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (skill.description != null)
                      Text(
                        skill.description!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      skill.category.name,
                      style: TextStyle(
                        fontSize: 12,
                        color: _getCategoryColor(skill.category),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Block with skill level display
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Ownership level:',
                    style: TextStyle(fontSize: 14),
                  ),
                  Text(
                    _getLevelLabel(skill.level),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _getLevelColor(skill.level),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Sliderffor changingcthehlevell
              _buildLevelSlider(context),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLevelSlider(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SliderTheme(
        data: SliderTheme.of(context).copyWith(
          activeTrackColor: _getLevelColor(skill.level),
          inactiveTrackColor: CupertinoColors.systemGrey5,
          thumbColor: CupertinoColors.white,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
          trackHeight: 4,
        ),
        child: Slider(
          value: skill.level.toDouble(),
          min: 1,
          max: 5,
          divisions: 4,
          onChanged: (newValue) => onLevelChanged(newValue.round()),
        ),
      ),
    );
  }

  String _getLevelLabel(int level) {
    switch (level) {
      case 1:
        return 'Beginner';
      case 2:
        return 'Basic';
      case 3:
        return 'Advanced';
      case 4:
        return 'Expert';
      case 5:
        return 'Expert';
      default:
        return 'Unknown';
    }
  }

  Color _getLevelColor(int level) {
    switch (level) {
      case 1:
        return CupertinoColors.systemGrey;
      case 2:
        return CupertinoColors.systemBlue;
      case 3:
        return CupertinoColors.activeBlue;
      case 4:
        return CupertinoColors.activeGreen;
      case 5:
        return CupertinoColors.systemIndigo;
      default:
        return CupertinoColors.systemGrey;
    }
  }

  String _getCategoryIcon(SkillCategory category) {
    switch (category) {
      case SkillCategory.language:
        return '💻';
      case SkillCategory.framework:
        return '🛠️';
      case SkillCategory.database:
        return '💾';
      case SkillCategory.tool:
        return '🔧';
      case SkillCategory.other:
        return '📌';
    }
  }

  Color _getCategoryColor(SkillCategory category) {
    switch (category) {
      case SkillCategory.language:
        return CupertinoColors.systemBlue;
      case SkillCategory.framework:
        return CupertinoColors.systemPurple;
      case SkillCategory.database:
        return CupertinoColors.systemGreen;
      case SkillCategory.tool:
        return CupertinoColors.systemOrange;
      case SkillCategory.other:
        return CupertinoColors.systemGrey;
    }
  }
}
