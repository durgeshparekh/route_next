import 'package:flutter/widgets.dart';
import 'navigation_action.dart';
import 'route_match.dart';

/// A global middleware function that runs before per-route guards on every navigation.
///
/// Receives the [BuildContext] and the [RouteMatch] being navigated to.
/// Returns a [NavigationAction] to allow, redirect, or deny.
///
/// Middleware runs in declaration order; the first non-allow result
/// short-circuits the chain (same behaviour as per-route guards).
///
/// Example:
/// ```dart
/// RouteNextApp(
///   middleware: [
///     // Analytics — always allow, just record the visit
///     (context, match) async {
///       Analytics.track(match.resolvedPath);
///       return NavigationAction.allow();
///     },
///     // Auth gate — redirect to /login for protected paths
///     (context, match) async {
///       final protected = match.resolvedPath.startsWith('/dashboard');
///       if (protected && !AuthService.isLoggedIn) {
///         return NavigationAction.redirect('/login');
///       }
///       return NavigationAction.allow();
///     },
///   ],
///   routes: [...],
/// )
/// ```
typedef RouteNextMiddleware = Future<NavigationAction> Function(
  BuildContext context,
  RouteMatch match,
);
