import 'package:flutter/cupertino.dart';
import 'package:geoflutterfire/geoflutterfire.dart';

///For a production app, this model should better be immutable (built_value)
class Container {
  Container({
    @required this.position,
    @required this.name,
    @required this.fullnessRate,

    this.currentCollection = 'H3',
    this.nextCollection = 'H4',
    this.createdAt,
  });

  factory Container.fromJson(Map<String, dynamic> json) {
    return Container(
      name: json['name'] as String,
      position: json['position'] as GeoFirePoint,
      fullnessRate: json['fullnessRate'] as String,
      createdAt: DateTime.parse(json['dateCreatedUtc'] as String),
      currentCollection: json['currentCollection'] as String,
      nextCollection: json['nextCollection'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};

    data['name'] = name;
    data['position'] = position.data;
    data['currentCollection'] = currentCollection;
    data['nextCollection'] = nextCollection;
    data['fullnessRate'] = fullnessRate;
    data['dateCreatedUtc'] = createdAt.toUtc();

    return data;
  }

  final String name;
  final GeoFirePoint position;
  final String currentCollection;
  final String nextCollection;
  String fullnessRate;
  DateTime createdAt;

}