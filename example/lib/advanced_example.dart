import 'package:flutter/material.dart';
import 'package:route_next/route_next.dart';
import 'pages/dashboard_page.dart';
import 'pages/analytics_page.dart';
import 'pages/settings_page.dart';
import 'pages/login_page.dart';
import 'pages/user_detail_page.dart';
import 'pages/not_found_page.dart';

/// Advanced example showing: auth guards, nested routes, sidebar layout.
///
/// Run this instead of main.dart by updating your entry point.
void main() {
  runApp(const AdvancedApp());
}

// Simulated auth state
bool _isLoggedIn = false;

final _navItems = [
  const NavItem(path: '/dashboard', icon: Icons.dashboard, label: 'Dashboard'),
  const NavItem(
    path: '/dashboard/analytics',
    icon: Icons.bar_chart,
    label: 'Analytics',
    children: [
      NavItem(path: '/dashboard/analytics', label: 'Overview'),
    ],
  ),
  const NavItem(
      path: '/dashboard/settings', icon: Icons.settings, label: 'Settings'),
];

class AdvancedApp extends StatelessWidget {
  const AdvancedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return RouteNextApp(
      title: 'SaaS Dashboard',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      notFound: (context) => const NotFoundPage(),
      routes: [
        RouteNextRoute(
          path: '/login',
          meta: const RouteMeta(title: 'Login'),
          builder: (context, params) => const LoginPage(),
        ),
        RouteNextRoute(
          path: '/dashboard',
          meta: const RouteMeta(title: 'Dashboard'),
          guard: (context) async {
            if (_isLoggedIn) return NavigationAction.allow();
            return NavigationAction.redirect('/login');
          },
          layout: (context, child) => RouteNextScaffold(
            sidebar: RouteNextSidebar(items: _navItems),
            drawer: RouteNextDrawer(items: _navItems),
            child: child,
          ),
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
            RouteNextRoute(
              path: 'users/:id',
              meta: const RouteMeta(title: 'User Detail'),
              builder: (context, params) =>
                  UserDetailPage(userId: params['id'] ?? 'unknown'),
            ),
          ],
        ),
      ],
    );
  }
}
