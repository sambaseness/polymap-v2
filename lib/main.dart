import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'state/app_state.dart';
import 'services/location_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ),
  );
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Initialize app state with persistence
  final appState = AppState();
  await appState.init();

  // Initialize GPS location services
  await LocationService.initialize();

  runApp(
    ChangeNotifierProvider<AppState>.value(
      value: appState,
      child: const PolyMapApp(),
    ),
  );
}
