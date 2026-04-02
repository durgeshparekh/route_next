import 'package:flutter/material.dart';
import 'package:route_next/route_next.dart';
import 'pages/home_page.dart';
import 'pages/about_page.dart';
import 'pages/services_page.dart';
import 'pages/portfolio_page.dart';
import 'pages/contact_page.dart';
import 'pages/not_found_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return RouteNextApp(
      title: 'My Portfolio',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      urlStrategy: RouteNextUrlStrategy.path,
      notFound: (context) => const NotFoundPage(),
      routes: [
        RouteNextRoute(
          path: '/',
          meta: const RouteMeta(title: 'Home'),
          builder: (context, params) => const HomePage(),
        ),
        RouteNextRoute(
          path: '/about',
          meta: const RouteMeta(title: 'About'),
          builder: (context, params) => const AboutPage(),
        ),
        RouteNextRoute(
          path: '/services',
          meta: const RouteMeta(title: 'Services'),
          builder: (context, params) => const ServicesPage(),
        ),
        RouteNextRoute(
          path: '/portfolio',
          meta: const RouteMeta(title: 'Portfolio'),
          builder: (context, params) => const PortfolioPage(),
        ),
        RouteNextRoute(
          path: '/contact',
          meta: const RouteMeta(title: 'Contact'),
          builder: (context, params) => const ContactPage(),
        ),
      ],
    );
  }
}
