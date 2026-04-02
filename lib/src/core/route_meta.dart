import 'package:flutter/foundation.dart';

/// Metadata associated with a route.
///
/// On Flutter web, the [title] automatically updates the browser tab title
/// via `document.title`. The [description] is available for future
/// meta tag / SEO support.
///
/// Example:
/// ```dart
/// RouteNextRoute(
///   path: '/about',
///   meta: RouteMeta(title: 'About Us', description: 'Learn more about us'),
///   builder: (_, __) => AboutPage(),
/// )
/// ```
@immutable
class RouteMeta {
  /// Creates route metadata.
  const RouteMeta({this.title, this.description});

  /// Page title. Updates document.title on web when this route is active.
  final String? title;

  /// Page description. Reserved for future meta tag support.
  final String? description;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RouteMeta &&
          runtimeType == other.runtimeType &&
          title == other.title &&
          description == other.description;

  @override
  int get hashCode => title.hashCode ^ description.hashCode;

  @override
  String toString() => 'RouteMeta(title: $title, description: $description)';
}
