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
