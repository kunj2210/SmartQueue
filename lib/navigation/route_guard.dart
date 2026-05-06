import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/splash_screen.dart';
import '../screens/auth/role_selection_screen.dart';
import '../screens/user/user_main_navigation.dart';
import '../screens/admin/admin_main_navigation.dart';

class RouteGuard extends StatelessWidget {
  final Widget adminWidget;
  final Widget userWidget;
  final Widget unauthWidget;

  const RouteGuard({
    required this.adminWidget,
    required this.userWidget,
    required this.unauthWidget,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        if (authProvider.isLoading) {
          return const SplashScreen();
        }
        if (!authProvider.isLoggedIn) {
          return unauthWidget;
        }
        if (authProvider.isAdmin) {
          return adminWidget;
        }
        return userWidget;
      },
    );
  }
}
