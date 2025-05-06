import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_inventory_app/auth/auth_func.dart';
import 'package:smart_inventory_app/components/custom_search_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_inventory_app/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filteredUsers = [];

  String _adminName = "Admin User"; // Default admin name
  String _adminEmail = "";
  int _productsCount = 0;
  int _usersCount = 0;

  void logout() {
    AuthFunc _auth = AuthFunc();
    _auth.signOut();
  }

  @override
  void initState() {
    super.initState();
    _fetchUsersFromFirebase();
    _fetchStats();
    _fetchAdminProfile();
    _searchController.addListener(_filterUsers);
  }

  Future<void> _fetchAdminProfile() async {
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final DocumentSnapshot adminDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(currentUser.uid)
                .get();

        if (adminDoc.exists) {
          setState(() {
            _adminName = adminDoc['name'] ?? "Admin User";
            _adminEmail = adminDoc['email'] ?? "";
          });
        }
      }
    } catch (e) {
      print('Error fetching admin profile: $e');
    }
  }

  Future<void> _updateAdminName(String newName) async {
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .update({'name': newName});

        setState(() {
          _adminName = newName;
        });
      }
    } catch (e) {
      print('Error updating admin name: $e');
    }
  }

  void _showEditNameDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController(
      text: _adminName,
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(Icons.edit, color: Color(0xFF3498db), size: 28),
                    SizedBox(width: 12),
                    Text(
                      'Edit Profile',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    prefixIcon: Icon(Icons.person_outline, color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Color(0xFF3498db),
                        width: 2,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 16,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () async {
                        final String newName = nameController.text.trim();
                        if (newName.isNotEmpty) {
                          await _updateAdminName(newName);
                          Navigator.of(context).pop();
                        }
                      },
                      child: Text(
                        'Save',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF3498db),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _fetchStats() async {
    try {
      final productsSnapshot =
          await FirebaseFirestore.instance.collection('products').get();
      final usersSnapshot =
          await FirebaseFirestore.instance.collection('users').get();
      setState(() {
        _productsCount = productsSnapshot.size;
        _usersCount =
            usersSnapshot.docs.where((doc) => doc['role'] != 'Admin').length;
      });
    } catch (e) {
      print('Error fetching stats: $e');
    }
  }

  Future<void> _fetchUsersFromFirebase() async {
    try {
      final QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('users').get();
      final List<UserModel> users =
          snapshot.docs.map((doc) {
            return UserModel(
              id: doc.id,
              name: doc['name']?.toString() ?? '',
              email: doc['email']?.toString() ?? '',
              role: doc['role']?.toString() ?? '',
            );
          }).toList();
      setState(() {
        _users =
            users
                .map(
                  (user) => {
                    'name': user.name,
                    'email': user.email,
                    'role': user.role,
                  },
                )
                .where((user) => user['role'] != 'Admin') // Exclude Admins
                .toList();
        _filteredUsers = _users;
        _usersCount = _users.length;
      });
    } catch (e) {
      print('Error fetching users: $e');
    }
  }

  void _filterUsers() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      _filteredUsers =
          _users.where((user) {
            return (user['name'].toLowerCase().contains(query) ||
                    user['email'].toLowerCase().contains(query)) &&
                user['role'] != 'Admin'; // Exclude Admins
          }).toList();
    });
  }

  void _showAddUserDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(Icons.person_add, color: Color(0xFF3498db), size: 28),
                    SizedBox(width: 12),
                    Text(
                      'Add User',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    prefixIcon: Icon(Icons.person_outline, color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Color(0xFF3498db),
                        width: 2,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined, color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Color(0xFF3498db),
                        width: 2,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock_outline, color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Color(0xFF3498db),
                        width: 2,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 16,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () async {
                        final String name = nameController.text.trim();
                        final String email = emailController.text.trim();
                        final String password = passwordController.text.trim();

                        if (name.isNotEmpty &&
                            email.isNotEmpty &&
                            password.isNotEmpty) {
                          try {
                            // Save current admin credentials
                            final currentUser =
                                FirebaseAuth.instance.currentUser;
                            final adminEmail = currentUser?.email;
                            // You must know the admin password or prompt for it
                            final adminPassword =
                                '123456'; // <-- Replace or prompt for this

                            // Create user in Firebase Authentication
                            UserCredential userCredential = await FirebaseAuth
                                .instance
                                .createUserWithEmailAndPassword(
                                  email: email,
                                  password: password,
                                );

                            // Add user to Firestore
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(userCredential.user!.uid)
                                .set({
                                  'name': name,
                                  'email': email,
                                  'role': 'Staff',
                                });

                            // Sign out from staff account
                            await FirebaseAuth.instance.signOut();

                            // Sign back in as admin
                            if (adminEmail != null &&
                                adminPassword.isNotEmpty) {
                              await FirebaseAuth.instance
                                  .signInWithEmailAndPassword(
                                    email: adminEmail,
                                    password: adminPassword,
                                  );
                            }

                            Navigator.of(context).pop(); // Close the dialog
                            _fetchUsersFromFirebase(); // Refresh the user list
                          } catch (e) {
                            print('Error adding user: $e');
                          }
                        }
                      },
                      child: Text(
                        'Add User',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF3498db),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180.0,
            floating: false,
            pinned: true,
            backgroundColor: Color(0xFF3498db),
            elevation: 4.0,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: false,
              titlePadding: EdgeInsets.only(left: 16.0, bottom: 16.0),
              title: Text(
                'Admin',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 22.0,
                  letterSpacing: 0.5,
                ),
              ),
              background: Container(
                color: Color(0xFF3498db),
                child: Stack(
                  children: [
                    Positioned(
                      right: -30,
                      top: 20,
                      child: Opacity(
                        opacity: 0.2,
                        child: Icon(
                          Icons.admin_panel_settings,
                          size: 150,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildProfileHeader(),
                _buildActionButtons(context),
                _buildStatsSection(),
                _buildUsersList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 45,
                  backgroundColor: Colors.white,
                  backgroundImage: NetworkImage(
                    'https://www.pngmart.com/files/21/Admin-Profile-PNG-Clipart.png',
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: CircleAvatar(
                    backgroundColor: Colors.green,
                    radius: 10,
                    child: Icon(Icons.check, size: 12, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            _adminName,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4),
          Text(
            'System Administrator',
            style: TextStyle(color: Colors.grey[700], fontSize: 16),
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.email_outlined, size: 16, color: Colors.blueGrey),
              SizedBox(width: 4),
              Text(
                _adminEmail.isEmpty ? 'admin@example.com' : _adminEmail,
                style: TextStyle(color: Colors.blueGrey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildActionButton(
            icon: Icons.edit,
            label: 'Edit Profile',
            onTap: () {
              _showEditNameDialog(context);
            },
            color: Colors.blue,
          ),
          SizedBox(width: 16),
          _buildActionButton(
            icon: Icons.logout,
            label: 'Logout',
            onTap: () {
              _showLogoutDialog(context);
            },
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Expanded(
      child: ElevatedButton.icon(
        icon: Icon(icon, color: Colors.white, size: 18),
        label: Text(label, style: TextStyle(color: Colors.white)),
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 8,
          backgroundColor: Colors.white,
          child: Container(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.logout_rounded,
                    color: Colors.red.shade400,
                    size: 32,
                  ),
                ),
                SizedBox(height: 24),
                Text(
                  'Logout',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Are you sure you want to logout?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    color: Colors.grey.shade600,
                  ),
                ),
                SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade100,
                          foregroundColor: Colors.grey.shade700,
                          elevation: 0,
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          logout();
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade400,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Logout',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStat(
                'Products',
                _productsCount.toString(),
                Icons.inventory_2_outlined,
              ),
              _buildStatDivider(),
              _buildStat('Users', _usersCount.toString(), Icons.people_outline),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.blueGrey, size: 24),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 4),
        Text(title, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(height: 40, width: 1, color: Colors.grey[300]);
  }

  Widget _buildUsersList() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Team Members',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  icon: Icon(Icons.add, size: 18),
                  label: Text('Add User'),
                  onPressed: () {
                    _showAddUserDialog(context);
                  },
                ),
              ],
            ),
          ),
          CustomSearchBar(
            controller: _searchController,
            hintText: 'Search users',
            onClear: () {},
          ),
          SizedBox(height: 25),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListView.separated(
              physics: NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: _filteredUsers.length,
              separatorBuilder: (context, index) => Divider(height: 1),
              itemBuilder: (context, index) {
                final user = _filteredUsers[index];
                return _buildUserListItem(
                  name: user['name'],
                  email: user['email'],
                  role: user['role'],
                  avatarUrl:
                      "https://www.pngmart.com/files/21/Admin-Profile-PNG-Clipart.png",
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, String email) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 8,
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.delete_forever_rounded,
                    color: Colors.red.shade400,
                    size: 36,
                  ),
                ),
                SizedBox(height: 24),
                Text(
                  'Delete User',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Are you sure you want to delete\n"$email"? This action cannot be undone.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    color: Colors.grey.shade600,
                  ),
                ),
                SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade100,
                          foregroundColor: Colors.grey.shade700,
                          elevation: 0,
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          try {
                            // Query to find user document by email
                            QuerySnapshot querySnapshot =
                                await FirebaseFirestore.instance
                                    .collection('users')
                                    .where('email', isEqualTo: email)
                                    .get();

                            // Delete the user document
                            if (querySnapshot.docs.isNotEmpty) {
                              // Get the user's UID
                              String userId = querySnapshot.docs.first.id;

                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(userId)
                                  .delete();

                              // --- Delete from Firebase Auth ---
                              // NOTE: You cannot delete another user from Firebase Auth directly from the client.
                              // This should be done via a Cloud Function or backend admin SDK.
                              // Example (pseudo-code):
                              // await FirebaseFunctions.instance.httpsCallable('deleteUserFromAuth').call({'uid': userId});
                            }

                            // Refresh the user list
                            _fetchUsersFromFirebase();

                            Navigator.of(context).pop(); // Close the dialog
                          } catch (e) {
                            print('Error deleting user: $e');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade400,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Delete',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserListItem({
    required String name,
    required String email,
    required String role,
    required String avatarUrl,
  }) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 6, horizontal: 2),
      elevation: 1.2,
      shadowColor: Colors.black.withOpacity(0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          leading: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 28,
              backgroundColor: Colors.grey.shade100,
              child: ClipOval(
                child: Image.network(
                  avatarUrl,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (context, error, stackTrace) => Container(
                        color:
                            role == 'Admin'
                                ? Color(0xFF3498db).withOpacity(0.1)
                                : Colors.grey.shade100,
                        child: Icon(
                          Icons.person,
                          size: 32,
                          color:
                              role == 'Admin'
                                  ? Color(0xFF3498db)
                                  : Colors.grey.shade400,
                        ),
                      ),
                ),
              ),
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    letterSpacing: 0.2,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      role == 'Admin'
                          ? Color(0xFF3498db).withOpacity(0.12)
                          : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color:
                        role == 'Admin'
                            ? Color(0xFF3498db).withOpacity(0.3)
                            : Colors.grey.shade300,
                    width: 0.5,
                  ),
                ),
                child: Text(
                  role,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color:
                        role == 'Admin'
                            ? Color(0xFF3498db)
                            : Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.email_outlined,
                      size: 14,
                      color: Colors.grey.shade500,
                    ),
                    SizedBox(width: 6),
                    Text(
                      email,
                      style: GoogleFonts.poppins(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          trailing: Material(
            color: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder:
                      (context) => Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 12,
                              offset: Offset(0, -5),
                            ),
                          ],
                        ),
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 40,
                              height: 4,
                              margin: EdgeInsets.only(bottom: 22),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 8,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.08),
                                          blurRadius: 8,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: CircleAvatar(
                                      backgroundImage: NetworkImage(avatarUrl),
                                      radius: 24,
                                      backgroundColor: Colors.grey.shade100,
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 17,
                                          color: Colors.grey.shade800,
                                        ),
                                      ),
                                      SizedBox(height: 3),
                                      Text(
                                        email,
                                        style: GoogleFonts.poppins(
                                          color: Colors.grey.shade600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Divider(height: 32, thickness: 0.8),
                            ListTile(
                              leading: Container(
                                padding: EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.delete_outline,
                                  color: Colors.red.shade700,
                                  size: 22,
                                ),
                              ),
                              title: Text(
                                'Delete User',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                              subtitle: Text(
                                'This action cannot be undone',
                                style: GoogleFonts.poppins(
                                  fontSize: 13.5,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                _showDeleteConfirmation(context, email);
                              },
                            ),
                            Padding(
                              padding: const EdgeInsets.all(20),
                              child: ElevatedButton(
                                onPressed: () => Navigator.pop(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey.shade100,
                                  foregroundColor: Colors.grey.shade800,
                                  elevation: 0,
                                  padding: EdgeInsets.symmetric(vertical: 14),
                                  minimumSize: Size(double.infinity, 50),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  'Cancel',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                );
              },
              child: Padding(
                padding: EdgeInsets.all(8),
                child: Icon(
                  Icons.more_vert_rounded,
                  color: Colors.grey.shade700,
                  size: 22,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
