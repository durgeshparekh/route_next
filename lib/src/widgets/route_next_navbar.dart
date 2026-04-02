import 'package:flutter/material.dart';
import '../navigation/route_next.dart';
import 'nav_item.dart';

/// A top navigation bar that auto-syncs with the current URL.
///
/// Renders items horizontally. Active item is highlighted.
/// Best for simple top-level navigation on static sites.
///
/// Example:
/// ```dart
/// RouteNextNavbar(
///   title: Text('My Site'),
///   items: [
///     NavItem(path: '/', label: 'Home'),
///     NavItem(path: '/about', label: 'About'),
///     NavItem(path: '/contact', label: 'Contact'),
///   ],
/// )
/// ```
class RouteNextNavbar extends StatelessWidget implements PreferredSizeWidget {
  /// Creates a RouteNextNavbar.
  const RouteNextNavbar({
    super.key,
    required this.items,
    this.title,
    this.actions,
    this.backgroundColor,
    this.activeColor,
    this.itemTextStyle,
    this.activeItemTextStyle,
    this.height = 56.0,
  });

  /// Optional title widget.
  final Widget? title;

  /// Navigation items displayed horizontally.
  final List<NavItem> items;

  /// Optional trailing action widgets.
  final List<Widget>? actions;

  /// Background color.
  final Color? backgroundColor;

  /// Color of the active item.
  final Color? activeColor;

  /// Text style for item labels.
  final TextStyle? itemTextStyle;

  /// Text style for the active item label.
  final TextStyle? activeItemTextStyle;

  /// Height of the navbar. Defaults to 56.0.
  final double height;

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final nav = RouteNext.of(context);
    final effectiveActiveColor =
        activeColor ?? Theme.of(context).colorScheme.primary;

    return AppBar(
      backgroundColor: backgroundColor,
      title: title,
      toolbarHeight: height,
      actions: [
        ...items
            .where((item) => item.visible?.call(context) ?? true)
            .map((item) {
          final isActive =
              nav.isActive(item.path, exact: item.children == null);
          return TextButton(
            onPressed: () => nav.push(item.path),
            style: TextButton.styleFrom(
              foregroundColor: isActive ? effectiveActiveColor : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (item.icon != null) ...[
                  Icon(item.icon, size: 18),
                  const SizedBox(width: 4),
                ],
                Text(
                  item.label,
                  style: isActive
                      ? (activeItemTextStyle ??
                          TextStyle(
                              color: effectiveActiveColor,
                              fontWeight: FontWeight.w600))
                      : itemTextStyle,
                ),
              ],
            ),
          );
        }),
        if (actions != null) ...actions!,
      ],
    );
  }
}
