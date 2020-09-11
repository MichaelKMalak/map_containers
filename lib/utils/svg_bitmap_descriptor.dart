import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class SvgBitmapDescriptor {
  static Future<BitmapDescriptor> fromSvgAsset(
      BuildContext context, String assetName) async {
    final svgString =
    await DefaultAssetBundle.of(context).loadString(assetName);
    final svgDrawableRoot = await svg.fromSvgString(svgString, null);

    // toPicture() and toImage() don't seem to be pixel ratio aware, so we calculate the actual sizes here
    final queryData = MediaQuery.of(context);
    final devicePixelRatio = queryData.devicePixelRatio;
    final width = 49 * devicePixelRatio;
    final height = 58 * devicePixelRatio;

    // Convert to ui.Picture
    final picture = svgDrawableRoot.toPicture(size: Size(width, height));

    // Convert to ui.Image. toImage() takes width and height as parameters
    // you need to find the best size to suit your needs and take into account the
    // screen DPI
    final image = await picture.toImage(width.round(), height.round());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(bytes.buffer.asUint8List());
  }
}
