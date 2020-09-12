import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../shared/modals.dart';

class NoInternetCard extends StatelessWidget {
  const NoInternetCard({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ModalCard(
      isSmall: true,
      child: Column(children: [
        Padding(
          padding: EdgeInsets.symmetric(
              horizontal: 21.w as double, vertical: 19.02.w as double),
          child: const Text(
            '''Please make sure you are connected to the internet''',
            softWrap: true,
          ),
        ),
      ]),
    );
  }
}
