import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Vertaling {
  final String nederlands;
  final String engels;
  final String uitspraak;
  const Vertaling({
    required this.nederlands,
    required this.engels,
    required this.uitspraak,
  });

  factory Vertaling.fromJson(Map<String, dynamic> json) {
    return Vertaling(
        nederlands: json['nederlands'] as String,
        engels: json['engels'] as String,
        uitspraak: json['uitspraak'] as String);
  }
}

class Les {
  final String les_naam;
  final String yt_link;
  final List<Vertaling> vertalingen;
  const Les({
    required this.les_naam,
    required this.yt_link,
    required this.vertalingen,
  });
  factory Les.fromJson(Map<String, dynamic> json) {
    var vertalingenFromJson = json['vertalingen'];
    var vertalingenList =
        new List<Map<String, dynamic>>.from(vertalingenFromJson);
    List<Vertaling> vertalingen = List.empty(growable: true);
    vertalingenList.forEach(
        (vertaling) => {vertalingen.add(Vertaling.fromJson(vertaling))});

    return Les(
        les_naam: json['les_naam'] as String,
        yt_link: json['yt_link'] as String,
        vertalingen: vertalingen);
  }
}

// A function that converts a response body into a List<Photo>.
List<Les> parseLes(String responseBody) {
  final parsed = jsonDecode(responseBody).cast<Map<String, dynamic>>();

  return parsed.map<Les>((json) => Les.fromJson(json)).toList();
}

Future<List<Les>> get_process_nl() async {
  String nl_string = await rootBundle.loadString("assets/nl.json");
  return parseLes(nl_string);
}
