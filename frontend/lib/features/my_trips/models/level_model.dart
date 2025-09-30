// Location/Level Model
class TravelLocation {
  final int levelNumber;
  final String name;
  final int xp;
  final bool isSafeHouse;
  final int? stamina; // Only used if isSafeHouse is true

  TravelLocation({
    required this.levelNumber,
    required this.name,
    required this.xp,
    this.isSafeHouse = false,
    this.stamina,
  });
}

// Food/HP Model (For the Legend)
class FoodItem {
  final String name;
  final int hp;
  final String speciality;

  FoodItem({required this.name, required this.hp, required this.speciality});
}
