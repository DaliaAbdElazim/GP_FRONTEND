// lib/widgets/base_screen.dart
import 'package:flutter/material.dart';
import 'navigation_drawer.dart';

class BaseScreen extends StatelessWidget {
  final String title;
  final String currentRoute;
  final Widget body;
  final List<Widget>? actions;

  const BaseScreen({
    Key? key,
    required this.title,
    required this.currentRoute,
    required this.body,
    this.actions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: actions),
      drawer: CustomNavigationDrawer(currentRoute: currentRoute),
      body: body,
    );
  }
}
