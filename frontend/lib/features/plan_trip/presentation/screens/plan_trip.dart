import 'dart:convert';
import 'package:explorex/features/plan_trip/utils/food_enum.dart';
import 'package:explorex/features/plan_trip/presentation/widgets/plan.dart';
import 'package:explorex/features/plan_trip/presentation/widgets/plan_date_picker.dart';
import 'package:explorex/features/plan_trip/presentation/widgets/plan_textfield.dart';
import 'package:explorex/shared/extension/app_theme_extension.dart';
import 'package:explorex/shared/widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PlanTrip extends StatefulWidget {
  const PlanTrip({super.key});
  @override
  State<PlanTrip> createState() => _PlanTripState();
}

class _PlanTripState extends State<PlanTrip> {
  TextEditingController source = TextEditingController();
  TextEditingController destination = TextEditingController();
  FoodEnum? _foodType = FoodEnum.non;
  bool _loading = false;
  // ignore: unused_field
  String? _response;

  DateTimeRange _selectedDateRange = DateTimeRange(
    start: DateTime.now(),
    end: DateTime.now().add(const Duration(days: 1)),
  );
  Map<String, dynamic>? _parsedResponse;

  Future<void> _pickDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 2),
      initialDateRange: _selectedDateRange,
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  Future<void> generateTrip(String source, String destination) async {
    setState(() {
      _loading = true;
      _response = null;
    });
    String foodPreference = _foodType?.displayName ?? "Any";
    String prompt =
        """
Plan a cultural trip from $source to $destination 
from the date ${DateFormat('dd MMM yyyy').format(_selectedDateRange.start)} 
to ${DateFormat('dd MMM yyyy').format(_selectedDateRange.end)}.

Food preference: $foodPreference.

Suggest places, places to stay, and food to try at each point of interest. 
Also include the dates at each place.
Return JSON with keys: places, stays, food, total_xp.
- Each place should have: name, xp, description.
- Each stay should have: name, location, stamina (stamina points).
- Each food should have: name, speciality, hp (health points).
Example:
{
  "places": [
    { "name": "Guruvayur", "xp": 150, "description": "22 Jan 2025 to 23 Jan 2025: Guruvayur is a pilgrimage town in the southwest Indian state of Kerala. It’s known for centuries-old, red-roofed Guruvayur Temple, where Hindu devotees make offerings of fruit, spices or coins, often equivalent to their own weight." }
  ],
  "stays": [
    { "name": "Lakshmi Inn 22 Jan 2025 to 23 Jan 2025:", "location": "Mamiyoor, Guruvayur", "stamina": 100 }
  ],
  "food": [
    { "name": "Masala Dosa", "speciality": "Masala dosa is a dish of South India, consisting of a savoury dosa crepe stuffed with a spiced potato curry. It is a popular breakfast item in South India.", "hp": 150 }
  ],
  "total_xp": 1200
}
""";

    try {
      final value = await Gemini.instance.prompt(parts: [Part.text(prompt)]);
      final raw = value?.output ?? "No response";

      Map<String, dynamic>? jsonResponse;

      try {
        jsonResponse = json.decode(raw);
      } catch (e) {
        final cleaned = raw
            .replaceAll("```json", "")
            .replaceAll("```", "")
            .trim();
        jsonResponse = json.decode(cleaned);
      }

      setState(() {
        _response = raw;
        _parsedResponse = jsonResponse;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _response = "Error: $e";
        _loading = false;
      });
    }
  }

  Future<void> saveForLater() async {
    if (_parsedResponse == null) return;
    final prefs = await SharedPreferences.getInstance();
    final savedTrips = prefs.getStringList("saved_trips") ?? [];
    savedTrips.add(json.encode(_parsedResponse));
    await prefs.setStringList("saved_trips", savedTrips);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Trip saved for later 💾")));
    }
  }

  Future<void> setAsCurrentTrip() async {
    if (_parsedResponse == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("current_trip", json.encode(_parsedResponse));
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Set as current trip 🚀")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Plan your Trip", style: context.textTheme.bodyLarge),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: SingleChildScrollView(
          child: Column(
            spacing: 12,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PlanTextfield(
                controller: source,
                label: "Source",
                icon: Icons.flight_takeoff_outlined,
              ),
              PlanTextfield(
                controller: destination,
                label: "Destination",
                icon: Icons.flight_land_outlined,
              ),
              PlanDatePicker(
                pickDateRange: _pickDateRange,
                selectedDateRange: _selectedDateRange,
              ),
              RadioGroup<FoodEnum>(
                groupValue: _foodType,
                onChanged: (FoodEnum? value) {
                  setState(() {
                    _foodType = value;
                  });
                },
                child: const Row(
                  children: <Widget>[
                    Expanded(
                      child: ListTile(
                        title: Text('Non-Veg'),
                        leading: Radio<FoodEnum>(value: FoodEnum.non),
                      ),
                    ),
                    Expanded(
                      child: ListTile(
                        title: Text('Veg'),
                        leading: Radio<FoodEnum>(value: FoodEnum.veg),
                      ),
                    ),
                  ],
                ),
              ),
              CustomButton(
                label: "Generate Plan",
                onPress: () {
                  generateTrip(source.text, destination.text);
                },
                icon: Icons.flight_rounded,
              ),

              if (_loading) const Center(child: CircularProgressIndicator()),

              if (!_loading && _parsedResponse != null)
                Plan(
                  parsedResponse: _parsedResponse,
                  saveForLater: saveForLater,
                  setAsCurrentTrip: setAsCurrentTrip,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
