import 'package:latlong2/latlong.dart';

/// Map data repository — the single source of truth for campus map data.
///
/// This replaces the scattered data access pattern (CampusData, CampusGps)
/// with a unified repository that provides:
/// - Building locations as LatLng for the real map
/// - Route definitions with GPS coordinates
/// - Search places with targets
/// - Offline fallback polylines
///
/// The campus GPS coordinates for ESP Dakar are approximate but field-verified.
class MapRepository {
  MapRepository._();

  // ========================================================================
  // CAMPUS CENTER & BOUNDS
  // ========================================================================

  /// Approximate campus center for ESP Dakar.
  static const LatLng campusCenter = LatLng(14.6928, -17.4467);

  /// Bounds for the initial map view.
  static const LatLng campusNorthWest = LatLng(14.6935, -17.4475);
  static const LatLng campusSouthEast = LatLng(14.6918, -17.4455);

  // ========================================================================
  // BUILDINGS (GPS coordinates)
  // ========================================================================

  static const List<BuildingGps> buildings = <BuildingGps>[
    // Northern buildings
    BuildingGps(name: 'Innodev', short: 'Innodev', position: LatLng(14.6934, -17.4472), color: BuildingColor.blue),
    BuildingGps(name: "Bibliothèque de l'ESP", short: 'Biblio.', position: LatLng(14.6930, -17.4471), color: BuildingColor.blue),
    BuildingGps(name: 'Amphithéâtre Abdoul Aziz Wane', short: 'Amphi A.A.', position: LatLng(14.6933, -17.4465), color: BuildingColor.brown),
    BuildingGps(name: "Secrétariat de l'ESP", short: 'Secrétariat', position: LatLng(14.6932, -17.4460), color: BuildingColor.brown),
    BuildingGps(name: 'Salle DUT1 Informatique', short: 'DUT1 Info', position: LatLng(14.6927, -17.4460), color: BuildingColor.blue),
    BuildingGps(name: 'Département Génie Chimique', short: 'Génie Chimique', position: LatLng(14.6929, -17.4453), color: BuildingColor.blue),
    BuildingGps(name: 'Département Génie Électrique', short: 'Génie Électrique', position: LatLng(14.6925, -17.4453), color: BuildingColor.blue),
    BuildingGps(name: 'CEPECS', short: 'CEPECS', position: LatLng(14.6922, -17.4471), color: BuildingColor.blue),
    BuildingGps(name: 'Département Génie Informatique', short: 'Génie Info', position: LatLng(14.6919, -17.4470), color: BuildingColor.blue),
    BuildingGps(name: 'Terrain de sport', short: 'Terrain', position: LatLng(14.6918, -17.4462), color: BuildingColor.green),
    BuildingGps(name: 'Labo LER', short: 'Labo LER', position: LatLng(14.6923, -17.4460), color: BuildingColor.blue),
    BuildingGps(name: 'Département Génie Civil', short: 'Génie Civil', position: LatLng(14.6920, -17.4455), color: BuildingColor.blue),
    BuildingGps(name: 'Restaurant ESP', short: 'Resto', position: LatLng(14.6915, -17.4471), color: BuildingColor.ochre),
    // Pavillons (residences)
    BuildingGps(name: 'Pavillon F', short: 'Pav. F', position: LatLng(14.6910, -17.4472), color: BuildingColor.brown),
    BuildingGps(name: 'Pavillon G', short: 'Pav. G', position: LatLng(14.6907, -17.4473), color: BuildingColor.brown),
    BuildingGps(name: 'Pavillon B', short: 'Pav. B', position: LatLng(14.6908, -17.4467), color: BuildingColor.brown),
    BuildingGps(name: 'Salle de télévision', short: 'Salle télé', position: LatLng(14.6910, -17.4462), color: BuildingColor.brown),
    BuildingGps(name: "Mosquée de l'ESP", short: 'Mosquée', position: LatLng(14.6910, -17.4457), color: BuildingColor.brown),
    BuildingGps(name: 'Pavillon A', short: 'Pav. A', position: LatLng(14.6907, -17.4460), color: BuildingColor.brown),
    BuildingGps(name: 'Pavillon C', short: 'Pav. C', position: LatLng(14.6904, -17.4467), color: BuildingColor.brown),
    BuildingGps(name: 'Pavillon E', short: 'Pav. E', position: LatLng(14.6904, -17.4460), color: BuildingColor.brown),
    BuildingGps(name: 'Parking AUF', short: 'P. AUF', position: LatLng(14.6904, -17.4474), color: BuildingColor.brown),
  ];

  /// User's current position (Pavillon C entrance).
  static const LatLng userPosition = LatLng(14.6904, -17.4467);

  // ========================================================================
  // ROUTES (GPS coordinates)
  // ========================================================================

  /// Route: Pavillon C → Département Génie Informatique (walking).
  static const List<LatLng> route1Walk = <LatLng>[
    LatLng(14.6904, -17.4467), LatLng(14.6907, -17.4465),
    LatLng(14.6910, -17.4463), LatLng(14.6913, -17.4465),
    LatLng(14.6916, -17.4468), LatLng(14.6919, -17.4470),
  ];

  /// Route: Pavillon C → Département Génie Informatique (accessible).
  static const List<LatLng> route1Accessible = <LatLng>[
    LatLng(14.6904, -17.4467), LatLng(14.6906, -17.4468),
    LatLng(14.6909, -17.4469), LatLng(14.6912, -17.4468),
    LatLng(14.6915, -17.4469), LatLng(14.6919, -17.4470),
  ];

  /// Route: Pavillon C → Département Génie Informatique (shortest).
  static const List<LatLng> route1Shortest = <LatLng>[
    LatLng(14.6904, -17.4467), LatLng(14.6908, -17.4466),
    LatLng(14.6912, -17.4468), LatLng(14.6919, -17.4470),
  ];

  /// Route: Restaurant ESP → Amphithéâtre Abdoul Aziz Wane (walking).
  static const List<LatLng> route2Walk = <LatLng>[
    LatLng(14.6915, -17.4471), LatLng(14.6918, -17.4467),
    LatLng(14.6923, -17.4462), LatLng(14.6928, -17.4460),
    LatLng(14.6933, -17.4455), LatLng(14.6937, -17.4450),
  ];

  /// Route: Parking AUF → Secrétariat de l'ESP (walking).
  static const List<LatLng> route3Walk = <LatLng>[
    LatLng(14.6904, -17.4474), LatLng(14.6907, -17.4470),
    LatLng(14.6910, -17.4467), LatLng(14.6915, -17.4462),
    LatLng(14.6920, -17.4458), LatLng(14.6925, -17.4455),
    LatLng(14.6932, -17.4460),
  ];

  /// All route definitions by index.
  static const List<List<LatLng>> routeDefinitions = <List<LatLng>>[
    route1Walk, route1Accessible, route1Shortest,
    route2Walk,
    route3Walk,
  ];

  // ========================================================================
  // SEARCH PLACES
  // ========================================================================

  static const List<SearchPlace> places = <SearchPlace>[
    SearchPlace(code: '204', name: 'Salle 204', place: 'Génie Informatique · 1er étage', dist: '335 m', lat: 14.6919, lon: -17.4470),
    SearchPlace(code: '107', name: 'Salle C-107 (TD)', place: 'Pavillon C · 1er étage', dist: '40 m', lat: 14.6904, lon: -17.4467),
    SearchPlace(code: 'LER', name: 'Labo LER 2.04', place: "Laboratoire d'Énergies Renouvelables", dist: '410 m', lat: 14.6923, lon: -17.4460),
    SearchPlace(code: 'AW', name: 'Amphi 204 places', place: 'Amphithéâtre Abdoul Aziz Wane', dist: '260 m', lat: 14.6933, lon: -17.4465),
    SearchPlace(code: 'RE', name: 'Restaurant ESP', place: 'Ouest du terrain', dist: '120 m', lat: 14.6915, lon: -17.4471),
    SearchPlace(code: 'BI', name: "Bibliothèque de l'ESP", place: 'Aile nord · face Innodev', dist: '290 m', lat: 14.6930, lon: -17.4471),
    SearchPlace(code: 'SE', name: "Secrétariat de l'ESP", place: 'Nord du campus', dist: '420 m', lat: 14.6932, lon: -17.4460),
    SearchPlace(code: 'C', name: 'Pavillon C', place: 'Résidence · 3 niveaux', dist: '0 m', lat: 14.6904, lon: -17.4467),
  ];

  // ========================================================================
  // HELPERS
  // ========================================================================

  /// Find a building by its short label.
  static BuildingGps? findBuilding(String shortLabel) {
    return buildings.where((b) => b.short == shortLabel).firstOrNull;
  }

  /// Find a place by code.
  static SearchPlace? findPlace(String code) {
    return places.where((p) => p.code == code).firstOrNull;
  }

  /// Get the route polyline for a given route index.
  /// [modeIndex]: 0 = walk, 1 = accessible, 2 = shortest.
  static List<LatLng> getRoute(int routeIndex, [int modeIndex = 0]) {
    final routes = routeDefinitions;
    if (routeIndex < 0 || routeIndex >= routes.length) return const <LatLng>[];
    final base = routes[routeIndex];
    // For mode variants, return the appropriate variant
    if (routeIndex == 0 && modeIndex == 1) return route1Accessible;
    if (routeIndex == 0 && modeIndex == 2) return route1Shortest;
    return base;
  }
}

/// Building color for the real map.
enum BuildingColor { blue, brown, ochre, green }

/// A building on the real GPS map.
class BuildingGps {
  const BuildingGps({
    required this.name,
    required this.short,
    required this.position,
    required this.color,
  });

  final String name;
  final String short;
  final LatLng position;
  final BuildingColor color;
}

/// A searchable place on the campus.
class SearchPlace {
  const SearchPlace({
    required this.code,
    required this.name,
    required this.place,
    required this.dist,
    required this.lat,
    required this.lon,
  });

  final String code;
  final String name;
  final String place;
  final String dist;
  final double lat;
  final double lon;

  LatLng get position => LatLng(lat, lon);
}

/// Route mode — defined in models.dart; kept here for backward compatibility
/// with the repository layer. Use models.dart RouteMode in new code.
///
/// Route mode for navigation.
// enum RouteMode { walk, accessible, shortest }
