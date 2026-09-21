import 'package:flutter/material.dart';

import '../data/campus_data.dart';
import '../data/map_repository.dart';
import '../navigation.dart';
import '../theme/pm_colors.dart';
import '../theme/pm_layout.dart';
import '../theme/pm_text.dart';
import '../theme/pm_tokens.dart';
import '../widgets/dashed_border.dart';
import '../widgets/glyphs.dart';
import '../widgets/pm_cards.dart';
import '../widgets/pm_primitives.dart';
import '../widgets/poly_map_view.dart';
import 'directory_screen.dart';
import 'qr_screen.dart';
import 'search_screen.dart';

/// 05 — Accueil : carte + feuille. The retained direction: the three most
/// frequent routes within thumb reach, the campus map above.
///
/// Wide screens: the sheet becomes a left panel and the map fills the rest.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return PmMapLayout(
      map: PolyMapView(
        showUserPosition: true,
        onBuildingTap: (building) {
          // Find the matching building in CampusData and navigate
          final index = MapRepository.buildings.indexWhere(
            (b) => b.name == building.name,
          );
          if (index >= 0) {
            PmNav.openBuilding(context);
          }
        },
      ),
      compact: (map) => Stack(
        fit: StackFit.expand,
        children: <Widget>[
          map,
          Positioned(
              top: top + 12,
              left: 16,
              right: 16,
              child: const _SearchRow(elevated: true)),
          const Positioned(left: 0, right: 0, bottom: 0, child: _Sheet()),
        ],
      ),
      panel: const _Panel(),
    );
  }
}

class _SearchRow extends StatelessWidget {
  const _SearchRow({this.elevated = false});
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final pm = context.pm;
    return Row(
      children: <Widget>[
        Expanded(
          child: PmSearchPlaceholder(
            elevated: elevated,
            onTap: () => PmNav.push<void>(context, const SearchScreen()),
          ),
        ),
        const SizedBox(width: 10),
        _RoundButton(
          elevated: elevated,
          onTap: () => PmNav.pushFullscreen<void>(context, const QrScreen()),
          semantics: 'Me localiser par QR code',
          child: SquareGlyph(color: pm.brown, width: 16, height: 16, radius: 4),
        ),
      ],
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.child,
    required this.onTap,
    required this.semantics,
    this.elevated = false,
  });
  final Widget child;
  final VoidCallback onTap;
  final String semantics;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final pm = context.pm;
    return Semantics(
      button: true,
      label: semantics,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(PmRadius.card),
          boxShadow: elevated ? PmShadow.floating(pm) : null,
        ),
        child: Material(
          color: pm.surf,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(PmRadius.card),
            side: BorderSide(color: pm.line),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(onTap: onTap, child: Center(child: child)),
        ),
      ),
    );
  }
}

/// Shared body of the sheet / panel: title, quick routes, browse link.
class _Destinations extends StatelessWidget {
  const _Destinations();

  @override
  Widget build(BuildContext context) {
    final pm = context.pm;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: <Widget>[
            Expanded(
                child: Text('Où allez-vous ?',
                    style: PmText.grotesk(19, color: pm.ink))),
            Text('ESP · FANN',
                style: PmText.mono(10.5, color: pm.ink2, ls: 0.06)),
          ],
        ),
        const SizedBox(height: 14),
        for (var i = 0; i < CampusData.routes.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(height: PmSpace.sm),
          _QuickRoute(index: i),
        ],
        const SizedBox(height: 10),
        DashedBorder(
          color: pm.line,
          radius: PmRadius.card,
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(PmRadius.card),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => PmNav.push<void>(context, const DirectoryScreen()),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text('Parcourir les bâtiments et étages',
                          style: PmText.sans(13.5, color: pm.ink2)),
                    ),
                    Chevron(color: pm.blue, size: 8),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Phone: bottom sheet over the map.
class _Sheet extends StatelessWidget {
  const _Sheet();

  @override
  Widget build(BuildContext context) {
    final pm = context.pm;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
      decoration: BoxDecoration(
        color: pm.surf,
        border: Border(top: BorderSide(color: pm.line)),
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(PmRadius.sheet)),
        boxShadow: PmShadow.sheet(pm),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Center(
            child: Container(
              width: 42,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                  color: pm.line, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const _Destinations(),
        ],
      ),
    );
  }
}

/// Tablet / desktop: left panel next to the map.
class _Panel extends StatelessWidget {
  const _Panel();

  @override
  Widget build(BuildContext context) {
    final pm = context.pm;
    final pad = MediaQuery.paddingOf(context);
    return Container(
      decoration: BoxDecoration(
        color: pm.surf,
        border: Border(right: BorderSide(color: pm.line)),
      ),
      child: ListView(
        padding: EdgeInsets.fromLTRB(22, pad.top + 22, 22, 22),
        children: const <Widget>[
          _SearchRow(),
          SizedBox(height: 26),
          _Destinations(),
        ],
      ),
    );
  }
}

class _QuickRoute extends StatelessWidget {
  const _QuickRoute({required this.index});
  final int index;

  @override
  Widget build(BuildContext context) {
    final pm = context.pm;
    final r = CampusData.routes[index];
    final tint = CampusData.quickRouteTints[index];
    return PmTile(
      onTap: () => PmNav.openRoute(context, index),
      child: Row(
        children: <Widget>[
          PmTagBox(
            text: CampusData.quickRouteTags[index],
            size: 32,
            background: tintColor(pm, tint),
            foreground: onTintColor(pm, tint),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(r.to,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: PmText.label(color: pm.ink)),
                Text('depuis ${r.from}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: PmText.sans(11.5, color: pm.ink2)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text('${r.minutes} min', style: PmText.mono(11.5, color: pm.ink2)),
        ],
      ),
    );
  }
}
