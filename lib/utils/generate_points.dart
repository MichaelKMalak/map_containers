//todo

// Future<void> _addGeoPoint(LatLng latLng) async {
//   final id = firestore.app.options.hashCode.toString();
//   final point =
//       geo.point(latitude: latLng.latitude, longitude: latLng.longitude);
//   return firestore
//       .collection('locations')
//       .doc(id)
//       .set(<String, dynamic> {'position': point.data, 'name': id});
// }