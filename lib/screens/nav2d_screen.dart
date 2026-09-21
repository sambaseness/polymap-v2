import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models.dart' as models;
import '../data/map_repository.dart';
import '../navigation.dart';
import '../state/app_state.dart';
import '../theme/pm_colors.dart';
import '../theme/pm_layout.dart';
import '../theme/pm_text.dart';
import '../theme/pm_tokens.dart';
import '../widgets/glyphs.dart';
import '../widgets/pm_button.dart';
import '../widgets/poly_map_view.dart';
import 'ar/ar_calibration_screen.dart';

/// 14 — Navigation 2D. Current turn, progress, switch to AR.
class Nav2dScreen extends StatelessWidget {
  const Nav2dScreen({super.key});

  static void _openAr(BuildContext context) =>
      PmNav.pushFullscreen<void>(context, const ArCalibrationScreen());

  @override
  Widget build(BuildContext context) {
    final pm = context.pm;
    final pad = MediaQuery.paddingOf(context);
    final state = context.watch<AppState>();
    final r = state.computedRoute;
    final progress = NavProgress.of(r);

    // Side buttons: AR toggle + 2D indicator
    final sideButtons = Column(
      children: <Widget>[
        _SideButton(
          color: pm.brown,
          semantics: 'Passer en vue AR',
          onTap: () => _openAr(context),
          child: const SquareGlyph(
              color: PmFixed.white, width: 15, height: 12, radius: 3),
        ),
        const SizedBox(height: 8),
        _SideButton(
          color: pm.surf,
          border: pm.line,
          semantics: 'Vue 2D (active)',
          child: Text('2D', style: PmText.mono(11, color: pm.ink2)),
        ),
      ],
    );

    // Get route GPS points based on mode
    final routePoints = switch (state.mode) {
      models.RouteMode.walk => MapRepository.route1Walk,
      models.RouteMode.accessible => MapRepository.route1Accessible,
      models.RouteMode.shortest => MapRepository.route1Shortest,
    };

    return Scaffold(
      body: PmMapLayout(
        map: PolyMapView(
          showUserPosition: true,
          routePoints: routePoints,
          onBuildingTap: null,
        ),
        compact: (map) => Stack(
          fit: StackFit.expand,
          children: <Widget>[
            map,
            Positioned(
                top: pad.top + 6,
                left: 14,
                right: 14,
                child: _TurnCard(progress: progress)),
            Positioned(right: 14, top: pad.top + 208, child: sideButtons),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: EdgeInsets.fromLTRB(18, 16, 18, pad.bottom + 12),
                decoration: BoxDecoration(
                  color: pm.surf,
                  border: Border(top: BorderSide(color: pm.line)),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                        color: pm.shadow,
                        offset: const Offset(0, -10),
                        blurRadius: 30)
                  ],
                ),
                child:
                    _Status(progress: progress, onAr: () => _openAr(context)),
              ),
            ),
          ],
        ),
        panel: Container(
          decoration: BoxDecoration(
              color: pm.surf,
              border: Border(right: BorderSide(color: pm.line))),
          padding: EdgeInsets.fromLTRB(22, pad.top + 20, 22, pad.bottom + 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _TurnCard(progress: progress),
              const Spacer(),
              _Status(progress: progress, onAr: () => _openAr(context)),
            ],
          ),
        ),
        mapOverlay: <Widget>[
          Positioned(right: 18, top: pad.top + 18, child: sideButtons)
        ],
      ),
    );
  }
}

/// Blue card: big distance + current instruction, then the next one.
class _TurnCard extends StatelessWidget {
  const _TurnCard({required this.progress});
  final NavProgress progress;

  @override
  Widget build(BuildContext context) {
    final pm = context.pm;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: pm.blue,
        borderRadius: BorderRadius.circular(20),
        boxShadow: <BoxShadow>[
          BoxShadow(
              color: pm.shadow, offset: const Offset(0, 10), blurRadius: 28)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              SizedBox(
                  width: 46,
                  height: 46,
                  child: Center(child: NavArrow(color: pm.onBlue))),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(progress.current.dist,
                        style: PmText.grotesk(34,
                            weight: FontWeight.w700,
                            color: pm.onBlue,
                            height: 1)),
                    const SizedBox(height: 3),
                    Text(progress.current.label,
                        maxLines: 2,
                        style: PmText.sans(14,
                            color: pm.onBlue.withValues(alpha: .88))),
                  ],
                ),
              ),
            ],
          ),
          if (progress.next != null) ...<Widget>[
            const SizedBox(height: 14),
            Container(height: 1, color: pm.onBlue.withValues(alpha: .22)),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Chevron(color: pm.onBlue.withValues(alpha: .9), size: 8),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Puis ${_lower(progress.next!.label)} · ${progress.next!.dist}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: PmText.sans(12.5,
                        color: pm.onBlue.withValues(alpha: .9)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static String _lower(String s) =>
      s.isEmpty ? s : s[0].toLowerCase() + s.substring(1);
}

/// Remaining time / distance, « Vue AR », stop, progress bar.
class _Status extends StatelessWidget {
  const _Status({required this.progress, required this.onAr});
  final NavProgress progress;
  final VoidCallback onAr;

  @override
  Widget build(BuildContext context) {
    final pm = context.pm;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('${progress.minutesLeft} min',
                      style: PmText.grotesk(24,
                          weight: FontWeight.w700, color: pm.ink)),
                  Text(
                      '${progress.metersLeft} m restants · arrivée ${progress.eta}',
                      style: PmText.mono(11.5, color: pm.ink2)),
                ],
              ),
            ),
            PmButton(
              label: 'Vue AR',
              variant: PmButtonVariant.ar,
              expand: false,
              height: 44,
              radius: 14,
              fontSize: 14,
              onTap: onAr,
            ),
            const SizedBox(width: 8),
            Semantics(
              button: true,
              label: 'Arrêter la navigation',
              child: Material(
                color: pm.surf2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: pm.line),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => Navigator.of(context).maybePop(),
                  child: SizedBox(
                    width: kPmTouchTarget,
                    height: kPmTouchTarget,
                    child: Center(child: CrossGlyph(color: pm.ink)),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: SizedBox(
            height: 5,
            child: LinearProgressIndicator(
                value: progress.fraction,
                backgroundColor: pm.surf2,
                color: pm.blue),
          ),
        ),
      ],
    );
  }
}

class _SideButton extends StatelessWidget {
  const _SideButton({
    required this.color,
    required this.child,
    required this.semantics,
    this.border,
    this.onTap,
  });

  final Color color;
  final Color? border;
  final Widget child;
  final String semantics;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final pm = context.pm;
    return Semantics(
      button: onTap != null,
      label: semantics,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: PmShadow.floating(pm)),
        child: Material(
          color: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: border == null ? BorderSide.none : BorderSide(color: border!),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(onTap: onTap, child: Center(child: child)),
        ),
      ),
    );
  }
}

/// Demo progress along a route: half-way through, on the second step —
/// matching the prototype's fixed « 85 m · Traverser l'Allée Jardin ».
/// A real implementation replaces this with live positioning.
class NavProgress {
  const NavProgress({
    required this.current,
    required this.next,
    required this.minutesLeft,
    required this.metersLeft,
    required this.eta,
    required this.fraction,
  });

  final models.RouteStep current;
  final models.RouteStep? next;
  final int minutesLeft;
  final int metersLeft;
  final String eta;
  final double fraction;

  static NavProgress of(models.ComputedRoute r) {
    final steps = r.steps;
    final ci = math.min(1, steps.length - 1);
    final minutesLeft = math.max(1, r.minutes - 1);
    final metersLeft = (r.distM * 0.75 / 5).round() * 5;
    final arrival = DateTime.now().add(Duration(minutes: minutesLeft));
    final eta =
        '${arrival.hour.toString().padLeft(2, '0')}h${arrival.minute.toString().padLeft(2, '0')}';
    return NavProgress(
      current: steps[ci],
      next: ci + 1 < steps.length ? steps[ci + 1] : null,
      minutesLeft: minutesLeft,
      metersLeft: metersLeft,
      eta: eta,
      fraction: 0.34,
    );
  }
}
