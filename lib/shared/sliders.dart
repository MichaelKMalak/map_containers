import 'package:flutter/material.dart';

class SliderWidget extends StatelessWidget {
  const SliderWidget({Key key, @required this.radius, @required this.onChanged}) : super(key: key );

  final double radius;
  final Function(double) onChanged;

  @override
  Widget build(BuildContext context) {
    return Slider(
      min: 100,
      max: 500,
      divisions: 4,
      value: radius,
      label: 'Radius ${radius}km',
      activeColor: Colors.green,
      inactiveColor: Colors.green.withOpacity(0.2),
      onChanged: onChanged,
    );
  }
}
