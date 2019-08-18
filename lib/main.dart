import 'package:flutter/material.dart';

import 'screens/MyCollection.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  final String title = 'DeBug';

  Widget build(BuildContext context) {
    return MaterialApp(
      title: title,
      theme: ThemeData(
        primarySwatch: Colors.deepOrange,
        canvasColor: Colors.white,
      ),
      home: MyCollection(),
    );
  }
}
