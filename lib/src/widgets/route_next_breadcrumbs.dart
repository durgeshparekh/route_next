import 'package:flutter/material.dart';
import '../core/route_match.dart';
import '../navigation/route_next.dart';

/// A breadcrumb trail that automatically reflects the current route hierarchy.
///
/// Uses [RouteMatch.matchChain] to derive each crumb. The label for each
/// crumb is taken from [RouteMeta.title] when available; otherwise the path
/// segment is capitalised and used as a fallback.
///
/// Example:
/// ```dart
/// RouteNextBreadcrumbs(
///   homeLabel: 'Home',
///   separator: Icon(Icons.chevron_right, size: 16),
/// )
/// ```
///
/// To customise individual crumb labels, supply a [labelBuilder]:
/// ```dart
/// RouteNextBreadcrumbs(
///   labelBuilder: (match) {
///     return switch (match.path) {
///       '/dashboard' => 'Dashboard',
///       '/dashboard/analytics' => 'Analytics',
///       _ => null, // fall back to default
///     };
///   },
/// )
/// ```
class RouteNextBreadcrumbs extends StatelessWidget {
  /// Creates a [RouteNextBreadcrumbs] widget.
  const RouteNextBreadcrumbs({
    super.key,
    this.separator,
    this.homeLabel = 'Home',
    this.labelBuilder,
    this.textStyle,
    this.activeTextStyle,
    this.padding,
  });

  /// Widget displayed between crumbs. Defaults to ` / `.
  final Widget? separator;

  /// Label used for the root `/` crumb. Defaults to `'Home'`.
  final String homeLabel;

  /// Optional callback to override the label for a specific [RouteMatch].
  ///
  /// Return `null` to fall back to [RouteMeta.title] or the path-segment label.
  final String? Function(RouteMatch match)? labelBuilder;

  /// Text style for non-active (ancestor) crumbs.
  final TextStyle? textStyle;

  /// Text style for the active (last) crumb.
  final TextStyle? activeTextStyle;

  /// Padding around the breadcrumb row. Defaults to `EdgeInsets.zero`.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final nav = RouteNext.of(context);
    final current = nav.current;
    if (current == null) return const SizedBox.shrink();

    // Build crumb list from the match chain.
    // matchChain includes ancestor route matches (parent → child order).
    final crumbs = <_Crumb>[];
    for (final match in current.matchChain) {
      crumbs.add(_Crumb(
        label: _labelFor(match),
        path: match.resolvedPath,
      ));
    }

    // If matchChain is empty (e.g., root '/'), add a single home crumb.
    if (crumbs.isEmpty) {
      crumbs.add(_Crumb(label: homeLabel, path: '/'));
    }

    final effectiveSeparator = separator ??
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text(
            '/',
            style: textStyle ??
                TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
          ),
        );

    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < crumbs.length; i++) ...[
            if (i > 0) effectiveSeparator,
            _CrumbWidget(
              crumb: crumbs[i],
              isLast: i == crumbs.length - 1,
              textStyle: textStyle,
              activeTextStyle: activeTextStyle,
              onTap: i == crumbs.length - 1 ? null : () => nav.push(crumbs[i].path),
            ),
          ],
        ],
      ),
    );
  }

  String _labelFor(RouteMatch match) {
    if (labelBuilder != null) {
      final custom = labelBuilder!(match);
      if (custom != null) return custom;
    }
    if (match.route.meta?.title != null) return match.route.meta!.title!;
    if (match.resolvedPath == '/') return homeLabel;
    // Derive from the last path segment: '/dashboard/analytics' → 'Analytics'
    final segment = match.resolvedPath.split('/').last;
    if (segment.isEmpty) return homeLabel;
    return segment[0].toUpperCase() + segment.substring(1).replaceAll('-', ' ');
  }
}

class _Crumb {
  const _Crumb({required this.label, required this.path});
  final String label;
  final String path;
}

class _CrumbWidget extends StatelessWidget {
  const _CrumbWidget({
    required this.crumb,
    required this.isLast,
    this.textStyle,
    this.activeTextStyle,
    this.onTap,
  });

  final _Crumb crumb;
  final bool isLast;
  final TextStyle? textStyle;
  final TextStyle? activeTextStyle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultActive = TextStyle(
      color: theme.colorScheme.onSurface,
      fontWeight: FontWeight.w600,
    );
    final defaultInactive = TextStyle(
      color: theme.colorScheme.primary,
    );

    final label = Text(
      crumb.label,
      style: isLast ? (activeTextStyle ?? defaultActive) : (textStyle ?? defaultInactive),
    );

    if (isLast) return label;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: label,
    );
  }
}
