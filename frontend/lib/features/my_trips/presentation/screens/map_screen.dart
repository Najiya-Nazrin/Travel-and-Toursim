import 'dart:convert';
import 'package:explorex/shared/widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:explorex/shared/extension/app_theme_extension.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({
    super.key,
    required this.parsedResponse,
    this.isSavedTrip = false,
    this.isCurrentTrip = false,
  });

  final Map<String, dynamic>? parsedResponse;
  final bool isSavedTrip;
  final bool isCurrentTrip;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  int xp = 0;
  int hp = 100;
  int stamina = 100;
  int maxHp = 100;
  int maxStamina = 100;
  int currentQuestIndex = 0;
  bool journeyStarted = false;

  List quests = [];
  List safeHouses = [];
  List culinary = [];

  List<int> completedQuests = [];
  List<int> completedSafeHouses = [];
  List<int> completedFood = [];

  @override
  void initState() {
    super.initState();
    quests = widget.parsedResponse?["places"] ?? [];
    safeHouses = widget.parsedResponse?["stays"] ?? [];
    culinary = widget.parsedResponse?["food"] ?? [];
    _loadStats();
  }

  Future<void> _loadStats() async {
    final prefs = await SharedPreferences.getInstance();

    if (widget.isCurrentTrip) {
      xp = prefs.getInt("xp") ?? 0;
      maxHp = prefs.getInt("maxHp") ?? 100;
      maxStamina = prefs.getInt("maxStamina") ?? 100;

      hp = prefs.getInt("hp") ?? maxHp;
      stamina = prefs.getInt("stamina") ?? maxStamina;
      currentQuestIndex = prefs.getInt("currentQuestIndex") ?? 0;
      journeyStarted = prefs.getBool("journeyStarted") ?? false;

      completedQuests =
          prefs.getStringList("completedQuests")?.map(int.parse).toList() ?? [];
      completedSafeHouses =
          prefs.getStringList("completedSafeHouses")?.map(int.parse).toList() ??
          [];
      completedFood =
          prefs.getStringList("completedFood")?.map(int.parse).toList() ?? [];
    }

    setState(() {});
  }

  Future<void> _saveStats() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt("xp", xp);
    await prefs.setInt("hp", hp);
    await prefs.setInt("stamina", stamina);
    await prefs.setInt("maxHp", maxHp);
    await prefs.setInt("maxStamina", maxStamina);
    await prefs.setInt("currentQuestIndex", currentQuestIndex);
    await prefs.setBool("journeyStarted", journeyStarted);

    await prefs.setStringList(
      "completedQuests",
      completedQuests.map((e) => e.toString()).toList(),
    );
    await prefs.setStringList(
      "completedSafeHouses",
      completedSafeHouses.map((e) => e.toString()).toList(),
    );
    await prefs.setStringList(
      "completedFood",
      completedFood.map((e) => e.toString()).toList(),
    );
  }

  Future<void> _startJourney() async {
    final prefs = await SharedPreferences.getInstance();
    final tripToStart = widget.parsedResponse!;

    // 1. Set this trip as current
    await prefs.setString("current_trip", jsonEncode(tripToStart));

    // 2. Remove this trip from saved_trips
    final saved = prefs.getStringList("saved_trips") ?? [];
    final savedTripsList = saved
        .map((t) => json.decode(t))
        .toList()
        .cast<Map<String, dynamic>>();

    savedTripsList.removeWhere(
      (t) => t['places']?[0]?['name'] == tripToStart['places']?[0]?['name'],
    );
    await prefs.setStringList(
      "saved_trips",
      savedTripsList.map((t) => jsonEncode(t)).toList(),
    );

    // 3. Reset stats using loaded max values
    xp = 0;
    hp = maxHp > 10 ? maxHp - 10 : maxHp;
    stamina = maxStamina > 10 ? maxStamina - 10 : maxStamina;
    currentQuestIndex = 0;
    completedQuests = [];
    completedSafeHouses = [];
    completedFood = [];

    setState(() {
      journeyStarted = true;
    });

    await _saveStats();
  }

  void _performQuest(int index, int reward) async {
    if (!completedQuests.contains(index) && index == currentQuestIndex) {
      setState(() {
        xp += reward;
        completedQuests.add(index);
        currentQuestIndex++;
        stamina = (stamina - 5).clamp(0, maxStamina);
        hp = (hp - 5).clamp(0, maxHp);
      });
      await _saveStats();

      if (currentQuestIndex >= quests.length) {
        _completeTrip();
      }
    }
  }

  void _useSafeHouse(int index, int restore) async {
    if (!completedSafeHouses.contains(index)) {
      setState(() {
        stamina = (stamina + restore).clamp(0, maxStamina);
        completedSafeHouses.add(index);
      });
      await _saveStats();
    }
  }

  void _eatFood(int index, int restore) async {
    if (!completedFood.contains(index)) {
      setState(() {
        hp = (hp + restore).clamp(0, maxHp);
        completedFood.add(index);
      });
      await _saveStats();
    }
  }

  Future<void> _completeTrip() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove("current_trip");
    await prefs.remove("currentQuestIndex");
    await prefs.remove("journeyStarted");
    await prefs.remove("completedQuests");
    await prefs.remove("completedSafeHouses");
    await prefs.remove("completedFood");

    List<String> oldTrips = prefs.getStringList("old_trips") ?? [];
    oldTrips.add(jsonEncode(widget.parsedResponse));
    await prefs.setStringList("old_trips", oldTrips);

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTripOngoing = widget.isCurrentTrip || journeyStarted;

    return Scaffold(
      appBar: AppBar(
        title: Text("Trip Details", style: context.textTheme.bodyLarge),
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.isSavedTrip && !journeyStarted)
                      CustomButton(
                        label: "Start Journey",
                        onPress: _startJourney,
                        icon: Icons.flag_outlined,
                      ),
                    const SizedBox(height: 16),
                    _buildSection(
                      context,
                      "Quests",
                      quests,
                      rewardKey: "xp",
                      descKey: "description",
                      type: "quest",
                    ),
                    const SizedBox(height: 24),
                    _buildSection(
                      context,
                      "Safe Houses",
                      safeHouses,
                      rewardKey: "stamina",
                      descKey: "location",
                      type: "safe",
                    ),
                    const SizedBox(height: 24),
                    _buildSection(
                      context,
                      "Culinary",
                      culinary,
                      rewardKey: "hp",
                      descKey: "speciality",
                      type: "food",
                    ),
                  ],
                ),
              ),
            ),
            if (isTripOngoing)
              Padding(
                padding: const EdgeInsets.only(left: 24, right: 24, bottom: 16),
                child: _buildStatsRow(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainer,
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 124, 121, 121).withAlpha(90),
            offset: const Offset(0, 2),
            blurRadius: 12,
          ),
        ],
        borderRadius: const BorderRadius.all(Radius.circular(18)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statBox("XP", xp, Colors.blue),
          _statBox("HP", hp, Colors.red, max: maxHp),
          _statBox("Stamina", stamina, Colors.green, max: maxStamina),
        ],
      ),
    );
  }

  Widget _statBox(String label, int value, Color color, {int? max}) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          max != null ? "$value/$max" : "$value",
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    List items, {
    required String rewardKey,
    required String descKey,
    required String type,
  }) {
    if (items.isEmpty) return const SizedBox.shrink();

    final isTripOngoing = widget.isCurrentTrip || journeyStarted;

    // Helper function to determine the button text/color based on type/status
    Map<String, dynamic> getButtonProperties(bool alreadyDone) {
      switch (type) {
        case "quest":
          return {
            'text': alreadyDone ? "Completed" : "Start Quest",
            'color': Colors.blue,
            'action': _performQuest,
            'enabled': !alreadyDone,
          };
        case "safe":
          return {
            'text': alreadyDone ? "Used" : "Save Point",
            'color': Colors.green,
            'action': _useSafeHouse,
            'enabled': !alreadyDone,
          };
        case "food":
          return {
            'text': alreadyDone ? "Tried" : "Try Food",
            'color': Colors.red,
            'action': _eatFood,
            'enabled': !alreadyDone,
          };
        default:
          return {
            'text': 'Action',
            'color': Colors.grey,
            'action': (int i, int r) {},
            'enabled': false,
          };
      }
    }

    // FIX: Determine the section label based on the type
    String getSectionLabel(int index, String sectionTitle) {
      if (type == "quest") {
        return 'LVL ${index + 1}';
      } else if (type == "safe") {
        return 'Base ${index + 1}';
      } else if (type == "food") {
        return 'Cuisine ${index + 1}';
      }
      return '$sectionTitle #${index + 1}';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // FIX: The main section title remains "Quests", "Safe Houses", "Culinary" for clarity
        Text(title, style: context.textTheme.bodyLarge),
        const SizedBox(height: 12),
        ...items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final reward = item[rewardKey] ?? 0;

          bool isQuest = type == "quest";
          bool unlocked = !isQuest || index <= currentQuestIndex;

          bool alreadyDone = isQuest
              ? completedQuests.contains(index)
              : type == "safe"
              ? completedSafeHouses.contains(index)
              : completedFood.contains(index);

          final buttonProps = getButtonProperties(alreadyDone);
          final isButtonEnabled =
              isTripOngoing && unlocked && buttonProps['enabled'];

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. LEFT CONTAINER: LVL/Base/Cuisine No & Reward
                  Container(
                    width: 80, // Slightly increased width for the new labels
                    padding: const EdgeInsets.only(right: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          // FIX: Use the new labels
                          getSectionLabel(index, title),
                          style: context.textTheme.bodySmall!.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.left,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: buttonProps['color'].withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            "$reward ${type == "quest"
                                ? "XP"
                                : type == "safe"
                                ? "STA"
                                : "HP"}",
                            style: context.textTheme.bodySmall!.copyWith(
                              fontWeight: FontWeight.bold,
                              color: buttonProps['color'],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 2. MIDDLE/RIGHT COLUMN: Name, Description, and Button
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item["name"] ?? "Unknown",
                          style: context.textTheme.bodyMedium!.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item[descKey] ?? "",
                          style: context.textTheme.bodySmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        // Full width CustomButton (or similar)
                        SizedBox(
                          width:
                              double.infinity, // Ensure button takes full width
                          child: ElevatedButton(
                            onPressed: isButtonEnabled
                                ? () => buttonProps['action'](index, reward)
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: buttonProps['color'],
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              buttonProps['text'],
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
