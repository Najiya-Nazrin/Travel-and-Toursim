import 'package:explorex/features/plan_trip/utils/plan_enum.dart';
import 'package:explorex/features/plan_trip/presentation/widgets/plan_items.dart';
import 'package:explorex/shared/extension/app_theme_extension.dart';
import 'package:explorex/shared/widgets/custom_button.dart';
import 'package:flutter/material.dart';

class Plan extends StatelessWidget {
  const Plan({
    super.key,
    required this.parsedResponse,
    required this.saveForLater,
    required this.setAsCurrentTrip,
  });
  final Map<String, dynamic>? parsedResponse;
  final VoidCallback saveForLater;
  final VoidCallback setAsCurrentTrip;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Places
        if (parsedResponse!['places'] != null)
          PlanItems(parsedResponse: parsedResponse, type: PlanEnum.quests),
        const SizedBox(height: 16),
        // Stays
        if (parsedResponse!['stays'] != null) ...[
          PlanItems(parsedResponse: parsedResponse, type: PlanEnum.safePlaces),
        ],
        const SizedBox(height: 16),
        // Food
        if (parsedResponse!['food'] != null)
          PlanItems(parsedResponse: parsedResponse, type: PlanEnum.food),

        // Total XP
        if (parsedResponse!['total_xp'] != null) ...[
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xffffedd5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  "Total XP: ${parsedResponse!['total_xp']}",
                  style: context.textTheme.bodyLarge!.copyWith(
                    color: const Color(0xffea580c),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],

        const SizedBox(height: 20),

        // 🚀 Action Buttons
        Row(
          children: [
            Expanded(
              child: CustomButton(
                label: "Save",
                onPress: saveForLater,
                icon: Icons.bookmark_add_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomButton(
                label: "Go on Trip",
                onPress: setAsCurrentTrip,
                icon: Icons.flag_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
