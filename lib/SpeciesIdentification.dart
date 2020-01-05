import 'dart:collection';
import 'dart:io';
import 'package:firebase_admob/firebase_admob.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:image_picker/image_picker.dart';

/// Tarantula Identifier Widget
class SpeciesIdentification extends StatefulWidget {
  SpeciesIdentification({Key key, String title}) : super(key: key);
  final String title = 'Tarantula Identifier';

  _SpeciesIdentificationState createState() => _SpeciesIdentificationState();
}

/// Identification states
enum IdentificationState { Done, Failed, Idle, InProgress }

/// Tarantula Identifier State
class _SpeciesIdentificationState extends State<SpeciesIdentification> {

  // Android native variables
  static const _CLASSIFIER_CHANNEL = const MethodChannel('classifier');
  static const _START_CLASSIFY = 'startClassification';
  static const _DONE_CLASSIFY = 'doneClassification';

  // Text styles
  final TextStyle _headerStyle = TextStyle(color: Colors.white, fontSize: 20);
  final TextStyle _bodyStyle = TextStyle(color: Colors.white, fontSize: 18);

  // Classification state is idle at startup
  IdentificationState _state = IdentificationState.Idle;
  int _numClassifications = 0;

  // Classification result sorted by confidence
  final SplayTreeMap _classificationResult = SplayTreeMap((a, b) => b.compareTo(a));

  // Map results to their properly format 'Genus species'
  final Map<String, String> _formattedSpecies = {
    'Acanthoscurriageniculata':'Acanthoscurria geniculata',
    'Aphonopelmachalcodes':'Aphonopelma chalcodes',
    'Aphonopelmaseemanni':'Aphonopelma seemanni',
    'Aviculariaavicularia':'Avicularia avicularia',
    'Brachypelmaalbopilosum':'Brachypelma albopilosum',
    'Brachypelmaboehmei':'Brachypelma boehmei',
    'Brachypelmahamorii':'Brachypelma hamorii',
    'Brachypelmavagans':'Brachypelma vagans',
    'Caribenaversicolor':'Caribena versicolor',
    'Chromatopelmacyaneopubescens':'Chromatopelma cyaneopubescens',
    'Grammostolapulchra':'Grammostola pulchra',
    'Grammostolapulchripes':'Grammostola pulchripes',
    'Lasiodoraparahybana':'Lasiodora parahybana',
    'Monocentropusbalfouri':'Monocentropus balfouri',
    'Nhanduchromatus':'Nhandu chromatus',
    'Poecilotheriaornata':'Poecilotheria ornata',
    'Poecilotheriaregalis':'Poecilotheria regalis',
    'Psalmopoeuscambridgei':'Psalmopoeus cambridgei',
    'Psalmopoeusirminia':'Psalmopoeus irminia',
    'Pterinochilusmurinus':'Pterinochilus murinus',
    'Theraphosastirmi':'Theraphosa stirmi'
  };

  // Image display variables
  final Color _darkeningColor = Colors.black54;
  final BlendMode _darkeningBlendMode = BlendMode.darken;
  Image _image = Image.asset('assets/purdypalps.jpg', fit: BoxFit.scaleDown,);

  // Admob variables
  final String _admobAppId = 'ca-app-pub-7947218986556642~7207687470';
  final String _interstitialId = 'ca-app-pub-7947218986556642/3281323550';
  final String _testDevice = 'EBEC53C82AA4D5C4DF8D081E94AEAFBE';
  final int _adPerClassificationsRate = 10;
  InterstitialAd _interstitialAd;

  /// Init state incl admob
  void initState() {
    super.initState();
    FirebaseAdMob.instance.initialize(appId: _admobAppId);
    _interstitialAd = _createInterstitialAd()..load();
  }

  /// Dispose state incl admob
  void dispose() {
    _interstitialAd.dispose();
    super.dispose();
  }

  /// Make a new interstitial ad
  InterstitialAd _createInterstitialAd() {
    return InterstitialAd(
      adUnitId: _interstitialId, //InterstitialAd.testAdUnitId,
      targetingInfo: MobileAdTargetingInfo(
          testDevices: [_testDevice],
          keywords: ['tarantula', 'tarantulas', 'spider', 'spiders', 'arachnid', 'arachnids', 'theraposa', 'theraposidae', 'identify', 'identifier', 'classify', 'classifier', 'purdypalps']
      ),
      listener: (MobileAdEvent event) {
        print("InterstitialAd event is $event");
      },
    );
  }

  /// Take an image with device camera
  void _takeImage() async {
    final File imageFile = await ImagePicker.pickImage(source: ImageSource.camera);
    _startClassify(imageFile);
  }

  /// Choose an image from device gallery
  void _pickImage() async {
    final File imageFile = await ImagePicker.pickImage(source: ImageSource.gallery);
    _startClassify(imageFile);
  }

  /// Start classification
  void _startClassify(final File imageFile) {

    // Display chosen image and spinner while classifying
    setState(() {
      _image = Image.file(imageFile);
      _state = IdentificationState.InProgress;
    });

    // Classify
    _CLASSIFIER_CHANNEL.invokeMethod(_START_CLASSIFY, {
      'imageBytes': imageFile.readAsBytesSync()
    });
    _CLASSIFIER_CHANNEL.setMethodCallHandler(_onClassifyComplete);
  }

  /// Complete classification
  /// NB must have return type of Future<dynamic>
  Future<dynamic> _onClassifyComplete(MethodCall methodCall) {

    // show an interstitial if classifications per ad quota reached and load next
    _numClassifications++;
    if (_numClassifications % _adPerClassificationsRate == 0) {
      _interstitialAd..show();
      _interstitialAd = _createInterstitialAd()..load();
    }

    // Classification considered failed, if wrong method called or result is empty
    if(methodCall.method != _DONE_CLASSIFY || methodCall.arguments.toString() == '{}') {
      setState(() {
        _state = IdentificationState.Failed;
      });
    }

    // Success, display results
    else {
      final List<String> classifications = methodCall.arguments.toString()
          .replaceAll('{', '')
          .replaceAll('}', '')
          .replaceAll(' ', '')
          .split(',');

      // clear previous classification results
      _classificationResult.clear();

      // sort by confidence DESC
      for (int i = 0; i < classifications.length; i++) {

        // get label and confidence
        final List<String> parts = classifications[i].split(':');
        final String label = _formattedSpecies[parts[0]];
        final String confidence = parts[1];

        // parse to int so tree map can use it as a key
        final int conf = int.parse((double.parse(confidence) * 100).toStringAsFixed(0));
        _classificationResult[conf] = label;
      }

      setState(() {
        _state = IdentificationState.Done;
      });
    }
  }

  /// Show info about supported species
  Future<void> _showInformation() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('The following species are currently supported'),
          content: Text(
                  '\n• Acanthoscurria geniculata'
                  '\n• Aphonopelma chalcodes'
                  '\n• Aphonopelma seemanni'
                  '\n• Avicularia avicularia'
                  '\n• Brachypelma albopilosum'
                  '\n• Brachypelma boehmei'
                  '\n• Brachypelma hamorii'
                  '\n• Brachypelma vagans'
                  '\n• Caribena versicolor'
                  '\n• Chromatopelma cyaneopubescens'
                  '\n• Grammostola pulchra'
                  '\n• Grammostola pulchripes'
                  '\n• Lasiodora parahybana'
                  '\n• Monocentropus balfouri'
                  '\n• Nhandu chromatus'
                  '\n• Poecilotheria ornata'
                  '\n• Poecilotheria regalis'
                  '\n• Psalmopoeus cambridgei'
                  '\n• Psalmopoeus irminia'
                  '\n• Pterinochilus murinus'
                  '\n• Theraphosa stirmi',
          style: TextStyle(fontSize: 13),),
          actions: [
            FlatButton(
                onPressed: () { Navigator.of(context).pop(); },
                child: Column(children: [Text('OK')])
            ),
          ],
        );
      },
    );
  }

  /// Show disclaimer about classifier
  Future<void> _showDisclaimer() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Disclaimer'),
          content: Text(
              'Please be aware that not all tarantula species can be identified visually. '
              'If a human cannot spot the difference, this app likely won\'t be able to, either.'),
          actions: <Widget>[
            FlatButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Column(children: [Text('OK')])),
          ],
        );
      },
    );
  }

  /// Build
  /// TODO find a better way to position in top right than padding
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text(widget.title), centerTitle: true),
        floatingActionButton: Container(padding: EdgeInsets.only(left: 250), child: _buildActionButtons()),
        floatingActionButtonLocation: FloatingActionButtonLocation.miniStartTop,
        body: SingleChildScrollView(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildButtonBar(),
                  _buildIdentificationBody()
                ],
              ),
            )
        )
    );
  }

  /// Action buttons
  Row _buildActionButtons() {
    return Row(
      children: [
        FloatingActionButton(
            backgroundColor: Colors.white,
            child: Icon(Icons.info, color: Colors.deepOrange,),
            mini: true,
            onPressed: () { _showInformation(); }
        ),
        FloatingActionButton(
            backgroundColor: Colors.white,
            child: Icon(Icons.warning, color: Colors.deepOrange,),
            mini: true,
            onPressed: () { _showDisclaimer(); }
        ),
      ],
    );
  }

  /// Button bar
  ButtonBar _buildButtonBar() {
    return ButtonBar(
        alignment: MainAxisAlignment.center,
        children: [
          RaisedButton(onPressed: _takeImage, child: Text('Camera')),
          RaisedButton(onPressed: _pickImage, child: Text('Gallery')),
        ]
    );
  }

  /// Body (state-dependent)
  /// TODO label is one word, i.e. genusspecies
  Container _buildIdentificationBody() {
    List<Widget> items = List();

    // Done identifying, show results
    if (_state == IdentificationState.Done) {
      int numResultsDisplaying = 0;

      for (MapEntry entry in _classificationResult.entries) {
        final String cParsed = entry.key.toString();
        final String confidence = cParsed.substring(0, 2) + '.' + cParsed.substring(2, cParsed.length) + '%';
        items.add(Text(entry.value, style: _headerStyle, textAlign: TextAlign.left));
        items.add(Text(confidence + '\n', style: _bodyStyle, textAlign: TextAlign.left));

        // Show only up to 5 reults
        numResultsDisplaying++;
        if (numResultsDisplaying == 5) {
          break;
        }
      }
    }

    // Identification in progress, show spinner
    else if (_state == IdentificationState.InProgress) {
      items.add(SpinKitCircle(color: Colors.white, size: 100.0));
      items.add(Text('\nIdentifying...', style: _bodyStyle));
    }

    // An error occurred =<
    else if (_state == IdentificationState.Failed) {
      items.add(Text('An error occurred. Please try again.',
          style: _headerStyle, textAlign: TextAlign.center));
    }

    // Idle, i.e. after startup, show instructions
    else {
      items.add(Text('Welcome to\nTarantula Identifier!',
          style: _headerStyle, textAlign: TextAlign.center));
      items.add(Text('\nStart by selecting an image with the buttons at the top of the screen.'
          '\n\nThe results will appear here.',
          style: _bodyStyle, textAlign: TextAlign.center));
    }

    return Container(
        constraints: BoxConstraints.expand(width: 500, height: 500),
        padding: EdgeInsets.only(left: 16.0, bottom: 8.0, right: 16.0, top: 8.0),
        margin: EdgeInsets.all(5),
        decoration: BoxDecoration(
            image: DecorationImage(
                image: _image.image,
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(_darkeningColor, _darkeningBlendMode)
            )
        ),
        child: Column(
          children: items,
          mainAxisAlignment: MainAxisAlignment.center
        )
    );
  }
}
