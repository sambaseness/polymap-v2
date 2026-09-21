import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:latlong2/latlong.dart';

import '../data/campus_data.dart';
import '../data/models.dart';

/// App-wide state: theme, session, the route being planned, preferences, GPS.
///
/// Uses SharedPreferences for persistence across app restarts.
class AppState extends ChangeNotifier {
  // ---- Persistence ---------------------------------------------------------

  static const _keyThemeMode = 'themeMode';
  static const _keyLanguage = 'language';
  static const _keyIsGuest = 'isGuest';
  static const _keyUserEmail = 'userEmail';
  static const _keyFavorites = 'favorites';
  static const _keyAvoidStairs = 'avoidStairs';
  static const _keyArDoorLabels = 'arDoorLabels';
  static const _keyVoiceGuidance = 'voiceGuidance';
  static const _keyHighContrast = 'highContrast';
  static const _keyGpsTracking = 'gpsTracking';

  SharedPreferences? _prefs;
  bool _initialized = false;

  /// Initialize from persistent storage. Call once at app start.
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadFromPrefs();
    _initialized = true;
    notifyListeners();
  }

  void _loadFromPrefs() {
    final prefs = _prefs;
    if (prefs == null) return;

    // Theme mode
    final themeIndex = prefs.getInt(_keyThemeMode);
    if (themeIndex != null && themeIndex < ThemeMode.values.length) {
      _themeMode = ThemeMode.values[themeIndex];
    }

    // Language
    _language = prefs.getString(_keyLanguage) ?? 'Français';

    // Session
    _isGuest = prefs.getBool(_keyIsGuest) ?? true;
    _userEmail = prefs.getString(_keyUserEmail) ?? '';

    // Favorites
    final favList = prefs.getStringList(_keyFavorites);
    if (favList != null) {
      _favorites = Set<String>.from(favList);
    }

    // Preferences
    avoidStairs = prefs.getBool(_keyAvoidStairs) ?? true;
    arDoorLabels = prefs.getBool(_keyArDoorLabels) ?? true;
    voiceGuidance = prefs.getBool(_keyVoiceGuidance) ?? false;
    highContrast = prefs.getBool(_keyHighContrast) ?? false;
    gpsTrackingEnabled = prefs.getBool(_keyGpsTracking) ?? false;
  }

  Future<void> _savePrefs() async {
    final prefs = _prefs;
    if (prefs == null || !_initialized) return;

    await Future.wait([
      prefs.setInt(_keyThemeMode, _themeMode.index),
      prefs.setString(_keyLanguage, _language),
      prefs.setBool(_keyIsGuest, _isGuest),
      prefs.setString(_keyUserEmail, _userEmail),
      prefs.setStringList(_keyFavorites, _favorites.toList()),
      prefs.setBool(_keyAvoidStairs, avoidStairs),
      prefs.setBool(_keyArDoorLabels, arDoorLabels),
      prefs.setBool(_keyVoiceGuidance, voiceGuidance),
      prefs.setBool(_keyHighContrast, highContrast),
      prefs.setBool(_keyGpsTracking, gpsTrackingEnabled),
    ]);
  }

  // ---- Appearance --------------------------------------------------------

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;
  set themeMode(ThemeMode value) {
    if (value == _themeMode) return;
    _themeMode = value;
    notifyListeners();
    _savePrefs();
  }

  String _language = 'Français';
  String get language => _language;
  set language(String value) {
    _language = value;
    notifyListeners();
    _savePrefs();
  }

  // ---- Session ------------------------------------------------------------

  bool _isGuest = true;
  bool get isGuest => _isGuest;

  String _userEmail = '';
  String get userEmail => _userEmail;

  void signIn(String email) {
    _isGuest = false;
    _userEmail = email;
    notifyListeners();
    _savePrefs();
  }

  void continueAsGuest() {
    _isGuest = true;
    _userEmail = '';
    notifyListeners();
    _savePrefs();
  }

  // ---- Route planning ---------------------------------------------------

  int _routeIndex = 0;
  RouteMode _mode = RouteMode.walk;

  CampusRoute get route => CampusData.routes[_routeIndex];
  RouteMode get mode => _mode;
  ComputedRoute get computedRoute => route.compute(_mode);

  void openRoute(int index) {
    _routeIndex = index.clamp(0, CampusData.routes.length - 1);
    _mode = RouteMode.walk;
    notifyListeners();
  }

  set mode(RouteMode value) {
    if (value == _mode) return;
    _mode = value;
    notifyListeners();
  }

  // ---- Floor plan --------------------------------------------------------

  int _floor = 1;
  int get floor => _floor;
  set floor(int value) {
    if (value == _floor) return;
    _floor = value;
    notifyListeners();
  }

  // ---- Favourites --------------------------------------------------------

  Set<String> _favorites = <String>{
    for (final p in CampusData.favorites) p.code,
  };
  bool isFavorite(String code) => _favorites.contains(code);
  void toggleFavorite(String code) {
    if (!_favorites.remove(code)) _favorites.add(code);
    notifyListeners();
    _savePrefs();
  }

  // ---- Accessibility & AR preferences -----------------------------------

  bool avoidStairs = true;
  bool arDoorLabels = true;
  bool voiceGuidance = false;
  bool highContrast = false;

  void setPref(void Function() change) {
    change();
    notifyListeners();
    _savePrefs();
  }

  // ---- GPS Tracking -----------------------------------------------------

  bool _gpsTrackingEnabled = false;
  bool get gpsTrackingEnabled => _gpsTrackingEnabled;
  set gpsTrackingEnabled(bool value) {
    if (value == _gpsTrackingEnabled) return;
    _gpsTrackingEnabled = value;
    notifyListeners();
    _savePrefs();
  }

  /// Current user position from GPS.
  LatLng? _currentGpsPosition;
  LatLng? get currentGpsPosition => _currentGpsPosition;

  void setGpsPosition(LatLng position) {
    _currentGpsPosition = position;
    notifyListeners();
  }

  // ---- Tab shell ----------------------------------------------------------

  int _tab = 0;
  int get tab => _tab;
  set tab(int value) {
    if (value == _tab) return;
    _tab = value;
    notifyListeners();
  }

  // ---- Current position (from QR scan) -----------------------------------

  String? _currentNodeId;
  String? get currentNodeId => _currentNodeId;

  void setCurrentPosition(String nodeId) {
    _currentNodeId = nodeId;
    notifyListeners();
  }

  void clearCurrentPosition() {
    _currentNodeId = null;
    notifyListeners();
  }
}
