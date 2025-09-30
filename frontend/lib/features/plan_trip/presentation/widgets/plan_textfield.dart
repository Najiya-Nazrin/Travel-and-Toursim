import 'package:explorex/shared/extension/app_theme_extension.dart';
import 'package:flutter/material.dart';

class PlanTextfield extends StatelessWidget {
  const PlanTextfield({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
  });
  final TextEditingController controller;
  final String label;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: const Color(0xff49819c)),
        hintText: label,
        hintStyle: context.textTheme.bodyMedium!.copyWith(
          color: const Color(0xff49819c),
        ),
        fillColor: const Color(0xffe7eff4),
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
