import 'package:flutter/material.dart';
import 'package:projet/home.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Gestion du parc',
      home: HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
