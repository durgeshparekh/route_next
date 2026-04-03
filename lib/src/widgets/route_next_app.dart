import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../core/route_match.dart';
import '../core/route_next_middleware.dart';
import '../core/route_next_route.dart';
import '../core/route_registry.dart';
import '../core/url_strategy.dart';
import '../navigator/route_next_delegate.dart';
import '../navigator/route_next_parser.dart';
import 'route_next_provider.dart';

/// The top-level widget for a RouteNext application.
///
/// Replaces `MaterialApp` and configures URL-based routing automatically.
/// Reads the browser URL on initialization and renders the matching route.
///
/// ## Simple usage
///
/// ```dart
/// void main() {
///   runApp(
///     RouteNextApp(
///       routes: [
///         RouteNextRoute(path: '/', builder: (_, __) => HomePage()),
///         RouteNextRoute(path: '/about', builder: (_, __) => AboutPage()),
///       ],
///     ),
///   );
/// }
/// ```
///
/// ## Advanced usage
///
/// ```dart
/// RouteNextApp(
///   title: 'My App',
///   theme: ThemeData.dark(),
///   urlStrategy: RouteNextUrlStrategy.path,
///   layout: (context, child) => AppShell(child: child),
///   notFound: (context) => Custom404Page(),
///   routes: [ ... ],
/// )
/// ```
class RouteNextApp extends StatefulWidget {
  /// Creates a RouteNextApp.
  const RouteNextApp({
    super.key,
    required this.routes,
    this.middleware = const [],
    this.layout,
    this.notFound,
    this.urlStrategy = RouteNextUrlStrategy.path,
    this.title = '',
    this.theme,
    this.darkTheme,
    this.themeMode,
    this.locale,
    this.localizationsDelegates,
    this.supportedLocales,
    this.navigatorKey,
    this.navigatorObservers,
    this.debugShowCheckedModeBanner = true,
  });

  /// List of top-level route definitions.
  final List<RouteNextRoute> routes;

  /// Global middleware pipeline. Runs before per-route guards on every navigation.
  ///
  /// Middleware executes in declaration order. The first non-allow result
  /// short-circuits the pipeline — per-route guards are skipped entirely.
  ///
  /// See [RouteNextMiddleware] for the function signature.
  final List<RouteNextMiddleware> middleware;

  /// Global layout wrapper applied to ALL routes.
  final Widget Function(BuildContext context, Widget child)? layout;

  /// Widget builder for 404 — displayed when no route matches the current URL.
  final Widget Function(BuildContext context)? notFound;

  /// URL strategy for the application. Defaults to [RouteNextUrlStrategy.path].
  final RouteNextUrlStrategy urlStrategy;

  /// Application title. Shown in the browser tab as a fallback.
  final String title;

  /// App theme.
  final ThemeData? theme;

  /// Dark theme.
  final ThemeData? darkTheme;

  /// Theme mode.
  final ThemeMode? themeMode;

  /// Locale.
  final Locale? locale;

  /// Localization delegates.
  final List<LocalizationsDelegate<dynamic>>? localizationsDelegates;

  /// Supported locales.
  final List<Locale>? supportedLocales;

  /// Navigator key.
  final GlobalKey<NavigatorState>? navigatorKey;

  /// Navigator observers.
  final List<NavigatorObserver>? navigatorObservers;

  /// Whether to show the debug banner.
  final bool debugShowCheckedModeBanner;

  @override
  State<RouteNextApp> createState() => _RouteNextAppState();
}

class _RouteNextAppState extends State<RouteNextApp> {
  late final RouteRegistry _registry;
  late final RouteNextParser _parser;
  late final RouteNextDelegate _delegate;
  late final GlobalKey<NavigatorState> _navigatorKey;
  late final PlatformRouteInformationProvider _routeInformationProvider;

  @override
  void initState() {
    super.initState();
    configureRouteNextUrlStrategy(widget.urlStrategy);

    _registry = RouteRegistry()..build(widget.routes);
    _navigatorKey = widget.navigatorKey ?? GlobalKey<NavigatorState>();

    // Pre-calculate initial match for zero-flicker startup
    final initialUri =
        kIsWeb ? _getInitialWebUri(widget.urlStrategy) : Uri.parse('/');
    final initialMatch = _registry.match(initialUri.path,
            query: Map<String, String>.from(initialUri.queryParameters)) ??
        RouteMatch.notFound(initialUri.path);

    _delegate = RouteNextDelegate(
      registry: _registry,
      navigatorKey: _navigatorKey,
      globalLayout: widget.layout,
      notFound: widget.notFound,
      appTitle: widget.title,
      middleware: widget.middleware,
      initialMatch: initialMatch,
    );
    _parser = RouteNextParser(registry: _registry);
    _routeInformationProvider = PlatformRouteInformationProvider(
      initialRouteInformation: RouteInformation(
        uri: initialUri,
      ),
    );
    _delegate.addListener(_handleRouteChanged);
  }

  @override
  void dispose() {
    _delegate.removeListener(_handleRouteChanged);
    super.dispose();
  }

  void _handleRouteChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  /// Calculates the initial Uri for the application on web.
  /// Handles both path-based and hash-based strategies.
  Uri _getInitialWebUri(RouteNextUrlStrategy strategy) {
    final uri = Uri.base;
    if (strategy == RouteNextUrlStrategy.path) {
      // We stripping origin to get a relative URI.
      // Uri.base.path already does this, but we also want query/fragment.
      return Uri(
        path: uri.path.isEmpty ? '/' : uri.path,
        queryParameters:
            uri.queryParameters.isNotEmpty ? uri.queryParameters : null,
      );
    } else {
      // In hash-based routing, the effective route is in the fragment.
      // E.g., http://localhost:8080/#/dashboard -> fragment is "/dashboard".
      final fragment = uri.fragment;
      if (fragment.isEmpty) return Uri(path: '/');

      // The fragment might be "/dashboard" or "dashboard".
      // We ensure it's parsed as a relative path.
      final pathPart = fragment.startsWith('/') ? fragment : '/$fragment';
      return Uri.parse(pathPart);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: widget.title,
      theme: widget.theme,
      darkTheme: widget.darkTheme,
      themeMode: widget.themeMode,
      locale: widget.locale,
      localizationsDelegates: widget.localizationsDelegates,
      supportedLocales: widget.supportedLocales ?? const [Locale('en', 'US')],
      debugShowCheckedModeBanner: widget.debugShowCheckedModeBanner,
      routerDelegate: _delegate,
      routeInformationParser: _parser,
      routeInformationProvider: _routeInformationProvider,
      builder: (context, child) => RouteNextProvider(
        delegate: _delegate,
        currentMatch: _delegate.currentConfiguration,
        child: child!,
      ),
    );
  }
}
