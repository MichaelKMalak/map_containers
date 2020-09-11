import 'package:flutter/material.dart';

 ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showSnackBar(
    BuildContext context, {@required String text, @required VoidCallback onPressed}) {
  final snackBar = SnackBar(content: Text(text));
  return Scaffold.of(context).showSnackBar(snackBar);
}
