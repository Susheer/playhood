import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Playhood')),
      body: const Center(
        child: Text(
          'Welcome to Playhood 🎧',
          style: TextStyle(fontSize: 22),
        ),
      ),
    );
  }
}
