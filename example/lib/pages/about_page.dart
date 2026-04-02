import 'package:flutter/material.dart';
import 'package:route_next/route_next.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
        leading: BackButton(onPressed: () => RouteNext.of(context).pop()),
      ),
      body: const Center(
        child: Text(
          'About Page\n\nRefresh this page — you stay here!',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
