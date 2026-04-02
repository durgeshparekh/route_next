import 'package:flutter/widgets.dart';
import '../core/route_match.dart';
import '../navigator/route_next_delegate.dart';
import '../widgets/route_next_provider.dart';

/// Provides imperative navigation methods accessible from anywhere in the widget tree.
///
/// Access via `RouteNext.of(context)`.
///
/// Example:
/// ```dart
/// // Navigate to a new page
/// RouteNext.of(context).push('/dashboard/analytics');
///
/// // Navigate with query parameters
/// RouteNext.of(context).push('/users/42', query: {'tab': 'posts'});
///
/// // Replace current route (no browser history entry)
/// RouteNext.of(context).replace('/login');
///
/// // Go back
/// RouteNext.of(context).pop();
///
/// // Check active route (useful for nav highlighting)
/// final isOnDashboard = RouteNext.of(context).isActive('/dashboard');
/// ```
class RouteNext {
  /// @nodoc
  RouteNext({
    required RouteNextDelegate delegate,
    required RouteMatch? current,
  })  : _delegate = delegate,
        _current = current;

  final RouteNextDelegate _delegate;
  final RouteMatch? _current;

  /// Access the [RouteNext] instance from the widget tree.
  ///
  /// Throws [FlutterError] if no [RouteNextApp] ancestor is found.
  static RouteNext of(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<RouteNextProvider>();
    if (provider == null) {
      throw FlutterError(
        'RouteNext.of() called with a context that does not contain a '
        'RouteNextApp.\n'
        'Make sure you have a RouteNextApp ancestor in your widget tree.',
      );
    }
    return RouteNext(
      delegate: provider.delegate,
      current: provider.currentMatch,
    );
  }

  /// Navigate to [path], adding an entry to browser history.
  ///
  /// [query] is an optional map of query parameters appended to the URL.
  /// [extra] is an optional object passed to the new route (not part of URL).
  void push(String path, {Map<String, String>? query, Object? extra}) {
    _delegate.push(path, query: query, extra: extra);
  }

  /// Navigate to [path], replacing the current browser history entry.
  ///
  /// Use for redirects (e.g., after login) where pressing back should not
  /// return to the previous page.
  /// [extra] is an optional object passed to the new route (not part of URL).
  void replace(String path, {Map<String, String>? query, Object? extra}) {
    _delegate.replace(path, query: query, extra: extra);
  }

  /// Go back to the previous page in browser history.
  ///
  /// If there is no previous page, this is a no-op.
  void pop() {
    _delegate.pop();
  }

  /// Get the current matched route information.
  ///
  /// Returns null if no route is currently matched (404 state).
  RouteMatch? get current => _current;

  /// Check if a given path is currently active.
  ///
  /// Can check against both resolved paths (e.g., /users/1) or patterns (e.g., /users/:id).
  /// By default, uses hierarchy matching: returns true if the path exists in the current match chain.
  ///
  /// Set [exact] to true for exact pattern or resolved path matching only.
  bool isActive(String path, {bool exact = false}) {
    if (_current == null) return false;

    if (exact) {
      return _current!.path == path || _current!.resolvedPath == path;
    }

    // Check if the path (either pattern or resolved) exists anywhere in the match chain.
    // This is much more accurate for highlighting parent navigation items.
    return _current!.matchChain.any((m) => m.path == path || m.resolvedPath == path);
  }

  /// Get the current full resolved URL path.
  String get currentPath => _current?.resolvedPath ?? '/';
}
