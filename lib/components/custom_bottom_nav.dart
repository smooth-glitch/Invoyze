import 'package:flutter/material.dart';

class CustomBottomNav extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  CustomBottomNav({required this.selectedIndex, required this.onItemTapped});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.0, left: 16.0, right: 16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: BottomNavigationBar(
            // Rest of your BottomNavigationBar code remains the same
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.inventory_2_outlined),
                activeIcon: Icon(Icons.inventory_2),
                label: 'Inventory',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.receipt_outlined),
                activeIcon: Icon(Icons.receipt),
                label: 'Invoices',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
            currentIndex: selectedIndex,
            selectedItemColor: Color(0xFF5C6BC0),
            unselectedItemColor: Colors.grey.shade600,
            backgroundColor: Colors.white,
            type: BottomNavigationBarType.fixed,
            selectedFontSize: 12,
            unselectedFontSize: 12,
            elevation: 0,
            selectedIconTheme: IconThemeData(size: 28),
            unselectedIconTheme: IconThemeData(size: 24),
            onTap: onItemTapped,
          ),
        ),
      ),
    );
  }
}
