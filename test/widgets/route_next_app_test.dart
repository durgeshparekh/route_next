import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:route_next/route_next.dart';

void main() {
  group('RouteNextApp Widget Tests', () {
    testWidgets('renders initial home route', (tester) async {
      await tester.pumpWidget(
        RouteNextApp(
          routes: [
            RouteNextRoute(
              path: '/',
              builder: (context, params) => const Text('Home Page'),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Home Page'), findsOneWidget);
    });

    testWidgets('navigates to another route via push', (tester) async {
      await tester.pumpWidget(
        RouteNextApp(
          routes: [
            RouteNextRoute(
              path: '/',
              builder: (context, params) => ElevatedButton(
                onPressed: () => RouteNext.of(context).push('/about'),
                child: const Text('Go to About'),
              ),
            ),
            RouteNextRoute(
              path: '/about',
              builder: (context, params) => const Text('About Page'),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('Go to About'));
      await tester.pumpAndSettle();

      expect(find.text('About Page'), findsOneWidget);
    });

    testWidgets('renders nested layouts', (tester) async {
      await tester.pumpWidget(
        RouteNextApp(
          routes: [
            RouteNextRoute(
              path: '/',
              builder: (context, params) => ElevatedButton(
                onPressed: () => RouteNext.of(context).push('/dashboard'),
                child: const Text('Go to Dashboard'),
              ),
            ),
            RouteNextRoute(
              path: '/dashboard',
              layout: (context, child) => Column(
                children: [
                  const Text('Dashboard Layout'),
                  Expanded(child: child),
                ],
              ),
              builder: (context, params) => const Text('Dashboard Home'),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('Go to Dashboard'));
      await tester.pumpAndSettle();

      expect(find.text('Dashboard Layout'), findsOneWidget);
      expect(find.text('Dashboard Home'), findsOneWidget);
    });

    testWidgets('handles 404 not found', (tester) async {
      await tester.pumpWidget(
        RouteNextApp(
          routes: [
            RouteNextRoute(
              path: '/',
              builder: (context, params) => const Text('Home'),
            ),
          ],
          notFound: (context) => const Text('Custom 404 Page'),
        ),
      );

      await tester.pumpAndSettle();

      final BuildContext context = tester.element(find.text('Home'));
      RouteNext.of(context).push('/unregistered');

      await tester.pumpAndSettle();
      expect(find.text('Custom 404 Page'), findsOneWidget);
    });

    testWidgets('executes async guards and redirects', (tester) async {
      bool isLoggedIn = false;

      await tester.pumpWidget(
        RouteNextApp(
          routes: [
            RouteNextRoute(
              path: '/login',
              builder: (context, params) => const Text('Login Page'),
            ),
            RouteNextRoute(
              path: '/profile',
              guard: (context) async {
                if (isLoggedIn) return NavigationAction.allow();
                return NavigationAction.redirect('/login');
              },
              builder: (context, params) => const Text('Profile Page'),
            ),
            RouteNextRoute(
              path: '/',
              builder: (context, params) => ElevatedButton(
                onPressed: () => RouteNext.of(context).push('/profile'),
                child: const Text('Go to Profile'),
              ),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Go to Profile'));
      await tester.pumpAndSettle();

      expect(find.text('Login Page'), findsOneWidget);
      expect(find.text('Profile Page'), findsNothing);

      isLoggedIn = true;
      RouteNext.of(tester.element(find.text('Login Page'))).push('/profile');
      await tester.pumpAndSettle();

      expect(find.text('Profile Page'), findsOneWidget);
    });
  });
}
