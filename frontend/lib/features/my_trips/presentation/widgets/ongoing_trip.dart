import 'package:explorex/shared/extension/app_theme_extension.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OngoingTrip extends StatefulWidget {
  final Map<String, dynamic> trip;
  const OngoingTrip({super.key, required this.trip});

  @override
  State<OngoingTrip> createState() => _OngoingTripState();
}

class _OngoingTripState extends State<OngoingTrip>
    with AutomaticKeepAliveClientMixin {
  int _completedQuestsCount = 0;
  int _totalQuestsCount = 0;
  double _progressValue = 0.0;
  String _progressText = '0%';

  @override
  void initState() {
    super.initState();
    // Initial calculation on widget creation
    _calculateProgress();
  }

  // FIX: Recalculate progress whenever the parent widget rebuilds
  @override
  void didUpdateWidget(covariant OngoingTrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Even if widget.trip is the same object, we must recalculate
    // because the data in SharedPreferences might have changed.
    _calculateProgress();
  }

  @override
  bool get wantKeepAlive => true;

  Future<void> _calculateProgress() async {
    // Re-instantiate SharedPreferences to ensure the latest data is retrieved
    final prefs = await SharedPreferences.getInstance();

    // 1. Get total quests count from the trip data
    final quests = widget.trip['places'] as List<dynamic>? ?? [];
    _totalQuestsCount = quests.length;

    // 2. Get completed quests count from SharedPreferences
    final completedQuests = prefs.getStringList("completedQuests") ?? [];
    _completedQuestsCount = completedQuests.length;

    // 3. Calculate progress robustly
    double calculatedProgress;
    if (_totalQuestsCount > 0) {
      // Use toDouble() for accurate division
      calculatedProgress =
          _completedQuestsCount.toDouble() / _totalQuestsCount.toDouble();

      // Safety clamp: ensures value is between 0.0 and 1.0
      _progressValue = calculatedProgress.clamp(0.0, 1.0);

      final percentage = (_progressValue * 100).round();
      _progressText = '$percentage%';
    } else {
      // If no quests, treat as 0%
      _progressValue = 0.0;
      _progressText = '0%';
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required by AutomaticKeepAliveClientMixin

    final places = widget.trip['places'] as List<dynamic>? ?? [];
    final firstPlace = places.isNotEmpty ? places[0]['name'] : "Unknown Place";
    final totalXp = widget.trip['total_xp'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xffEFEFEF), width: 1),
        borderRadius: BorderRadius.circular(16),
        color: context.colorScheme.surfaceContainer,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFBFBFBF).withAlpha(86),
            offset: const Offset(0, 2),
            blurRadius: 12,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  firstPlace,
                  style: context.textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  "Currently Exploring • $totalXp XP",
                  style: context.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 50,
                width: 50,
                child: CircularProgressIndicator(value: _progressValue),
              ),
              Text(
                _progressText, // DYNAMIC: Use calculated percentage
                style: context.textTheme.bodySmall!.copyWith(
                  fontWeight: FontWeight.bold,
                  color: context.colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
