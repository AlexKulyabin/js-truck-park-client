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

import 'package:google_maps_flutter/google_maps_flutter.dart' as google_maps;
import '/flutter_flow/lat_lng.dart' as ff_lat_lng;
import '/features/map/presentation/map_marker_item.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'dart:ui' as ui;
import 'dart:async';

class CustomGoogleMap extends StatefulWidget {
  const CustomGoogleMap({
    super.key,
    this.width,
    this.height,
    required this.initialLat,
    required this.initialLng,
    required this.initialZoom,
    required this.markers,
    this.onMarkerTap,
    this.onClusterTap,
    this.allowGestures,
    this.onCameraIdle,
    this.onLongPress,
    this.markerIconPath,
    this.markerSize,
    this.clusterSize, // Новый параметр
    this.centerToMoveTo,
    this.isDarkMode,
  });

  final double? width;
  final double? height;
  final double initialLat;
  final double initialLng;
  final double initialZoom;
  final List<MapMarkerItem> markers;
  final Future Function(String markerId)? onMarkerTap;
  final Future Function(double lat, double lng)? onClusterTap;
  final bool? allowGestures;
  final Future Function(double minLat, double minLng, double maxLat,
      double maxLng, double zoom)? onCameraIdle;
  final Future Function(ff_lat_lng.LatLng longPressedPoint)? onLongPress;
  final String? markerIconPath;
  final int? markerSize;
  final int? clusterSize; // Новый параметр
  final ff_lat_lng.LatLng? centerToMoveTo;
  final bool? isDarkMode;

  @override
  State<CustomGoogleMap> createState() => _CustomGoogleMapState();
}

class _CustomGoogleMapState extends State<CustomGoogleMap> {
  google_maps.GoogleMapController? _controller;
  Set<google_maps.Marker> _markers = {};
  bool _isMapReady = false;
  google_maps.BitmapDescriptor? _customMarkerIcon;
  double _currentZoom = 10.0;

  final String _darkStyle = '''[
  {"elementType": "geometry", "stylers": [{"color": "#242f3e"}]},
  {"elementType": "labels.text.stroke", "stylers": [{"color": "#242f3e"}]},
  {"elementType": "labels.text.fill", "stylers": [{"color": "#746855"}]},
  {"featureType": "road", "elementType": "geometry", "stylers": [{"color": "#38414e"}]},
  {"featureType": "water", "elementType": "geometry", "stylers": [{"color": "#17263c"}]}
]''';

  @override
  void initState() {
    super.initState();
    _currentZoom = widget.initialZoom;
    _prepareIcons();
  }

  Future<void> _prepareIcons() async {
    if (widget.markerIconPath != null && widget.markerIconPath!.isNotEmpty) {
      try {
        _customMarkerIcon = await _getBitmapDescriptorFromUrl(
          widget.markerIconPath!,
          widget.markerSize ?? 100,
        );
      } catch (e) {
        debugPrint("Icon load error: $e");
      }
    }
    _updateMarkers();
  }

  @override
  void didUpdateWidget(CustomGoogleMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.markers != widget.markers ||
        oldWidget.clusterSize != widget.clusterSize) {
      _updateMarkers();
    }
    if (oldWidget.isDarkMode != widget.isDarkMode && _controller != null) {
      _setMapStyle();
    }
    if (widget.centerToMoveTo != oldWidget.centerToMoveTo &&
        widget.centerToMoveTo != null) {
      _moveToLatLng(widget.centerToMoveTo!, targetZoom: 14.0);
    }
  }

  void _setMapStyle() {
    if (widget.isDarkMode == true) {
      _controller?.setMapStyle(_darkStyle);
    } else {
      _controller?.setMapStyle(null);
    }
  }

  void _moveToLatLng(ff_lat_lng.LatLng position, {double? targetZoom}) {
    _controller?.animateCamera(
      google_maps.CameraUpdate.newLatLngZoom(
        google_maps.LatLng(position.latitude, position.longitude),
        targetZoom ?? _currentZoom,
      ),
    );
  }

  Future<void> _updateMarkers() async {
    if (!_isMapReady || !mounted) return;
    final List<google_maps.Marker> newMarkers = [];
    final iconToUse =
        _customMarkerIcon ?? google_maps.BitmapDescriptor.defaultMarker;

    for (final item in widget.markers) {
      if (item.isCluster) {
        final clusterIcon = await _getClusterIcon(item.count);
        newMarkers.add(google_maps.Marker(
          markerId: google_maps.MarkerId(item.id),
          position: google_maps.LatLng(item.latitude, item.longitude),
          icon: clusterIcon,
          onTap: () => _moveToLatLng(
            ff_lat_lng.LatLng(item.latitude, item.longitude),
            targetZoom: _currentZoom + 2.0,
          ),
        ));
      } else {
        newMarkers.add(google_maps.Marker(
          markerId: google_maps.MarkerId(item.id),
          position: google_maps.LatLng(item.latitude, item.longitude),
          icon: iconToUse,
          onTap: () {
            if (widget.onMarkerTap != null) {
              widget.onMarkerTap!(item.id);
            }
          },
        ));
      }
    }
    if (mounted) setState(() => _markers = newMarkers.toSet());
  }

  @override
  Widget build(BuildContext context) {
    final bool gesturesEnabled = widget.allowGestures ?? true;

    return google_maps.GoogleMap(
      initialCameraPosition: google_maps.CameraPosition(
          target: google_maps.LatLng(widget.initialLat, widget.initialLng),
          zoom: widget.initialZoom),
      markers: _markers,
      onTap: (latLng) {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      onMapCreated: (controller) async {
        _controller = controller;
        _isMapReady = true;
        _setMapStyle();
        _updateMarkers();
        await Future.delayed(const Duration(milliseconds: 700));
        _triggerCameraIdle();
      },
      scrollGesturesEnabled: gesturesEnabled,
      zoomGesturesEnabled: gesturesEnabled,
      tiltGesturesEnabled: gesturesEnabled,
      rotateGesturesEnabled: gesturesEnabled,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      onCameraMove: (position) => _currentZoom = position.zoom,
      onCameraIdle: () => _triggerCameraIdle(),
      onLongPress: (latLng) {
        if (gesturesEnabled && widget.onLongPress != null) {
          widget.onLongPress!(
              ff_lat_lng.LatLng(latLng.latitude, latLng.longitude));
        }
      },
    );
  }

  Future<void> _triggerCameraIdle() async {
    if (_controller == null || !_isMapReady || widget.onCameraIdle == null)
      return;
    final bounds = await _controller!.getVisibleRegion();
    final zoom = await _controller!.getZoomLevel();
    widget.onCameraIdle!(bounds.southwest.latitude, bounds.southwest.longitude,
        bounds.northeast.latitude, bounds.northeast.longitude, zoom);
  }

  // ОБНОВЛЕННЫЙ МЕТОД: Использует параметр clusterSize из FlutterFlow
  Future<google_maps.BitmapDescriptor> _getClusterIcon(int clusterSize) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint = Paint()..color = const Color(0xFF1E88E5);

    // Берем размер из настроек FF (по умолчанию 100, если забыли указать)
    final double size = (widget.clusterSize?.toDouble() ?? 100.0);
    final double radius = size / 2;

    // 1. Синий круг
    canvas.drawCircle(Offset(radius, radius), radius * 0.85, paint);

    // 2. Белая обводка
    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = size * 0.05;
    canvas.drawCircle(Offset(radius, radius), radius * 0.85, borderPaint);

    // 3. Текст
    final textPainter = TextPainter(textDirection: ui.TextDirection.ltr)
      ..text = TextSpan(
          text: clusterSize.toString(),
          style: TextStyle(
              fontSize: size * 0.35,
              fontWeight: FontWeight.bold,
              color: Colors.white))
      ..layout();

    textPainter.paint(
        canvas,
        Offset(
            radius - textPainter.width / 2, radius - textPainter.height / 2));

    final img = await pictureRecorder
        .endRecording()
        .toImage(size.toInt(), size.toInt());
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    return google_maps.BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  }

  Future<google_maps.BitmapDescriptor> _getBitmapDescriptorFromUrl(
      String url, int size) async {
    final Completer<ui.Image> completer = Completer();
    final ImageStream stream =
        NetworkImage(url).resolve(ImageConfiguration.empty);
    stream.addListener(
        ImageStreamListener((info, _) => completer.complete(info.image)));
    final ui.Image image = await completer.future;
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final double dpr =
        ui.PlatformDispatcher.instance.views.first.devicePixelRatio;
    final double dstWidth = size.toDouble() * dpr;
    final double dstHeight = (image.height * dstWidth / image.width);

    canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        Rect.fromLTWH(0, 0, dstWidth, dstHeight),
        Paint()..filterQuality = ui.FilterQuality.high);

    final img = await pictureRecorder
        .endRecording()
        .toImage(dstWidth.toInt(), dstHeight.toInt());
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    return google_maps.BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  }
}
// Set your widget name, define your parameter, and then add the
// boilerplate code using the green button on the right!
