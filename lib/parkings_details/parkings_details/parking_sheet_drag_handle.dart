import 'package:flutter/material.dart';

import 'parking_sheet_dismiss_tracker.dart';

const parkingSheetDragHandleKey =
    ValueKey<String>('parking-details-drag-handle');
const parkingSheetCloseButtonKey =
    ValueKey<String>('parking-details-close-button');

class ParkingSheetDragHandle extends StatefulWidget {
  const ParkingSheetDragHandle({
    super.key,
    required this.backgroundColor,
    required this.handleColor,
    required this.iconColor,
    required this.onDismiss,
  });

  final Color backgroundColor;
  final Color handleColor;
  final Color iconColor;
  final VoidCallback onDismiss;

  @override
  State<ParkingSheetDragHandle> createState() => _ParkingSheetDragHandleState();
}

class _ParkingSheetDragHandleState extends State<ParkingSheetDragHandle> {
  final _dismissTracker = ParkingSheetDismissTracker();
  bool _didRequestDismiss = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      key: parkingSheetDragHandleKey,
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) {
        _didRequestDismiss = false;
        _dismissTracker.reset();
      },
      onPointerMove: (event) {
        if (_didRequestDismiss ||
            !_dismissTracker.registerDragDelta(event.delta.dy)) {
          return;
        }
        _didRequestDismiss = true;
        widget.onDismiss();
      },
      onPointerUp: (_) => _dismissTracker.reset(),
      onPointerCancel: (_) => _dismissTracker.reset(),
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            color: widget.backgroundColor,
            child: Align(
              alignment: AlignmentDirectional.center,
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(vertical: 16.0),
                child: Container(
                  width: 32.0,
                  height: 4.0,
                  decoration: BoxDecoration(
                    color: widget.handleColor,
                    borderRadius: BorderRadius.circular(24.0),
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(top: 6.0),
              child: InkWell(
                key: parkingSheetCloseButtonKey,
                splashColor: Colors.transparent,
                focusColor: Colors.transparent,
                hoverColor: Colors.transparent,
                highlightColor: Colors.transparent,
                onTap: widget.onDismiss,
                child: Icon(
                  Icons.close_rounded,
                  color: widget.iconColor,
                  size: 24.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
