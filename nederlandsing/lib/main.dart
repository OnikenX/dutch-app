// Copyright 2018 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ffi';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'parser.dart';
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

final _biggerFont = const TextStyle(fontSize: 18.0);

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nederlandsing',
      home: Nederlandsing(),
      themeMode: ThemeMode.system,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
    );
  }
}

class _NederlandsingState extends State<Nederlandsing> {
  var isInALes = false;
  var whichLes = 0;
  final Future<List<Les>> nl = Future<List<Les>>.sync(() => get_process_nl());

  Widget makeMenu() {
    var itemCount = widget.lessen.length +
        (widget.lessen.length > 1 ? widget.lessen.length - 1 : 0);
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemBuilder: (context, i) {
        if (i.isOdd) return const Divider(); /*2*/
        final int index = i ~/ 2;
        return ListTile(
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    settings: RouteSettings(),
                      builder: (context) => _LesWoordenState(
                            les: widget.lessen[index],
                          )));
            },
            title: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              // clipBehavior: Clip.hardEdge,
              child: Text(
                widget.lessen[index].les_naam,
                style: _biggerFont,
              ),
            ));
      },
      itemCount: itemCount,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        // backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text('Nederlandsing'),
        ),
        body: FutureBuilder<List<Les>>(
          future: nl, // a previously-obtained Future<String> or null
          builder: (BuildContext context, AsyncSnapshot<List<Les>> snapshot) {
            Widget state = Text("Undefined");
            if (snapshot.hasData) {
              if (widget.lessen.isEmpty) {
                widget.lessen = snapshot.data!;
              }
              state = makeMenu();
            } else if (snapshot.hasError) {
              state = Text('Error: ${snapshot.error}');
            } else {
              state = const Center(
                child: FittedBox(
                  child: CircularProgressIndicator.adaptive(),
                  fit: BoxFit.fill,
                  clipBehavior: Clip.hardEdge,
                  alignment: Alignment.center,
                ),
              );
            }
            return state;
          },
        ));
  }
}

class Nederlandsing extends StatefulWidget {
  Nederlandsing({Key? key}) : super(key: key);
  var lessen = List<Les>.empty(growable: true);

  @override
  _NederlandsingState createState() => _NederlandsingState();
}

class _LesWoordenState extends StatelessWidget {
  final Les les;
  final AudioPlayer audioPlayer = AudioPlayer();
  _LesWoordenState({required this.les});
  var audios = <String, Uint8List>{};
  //giving the
  Future playAudio(String text, String coded) async {
    var audio;
    if (audios.containsKey(text)) {
      audio = audios[text]!;
    } else {
      audio = base64Decode(coded);
      audios[text] = audio;
    }
    await audioPlayer.playBytes(audio);
  }

  Future _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      print('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    //if he is in a lesson
    // ignore: non_constant_identifier_names
    var n_vertalingen = les.vertalingen.length;
    var itemCount = n_vertalingen + (n_vertalingen > 1 ? n_vertalingen - 1 : 0);
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text(les.les_naam)),
        actions: [
          IconButton(
              onPressed: () => {Future<void>.value(_launchURL(les.yt_link))},
              icon: const Image(image: AssetImage("assets/youtube.png")))
        ],
      ),
      body: ListView.builder(
        clipBehavior: Clip.antiAlias,
        itemBuilder: (context, i) {
          if (i.isOdd) return const Divider(); /*2*/
          final int index = i ~/ 2;
          var vertaling = les.vertalingen[index];
          return ListTile(
              onTap: () {
                Future.value(
                    playAudio(vertaling.nederlands, vertaling.uitspraak));
              },
              title: FittedBox(
                clipBehavior: Clip.hardEdge,
                fit: BoxFit.scaleDown,
                child: Row(
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      clipBehavior: Clip.hardEdge,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        vertaling.nederlands,
                        style: _biggerFont,
                      ),
                    ),
                    const Text(
                      " | ",
                    ),
                    FittedBox(
                      fit: BoxFit.cover,
                      clipBehavior: Clip.hardEdge,
                      alignment: Alignment.centerRight,
                      child: Text(
                        vertaling.engels,
                        style: _biggerFont,
                      ),
                    )
                  ],
                ),
              ));
        },
        itemCount: itemCount,
      ),
    );
  }
}
