import 'package:flutter_test/flutter_test.dart';
import 'package:route_next/route_next.dart';

void main() {
  group('NavigationAction', () {
    test('allow() has correct type', () {
      final action = NavigationAction.allow();
      expect(action.type, NavigationActionType.allow);
      expect(action.redirectPath, isNull);
    });

    test('redirect() has correct type and path', () {
      final action = NavigationAction.redirect('/login');
      expect(action.type, NavigationActionType.redirect);
      expect(action.redirectPath, '/login');
    });

    test('deny() has correct type', () {
      final action = NavigationAction.deny();
      expect(action.type, NavigationActionType.deny);
      expect(action.redirectPath, isNull);
    });

    test('equality works', () {
      expect(NavigationAction.allow(), equals(NavigationAction.allow()));
      expect(
        NavigationAction.redirect('/login'),
        equals(NavigationAction.redirect('/login')),
      );
      expect(NavigationAction.deny(), equals(NavigationAction.deny()));
    });

    test('different redirects are not equal', () {
      expect(
        NavigationAction.redirect('/login'),
        isNot(equals(NavigationAction.redirect('/home'))),
      );
    });
  });
}
