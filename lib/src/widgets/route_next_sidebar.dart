import 'package:flutter/material.dart';
import '../navigation/route_next.dart';
import 'nav_item.dart';

/// A permanent sidebar navigation panel.
///
/// Unlike [RouteNextDrawer], which overlays the content, the sidebar
/// is always visible alongside the page content (typically on desktop widths).
///
/// Has the same auto-syncing behavior as [RouteNextDrawer].
///
/// Example:
/// ```dart
/// RouteNextSidebar(
///   header: Padding(
///     padding: EdgeInsets.all(16),
///     child: Text('My App', style: TextStyle(fontSize: 20)),
///   ),
///   items: [
///     NavItem(path: '/', icon: Icons.home, label: 'Home'),
///     NavItem(path: '/about', icon: Icons.info, label: 'About'),
///   ],
/// )
/// ```
class RouteNextSidebar extends StatelessWidget {
  /// Creates a RouteNextSidebar.
  const RouteNextSidebar({
    super.key,
    required this.items,
    this.header,
    this.footer,
    this.width = 260.0,
    this.backgroundColor,
    this.activeColor,
    this.itemTextStyle,
    this.activeItemTextStyle,
    this.itemPadding,
    this.decoration,
  });

  /// Optional header widget.
  final Widget? header;

  /// Navigation items.
  final List<NavItem> items;

  /// Optional footer widget.
  final Widget? footer;

  /// Width of the sidebar. Defaults to 260.0.
  final double width;

  /// Background color.
  final Color? backgroundColor;

  /// Color of the active item highlight.
  final Color? activeColor;

  /// Text style for item labels.
  final TextStyle? itemTextStyle;

  /// Text style for the active item label.
  final TextStyle? activeItemTextStyle;

  /// Padding around each item.
  final EdgeInsets? itemPadding;

  /// Optional decoration for the sidebar container.
  final BoxDecoration? decoration;

  @override
  Widget build(BuildContext context) {
    final nav = RouteNext.of(context);
    final effectiveActiveColor =
        activeColor ?? Theme.of(context).colorScheme.primary;
    final effectiveBg =
        backgroundColor ?? Theme.of(context).colorScheme.surface;

    return Container(
      width: width,
      decoration: decoration ??
          BoxDecoration(
            color: effectiveBg,
            border: Border(
              right: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 1,
              ),
            ),
          ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (header != null) header!,
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
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
      onTap: () => nav.push(item.path),
    );
  }
}
