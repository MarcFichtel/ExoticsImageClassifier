import 'package:flutter/material.dart';
import 'package:tarantula_classifier/screens/About.dart';
import 'package:tarantula_classifier/screens/MyCollection.dart';
import 'package:tarantula_classifier/screens/Settings.dart';
import 'package:tarantula_classifier/screens/SpeciesInformation.dart';
import 'package:tarantula_classifier/screens/SpeciesIdentification.dart';

class MainMenu extends StatefulWidget {
  MainMenu({Key key}) : super(key: key);
  final String title = 'Menu';

  _MainMenuState createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {
  final double buttonEdgeInsets = 5;
  final double buttonHeight = 50;
  final double buttonTextSize = 22;

  //final Color buttonColor = Colors.deepOrangeAccent;
  //final Color buttonTextColor = Colors.white;
  final List<String> buttonText = <String>[
    'My Collection',
    'Species Information',
    'Species Identification',
    'Settings',
    'About'
  ];
  final List<Icon> buttonIcons = <Icon>[
    Icon(Icons.apps),
    Icon(Icons.info_outline),
    Icon(Icons.search),
    Icon(Icons.build),
    Icon(Icons.thumb_up),
  ];

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title), centerTitle: true),
      body: ListView.separated(
        padding: EdgeInsets.all(buttonEdgeInsets),
        itemCount: buttonText.length,
        itemBuilder: (BuildContext context, int index) {
          return ButtonTheme(
              height: buttonHeight,
              child: FlatButton(
                  onPressed: () {
                    Navigator.pop(context);
                    if (index == 0) Navigator.push(context, MaterialPageRoute(builder: (context) => MyCollection()));
                    else if (index == 1) Navigator.push(context, MaterialPageRoute(builder: (context) => SpeciesInformation()));
                    else if (index == 2) Navigator.push(context, MaterialPageRoute(builder: (context) => SpeciesIdentification()));
                    else if (index == 3) Navigator.push(context, MaterialPageRoute(builder: (context) => Settings()));
                    else Navigator.push(context, MaterialPageRoute(builder: (context) => About()));
                  },
                  child: Row(children: <Widget>[
                    buttonIcons[index],
                    Text(
                      '  ${buttonText[index]}',
                      style: TextStyle(
                          fontSize: buttonTextSize,
                          fontWeight: FontWeight.w300),
                    ),
                  ])
              )
          );
        },
        separatorBuilder: (BuildContext context, int index) => const Divider(
          color: Colors.white,
        ),
      ),
    );
  }
}
