import '/backend/schema/structs/index.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/custom_code/actions/index.dart' as actions;
import '/flutter_flow/custom_functions.dart' as functions;
import '/flutter_flow/revenue_cat_util.dart' as revenue_cat;
import '/index.dart';
import 'pay_wall_widget.dart' show PayWallWidget;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class PayWallModel extends FlutterFlowModel<PayWallWidget> {
  ///  Local state fields for this page.

  String? temp;

  bool isPageload = false;

  ///  State fields for stateful widgets in this page.

  // Stores action output result for [Custom Action - getSmartSubscriptionPrices] action in PayWall widget.
  SubscriptionPricesStructStruct? smartPrices;
  // Stores action output result for [Custom Action - fetchPremiumExpirationDate] action in Button widget.
  DateTime? fetchPremiumExpirationDateOut2;
  // Stores action output result for [Custom Action - purchaseSmartPackage] action in Button widget.
  bool? purchaseSmartPackageOut;
  // Stores action output result for [Custom Action - fetchPremiumExpirationDate] action in Button widget.
  DateTime? fetchPremiumExpirationDateOut;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
