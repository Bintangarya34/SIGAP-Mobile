import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants/colors.dart';
import 'core/providers/station_provider.dart';
import 'core/services/cache_service.dart';
import 'core/services/notification_service.dart';
import 'features/dashboard/presentation/pages/dashboard_page.dart';
import 'features/analitik/presentation/pages/analitik_page.dart';
import 'features/laporan/presentation/pages/lapor_banjir_page.dart';
import 'features/map/presentation/pages/map_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive Cache Storage for Offline-First capability
  await CacheService.init();

  // Initialize Local Push Notifications
  await NotificationService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => StationProvider()),
      ],
      child: const SigapApp(),
    ),
  );
}

class SigapApp extends StatelessWidget {
  const SigapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SIGAP Banjir Mobile',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: BrutalColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: BrutalColors.primary,
          primary: BrutalColors.primary,
          secondary: BrutalColors.secondary,
          background: BrutalColors.background,
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const DashboardPage(),
        '/analitik': (context) => const AnalitikPage(),
        '/lapor': (context) => const LaporBanjirPage(),
        '/map': (context) => const MapPage(),
      },
    );
  }
}
