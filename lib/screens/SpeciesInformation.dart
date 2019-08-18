import 'package:flutter/material.dart';

import 'MainMenu.dart';

class SpeciesInformation extends StatefulWidget {
  SpeciesInformation({Key key}) : super(key: key);
  final String title = 'Species Information';

  _SpeciesInformationState createState() => _SpeciesInformationState();
}

class _SpeciesInformationState extends State<SpeciesInformation> {
  final Map<String, List<String>> speciesByGenus = {
    'Brachypelma': ['albopilosum', 'albiceps', 'auratum', 'baumgarteni', 'boehmei', 'emilia', 'fossorium', 'hamorii', 'klaasi', 'sabulosum', 'smithi'],
    'Homoeomma': ['chilensis'],
    'Theraposa': ['apophis', 'blondi', 'stirmi']
  };

  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text("Species Information"), centerTitle: true),
        drawer: Drawer(child: MainMenu()),
        body:
            SingleChildScrollView(child: Container(child: buildSpeciesList())));
  }

  Widget buildSpeciesList() {
    final List<ExpansionPanelRadio> radios = List<ExpansionPanelRadio>();
    for (MapEntry entry in speciesByGenus.entries) {
      final String genus = entry.key;
      final List<String> species = entry.value;
      radios.add(ExpansionPanelRadio(
          value: genus,
          canTapOnHeader: true,
          headerBuilder: (BuildContext context, bool isExpanded) {
            return ListTile(
                title: Text(genus,
                    style:
                        TextStyle(fontSize: 22, fontWeight: FontWeight.w300)));
          },
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: species.map<FlatButton>((String sp) {
              return FlatButton(
                  onPressed: () {
                    print('Selected species $genus $sp');
                  },
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(sp,
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w400)),
                  ));
            }).toList(),
          )));
    }
    return ExpansionPanelList.radio(children: radios);
  }
}
