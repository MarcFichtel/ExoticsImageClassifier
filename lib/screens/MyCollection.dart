import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarantula_classifier/data/CollectionMember.dart';
import 'package:tarantula_classifier/util/CollectionHandler.dart';

import 'MainMenu.dart';

class MyCollection extends StatefulWidget {
  MyCollection({Key key}) : super(key: key);
  final String title = 'My Collection';

  _MyCollectionState createState() => _MyCollectionState();
}

class _MyCollectionState extends State<MyCollection> {
  final CollectionHandler _handler = CollectionHandler();

  // buttons for handling selecting, displaying, and editing members
  DisplayMode _displayMode;
  Row buttons;

  FlatButton _sort;
  FlatButton _filter;
  FlatButton _water;
  FlatButton _feed;

  IconButton _noneSelected;
  IconButton _allSelected;
  IconButton _partialSelected;

  Widget _body;
  GridView _grid;
  ListView _list; // todo
  ListView _detail; // todo

  @override
  void initState() {
    super.initState();

    // build body depending on display mode
    try {
      _getDisplayMode().then((mode) {
        if (mode == DisplayMode.details.toString()) { _displayMode = DisplayMode.details; }
        else if (mode == DisplayMode.list.toString()) { _displayMode = DisplayMode.list; }
        else { _displayMode = DisplayMode.grid; }
      });
    }
    catch (e) { print('Error: ' + e); }

    _handler.getCollection().then((collection) => _buildBody(collection, _displayMode));

    _sort = FlatButton(
        onPressed: () => print('Sorting'),
        child: Column(children: [Icon(Icons.sort), Text('Sort')]));
    _filter = FlatButton(
        onPressed: () => print('Filtering'),
        child: Column(children: [Icon(Icons.filter_list), Text('Filter')]));
    _water = FlatButton(
        onPressed: () => print('Watering'),
        child: Column(children: [Icon(Icons.opacity), Text('Water')]));
    _feed = FlatButton(
        onPressed: () => print('Feeding'),
        child: Column(children: [Icon(Icons.bug_report), Text('Feed')]));

    _noneSelected = IconButton(
        icon: Icon(Icons.check_box_outline_blank),
        onPressed: () {
          _buildBottomNavBar(SelectionState.all);
          // todo select all
        });
    _allSelected = IconButton(
        icon: Icon(Icons.check_box),
        onPressed: () {
          _buildBottomNavBar(SelectionState.none);
          // todo select none
        });
    _partialSelected = IconButton(
        icon: Icon(Icons.indeterminate_check_box),
        onPressed: () {
          _buildBottomNavBar(SelectionState.all);
          // todo select all
        });

    _buildBottomNavBar(SelectionState.none);
  }

  /// Load the display mode
  Future<String> _getDisplayMode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('displayMode');
  }

  /// Get the display mode
  Future<void> _setDisplayMode(DisplayMode mode) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('displayMode', mode.toString());
  }

  /// Update the screen body based on display mode
  void _buildBody(final List<CollectionMember> collection, final DisplayMode displayMode) {
    _grid = GridView.count(
      crossAxisCount: 3,
      children: collection.map((member) => GridTile(
          header: Container(
            alignment: Alignment.center,
            child: Text(member.name),
            padding: EdgeInsets.symmetric(vertical: 10),
          ),
          child: GestureDetector(
              onLongPress: () { print('Selected ' + member.name); },
              child: AnimatedContainer(
                curve: Curves.bounceIn,
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.deepOrangeAccent),
                    borderRadius:
                    BorderRadius.all(Radius.circular(10))),
                margin: EdgeInsets.fromLTRB(5, 30, 5, 5),
                child: FlatButton(
                  onPressed: () { print('Pressed member with id ' + member.uuid); },
                  child: null,
                ),
                duration: Duration(seconds: 5),
              )
          )
      )).toList(),
    );

    _list = ListView.builder(
        itemCount: collection.length,
        itemBuilder: (BuildContext context, int index) {
          return ButtonTheme(
              height: 50,
              child: RaisedButton(
                  color: Colors.white,
                  onPressed: () { print('Clicked ' + collection[index].name);},
                  child: Container(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          Text(collection[index].name, style: TextStyle(fontWeight: FontWeight.w300)),
                          Text(collection[index].species, style: TextStyle(fontWeight: FontWeight.w300)),
                        ],
                      )
                  )
              )
          );
        }
    );

    //_detail = ListView.builder(itemBuilder: null);

    setState(() {
      if (displayMode == DisplayMode.grid) {
        print('Building body with grid mode');
        _body = _grid;
      } else if (displayMode == DisplayMode.list) {
        print('Building body with list mode');
        _body = _list;
      } else {
        print('Building body with details mode');
        _body = _detail;
      }
    });
  }

  /// Build bottom button bar depending on selection state
  void _buildBottomNavBar(SelectionState selectionState) {
    Row bottomButtons;
    if (selectionState == SelectionState.none) {
      bottomButtons = Row(children: [
        Container(padding: EdgeInsets.only(top: 5), height: 50, width: 70, child: _noneSelected),
        Container(padding: EdgeInsets.only(top: 5), height: 50, width: 70, child: _sort),
        Container(padding: EdgeInsets.only(top: 5), height: 50, width: 70, child: _filter),
      ]);
    } else if (selectionState == SelectionState.all) {
      bottomButtons = Row(children: [
        Container(padding: EdgeInsets.only(top: 5), height: 50, width: 70, child: _allSelected),
        Container(padding: EdgeInsets.only(top: 5), height: 50, width: 70, child: _sort),
        Container(padding: EdgeInsets.only(top: 5), height: 50, width: 70, child: _filter),
        Container(padding: EdgeInsets.only(top: 5), height: 50, width: 70, child: _water),
        Container(padding: EdgeInsets.only(top: 5), height: 50, width: 70, child: _feed),
      ]);
    } else {
      bottomButtons = Row(children: [
        Container(padding: EdgeInsets.only(top: 5), height: 50, width: 70, child: _partialSelected),
        Container(padding: EdgeInsets.only(top: 5), height: 50, width: 70, child: _sort),
        Container(padding: EdgeInsets.only(top: 5), height: 50, width: 70, child: _filter),
        Container(padding: EdgeInsets.only(top: 5), height: 50, width: 70, child: _water),
        Container(padding: EdgeInsets.only(top: 5), height: 50, width: 70, child: _feed),
      ]);
    }
    setState(() {
      buttons = bottomButtons;
    });
  }

  /// Let user choose a display mode
  Future<void> _addNewMember() async {
    String name;
    String genus = 'Genus';
    String species = 'Species';

    return showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Add Tarantula'),
            content: Column(
              children: [
                TextField(
                  decoration: InputDecoration(labelText: 'Name'),
                  textCapitalization: TextCapitalization.words,
                  onChanged: (nameValue) {
                    name = nameValue;
                  },
                ),
                DropdownButtonFormField<String>(
                  value: genus,
                  items: [
                    DropdownMenuItem<String>(value: genus, child: Text('Brachypelma')),
                    DropdownMenuItem<String>(value: 'Chromatopelma', child: Text('Chromatopelma')),
                    DropdownMenuItem<String>(value: 'Homoeomma', child: Text('Homoeomma')),
                    DropdownMenuItem<String>(value: 'Poecilotheria', child: Text('Poecilotheria')),
                    DropdownMenuItem<String>(value: 'Theraposa', child: Text('Theraposa')),
                  ],
                  onChanged: (genusValue) {
                    // todo populate species dropdown
                    setState(() {
                      genus = genusValue;
                      print('Selected $genusValue');
                    });
                  },
                ),
                DropdownButtonFormField<String>(
                  value: species,
                  items: [
                    DropdownMenuItem<String>(value: species, child: Text('albopilosum')),
                    DropdownMenuItem<String>(value: 'albiceps', child: Text('albiceps')),
                    DropdownMenuItem<String>(value: 'auratum', child: Text('auratum')),
                    DropdownMenuItem<String>(value: 'baumgarteni', child: Text('baumgarteni')),
                    DropdownMenuItem<String>(value: 'smithi', child: Text('smithi')),
                  ],
                  onChanged: (speciesValue) {
                    setState(() {
                      species = speciesValue;
                      print('Selected $speciesValue');
                    });
                  },
                ),
              ],
            ),
            actions: <Widget>[
              RaisedButton(
                onPressed: () {
                  Navigator.pop(context);
                  print('Added new tarantula: ' + name + ' the ' + species);
                  Future<List<CollectionMember>> updatedCollection = _handler.addMember(CollectionMember(name, species, 0, 0, 0));
                  updatedCollection.then((collection) => _buildBody(collection, _displayMode));
                },
                child: const Text('Add', style: TextStyle(color: Colors.white)),
              ),
              FlatButton(
                onPressed: () {
                  Navigator.pop(context);
                  print('Canceled new tarantula');
                },
                child: const Text('Cancel'),
              ),
            ]
          );
        });
  }

  /// Let user choose a display mode
  Future<void> _chooseDisplayMode() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Choose Display Mode'),
          content: Text('How would you like your collection to be displayed?'),
          actions: <Widget>[
            FlatButton(
                onPressed: () {
                  _setDisplayMode(DisplayMode.grid);
                  Navigator.of(context).pop();
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => MyCollection()));
                },
                child: Column(children: [Icon(Icons.grid_on), Text('Grid')])),
            FlatButton(
                onPressed: () {
                  _setDisplayMode(DisplayMode.list);
                  Navigator.of(context).pop();
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => MyCollection()));
                },
                child: Column(children: [Icon(Icons.list), Text('List')])),
            FlatButton(
                onPressed: () {
                  _setDisplayMode(DisplayMode.details);
                  Navigator.of(context).pop();
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => MyCollection()));
                },
                child: Column(children: [Icon(Icons.art_track), Text('Detail')])),
          ],
        );
      },
    );
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text("My Collection"),
          centerTitle: true,
          actions: <Widget>[
            Container(
                padding: EdgeInsets.only(top: 5, right: 5),
                height: 50,
                width: 90,
                child: FlatButton(
                    onPressed: () => _chooseDisplayMode(),
                    child: Column(children: [
                      Icon(Icons.art_track, color: Colors.white),
                      Text('Display', style: TextStyle(color: Colors.white))
                    ]))),
          ]),
      drawer: Drawer(child: MainMenu()),
      body: _body,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton:
      RaisedButton(
        child: Icon(Icons.add, color: Colors.white, size: 50),
        shape: CircleBorder(),
        color: Colors.deepOrangeAccent,
        onPressed: () { _addNewMember(); },
      ),
      bottomNavigationBar: BottomAppBar(child: buttons),
    );
  }
}

/// Enums for displaying and selecting
enum DisplayMode { grid, list, details }
enum SelectionState { none, all, partial }
