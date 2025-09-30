import 'dart:convert';
import 'package:explorex/features/my_trips/presentation/screens/map_screen.dart';
import 'package:explorex/features/my_trips/presentation/widgets/ongoing_trip.dart';
import 'package:explorex/shared/extension/app_theme_extension.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyTrips extends StatefulWidget {
  const MyTrips({super.key});

  @override
  State<MyTrips> createState() => _MyTripsState();
}

class _MyTripsState extends State<MyTrips> {
  Map<String, dynamic>? _currentTrip;
  List<Map<String, dynamic>> _savedTrips = [];
  List<Map<String, dynamic>> _oldTrips = [];

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    final prefs = await SharedPreferences.getInstance();

    // Load current trip
    final current = prefs.getString("current_trip");
    _currentTrip = (current != null) ? json.decode(current) : null;

    // Load saved trips
    final saved = prefs.getStringList("saved_trips") ?? [];
    _savedTrips = saved
        .map((t) => json.decode(t))
        .toList()
        .cast<Map<String, dynamic>>();

    // Load old trips
    final old = prefs.getStringList("old_trips") ?? [];
    _oldTrips = old
        .map((t) => json.decode(t))
        .toList()
        .cast<Map<String, dynamic>>();

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("My Trips", style: context.textTheme.bodyLarge),
              const SizedBox(height: 12),

              // Ongoing Trip
              if (_currentTrip != null)
                GestureDetector(
                  onTap: () {
                    // Navigate to MapScreen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MapScreen(
                          parsedResponse: _currentTrip!,
                          isCurrentTrip: true, // mark as current trip
                        ),
                      ),
                    ).then(
                      (_) => _loadTrips(),
                    ); // Reload MyTrips state after returning
                  },
                  child: OngoingTrip(trip: _currentTrip!),
                )
              else
                Text("No ongoing trip", style: context.textTheme.bodySmall),

              const SizedBox(height: 20),

              // Saved Trips
              Text("Saved Trips", style: context.textTheme.bodyLarge),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  children: [
                    _savedTrips.isNotEmpty
                        ? Column(
                            children: _savedTrips.map((trip) {
                              // Check if this saved trip is already the current trip
                              final isThisTheCurrentTrip =
                                  _currentTrip != null &&
                                  _currentTrip!['places']?[0]?['name'] ==
                                      trip['places']?[0]?['name'];

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  title: Text(
                                    trip['places']?[0]?['name'] ??
                                        "Unnamed Trip",
                                    style: context.textTheme.bodyMedium,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Total XP: ${trip['total_xp'] ?? 0}",
                                        style: context.textTheme.bodySmall,
                                      ),
                                      if (isThisTheCurrentTrip)
                                        Text(
                                          "Currently Ongoing",
                                          style: context.textTheme.bodySmall!
                                              .copyWith(color: Colors.orange),
                                        ),
                                    ],
                                  ),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () {
                                    // Action: Just view trip details (MapScreen)
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => MapScreen(
                                          parsedResponse: trip,
                                          // isSavedTrip is true only if there is no current trip
                                          isSavedTrip: _currentTrip == null,
                                          // isCurrentTrip is true if the selected saved trip is the ongoing one
                                          isCurrentTrip: isThisTheCurrentTrip,
                                        ),
                                      ),
                                    ).then(
                                      (_) => _loadTrips(),
                                    ); // Reload after returning
                                  },
                                ),
                              );
                            }).toList(),
                          )
                        : Text(
                            "No saved trips yet",
                            style: context.textTheme.bodySmall,
                          ),

                    const SizedBox(height: 20),

                    // Completed Trips
                    Text("Completed Trips", style: context.textTheme.bodyLarge),
                    const SizedBox(height: 12),
                    _oldTrips.isNotEmpty
                        ? Column(
                            children: _oldTrips.map((trip) {
                              return Card(
                                color: context
                                    .colorScheme
                                    .surfaceVariant, // Optional: change color to distinguish
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  // onTap: null // Disabled tap
                                  title: Text(
                                    trip['places']?[0]?['name'] ??
                                        "Unnamed Trip",
                                    style: context.textTheme.bodyMedium!
                                        .copyWith(
                                          color: context
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    "Total XP Earned: ${trip['total_xp'] ?? 0}",
                                    style: context.textTheme.bodySmall,
                                  ),
                                ),
                              );
                            }).toList(),
                          )
                        : Text(
                            "No completed trips yet",
                            style: context.textTheme.bodySmall,
                          ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
