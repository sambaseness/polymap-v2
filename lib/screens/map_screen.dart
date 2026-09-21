import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models.dart' as models;
import '../data/map_repository.dart';
import '../navigation.dart';
import '../state/app_state.dart';
import '../theme/pm_colors.dart';
import '../theme/pm_text.dart';
import '../theme/pm_tokens.dart';
import '../widgets/glyphs.dart';
import '../widgets/pm_button.dart';
import '../widgets/poly_map_view.dart';
import 'route_screen.dart';

/// Full-screen map for navigation.
///
/// Shows the real OSM map with building markers, route polyline,
/// and turn-by-turn navigation controls.
class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  static void open(BuildContext context) {
    PmNav.pushFullscreen<void>(context, const MapScreen());
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final computedRoute = state.computedRoute;
    final pad = MediaQuery.paddingOf(context);

    // Get GPS route points based on mode
    final routePoints = switch (state.mode) {
      models.RouteMode.walk => MapRepository.route1Walk,
      models.RouteMode.accessible => MapRepository.route1Accessible,
      models.RouteMode.shortest => MapRepository.route1Shortest,
    };

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Full-screen map
          PolyMapView(
            showUserPosition: true,
            routePoints: routePoints,
            routeColor: null,
            onBuildingTap: (building) => _showBuildingInfo(context, building),
            onMapReady: () {
              debugPrint('Map ready — center: ${MapRepository.campusCenter}');
            },
          ),

          // Top bar: back + route info
          Positioned(
            top: pad.top + 8,
            left: 16,
            right: 16,
            child: _MapHeader(route: computedRoute, mode: state.mode),
          ),

          // Bottom navigation controls
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _NavigationControls(progress: computedRoute),
          ),

          // Floating action buttons
          Positioned(
            right: 16,
            top: pad.top + 60,
            child: _MapFABs(),
          ),
        ],
      ),
    );
  }

  void _showBuildingInfo(BuildContext context, BuildingGps building) {
    final pm = context.pm;
    showModalBottomSheet(
      context: context,
      backgroundColor: pm.surf,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(22, 16, 22, MediaQuery.paddingOf(ctx).bottom + 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(building.name, style: PmText.grotesk(20, color: pm.ink)),
            const SizedBox(height: 8),
            Text(building.short, style: PmText.sans(14, color: pm.ink2)),
            const SizedBox(height: 16),
            PmButton(
              label: 'Itinéraire',
              onTap: () {
                Navigator.pop(ctx);
                context.read<AppState>().openRoute(0);
                PmNav.push<void>(ctx, const RouteScreen());
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Header bar showing route origin/destination and mode selector.
class _MapHeader extends StatelessWidget {
  const _MapHeader({required this.route, required this.mode});

  final models.ComputedRoute route;
  final models.RouteMode mode;

  @override
  Widget build(BuildContext context) {
    final pm = context.pm;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: pm.surf,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: pm.shadow, offset: const Offset(0, 4), blurRadius: 16)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Chevron(color: Colors.black87, size: 10),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${route.route.from} → ${route.route.to}',
                        style: PmText.grotesk(15, color: pm.ink, weight: FontWeight.w600)),
                    Text('${route.distM} m · ${route.minutes} min',
                        style: PmText.sans(11, color: pm.ink2)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Mode selector tabs
          Row(
            children: models.RouteMode.values.map((m) {
              final isSelected = m == mode;
              return Expanded(
                child: GestureDetector(
                  onTap: () => context.read<AppState>().mode = m,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? pm.blue : pm.surf2,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        m.label,
                        style: PmText.sans(11,
                            color: isSelected ? Colors.white : pm.ink2,
                            weight: isSelected ? FontWeight.w600 : FontWeight.w400),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// Bottom navigation bar with progress and controls.
class _NavigationControls extends StatelessWidget {
  const _NavigationControls({required this.progress});

  final models.ComputedRoute progress;

  /// Estimated fraction of route completed (0.0 to 1.0).
  /// Based on midpoint of route as a placeholder.
  double get _fraction => (progress.hereIndex / (progress.points.length - 1)).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final pm = context.pm;
    return Container(
      padding: EdgeInsets.fromLTRB(18, 14, 18, 18),
      decoration: BoxDecoration(
        color: pm.surf,
        border: Border(top: BorderSide(color: pm.line)),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [BoxShadow(color: pm.shadow, offset: const Offset(0, -5), blurRadius: 20)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${progress.minutes} min',
                        style: PmText.grotesk(22, color: pm.ink, weight: FontWeight.w700)),
                    Text('${progress.distM} m restants',
                        style: PmText.sans(11, color: pm.ink2)),
                  ],
                ),
              ),
              PmButton(
                label: 'Arrêter',
                variant: PmButtonVariant.ghost,
                height: 40,
                radius: 12,
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: SizedBox(
              height: 4,
              child: LinearProgressIndicator(
                value: _fraction.clamp(0.0, 1.0),
                backgroundColor: pm.surf2,
                color: pm.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Floating action buttons for map controls.
class _MapFABs extends StatelessWidget {
  const _MapFABs();

  @override
  Widget build(BuildContext context) {
    final pm = context.pm;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _MapFAB(
          icon: Icons.add,
          onTap: () {},
          color: pm.surf,
          border: pm.line,
        ),
        const SizedBox(height: 8),
        _MapFAB(
          icon: Icons.remove,
          onTap: () {},
          color: pm.surf,
          border: pm.line,
        ),
        const SizedBox(height: 8),
        _MapFAB(
          icon: Icons.my_location,
          onTap: () {},
          color: pm.blue,
          border: null,
        ),
      ],
    );
  }
}

/// Individual floating action button.
class _MapFAB extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final Color? border;

  const _MapFAB({
    required this.icon,
    required this.onTap,
    required this.color,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final pm = context.pm;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: border == null ? null : Border.all(color: border!),
        boxShadow: PmShadow.floating(pm),
      ),
      child: Material(
        color: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Center(
            child: Icon(icon,
                color: color == pm.blue ? Colors.white : pm.ink, size: 20),
          ),
        ),
      ),
    );
  }
}
