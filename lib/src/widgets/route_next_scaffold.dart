import 'package:flutter/material.dart';
import 'route_next_drawer.dart';
import 'route_next_navbar.dart';
import 'route_next_sidebar.dart';

/// A responsive shell layout combining navigation components with page content.
///
/// On wide screens (>= [sidebarBreakpoint]), shows a permanent [sidebar].
/// On narrow screens, uses a [drawer] that opens via hamburger menu.
///
/// Example:
/// ```dart
/// RouteNextRoute(
///   path: '/dashboard',
///   layout: (context, child) => RouteNextScaffold(
///     sidebar: RouteNextSidebar(items: navItems),
///     drawer: RouteNextDrawer(items: navItems),
///     navbar: RouteNextNavbar(title: Text('Dashboard'), items: []),
///     child: child,
///   ),
///   builder: (_, __) => DashboardHome(),
/// )
/// ```
class RouteNextScaffold extends StatelessWidget {
  /// Creates a RouteNextScaffold.
  const RouteNextScaffold({
    super.key,
    required this.child,
    this.drawer,
    this.sidebar,
    this.navbar,
    this.footer,
    this.sidebarBreakpoint = 768.0,
    this.backgroundColor,
  });

  /// The page content to display in the body area.
  final Widget child;

  /// Drawer for mobile/narrow screens.
  final RouteNextDrawer? drawer;

  /// Permanent sidebar for desktop/wide screens.
  final RouteNextSidebar? sidebar;

  /// Top navigation bar.
  final RouteNextNavbar? navbar;

  /// Footer widget displayed below the body.
  final Widget? footer;

  /// Width breakpoint at which to switch from drawer to sidebar.
  /// Defaults to 768.0.
  final double sidebarBreakpoint;

  /// Background color for the body area.
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= sidebarBreakpoint;

        final Widget body = footer != null
            ? Column(
                children: [
                  Expanded(child: child),
                  footer!,
                ],
              )
            : child;

        if (isWide && sidebar != null) {
          // Desktop: permanent sidebar + body side by side
          return Scaffold(
            backgroundColor: backgroundColor,
            appBar: navbar,
            body: Row(
              children: [
                sidebar!,
                Expanded(child: body),
              ],
            ),
          );
        } else {
          // Mobile: scaffold with optional drawer
          return Scaffold(
            backgroundColor: backgroundColor,
            appBar: navbar,
            drawer: drawer,
            body: body,
          );
        }
      },
    );
  }
}
