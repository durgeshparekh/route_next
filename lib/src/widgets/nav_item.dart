import 'package:flutter/widgets.dart';

/// Defines a navigation item for use in [RouteNextDrawer], [RouteNextSidebar],
/// or [RouteNextNavbar].
///
/// Each item maps to a route path and is automatically highlighted when
/// its path (or a child's path) is active.
///
/// Example:
/// ```dart
/// NavItem(
///   path: '/dashboard',
///   icon: Icons.dashboard,
///   label: 'Dashboard',
///   children: [
///     NavItem(path: '/dashboard/analytics', label: 'Analytics'),
///     NavItem(path: '/dashboard/reports', label: 'Reports'),
///   ],
/// )
/// ```
@immutable
class NavItem {
  /// Creates a navigation item.
  const NavItem({
    required this.path,
    required this.label,
    this.icon,
    this.children,
    this.visible,
  });

  /// The route path this item navigates to on tap.
  final String path;

  /// Display label for the item.
  final String label;

  /// Optional leading icon.
  final IconData? icon;

  /// Optional nested child items.
  final List<NavItem>? children;

  /// Optional visibility condition.
  ///
  /// If provided, the item is only rendered when this returns true.
  final bool Function(BuildContext)? visible;
}
