import 'dart:async';
import 'package:flutter/material.dart';

// --- RouteNext Core Models ---

enum NavigationActionType { allow, redirect, deny }

class NavigationAction {
  factory NavigationAction.allow() =>
      const NavigationAction._(NavigationActionType.allow);
  factory NavigationAction.redirect(String path) =>
      NavigationAction._(NavigationActionType.redirect, redirectPath: path);
  factory NavigationAction.deny() =>
      const NavigationAction._(NavigationActionType.deny);

  const NavigationAction._(this.type, {this.redirectPath});
  final NavigationActionType type;
  final String? redirectPath;
}

@immutable
class RouteMeta {
  const RouteMeta({this.title});
  final String? title;
}

@immutable
class RouteMatch {
  const RouteMatch({
    required this.route,
    this.params = const {},
    this.query = const {},
    required this.matchedPath,
    this.layoutChain = const [],
    this.guardChain = const [],
    this.isNotFound = false,
  });

  factory RouteMatch.notFound(String path) => RouteMatch(
        route: RouteNextRoute(
            path: path, builder: (_, __) => const SizedBox.shrink()),
        matchedPath: path,
        isNotFound: true,
      );

  final RouteNextRoute route;
  final Map<String, String> params;
  final Map<String, String> query;
  final String matchedPath;
  final List<Widget Function(BuildContext, Widget)> layoutChain;
  final List<Future<NavigationAction> Function(BuildContext)> guardChain;
  final bool isNotFound;

  Map<String, String> get allParams => {...params, ...query};
}

@immutable
class RouteNextRoute {
  const RouteNextRoute({
    required this.path,
    required this.builder,
    this.children,
    this.guard,
    this.layout,
    this.meta,
  });

  final String path;
  final Widget Function(BuildContext context, Map<String, String> params)
      builder;
  final List<RouteNextRoute>? children;
  final Future<NavigationAction> Function(BuildContext context)? guard;
  final Widget Function(BuildContext context, Widget child)? layout;
  final RouteMeta? meta;
}

// --- RouteNext Engine ---

class _TrieNode {
  final Map<String, _TrieNode> staticChildren = {};
  _TrieNode? paramChild;
  String? paramName;
  _TrieNode? wildcardChild;
  RouteNextRoute? route;
  String? fullPath;
  List<Widget Function(BuildContext, Widget)> layoutChain = [];
  List<Future<NavigationAction> Function(BuildContext)> guardChain = [];
}

class RouteRegistry {
  final _TrieNode _root = _TrieNode();
  final List<String> _registeredPaths = [];

  void build(List<RouteNextRoute> routes) {
    _insertRoutes(routes, '', [], []);
  }

  void _insertRoutes(
      List<RouteNextRoute> routes,
      String parentPath,
      List<Widget Function(BuildContext, Widget)> parentLayouts,
      List<Future<NavigationAction> Function(BuildContext)> parentGuards) {
    for (final route in routes) {
      final fullPath = _normalizePath('$parentPath/${route.path}');
      final layouts = [
        ...parentLayouts,
        if (route.layout != null) route.layout!
      ];
      final guards = [...parentGuards, if (route.guard != null) route.guard!];
      _insert(fullPath, route, layouts, guards);
      if (route.children != null) {
        _insertRoutes(route.children!, fullPath, layouts, guards);
      }
    }
  }

  void _insert(
      String path,
      RouteNextRoute route,
      List<Widget Function(BuildContext, Widget)> layoutChain,
      List<Future<NavigationAction> Function(BuildContext)> guardChain) {
    if (_registeredPaths.contains(path)) {
      throw ArgumentError('Duplicate path: $path');
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
        guardChain: node.guardChain);
  }

  _TrieNode? _matchNode(
      _TrieNode node, List<String> segments, int index, Map<String, String> params) {
    if (index == segments.length) return node.route != null ? node : null;
    final segment = segments[index];
    if (node.staticChildren.containsKey(segment)) {
      final result =
          _matchNode(node.staticChildren[segment]!, segments, index + 1, params);
      if (result != null) return result;
    }
    if (node.paramChild != null) {
      final savedParams = Map<String, String>.from(params);
      params[node.paramChild!.paramName!] = Uri.decodeComponent(segment);
      final result = _matchNode(node.paramChild!, segments, index + 1, params);
      if (result != null) return result;
      params
        ..clear()
        ..addAll(savedParams);
    }
    if (node.wildcardChild != null) {
      params['*'] = segments.sublist(index).map(Uri.decodeComponent).join('/');
      return node.wildcardChild!.route != null ? node.wildcardChild : null;
    }
    return null;
  }

  static String _normalizePath(String path) {
    if (path.isEmpty) return '/';
    var n = path.replaceAll(RegExp(r'/{2,}'), '/');
    if (!n.startsWith('/')) n = '/$n';
    if (n.length > 1 && n.endsWith('/')) {
      n = n.substring(0, n.length - 1);
    }
    return n;
  }

  static List<String> _splitPath(String path) {
    if (path == '/') return [];
    return path.split('/').where((s) => s.isNotEmpty).toList();
  }
}

// --- RouteNext Navigator ---

class RouteNextDelegate extends RouterDelegate<RouteMatch>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<RouteMatch> {
  RouteNextDelegate(
      {required this.registry,
      required GlobalKey<NavigatorState> navigatorKey,
      this.globalLayout,
      this.notFound})
      : _navigatorKey = navigatorKey;
  final RouteRegistry registry;
  final Widget Function(BuildContext, Widget)? globalLayout;
  final Widget Function(BuildContext)? notFound;
  final GlobalKey<NavigatorState> _navigatorKey;
  RouteMatch? _currentMatch;

  @override
  GlobalKey<NavigatorState> get navigatorKey => _navigatorKey;
  @override
  RouteMatch? get currentConfiguration => _currentMatch;

  void push(String path, {Map<String, String>? query}) {
    final m =
        registry.match(path, query: query ?? const {}) ?? RouteMatch.notFound(path);
    setNewRoutePath(m);
  }

  @override
  Future<void> setNewRoutePath(RouteMatch configuration) async {
    return _handleNewPath(configuration, 0);
  }

  Future<void> _handleNewPath(RouteMatch configuration, int depth) async {
    if (depth > 5) {
      _currentMatch = RouteMatch.notFound(configuration.matchedPath);
      notifyListeners();
      return;
    }
    if (configuration.isNotFound || configuration.guardChain.isEmpty) {
      _currentMatch = configuration;
      notifyListeners();
      return;
    }
    final context = navigatorKey.currentContext;
    if (context == null) {
      _currentMatch = configuration;
      notifyListeners();
      return;
    }
    for (final guard in configuration.guardChain) {
      final action = await guard(context);
      if (action.type == NavigationActionType.redirect) {
        final m = registry.match(action.redirectPath!) ??
            RouteMatch.notFound(action.redirectPath!);
        return _handleNewPath(m, depth + 1);
      } else if (action.type == NavigationActionType.deny) {
        return;
      }
    }
    _currentMatch = configuration;
    notifyListeners();
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
      pages: [MaterialPage(child: body)],
      onDidRemovePage: (page) {},
    );
  }

  Widget _defaultNotFound(BuildContext context) =>
      const Scaffold(body: Center(child: Text('404 Not Found')));
}

class RouteNextParser extends RouteInformationParser<RouteMatch> {
  RouteNextParser({required this.registry});
  final RouteRegistry registry;
  @override
  Future<RouteMatch> parseRouteInformation(
      RouteInformation routeInformation) async {
    final uri = routeInformation.uri;
    return registry.match(uri.path, query: uri.queryParameters) ??
        RouteMatch.notFound(uri.path);
  }

  @override
  RouteInformation? restoreRouteInformation(RouteMatch configuration) =>
      RouteInformation(
          uri: Uri.parse(configuration.matchedPath).replace(
              queryParameters:
                  configuration.query.isEmpty ? null : configuration.query));
}

// --- RouteNext Provider & App ---

class RouteNextProvider extends InheritedWidget {
  const RouteNextProvider(
      {super.key,
      required this.delegate,
      required this.currentMatch,
      required super.child});
  final RouteNextDelegate delegate;
  final RouteMatch? currentMatch;
  static RouteNextProvider of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<RouteNextProvider>()!;
  @override
  bool updateShouldNotify(RouteNextProvider oldWidget) =>
      currentMatch != oldWidget.currentMatch;
}

class RouteNext {
  static RouteNextDelegate of(BuildContext context) =>
      RouteNextProvider.of(context).delegate;
}

class RouteNextApp extends StatefulWidget {
  const RouteNextApp(
      {super.key,
      required this.routes,
      this.layout,
      this.notFound,
      this.title = '',
      this.theme});
  final List<RouteNextRoute> routes;
  final Widget Function(BuildContext, Widget)? layout;
  final Widget Function(BuildContext)? notFound;
  final String title;
  final ThemeData? theme;
  @override
  State<RouteNextApp> createState() => _RouteNextAppState();
}

class _RouteNextAppState extends State<RouteNextApp> {
  late final RouteRegistry _registry;
  late final RouteNextParser _parser;
  late final RouteNextDelegate _delegate;
  @override
  void initState() {
    super.initState();
    _registry = RouteRegistry()..build(widget.routes);
    _delegate = RouteNextDelegate(
        registry: _registry,
        navigatorKey: GlobalKey<NavigatorState>(),
        globalLayout: widget.layout,
        notFound: widget.notFound);
    _parser = RouteNextParser(registry: _registry);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: widget.title,
      theme: widget.theme,
      routerDelegate: _delegate,
      routeInformationParser: _parser,
      builder: (context, child) => RouteNextProvider(
          delegate: _delegate,
          currentMatch: _delegate.currentConfiguration,
          child: child!),
    );
  }
}

// --- Example Application ---

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return RouteNextApp(
      title: 'RouteNext Demo',
      theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true),
      // ignore: prefer_const_constructors
      layout: (context, child) => MyMainShell(child: child),
      routes: [
        RouteNextRoute(
            path: '/',
            builder: (context, params) => const Center(
                child: Text('Welcome to Home!', style: TextStyle(fontSize: 24)))),
        RouteNextRoute(
            path: '/about',
            builder: (context, params) => const Center(
                child: Text('This is the About page.',
                    style: TextStyle(fontSize: 24)))),
        RouteNextRoute(
            path: '/users/:id',
            builder: (context, params) => Center(
                child: Text('User Profile: ID ${params['id']}',
                    style: TextStyle(fontSize: 24)))),
        RouteNextRoute(
          path: '/admin',
          guard: (context) async {
            // Mock auth check
            await Future.delayed(const Duration(milliseconds: 500));
            return NavigationAction.redirect('/login');
          },
          builder: (context, params) => const Center(child: Text('Admin Dashboard')),
        ),
        RouteNextRoute(
            path: '/login',
            builder: (context, params) =>
                const Center(child: Text('Please Log In'))),
      ],
    );
  }
}

class MyMainShell extends StatelessWidget {
  const MyMainShell({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final activePath =
        RouteNextProvider.of(context).currentMatch?.matchedPath ?? '/';

    return Scaffold(
      appBar: AppBar(title: const Text('RouteNext App')),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(child: Text('Menu')),
            ListTile(
              title: const Text('Home'),
              selected: activePath == '/',
              onTap: () {
                RouteNext.of(context).push('/');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('About'),
              selected: activePath == '/about',
              onTap: () {
                RouteNext.of(context).push('/about');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Admin Panel'),
              onTap: () {
                RouteNext.of(context).push('/admin');
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: activePath == '/about' ? 1 : 0,
        onTap: (i) => RouteNext.of(context).push(i == 0 ? '/' : '/about'),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.info), label: 'Info'),
        ],
      ),
    );
  }
}
