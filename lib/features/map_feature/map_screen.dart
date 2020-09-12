import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:rxdart/rxdart.dart';

import '../../constants/constants.dart';
import '../../models/map_container_model.dart';
import '../../services/connectivity_service.dart';
import '../../services/repository.dart';
import '../../shared/sliders.dart';
import '../../utils/svg_bitmap_descriptor.dart';
import 'details_card.dart';
import 'no_internet_card.dart';
import 'relocation_card.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key key, this.repository, this.connectionStatus})
      : super(key: key);

  final Repository repository;
  final ConnectivityService connectionStatus;

  @override
  State createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  Repository get repository => widget.repository;
  ConnectivityService get connectionStatus => widget.connectionStatus;
  MarkerId get selectedMarkerId => MarkerId(_selectedContainerName);

  StreamSubscription connectivitySubscription;
  StreamSubscription firestoreSubscription;

  GoogleMapController _mapController;
  Location currentUserLocation = Location();

  BehaviorSubject<double> radius =
      BehaviorSubject<double>.seeded(Constants.position.initialZoomKey);

  Map<MarkerId, Marker> markers = <MarkerId, Marker>{};
  Map<String, MapContainer> containerList = <String, MapContainer>{};

  bool _isConnectedToInternet = true;
  bool _isRelocatingContainer = false;
  bool _isModalVisible = false;
  String _selectedContainerName = '';

  BitmapDescriptor _greenMarkerIcon;
  BitmapDescriptor _yellowMarkerIcon;

  void _refreshUI() => setState(() {});

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
          child: SliderWidget(
            radius: radius.value,
            onChanged: _updateZoom,
          ),
        ),
        Visibility(
          visible: _isModalVisible &&
              !_isRelocatingContainer &&
              _isConnectedToInternet,
          child: DetailsCard(
            container: containerList[_selectedContainerName],
            onPressedNavigate: _onPressedNavigate,
            onPressedRelocate: _toggleToRelocateContainerMode,
          ),
        ),
        Visibility(
          visible: _isRelocatingContainer && _isConnectedToInternet,
          child: RelocationCard(onPressedSave: _relocateContainerOnServer),
        ),
        Visibility(
          visible: !_isConnectedToInternet,
          child: const NoInternetCard(),
        ),
      ]),
    );
  }

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _createMarkerImageFromAsset(context);
      _subscribeToConnectivityChanges(context);
    });
  }

  void _setInternetConnectionTo(bool state) {
    if (_isConnectedToInternet != state) {
      _isConnectedToInternet = state;
      _refreshUI();
    }
  }

  void _setRelocationModeTo(bool state) {
    if (_isRelocatingContainer != state) {
      _isRelocatingContainer = state;
      _refreshUI();
    }
  }

  void _setContainerDetailsVisibilityTo(bool state) {
    if (_isModalVisible != state) {
      _isModalVisible = state;
      _refreshUI();
    }
  }

  void _subscribeToConnectivityChanges(BuildContext context) {
    _checkCurrentInternetConnectivity(context);
    connectivitySubscription =
        connectionStatus.connectionChange.listen((dynamic hasConnection) {
      if (hasConnection != null && hasConnection is bool && !hasConnection) {
        _setInternetConnectionTo(false);
      } else {
        _setInternetConnectionTo(true);
      }
    });
  }

  void _checkCurrentInternetConnectivity(BuildContext context) {
    if (connectionStatus.hasConnection != null &&
        !connectionStatus.hasConnection) {
      _setInternetConnectionTo(false);
    } else {
      _setInternetConnectionTo(true);
    }
  }

  void _onPressedNavigate() {
    _setRelocationModeTo(false);
    _setContainerDetailsVisibilityTo(false);
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
          target: LatLng(pos.latitude, pos.longitude),
          zoom: Constants.position.initialZoomValue,
        ),
      ),
    );
  }

  void _subscribeToMarkerUpdates(LatLng center) {
    firestoreSubscription = radius
        .switchMap((rad) => repository.getContainers(center, rad))
        .listen(_updateMarkers);
  }

  void _updateMarkers(List<MapContainer> containerList) {
    markers.clear();
    this.containerList = {for (var e in containerList) e.name: e};
    for (final container in containerList) {
      _addMarkerToList(container.position, container.name);
    }
    _refreshUI();
  }

  void _addMarkerToList(LatLng pos, String markerIdVal,
      {bool isYellowMarker = false}) {
    final markerId = MarkerId(markerIdVal);
    final marker =
        _newMarker(markerId, pos, isYellowMarker: isYellowMarker);

    markers[markerId] = marker;
  }

  Marker _newMarker(MarkerId markerId, LatLng pos, {bool isYellowMarker = false}) {
    final markerIcon = isYellowMarker ? _yellowMarkerIcon : _greenMarkerIcon;
    return Marker(
      markerId: markerId,
      position: pos,
      icon: markerIcon ??
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      onTap: () => _showContainerDetailsModal(markerId.value),
    );
  }

  void _updateZoom(double value) {
    final zoom = Constants.position.zoomMap[value];
    _mapController.moveCamera(CameraUpdate.zoomTo(zoom));
    radius.add(value);
    _refreshUI();
  }

  void _showContainerDetailsModal(String markerIdVal) {
    _selectedContainerName = markerIdVal;
    _setContainerDetailsVisibilityTo(true);
  }

  void _relocateContainerLocally(LatLng newLatLng) {
    _addMarkerToList(newLatLng, _selectedContainerName, isYellowMarker: true);
    _refreshUI();
  }

  Future<void> _relocateContainerOnServer() async {
    final newLatLng = markers[selectedMarkerId].position;
    final updatedContainer =
        MapContainer(name: _selectedContainerName, position: newLatLng);
    await repository.updateContainersPosition(updatedContainer);
    _setRelocationModeTo(false);
  }

  void _toggleToRelocateContainerMode() {
    final targetMarker = markers[selectedMarkerId];
    final redrawnMarker = _newMarker(
        selectedMarkerId, targetMarker.position, isYellowMarker: true);

    markers.clear();
    markers[selectedMarkerId] = redrawnMarker;

    _setRelocationModeTo(true);
  }

  @override
  void dispose() {
    firestoreSubscription.cancel();
    connectivitySubscription.cancel();
    super.dispose();
  }
}
