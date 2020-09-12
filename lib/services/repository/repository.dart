import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geoflutterfire/geoflutterfire.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class Repository {
  Repository(this._firestore, this._geo): assert(_firestore != null, _geo != null);

  final FirebaseFirestore _firestore;
  final Geoflutterfire _geo;

  Stream<List<DocumentSnapshot>> getContainers(LatLng centerPoint, double rad) {
    final ref = _firestore.collection('locations');
    final center = _geo.point(latitude: centerPoint.latitude, longitude: centerPoint.longitude);
    return _geo.collection(collectionRef: ref).within(
      center: center,
      radius: rad,
      field: 'position',
      //strictMode: true,
    );
  }

  Future<void> updateContainersPosition(String id, LatLng newLatLng) {
    final point = _geo.point(latitude: newLatLng.latitude, longitude: newLatLng.longitude);
    return _firestore
        .collection('locations')
        .doc(id)
        .set(<String, dynamic>{'position': point.data, 'name': id});
  }
}
