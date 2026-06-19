import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:geolocator/geolocator.dart' as geo;
import '../../../core/theme/app_colors.dart';
import '../providers/report_providers.dart';
import '../models/pothole_report.dart';
import 'report_screen.dart';
import 'pothole_detail_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  MapboxMap? _mapboxMap;
  PointAnnotationManager? _annotationManager;
  bool _mapReady = false;
  bool _isDarkStyle = true;

  late AnimationController _fabAnimController;
  late Animation<double> _fabAnim;

  // Cache for dynamically generated marker icons
  PointAnnotation? _userLocationAnnotation;
  Uint8List? _userLocationIconBytes;
  Uint8List? _reportedIconBytes;
  Uint8List? _inProgressIconBytes;
  Uint8List? _fixedIconBytes;

  // Mapping of annotation IDs to PotholeReport objects for click events
  final Map<String, PotholeReport> _annotationToReportMap = {};

  @override
  void initState() {
    super.initState();
    _fabAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fabAnim = CurvedAnimation(
      parent: _fabAnimController,
      curve: Curves.elasticOut,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(currentLocationProvider.notifier).fetchLocation();
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _fabAnimController.forward();
      });
    });
  }

  @override
  void dispose() {
    _fabAnimController.dispose();
    super.dispose();
  }

  void _onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
    _annotationManager =
        await mapboxMap.annotations.createPointAnnotationManager();

    // Add click listener to route marker clicks to PotholeDetailScreen
    _annotationManager!.addOnPointAnnotationClickListener(
      _PointAnnotationClickListener((annotation) {
        final report = _annotationToReportMap[annotation.id];
        if (report != null && mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PotholeDetailScreen(report: report),
            ),
          );
        }
      }),
    );

    // Enable native location dot components as fallback
    try {
      await _mapboxMap!.location.updateSettings(
        LocationComponentSettings(
          enabled: true,
          pulsingEnabled: true,
        ),
      );
    } catch (_) {}

    setState(() => _mapReady = true);

    // Initial marker draw since data might be loaded on startup
    final reports = ref.read(allPotholesProvider).valueOrNull;
    if (reports != null) {
      _updateMapMarkers(reports);
    }

    final location = ref.read(currentLocationProvider).valueOrNull;
    if (location != null) {
      _updateUserLocationMarker(location);
    }
  }

  /// Generates a circular PNG icon with drop shadow and border dynamically in memory
  Future<Uint8List> _createCircleMarkerBytes({
    required Color color,
    required double radius,
    Color borderColor = Colors.white,
    double borderWidth = 2.0,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = (radius + borderWidth) * 2 + 4; // Padding for shadow blur
    final center = size / 2;

    // 1. Draw soft drop shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
    canvas.drawCircle(
        Offset(center, center), radius + borderWidth - 1, shadowPaint);

    // 2. Draw white border
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
        Offset(center, center), radius + borderWidth, borderPaint);

    // 3. Draw fill circle
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(center, center), radius, fillPaint);

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);
    return pngBytes!.buffer.asUint8List();
  }

  Future<Uint8List> _getPotholeIcon(PotholeStatus status) async {
    switch (status) {
      case PotholeStatus.fixed:
        return _fixedIconBytes ??= await _createCircleMarkerBytes(
          color: AppColors.statusFixed,
          radius: 8.0,
          borderColor: Colors.white,
          borderWidth: 2.0,
        );
      case PotholeStatus.inProgress:
        return _inProgressIconBytes ??= await _createCircleMarkerBytes(
          color: AppColors.statusInProgress,
          radius: 8.0,
          borderColor: Colors.white,
          borderWidth: 2.0,
        );
      default:
        return _reportedIconBytes ??= await _createCircleMarkerBytes(
          color: AppColors.statusReported,
          radius: 8.0,
          borderColor: Colors.white,
          borderWidth: 2.0,
        );
    }
  }

  /// Places or updates the bright blue current location puck on the map
  Future<void> _updateUserLocationMarker(geo.Position location) async {
    if (_annotationManager == null || !_mapReady) return;

    _userLocationIconBytes ??= await _createCircleMarkerBytes(
      color: const Color(0xFF007AFF), // iOS/Mapbox Blue puck
      radius: 9.0,
      borderColor: Colors.white,
      borderWidth: 3.0,
    );

    if (_userLocationAnnotation != null) {
      try {
        await _annotationManager!.delete(_userLocationAnnotation!);
      } catch (_) {}
    }

    final options = PointAnnotationOptions(
      geometry: Point(
        coordinates: Position(location.longitude, location.latitude),
      ),
      image: _userLocationIconBytes,
    );

    _userLocationAnnotation = await _annotationManager!.create(options);
  }

  /// Updates and draws all reported pothole markers on the map
  Future<void> _updateMapMarkers(List<PotholeReport> reports) async {
    if (_annotationManager == null || !_mapReady) return;

    // Delete all annotations and clear the click tracking map
    await _annotationManager!.deleteAll();
    _annotationToReportMap.clear();

    // Re-draw user location since deleteAll removes it too
    final userLocation = ref.read(currentLocationProvider).valueOrNull;
    if (userLocation != null) {
      _userLocationAnnotation = null;
      await _updateUserLocationMarker(userLocation);
    }

    for (final report in reports) {
      final iconBytes = await _getPotholeIcon(report.status);

      final options = PointAnnotationOptions(
        geometry: Point(
          coordinates: Position(report.longitude, report.latitude),
        ),
        image: iconBytes,
      );

      final annotation = await _annotationManager!.create(options);
      _annotationToReportMap[annotation.id] = report;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to changes in pothole list and user location to update markers reactively
    ref.listen<AsyncValue<List<PotholeReport>>>(allPotholesProvider,
        (previous, next) {
      next.whenData((reports) {
        _updateMapMarkers(reports);
      });
    });

    ref.listen<AsyncValue<geo.Position?>>(currentLocationProvider,
        (previous, next) {
      next.whenData((location) {
        if (location != null) {
          _updateUserLocationMarker(location);
        }
      });
    });

    final locationAsync = ref.watch(currentLocationProvider);
    final reportsAsync = ref.watch(allPotholesProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(reportsAsync),
      body: Stack(
        children: [
          // Map
          MapWidget(
            key: const ValueKey('roadcare_map'),
            cameraOptions: CameraOptions(
              center: Point(
                coordinates: Position(
                  locationAsync.valueOrNull?.longitude ?? 78.9629,
                  locationAsync.valueOrNull?.latitude ?? 20.5937,
                ),
              ),
              zoom: 13.0,
            ),
            styleUri: MapboxStyles.DARK,
            onMapCreated: _onMapCreated,
          ),

          // Location loading indicator
          if (locationAsync is AsyncLoading)
            Positioned(
              top: 110,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Getting your location...',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Map controls (right side)
          Positioned(
            bottom: 100,
            right: 16,
            child: Column(
              children: [
                _buildMapControlButton(
                  icon: Icons.my_location,
                  onTap: _centerOnUserLocation,
                  tooltip: 'My Location',
                ),
                const SizedBox(height: 8),
                _buildMapControlButton(
                  icon: Icons.layers_outlined,
                  onTap: _toggleMapStyle,
                  tooltip: 'Toggle Style',
                ),
              ],
            ),
          ),

          // Custom FAB to avoid overlap
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: ScaleTransition(
                scale: _fabAnim,
                child: FloatingActionButton.extended(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ReportScreen()),
                  ),
                  icon: const Icon(Icons.add_road),
                  label: const Text(
                    'Report Pothole',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 8,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
      AsyncValue<List<PotholeReport>> reportsAsync) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xEE0D1117), Colors.transparent],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.report_problem_rounded,
                color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 10),
          const Text(
            'RoadCare',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
      actions: [
        reportsAsync.when(
          data: (reports) {
            final active =
                reports.where((r) => r.status != PotholeStatus.fixed).length;
            return Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppColors.statusReported,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$active active',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildMapControlButton({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(icon, color: AppColors.textPrimary, size: 20),
        ),
      ),
    );
  }

  void _centerOnUserLocation() async {
    final location = ref.read(currentLocationProvider).valueOrNull;
    if (location != null && _mapboxMap != null) {
      await _mapboxMap!.setCamera(
        CameraOptions(
          center: Point(
            coordinates: Position(location.longitude, location.latitude),
          ),
          zoom: 15.0,
        ),
      );
      _updateUserLocationMarker(location);
    } else {
      await ref.read(currentLocationProvider.notifier).fetchLocation();
      final newState = ref.read(currentLocationProvider);

      if (newState.hasError && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(newState.error.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      } else if (newState.valueOrNull != null && _mapboxMap != null) {
        final newLoc = newState.valueOrNull!;
        await _mapboxMap!.setCamera(
          CameraOptions(
            center: Point(
              coordinates: Position(newLoc.longitude, newLoc.latitude),
            ),
            zoom: 15.0,
          ),
        );
        _updateUserLocationMarker(newLoc);
      }
    }
  }

  void _toggleMapStyle() async {
    if (_mapboxMap == null) return;
    _isDarkStyle = !_isDarkStyle;
    await _mapboxMap!.loadStyleURI(
      _isDarkStyle ? MapboxStyles.DARK : MapboxStyles.LIGHT,
    );
  }
}

class _PointAnnotationClickListener extends OnPointAnnotationClickListener {
  final void Function(PointAnnotation) onClick;
  _PointAnnotationClickListener(this.onClick);

  @override
  void onPointAnnotationClick(PointAnnotation annotation) {
    onClick(annotation);
  }
}
