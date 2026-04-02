import 'package:flutter/widgets.dart';
import '../core/route_match.dart';
import '../navigator/route_next_delegate.dart';

/// InheritedWidget that exposes the RouteNextDelegate and current RouteMatch
/// to descendant widgets.
///
/// Placed above MaterialApp.router() by RouteNextApp.
class RouteNextProvider extends InheritedWidget {
  /// Creates a RouteNextProvider.
  const RouteNextProvider({
    super.key,
    required this.delegate,
    required this.currentMatch,
    required super.child,
  });

  /// The router delegate.
  final RouteNextDelegate delegate;

  /// The current matched route.
  final RouteMatch? currentMatch;

  @override
  bool updateShouldNotify(RouteNextProvider oldWidget) =>
      currentMatch != oldWidget.currentMatch;
}
