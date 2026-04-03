## 1.2.1

### New Features

* **Global middleware pipeline**: Add app-wide `middleware` to `RouteNextApp` — runs before per-route guards on every navigation. Compose analytics, auth gates, and feature flags without attaching guards to individual routes.
  ```dart
  RouteNextApp(
    middleware: [
      (context, match) async {
        Analytics.track(match.resolvedPath);
        return NavigationAction.allow();
      },
    ],
    routes: [...],
  )
  ```
* **`RouteNextBreadcrumbs`**: Auto-generated breadcrumb trail driven by `RouteMatch.matchChain`. Labels are derived from `RouteMeta.title`, a custom `labelBuilder`, or the capitalised path segment. Supports custom separators, text styles, and padding.
* **`RouteNextCommandPalette`**: ⌘K / Ctrl+K command palette overlay. Supports fuzzy substring search, keyboard navigation (↑↓ Enter Esc), group badges, and both route navigation and arbitrary `onSelect` callbacks.
* **`RouteNextTabBar`**: URL-driven tab bar where the active tab is determined by `RouteNext.isActive()`. Works as a standalone widget or as `AppBar.bottom` via `.asPreferredSize()`. Supports scrollable mode, custom colors, and icon+label tabs. Correctly hides the indicator when no tab matches the current URL.

### Bug Fixes

* **`RouteNextCommandPalette` — FocusNode memory leaks**: Two `FocusNode` instances were previously created inline inside `build()` methods (both in `_RouteNextCommandPaletteState` and `_PaletteOverlayState`), causing a new unmanaged node to be allocated on every rebuild. Fixed by promoting both to named fields disposed in their respective `dispose()` methods.
* **`RouteNextTabBar` — ghost active tab**: When the current URL matched none of the tabs, `activeIndex` fell back to `0`, causing the first tab to appear falsely selected. Fixed by tracking `hasActiveTab` separately; when `false`, the indicator and label color are both suppressed.

---

## 1.2.0

### Bug Fixes

* **Critical — Navigator key crash fixed**: Dart `Map.==` uses reference equality, so the duplicate-detection logic in `_commitToStack` and `setNewRoutePath` always evaluated to false, allowing duplicate `Page` entries with identical `LocalKey`s to enter the Navigator's `pages` list and trigger the `!keyReservation.contains(key)` assertion crash. Fixed by introducing a `_mapsEqual` helper that performs value-based comparison.
* **`onDidRemovePage` double-remove**: When the delegate shortened the stack and called `notifyListeners()`, Flutter's reconciliation also fired `onDidRemovePage`, causing the handler to remove the same entry a second time and leave a blank screen. Fixed by guarding removal with `page.key == _pageKey(_stack.last)`.
* **Page key string-concat collision**: `ValueKey(resolvedPath + extra.hashCode.toString())` could produce identical keys for logically distinct routes (e.g. path `/a1` with no extra vs path `/a` whose extra has `hashCode == 1`). Fixed by using a Dart record tuple: `ValueKey((resolvedPath, extra?.hashCode))`.
* **`replace()` bypassing deduplication**: `replace()` manipulated `_stack` directly instead of routing through `_commitToStack`, allowing duplicate resolved paths to accumulate. Fixed by routing through the central `_commitToStack` helper.
* **Guard redirect to existing stack entry**: When a guard redirected to a path already present in the stack, `_handleNewPath` appended a duplicate entry directly via `_stack.add`, bypassing deduplication. Fixed by routing all commits through `_commitToStack`.
* **`RouteNextProvider.updateShouldNotify` ignoring `extra`**: Widget subtrees that depended on `extra` did not rebuild when only `extra` changed because `updateShouldNotify` only compared `currentMatch` object identity. Fixed by also comparing `currentMatch?.extra`.

### Breaking Changes

* **Minimum Flutter version raised to `>=3.27.0`** (was `>=3.16.0`). Required by `Color.withValues(alpha:)` usage in built-in UI components (Sidebar, Drawer). Users on Flutter < 3.27 should stay on `1.1.0` or upgrade Flutter.

### Tests

* Added 19 new regression tests in `test/widgets/route_next_delegate_test.dart` covering all of the above bug scenarios: back-navigation stack integrity, replace-mode deduplication, page-key collision, guard redirect loops, `onDidRemovePage` interaction, `isActive` matching, and 404 fallback rendering.

## 1.1.0

* **Architecture Refined**: Significantly improved the core navigation engine for production readiness.
* **Smart History Sync**: Optimized `RouteNextDelegate` to intelligently reconcile the internal stack with browser back/forward navigation.
* **Persistent Layouts**: Shared layouts (Sidebars, Navbars) now maintain their internal state (scroll, focus) during navigation between child routes.
* **Hierarchical Metadata**: Introduced `matchChain` in `RouteMatch` for robust breadcrumb support and parent route awareness.
* **Improved `isActive`**: Refined the active status logic to support both pattern and resolved path matching across the entire route hierarchy.
* **Enhanced Example**: Rebuilt the example project to demonstrate best practices for guards and nested layouts.

## 1.0.0

* Initial release of RouteNext.
* URL-first navigation powered by Navigator 2.0.
* Browser refresh and deep-linking support.
* Support for nested routes and layouts.
* Async route guards (middleware).
* Pattern matching with dynamic params (:id) and wildcards (*).
* Built-in UI components: RouteNextScaffold, Sidebar, Drawer, and Navbar.
