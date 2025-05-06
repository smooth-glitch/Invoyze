import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_inventory_app/auth/auth_func.dart';
import 'package:smart_inventory_app/components/custom_search_bar.dart';
import 'package:smart_inventory_app/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:smart_inventory_app/models/invoice_model.dart';
import 'package:smart_inventory_app/screens/create_invoice_screen.dart';
import 'package:smart_inventory_app/screens/invoice_detail_screen.dart';

class StaffScreen extends StatefulWidget {
  final UserModel user;
  const StaffScreen({super.key, required this.user});

  @override
  _StaffScreenState createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF3F51B5); // Indigo
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Invoyze',
          style: GoogleFonts.poppins(
            fontSize: isSmallScreen ? 20 : 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          //* Logout Button
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: Text(
                      'Logout',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: primaryColor,
                      ),
                    ),
                    content: Text(
                      'Are you sure you want to logout?',
                      style: GoogleFonts.poppins(),
                    ),
                    actions: [
                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey[700],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          final _auth = AuthFunc();
                          _auth.signOut();
                        },
                        child: Text(
                          'Logout',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                    contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                    actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  );
                },
              );
            },
          ),
        ],
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              // ignore: deprecated_member_use
              colors: [primaryColor, primaryColor.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 4,
      ),
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [const Color(0xFFEEEEFF), Colors.white],
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(screenSize.width * 0.04),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: screenSize.height * 0.015),
                Card(
                  elevation: 2,
                  shadowColor: Colors.black26,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(screenSize.width * 0.04),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: isSmallScreen ? 30 : 40,
                          backgroundColor: primaryColor.withOpacity(0.2),
                          child: Text(
                            widget.user.name![0].toUpperCase(),
                            style: GoogleFonts.poppins(
                              fontSize: isSmallScreen ? 22 : 28,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        ),
                        SizedBox(width: screenSize.width * 0.04),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.user.name!,
                                style: GoogleFonts.poppins(
                                  fontSize: isSmallScreen ? 16 : 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: screenSize.height * 0.008),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: screenSize.width * 0.03,
                                  vertical: screenSize.height * 0.006,
                                ),
                                decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  widget.user.role!,
                                  style: GoogleFonts.poppins(
                                    fontSize: isSmallScreen ? 12 : 14,
                                    color: primaryColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              SizedBox(height: screenSize.height * 0.008),
                              Row(
                                children: [
                                  Icon(
                                    Icons.email_outlined,
                                    size: isSmallScreen ? 14 : 16,
                                    color: Colors.grey[600],
                                  ),
                                  SizedBox(width: screenSize.width * 0.02),
                                  Expanded(
                                    child: Text(
                                      widget.user.email!,
                                      style: GoogleFonts.poppins(
                                        fontSize: isSmallScreen ? 12 : 14,
                                        color: Colors.grey[700],
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: screenSize.height * 0.02),

                // Statistics Cards
                StreamBuilder<QuerySnapshot>(
                  stream:
                      FirebaseFirestore.instance
                          .collection('products')
                          .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: SizedBox(
                          height: screenSize.height * 0.25,
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error loading data',
                          style: GoogleFonts.poppins(color: Colors.red),
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildStatCard(
                                "Total Inventory",
                                "£0",
                                Colors.blue,
                                context,
                              ),
                              _buildStatCard(
                                "Total Products",
                                "0",
                                Colors.green,
                                context,
                              ),
                            ],
                          ),
                          SizedBox(height: screenSize.height * 0.015),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildStatCard(
                                "Low Stock",
                                "0 Items",
                                Colors.orange,
                                context,
                              ),
                              _buildStatCard(
                                "Avg Price",
                                "£0",
                                Colors.purple,
                                context,
                              ),
                            ],
                          ),
                        ],
                      );
                    }

                    final products = snapshot.data!.docs;
                    int totalProducts = products.length;
                    double totalInventory = products.fold(
                      0.0,
                      // ignore: avoid_types_as_parameter_names
                      (sum, product) =>
                          sum +
                          ((product['price'] as num? ?? 0) *
                              (product['quantity'] as num? ?? 0)),
                    );
                    int lowStock =
                        products
                            .where(
                              (product) =>
                                  (product['quantity'] as num? ?? 0) < 5,
                            )
                            .length;

                    return StreamBuilder<QuerySnapshot>(
                      stream:
                          FirebaseFirestore.instance
                              .collection('invoices')
                              .snapshots(),
                      builder: (context, salesSnapshot) {
                        // ignore: unused_local_variable
                        double totalSales = 0.0;

                        if (salesSnapshot.hasData) {
                          totalSales = salesSnapshot.data!.docs.fold(
                            0.0,
                            // ignore: avoid_types_as_parameter_names
                            (sum, invoice) =>
                                sum +
                                ((invoice['totalAmount'] as num?)?.toDouble() ??
                                    0.0),
                          );
                        }

                        return Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildStatCard(
                                  "Total Inventory",
                                  "£${totalInventory.toStringAsFixed(0)}",
                                  Colors.blue,
                                  context,
                                ),
                                _buildStatCard(
                                  "Total Products",
                                  totalProducts.toString(),
                                  Colors.green,
                                  context,
                                ),
                              ],
                            ),
                            SizedBox(height: screenSize.height * 0.015),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildStatCard(
                                  "Low Stock",
                                  "$lowStock Items",
                                  Colors.orange,
                                  context,
                                ),
                                _buildStatCard(
                                  "Avg Price",
                                  // ignore: avoid_types_as_parameter_names
                                  "£${(products.fold(0.0, (sum, product) => sum + ((product['price'] as num?)?.toDouble() ?? 0.0)) / (totalProducts > 0 ? totalProducts : 1)).toStringAsFixed(0)}",
                                  Colors.purple,
                                  context,
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),

                SizedBox(height: screenSize.height * 0.02),

                CustomSearchBar(
                  controller: _searchController,
                  hintText: 'Search Invoice',
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                  onClear: () {},
                ),

                // Invoice List Section
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream:
                        FirebaseFirestore.instance
                            .collection('invoices')
                            .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error: ${snapshot.error}',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.red,
                            ),
                          ),
                        );
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final invoices =
                          snapshot.data!.docs.map((doc) {
                            DateTime parseDate(dynamic date) {
                              if (date is Timestamp) {
                                return date.toDate();
                              } else if (date is String) {
                                return DateTime.parse(date);
                              }
                              return DateTime.now();
                            }

                            return InvoiceModel(
                              id: doc.id,
                              customerName:
                                  doc['customerName'] ?? 'Unknown Customer',
                              totalAmount:
                                  (doc['totalAmount'] as num?)?.toDouble() ??
                                  0.0,
                              date: parseDate(doc['date']),
                              products: List<Map<String, dynamic>>.from(
                                doc['products'] ?? [],
                              ),
                            );
                          }).toList();

                      final filteredInvoices =
                          invoices.where((invoice) {
                            return invoice.customerName.toLowerCase().contains(
                                  _searchQuery,
                                ) ||
                                invoice.id.toLowerCase().contains(_searchQuery);
                          }).toList();

                      return ListView.builder(
                        itemCount: filteredInvoices.length,
                        itemBuilder: (context, index) {
                          final invoice = filteredInvoices[index];
                          return _buildInvoiceCard(context, invoice);
                        },
                      );
                    },
                  ),
                ),
                SizedBox(height: screenSize.height * 0.02),

                // Create Invoice Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CreateInvoiceScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: screenSize.height * 0.018,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                    ),
                    icon: Icon(
                      Icons.receipt_long,
                      size: isSmallScreen ? 20 : 24,
                    ),
                    label: Text(
                      'Create Invoice',
                      style: GoogleFonts.poppins(
                        fontSize: isSmallScreen ? 16 : 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: screenSize.height * 0.015),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInvoiceCard(BuildContext context, InvoiceModel invoice) {
    final DateFormat dateFormatter = DateFormat('dd MMM yyyy');
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      // ignore: deprecated_member_use
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => InvoiceDetailScreen(invoice: invoice),
            ),
          );
        },
        child: Padding(
          padding: EdgeInsets.all(screenSize.width * 0.04),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dateFormatter.format(invoice.date),
                style: GoogleFonts.poppins(
                  color: Colors.grey[600],
                  fontSize: isSmallScreen ? 10 : 12,
                ),
              ),
              SizedBox(height: screenSize.height * 0.01),
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.blue.withOpacity(0.1),
                    child: Icon(
                      Icons.person,
                      color: Colors.blue,
                      size: isSmallScreen ? 24 : 28,
                    ),
                  ),
                  SizedBox(width: screenSize.width * 0.03),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        invoice.customerName,
                        style: GoogleFonts.poppins(
                          fontSize: isSmallScreen ? 14 : 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${invoice.products.length} items',
                        style: GoogleFonts.poppins(
                          fontSize: isSmallScreen ? 10 : 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenSize.width * 0.03,
                      vertical: screenSize.height * 0.006,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '£${invoice.totalAmount.toStringAsFixed(0)}',
                      style: GoogleFonts.poppins(
                        fontSize: isSmallScreen ? 14 : 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _buildStatCard(
  String title,
  String value,
  Color color,
  BuildContext context,
) {
  final screenSize = MediaQuery.of(context).size;
  final isSmallScreen = screenSize.width < 360;

  return Container(
    height: screenSize.height * 0.12,
    width: screenSize.width * 0.44,
    padding: EdgeInsets.all(screenSize.width * 0.03),
    decoration: BoxDecoration(
      color: color.withOpacity(0.2),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: isSmallScreen ? 12 : 14,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: isSmallScreen ? 16 : 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    ),
  );
}
