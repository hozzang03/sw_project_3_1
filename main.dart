import 'package:flutter/material.dart';
import 'screens/title_youtube.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '한 끼 YoutubePage',
      theme: ThemeData(primarySwatch: Colors.orange),
      home: const TitleYoutube(),
    );
  }
}
