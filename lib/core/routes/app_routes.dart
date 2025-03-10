import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ev_charging_app/features/authentication/presentation/pages/splash_screen.dart';
import 'package:ev_charging_app/features/authentication/presentation/pages/sign_in_page.dart';
import 'package:ev_charging_app/features/authentication/presentation/pages/sign_up_page.dart';
import 'package:ev_charging_app/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:ev_charging_app/features/profile/presentation/pages/profile_page.dart';
import 'package:ev_charging_app/features/charging_stations/presentation/pages/map_page.dart';
import 'package:ev_charging_app/features/charging_stations/presentation/pages/qr_scanner_page.dart';
import 'package:ev_charging_app/features/charging_stations/presentation/pages/station_details_page.dart';
import 'package:ev_charging_app/features/assistant/presentation/pages/assistant_page.dart';
import 'package:ev_charging_app/core/services/station_service.dart';

import '../models/station.dart';

class AppRoutes {
  // Route names
  static const String splash = '/';
  static const String signIn = '/signin';
  static const String signUp = '/signup';
  static const String dashboard = '/dashboard';
  static const String profile = '/profile';
  static const String map = '/map';
  static const String qrScanner = '/qr-scanner';
  static const String assistant = '/assistant';
  static const String stationDetails = '/station-details';

  // Route map
  static Map<String, WidgetBuilder> getRoutes() {
    return {
      splash: (context) => const SplashScreen(),
      signIn: (context) => const SignInPage(),
      signUp: (context) => const SignUpPage(),
      dashboard: (context) => const DashboardPage(),
      profile: (context) => const ProfilePage(),
      map: (context) => const MapPage(stations: [], currentLocation: null),
      qrScanner: (context) => const QRScannerPage(),
      assistant: (context) => const AssistantPage(),
    };
  }

  // Generate route for dynamic routes (e.g., station details with parameters)
  static Route<dynamic>? generateRoute(RouteSettings settings) {
    if (settings.name?.startsWith(stationDetails) ?? false) {
      final stationId = settings.arguments as String?;

      if (stationId == null || stationId.isEmpty) return null;
      return MaterialPageRoute(
        builder: (context) {
          // Get StationService instance from provider
          final stationService =
              Provider.of<StationService>(context, listen: false);

          // Return FutureBuilder to handle async station loading
          return FutureBuilder(
            future: stationService.getStationDetails(stationId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError || !snapshot.hasData) {
                return Scaffold(
                  appBar: AppBar(
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  body: const Center(
                    child: Text('Station not found'),
                  ),
                );
              }

              return StationDetailsPage(
                station: Station.fromJson(
                  stationId,
                  snapshot.data as Map<String, dynamic>,
                ),
              );
            },
          );
        },
        settings: settings,
      );
    }
    return null;
  }
}
