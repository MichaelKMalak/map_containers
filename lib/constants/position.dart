import 'package:google_maps_flutter/google_maps_flutter.dart';

class ConstantPositions {
  const ConstantPositions();

  double get initialLat => 39.897037;
  double get initialLng => 32.775253;

  CameraPosition get initialCameraPosition => CameraPosition(
    target: LatLng(initialLat, initialLng),
    zoom: 17,
  );
}
