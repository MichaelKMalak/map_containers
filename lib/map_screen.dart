import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geoflutterfire/geoflutterfire.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:rxdart/rxdart.dart';

class MapScreen extends StatefulWidget {
  @override
  State createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  GoogleMapController _mapController;
  Location location = Location();

  FirebaseFirestore firestore = FirebaseFirestore.instance;
  Geoflutterfire geo = Geoflutterfire();

  BehaviorSubject<double> radius = BehaviorSubject<double>.seeded(100.0);
  Stream<dynamic> query;

  StreamSubscription subscription;

  Map<MarkerId, Marker> markers = <MarkerId, Marker>{};

  static final CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  @override
  build(context) {
    return Scaffold(
      body: Stack(children: [
        GoogleMap(
          initialCameraPosition: _kGooglePlex,
          onMapCreated: _onMapCreated,
          myLocationEnabled: true,
          mapType: MapType.hybrid,
          markers: Set<Marker>.of(markers.values),
          onTap: _addMarker,
          //trackCameraPosition: true
        ),

        Positioned(
            bottom: 50,
            left: 10,
            child: Slider(
              min: 100.0,
              max: 500.0,
              divisions: 4,
              value: radius.value,
              label: 'Radius ${radius.value}km',
              activeColor: Colors.green,
              inactiveColor: Colors.green.withOpacity(0.2),
              onChanged: _updateQuery,
            )
        )
      ]),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    _startQuery();
    setState(() {
      _mapController = controller;
    });
    _animateToUser();
  }

  _addMarker(LatLng latLng) async {
    var markerIdVal = 'Magic Marker';
    final MarkerId markerId = MarkerId(markerIdVal);

    var marker = Marker(
      markerId: markerId,
      position: latLng,
      icon: BitmapDescriptor.defaultMarker,
      infoWindow: InfoWindow(title: markerIdVal, snippet: '🍄🍄🍄'),
    );

    _addGeoPoint(latLng);

    setState(() {
      markers[markerId] = marker;
    });
  }

  _animateToUser() async {
    var pos = await location.getLocation();
    _mapController.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
      target: LatLng(pos.latitude, pos.latitude),
      zoom: 17.0,
    )));
  }

  Future<DocumentReference> _addGeoPoint(LatLng latLng) async {
    GeoFirePoint point =
        geo.point(latitude: latLng.latitude, longitude: latLng.longitude);
    return firestore
        .collection('locations')
        .add({'position': point.data, 'name': 'Magic Marker'});
  }

  _startQuery() async {
    var pos = await location.getLocation();
    double lat = pos.latitude;
    double lng = pos.longitude;

    var ref = firestore.collection('locations');
    GeoFirePoint center = geo.point(latitude: lat, longitude: lng);

    subscription = radius.switchMap((rad) {
      return geo.collection(collectionRef: ref).within(
          center: center, radius: rad, field: 'position', strictMode: true);
    }).listen(_updateMarkers);
  }

  void _updateMarkers(List<DocumentSnapshot> documentList) {
    print('==========================================');
    print(documentList);

    markers.clear();

    var updatedMarkers = <MarkerId, Marker>{};

    documentList.forEach((DocumentSnapshot document) {
      var data = document.data();
      print(data);
      GeoPoint pos = data['position']['geopoint'];
      var markerIdVal = data['name'];

      final MarkerId markerId = MarkerId(markerIdVal);

      var marker = Marker(
        markerId: markerId,
        position: LatLng(pos.latitude, pos.longitude),
        icon: BitmapDescriptor.defaultMarker,
        infoWindow: InfoWindow(title: markerIdVal, snippet: '🍄🍄🍄'),
      );

      updatedMarkers[markerId] = marker;
    });

    setState(() {
      markers.addAll(updatedMarkers);
    });
  }

  _updateQuery(value) {
    final zoomMap = {
      100.0: 12.0,
      200.0: 10.0,
      300.0: 7.0,
      400.0: 6.0,
      500.0: 5.0
    };
    final zoom = zoomMap[value];
    _mapController.moveCamera(CameraUpdate.zoomTo(zoom));

    setState(() {
      radius.add(value);
    });
  }

  @override
  dispose() {
    subscription.cancel();
    super.dispose();
  }
}
