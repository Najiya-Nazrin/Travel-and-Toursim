// File: Home.dart

import 'package:explorex/features/home/models/loc_model.dart';
import 'package:explorex/features/home/presentation/widgets/dashboard.dart';
import 'package:explorex/features/home/presentation/widgets/home_top.dart';
import 'package:explorex/features/home/presentation/widgets/locations.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:explorex/shared/widgets/custom_button.dart';

class Home extends StatefulWidget {
  final VoidCallback? onPlanTripPressed;

  const Home({super.key, this.onPlanTripPressed});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int xp = 0;
  int level = 1;
  String title = "Greenhorn Explorer";

  int hp = 100;
  int stamina = 100;
  int maxHp = 100;
  int maxStamina = 100;

  final List<int> xpThresholds = [0, 50, 200, 500, 1000, 1700, 2500, 3500];

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  // Helper method to show the "Feature to be added later" message
  void _showFeatureComingSoonToast() {
    // Ensure the context is available and the widget is mounted
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Feature to be added later! 🚧"),
          duration: Duration(milliseconds: 1500),
          behavior:
              SnackBarBehavior.floating, // Makes it look more like a toast
        ),
      );
    }
  }

  /// Load stats from SharedPreferences
  Future<void> _loadStats() async {
    final prefs = await SharedPreferences.getInstance();

    xp = prefs.getInt("xp") ?? 0;

    int calculatedLevel = 1;
    for (int i = xpThresholds.length - 1; i >= 0; i--) {
      if (xp >= xpThresholds[i]) {
        calculatedLevel = i + 1;
        break;
      }
    }
    level = calculatedLevel;

    maxHp = prefs.getInt("maxHp") ?? calculateMaxHp(level);
    maxStamina = prefs.getInt("maxStamina") ?? calculateMaxStamina(level);

    if (maxHp != calculateMaxHp(level) ||
        maxStamina != calculateMaxStamina(level)) {
      maxHp = calculateMaxHp(level);
      maxStamina = calculateMaxStamina(level);
      await prefs.setInt("maxHp", maxHp);
      await prefs.setInt("maxStamina", maxStamina);
    }

    hp = prefs.getInt("hp") ?? maxHp;
    stamina = prefs.getInt("stamina") ?? maxStamina;

    title = getTitle(level);

    await prefs.setInt("level", level);

    setState(() {});
  }

  /// Max HP based on level
  int calculateMaxHp(int lvl) => 100 + (lvl - 1) * 15;

  /// Max Stamina based on level
  int calculateMaxStamina(int lvl) => 100 + (lvl - 1) * 20;

  /// Get title for level
  String getTitle(int lvl) {
    if (lvl < 3) return "Greenhorn Explorer";
    if (lvl < 5) return "Seasoned Adventurer";
    if (lvl < 8) return "Wilderness Scout";
    if (lvl < 12) return "Dungeon Delver";
    if (lvl < 17) return "Relic Hunter";
    if (lvl < 23) return "Guardian of the Trails";
    if (lvl < 30) return "Sovereign Pathfinder";
    if (lvl < 40) return "Master Cartographer";
    if (lvl < 55) return "Keeper of Ancient Lore";
    if (lvl < 75) return "World-Wanderer";
    if (lvl < 100) return "Mythic Voyager";
    return "The One Legend";
  }

  /// Gain XP and handle level up
  Future<void> gainXp(int gainedXp) async {
    final prefs = await SharedPreferences.getInstance();
    xp += gainedXp;

    int newLevel = level;
    for (int i = xpThresholds.length - 1; i >= 0; i--) {
      if (xp >= xpThresholds[i]) {
        newLevel = i + 1;
        break;
      }
    }

    if (newLevel != level) {
      level = newLevel;
      title = getTitle(level);

      final newMaxHp = calculateMaxHp(level);
      final newMaxStamina = calculateMaxStamina(level);

      hp = hp + (newMaxHp - maxHp);
      stamina = stamina + (newMaxStamina - maxStamina);

      maxHp = newMaxHp;
      maxStamina = newMaxStamina;
    }

    await prefs.setInt("xp", xp);
    await prefs.setInt("level", level);
    await prefs.setInt("hp", hp);
    await prefs.setInt("stamina", stamina);
    await prefs.setInt("maxHp", maxHp);
    await prefs.setInt("maxStamina", maxStamina);

    setState(() {});
  }

  /// Update HP or Stamina manually (e.g., losing HP/stamina)
  Future<void> updateHpStamina({int? newHp, int? newStamina}) async {
    final prefs = await SharedPreferences.getInstance();
    if (newHp != null) {
      hp = newHp.clamp(0, maxHp);
      await prefs.setInt("hp", hp);
    }
    if (newStamina != null) {
      stamina = newStamina.clamp(0, maxStamina);
      await prefs.setInt("stamina", stamina);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final currentLevelXp = xpThresholds[level - 1];
    final nextLevelXp = (level < xpThresholds.length)
        ? xpThresholds[level]
        : currentLevelXp + 1000;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: SingleChildScrollView(
            child: Column(
              children: [
                HomeTop(name: "Adventurer"),
                const SizedBox(height: 16),
                Dashboard(
                  level: "$level",
                  exp: xp,
                  hp: hp,
                  stamina: stamina,
                  title: title,
                  currentLevelXp: currentLevelXp,
                  nextLevelXp: nextLevelXp,
                  maxHp: maxHp,
                  maxStamina: maxStamina,
                ),
                const SizedBox(height: 16),
                CustomButton(
                  label: "Plan a Trip",
                  onPress: () {
                    widget.onPlanTripPressed?.call();
                  },
                  icon: Icons.location_on_sharp,
                ),
                const SizedBox(height: 16),

                Locations(
                  title: "Explore",
                  locations: [
                    LocModel(
                      path: "assets/images/places/kerala.png",
                      // FIX: Call the toast function on tap
                      onTap: _showFeatureComingSoonToast,
                    ),
                    LocModel(
                      path: "assets/images/places/lakshadweep.png",
                      // FIX: Call the toast function on tap
                      onTap: _showFeatureComingSoonToast,
                    ),
                    LocModel(
                      path: "assets/images/places/karnataka.png",
                      // FIX: Call the toast function on tap
                      onTap: _showFeatureComingSoonToast,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Locations(
                  title: "Events",
                  locations: [
                    LocModel(
                      path: "assets/images/events/diwali.png",
                      // FIX: Call the toast function on tap
                      onTap: _showFeatureComingSoonToast,
                    ),
                    LocModel(
                      path: "assets/images/events/lucknow_mahotsav.png",
                      // FIX: Call the toast function on tap
                      onTap: _showFeatureComingSoonToast,
                    ),
                    LocModel(
                      path: "assets/images/events/carnival.png",
                      // FIX: Call the toast function on tap
                      onTap: _showFeatureComingSoonToast,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
