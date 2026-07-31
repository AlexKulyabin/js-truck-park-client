import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart'
    as smooth_page_indicator;

import '../../../flutter_flow/flutter_flow_theme.dart';
import '../../../flutter_flow/flutter_flow_util.dart';
import '../application/parking_request_details_controller.dart';
import '../application/parking_requests_controller.dart';
import '../domain/parking_request_details_repository.dart';
import '../domain/parking_request_summary.dart';

class ParkingRequestDetailsView extends StatefulWidget {
  const ParkingRequestDetailsView({
    super.key,
    required this.request,
    required this.repository,
  });

  static const statusBannerKey = Key('parking-request-details-status');
  static const photosLoadingKey = Key('parking-request-photos-loading');
  static const photosFailureKey = Key('parking-request-photos-failure');
  static const photosEmptyKey = Key('parking-request-photos-empty');
  static const photosPageKey = Key('parking-request-photos-page');
  static const reviewLoadingKey = Key('parking-request-review-loading');
  static const reviewFailureKey = Key('parking-request-review-failure');
  static const addressKey = Key('parking-request-details-address');
  static const capacityKey = Key('parking-request-details-capacity');

  final ParkingRequestSummary request;
  final ParkingRequestDetailsRepository repository;

  @override
  State<ParkingRequestDetailsView> createState() =>
      _ParkingRequestDetailsViewState();
}

class _ParkingRequestDetailsViewState extends State<ParkingRequestDetailsView> {
  late final ParkingRequestDetailsController _controller;
  final _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _controller = ParkingRequestDetailsController(
      repository: widget.repository,
      parkingId: widget.request.id,
    )..addListener(_onStateChanged);
    unawaited(_controller.load());
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onStateChanged)
      ..dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      if (widget.request.status != ParkingRequestStatus.approved)
        _statusBanner(context),
      Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 16.0),
        child: _photos(context),
      ),
      _address(context),
      _reviews(context),
      _capacity(context),
      _services(context),
    ];

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        body: SafeArea(
          top: true,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(
                    0.0,
                    0.0,
                    0.0,
                    16.0,
                  ),
                  child: Stack(
                    alignment: const AlignmentDirectional(-1.0, 0.0),
                    children: [
                      const SizedBox(height: 46.0, width: double.infinity),
                      Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                          8.0,
                          11.0,
                          0.0,
                          11.0,
                        ),
                        child: InkWell(
                          splashColor: Colors.transparent,
                          focusColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          onTap: context.safePop,
                          child: Icon(
                            Icons.arrow_back_ios_rounded,
                            color: FlutterFlowTheme.of(context).primary,
                            size: 24.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SafeArea(
                  child: Container(
                    color: FlutterFlowTheme.of(context).primaryBackground,
                    child: Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        16.0,
                        0.0,
                        16.0,
                        0.0,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        children: children.divide(const SizedBox(height: 16.0)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusBanner(BuildContext context) {
    final rejected = widget.request.status == ParkingRequestStatus.rejected;
    return Container(
      key: ParkingRequestDetailsView.statusBannerKey,
      width: double.infinity,
      decoration: BoxDecoration(
        color: rejected
            ? const Color(0x15F75555)
            : FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(12.0, 8.0, 12.0, 8.0),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(0.0),
              child: SvgPicture.asset(
                rejected
                    ? 'assets/images/attantion.svg'
                    : Theme.of(context).brightness == Brightness.dark
                        ? 'assets/images/pending_dark.svg'
                        : 'assets/images/pending.svg',
                width: 18.0,
                height: 18.0,
                fit: BoxFit.cover,
              ),
            ),
            Text(
              FFLocalizations.of(context).getText(
                rejected
                    ? 'etzzmx5b' /* Request was rejected */
                    : 'buuba128' /* Request under moderation */,
              ),
              style: FlutterFlowTheme.of(context).bodyMedium.override(
                    font: GoogleFonts.roboto(
                      fontWeight:
                          FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                      fontStyle:
                          FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                    ),
                    color: rejected
                        ? FlutterFlowTheme.of(context).accent3
                        : FlutterFlowTheme.of(context).accent4,
                    letterSpacing: 0.0,
                    fontWeight:
                        FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                    fontStyle:
                        FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                  ),
            ),
          ].divide(const SizedBox(width: 8.0)),
        ),
      ),
    );
  }

  Widget _photos(BuildContext context) {
    final state = _controller.state;
    if (state.photosPhase == ParkingRequestsLoadPhase.idle ||
        state.photosPhase == ParkingRequestsLoadPhase.loading) {
      return _loading(
        context,
        key: ParkingRequestDetailsView.photosLoadingKey,
      );
    }
    if (state.photosPhase == ParkingRequestsLoadPhase.failure) {
      return InkWell(
        key: ParkingRequestDetailsView.photosFailureKey,
        onTap: () => unawaited(_controller.loadPhotos()),
        child: _loading(context),
      );
    }
    if (state.photos.isEmpty) {
      return Container(
        key: ParkingRequestDetailsView.photosEmptyKey,
        width: double.infinity,
        height: 194.0,
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).secondaryBackground,
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Icon(
          Icons.no_photography,
          color: FlutterFlowTheme.of(context).checkBoxes,
          size: 100.0,
        ),
      );
    }

    return SizedBox(
      key: ParkingRequestDetailsView.photosPageKey,
      width: double.infinity,
      height: 210.0,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.horizontal,
            itemCount: state.photos.length,
            itemBuilder: (context, index) => ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Image.network(
                state.photos[index].url,
                width: double.infinity,
                height: 194.0,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Align(
            alignment: const AlignmentDirectional(0.0, 0.8),
            child: smooth_page_indicator.SmoothPageIndicator(
              controller: _pageController,
              count: state.photos.length,
              axisDirection: Axis.horizontal,
              onDotClicked: (index) => _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 500),
                curve: Curves.ease,
              ),
              effect: smooth_page_indicator.SlideEffect(
                spacing: 8.0,
                radius: 8.0,
                dotWidth: 8.0,
                dotHeight: 8.0,
                dotColor: FlutterFlowTheme.of(context).thertaryText,
                activeDotColor:
                    FlutterFlowTheme.of(context).secondaryBackground,
                paintStyle: PaintingStyle.fill,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _address(BuildContext context) => _infoContainer(
        key: ParkingRequestDetailsView.addressKey,
        context: context,
        iconAsset: 'assets/images/map.svg',
        child: Flexible(
          child: Text(
            valueOrDefault<String>(widget.request.address, 'No address'),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: FlutterFlowTheme.of(context).labelLarge.override(
                  font: GoogleFonts.roboto(
                    fontWeight:
                        FlutterFlowTheme.of(context).labelLarge.fontWeight,
                    fontStyle:
                        FlutterFlowTheme.of(context).labelLarge.fontStyle,
                  ),
                  letterSpacing: 0.0,
                  fontWeight:
                      FlutterFlowTheme.of(context).labelLarge.fontWeight,
                  fontStyle: FlutterFlowTheme.of(context).labelLarge.fontStyle,
                ),
          ),
        ),
      );

  Widget _reviews(BuildContext context) {
    final state = _controller.state;
    if (state.reviewCountPhase == ParkingRequestsLoadPhase.idle ||
        state.reviewCountPhase == ParkingRequestsLoadPhase.loading) {
      return _loading(
        context,
        key: ParkingRequestDetailsView.reviewLoadingKey,
      );
    }
    if (state.reviewCountPhase == ParkingRequestsLoadPhase.failure) {
      return InkWell(
        key: ParkingRequestDetailsView.reviewFailureKey,
        onTap: () => unawaited(_controller.loadReviewCount()),
        child: _loading(context),
      );
    }
    return _infoContainer(
      context: context,
      iconAsset: 'assets/images/review.svg',
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.request.rating?.toString() ?? '4.0',
            style: FlutterFlowTheme.of(context).bodyLarge.override(
                  font: GoogleFonts.roboto(fontWeight: FontWeight.w500),
                  letterSpacing: 0.0,
                  fontWeight: FontWeight.w500,
                ),
          ),
          Text(
            '${state.reviewCount} ${FFLocalizations.of(context).getVariableText(enText: 'reviews', ruText: 'отзывов')}',
            style: FlutterFlowTheme.of(context).labelLarge.override(
                  font: GoogleFonts.roboto(
                    fontWeight:
                        FlutterFlowTheme.of(context).labelLarge.fontWeight,
                  ),
                  fontSize: 15.0,
                  letterSpacing: 0.0,
                ),
          ),
        ].divide(const SizedBox(height: 4.0)),
      ),
    );
  }

  Widget _capacity(BuildContext context) => _infoContainer(
        key: ParkingRequestDetailsView.capacityKey,
        context: context,
        iconAsset: 'assets/images/spaces.svg',
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              FFLocalizations.of(context).getText(_translationKeys.capacity),
              style: FlutterFlowTheme.of(context).bodyLarge.override(
                    font: GoogleFonts.roboto(fontWeight: FontWeight.w500),
                    letterSpacing: 0.0,
                    fontWeight: FontWeight.w500,
                  ),
            ),
            Text(
              widget.request.totalSpaces?.toString() ?? '-',
              style: FlutterFlowTheme.of(context).labelLarge.override(
                    font: GoogleFonts.roboto(
                      fontWeight:
                          FlutterFlowTheme.of(context).labelLarge.fontWeight,
                    ),
                    fontSize: 15.0,
                    letterSpacing: 0.0,
                  ),
            ),
          ].divide(const SizedBox(height: 4.0)),
        ),
      );

  Widget _infoContainer({
    Key? key,
    required BuildContext context,
    required String iconAsset,
    required Widget child,
  }) =>
      Container(
        key: key,
        width: double.infinity,
        height: 72.0,
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).secondaryBackground,
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(0.0),
                child: SvgPicture.asset(
                  iconAsset,
                  width: 30.0,
                  height: 30.0,
                  fit: BoxFit.cover,
                ),
              ),
              child,
            ].divide(const SizedBox(width: 12.0)),
          ),
        ),
      );

  Widget _services(BuildContext context) {
    final services = [
      (
        visible: widget.request.hasGasStation,
        asset: 'assets/images/gas.svg',
        label: _translationKeys.gasStation,
      ),
      (
        visible: widget.request.hasShower,
        asset: 'assets/images/shower.svg',
        label: _translationKeys.shower,
      ),
      (
        visible: widget.request.hasLaundry,
        asset: 'assets/images/laundry.svg',
        label: _translationKeys.laundry,
      ),
      (
        visible: widget.request.hasHotel,
        asset: 'assets/images/hotel.svg',
        label: _translationKeys.hotel,
      ),
      (
        visible: widget.request.hasShop,
        asset: 'assets/images/shop.svg',
        label: _translationKeys.shop,
      ),
      (
        visible: widget.request.hasRecreationArea,
        asset: 'assets/images/coffee.svg',
        label: _translationKeys.recreationArea,
      ),
    ];

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 36.0),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).secondaryBackground,
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16.0, 16.0, 16.0, 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  0.0,
                  0.0,
                  0.0,
                  14.0,
                ),
                child: Text(
                  FFLocalizations.of(context)
                      .getText(_translationKeys.additionalServices),
                  style: FlutterFlowTheme.of(context).bodyLarge.override(
                        font: GoogleFonts.roboto(fontWeight: FontWeight.w500),
                        letterSpacing: 0.0,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
              for (final service in services)
                if (service.visible)
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      0.0,
                      10.0,
                      0.0,
                      10.0,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(0.0),
                          child: SvgPicture.asset(
                            service.asset,
                            width: 24.0,
                            height: 24.0,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Text(
                          FFLocalizations.of(context).getText(service.label),
                          style:
                              FlutterFlowTheme.of(context).bodyLarge.override(
                                    font: GoogleFonts.roboto(
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .bodyLarge
                                          .fontWeight,
                                    ),
                                    letterSpacing: 0.0,
                                  ),
                        ),
                      ].divide(const SizedBox(width: 16.0)),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _loading(BuildContext context, {Key? key}) => Center(
        child: SizedBox(
          key: key,
          width: 50.0,
          height: 50.0,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              FlutterFlowTheme.of(context).primary,
            ),
          ),
        ),
      );

  _DetailsTranslationKeys get _translationKeys =>
      switch (widget.request.status) {
        ParkingRequestStatus.pending => const _DetailsTranslationKeys(
            capacity: 'qaii939u',
            additionalServices: '4pcnkj37',
            gasStation: '8w0lya63',
            shower: 'u4t7ah6v',
            laundry: 'ln71rckf',
            hotel: '5tg57khw',
            shop: 'okvhauwn',
            recreationArea: 'f6mlhyp9',
          ),
        ParkingRequestStatus.approved => const _DetailsTranslationKeys(
            capacity: 'ddptkcow',
            additionalServices: 'gea2j1pf',
            gasStation: 'o417beo6',
            shower: 'aixmh7aq',
            laundry: '1uh98xps',
            hotel: 'qz5a0rvg',
            shop: 'r3l81vm2',
            recreationArea: '41rb59qv',
          ),
        ParkingRequestStatus.rejected => const _DetailsTranslationKeys(
            capacity: 'keor7ie4',
            additionalServices: 'lo8hjh4q',
            gasStation: 'oucn91nl',
            shower: 't37c1t9b',
            laundry: 'pkntm941',
            hotel: 'okjbagoe',
            shop: 'mc2100o5',
            recreationArea: 'bo6l1893',
          ),
      };
}

class _DetailsTranslationKeys {
  const _DetailsTranslationKeys({
    required this.capacity,
    required this.additionalServices,
    required this.gasStation,
    required this.shower,
    required this.laundry,
    required this.hotel,
    required this.shop,
    required this.recreationArea,
  });

  final String capacity;
  final String additionalServices;
  final String gasStation;
  final String shower;
  final String laundry;
  final String hotel;
  final String shop;
  final String recreationArea;
}
