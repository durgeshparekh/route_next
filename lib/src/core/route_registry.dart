import 'package:flutter/widgets.dart';
import 'navigation_action.dart';
import 'route_match.dart';
import 'route_next_route.dart';

/// Internal trie node. Not part of the public API.
class _TrieNode {
  /// Children keyed by exact path segment string.
  final Map<String, _TrieNode> staticChildren = {};

  /// Child node for dynamic parameter segments (`:param`).
  _TrieNode? paramChild;

  /// The parameter name extracted from `:paramName`. e.g., 'id' from ':id'.
  String? paramName;

  /// Child node for wildcard catch-all segments (`*`).
  _TrieNode? wildcardChild;

  /// The route definition registered at this node, if this is a terminal node.
  RouteNextRoute? route;

  /// The full absolute path for the route at this node.
  String? fullPath;

  /// Layout chain collected from parent routes during tree building.
  List<Widget Function(BuildContext, Widget)> layoutChain = [];

  /// Guard chain collected from parent routes during tree building.
  List<Future<NavigationAction> Function(BuildContext)> guardChain = [];
}

/// Builds and maintains a trie (prefix tree) for efficient URL path matching.
///
/// The trie is constructed once from the route definitions and supports
/// O(n) matching where n is the number of path segments.
///
/// Matching priority (highest to lowest):
/// 1. Exact static segment match (e.g., `/users/settings`)
/// 2. Dynamic parameter match (e.g., `/users/:id`)
/// 3. Wildcard catch-all match (e.g., `/docs/*`)
class RouteRegistry {
  final _TrieNode _root = _TrieNode();
  final List<String> _registeredPaths = [];

  /// Build the trie from a list of route definitions.
  ///
  /// Recursively processes nested children, prepending parent paths.
  /// Throws [ArgumentError] if duplicate paths are found.
  void build(List<RouteNextRoute> routes) {
    _insertRoutes(routes, '', [], []);
  }

  void _insertRoutes(
    List<RouteNextRoute> routes,
    String parentPath,
    List<Widget Function(BuildContext, Widget)> parentLayouts,
    List<Future<NavigationAction> Function(BuildContext)> parentGuards,
  ) {
    for (final route in routes) {
      final fullPath = _normalizePath('$parentPath/${route.path}');

      final layouts = [
        ...parentLayouts,
        if (route.layout != null) route.layout!,
      ];
      final guards = [
        ...parentGuards,
        if (route.guard != null) route.guard!,
      ];

      _insert(fullPath, route, layouts, guards);

      if (route.children != null && route.children!.isNotEmpty) {
        _insertRoutes(route.children!, fullPath, layouts, guards);
      }
    }
  }

  /// Internal recursive route insertion.
  void _insert(
    String path,
    RouteNextRoute route,
    List<Widget Function(BuildContext, Widget)> layoutChain,
    List<Future<NavigationAction> Function(BuildContext)> guardChain,
  ) {
    if (_registeredPaths.contains(path)) {
      throw ArgumentError('Duplicate route path: $path');
    }
    _registeredPaths.add(path);

    final segments = _splitPath(path);
    var node = _root;

    for (final segment in segments) {
      if (segment == '*') {
        node.wildcardChild ??= _TrieNode();
        node = node.wildcardChild!;
      } else if (segment.startsWith(':')) {
        node.paramChild ??= _TrieNode();
        node.paramChild!.paramName = segment.substring(1);
        node = node.paramChild!;
      } else {
        node.staticChildren[segment] ??= _TrieNode();
        node = node.staticChildren[segment]!;
      }
    }

    node.route = route;
    node.fullPath = path;
    node.layoutChain = layoutChain;
    node.guardChain = guardChain;
  }

  /// Match a URL path string to a registered route.
  ///
  /// Returns a [RouteMatch] with the matched route and extracted parameters,
  /// or `null` if no route matches the given path.
  ///
  /// [path] should be the path portion of the URL (no query string).
  RouteMatch? match(String path, {Map<String, String> query = const {}}) {
    final normalized = _normalizePath(path);
    final segments = _splitPath(normalized);
    final params = <String, String>{};

    final node = _matchNode(_root, segments, 0, params);
    if (node == null || node.route == null) return null;

    return RouteMatch(
      route: node.route!,
      params: Map.unmodifiable(params),
      query: Map.unmodifiable(query),
      matchedPath: node.fullPath ?? normalized,
      layoutChain: node.layoutChain,
      guardChain: node.guardChain,
    );
  }

  _TrieNode? _matchNode(
    _TrieNode node,
    List<String> segments,
    int index,
    Map<String, String> params,
  ) {
    if (index == segments.length) {
      return node.route != null ? node : null;
    }

    final segment = segments[index];

    // Priority 1: static match
    if (node.staticChildren.containsKey(segment)) {
      final result = _matchNode(
        node.staticChildren[segment]!,
        segments,
        index + 1,
        params,
      );
      if (result != null) return result;
    }

    // Priority 2: dynamic param match
    if (node.paramChild != null) {
      final savedParams = Map<String, String>.from(params);
      params[node.paramChild!.paramName!] = Uri.decodeComponent(segment);
      final result = _matchNode(node.paramChild!, segments, index + 1, params);
      if (result != null) return result;
      params
        ..clear()
        ..addAll(savedParams);
    }

    // Priority 3: wildcard catch-all
    if (node.wildcardChild != null) {
      params['*'] = segments.sublist(index).map(Uri.decodeComponent).join('/');
      return node.wildcardChild!.route != null ? node.wildcardChild : null;
    }

    return null;
  }

  /// Get the list of all registered route paths (for debugging/logging).
  List<String> get registeredPaths => List.unmodifiable(_registeredPaths);

  /// Normalize a path: ensure leading slash, strip trailing slash, collapse doubles.
  static String _normalizePath(String path) {
    if (path.isEmpty) return '/';
    var normalized = path.replaceAll(RegExp(r'/{2,}'), '/');
    if (!normalized.startsWith('/')) normalized = '/$normalized';
    if (normalized.length > 1 && normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    return normalized;
  }

  /// Split path into segments, filtering empty strings.
  static List<String> _splitPath(String path) {
    if (path == '/') return [];
    return path.split('/').where((s) => s.isNotEmpty).toList();
  }
}
