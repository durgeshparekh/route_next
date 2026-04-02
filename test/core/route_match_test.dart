import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:route_next/route_next.dart';

void main() {
  group('RouteMatch', () {
    test('allParams merges query and params, path takes priority', () {
      const route = RouteNextRoute(
        path: '/users/:id',
        builder: _stub,
      );
      const match = RouteMatch(
        route: route,
        params: {'id': '42'},
        query: {'id': 'ignored', 'tab': 'posts'},
        matchedPath: '/users/42',
      );

      expect(match.allParams['id'], '42'); // path param wins
      expect(match.allParams['tab'], 'posts');
    });

    test('equality based on matchedPath, params, query', () {
      const route = RouteNextRoute(
        path: '/about',
        builder: _stub,
      );
      const m1 = RouteMatch(
        route: route,
        params: {},
        query: {},
        matchedPath: '/about',
      );
      const m2 = RouteMatch(
        route: route,
        params: {},
        query: {},
        matchedPath: '/about',
      );
      expect(m1, equals(m2));
    });
  });
}

Widget _stub(BuildContext context, Map<String, String> params) =>
    const SizedBox();
