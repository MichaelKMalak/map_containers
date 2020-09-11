import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:map_containers/constants/constants.dart';

import 'pages/map_screen.dart';

FirebaseAnalytics analytics;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  analytics = FirebaseAnalytics();

  Crashlytics.instance.enableInDevMode = true;
  FlutterError.onError = Crashlytics.instance.recordFlutterError;

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
          primaryColor: Constants.color.darkGrey,
          accentColor: Constants.color.green,
          textTheme: Theme.of(context).textTheme.apply(
              fontFamily: 'Open Sans',
              bodyColor: Constants.color.darkGrey,
              displayColor: Colors.white),
          buttonTheme: ButtonThemeData(
            buttonColor: Constants.color.green,
            textTheme: ButtonTextTheme.primary
          )
      ),
      home: const MapScreen(),
    );
  }
}
