import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ModalCard extends StatelessWidget {
  const ModalCard({Key key, @required this.child}) : super(key: key );
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: SizedBox(
        height: 219.h as double,
        width: 336.w as double,
        child: Card(margin: EdgeInsets.all(3.w as double), child: child),
      ),
    );
  }
}
