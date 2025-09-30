import 'package:explorex/core/themes/light_theme.dart';
import 'package:explorex/shared/widgets/navbar.dart';

import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';

const apiKey = 'API_KEY';
void main() {
  Gemini.init(apiKey: apiKey);
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      home: const Navbar(),
    );
  }
}
