import 'package:flutter/material.dart';
import '../core/navigation_action.dart';
import '../core/page_transition.dart';
import '../core/route_match.dart';
import '../core/route_registry.dart';
import 'guard_runner.dart';
import 'document_title_stub.dart'
    if (dart.library.html) 'document_title_web.dart';

/// Manages the navigation page stack and renders the current route.
///
/// Responsible for:
/// - Maintaining the current [RouteMatch] state.
/// - Running guard chains before rendering pages.
/// - Wrapping pages in their layout chains.
/// - Applying page transitions.
/// - Updating document.title from [RouteMeta].
/// - Handling the global notFound fallback.
class RouteNextDelegate extends RouterDelegate<RouteMatch>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<RouteMatch> {
  /// Creates the router delegate.
  RouteNextDelegate({
    required this.registry,
    required GlobalKey<NavigatorState> navigatorKey,
    this.globalLayout,
    this.notFound,
    this.appTitle = '',
  }) : _navigatorKey = navigatorKey;

  /// The route registry.
  final RouteRegistry registry;

  /// Optional global layout wrapper applied around all routes.
  final Widget Function(BuildContext context, Widget child)? globalLayout;

  /// Widget builder for the 404 page.
  final Widget Function(BuildContext context)? notFound;

  /// The application title (used as fallback document.title).
  final String appTitle;

  final GlobalKey<NavigatorState> _navigatorKey;

  RouteMatch? _currentMatch;

  @override
  GlobalKey<NavigatorState> get navigatorKey => _navigatorKey;

  @override
  RouteMatch? get currentConfiguration => _currentMatch;

  /// Navigate to a path by adding a history entry.
  void push(String path, {Map<String, String>? query}) {
    final match = registry.match(path, query: query ?? const {}) ??
        RouteMatch.notFound(path);
    setNewRoutePath(match);
  }

  /// Navigate to a path, replacing the current history entry.
  void replace(String path, {Map<String, String>? query}) {
    final match = registry.match(path, query: query ?? const {}) ??
        RouteMatch.notFound(path);
    _currentMatch = match;
    _updateDocumentTitle(match);
    notifyListeners();
  }

  /// Go back to the previous page.
  void pop() {
    navigatorKey.currentState?.pop();
  }

  static const int _maxRedirectMatchDepth = 5;

  @override
  Future<void> setNewRoutePath(RouteMatch configuration) async {
    return _handleNewPath(configuration, 0);
  }

  Future<void> _handleNewPath(RouteMatch configuration, int depth) async {
    if (depth > _maxRedirectMatchDepth) {
      FlutterError.reportError(FlutterErrorDetails(
        exception: Exception(
            'RouteNext: Infinite redirect loop detected at path: ${configuration.matchedPath}'),
        library: 'route_next',
        context: ErrorDescription('while handling route redirection'),
      ));
      _currentMatch = RouteMatch.notFound(configuration.matchedPath);
      notifyListeners();
      return;
    }

    if (configuration.isNotFound) {
      _currentMatch = configuration;
      notifyListeners();
      return;
    }

    final context = navigatorKey.currentContext;
    if (context == null || configuration.guardChain.isEmpty) {
      _currentMatch = configuration;
      _updateDocumentTitle(configuration);
      notifyListeners();
      return;
    }

    final action = await GuardRunner.run(context, configuration.guardChain);

    switch (action.type) {
      case NavigationActionType.allow:
        _currentMatch = configuration;
        _updateDocumentTitle(configuration);
        notifyListeners();

      case NavigationActionType.redirect:
        final redirectMatch = registry.match(action.redirectPath!) ??
            RouteMatch.notFound(action.redirectPath!);
        await _handleNewPath(redirectMatch, depth + 1);

      case NavigationActionType.deny:
        if (_currentMatch == null) {
          notifyListeners();
        }
    }
  }

  void _updateDocumentTitle(RouteMatch match) {
    final title =
        match.route.meta?.title ?? (appTitle.isNotEmpty ? appTitle : null);
    if (title != null) {
      setDocumentTitle(title);
    }
  }

  @override
  Widget build(BuildContext context) {
    final match = _currentMatch;

    Widget body;
    if (match == null || match.isNotFound) {
      body = notFound?.call(context) ?? _defaultNotFound(context);
    } else {
      body = match.route.builder(context, match.allParams);

      for (final layout in match.layoutChain.reversed) {
        body = layout(context, body);
      }

      if (globalLayout != null) {
        body = globalLayout!(context, body);
      }
    }

    return Navigator(
      key: navigatorKey,
      pages: [
        _buildPage(
          key: ValueKey(match?.matchedPath ?? '404'),
          child: body,
          transition: match?.route.transition,
        ),
      ],
      onDidRemovePage: (page) {},
    );
  }

  Page<dynamic> _buildPage({
    required LocalKey key,
    required Widget child,
    RouteNextTransition? transition,
  }) {
    if (transition == null || transition.type == TransitionType.none) {
      return MaterialPage<void>(key: key, child: child);
    }
    return _AnimatedPage(key: key, child: child, transition: transition);
  }

  Widget _defaultNotFound(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '404',
              style: TextStyle(fontSize: 72, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('Page Not Found'),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () => push('/'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedPage extends Page<void> {
  const _AnimatedPage({
    required super.key,
    required this.child,
    required this.transition,
  });

  final Widget child;
  final RouteNextTransition transition;

  @override
  Route<void> createRoute(BuildContext context) {
    return PageRouteBuilder<void>(
      settings: this,
      transitionDuration: transition.duration,
      pageBuilder: (_, __, ___) => child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: transition.curve,
        );
        switch (transition.type) {
          case TransitionType.fade:
            return FadeTransition(opacity: curved, child: child);
          case TransitionType.slideLeft:
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            );
          case TransitionType.slideRight:
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(-1.0, 0.0),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            );
          case TransitionType.slideUp:
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 1.0),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            );
          case TransitionType.scale:
            return ScaleTransition(scale: curved, child: child);
          case TransitionType.none:
            return child;
        }
      },
    );
  }
}
