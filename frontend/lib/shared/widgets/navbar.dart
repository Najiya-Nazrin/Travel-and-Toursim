import 'package:explorex/features/home/presentation/screens/home.dart';
import 'package:explorex/features/my_trips/presentation/screens/my_trips.dart';
import 'package:explorex/features/plan_trip/presentation/screens/plan_trip.dart';
import 'package:flutter/material.dart';
// File: Navbar.dart

class Navbar extends StatefulWidget {
  const Navbar({super.key});

  @override
  State<Navbar> createState() => _NavbarState();
}

class _NavbarState extends State<Navbar> {
  int currentPageIndex = 0;

  // Function to change the current page index
  void _changePage(int index) {
    setState(() {
      currentPageIndex = index;
    });
  }

  // Create a list of the pages to display
  // FIX: Pass the callback function to the Home widget
  late final List<Widget> _pages = [
    Home(onPlanTripPressed: () => _changePage(1)), // Pass callback here
    const PlanTrip(),
    const MyTrips(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Use the current index to display the correct page from the list
      body: _pages[currentPageIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentPageIndex,
        onDestinationSelected: (int index) {
          // Update the index to switch the displayed page
          _changePage(index); // Use the central function
        },
        destinations: const <Widget>[
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(
            icon: Icon(Icons.flight_takeoff_outlined),
            label: 'Plan Trip',
          ),
          NavigationDestination(
            icon: Icon(Icons.location_on_outlined),
            label: 'My Trips',
          ),
        ],
      ),
    );
  }
}
