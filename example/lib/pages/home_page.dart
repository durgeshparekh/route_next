import 'package:flutter/material.dart';
import 'package:route_next/route_next.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final nav = RouteNext.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Welcome Home!',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('Try refreshing the page — you will stay here.'),
            const SizedBox(height: 32),
            Wrap(
              spacing: 12,
              children: [
                ElevatedButton(
                  onPressed: () => nav.push('/about'),
                  child: const Text('About'),
                ),
                ElevatedButton(
                  onPressed: () => nav.push('/services'),
                  child: const Text('Services'),
                ),
                ElevatedButton(
                  onPressed: () => nav.push('/portfolio'),
                  child: const Text('Portfolio'),
                ),
                ElevatedButton(
                  onPressed: () => nav.push('/contact'),
                  child: const Text('Contact'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
