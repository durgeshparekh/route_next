import 'package:flutter/material.dart';
import '../navigation/route_next.dart';
import 'nav_item.dart';

/// A navigation drawer that automatically stays in sync with the current URL.
///
/// Features:
/// - Highlights the active item based on the current URL path.
/// - Auto-expands parent groups when a child path is active.
/// - Navigates via [RouteNext.push()] on tap — URL-driven, so refresh works.
/// - Supports nested item groups (expandable sections).
/// - Supports conditional visibility per item.
///
/// Example:
/// ```dart
/// RouteNextDrawer(
///   header: DrawerHeader(child: Text('My App')),
///   items: [
///     NavItem(path: '/', icon: Icons.home, label: 'Home'),
///     NavItem(
///       path: '/dashboard',
///       icon: Icons.dashboard,
///       label: 'Dashboard',
///       children: [
///         NavItem(path: '/dashboard/analytics', label: 'Analytics'),
///       ],
///     ),
///   ],
/// )
/// ```
class RouteNextDrawer extends StatelessWidget {
  /// Creates a RouteNextDrawer.
  const RouteNextDrawer({
    super.key,
    required this.items,
    this.header,
    this.footer,
    this.width = 280.0,
    this.backgroundColor,
    this.activeColor,
    this.itemTextStyle,
    this.activeItemTextStyle,
    this.itemPadding,
  });

  /// Optional header widget displayed at the top of the drawer.
  final Widget? header;

  /// List of navigation items to display.
  final List<NavItem> items;

  /// Optional footer widget displayed at the bottom of the drawer.
  final Widget? footer;

  /// Width of the drawer. Defaults to 280.0.
  final double width;

  /// Background color of the drawer.
  final Color? backgroundColor;

  /// Color of the active item highlight.
  final Color? activeColor;

  /// Text style for item labels.
  final TextStyle? itemTextStyle;

  /// Text style for the active item label.
  final TextStyle? activeItemTextStyle;

  /// Padding around each item.
  final EdgeInsets? itemPadding;

  @override
  Widget build(BuildContext context) {
    final nav = RouteNext.of(context);
    final effectiveActiveColor =
        activeColor ?? Theme.of(context).colorScheme.primary;

    return Drawer(
      width: width,
      backgroundColor: backgroundColor,
      child: Column(
        children: [
          if (header != null) header!,
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: items
                  .where((item) => item.visible?.call(context) ?? true)
                  .map((item) =>
                      _buildItem(context, nav, item, effectiveActiveColor))
                  .toList(),
            ),
          ),
          if (footer != null) footer!,
        ],
      ),
    );
  }

  Widget _buildItem(
    BuildContext context,
    RouteNext nav,
    NavItem item,
    Color effectiveActiveColor,
  ) {
    if (item.children != null && item.children!.isNotEmpty) {
      final isGroupActive = nav.isActive(item.path);
      return ExpansionTile(
        initiallyExpanded: isGroupActive,
        leading: item.icon != null
            ? Icon(item.icon,
                color: isGroupActive ? effectiveActiveColor : null)
            : null,
        title: Text(
          item.label,
          style: isGroupActive
              ? (activeItemTextStyle ??
                  TextStyle(
                      color: effectiveActiveColor, fontWeight: FontWeight.w600))
              : itemTextStyle,
        ),
        children: item.children!
            .where((child) => child.visible?.call(context) ?? true)
            .map((child) =>
                _buildLeafItem(context, nav, child, effectiveActiveColor))
            .toList(),
      );
    }
    return _buildLeafItem(context, nav, item, effectiveActiveColor);
  }

  Widget _buildLeafItem(
    BuildContext context,
    RouteNext nav,
    NavItem item,
    Color effectiveActiveColor,
  ) {
    final isActive = nav.isActive(item.path, exact: true);
    final effectivePadding =
        itemPadding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 4);

    return ListTile(
      contentPadding: effectivePadding,
      leading: item.icon != null
          ? Icon(item.icon, color: isActive ? effectiveActiveColor : null)
          : null,
      title: Text(
        item.label,
        style: isActive
            ? (activeItemTextStyle ??
                TextStyle(
                    color: effectiveActiveColor, fontWeight: FontWeight.w600))
            : itemTextStyle,
      ),
      selected: isActive,
      selectedTileColor: effectiveActiveColor.withValues(alpha: 0.1),
      onTap: () {
        Navigator.of(context).pop(); // close drawer
        nav.push(item.path);
      },
    );
  }
}
