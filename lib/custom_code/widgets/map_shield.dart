// Automatic FlutterFlow imports
import '/backend/schema/structs/index.dart';
import '/backend/schema/enums/enums.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import '/custom_code/actions/index.dart'; // Imports custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'package:pointer_interceptor/pointer_interceptor.dart';

class MapShield extends StatefulWidget {
  const MapShield({
    super.key,
    this.width,
    this.height,
  });

  final double? width;
  final double? height;

  @override
  State<MapShield> createState() => _MapShieldState();
}

class _MapShieldState extends State<MapShield> {
  @override
  Widget build(BuildContext context) {
    return PointerInterceptor(
      child: Container(
        // Если ширина не задана, берем бесконечность (заполнит родителя)
        width: widget.width ?? double.infinity,
        height: widget.height ?? double.infinity,
        color: Colors.transparent,
      ),
    );
  }
}
// Set your widget name, define your parameter, and then add the
// boilerplate code using the green button on the right!
