enum FoodEnum { veg, non }

extension FoodEnumExtension on FoodEnum {
  String get displayName {
    switch (this) {
      case FoodEnum.veg:
        return "Vegetarian";
      case FoodEnum.non:
        return "Non-Vegetarian";
    }
  }
}
