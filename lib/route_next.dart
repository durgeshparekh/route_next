/// RouteNext — Next.js-style navigation for Flutter web.
///
/// Provides URL-based routing where refresh, deep linking, and browser
/// navigation all work correctly out of the box.
///
/// ## Quick start
///
/// ```dart
/// void main() {
///   runApp(
///     RouteNextApp(
///       routes: [
///         RouteNextRoute(path: '/', builder: (_, __) => HomePage()),
///         RouteNextRoute(path: '/about', builder: (_, __) => AboutPage()),
///         RouteNextRoute(path: '/contact', builder: (_, __) => ContactPage()),
///       ],
///     ),
///   );
/// }
/// ```
library route_next;

// Core models
export 'src/core/route_next_route.dart';
export 'src/core/route_match.dart';
export 'src/core/route_meta.dart';
export 'src/core/navigation_action.dart';
export 'src/core/page_transition.dart';
export 'src/core/url_strategy.dart';
export 'src/core/route_registry.dart';
export 'src/core/route_next_middleware.dart';

// Widgets
export 'src/widgets/route_next_app.dart';
export 'src/widgets/route_next_scaffold.dart';
export 'src/widgets/route_next_drawer.dart';
export 'src/widgets/route_next_sidebar.dart';
export 'src/widgets/route_next_navbar.dart';
export 'src/widgets/nav_item.dart';
export 'src/widgets/route_next_breadcrumbs.dart';
export 'src/widgets/route_next_command_palette.dart';
export 'src/widgets/route_next_tab_bar.dart';

// Navigation API
export 'src/navigation/route_next.dart';
