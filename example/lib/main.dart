import 'package:flutter/material.dart';
import 'package:route_next/route_next.dart';
import 'pages/home_page.dart';
import 'pages/about_page.dart';
import 'pages/contact_page.dart';
import 'pages/not_found_page.dart';
import 'pages/login_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/analytics_page.dart';
import 'pages/settings_page.dart';
import 'pages/user_detail_page.dart';

void main() {
  runApp(const MyApp());
}

// Simple mock auth service
class AuthService {
  static bool isAuthenticated = false;
  static Future<bool> check() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return isAuthenticated;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return RouteNextApp(
      title: 'RouteNext Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      urlStrategy: RouteNextUrlStrategy.path,
      notFound: (context) => const NotFoundPage(),
      routes: [
        // Public Route: Home
        RouteNextRoute(
          path: '/',
          meta: const RouteMeta(title: 'Home'),
          builder: (context, params) => const HomePage(),
        ),

        // Public Route: Login
        RouteNextRoute(
          path: '/login',
          meta: const RouteMeta(title: 'Login'),
          builder: (context, params) => const LoginPage(),
        ),

        // Authenticated Shell: Dashboard & Admin
        RouteNextRoute(
          path: '/app',
          guard: (context) async {
            final ok = await AuthService.check();
            if (!ok) return NavigationAction.redirect('/login');
            return NavigationAction.allow();
          },
          layout: (context, child) {
            final navItems = [
              const NavItem(path: '/app', icon: Icons.dashboard, label: 'Dashboard'),
              const NavItem(path: '/app/analytics', icon: Icons.analytics, label: 'Analytics'),
              const NavItem(path: '/app/settings', icon: Icons.settings, label: 'Settings'),
              const NavItem(path: '/', icon: Icons.logout, label: 'Exit to Home'),
            ];

            return RouteNextScaffold(
              navbar: RouteNextNavbar(
                title: const Text('RouteNext App'),
                items: const [],
                actions: [
                  IconButton(
                    icon: const Icon(Icons.logout),
                    onPressed: () {
                      AuthService.isAuthenticated = false;
                      RouteNext.of(context).replace('/login');
                    },
                  ),
                ],
              ),
              sidebar: RouteNextSidebar(items: navItems),
              drawer: RouteNextDrawer(items: navItems),
              child: child,
            );
          },
          builder: (context, params) => const DashboardPage(),
          children: [
            RouteNextRoute(
              path: 'analytics',
              meta: const RouteMeta(title: 'Analytics'),
              builder: (context, params) => const AnalyticsPage(),
            ),
            RouteNextRoute(
              path: 'settings',
              meta: const RouteMeta(title: 'Settings'),
              builder: (context, params) => const SettingsPage(),
            ),
          ],
        ),

        // Dynamic Route
        RouteNextRoute(
          path: '/users/:id',
          meta: const RouteMeta(title: 'User Profile'),
          builder: (context, params) => UserDetailPage(userId: params['id']!),
        ),

        // Static Marketing Pages
        RouteNextRoute(
          path: '/about',
          meta: const RouteMeta(title: 'About'),
          builder: (context, params) => const AboutPage(),
        ),
        RouteNextRoute(
          path: '/contact',
          meta: const RouteMeta(title: 'Contact'),
          builder: (context, params) => const ContactPage(),
        ),
      ],
    );
  }
}
