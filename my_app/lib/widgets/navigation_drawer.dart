import 'package:flutter/material.dart';
import 'package:my_app/utils/session_manager.dart';

class CustomNavigationDrawer extends StatelessWidget {
  final String currentRoute;
  const CustomNavigationDrawer({Key? key, required this.currentRoute})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 40, color: Colors.blue),
                ),
                SizedBox(height: 10),
                Text(
                  'Navigation Menu',
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
              ],
            ),
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.home,
            title: 'Home',
            route: '/home',
            isSelected: currentRoute == '/home',
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.person,
            title: 'Profile',
            route: '/profile',
            isSelected: currentRoute == '/profile',
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.list_alt,  // Changed icon to represent contributions
            title: 'Contributions',
            route: '/contributions',
            isSelected: currentRoute == '/contributions',
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.settings,
            title: 'Settings',
            route: '/settings',
            isSelected: currentRoute == '/settings',
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.contact_mail,
            title: 'Contact Us',
            route: '/contact',
            isSelected: currentRoute == '/contact',
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.help,
            title: 'Support',
            route: '/support',
            isSelected: currentRoute == '/support',
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.chat,
            title: 'Chatbot',
            route: '/chatbot',
            isSelected: currentRoute == '/chatbot',
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.settings,
            title: 'Notification',
            route: '/notification',
            isSelected: currentRoute == '/notification',
          ),
          Divider(), // Add a divider before the logout button
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red),
            title: Text(
              'Logout',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.normal,
              ),
            ),
            onTap: () {
              // Close the drawer
              Navigator.pop(context);

              // Perform logout directly
              _handleLogout(context);
            },
          ),
        ],
      ),
    );
  }

  void _handleLogout(BuildContext context) async {
    // Add logout logic here
    // For example:
    // AuthService.logout();
    await SessionManager.logout(context);
    // Optional: Show a confirmation dialog or snackbar
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Logged out successfully')));

    // Note: No navigation is performed, as requested
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String route,
    required bool isSelected,
  }) {
    return ListTile(
      leading: Icon(icon, color: isSelected ? Colors.blue : Colors.grey),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.blue : Colors.black,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onTap: () {
        // Close the drawer
        Navigator.pop(context);

        // If we're not already on this route, navigate to it
        if (!isSelected) {
          Navigator.pushReplacementNamed(context, route);
        }
      },
    );
  }
}