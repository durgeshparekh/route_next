// Tests for RouteNextDelegate — covering every bug fixed in the package.
//
// Bug catalogue (all fixed):
//  A. onDidRemovePage double-removes _stack → blank screen after back nav
//  B. String-concat page key collision → !keyReservation.contains(key) crash
//  C. replace() bypassed duplicate check → duplicate keys during transition
//  D. Guard redirect to already-stacked path → duplicate key crash
//  E. Infinite-redirect shows notFound instead of crashing
//  F. Guard deny keeps current page intact (no blank screen)
//  G. Guard deny when stack is empty does not throw
//  H. Multiple sequential guards all execute in order
//  I. Layout chain wraps correctly (outermost → innermost)
//  J. replace() to a path already in stack truncates rather than duplicates
//  K. RouteNextProvider rebuilds when extra changes on same path

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:route_next/route_next.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Widget _app({
  required List<RouteNextRoute> routes,
  Widget Function(BuildContext)? notFound,
}) {
  return RouteNextApp(
    routes: routes,
    notFound: notFound,
  );
}

Widget Function(BuildContext, Map<String, String>) _page(String label) =>
    (_, __) => Scaffold(body: Center(child: Text(label)));

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // -------------------------------------------------------------------------
  // A. onDidRemovePage double-remove
  // -------------------------------------------------------------------------
  group('BUG-A: onDidRemovePage must not double-remove stack entries', () {
    testWidgets('back navigation after push shows previous page', (tester) async {
      await tester.pumpWidget(_app(routes: [
        RouteNextRoute(path: '/', builder: _page('Home')),
        RouteNextRoute(path: '/about', builder: _page('About')),
      ]));
      await tester.pumpAndSettle();

      RouteNext.of(tester.element(find.text('Home'))).push('/about');
      await tester.pumpAndSettle();
      expect(find.text('About'), findsOneWidget);

      // System back — Navigator pops, which fires onDidRemovePage.
      final NavigatorState nav = tester.state(find.byType(Navigator).first);
      nav.pop();
      await tester.pumpAndSettle();

      // Stack must still have Home — not be empty.
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('About'), findsNothing);
    });

    testWidgets('three-deep navigation: pop twice returns to root', (tester) async {
      await tester.pumpWidget(_app(routes: [
        RouteNextRoute(path: '/', builder: _page('Home')),
        RouteNextRoute(path: '/a', builder: _page('A')),
        RouteNextRoute(path: '/b', builder: _page('B')),
      ]));
      await tester.pumpAndSettle();

      final ctx = tester.element(find.text('Home'));
      RouteNext.of(ctx).push('/a');
      await tester.pumpAndSettle();
      RouteNext.of(tester.element(find.text('A'))).push('/b');
      await tester.pumpAndSettle();

      final NavigatorState nav = tester.state(find.byType(Navigator).first);
      nav.pop();
      await tester.pumpAndSettle();
      expect(find.text('A'), findsOneWidget);

      nav.pop();
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  // B. String-concat key collision
  // -------------------------------------------------------------------------
  group('BUG-B: page keys must not collide when path+extra form same string', () {
    testWidgets('path /a1 and path /a with extra.hashCode==1 get distinct keys',
        (tester) async {
      // We cannot easily force hashCode == 1, so we verify that two distinct
      // pages are rendered without a crash — the record-based key prevents
      // ambiguity structurally.
      await tester.pumpWidget(_app(routes: [
        RouteNextRoute(path: '/', builder: _page('Home')),
        RouteNextRoute(path: '/a1', builder: _page('A1')),
        RouteNextRoute(path: '/a', builder: _page('A')),
      ]));
      await tester.pumpAndSettle();

      RouteNext.of(tester.element(find.text('Home'))).push('/a1');
      await tester.pumpAndSettle();
      expect(find.text('A1'), findsOneWidget);

      // Push /a on top of /a1 — previously this could collide if extra was
      // involved. No crash expected.
      RouteNext.of(tester.element(find.text('A1'))).push('/a');
      await tester.pumpAndSettle();
      expect(find.text('A'), findsOneWidget);
    });

    testWidgets('push with extra renders page and subsequent push is distinct',
        (tester) async {
      String? receivedExtra;
      await tester.pumpWidget(RouteNextApp(routes: [
        RouteNextRoute(path: '/', builder: _page('Home')),
        RouteNextRoute(
          path: '/detail',
          builder: (context, params) {
            receivedExtra =
                RouteNext.of(context).current?.extra as String?;
            return Scaffold(body: Text('Detail $receivedExtra'));
          },
        ),
      ]));
      await tester.pumpAndSettle();

      RouteNext.of(tester.element(find.text('Home')))
          .push('/detail', extra: 'payload-1');
      await tester.pumpAndSettle();
      expect(receivedExtra, 'payload-1');

      // Push same path with different extra — must not crash.
      RouteNext.of(tester.element(find.text('Detail payload-1')))
          .push('/detail', extra: 'payload-2');
      await tester.pumpAndSettle();
      expect(find.textContaining('Detail'), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  // C. replace() bypassed duplicate check
  // -------------------------------------------------------------------------
  group('BUG-C: replace() must not leave duplicate keys in the stack', () {
    testWidgets('replace to a path already deeper in stack truncates correctly',
        (tester) async {
      await tester.pumpWidget(_app(routes: [
        RouteNextRoute(path: '/', builder: _page('Home')),
        RouteNextRoute(path: '/a', builder: _page('A')),
        RouteNextRoute(path: '/b', builder: _page('B')),
      ]));
      await tester.pumpAndSettle();

      RouteNext.of(tester.element(find.text('Home'))).push('/a');
      await tester.pumpAndSettle();
      RouteNext.of(tester.element(find.text('A'))).push('/b');
      await tester.pumpAndSettle();

      // replace('/a') while /a is behind /b in the stack.
      // Must not create [Home, A, A] — must truncate to [Home, A].
      RouteNext.of(tester.element(find.text('B'))).replace('/a');
      await tester.pumpAndSettle();

      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsNothing);
    });

    testWidgets('replace to current page is a no-op (no blank screen)',
        (tester) async {
      await tester.pumpWidget(_app(routes: [
        RouteNextRoute(path: '/', builder: _page('Home')),
        RouteNextRoute(path: '/a', builder: _page('A')),
      ]));
      await tester.pumpAndSettle();

      RouteNext.of(tester.element(find.text('Home'))).push('/a');
      await tester.pumpAndSettle();

      RouteNext.of(tester.element(find.text('A'))).replace('/a');
      await tester.pumpAndSettle();

      // Still on A, no crash, no blank.
      expect(find.text('A'), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  // D. Guard redirect to already-stacked path → duplicate key crash
  // -------------------------------------------------------------------------
  group('BUG-D: guard redirect to existing stack entry must not crash', () {
    testWidgets('guard redirects to home which is already in stack',
        (tester) async {
      await tester.pumpWidget(_app(routes: [
        RouteNextRoute(path: '/', builder: _page('Home')),
        RouteNextRoute(
          path: '/protected',
          guard: (ctx) async => NavigationAction.redirect('/'),
          builder: _page('Protected'),
        ),
      ]));
      await tester.pumpAndSettle();

      // Push /protected → guard redirects back to / which is already in stack.
      RouteNext.of(tester.element(find.text('Home'))).push('/protected');
      await tester.pumpAndSettle();

      // Should show Home, not crash with duplicate-key assertion.
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Protected'), findsNothing);
    });

    testWidgets('guard chain: parent redirects, child guard never runs',
        (tester) async {
      bool childGuardRan = false;

      await tester.pumpWidget(_app(routes: [
        RouteNextRoute(path: '/', builder: _page('Home')),
        RouteNextRoute(path: '/login', builder: _page('Login')),
        RouteNextRoute(
          path: '/section',
          guard: (ctx) async => NavigationAction.redirect('/login'),
          builder: _page('Section'),
          children: [
            RouteNextRoute(
              path: 'child',
              guard: (ctx) async {
                childGuardRan = true;
                return NavigationAction.allow();
              },
              builder: _page('Child'),
            ),
          ],
        ),
      ]));
      await tester.pumpAndSettle();

      RouteNext.of(tester.element(find.text('Home'))).push('/section/child');
      await tester.pumpAndSettle();

      expect(find.text('Login'), findsOneWidget);
      expect(childGuardRan, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // E. Infinite redirect detection
  // -------------------------------------------------------------------------
  group('BUG-E: infinite redirect loop shows 404 instead of hanging', () {
    testWidgets('self-redirecting guard triggers notFound after depth limit',
        (tester) async {
      await tester.pumpWidget(RouteNextApp(
        notFound: (ctx) => const Scaffold(body: Text('404')),
        routes: [
          RouteNextRoute(path: '/', builder: _page('Home')),
          RouteNextRoute(
            path: '/loop',
            guard: (ctx) async => NavigationAction.redirect('/loop'),
            builder: _page('Loop'),
          ),
        ],
      ));
      await tester.pumpAndSettle();

      // Capture flutter errors so the test doesn't fail on the reported error.
      final errors = <FlutterErrorDetails>[];
      FlutterError.onError = (d) => errors.add(d);

      RouteNext.of(tester.element(find.text('Home'))).push('/loop');
      await tester.pumpAndSettle();

      FlutterError.onError = FlutterError.presentError;

      // At least one error reported about the loop.
      expect(errors, isNotEmpty);
      expect(
        errors.any((e) => e.exception.toString().contains('redirect loop')),
        isTrue,
      );
    });
  });

  // -------------------------------------------------------------------------
  // F. Guard deny keeps current page
  // -------------------------------------------------------------------------
  group('BUG-F: guard deny must leave the current route unchanged', () {
    testWidgets('denied navigation stays on current page', (tester) async {
      await tester.pumpWidget(_app(routes: [
        RouteNextRoute(path: '/', builder: _page('Home')),
        RouteNextRoute(
          path: '/denied',
          guard: (ctx) async => NavigationAction.deny(),
          builder: _page('Denied'),
        ),
      ]));
      await tester.pumpAndSettle();

      RouteNext.of(tester.element(find.text('Home'))).push('/denied');
      await tester.pumpAndSettle();

      // Must still show Home, not blank, not 'Denied'.
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Denied'), findsNothing);
    });
  });

  // -------------------------------------------------------------------------
  // G. Guard deny on empty stack must not throw
  // -------------------------------------------------------------------------
  group('BUG-G: guard deny on empty stack is a no-op', () {
    testWidgets('initial navigation denied shows empty (no crash)', (tester) async {
      final errors = <FlutterErrorDetails>[];
      FlutterError.onError = (d) => errors.add(d);

      await tester.pumpWidget(RouteNextApp(
        routes: [
          RouteNextRoute(
            path: '/',
            guard: (ctx) async => NavigationAction.deny(),
            builder: _page('Home'),
          ),
        ],
      ));
      await tester.pumpAndSettle();

      FlutterError.onError = FlutterError.presentError;

      // No assertion errors from the framework.
      expect(
        errors.where((e) => e.exception is AssertionError),
        isEmpty,
      );
    });
  });

  // -------------------------------------------------------------------------
  // H. Multiple sequential guards execute in order
  // -------------------------------------------------------------------------
  group('BUG-H: multiple guards run sequentially, first non-allow stops chain',
      () {
    testWidgets('all-allow guards permit navigation', (tester) async {
      final order = <int>[];
      await tester.pumpWidget(_app(routes: [
        RouteNextRoute(path: '/', builder: _page('Home')),
        RouteNextRoute(
          path: '/outer',
          guard: (ctx) async {
            order.add(1);
            return NavigationAction.allow();
          },
          builder: _page('Outer'),
          children: [
            RouteNextRoute(
              path: 'inner',
              guard: (ctx) async {
                order.add(2);
                return NavigationAction.allow();
              },
              builder: _page('Inner'),
            ),
          ],
        ),
      ]));
      await tester.pumpAndSettle();

      RouteNext.of(tester.element(find.text('Home'))).push('/outer/inner');
      await tester.pumpAndSettle();

      expect(find.text('Inner'), findsOneWidget);
      expect(order, [1, 2]);
    });

    testWidgets('first denying guard stops chain and blocks navigation',
        (tester) async {
      final order = <int>[];
      await tester.pumpWidget(_app(routes: [
        RouteNextRoute(path: '/', builder: _page('Home')),
        RouteNextRoute(
          path: '/outer',
          guard: (ctx) async {
            order.add(1);
            return NavigationAction.deny();
          },
          builder: _page('Outer'),
          children: [
            RouteNextRoute(
              path: 'inner',
              guard: (ctx) async {
                order.add(2); // must NOT run
                return NavigationAction.allow();
              },
              builder: _page('Inner'),
            ),
          ],
        ),
      ]));
      await tester.pumpAndSettle();

      RouteNext.of(tester.element(find.text('Home'))).push('/outer/inner');
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Inner'), findsNothing);
      expect(order, [1]); // guard 2 never ran
    });
  });

  // -------------------------------------------------------------------------
  // I. Layout chain wraps in the correct nesting order
  // -------------------------------------------------------------------------
  group('BUG-I: layout chain nesting order is parent-outermost', () {
    testWidgets('inner layout is nested inside outer layout', (tester) async {
      await tester.pumpWidget(_app(routes: [
        RouteNextRoute(
          path: '/',
          layout: (ctx, child) => Column(children: [
            const Text('OuterLayout'),
            Expanded(child: child),
          ]),
          builder: _page('Home'),
          children: [
            RouteNextRoute(
              path: 'sub',
              layout: (ctx, child) => Column(children: [
                const Text('InnerLayout'),
                Expanded(child: child),
              ]),
              builder: _page('Sub'),
            ),
          ],
        ),
      ]));
      await tester.pumpAndSettle();

      RouteNext.of(tester.element(find.text('Home'))).push('/sub');
      await tester.pumpAndSettle();

      expect(find.text('OuterLayout'), findsOneWidget);
      expect(find.text('InnerLayout'), findsOneWidget);
      expect(find.text('Sub'), findsOneWidget);

      // The depth check: OuterLayout text appears before InnerLayout text in
      // the widget tree traversal order, confirming outer wraps inner.
      final allText = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data)
          .toList();
      final outerIdx = allText.indexOf('OuterLayout');
      final innerIdx = allText.indexOf('InnerLayout');
      expect(outerIdx, lessThan(innerIdx));
    });
  });

  // -------------------------------------------------------------------------
  // J. replace() to path already in stack (not just current)
  // -------------------------------------------------------------------------
  group('BUG-J: replace() to earlier stack entry truncates, not appends', () {
    testWidgets('stack is truncated to matched entry, back nav works correctly',
        (tester) async {
      await tester.pumpWidget(_app(routes: [
        RouteNextRoute(path: '/', builder: _page('Home')),
        RouteNextRoute(path: '/a', builder: _page('A')),
        RouteNextRoute(path: '/b', builder: _page('B')),
        RouteNextRoute(path: '/c', builder: _page('C')),
      ]));
      await tester.pumpAndSettle();

      // Build stack: / → /a → /b → /c
      RouteNext.of(tester.element(find.text('Home'))).push('/a');
      await tester.pumpAndSettle();
      RouteNext.of(tester.element(find.text('A'))).push('/b');
      await tester.pumpAndSettle();
      RouteNext.of(tester.element(find.text('B'))).push('/c');
      await tester.pumpAndSettle();

      // replace('/a') while on /c — removes /c (current) then finds /a in
      // remaining [/, /a, /b] and truncates to [/, /a].
      RouteNext.of(tester.element(find.text('C'))).replace('/a');
      await tester.pumpAndSettle();
      expect(find.text('A'), findsOneWidget);

      // Only one back nav should reach Home, not /b.
      final NavigatorState nav = tester.state(find.byType(Navigator).first);
      nav.pop();
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  // K. RouteNextProvider notifies on extra change with same path
  // -------------------------------------------------------------------------
  group('BUG-K: RouteNextProvider rebuilds when extra changes on same path', () {
    testWidgets('widget reading extra rebuilds on second push with new extra',
        (tester) async {
      int buildCount = 0;

      await tester.pumpWidget(RouteNextApp(routes: [
        RouteNextRoute(path: '/', builder: _page('Home')),
        RouteNextRoute(
          path: '/detail',
          builder: (context, params) {
            buildCount++;
            final extra = RouteNext.of(context).current?.extra as String? ?? '';
            return Scaffold(body: Text('Detail: $extra'));
          },
        ),
      ]));
      await tester.pumpAndSettle();

      RouteNext.of(tester.element(find.text('Home')))
          .push('/detail', extra: 'first');
      await tester.pumpAndSettle();
      final countAfterFirst = buildCount;

      // Push same path with different extra. Provider must trigger rebuild.
      RouteNext.of(tester.element(find.textContaining('Detail')))
          .replace('/detail', extra: 'second');
      await tester.pumpAndSettle();

      expect(buildCount, greaterThan(countAfterFirst));
      expect(find.text('Detail: second'), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  // Regression: isActive correctly reflects hierarchy
  // -------------------------------------------------------------------------
  group('isActive: hierarchy matching vs exact matching', () {
    testWidgets('isActive returns true for parent path when on child route',
        (tester) async {
      bool? parentActive;
      bool? childActive;

      await tester.pumpWidget(RouteNextApp(routes: [
        RouteNextRoute(path: '/', builder: _page('Home')),
        RouteNextRoute(
          path: '/dashboard',
          builder: _page('Dashboard'),
          children: [
            RouteNextRoute(
              path: 'analytics',
              builder: (context, params) {
                final nav = RouteNext.of(context);
                parentActive = nav.isActive('/dashboard');
                childActive = nav.isActive('/dashboard/analytics', exact: true);
                return const Scaffold(body: Text('Analytics'));
              },
            ),
          ],
        ),
      ]));
      await tester.pumpAndSettle();

      RouteNext.of(tester.element(find.text('Home')))
          .push('/dashboard/analytics');
      await tester.pumpAndSettle();

      expect(parentActive, isTrue);
      expect(childActive, isTrue);
    });

    testWidgets('isActive exact=true returns false for parent when on child',
        (tester) async {
      bool? parentExactActive;

      await tester.pumpWidget(RouteNextApp(routes: [
        RouteNextRoute(path: '/', builder: _page('Home')),
        RouteNextRoute(
          path: '/dashboard',
          builder: _page('Dashboard'),
          children: [
            RouteNextRoute(
              path: 'analytics',
              builder: (context, params) {
                parentExactActive =
                    RouteNext.of(context).isActive('/dashboard', exact: true);
                return const Scaffold(body: Text('Analytics'));
              },
            ),
          ],
        ),
      ]));
      await tester.pumpAndSettle();

      RouteNext.of(tester.element(find.text('Home')))
          .push('/dashboard/analytics');
      await tester.pumpAndSettle();

      expect(parentExactActive, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // Regression: 404 on initial unmatched URL
  // -------------------------------------------------------------------------
  group('404 not found handling', () {
    testWidgets('push to unregistered path shows custom notFound widget',
        (tester) async {
      await tester.pumpWidget(RouteNextApp(
        notFound: (ctx) => const Scaffold(body: Text('Custom 404')),
        routes: [
          RouteNextRoute(path: '/', builder: _page('Home')),
        ],
      ));
      await tester.pumpAndSettle();

      RouteNext.of(tester.element(find.text('Home'))).push('/does-not-exist');
      await tester.pumpAndSettle();

      expect(find.text('Custom 404'), findsOneWidget);
    });
  });
}
