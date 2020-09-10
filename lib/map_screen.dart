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

  StreamSubscription subscription;

  Map<MarkerId, Marker> markers = <MarkerId, Marker>{};

  bool _isRelocatingContainer = false;
  bool _isModalVisible = false;
  String _selectedPoint = '';

  static double get initialLat => 39.897037;
  static double get initialLng => 32.775253;

  static final CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(initialLat, initialLng),
    zoom: 12.0,
  );

  @override
  build(context) {
    return Scaffold(
      body: Stack(children: [
        GoogleMap(
          initialCameraPosition: _initialCameraPosition,
          onMapCreated: _onMapCreated,
          myLocationEnabled: true,
          mapType: MapType.hybrid,
          markers: Set<Marker>.of(markers.values),
          onTap: _isRelocatingContainer ? _relocateContainerLocally : null,
        ),
        Positioned(
          bottom: 50,
          left: 10,
          child: _buildSlider(),
        ),
        _buildContainerDetailsCard(context),
        _buildRelocationCard(),
      ]),
    );
  }

  Widget _buildRelocationCard() {
    return containerCard(
      visibilityCondition: _isRelocatingContainer,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            '''Please select a location from the map for your pin to be relocated. You can select a location by tapping on the map.''',
            softWrap: true,
          ),
          FlatButton(
            child: Text('SAVE'),
            onPressed: () {
              _relocateContainerOnServer();
              setState(() {
                _isRelocatingContainer = false;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContainerDetailsCard(BuildContext context) {
    return containerCard(
      visibilityCondition: _isModalVisible && !_isRelocatingContainer,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            _selectedPoint,
            style: Theme.of(context).textTheme.headline6,
          ),
          Row(
            children: [
              FlatButton(
                child: Text('NAVIGATE'),
                onPressed: () {
                  setState(() {
                    _isRelocatingContainer = false;
                    _isModalVisible = false;
                  });
                },
              ),
              FlatButton(
                child: Text('RELOCATE'),
                onPressed: () => _toggleToRelocateContainerMode(_selectedPoint),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget containerCard(
      {@required Widget child, @required bool visibilityCondition}) {
    return Visibility(
      visible: visibilityCondition,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: FractionallySizedBox(
          heightFactor: 0.3,
          widthFactor: 0.9,
          child: Card(margin: EdgeInsets.only(bottom: 50), child: child),
        ),
      ),
    );
  }

  Widget _buildSlider() => Slider(
        min: 100.0,
        max: 500.0,
        divisions: 4,
        value: radius.value,
        label: 'Radius ${radius.value}km',
        activeColor: Colors.green,
        inactiveColor: Colors.green.withOpacity(0.2),
        onChanged: _updateZoom,
      );

  void _onMapCreated(GoogleMapController controller) {
    setState(() {
      _mapController = controller;
    });
    _startQuery();
  }

  _startQuery() async {
    final pos = await location.getLocation();
    final lat = pos.latitude ?? initialLat;
    final lng = pos.longitude ?? initialLng;
    final ref = firestore.collection('locations');
    final center = geo.point(latitude: lat, longitude: lng);

    _animateToUser(pos);
    _subscribeToMarkerUpdates(ref, center);
  }

  _animateToUser(LocationData pos) async {
    _mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(pos.latitude, pos.latitude),
          zoom: 17.0,
        ),
      ),
    );
  }

  void _subscribeToMarkerUpdates(CollectionReference ref, GeoFirePoint center) {
    subscription = radius.switchMap((rad) {
      return geo.collection(collectionRef: ref).within(
            center: center,
            radius: rad,
            field: 'position',
            //strictMode: true,
          );
    }).listen(_updateMarkers);
  }

  void _updateMarkers(List<DocumentSnapshot> documentList) {
    markers.clear();
    documentList.forEach((DocumentSnapshot document) {
      final data = document.data();
      final GeoPoint pos = data['position']['geopoint'];
      final String markerIdVal = data['name'];

      _addMarker(pos, markerIdVal);
    });
    setState(() {});
  }

  _addMarker(GeoPoint pos, String markerIdVal) {
    final MarkerId markerId = MarkerId(markerIdVal);
    final LatLng posLatLng = LatLng(pos.latitude, pos.longitude);
    final marker = newMarker(markerId, posLatLng, markerIdVal);

    markers[markerId] = marker;
  }

  Marker newMarker(MarkerId markerId, LatLng pos, String markerIdVal) {
    return Marker(
      markerId: markerId,
      position: pos,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      //infoWindow: InfoWindow(title: markerIdVal, snippet: '🍄🍄🍄'),
      onTap: () => _showModal(markerIdVal),
    );
  }

  _addGeoPoint(LatLng latLng) async {
    final id = firestore.app.options.hashCode.toString();
    GeoFirePoint point =
        geo.point(latitude: latLng.latitude, longitude: latLng.longitude);
    return firestore
        .collection('locations')
        .doc(id)
        .set({'position': point.data, 'name': id});
  }

  Future<void> _relocateGeoPoint(String id, LatLng newLatLng) async {
    GeoFirePoint point =
        geo.point(latitude: newLatLng.latitude, longitude: newLatLng.longitude);
    return firestore
        .collection('locations')
        .doc(id)
        .set({'position': point.data, 'name': id});
  }

  _updateZoom(value) {
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

  _showModal(String markerIdVal) {
    setState(() {
      _selectedPoint = markerIdVal;
      _isModalVisible = true;
    });
  }

  _relocateContainerLocally(LatLng newLatLng) async {
    final String markerIdVal = _selectedPoint;
    final GeoPoint pos = GeoPoint(newLatLng.latitude, newLatLng.longitude);
    _addMarker(pos, markerIdVal);
    setState(() {});
  }

  _relocateContainerOnServer() async {
    final String markerIdVal = _selectedPoint;
    final MarkerId markerId = MarkerId(markerIdVal);
    final newLatLng = markers[markerId].position;
    await _relocateGeoPoint(markerIdVal, newLatLng);
    setState(() {
      _isRelocatingContainer = false;
    });
  }

  _toggleToRelocateContainerMode(String selectedPoint) {
    final MarkerId markerId = MarkerId(selectedPoint);
    markers.removeWhere((key, value) => key != markerId);
    setState(() {
      _isRelocatingContainer = true;
    });
  }

  @override
  dispose() {
    subscription.cancel();
    super.dispose();
  }
}
