import 'package:explorex/shared/extension/app_theme_extension.dart';
import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  const CustomButton({
    super.key,
    required this.label,
    required this.onPress,
    required this.icon,
  });
  final String label;
  final VoidCallback onPress;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ElevatedButton(
        style: ButtonStyle(
          backgroundColor: WidgetStatePropertyAll(
            context.colorScheme.surfaceDim,
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        onPressed: onPress,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 8,
          children: [
            Icon(icon, color: const Color(0xffffffff), size: 18),
            Text(
              label,
              style: context.textTheme.bodyMedium!.copyWith(
                color: const Color(0xffffffff),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
