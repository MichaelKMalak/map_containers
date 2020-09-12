import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geoflutterfire/geoflutterfire.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:map_containers/models/container.dart';
import 'package:rxdart/rxdart.dart';

import '../constants/constants.dart';
import '../services/connectivity/connectivity_service.dart';
import '../services/repository/repository.dart';
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
  Location currentUserLocation = Location();

  Repository repository =
      Repository(FirebaseFirestore.instance, Geoflutterfire());

  BehaviorSubject<double> radius = BehaviorSubject<double>.seeded(100);

  StreamSubscription subscription;

  Map<MarkerId, Marker> markers = <MarkerId, Marker>{};

  bool _isRelocatingContainer = false;
  bool _isModalVisible = false;
  String _selectedContainerName = '';

  BitmapDescriptor _greenMarkerIcon;
  BitmapDescriptor _yellowMarkerIcon;

  final connectionStatus = ConnectivityService.getInstance();
  StreamSubscription connectivitySubscription;

  @override
  Scaffold build(BuildContext context) {
    ScreenUtil.init(context, width: 360, height: 740, allowFontScaling: true);
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
      _createMarkerImageFromAsset(context);
      checkInternetConnectivity(context);
      subscribeToConnectivityChanges(context);
    });
  }

  void subscribeToConnectivityChanges(BuildContext context) {
    connectivitySubscription =
        connectionStatus.connectionChange.listen((dynamic hasConnection) {
          if (hasConnection != null && hasConnection is bool && !hasConnection) {
            showSnackBar(context,
                text: 'No internet connection', onPressed: null);
            _refreshUI();
          }
        });
  }

  void checkInternetConnectivity(BuildContext context) {
    if (connectionStatus.hasConnection != null &&
        !connectionStatus.hasConnection) {
      showSnackBar(context,
          text: 'Please Connect to the internet', onPressed: null);
    }
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
              _selectedContainerName,
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
                onPressed: () => _toggleToRelocateContainerMode(_selectedContainerName),
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
    final pos = await currentUserLocation.getLocation();
    final lat = pos.latitude ?? Constants.position.initialLat;
    final lng = pos.longitude ?? Constants.position.initialLng;
    final center = LatLng(lat, lng);

    _animateToUser(pos);
    _subscribeToMarkerUpdates(center);
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

  void _subscribeToMarkerUpdates(LatLng center) {
    subscription = radius
        .switchMap((rad) => repository.getContainers(center, rad))
        .listen(_updateMarkers);
  }

  void _updateMarkers(List<MapContainer> containerList) {
    markers.clear();
    for (final container in containerList) {
      _addMarkerToList(container.position, container.name);
    }
    _refreshUI();
  }

  void _addMarkerToList(LatLng pos, String markerIdVal,
      {bool isYellowMarker = false}) {
    final markerId = MarkerId(markerIdVal);
    final marker = newMarker(markerId, pos, markerIdVal,
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
    _selectedContainerName = markerIdVal;
    _isModalVisible = true;
    _refreshUI();
  }

  void _relocateContainerLocally(LatLng newLatLng) {
    final markerIdVal = _selectedContainerName;
    _addMarkerToList(newLatLng, markerIdVal, isYellowMarker: true);
    _refreshUI();
  }

  Future<void> _relocateContainerOnServer() async {
    final markerIdVal = _selectedContainerName;
    final markerId = MarkerId(markerIdVal);
    final newLatLng = markers[markerId].position;
    final updatedContainer = MapContainer(name: markerIdVal, position: newLatLng);
    await repository.updateContainersPosition(updatedContainer);
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
