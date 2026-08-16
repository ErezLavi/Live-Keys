import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:piano_app/piano/piano_screen.dart';
import 'package:piano_app/piano/piano_screen_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  final pianoPageController = PianoPageController();
  runApp(MyApp(controller: pianoPageController));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.controller});

  final PianoPageController controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChordLens',
      home: PianoPage(controller: controller),
    );
  }
}
