import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ModalCard extends StatelessWidget {
  const ModalCard({Key key, @required this.child, this.isSmall = false}) : super(key: key );
  final Widget child;
  final bool isSmall;
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: SizedBox(
        height: isSmall ? 100.h as double : 219.h as double,
        width: 336.w as double,
        child: Card(margin: EdgeInsets.all(3.w as double), child: child),
      ),
    );
  }
}
