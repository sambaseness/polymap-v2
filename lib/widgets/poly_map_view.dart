import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:latlong2/latlong.dart';

import '../data/map_repository.dart';
import '../theme/pm_colors.dart';
import '../theme/pm_text.dart';

/// Unified campus map widget built on flutter_map.
///
/// This replaces both [RealCampusMap] (OSM tiles) and [CampusMap]
/// (schematic CustomPaint) with a single widget that handles:
/// - OpenStreetMap tile rendering
/// - Building markers with colored pins
/// - Real user position via [CurrentLocationLayer]
/// - Route polylines
/// - Building tap callbacks
/// - Map ready callback
class PolyMapView extends StatefulWidget {
  const PolyMapView({
    super.key,
    this.showUserPosition = true,
    this.routePoints,
    this.routeColor,
    this.onBuildingTap,
    this.onMapReady,
    this.initialZoom = 17.0,
    this.showLabels = true,
    this.fitBounds = false,
  });

  final bool showUserPosition;
  final List<LatLng>? routePoints;
  final Color? routeColor;
  final void Function(BuildingGps building)? onBuildingTap;
  final VoidCallback? onMapReady;
  final double initialZoom;
  final bool showLabels;
  final bool fitBounds;

  @override
  State<PolyMapView> createState() => _PolyMapViewState();
}

class _PolyMapViewState extends State<PolyMapView> {
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.fitBounds) {
        _fitToCampus();
      }
      widget.onMapReady?.call();
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  /// Fit the map to the campus bounding box.
  Future<void> _fitToCampus() async {
    _mapController.move(MapRepository.campusCenter, widget.initialZoom);
  }

  @override
  Widget build(BuildContext context) {
    final pm = context.pm;

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: MapRepository.campusCenter,
        initialZoom: widget.initialZoom,
        minZoom: 15.0,
        maxZoom: 19.0,
        onMapReady: widget.onMapReady,
      ),
      children: [
        // OpenStreetMap tile layer
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.polymap.esp',
          maxZoom: 19,
        ),

        // Route polyline
        if (widget.routePoints != null && widget.routePoints!.length >= 2)
          PolylineLayer(
            polylines: [
              Polyline(
                points: widget.routePoints!,
                color: widget.routeColor ?? pm.blue,
                strokeWidth: 5.0,
                borderStrokeWidth: 2.0,
                borderColor: pm.surf,
              ),
            ],
          ),

        // Building markers
        MarkerLayer(
          markers: [
            for (final building in MapRepository.buildings)
              Marker(
                point: building.position,
                width: 40,
                height: 40,
                child: GestureDetector(
                  onTap: () => widget.onBuildingTap?.call(building),
                  child: _BuildingMarker(
                    building: building,
                    color: _buildingMarkerColor(building.color, pm),
                    showLabel: widget.showLabels,
                    pm: pm,
                  ),
                ),
              ),
          ],
        ),

        // User's current GPS position via flutter_map_location_marker
        if (widget.showUserPosition)
          CurrentLocationLayer(
            style: LocationMarkerStyle(
              marker: const DefaultLocationMarker(
                child: Icon(Icons.navigation, color: Colors.white, size: 24),
              ),
              markerSize: const Size(40, 40),
              markerDirection: MarkerDirection.heading,
            ),
            alignPositionOnUpdate: AlignOnUpdate.always,
            alignDirectionOnUpdate: AlignOnUpdate.never,
          ),

        // Attribution
        RichAttributionWidget(
          attributions: [
            TextSourceAttribution(
              'OpenStreetMap contributors',
              textStyle: PmText.sans(10, color: pm.ink2),
            ),
          ],
        ),
      ],
    );
  }
}

/// Colored building marker color helper.
Color _buildingMarkerColor(BuildingColor color, PmColors pm) {
  return switch (color) {
    BuildingColor.blue => pm.blue,
    BuildingColor.brown => pm.brown,
    BuildingColor.ochre => pm.ochre,
    BuildingColor.green => pm.green,
  };
}

/// Colored building marker with optional label.
class _BuildingMarker extends StatelessWidget {
  const _BuildingMarker({
    required this.building,
    required this.color,
    required this.showLabel,
    required this.pm,
  });

  final BuildingGps building;
  final Color color;
  final bool showLabel;
  final PmColors pm;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Building icon
        Center(
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: pm.surf, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: pm.shadow,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                building.short.split('\n').first,
                style: PmText.sans(8, weight: FontWeight.w600, color: pm.surf),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
        // Building name label
        if (showLabel && building.short.length > 6)
          Positioned(
            bottom: -16,
            left: 48,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: pm.surf.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                building.short.split('\n').first,
                style: PmText.sans(7, color: pm.ink),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
      ],
    );
  }
}

/// Compact map preview — a smaller version of PolyMapView for use inside
/// sheets and panels. Automatically hides user position and labels.
class PolyMapPreview extends StatelessWidget {
  const PolyMapPreview({
    super.key,
    this.routePoints,
    this.routeColor,
    this.onBuildingTap,
    this.height = 200,
  });

  final List<LatLng>? routePoints;
  final Color? routeColor;
  final void Function(BuildingGps building)? onBuildingTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: PolyMapView(
        showUserPosition: false,
        showLabels: false,
        routePoints: routePoints,
        routeColor: routeColor,
        onBuildingTap: onBuildingTap,
        initialZoom: 15.0,
        fitBounds: true,
      ),
    );
  }
}
