import 'package:flutter/widgets.dart';
import 'navigation_action.dart';
import 'route_next_route.dart';

/// The result of matching a URL path against the route registry.
///
/// Contains the matched route definition, extracted parameters,
/// query string values, and the full matched path.
@immutable
class RouteMatch {
  /// Creates a route match result.
  const RouteMatch({
    required this.route,
    required this.params,
    required this.query,
    required this.path,
    required this.resolvedPath,
    this.layoutChain = const [],
    this.guardChain = const [],
    this.matchChain = const [],
    this.isNotFound = false,
    this.extra,
  });

  /// Creates a [RouteMatch] representing a "404 Not Found" state.
  factory RouteMatch.notFound(String path) {
    return RouteMatch(
      route: RouteNextRoute(
        path: path,
        builder: (context, params) => const SizedBox.shrink(),
      ),
      params: const {},
      query: const {},
      path: path,
      resolvedPath: path,
      isNotFound: true,
    );
  }

  /// The matched route definition.
  final RouteNextRoute route;

  /// Dynamic parameters extracted from the URL path.
  ///
  /// For route `/users/:id` matched against `/users/42`:
  ///   params = {'id': '42'}
  ///
  /// For catch-all route `/docs/*` matched against `/docs/a/b/c`:
  ///   params = {'*': 'a/b/c'}
  final Map<String, String> params;

  /// Query string parameters parsed from the URL.
  ///
  /// For URL `/users/42?tab=posts&sort=desc`:
  ///   query = {'tab': 'posts', 'sort': 'desc'}
  final Map<String, String> query;

  /// The route pattern that was matched (e.g., /users/:id).
  final String path;

  /// The full resolved path (e.g., /users/42).
  final String resolvedPath;

  /// Deprecated. Use [resolvedPath] instead.
  @Deprecated('Use resolvedPath instead. Will be removed in 2.0.0')
  String get matchedPath => resolvedPath;

  /// The chain of layout wrappers to apply (from outermost parent to innermost).
  final List<Widget Function(BuildContext, Widget)> layoutChain;

  /// The chain of guards to execute (from outermost parent to innermost).
  final List<Future<NavigationAction> Function(BuildContext)> guardChain;

  /// The chain of matches for each level of the route hierarchy.
  final List<RouteMatch> matchChain;

  /// Whether this match represents a "404 Not Found" state.
  final bool isNotFound;

  /// Optional extra data passed during navigation.
  final Object? extra;

  /// Merges path params and query params into a single map for convenience.
  ///
  /// Path params take priority over query params if keys collide.
  Map<String, String> get allParams => {...query, ...params};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RouteMatch &&
          runtimeType == other.runtimeType &&
          path == other.path &&
          resolvedPath == other.resolvedPath &&
          params == other.params &&
          query == other.query &&
          matchChain == other.matchChain;

  @override
  int get hashCode =>
      path.hashCode ^
      resolvedPath.hashCode ^
      params.hashCode ^
      query.hashCode ^
      matchChain.hashCode;

  @override
  String toString() =>
      'RouteMatch(path: $path, resolvedPath: $resolvedPath, params: $params, query: $query)';
}

/// Helper extension for parsing parameters from route maps.
extension ParamParsingExtension on Map<String, String> {
  /// Extract an integer parameter. Returns null if not found or invalid.
  int? getInt(String key) => int.tryParse(this[key] ?? '');

  /// Extract a double parameter. Returns null if not found or invalid.
  double? getDouble(String key) => double.tryParse(this[key] ?? '');

  /// Extract a boolean parameter. Returns true only if value is 'true'.
  bool getBool(String key) => this[key]?.toLowerCase() == 'true';

  /// Extract a parameter or throw an [ArgumentError] if missing.
  String require(String key) {
    final value = this[key];
    if (value == null) throw ArgumentError('Missing required parameter: $key');
    return value;
  }
}
