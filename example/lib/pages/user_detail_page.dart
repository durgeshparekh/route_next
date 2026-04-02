import 'package:flutter/material.dart';

class UserDetailPage extends StatelessWidget {
  const UserDetailPage({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('User: $userId')),
      body: Center(
        child: Text(
          'User Detail Page\nUser ID: $userId',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
