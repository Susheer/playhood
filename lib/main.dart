import 'package:flutter/material.dart';
import 'package:playhood/home_screen.dart';

void main() {
  runApp(const PlayHood());
}

class PlayHood extends StatelessWidget {
  const PlayHood({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Playhood',
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      home: const HomeScreen(),
    );
  }
}
