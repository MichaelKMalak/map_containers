import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geoflutterfire/geoflutterfire.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:rxdart/rxdart.dart';

import '../constants/constants.dart';
import '../services/connectivity/connectivity_service.dart';
import '../shared/buttons.dart';
import '../shared/modals.dart';
import '../shared/snackbars.dart';
import '../utils/svg_bitmap_descriptor.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key key}) : super(key: key);

  @override
  State createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  GoogleMapController _mapController;
  Location location = Location();

  FirebaseFirestore firestore = FirebaseFirestore.instance;
  Geoflutterfire geo = Geoflutterfire();

  BehaviorSubject<double> radius = BehaviorSubject<double>.seeded(100);

  StreamSubscription subscription;

  Map<MarkerId, Marker> markers = <MarkerId, Marker>{};

  bool _isRelocatingContainer = false;
  bool _isModalVisible = false;
  String _selectedPoint = '';

  BitmapDescriptor _greenMarkerIcon;
  BitmapDescriptor _yellowMarkerIcon;

  final connectionStatus = ConnectivityService.getInstance();
  StreamSubscription connectivitySubscription;

  @override
  Scaffold build(BuildContext context) {
    ScreenUtil.init(context, width: 360, height: 740, allowFontScaling: true);
    _createMarkerImageFromAsset(context);

    return Scaffold(
      body: Stack(children: [
        GoogleMap(
          initialCameraPosition: Constants.position.initialCameraPosition,
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
        Visibility(
          visible: _isModalVisible && !_isRelocatingContainer,
          child: _buildContainerDetailsCard(context),
        ),
        Visibility(
          visible: _isRelocatingContainer,
          child: _buildRelocationCard(),
        ),
      ]),
    );
  }

  void _refreshUI() => setState(() {});

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (connectionStatus.hasConnection != null &&
          !connectionStatus.hasConnection) {
        showSnackBar(context,
            text: 'Please Connect to the internet', onPressed: null);
      }

      connectivitySubscription =
          connectionStatus.connectionChange.listen((dynamic hasConnection) {
            if (hasConnection != null && hasConnection is bool && !hasConnection) {
              showSnackBar(context,
                  text: 'No internet connection', onPressed: null);
              _refreshUI();
            }
          });
    });
  }

  Widget _buildSlider() => Slider(
        min: 100,
        max: 500,
        divisions: 4,
        value: radius.value,
        label: 'Radius ${radius.value}km',
        activeColor: Colors.green,
        inactiveColor: Colors.green.withOpacity(0.2),
        onChanged: _updateZoom,
      );

  Widget _buildRelocationCard() {
    return ModalCard(
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
                horizontal: 21.w as double, vertical: 19.02.w as double),
            child: const Text(
              '''Please select a location from the map for your pin to be relocated. You can select a location by tapping on the map.''',
              softWrap: true,
            ),
          ),
          buildRaisedButton(
            onPressed: () {
              _relocateContainerOnServer();
              _isRelocatingContainer = false;
              _refreshUI();
            },
            text: 'SAVE',
          ),
        ],
      ),
    );
  }

  Widget _buildContainerDetailsCard(BuildContext context) {
    return ModalCard(
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
                horizontal: 21.w as double, vertical: 19.02.w as double),
            child: Text(
              _selectedPoint,
              style: Theme.of(context).textTheme.headline6,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              buildRaisedButton(
                onPressed: () {
                  _isRelocatingContainer = false;
                  _isModalVisible = false;
                  _refreshUI();
                },
                text: 'NAVIGATE',
              ),
              buildRaisedButton(
                onPressed: () => _toggleToRelocateContainerMode(_selectedPoint),
                text: 'RELOCATE',
              )
            ],
          )
        ],
      ),
    );
  }

  Future<void> _createMarkerImageFromAsset(BuildContext context) async {
    if (_greenMarkerIcon == null) {
      await SvgBitmapDescriptor.fromSvgAsset(
              context, Constants.imagePath.greenBin)
          .then(_updateGreenMarkerBitmap);
    }

    if (_yellowMarkerIcon == null) {
      await SvgBitmapDescriptor.fromSvgAsset(
              context, Constants.imagePath.yellowBin)
          .then(_updateYellowMarkerBitmap);
    }
  }

  void _updateGreenMarkerBitmap(BitmapDescriptor bitmap) {
    _greenMarkerIcon = bitmap;
    _refreshUI();
  }

  void _updateYellowMarkerBitmap(BitmapDescriptor bitmap) {
    _yellowMarkerIcon = bitmap;
    _refreshUI();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _refreshUI();
    _startQuery();
  }

  Future<void> _startQuery() async {
    final pos = await location.getLocation();
    final lat = pos.latitude ?? Constants.position.initialLat;
    final lng = pos.longitude ?? Constants.position.initialLng;
    final ref = firestore.collection('locations');
    final center = geo.point(latitude: lat, longitude: lng);

    _animateToUser(pos);
    _subscribeToMarkerUpdates(ref, center);
  }

  void _animateToUser(LocationData pos) {
    _mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(pos.latitude, pos.latitude),
          zoom: 17,
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
    for (final document in documentList) {
      final data = document.data();
      final pos = data['position']['geopoint'] as GeoPoint;
      final markerIdVal = data['name'] as String;

      _addMarkerToList(pos, markerIdVal);
    }
    _refreshUI();
  }

  void _addMarkerToList(GeoPoint pos, String markerIdVal,
      {bool isYellowMarker = false}) {
    final markerId = MarkerId(markerIdVal);
    final posLatLng = LatLng(pos.latitude, pos.longitude);
    final marker = newMarker(markerId, posLatLng, markerIdVal,
        isYellowMarker: isYellowMarker);

    markers[markerId] = marker;
  }

  Marker newMarker(MarkerId markerId, LatLng pos, String markerIdVal,
      {bool isYellowMarker = false}) {
    final markerIcon = isYellowMarker ? _yellowMarkerIcon : _greenMarkerIcon;
    return Marker(
      markerId: markerId,
      position: pos,
      icon: markerIcon ??
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      onTap: () => _showModal(markerIdVal),
    );
  }



  Future<void> _relocateGeoPoint(String id, LatLng newLatLng) async {
    final point =
        geo.point(latitude: newLatLng.latitude, longitude: newLatLng.longitude);
    return firestore
        .collection('locations')
        .doc(id)
        .set(<String, dynamic>{'position': point.data, 'name': id});
  }

  void _updateZoom(double value) {
    final zoomMap = {
      100.0: 17.0,
      200.0: 14.0,
      300.0: 10.0,
      400.0: 7.0,
      500.0: 5.0
    };
    final zoom = zoomMap[value];
    _mapController.moveCamera(CameraUpdate.zoomTo(zoom));
    radius.add(value);
    _refreshUI();
  }

  void _showModal(String markerIdVal) {
    _selectedPoint = markerIdVal;
    _isModalVisible = true;
    _refreshUI();
  }

  void _relocateContainerLocally(LatLng newLatLng) {
    final markerIdVal = _selectedPoint;
    final pos = GeoPoint(newLatLng.latitude, newLatLng.longitude);
    _addMarkerToList(pos, markerIdVal, isYellowMarker: true);
    _refreshUI();
  }

  Future<void> _relocateContainerOnServer() async {
    final markerIdVal = _selectedPoint;
    final markerId = MarkerId(markerIdVal);
    final newLatLng = markers[markerId].position;
    await _relocateGeoPoint(markerIdVal, newLatLng);
    _isRelocatingContainer = false;
    _refreshUI();
  }

  void _toggleToRelocateContainerMode(String markerIdVal) {
    final markerId = MarkerId(markerIdVal);
    final targetMarker = markers[markerId];
    final redrawnMarker = newMarker(
        markerId, targetMarker.position, markerIdVal,
        isYellowMarker: true);

    markers.clear();
    markers[markerId] = redrawnMarker;

    _isRelocatingContainer = true;
    _refreshUI();
  }

  @override
  void dispose() {
    subscription.cancel();
    connectivitySubscription.cancel();
    super.dispose();
  }
}
