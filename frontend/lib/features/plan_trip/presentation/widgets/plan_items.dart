import 'package:explorex/features/plan_trip/utils/plan_enum.dart';
import 'package:explorex/shared/extension/app_theme_extension.dart';
import 'package:flutter/material.dart';

class PlanItems extends StatelessWidget {
  const PlanItems({
    super.key,
    required this.parsedResponse,
    required this.type,
  });
  final Map<String, dynamic>? parsedResponse;
  final PlanEnum type;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(type.title, style: context.textTheme.bodyLarge),
        const SizedBox(height: 8),
        ...parsedResponse![type.type].map<Widget>((p) {
          return Card(
            child: ListTile(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      p['name'],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodyMedium,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: type.bgColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "${p[type.reward]} ${type.rewardType}",
                      style: context.textTheme.bodySmall!.copyWith(
                        color: type.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    p[type.subTitle] ?? "",
                    style: context.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }
}
