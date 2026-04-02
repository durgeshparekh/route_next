import 'package:flutter/material.dart';
import 'package:route_next/route_next.dart';

class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '404',
              style: TextStyle(fontSize: 72, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('Page Not Found'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => RouteNext.of(context).push('/'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    );
  }
}
