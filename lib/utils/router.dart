import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_providers.dart';
import '../screens/auth/auth_screen.dart';
import '../screens/landing_page.dart';
import '../screens/new_chart_page.dart';
import '../screens/saved_charts_page.dart';
import '../screens/settings_page.dart';
import '../screens/splash_screen.dart';
import '../widgets/app_drawer.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      // Get the current auth state
      final authState = ref.read(authStateChangesProvider);

      return authState.when(
        data: (user) {
          final isLoggedIn = user != null;
          final isOnAuthScreen = state.fullPath == '/auth';

          // If user is logged in but on auth screen, redirect to home
          if (isLoggedIn && isOnAuthScreen) {
            return '/home';
          }

          // Allow all other routes - no forced authentication
          return null;
        },
        loading: () {
          // While loading, allow current route or go to splash
          return state.fullPath == '/' ? null : '/';
        },
        error: (error, stack) {
          // On error, allow access but don't force redirect
          return null;
        },
      );
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      
      // Shell route with app bar and drawer for all main sections
      ShellRoute(
        builder: (context, state, child) {
          return Scaffold(
            body: CustomScrollView(
              slivers: [
                SliverAppBar(
                  title: const Text('Veda Jyoti'),
                  pinned: true,
                  floating: true,
                  expandedHeight: 50,
                  leading: Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.settings),
                      onPressed: () => context.go('/settings'),
                    ),
                  ],
                ),
                SliverToBoxAdapter(
                  child: child,
                ),
              ],
            ),
            drawer: const AppDrawer(),
          );
        },
        routes: [
          GoRoute(
            path: '/auth',
            builder: (context, state) => const AuthScreen(),
          ),
          GoRoute(
            path: '/home',
            builder: (context, state) => const LandingPage(),
          ),
          GoRoute(
            path: '/new-chart',
            builder: (context, state) => const NewChartPage(),
          ),
          GoRoute(
            path: '/saved-charts',
            builder: (context, state) => const SavedChartsPage(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsPage(),
          ),
        ],
      ),
    ],
  );
});

final routerDelegateProvider = Provider<GoRouterDelegate>((ref) {
  final router = ref.watch(routerProvider);
  return router.routerDelegate;
});

final routeInformationParserProvider = Provider<RouteInformationParser<Object>>((ref) {
  final router = ref.watch(routerProvider);
  return router.routeInformationParser;
});

final routeInformationProvider = Provider<RouteInformationProvider?>((ref) {
  final router = ref.watch(routerProvider);
  return router.routeInformationProvider;
});