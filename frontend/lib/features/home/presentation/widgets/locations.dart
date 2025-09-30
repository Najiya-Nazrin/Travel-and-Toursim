import 'package:explorex/features/home/models/loc_model.dart';
import 'package:explorex/shared/extension/app_theme_extension.dart';
import 'package:flutter/material.dart';

class Locations extends StatelessWidget {
  const Locations({super.key, required this.locations, required this.title});
  final List<LocModel> locations;
  final String title;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 16,
      children: [
        Text(title, style: context.textTheme.bodyLarge),
        SizedBox(
          height: 350,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: locations.length,
            itemBuilder: (context, index) {
              final location = locations[index];
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: GestureDetector(
                  onTap: location.onTap,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(location.path, height: 350),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
