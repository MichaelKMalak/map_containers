import 'dart:math';

import 'package:google_maps_flutter/google_maps_flutter.dart';

class RandomizeLatLng {
  static LatLng withCenter(LatLng center) {
    final randomNumber_1 = (Random().nextDouble() * 0.1) - 0.05; // [-0.05, 0.05]
    final randomNumber_2 = (Random().nextDouble() * 0.1) - 0.05; // [-0.05, 0.05]
    final randomLatLng = LatLng(center.latitude + randomNumber_1, center.longitude + randomNumber_2);
    return randomLatLng;
  }
}