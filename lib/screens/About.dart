import 'package:flutter/material.dart';

import 'MainMenu.dart';

class About extends StatelessWidget {
  final double textSize = 15;
  final double textPadding = 15;

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("About"), centerTitle: true),
        drawer: Drawer(child: MainMenu()),
      body:  Column(
          children: <Widget>[
            Container(
              padding: EdgeInsets.all(textPadding),
              child: Text(
                'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: textSize, fontWeight: FontWeight.w300),
              ),
            ),
            Container(
              padding: EdgeInsets.all(textPadding),
              child: Text(
                'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: textSize, fontWeight: FontWeight.w300),
              ),
            ),
          ]
      )
    );
  }
}