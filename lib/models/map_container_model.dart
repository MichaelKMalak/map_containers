import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:geoflutterfire/geoflutterfire.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

///For a production app, this model should better be immutable (built_value)
class MapContainer {
  MapContainer({
    @required this.position,
    @required this.name,
    this.fullnessRate = '40.0',
    this.currentCollection = 'H3',
    this.nextCollection = 'H4',
    this.createdAt,
  });

  factory MapContainer.fromJson(Map<String, dynamic> json) {
    final geoPoint = json['position']['geopoint'] as GeoPoint;
    final createdAt = json['dateCreatedUtc'] as Timestamp;
    return MapContainer(
      name: json['name'] as String,
      position: LatLng(geoPoint.latitude, geoPoint.longitude),
      fullnessRate: json['fullnessRate'] as String,
      createdAt: createdAt?.toDate(),
      currentCollection: json['currentCollection'] as String,
      nextCollection: json['nextCollection'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};

    data['name'] = name;
    data['position'] = GeoFirePoint(position.latitude, position.longitude).data;
    data['currentCollection'] = currentCollection;
    data['nextCollection'] = nextCollection;
    data['fullnessRate'] = fullnessRate;
    data['dateCreatedUtc'] = createdAt?.toUtc() ?? DateTime.now();

    return data;
  }

  final String name;
  final LatLng position;
  final String currentCollection;
  final String nextCollection;
  String fullnessRate;
  DateTime createdAt;
}
