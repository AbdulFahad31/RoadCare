import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/report_providers.dart';
import '../models/pothole_report.dart';
import 'report_screen.dart';
import '../widgets/map_legend_widget.dart';
import '../widgets/nearby_stats_widget.dart';

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
    
    // Enable user location dot
    await _mapboxMap!.location.updateSettings(
      LocationComponentSettings(
        enabled: true,
        pulsingEnabled: true,
      ),
    );
    
    setState(() => _mapReady = true);
  }

  Future<void> _updateMapMarkers(List<PotholeReport> reports) async {
    if (_annotationManager == null || !_mapReady) return;

    await _annotationManager!.deleteAll();

    for (final report in reports) {
      final colorInt = _getStatusColorInt(report.status);

      final options = PointAnnotationOptions(
        geometry: Point(
          coordinates: Position(report.longitude, report.latitude),
        ),
        textField: report.id,
        textColor: colorInt,
        textSize: _getSeveritySize(report.severity),
        textOffset: [0, 0],
      );

      await _annotationManager!.create(options);
    }
  }

  int _getStatusColorInt(PotholeStatus status) {
    switch (status) {
      case PotholeStatus.fixed:
        return AppColors.statusFixed.toARGB32();
      case PotholeStatus.inProgress:
        return AppColors.statusInProgress.toARGB32();
      default:
        return AppColors.statusReported.toARGB32();
    }
  }

  double _getSeveritySize(PotholeSeverity severity) {
    switch (severity) {
      case PotholeSeverity.high:
        return 16.0;
      case PotholeSeverity.medium:
        return 13.0;
      default:
        return 10.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationAsync = ref.watch(currentLocationProvider);
    final reportsAsync = ref.watch(allPotholesProvider);

    if (_mapReady) {
      reportsAsync.whenData((reports) => _updateMapMarkers(reports));
    }

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

          // Legend (bottom left)
          const Positioned(
            bottom: 20,
            left: 16,
            child: MapLegendWidget(),
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
    } else {
      await ref.read(currentLocationProvider.notifier).fetchLocation();
      final newState = ref.read(currentLocationProvider);
      
      if (newState.hasError && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newState.error.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      } else if (newState.valueOrNull != null && _mapboxMap != null) {
        await _mapboxMap!.setCamera(
          CameraOptions(
            center: Point(
              coordinates: Position(
                newState.valueOrNull!.longitude,
                newState.valueOrNull!.latitude,
              ),
            ),
            zoom: 15.0,
          ),
        );
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
