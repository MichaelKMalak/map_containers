import 'package:google_maps_flutter/google_maps_flutter.dart';

class ConstantPositions {
  const ConstantPositions();

  double get initialLat => 39.897037;
  double get initialLng => 32.775253;

  LatLng get initialLatLng => LatLng(initialLat, initialLng);

  CameraPosition get initialCameraPosition => CameraPosition(
    target: initialLatLng,
    zoom: 17,
  );
}
