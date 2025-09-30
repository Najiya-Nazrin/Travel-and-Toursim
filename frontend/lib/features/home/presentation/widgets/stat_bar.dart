import 'package:explorex/shared/extension/app_theme_extension.dart';
import 'package:flutter/material.dart';

/// 🔹 Reusable stat bar
class StatBar extends StatelessWidget {
  final String label;
  final int value;
  final int maxValue;
  final Color color;

  const StatBar({
    required this.label,
    required this.value,
    required this.maxValue,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      // Assuming 'spacing' adds space between all children
      spacing: 8,
      children: [
        // 1. Label: Fixed width
        SizedBox(
          width: 70,
          child: Text(
            "$label:",
            style: context.textTheme.bodySmall!.copyWith(color: Colors.white),
          ),
        ),

        // 2. Progress Bar: Takes up the remaining available space (which is now fixed)
        Expanded(
          child: LinearProgressIndicator(
            value: (value / maxValue).clamp(0.0, 1.0),
            color: color,
            backgroundColor: Colors.white.withAlpha(70),
            minHeight: 8,
            borderRadius: BorderRadius.circular(8),
          ),
        ),

        // 3. Value/Max Text: Fixed width is increased and text wrapping is disabled.
        SizedBox(
          width: 70, // Increased from 60 to 70 for safety with large numbers
          child: Text(
            "$value / $maxValue",
            style: context.textTheme.bodySmall!.copyWith(color: Colors.white),
            textAlign: TextAlign.right, // Align right for a clean look
            softWrap: false, // Crucial: Prevents the text from wrapping
            overflow: TextOverflow.clip, // Clip if numbers are extremely large
          ),
        ),
      ],
    );
  }
}
