import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'navigation/route_guard.dart';
import 'providers/auth_provider.dart';
import 'providers/appointment_provider.dart';
import 'providers/queue_provider.dart';
import 'providers/admin_provider.dart';
import 'screens/admin/admin_main_navigation.dart';
import 'screens/auth/role_selection_screen.dart';
import 'screens/user/user_main_navigation.dart';
import 'services/connectivity_service.dart';
import 'services/firebase_service.dart';
import 'services/hive_service.dart';
import 'utils/app_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await HiveService.init();

  runApp(const SmartQueueApp());
}

class SmartQueueApp extends StatelessWidget {
  const SmartQueueApp({super.key});

  @override
  Widget build(BuildContext context) {
    final hiveService = HiveService();
    final firebaseService = FirebaseService();
    final connectivityService = ConnectivityService(
      firebaseService,
      hiveService,
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider()..checkAuthState(),
        ),
        ChangeNotifierProvider.value(value: connectivityService),
        ChangeNotifierProvider(
          create: (_) => AppointmentProvider(
            firebaseService,
            hiveService,
            connectivityService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => QueueProvider(firebaseService),
        ),
        ChangeNotifierProvider(
          create: (_) => AdminProvider(firebaseService, hiveService),
        ),
      ],
      child: MaterialApp(
        title: 'SmartQueue',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          textTheme: GoogleFonts.poppinsTextTheme(),
          scaffoldBackgroundColor: AppColors.background,
          appBarTheme: const AppBarTheme(
            elevation: 0,
            scrolledUnderElevation: 0,
          ),
          cardTheme: CardThemeData(
            elevation: 0,
            color: AppColors.cardBackground,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        home: RouteGuard(
          adminWidget: const AdminMainNavigation(),
          userWidget: const UserMainNavigation(),
          unauthWidget: const RoleSelectionScreen(),
        ),
      ),
    );
  }
}
