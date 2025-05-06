import 'package:flutter/material.dart';
import 'package:smart_inventory_app/components/custom_bottom_nav.dart';
import 'package:smart_inventory_app/screens/home_screen.dart';
import 'package:smart_inventory_app/screens/inventory_screen.dart';
import 'package:smart_inventory_app/screens/invoice_screen.dart';
import 'package:smart_inventory_app/screens/profile_screen.dart';

class MainScreen extends StatefulWidget {
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  void onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  final List<Widget> _widgetOptions = [
    HomeScreen(),
    InventoryScreen(),
    InvoiceListScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: CustomBottomNav(
        selectedIndex: _selectedIndex,
        onItemTapped: onItemTapped,
      ),
    );
  }
}
