import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geoflutterfire/geoflutterfire.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:map_containers/models/container.dart';

class Repository {
  Repository(this._firestore, this._geo)
      : assert(_firestore != null, _geo != null);

  final FirebaseFirestore _firestore;
  final Geoflutterfire _geo;

  Stream<List<MapContainer>> getContainers(LatLng centerPoint, double rad) {
    final ref = _firestore.collection('locations');
    final center = _geo.point(
        latitude: centerPoint.latitude, longitude: centerPoint.longitude);
    return _geo
        .collection(collectionRef: ref)
        .within(
          center: center,
          radius: rad,
          field: 'position',
          //strictMode: true,
        )
        .map(toMapContainers);
  }

  List<MapContainer> toMapContainers(List<DocumentSnapshot> documentList) {
    return documentList
        .map((document) => MapContainer.fromJson(document.data()))
        .toList();
  }

  Future<void> updateContainersPosition(MapContainer container) {
    return _firestore
        .collection('locations')
        .doc(container.name)
        .set(container.toJson());
  }
}
