import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models.dart';
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
import '../widgets/pm_cards.dart';
import '../widgets/pm_primitives.dart';
import '../widgets/poly_map_view.dart';
import 'nav2d_screen.dart';

/// 13 — Aperçu itinéraire. Three variants: on foot, accessible, shortest.
class RouteScreen extends StatelessWidget {
  const RouteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    final state = context.watch<AppState>();
    final r = state.computedRoute;

    // Get route GPS points based on mode
    final routePoints = switch (state.mode) {
      models.RouteMode.walk => MapRepository.route1Walk,
      models.RouteMode.accessible => MapRepository.route1Accessible,
      models.RouteMode.shortest => MapRepository.route1Shortest,
    };

    return Scaffold(
      body: PmMapLayout(
        map: PolyMapView(
          showUserPosition: false,
          routePoints: routePoints,
          routeColor: null,
        ),
        compact: (map) => Stack(
          fit: StackFit.expand,
          children: <Widget>[
            map,
            Positioned(
                top: pad.top + 8,
                left: 16,
                right: 16,
                child: _Header(route: r, mode: state.mode)),
            Positioned(left: 0, right: 0, bottom: 0, child: _Sheet(route: r)),
          ],
        ),
        panel: _Panel(route: r, mode: state.mode),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.route, required this.mode, this.card = true});
  final ComputedRoute route;
  final RouteMode mode;
  final bool card;

  @override
  Widget build(BuildContext context) {
    final pm = context.pm;
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            PmBackButton(
                size: 26, onTap: () => Navigator.of(context).maybePop()),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Départ · ${route.route.from}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: PmText.sans(11.5, color: pm.ink2)),
                  Text(route.route.to,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: PmText.grotesk(17, color: pm.ink)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        PmSegmented<RouteMode>(
          values: RouteMode.values,
          selected: mode,
          labelOf: (m) => m.label,
          onChanged: (m) => context.read<AppState>().mode = m,
          radius: 10,
          verticalPadding: 8,
          fontSize: 12,
        ),
      ],
    );
    if (!card) return body;
    return PmCard(
      radius: 16,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      shadow: <BoxShadow>[
        BoxShadow(color: pm.shadow, offset: const Offset(0, 8), blurRadius: 24)
      ],
      child: body,
    );
  }
}

class _Steps extends StatelessWidget {
  const _Steps({required this.route, this.scrollable = true});
  final ComputedRoute route;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[for (final s in route.steps) PmStepRow(s)];
    if (!scrollable) return Column(children: rows);
    return ConstrainedBox(
      constraints:
          BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.34),
      child:
          ListView(shrinkWrap: true, padding: EdgeInsets.zero, children: rows),
    );
  }
}

class _StartButton extends StatelessWidget {
  const _StartButton();

  @override
  Widget build(BuildContext context) => PmButton(
        label: 'Démarrer la navigation',
        height: 54,
        fontSize: 16,
        leading: Chevron(
            color: context.pm.onBlue,
            size: 10,
            thickness: 2.5,
            direction: AxisDirection.up),
        onTap: () => PmNav.push<void>(context, const Nav2dScreen()),
      );
}

/// Phone: bottom sheet with summary, steps and the start button.
class _Sheet extends StatelessWidget {
  const _Sheet({required this.route});
  final ComputedRoute route;

  @override
  Widget build(BuildContext context) {
    final pm = context.pm;
    final pad = MediaQuery.paddingOf(context);
    return Container(
      padding: EdgeInsets.fromLTRB(18, 14, 18, pad.bottom + 12),
      decoration: BoxDecoration(
        color: pm.surf,
        border: Border(top: BorderSide(color: pm.line)),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        boxShadow: PmShadow.sheet(pm),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          PmRouteSummary(
              minutes: route.minutes,
              distM: route.distM,
              steps: route.steps.length),
          const SizedBox(height: 14),
          _Steps(route: route),
          const SizedBox(height: 16),
          const _StartButton(),
        ],
      ),
    );
  }
}

/// Wide: everything in the left panel, map on the right.
class _Panel extends StatelessWidget {
  const _Panel({required this.route, required this.mode});
  final ComputedRoute route;
  final RouteMode mode;

  @override
  Widget build(BuildContext context) {
    final pm = context.pm;
    final pad = MediaQuery.paddingOf(context);
    return Container(
      decoration: BoxDecoration(
          color: pm.surf, border: Border(right: BorderSide(color: pm.line))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.fromLTRB(22, pad.top + 20, 22, 18),
            child: _Header(route: route, mode: mode, card: false),
          ),
          const PmDivider(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
              children: <Widget>[
                PmRouteSummary(
                    minutes: route.minutes,
                    distM: route.distM,
                    steps: route.steps.length),
                const SizedBox(height: 14),
                _Steps(route: route, scrollable: false),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(22, 12, 22, pad.bottom + 22),
            child: const _StartButton(),
          ),
        ],
      ),
    );
  }
}
