import 'package:explorex/features/my_trips/models/level_model.dart';
import 'package:flutter/material.dart';

class HPLegend extends StatelessWidget {
  final List<FoodItem> items;

  const HPLegend({required this.items, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.green, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'POWER-UPS: HP from Food',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.green,
              ),
            ),
            const Divider(),
            ...items
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.favorite,
                          color: Colors.red,
                          size: 16,
                        ), // HP Icon
                        const SizedBox(width: 4),
                        Text(
                          '${item.name}: +${item.hp} HP',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ],
        ),
      ),
    );
  }
}
