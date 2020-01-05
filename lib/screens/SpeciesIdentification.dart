import 'dart:collection';
import 'dart:io';
import 'dart:ui';

import 'package:firebase_admob/firebase_admob.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:image_picker/image_picker.dart';

class SpeciesIdentification extends StatefulWidget {
  SpeciesIdentification({Key key}) : super(key: key);
  final String title = 'Identification';

  _SpeciesIdentificationState createState() => _SpeciesIdentificationState();
}

// homepage state
class _SpeciesIdentificationState extends State<SpeciesIdentification> {

  // Channel used for image classification
  static const _CLASSIFIER_CHANNEL = const MethodChannel('classifier');

  // Image variables
  final Color darkeningColor = Colors.black54;
  final BlendMode darkeningBlendMode = BlendMode.darken;
  Image image = Image.asset('graphics/purdypalps.jpg', fit: BoxFit.scaleDown,);

  // Text variables
  String species1 = 'Chromatopelma cyaneopubescens';
  String species2 = 'Grammostola pulchra';
  String species3 = 'Ceratogyrus marshalli';
  String confidence1 = '55.55%';
  String confidence2 = '25.25%';
  String confidence3 = '5.55%';

  // Admob variables
  final String admobAppId = 'ca-app-pub-7947218986556642~7207687470';
  final String homepageBannerId = 'ca-app-pub-7947218986556642/8189596656';
  final String testDevice = '4A772457DA2E2B37A4FF8564C65A67A4';
  BannerAd _bannerAd;

  /// Initialize state including admob
  @override
  void initState() {
    super.initState();
    FirebaseAdMob.instance.initialize(appId: admobAppId);
    _bannerAd = _createHomepageBannerAd()..load()..show();
  }

  /// Dispose state
  @override
  void dispose() {
    _bannerAd.dispose();
    super.dispose();
  }

  /// Make a new banner ad for the homepage
  BannerAd _createHomepageBannerAd() {
    final MobileAdTargetingInfo targetInfo = MobileAdTargetingInfo(
        testDevices: <String>[testDevice],
        keywords: <String>['tarantula', 'tarantulas', 'spider', 'spiders', 'arachnid', 'arachnids', 'theraposa', 'theraposidae', 'arachnboards']
    );

    return BannerAd(
      adUnitId: homepageBannerId,
      size: AdSize.smartBanner,
      targetingInfo: targetInfo,
      listener: (MobileAdEvent event) {
        print("BannerAd event is $event");
      },
    );
  }

  /// Take an image with device camera
  void _takeImage() async {
    final File imageFile = await ImagePicker.pickImage(source: ImageSource.camera);
    _startClassification(imageFile);
  }

  /// Choose an image from device gallery
  void _uploadImage() async {
    final File imageFile = await ImagePicker.pickImage(source: ImageSource.gallery);
    _startClassification(imageFile);
  }

  /// Start classifier - Update happens when classifier is done
  void _startClassification(final File imageFile) {
    final Image img = Image.file(imageFile);
    setState(() { this.image = img; });
    _CLASSIFIER_CHANNEL.invokeMethod('startClassification', {
      'imageBytes': imageFile.readAsBytesSync()
    });
    _CLASSIFIER_CHANNEL.setMethodCallHandler(updateClassification);
  }

  /// Handler for classifier returning classification results
  Future<dynamic> updateClassification(MethodCall methodCall) async {
    if(methodCall.method == 'updateClassification') {

      // only parse results if there are any
      List<String> classifications = List();
      if (methodCall.arguments.toString() != '{}') {
        classifications = methodCall.arguments.toString()
            .replaceAll('{', '')
            .replaceAll('}', '')
            .replaceAll(' ', '')
            .split(',');
      }
      // sort by confidence DESC
      final SplayTreeMap sortedByConfidence = SplayTreeMap((a, b) => b.compareTo(a));

      for (int i = 0; i < classifications.length; i++) {

        // get label and confidence
        final List<String> parts = classifications[i].split(':');
        final String label = parts[0];
        final String confidence = parts[1];

        // parse to int so tree map can use it as a key
        final int conf = int.parse((double.parse(confidence) * 100).toStringAsFixed(0));
        sortedByConfidence[conf] = label;
      }

      // get first three classifications
      int first, second, third;
      String firstConfidence = 'n/a', firstSpecies = 'n/a',
          secondConfidence = 'n/a', secondSpecies = 'n/a',
          thirdConfidence = 'n/a', thirdSpecies = 'n/a';

      print('SETTING RESULT 1');
      if (classifications.length > 0) {
        first = sortedByConfidence.firstKey();
        firstSpecies = sortedByConfidence[first];
        firstConfidence = (first / 100).toString();
      }

      print('SETTING RESULT 2');
      if (classifications.length > 1) {
        second = sortedByConfidence.firstKeyAfter(first);
        secondSpecies = sortedByConfidence[second];
        secondConfidence = (second / 100).toString();
      }

      print('SETTING RESULT 3');
      if (classifications.length > 2) {
        third = sortedByConfidence.firstKeyAfter(second);
        thirdSpecies = sortedByConfidence[third];
        thirdConfidence = (third / 100).toString();
      }

      print('UPDATING UI');

      // update UI
      setState(() {
        species1 = firstSpecies;
        species2 = secondSpecies;
        species3 = thirdSpecies;
        confidence1 = firstConfidence;
        confidence2 = secondConfidence;
        confidence3 = thirdConfidence;
      });

      print('DONEEE');

    } else {
      throw 'Unknown method call invoked: $methodCall.method';
    }
  }

  /// Show disclaimer about classifier
  Future<void> _showDisclaimer() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Disclaimer'),
          content: Text('Something about how not all tarantulas can be identified visually, how I\'m not an entomologist, etc'),
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

  Widget build(final BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          centerTitle: true,
          actions: [
            Container(
                padding: EdgeInsets.only(top: 15, right: 5),
                height: 100,
                width: 100,
                child: FlatButton(
                    onPressed: () => _showDisclaimer(),
                    child: Column(children: [
                      Icon(Icons.warning, color: Colors.white),
                    ]))),
          ]
        ),
        body: SingleChildScrollView(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                ButtonBar(
                  alignment: MainAxisAlignment.center,
                  children: <Widget>[
                    RaisedButton(onPressed: _takeImage, child: Text('Take image')),
                    RaisedButton(onPressed: _uploadImage, child: Text('Upload image')),
                  ],
                ),
                Container(
                  constraints: BoxConstraints.loose(Size(500, 500)),
                  padding: EdgeInsets.only(left: 16.0, bottom: 8.0, right: 16.0, top: 8.0),
                  margin: EdgeInsets.all(5),
                  decoration: BoxDecoration(image: DecorationImage(
                      image: image.image,
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(darkeningColor, darkeningBlendMode)
                  )),
                  child: Stack(
                    children: <Widget>[
                      Positioned(
                        left: 0, top: 0,
                        child: Text(confidence1, style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 30.0,
                        )),
                      ),
                      Positioned(
                        left: 0, top: 30,
                        child: Text(species1, style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.normal,
                          fontSize: 18.0,
                        )),
                      ),
                      Positioned(
                        left: 0, top: 75,
                        child: Text(confidence2, style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 25.0,
                        )),
                      ),
                      Positioned(
                        left: 0, top: 100,
                        child: Text(species2, style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.normal,
                          fontSize: 18.0,
                        )),
                      ),
                      Positioned(
                        left: 0, top: 150,
                        child: Text(confidence3, style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20.0,
                        )),
                      ),
                      Positioned(
                        left: 0, top: 170,
                        child: Text(species3, style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.normal,
                          fontSize: 18.0,
                        )),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        )
    );
  }
}
