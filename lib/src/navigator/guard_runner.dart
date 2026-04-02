import 'package:flutter/widgets.dart';
import '../core/navigation_action.dart';

/// Executes a chain of guard functions sequentially.
///
/// Guards are executed in order (parent to child). Execution stops at the
/// first guard that returns something other than [NavigationAction.allow()].
///
/// Example:
/// ```dart
/// final result = await GuardRunner.run(context, [
///   (ctx) async => NavigationAction.allow(),
///   (ctx) async => isLoggedIn ? NavigationAction.allow() : NavigationAction.redirect('/login'),
/// ]);
/// ```
class GuardRunner {
  GuardRunner._();

  /// Execute a list of guard functions in order.
  ///
  /// Returns [NavigationAction.allow()] if all guards pass or the list is empty.
  /// Returns the first non-allow action encountered.
  ///
  /// If a guard throws an exception, it is treated as [NavigationAction.deny()]
  /// and the error is logged to [FlutterError] (not rethrown).
  static Future<NavigationAction> run(
    BuildContext context,
    List<Future<NavigationAction> Function(BuildContext)> guards,
  ) async {
    for (final guard in guards) {
      try {
        final action = await guard(context);
        if (action.type != NavigationActionType.allow) {
          return action;
        }
      } catch (error, stackTrace) {
        FlutterError.reportError(FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'route_next',
          context: ErrorDescription('while running route guard'),
        ));
        return NavigationAction.deny();
      }
    }
    return NavigationAction.allow();
  }
}
