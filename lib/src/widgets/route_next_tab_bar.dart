import 'package:flutter/material.dart';
import '../navigation/route_next.dart';
import 'nav_item.dart';

/// A URL-driven tab bar where the active tab is determined by the current route.
///
/// Unlike Flutter's native [TabBar], which requires a [TabController] and
/// manages state by index, [RouteNextTabBar] derives the active tab purely
/// from the router — so refreshing the page, deep-linking, or pressing the
/// browser back button all keep the correct tab selected automatically.
///
/// Each [NavItem] maps to a route path. When a tab is tapped, [RouteNext.push]
/// is called with [NavItem.path]. The tab is highlighted when
/// [RouteNext.isActive] returns `true` for its path.
///
/// Example:
/// ```dart
/// RouteNextTabBar(
///   tabs: [
///     NavItem(path: '/dashboard',           label: 'Overview'),
///     NavItem(path: '/dashboard/analytics', label: 'Analytics'),
///     NavItem(path: '/dashboard/reports',   label: 'Reports'),
///   ],
/// )
/// ```
///
/// To render the tab bar inside an [AppBar], use [RouteNextTabBar.asPreferredSize]:
/// ```dart
/// AppBar(
///   title: Text('Dashboard'),
///   bottom: RouteNextTabBar(tabs: [...]).asPreferredSize(),
/// )
/// ```
class RouteNextTabBar extends StatelessWidget {
  /// Creates a [RouteNextTabBar].
  const RouteNextTabBar({
    super.key,
    required this.tabs,
    this.isScrollable = false,
    this.activeColor,
    this.inactiveColor,
    this.indicatorColor,
    this.indicatorWeight = 2.0,
    this.labelStyle,
    this.unselectedLabelStyle,
    this.backgroundColor,
    this.tabHeight = 46.0,
    this.padding,
  });

  /// The tabs to display. Each [NavItem.path] is matched against the active route.
  final List<NavItem> tabs;

  /// Whether the tab bar scrolls horizontally. Defaults to `false`.
  final bool isScrollable;

  /// Color for the active tab label and indicator. Defaults to [ColorScheme.primary].
  final Color? activeColor;

  /// Color for inactive tab labels. Defaults to [ColorScheme.onSurfaceVariant].
  final Color? inactiveColor;

  /// Color of the active indicator line. Defaults to [activeColor].
  final Color? indicatorColor;

  /// Thickness of the active indicator line. Defaults to `2.0`.
  final double indicatorWeight;

  /// Text style for the active tab label.
  final TextStyle? labelStyle;

  /// Text style for inactive tab labels.
  final TextStyle? unselectedLabelStyle;

  /// Background color of the tab bar.
  final Color? backgroundColor;

  /// Height of each tab. Defaults to `46.0`.
  final double tabHeight;

  /// Padding around the tab bar.
  final EdgeInsetsGeometry? padding;

  /// Wraps this widget as a [PreferredSizeWidget] for use as [AppBar.bottom].
  PreferredSize asPreferredSize() => PreferredSize(
        preferredSize: Size.fromHeight(tabHeight),
        child: this,
      );

  @override
  Widget build(BuildContext context) {
    final nav = RouteNext.of(context);
    final theme = Theme.of(context);
    final effectiveActiveColor = activeColor ?? theme.colorScheme.primary;
    final effectiveInactiveColor =
        inactiveColor ?? theme.colorScheme.onSurfaceVariant;
    final effectiveIndicator = indicatorColor ?? effectiveActiveColor;

    final visibleTabs =
        tabs.where((t) => t.visible?.call(context) ?? true).toList();
    final activeIndex = visibleTabs.indexWhere((t) => nav.isActive(t.path));
    final hasActiveTab = activeIndex >= 0;

    // TabBar requires a TabController tied to an index. We create a
    // short-lived controller driven by the active route index. When the
    // route changes the widget rebuilds and the controller is recreated.
    return _RouteNextTabBarInner(
      tabs: visibleTabs,
      activeIndex: hasActiveTab ? activeIndex : 0,
      hasActiveTab: hasActiveTab,
      isScrollable: isScrollable,
      effectiveActiveColor: effectiveActiveColor,
      effectiveInactiveColor: effectiveInactiveColor,
      effectiveIndicator: effectiveIndicator,
      indicatorWeight: indicatorWeight,
      labelStyle: labelStyle,
      unselectedLabelStyle: unselectedLabelStyle,
      backgroundColor: backgroundColor,
      tabHeight: tabHeight,
      padding: padding,
      onTap: (i) => nav.push(visibleTabs[i].path),
    );
  }
}

class _RouteNextTabBarInner extends StatefulWidget {
  const _RouteNextTabBarInner({
    required this.tabs,
    required this.activeIndex,
    required this.hasActiveTab,
    required this.isScrollable,
    required this.effectiveActiveColor,
    required this.effectiveInactiveColor,
    required this.effectiveIndicator,
    required this.indicatorWeight,
    required this.labelStyle,
    required this.unselectedLabelStyle,
    required this.backgroundColor,
    required this.tabHeight,
    required this.padding,
    required this.onTap,
  });

  final List<NavItem> tabs;
  final int activeIndex;
  /// Whether any tab actually matches the current route.
  /// When false, the indicator is hidden so no tab appears falsely active.
  final bool hasActiveTab;
  final bool isScrollable;
  final Color effectiveActiveColor;
  final Color effectiveInactiveColor;
  final Color effectiveIndicator;
  final double indicatorWeight;
  final TextStyle? labelStyle;
  final TextStyle? unselectedLabelStyle;
  final Color? backgroundColor;
  final double tabHeight;
  final EdgeInsetsGeometry? padding;
  final void Function(int) onTap;

  @override
  State<_RouteNextTabBarInner> createState() => _RouteNextTabBarInnerState();
}

class _RouteNextTabBarInnerState extends State<_RouteNextTabBarInner>
    with SingleTickerProviderStateMixin {
  late TabController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TabController(
      length: widget.tabs.length,
      initialIndex: widget.activeIndex,
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(_RouteNextTabBarInner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tabs.length != oldWidget.tabs.length) {
      _controller.dispose();
      _controller = TabController(
        length: widget.tabs.length,
        initialIndex: widget.activeIndex,
        vsync: this,
      );
    } else if (widget.activeIndex != oldWidget.activeIndex) {
      // Sync controller to route-driven index without firing onTap.
      _controller.animateTo(widget.activeIndex);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: widget.backgroundColor ?? Colors.transparent,
      child: Padding(
        padding: widget.padding ?? EdgeInsets.zero,
        child: TabBar(
          controller: _controller,
          isScrollable: widget.isScrollable,
          // Hide indicator entirely when no tab matches the current URL,
          // so the first tab is never falsely highlighted.
          indicatorColor: widget.hasActiveTab
              ? widget.effectiveIndicator
              : Colors.transparent,
          indicatorWeight: widget.indicatorWeight,
          labelColor: widget.hasActiveTab
              ? widget.effectiveActiveColor
              : widget.effectiveInactiveColor,
          unselectedLabelColor: widget.effectiveInactiveColor,
          labelStyle: widget.labelStyle,
          unselectedLabelStyle: widget.unselectedLabelStyle,
          tabAlignment: widget.isScrollable ? TabAlignment.start : null,
          onTap: widget.onTap,
          tabs: widget.tabs.map((t) {
            return Tab(
              height: widget.tabHeight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (t.icon != null) ...[
                    Icon(t.icon, size: 16),
                    const SizedBox(width: 6),
                  ],
                  Text(t.label),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
