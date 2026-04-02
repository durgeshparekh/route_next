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
  void push(String path, {Map<String, String>? query}) {
    _delegate.push(path, query: query);
  }

  /// Navigate to [path], replacing the current browser history entry.
  ///
  /// Use for redirects (e.g., after login) where pressing back should not
  /// return to the previous page.
  void replace(String path, {Map<String, String>? query}) {
    _delegate.replace(path, query: query);
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
  /// By default, uses prefix matching:
  ///   isActive('/dashboard') returns true when on '/dashboard/settings'
  ///
  /// Set [exact] to true for exact path matching only.
  bool isActive(String path, {bool exact = false}) {
    final currentPath = _current?.matchedPath;
    if (currentPath == null) return false;
    if (exact) return currentPath == path;
    return currentPath == path || currentPath.startsWith('$path/');
  }

  /// Get the current full URL path.
  String get currentPath => _current?.matchedPath ?? '/';
}
