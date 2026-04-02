import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';

/// The type of animation to use when transitioning between pages.
enum TransitionType {
  /// Crossfade between pages.
  fade,

  /// New page slides in from the right, old page slides out to the left.
  slideLeft,

  /// New page slides in from the left, old page slides out to the right.
  slideRight,

  /// New page slides up from the bottom.
  slideUp,

  /// New page scales up from center.
  scale,

  /// No animation — instant switch.
  none,
}

/// Configuration for page transition animations.
///
/// Example:
/// ```dart
/// RouteNextRoute(
///   path: '/about',
///   transition: RouteNextTransition(
///     type: TransitionType.slideLeft,
///     duration: Duration(milliseconds: 400),
///   ),
///   builder: (_, __) => AboutPage(),
/// )
/// ```
@immutable
class RouteNextTransition {
  /// Creates a page transition configuration.
  const RouteNextTransition({
    this.type = TransitionType.fade,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
  });

  /// The type of transition animation.
  final TransitionType type;

  /// Duration of the transition animation.
  final Duration duration;

  /// Animation curve for the transition.
  final Curve curve;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RouteNextTransition &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          duration == other.duration &&
          curve == other.curve;

  @override
  int get hashCode => type.hashCode ^ duration.hashCode ^ curve.hashCode;

  @override
  String toString() =>
      'RouteNextTransition(type: $type, duration: $duration, curve: $curve)';
}
