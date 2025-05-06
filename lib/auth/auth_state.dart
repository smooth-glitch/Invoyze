import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:smart_inventory_app/main_screen.dart';
import 'package:smart_inventory_app/models/user_model.dart';
import 'package:smart_inventory_app/screens/login_screen.dart';
import 'package:smart_inventory_app/screens/staff_screen.dart'; // Import your StaffScreen

class AuthState extends StatelessWidget {
  const AuthState({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (authSnapshot.hasError) {
          return const Center(child: Text('Something went wrong'));
        } else if (authSnapshot.hasData) {
          // User is authenticated, check their role
          final userId = authSnapshot.data!.uid;
          return StreamBuilder<DocumentSnapshot>(
            stream:
                FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .snapshots(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final userData =
                  userSnapshot.data!.data() as Map<String, dynamic>;
              final user = UserModel(
                id: userSnapshot.data!.id,
                name: userData['name'],
                email: userData['email'],
                role: userData['role'],
              );
              // Navigate based on role
              return user.role == 'Staff'
                  ? StaffScreen(user: user)
                  : MainScreen();
            },
          );
        } else {
          // User is not authenticated
          return const LoginScreen();
        }
      },
    );
  }
}
