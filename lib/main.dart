import 'package:flutter/material.dart';
import 'SpeciesIdentification.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  final String title = 'Tarantula Identifier';

  Widget build(BuildContext context) {
    return MaterialApp(
      title: title,
      theme: ThemeData(
        primarySwatch: Colors.deepOrange,
        canvasColor: Colors.white,
      ),
      home: SpeciesIdentification(),
    );
  }
}
