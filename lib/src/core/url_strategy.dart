import 'package:flutter/foundation.dart';
import 'package:flutter_web_plugins/url_strategy.dart'
    if (dart.library.io) 'url_strategy_io_stub.dart';

/// URL strategy options for the application.
enum RouteNextUrlStrategy {
  /// Clean URLs: `/dashboard/settings`
  ///
  /// Requires server configuration to serve index.html for all paths.
  /// Recommended for production apps with proper hosting setup.
  path,

  /// Hash-based URLs: `/#/dashboard/settings`
  ///
  /// Works without any server configuration. The hash fragment
  /// is never sent to the server, so any static file server works.
  /// Recommended for simple deployments or GitHub Pages.
  hash,
}

/// Configure the URL strategy for the application.
///
/// Must be called before [runApp] and before any [MaterialApp] is created.
/// Called internally by [RouteNextApp] in its [State.initState].
///
/// On non-web platforms, this is a no-op.
void configureRouteNextUrlStrategy(RouteNextUrlStrategy strategy) {
  if (!kIsWeb) return;
  try {
    if (strategy == RouteNextUrlStrategy.path) {
      usePathUrlStrategy();
    }
    // Hash strategy is the default; no action needed.
  } catch (_) {
    // Silently ignore on platforms that don't support URL strategies.
  }
}
