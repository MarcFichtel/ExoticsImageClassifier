import 'package:flutter/material.dart';

import 'MainMenu.dart';

class Settings extends StatelessWidget {
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Settings"), centerTitle: true),
      drawer: Drawer(child: MainMenu()),
      body: Center(
        child: RaisedButton(
          onPressed: () { Navigator.pop(context); },
          child: Text('Go back!'),
        ),
      ),
    );
  }
}