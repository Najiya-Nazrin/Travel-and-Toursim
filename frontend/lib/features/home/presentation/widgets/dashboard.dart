import 'package:explorex/features/home/presentation/widgets/stat_bar.dart';
import 'package:explorex/shared/extension/app_theme_extension.dart';
import 'package:flutter/material.dart';

class Dashboard extends StatelessWidget {
  const Dashboard({
    super.key,
    required this.level,
    required this.exp,
    required this.hp,
    required this.stamina,
    required this.title,
    required this.currentLevelXp,
    required this.nextLevelXp,
    required this.maxHp,
    required this.maxStamina,
  });

  final String level;
  final int exp;
  final int hp;
  final int stamina;
  final String title;
  final int currentLevelXp;
  final int nextLevelXp;
  final int maxHp;
  final int maxStamina;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.colorScheme.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        // Assuming 'spacing' is an extension property on Column/Row that adds space between children.
        spacing: 12,
        children: [
          // Level + Title
          Text(
            "LVL $level - $title",
            style: context.textTheme.bodyMedium!.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),

          // XP Bar aligned with other bars
          StatBar(
            label: "XP",
            value: exp - currentLevelXp,
            maxValue: nextLevelXp - currentLevelXp,
            color: Colors.blueAccent,
          ),

          // HP & Stamina Bars
          StatBar(
            label: "HP",
            value: hp,
            maxValue: maxHp,
            color: Colors.redAccent,
          ),
          StatBar(
            label: "Stamina",
            value: stamina,
            maxValue: maxStamina,
            color: Colors.orangeAccent,
          ),
        ],
      ),
    );
  }
}
