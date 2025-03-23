// File: lib/widgets/app_drawer.dart

import 'package:flutter/material.dart';

class AppDrawer extends StatelessWidget {
  final String currentRoute;

  const AppDrawer({Key? key, required this.currentRoute}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Define dark red color
    const Color darkRed = Color(0xFFB71C1C);

    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFEBEE), // Light red
              Colors.white,
            ],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: darkRed),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 30,
                    child: Icon(Icons.person, color: darkRed, size: 40),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'App Name',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'user@example.com',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            _buildDrawerItem(
              context,
              icon: Icons.home,
              title: 'Home',
              route: '/home',
              currentRoute: currentRoute,
            ),
            _buildDrawerItem(
              context,
              icon: Icons.person,
              title: 'Profile',
              route: '/profile',
              currentRoute: currentRoute,
            ),
            _buildDrawerItem(
              context,
              icon: Icons.settings,
              title: 'Settings',
              route: '/settings',
              currentRoute: currentRoute,
            ),
            _buildDrawerItem(
              context,
              icon: Icons.contact_mail,
              title: 'Contact Us',
              route: '/contact',
              currentRoute: currentRoute,
            ),
            _buildDrawerItem(
              context,
              icon: Icons.help,
              title: 'Support',
              route: '/support',
              currentRoute: currentRoute,
            ),
            _buildDrawerItem(
              context,
              icon: Icons.chat,
              title: 'Chatbot',
              route: '/chatbot',
              currentRoute: currentRoute,
            ),
            const Divider(),
            _buildDrawerItem(
              context,
              icon: Icons.logout,
              title: 'Logout',
              route: '/',
              currentRoute: currentRoute,
              onTap: () {
                // Clear any user session data if needed
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/', (route) => false);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
    required String currentRoute,
    VoidCallback? onTap,
  }) {
    final bool isSelected = route == currentRoute;
    const Color darkRed = Color(0xFFB71C1C);

    return ListTile(
      leading: Icon(icon, color: isSelected ? darkRed : Colors.black87),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? darkRed : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: Colors.red.withOpacity(0.1),
      onTap:
          onTap ??
          () {
            if (route != currentRoute) {
              Navigator.pop(context); // Close drawer
              Navigator.pushReplacementNamed(context, route);
            } else {
              Navigator.pop(
                context,
              ); // Just close drawer if we're already on this page
            }
          },
    );
  }
}
