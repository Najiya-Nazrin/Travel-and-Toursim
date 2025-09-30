import 'package:explorex/features/my_trips/models/level_model.dart';
import 'package:flutter/material.dart';

class LevelMarker extends StatelessWidget {
  final TravelLocation location;
  final double top;
  final double left;

  const LevelMarker({
    required this.location,
    required this.top,
    required this.left,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      child: Column(
        children: [
          // The sign with the number
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.brown, width: 3),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              location.levelNumber.toString(),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.brown,
              ),
            ),
          ),
          // The base showing XP or Stamina
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: location.isSafeHouse
                  ? Colors.lightBlue
                  : Colors.orange.shade800,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.brown, width: 2),
            ),
            child: Text(
              location.isSafeHouse
                  ? 'STAMINA: ${location.stamina}'
                  : 'XP: ${location.xp}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
