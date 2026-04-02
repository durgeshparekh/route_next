import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:route_next/route_next.dart';

Widget _w(String label) => Text(label);

void main() {
  group('RouteRegistry', () {
    late RouteRegistry registry;

    setUp(() {
      registry = RouteRegistry();
    });

    test('matches exact static paths', () {
      registry.build([
        RouteNextRoute(path: '/', builder: (_, __) => _w('home')),
        RouteNextRoute(path: '/about', builder: (_, __) => _w('about')),
        RouteNextRoute(path: '/contact', builder: (_, __) => _w('contact')),
      ]);

      expect(registry.match('/about'), isNotNull);
      expect(registry.match('/contact'), isNotNull);
      expect(registry.match('/about')!.resolvedPath, '/about');
    });

    test('matches dynamic parameter paths', () {
      registry.build([
        RouteNextRoute(path: '/users/:id', builder: (_, __) => _w('user')),
      ]);

      final m1 = registry.match('/users/42');
      expect(m1, isNotNull);
      expect(m1!.params['id'], '42');

      final m2 = registry.match('/users/abc');
      expect(m2, isNotNull);
      expect(m2!.params['id'], 'abc');
    });

    test('matches catch-all wildcard paths', () {
      registry.build([
        RouteNextRoute(path: '/docs/*', builder: (_, __) => _w('docs')),
      ]);

      final m1 = registry.match('/docs/getting-started');
      expect(m1, isNotNull);
      expect(m1!.params['*'], 'getting-started');

      final m2 = registry.match('/docs/a/b/c');
      expect(m2, isNotNull);
      expect(m2!.params['*'], 'a/b/c');
    });

    test('matches nested routes with correct full paths', () {
      registry.build([
        RouteNextRoute(
          path: '/dashboard',
          builder: (_, __) => _w('dashboard'),
          children: [
            RouteNextRoute(
              path: 'analytics',
              builder: (_, __) => _w('analytics'),
            ),
            RouteNextRoute(
              path: 'settings',
              builder: (_, __) => _w('settings'),
            ),
          ],
        ),
      ]);

      expect(registry.match('/dashboard/analytics'), isNotNull);
      expect(registry.match('/dashboard/settings'), isNotNull);
      expect(
        registry.match('/dashboard/analytics')!.resolvedPath,
        '/dashboard/analytics',
      );
    });

    test('prioritizes static over param over wildcard', () {
      registry.build([
        RouteNextRoute(
            path: '/users/settings', builder: (_, __) => _w('settings')),
        RouteNextRoute(path: '/users/:id', builder: (_, __) => _w('user')),
        RouteNextRoute(path: '/users/*', builder: (_, __) => _w('wildcard')),
      ]);

      // static wins
      final m1 = registry.match('/users/settings');
      expect(m1!.route.path, '/users/settings');

      // param wins over wildcard
      final m2 = registry.match('/users/42');
      expect(m2!.params['id'], '42');

      // wildcard for multi-segment
      final m3 = registry.match('/users/a/b/c');
      expect(m3!.params['*'], 'a/b/c');
    });

    test('returns null for unregistered paths', () {
      registry.build([
        RouteNextRoute(path: '/', builder: (_, __) => _w('home')),
        RouteNextRoute(path: '/about', builder: (_, __) => _w('about')),
      ]);

      expect(registry.match('/nonexistent'), isNull);
    });

    test('handles trailing slashes consistently', () {
      registry.build([
        RouteNextRoute(path: '/about', builder: (_, __) => _w('about')),
      ]);

      expect(registry.match('/about'), isNotNull);
      expect(registry.match('/about/'), isNotNull);
    });

    test('handles root path correctly', () {
      registry.build([
        RouteNextRoute(path: '/', builder: (_, __) => _w('home')),
      ]);

      expect(registry.match('/'), isNotNull);
      expect(registry.match(''), isNotNull);
    });

    test('collects layout chain from parent routes', () {
      Widget layoutA(BuildContext ctx, Widget child) =>
          ColoredBox(color: const Color(0xFFFF0000), child: child);
      Widget layoutB(BuildContext ctx, Widget child) =>
          ColoredBox(color: const Color(0xFF00FF00), child: child);

      registry.build([
        RouteNextRoute(
          path: '/',
          layout: layoutA,
          builder: (_, __) => _w('home'),
          children: [
            RouteNextRoute(
              path: 'dashboard',
              layout: layoutB,
              builder: (_, __) => _w('dash'),
              children: [
                RouteNextRoute(
                  path: 'settings',
                  builder: (_, __) => _w('settings'),
                ),
              ],
            ),
          ],
        ),
      ]);

      final m = registry.match('/dashboard/settings');
      expect(m, isNotNull);
      expect(m!.layoutChain.length, 2);
    });

    test('collects guard chain from parent routes', () {
      Future<NavigationAction> guardA(BuildContext ctx) async =>
          NavigationAction.allow();
      Future<NavigationAction> guardB(BuildContext ctx) async =>
          NavigationAction.allow();

      registry.build([
        RouteNextRoute(
          path: '/dashboard',
          guard: guardA,
          builder: (_, __) => _w('dash'),
          children: [
            RouteNextRoute(
              path: 'settings',
              guard: guardB,
              builder: (_, __) => _w('settings'),
            ),
          ],
        ),
      ]);

      final m = registry.match('/dashboard/settings');
      expect(m, isNotNull);
      expect(m!.guardChain.length, 2);
    });

    test('throws on duplicate path registration', () {
      expect(
        () => registry.build([
          RouteNextRoute(path: '/about', builder: (_, __) => _w('about')),
          RouteNextRoute(path: '/about', builder: (_, __) => _w('about2')),
        ]),
        throwsArgumentError,
      );
    });

    test('parses query parameters', () {
      registry.build([
        RouteNextRoute(path: '/search', builder: (_, __) => _w('search')),
      ]);

      final m = registry.match('/search', query: {'q': 'flutter', 'page': '2'});
      expect(m, isNotNull);
      expect(m!.query['q'], 'flutter');
      expect(m.query['page'], '2');
    });
    test('populates matchChain for nested routes', () {
      registry.build([
        RouteNextRoute(
          path: '/a',
          builder: (_, __) => _w('a'),
          children: [
            RouteNextRoute(
              path: 'b',
              builder: (_, __) => _w('b'),
              children: [
                RouteNextRoute(
                  path: 'c',
                  builder: (_, __) => _w('c'),
                ),
              ],
            ),
          ],
        ),
      ]);

      final m = registry.match('/a/b/c');
      expect(m, isNotNull);
      expect(m!.matchChain.length, 3);
      expect(m.matchChain[0].path, '/a');
      expect(m.matchChain[1].path, '/a/b');
      expect(m.matchChain[2].path, '/a/b/c');
    });
  });
}
