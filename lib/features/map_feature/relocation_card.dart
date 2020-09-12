import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../shared/buttons.dart';
import '../../shared/modals.dart';

class RelocationCard extends StatelessWidget {
const RelocationCard(
{Key key,
@required this.onPressedSave})
: super(key: key);

final VoidCallback onPressedSave;

@override
  Widget build(BuildContext context) {
    return ModalCard(
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
                horizontal: 21.w as double, vertical: 19.02.w as double),
            child: const Text(
              '''Please select a location from the map for your pin to be relocated. You can select a location by tapping on the map.''',
              softWrap: true,
            ),
          ),
          StyledButton(
            onPressed: onPressedSave,
            text: 'SAVE',
          ),
        ],
      ),
    );
  }
}
