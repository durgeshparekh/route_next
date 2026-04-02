# RouteNext

**Next.js-style navigation for Flutter web.** 

RouteNext provides URL-based routing where browser refresh, deep linking, and back/forward navigation just work out of the box. Designed for a seamless development experience similar to modern web frameworks.

[![pub package](https://img.shields.io/pub/v/route_next.svg)](https://pub.dev/packages/route_next)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Features

- 🌐 **Clean URLs**: Switch between hash-based (`/#/about`) and path-based (`/about`) URL strategies.
- 🔗 **Deep Linking**: Direct access to any URL is handled automatically on initial launch and refresh.
- 🛡️ **Route Guards**: Truly asynchronous "middleware" that can block or redirect navigation.
- 🏗️ **Layouts & Shells**: Next.js-style nested layouts that wrap your page content automatically.
- 🔡 **Dynamic Params**: Pattern-matched routes like `/users/:id` and catch-all wildcards `/*`.
- 🔄 **Auto-Syncing UI**: Built-in `Drawer`, `Sidebar`, and `Navbar` widgets that stay in sync with the active URL.
- 🎬 **Page Transitions**: Built-in support for fade, slide, and scale animations.

## Getting Started

### 1. Simple Setup

Wrap your application in `RouteNextApp` and define your routes:

```dart
import 'package:flutter/material.dart';
import 'package:route_next/route_next.dart';

void main() {
  runApp(
    RouteNextApp(
      title: 'My Portfolio',
      routes: [
        RouteNextRoute(path: '/', builder: (context, params) => HomePage()),
        RouteNextRoute(path: '/about', builder: (context, params) => AboutPage()),
        RouteNextRoute(path: '/users/:id', builder: (context, params) => UserPage(id: params['id']!)),
      ],
    ),
  );
}
```

### 2. Imperative Navigation

Use `RouteNext.of(context)` to navigate from anywhere in your widget tree:

```dart
// Push a new route
RouteNext.of(context).push('/about');

// Push with query parameters
RouteNext.of(context).push('/search', query: {'q': 'flutter'});

// Replace current route
RouteNext.of(context).replace('/dashboard');

// Go back
RouteNext.of(context).pop();
```

## Advanced Usage

### Route Guards (Middleware)

Guards run asynchronously before a route is rendered. They can allow, redirect, or deny navigation.

```dart
RouteNextRoute(
  path: '/dashboard',
  guard: (context) async {
    final bool isAuthenticated = await AuthService.checkAuth();
    if (isAuthenticated) {
      return NavigationAction.allow();
    } else {
      return NavigationAction.redirect('/login');
    }
  },
  builder: (context, params) => DashboardPage(),
)
```

### Nested Layouts

Layouts wrap the matched page widget and all its children. This is perfect for persistent app shells (sidebars, navbars).

```dart
RouteNextRoute(
  path: '/admin',
  layout: (context, child) => AdminShell(body: child),
  builder: (context, params) => AdminHome(),
  children: [
    RouteNextRoute(path: 'users', builder: (context, params) => UserList()),
    RouteNextRoute(path: 'settings', builder: (context, params) => AdminSettings()),
  ],
)
```

In this example, both `/admin/users` and `/admin/settings` will be wrapped inside `AdminShell`.

### URL Strategies

By default, RouteNext uses path-based URLs (`/path`). You can easily switch to hash-based (`/#/path`):

```dart
RouteNextApp(
  urlStrategy: RouteNextUrlStrategy.hash, // Use hash strategy
  routes: [ ... ],
)
```

## UI Components

RouteNext includes responsive navigation widgets that automatically highlight based on the current URL path:

- `RouteNextScaffold`: A shell layout with built-in sidebar/drawer management.
- `RouteNextNavbar`: A top app bar with auto-highlighting action buttons.
- `RouteNextSidebar`: A permanent left-hand navigation panel.
- `RouteNextDrawer`: A slide-out navigation menu for mobile.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.