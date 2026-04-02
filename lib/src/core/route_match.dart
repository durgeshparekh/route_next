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
    required this.matchedPath,
    this.layoutChain = const [],
    this.guardChain = const [],
    this.isNotFound = false,
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
      matchedPath: path,
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

  /// The full path that was matched (without query string).
  final String matchedPath;

  /// The chain of layout wrappers to apply (from outermost parent to innermost).
  final List<Widget Function(BuildContext, Widget)> layoutChain;

  /// The chain of guards to execute (from outermost parent to innermost).
  final List<Future<NavigationAction> Function(BuildContext)> guardChain;

  /// Whether this match represents a "404 Not Found" state.
  final bool isNotFound;

  /// Merges path params and query params into a single map for convenience.
  ///
  /// Path params take priority over query params if keys collide.
  Map<String, String> get allParams => {...query, ...params};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RouteMatch &&
          runtimeType == other.runtimeType &&
          matchedPath == other.matchedPath &&
          params == other.params &&
          query == other.query;

  @override
  int get hashCode => matchedPath.hashCode ^ params.hashCode ^ query.hashCode;

  @override
  String toString() =>
      'RouteMatch(matchedPath: $matchedPath, params: $params, query: $query)';
}
