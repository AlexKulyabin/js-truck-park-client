import 'package:flutter/material.dart';

class ParkingSheetRouteController {
  bool _isDismissing = false;

  bool dismiss(BuildContext context) {
    if (_isDismissing) {
      return false;
    }

    final route = ModalRoute.of(context);
    if (route is! PopupRoute || !route.isCurrent) {
      return false;
    }

    _isDismissing = true;
    Navigator.of(context).pop();
    return true;
  }
}
