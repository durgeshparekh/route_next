import 'package:flutter/widgets.dart';
import 'navigation_action.dart';
import 'page_transition.dart';
import 'route_meta.dart';

/// Defines a single route in the application's route tree.
///
/// Each route maps a URL path pattern to a widget builder function.
/// Routes can be nested, guarded, wrapped in layouts, and annotated with metadata.
///
/// ## Path Patterns
///
/// Three segment types are supported:
/// - **Static**: `/about`, `/dashboard/settings`
/// - **Dynamic parameter**: `/users/:id`, `/posts/:slug`
/// - **Catch-all wildcard**: `/docs/*` (matches `/docs/a`, `/docs/a/b/c`, etc.)
///
/// ## Example
///
/// ```dart
/// RouteNextRoute(
///   path: '/users/:id',
///   meta: RouteMeta(title: 'User Profile'),
///   guard: (context) async {
///     final auth = await AuthService.isAuthenticated();
///     return auth
///         ? NavigationAction.allow()
///         : NavigationAction.redirect('/login');
///   },
///   builder: (context, params) => UserPage(id: params['id']!),
/// )
/// ```
@immutable
class RouteNextRoute {
  /// Creates a route definition.
  const RouteNextRoute({
    required this.path,
    required this.builder,
    this.children,
    this.guard,
    this.layout,
    this.transition,
    this.meta,
  });

  /// URL path pattern for this route.
  ///
  /// Child route paths are relative to their parent.
  /// Example: parent `/dashboard` + child `analytics` = `/dashboard/analytics`
  final String path;

  /// Widget builder called when this route is matched.
  ///
  /// `params` contains extracted dynamic segments and query parameters merged.
  /// For path `/users/:id` matched against `/users/42?tab=posts`:
  ///   `params = {'id': '42', 'tab': 'posts'}`
  final Widget Function(BuildContext context, Map<String, String> params)
      builder;

  /// Optional nested child routes.
  ///
  /// Child paths are relative to this route's path.
  final List<RouteNextRoute>? children;

  /// Optional async guard (middleware) that runs before the page renders.
  ///
  /// Must return a [NavigationAction]:
  /// - `NavigationAction.allow()` — proceed to render the page
  /// - `NavigationAction.redirect('/path')` — redirect to another route
  /// - `NavigationAction.deny()` — block navigation
  ///
  /// Guards execute in order from parent to child. If a parent guard redirects,
  /// child guards are not executed.
  final Future<NavigationAction> Function(BuildContext context)? guard;

  /// Optional layout wrapper for this route and all its children.
  ///
  /// Similar to Next.js `layout.tsx`. The `child` parameter is the matched
  /// page widget rendered inside the layout.
  ///
  /// Layouts nest automatically: if both parent and child routes have layouts,
  /// the parent layout wraps the child layout which wraps the page widget.
  ///
  /// ```dart
  /// layout: (context, child) => Scaffold(
  ///   appBar: AppBar(title: Text('My App')),
  ///   body: child,
  /// )
  /// ```
  final Widget Function(BuildContext context, Widget child)? layout;

  /// Optional page transition animation when navigating to this route.
  final RouteNextTransition? transition;

  /// Optional metadata for this route.
  ///
  /// On Flutter web, [RouteMeta.title] automatically updates `document.title`.
  final RouteMeta? meta;
}
