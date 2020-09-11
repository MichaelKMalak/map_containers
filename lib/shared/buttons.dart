import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

Widget buildRaisedButton(
    {@required String text, @required VoidCallback onPressed}) {
  return RaisedButton(
    onPressed: onPressed,
    child: Padding(
      padding: EdgeInsets.all(16.w as double),
      child: Text(text),
    ),
  );
}
