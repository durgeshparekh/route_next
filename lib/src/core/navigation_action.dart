import 'package:flutter/foundation.dart';

/// The type of action a route guard returns.
enum NavigationActionType {
  /// Allow navigation to proceed.
  allow,

  /// Redirect to a different path.
  redirect,

  /// Deny navigation entirely.
  deny,
}

/// Represents the result of a route guard evaluation.
///
/// Used as the return type of [RouteNextRoute.guard] functions to control
/// whether navigation should proceed, redirect, or be denied.
///
/// Example:
/// ```dart
/// guard: (context) async {
///   final isLoggedIn = await AuthService.isAuthenticated();
///   if (isLoggedIn) return NavigationAction.allow();
///   return NavigationAction.redirect('/login');
/// }
/// ```
@immutable
class NavigationAction {
  const NavigationAction._(this.type, [this.redirectPath]);

  /// Allow navigation to proceed to the requested route.
  factory NavigationAction.allow() =>
      const NavigationAction._(NavigationActionType.allow);

  /// Redirect navigation to a different route.
  ///
  /// [path] is the absolute path to redirect to. Example: '/login'
  /// The redirect target goes through its own route matching and guard checks.
  factory NavigationAction.redirect(String path) =>
      NavigationAction._(NavigationActionType.redirect, path);

  /// Deny navigation. The router stays on the current page or shows the 404 page.
  factory NavigationAction.deny() =>
      const NavigationAction._(NavigationActionType.deny);

  /// The type of this navigation action.
  final NavigationActionType type;

  /// The path to redirect to. Only set when [type] is [NavigationActionType.redirect].
  final String? redirectPath;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NavigationAction &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          redirectPath == other.redirectPath;

  @override
  int get hashCode => type.hashCode ^ redirectPath.hashCode;

  @override
  String toString() =>
      'NavigationAction(type: $type, redirectPath: $redirectPath)';
}
