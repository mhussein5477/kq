import 'package:flutter/material.dart';
import 'package:kq/screens/home/enquiriesScreen.dart';
import 'package:kq/screens/home/homeScreen.dart';
import 'package:kq/screens/home/profile.dart';
import 'package:kq/screens/home/reportScreen.dart';
import 'package:kq/screens/home/trendsScreen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomeScreen(),
    const ReportsScreen(),
    const TrendsScreen(),
    const EnquiriesScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],

      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          indicatorColor: const Color(0xFFE31E24).withOpacity(0.15),

          // Active icon + label
          labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>(
            (states) => TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: states.contains(WidgetState.selected)
                  ? const Color(0xFFE31E24)
                  : Colors.grey[500],
            ),
          ),
          iconTheme: WidgetStateProperty.resolveWith<IconThemeData>(
            (states) => IconThemeData(
              size: 26,
              color: states.contains(WidgetState.selected)
                  ? const Color(0xFFE31E24)
                  : Colors.grey[500],
            ),
          ),
        ),

        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) {
            setState(() => _selectedIndex = index);
          },
          height: 70,
          elevation: 3,
          surfaceTintColor: Colors.white,
          backgroundColor: Colors.white,

          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.assignment_outlined),
              selectedIcon: Icon(Icons.assignment),
              label: 'Reports',
            ),
            NavigationDestination(
              icon: Icon(Icons.trending_up_outlined),
              selectedIcon: Icon(Icons.trending_up),
              label: 'Trends',
            ),
            NavigationDestination(
              icon: Icon(Icons.help_outline),
              selectedIcon: Icon(Icons.help),
              label: 'Enquiries',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
