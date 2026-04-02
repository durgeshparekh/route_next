import 'package:flutter/widgets.dart';
import '../core/route_match.dart';
import '../core/route_registry.dart';

/// Parses browser URL information into a [RouteMatch] and vice versa.
///
/// This is the bridge between the browser's URL bar and the route registry.
/// Navigator 2.0 calls this automatically when the URL changes (browser
/// back/forward, manual URL entry, refresh).
class RouteNextParser extends RouteInformationParser<RouteMatch> {
  /// Creates a parser backed by the given [registry].
  RouteNextParser({required this.registry});

  /// The route registry used for path matching.
  final RouteRegistry registry;

  /// Called by the framework when the URL changes.
  ///
  /// Parses the URL path and query string, runs it through the route registry,
  /// and returns a [RouteMatch] or a 404 match if no route matches.
  @override
  Future<RouteMatch> parseRouteInformation(
    RouteInformation routeInformation,
  ) async {
    final uri = routeInformation.uri;
    final path = uri.path.isEmpty ? '/' : uri.path;
    final query = uri.queryParameters;
    return registry.match(path, query: Map<String, String>.from(query)) ??
        RouteMatch.notFound(path);
  }

  /// Called by the framework to sync the browser URL bar with the current route.
  ///
  /// Converts a [RouteMatch] back into a [RouteInformation] containing
  /// the URL path and query string.
  @override
  RouteInformation? restoreRouteInformation(RouteMatch configuration) {
    if (configuration.isNotFound) {
      return RouteInformation(uri: Uri(path: configuration.resolvedPath));
    }
    final Uri uri;
    if (configuration.query.isNotEmpty) {
      uri = Uri(
        path: configuration.resolvedPath,
        queryParameters: configuration.query,
      );
    } else {
      uri = Uri(path: configuration.resolvedPath);
    }
    return RouteInformation(uri: uri);
  }
}
