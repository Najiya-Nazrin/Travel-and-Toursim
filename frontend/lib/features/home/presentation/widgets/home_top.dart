import 'package:explorex/shared/extension/app_theme_extension.dart';
import 'package:flutter/material.dart';

class HomeTop extends StatelessWidget {
  const HomeTop({super.key, required this.name});
  final String name;
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Welcome back,", style: context.textTheme.bodySmall),
            Text(name, style: context.textTheme.bodyLarge),
          ],
        ),
        ClipRRect(
          borderRadius: BorderRadiusGeometry.circular(100),
          child: Image.asset("assets/images/icons/avatar.png", height: 48),
        ),
      ],
    );
  }
}
