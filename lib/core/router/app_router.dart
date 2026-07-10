import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/dashboard/presentation/doctor/doctor_dashboard_screen.dart';
import '../../features/dashboard/presentation/receptionist/receptionist_dashboard_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // 🟢 ADDED: Watch the live auth state. Any state transition triggers evaluation
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/login',
    debugLogDiagnostics: true,

    // 🟢 ADDED: Enterprise role-based navigation router intercept guard
    redirect: (context, state) {
      final isAuthenticated = authState.status == AuthStatus.authenticated;
      final isGoingToLogin = state.matchedLocation == '/login';

      // Guard Rule 1: If unauthenticated, clamp them strictly to the login terminal
      if (!isAuthenticated) {
        return isGoingToLogin ? null : '/login';
      }

      // Guard Rule 2: If already logged-in but hit /login, auto-bounce them back to work boards
      if (isGoingToLogin) {
        final roles = authState.user?.roles.map((r) => r.toLowerCase()).toList() ?? [];
        if (roles.contains('doctor')) {
          return '/doctor-dashboard';
        } else if (roles.contains('receptionist')) {
          return '/receptionist-dashboard';
        }
      }

      // Proceed normally for any explicit deeper matching links
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/doctor-dashboard',
        name: 'doctor_dashboard',
        builder: (context, state) => const DoctorDashboardScreen(),
      ),
      GoRoute(
        path: '/receptionist-dashboard',
        name: 'receptionist_dashboard',
        builder: (context, state) => const ReceptionistDashboardScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Route error: ${state.error}'),
      ),
    ),
  );
});