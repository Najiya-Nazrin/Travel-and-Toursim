import 'package:flutter/material.dart';

enum PlanEnum {
  quests(
    title: "Quests & Landmarks 🏛️",
    type: "places",
    reward: "xp",
    rewardType: "XP",
    subTitle: "description",
    color: Color(0xffea580c),
    bgColor: Color(0xffffedd5),
  ),
  safePlaces(
    title: "Safe Place 🏨",
    type: "stays",
    reward: "stamina",
    rewardType: "Stamina",
    subTitle: "location",
    color: Color(0xff1d4ed8),
    bgColor: Color(0xffdbeafe),
  ),
  food(
    title: "Culinary Power-Ups 🍚",
    type: "food",
    reward: "hp",
    rewardType: "HP",
    subTitle: "speciality",
    color: Color(0xff16a34a),
    bgColor: Color(0xffdcfce7),
  );

  const PlanEnum({
    required this.title,
    required this.type,
    required this.reward,
    required this.rewardType,
    required this.color,
    required this.bgColor,
    required this.subTitle,
  });
  final String title;
  final String type;
  final String reward;
  final String rewardType;
  final String subTitle;
  final Color color;
  final Color bgColor;
}
