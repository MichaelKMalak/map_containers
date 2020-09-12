import 'package:google_maps_flutter/google_maps_flutter.dart';

class ConstantMapParameters {
  const ConstantMapParameters();

  double get initialZoomKey => 100;
  double get initialZoomValue => 17;

  Map<double, double> get zoomMap => {
        initialZoomKey: initialZoomValue,
        200.0: 14.0,
        300.0: 10.0,
        400.0: 7.0,
        500.0: 5.0
      };

  double get initialLat => 39.897037;
  double get initialLng => 32.775253;

  LatLng get initialLatLng => LatLng(initialLat, initialLng);

  CameraPosition get initialCameraPosition => CameraPosition(
        target: initialLatLng,
        zoom: initialZoomValue,
      );
}
