import 'package:explorex/shared/extension/app_theme_extension.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PlanDatePicker extends StatelessWidget {
  const PlanDatePicker({
    super.key,
    required this.pickDateRange,
    required this.selectedDateRange,
  });
  final VoidCallback pickDateRange;
  final DateTimeRange selectedDateRange;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: pickDateRange,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xffe7eff4),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),

        child: Row(
          spacing: 16,
          children: [
            Icon(Icons.calendar_today_outlined, color: const Color(0xff49819c)),
            Text(
              "${DateFormat('dd MMM yyyy').format(selectedDateRange.start)} → ${DateFormat('dd MMM yyyy').format(selectedDateRange.end)}",
              style: context.textTheme.bodyMedium!.copyWith(
                color: const Color(0xff49819c),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
