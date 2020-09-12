import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../models/map_container_model.dart';
import '../../shared/buttons.dart';
import '../../shared/modals.dart';

class DetailsCard extends StatelessWidget {
  const DetailsCard(
      {Key key,
      @required this.container,
      @required this.onPressedNavigate,
      @required this.onPressedRelocate})
      : super(key: key);

  final MapContainer container;
  final VoidCallback onPressedNavigate;
  final VoidCallback onPressedRelocate;

  @override
  Widget build(BuildContext context) {
    return ModalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
                horizontal: 21.w as double, vertical: 15.h as double),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Container ${container.name}(${container.currentCollection??''})',
                  style: Theme.of(context).textTheme.headline6.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Next Collection(${container.nextCollection??''})',
                  style: Theme.of(context).textTheme.bodyText1.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  container.createdAt != null ? '${container.createdAt.day}.${container.createdAt.month}.${container.createdAt.year}(T1)' : '',
                  style: Theme.of(context).textTheme.bodyText1,
                ),
                Text(
                  'Fullness Rate',
                  style: Theme.of(context).textTheme.bodyText1.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${container.fullnessRate??'0'}%',
                  style: Theme.of(context).textTheme.bodyText1,
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              StyledButton(
                onPressed:
                    onPressedNavigate,
                text: 'NAVIGATE',
              ),
              StyledButton(
                onPressed: onPressedRelocate,
                text: 'RELOCATE',
              )
            ],
          )
        ],
      ),
    );
  }
}
