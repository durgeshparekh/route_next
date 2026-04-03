# RouteNext

**Next.js-style navigation for Flutter web.**

RouteNext provides URL-based routing where browser refresh, deep linking, and back/forward navigation just work out of the box. Designed for the same seamless development experience as modern web frameworks — nested layouts, composable middleware, and a full set of URL-aware UI components.

[![pub package](https://img.shields.io/pub/v/route_next.svg)](https://pub.dev/packages/route_next)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-%3E%3D3.27.0-blue)](https://flutter.dev)

---

## Features

- **Clean URLs** — path-based (`/about`) or hash-based (`/#/about`) strategies.
- **Deep Linking** — any URL works on initial launch and browser refresh.
- **Global Middleware** — composable pipeline that runs before every navigation. Perfect for analytics, auth gates, and feature flags.
- **Per-Route Guards** — async functions that can allow, redirect, or deny navigation to individual routes.
- **Nested Layouts** — Next.js-style layouts that wrap page content and persist state across child routes.
- **Dynamic Params & Wildcards** — `/users/:id`, `/docs/*`.
- **Page Transitions** — fade, slide, and scale animations built in.
- **Breadcrumbs** — auto-generated trail from the live route hierarchy.
- **Command Palette** — ⌘K / Ctrl+K search overlay for quick navigation and actions.
- **Tab Bar** — URL-driven tabs where the active tab always reflects the current route.
- **Auto-syncing UI** — `Sidebar`, `Navbar`, and `Drawer` that highlight the active link automatically.

---

## Getting Started

Add `route_next` to your `pubspec.yaml`:

```yaml
dependencies:
  route_next: ^1.2.1
```

Then replace `MaterialApp` with `RouteNextApp`:

```dart
import 'package:flutter/material.dart';
import 'package:route_next/route_next.dart';

void main() {
  runApp(
    RouteNextApp(
      title: 'My App',
      routes: [
        RouteNextRoute(path: '/',      builder: (_, __) => HomePage()),
        RouteNextRoute(path: '/about', builder: (_, __) => AboutPage()),
        RouteNextRoute(
          path: '/users/:id',
          builder: (_, params) => UserPage(id: params['id']!),
        ),
      ],
    ),
  );
}
```

---

## Navigation API

Access the router from anywhere in the widget tree via `RouteNext.of(context)`:

```dart
// Push a new route (adds a browser history entry)
RouteNext.of(context).push('/dashboard');

// Push with query parameters  →  /search?q=flutter
RouteNext.of(context).push('/search', query: {'q': 'flutter'});

// Push with in-memory extra data (not visible in the URL)
RouteNext.of(context).push('/checkout', extra: cartData);

// Replace the current history entry (no back button)
RouteNext.of(context).replace('/login');

// Go back
RouteNext.of(context).pop();

// Read the current route
final match = RouteNext.of(context).current; // RouteMatch?

// Check if a path is active (useful for nav highlighting)
final onDashboard = RouteNext.of(context).isActive('/dashboard');
```

---

## Nested Routes & Layouts

Wrap a group of routes in a shared layout. The layout persists across child navigations — scroll position, focus, and animation state are all preserved.

```dart
RouteNextApp(
  routes: [
    RouteNextRoute(
      path: '/dashboard',
      layout: (context, child) => DashboardShell(body: child),
      builder: (_, __) => DashboardHome(),
      children: [
        RouteNextRoute(path: 'analytics', builder: (_, __) => AnalyticsPage()),
        RouteNextRoute(path: 'reports',   builder: (_, __) => ReportsPage()),
        RouteNextRoute(path: 'settings',  builder: (_, __) => SettingsPage()),
      ],
    ),
  ],
)
```

`DashboardShell` is mounted once for the entire `/dashboard/*` subtree. Navigating between `/dashboard/analytics` and `/dashboard/reports` does **not** remount the shell.

---

## Global Middleware Pipeline

Add composable middleware to `RouteNextApp` to run logic before **every** navigation — before per-route guards fire.

Middleware runs in declaration order. The first non-`allow` result short-circuits the chain.

```dart
RouteNextApp(
  middleware: [
    // 1. Analytics — always allow, just record the visit
    (context, match) async {
      Analytics.track(match.resolvedPath);
      return NavigationAction.allow();
    },

    // 2. Auth gate — redirect unauthenticated users to /login
    (context, match) async {
      final protectedPaths = ['/dashboard', '/admin'];
      final isProtected = protectedPaths.any(
        (p) => match.resolvedPath.startsWith(p),
      );
      if (isProtected && !AuthService.isLoggedIn) {
        return NavigationAction.redirect('/login');
      }
      return NavigationAction.allow();
    },

    // 3. Feature flag — block beta routes for non-beta users
    (context, match) async {
      if (match.resolvedPath.startsWith('/beta') && !UserPrefs.isBeta) {
        return NavigationAction.deny();
      }
      return NavigationAction.allow();
    },
  ],
  routes: [...],
)
```

### Per-Route Guards

For route-specific logic, attach a `guard` directly to a `RouteNextRoute`:

```dart
RouteNextRoute(
  path: '/admin',
  guard: (context) async {
    final isAdmin = await AuthService.hasAdminRole();
    return isAdmin
        ? NavigationAction.allow()
        : NavigationAction.redirect('/403');
  },
  builder: (_, __) => AdminPage(),
)
```

---

## Route Metadata & Document Title

Use `RouteMeta` to set the browser tab title and attach arbitrary metadata:

```dart
RouteNextRoute(
  path: '/dashboard',
  meta: RouteMeta(title: 'Dashboard — My App'),
  builder: (_, __) => DashboardPage(),
)
```

On Flutter web, `document.title` is updated automatically when the route becomes active.

---

## URL Strategies

```dart
RouteNextApp(
  urlStrategy: RouteNextUrlStrategy.hash, // /#/path  (default: .path)
  routes: [...],
)
```

| Strategy | URL shape | When to use |
|---|---|---|
| `RouteNextUrlStrategy.path` | `/dashboard` | Production with server-side wildcard |
| `RouteNextUrlStrategy.hash` | `/#/dashboard` | Static hosting (GitHub Pages, Firebase) |

---

## Page Transitions

Specify a transition per route:

```dart
RouteNextRoute(
  path: '/modal',
  transition: RouteNextTransition.fade,
  builder: (_, __) => ModalPage(),
)
```

Available transitions: `fade`, `slideRight`, `slideUp`, `scale`.

---

## Breadcrumbs

`RouteNextBreadcrumbs` automatically builds a breadcrumb trail from the current route hierarchy. No configuration needed:

```dart
RouteNextBreadcrumbs()
```

### Customisation

```dart
RouteNextBreadcrumbs(
  homeLabel: 'Home',
  separator: Icon(Icons.chevron_right, size: 16),
  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),

  // Override labels for specific routes
  labelBuilder: (match) => switch (match.resolvedPath) {
    '/dashboard'            => 'Dashboard',
    '/dashboard/analytics'  => 'Analytics',
    _                       => null, // fall back to RouteMeta.title or segment name
  },
)
```

Label resolution order for each crumb:
1. `labelBuilder` return value (if non-null)
2. `RouteMeta.title` on the matched route
3. Capitalised last path segment (`/dashboard/my-reports` → `My reports`)
4. `homeLabel` for the root `/` route

---

## Command Palette

Wrap your app shell with `RouteNextCommandPalette` to get a ⌘K / Ctrl+K search overlay:

```dart
RouteNextCommandPalette(
  commands: [
    CommandItem(label: 'Dashboard',   icon: Icons.dashboard,  path: '/dashboard'),
    CommandItem(label: 'Analytics',   icon: Icons.bar_chart,  path: '/dashboard/analytics'),
    CommandItem(label: 'Settings',    icon: Icons.settings,   path: '/settings'),
    CommandItem(label: 'Users',       icon: Icons.people,     path: '/admin/users', group: 'Admin'),

    // Non-navigation action
    CommandItem(
      label: 'Toggle dark mode',
      icon:  Icons.dark_mode,
      group: 'Actions',
      onSelect: () => themeNotifier.toggle(),
    ),
  ],
  child: MyAppShell(),
)
```

| Keyboard shortcut | Action |
|---|---|
| ⌘K / Ctrl+K | Open / close palette |
| ↑ / ↓ | Move selection |
| Enter | Activate selected item |
| Escape | Dismiss palette |

Search is case-insensitive and matches against `label`, `description`, and `group`.

### `CommandItem` properties

| Property | Type | Description |
|---|---|---|
| `label` | `String` | Primary display text (required) |
| `description` | `String?` | Secondary line shown below label |
| `icon` | `IconData?` | Leading icon |
| `path` | `String?` | Route to navigate to on selection |
| `onSelect` | `VoidCallback?` | Arbitrary callback (takes precedence over `path`) |
| `group` | `String?` | Badge shown on the trailing edge |

Either `path` or `onSelect` must be provided.

---

## Tab Bar

`RouteNextTabBar` is a URL-driven tab bar. The active tab is determined by `RouteNext.isActive()` — deep links, browser back/forward, and page refresh all keep the correct tab selected automatically.

```dart
RouteNextTabBar(
  tabs: [
    NavItem(path: '/dashboard',            label: 'Overview'),
    NavItem(path: '/dashboard/analytics',  label: 'Analytics'),
    NavItem(path: '/dashboard/reports',    label: 'Reports'),
  ],
)
```

### Inside an `AppBar`

```dart
AppBar(
  title: Text('Dashboard'),
  bottom: RouteNextTabBar(
    tabs: [
      NavItem(path: '/dashboard',           label: 'Overview'),
      NavItem(path: '/dashboard/analytics', label: 'Analytics'),
    ],
  ).asPreferredSize(),
)
```

### Customisation

```dart
RouteNextTabBar(
  tabs: [
    NavItem(path: '/dashboard',           label: 'Overview',   icon: Icons.home),
    NavItem(path: '/dashboard/analytics', label: 'Analytics',  icon: Icons.bar_chart),
    NavItem(path: '/dashboard/reports',   label: 'Reports',    icon: Icons.description),
  ],
  isScrollable:       true,
  activeColor:        Colors.indigo,
  inactiveColor:      Colors.grey,
  indicatorColor:     Colors.indigo,
  indicatorWeight:    3.0,
  tabHeight:          52.0,
  backgroundColor:    Colors.white,
)
```

When the current URL does not match any tab, the indicator and active label colour are both hidden — no tab appears falsely selected.

---

## Built-in Navigation Widgets

All built-in widgets stay in sync with the active URL automatically.

### `RouteNextScaffold`

A complete app shell with sidebar, drawer, and navbar management:

```dart
RouteNextScaffold(
  sidebar: RouteNextSidebar(
    items: [
      NavItem(path: '/dashboard', label: 'Dashboard', icon: Icons.dashboard),
      NavItem(path: '/users',     label: 'Users',     icon: Icons.people),
    ],
  ),
  body: RouterOutlet(),
)
```

### `RouteNextNavbar`

A top app bar with auto-highlighting action buttons:

```dart
RouteNextNavbar(
  items: [
    NavItem(path: '/',       label: 'Home'),
    NavItem(path: '/pricing', label: 'Pricing'),
    NavItem(path: '/docs',    label: 'Docs'),
  ],
)
```

### `RouteNextDrawer`

A slide-out drawer for mobile:

```dart
RouteNextDrawer(
  items: [
    NavItem(path: '/dashboard', label: 'Dashboard', icon: Icons.dashboard),
    NavItem(path: '/settings',  label: 'Settings',  icon: Icons.settings),
  ],
)
```

### `NavItem` properties

| Property | Type | Description |
|---|---|---|
| `path` | `String` | Route path navigated to on tap |
| `label` | `String` | Display text |
| `icon` | `IconData?` | Leading icon |
| `visible` | `bool Function(BuildContext)?` | Conditionally hide the item |

---

## Dynamic Params & Wildcards

```dart
// Dynamic segment
RouteNextRoute(
  path: '/users/:id',
  builder: (context, params) => UserPage(id: params['id']!),
)

// Catch-all wildcard  — matches /docs, /docs/guide, /docs/a/b/c
RouteNextRoute(
  path: '/docs/*',
  builder: (context, params) => DocsPage(slug: params['*'] ?? ''),
)

// Query parameters are merged into params automatically
// /search?q=flutter&page=2  →  params = {'q': 'flutter', 'page': '2'}
RouteNextRoute(
  path: '/search',
  builder: (context, params) => SearchPage(
    query: params['q'] ?? '',
    page: int.tryParse(params['page'] ?? '1') ?? 1,
  ),
)
```

---

## Complete Example

A minimal but complete SaaS dashboard shell:

```dart
RouteNextApp(
  title: 'My SaaS',
  theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),

  middleware: [
    (context, match) async {
      if (match.resolvedPath.startsWith('/app') && !Auth.isLoggedIn) {
        return NavigationAction.redirect('/login');
      }
      return NavigationAction.allow();
    },
  ],

  routes: [
    RouteNextRoute(path: '/login', builder: (_, __) => LoginPage()),

    RouteNextRoute(
      path: '/app',
      layout: (context, child) => RouteNextCommandPalette(
        commands: globalCommands,
        child: AppShell(child: child),
      ),
      builder: (_, __) => OverviewPage(),
      children: [
        RouteNextRoute(
          path: 'analytics',
          meta: RouteMeta(title: 'Analytics — My SaaS'),
          builder: (_, __) => AnalyticsPage(),
        ),
        RouteNextRoute(
          path: 'users/:id',
          guard: (context) async {
            final isAdmin = await Auth.hasRole('admin');
            return isAdmin ? NavigationAction.allow() : NavigationAction.deny();
          },
          builder: (context, params) => UserDetailPage(id: params['id']!),
        ),
      ],
    ),
  ],
)
```

---

## License

MIT — see the [LICENSE](LICENSE) file for details.
