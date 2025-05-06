import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_inventory_app/components/custom_search_bar.dart';
import 'package:smart_inventory_app/models/invoice_model.dart';
import 'package:smart_inventory_app/screens/invoice_detail_screen.dart';

class InvoiceListScreen extends StatefulWidget {
  @override
  _InvoiceListScreenState createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends State<InvoiceListScreen> {
  final TextEditingController invoiceController = TextEditingController();
  String _searchQuery = '';
  final DateFormat _dateFormatter = DateFormat('dd MMM yyyy');
  List<InvoiceModel> _allInvoices = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  void _loadInvoices() {
    FirebaseFirestore.instance
        .collection('invoices')
        .snapshots()
        .listen(
          (snapshot) {
            if (mounted) {
              setState(() {
                _allInvoices =
                    snapshot.docs.map((doc) {
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
                        customerName: doc['customerName'] ?? 'Unknown Customer',
                        totalAmount:
                            (doc['totalAmount'] as num?)?.toDouble() ?? 0.0,
                        date: parseDate(doc['date']),
                        products: List<Map<String, dynamic>>.from(
                          doc['products'] ?? [],
                        ),
                      );
                    }).toList();
                _isLoading = false;
              });
            }
          },
          onError: (error) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
        );
  }

  List<InvoiceModel> get _filteredInvoices {
    return _allInvoices.where((invoice) {
      return invoice.customerName.toLowerCase().contains(_searchQuery) ||
          invoice.id.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  @override
  void dispose() {
    invoiceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          "Invoices",
          style: GoogleFonts.poppins(
            fontSize: screenWidth * 0.05,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        iconTheme: IconThemeData(color: Colors.black87),
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(screenWidth * 0.04),
                    color: Colors.white,
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Summary',
                          style: GoogleFonts.poppins(
                            fontSize: screenWidth * 0.04,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        screenWidth < 600
                            ? Column(
                              children: [
                                _buildSummaryCard(
                                  'Total Invoices',
                                  '${_filteredInvoices.length}',
                                  Icons.receipt_long,
                                  Colors.blue,
                                  screenWidth: screenWidth,
                                ),
                                SizedBox(height: screenHeight * 0.01),
                                _buildSummaryCard(
                                  'Total Revenue',
                                  '\£${_calculateTotalRevenue(_filteredInvoices).toStringAsFixed(0)}',
                                  Icons.attach_money,
                                  Colors.green,
                                  screenWidth: screenWidth,
                                ),
                              ],
                            )
                            : Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                      right: screenWidth * 0.02,
                                    ),
                                    child: _buildSummaryCard(
                                      'Total Invoices',
                                      '${_filteredInvoices.length}',
                                      Icons.receipt_long,
                                      Colors.blue,
                                      screenWidth: screenWidth,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                      left: screenWidth * 0.02,
                                    ),
                                    child: _buildSummaryCard(
                                      'Total Revenue',
                                      '\£${_calculateTotalRevenue(_filteredInvoices).toStringAsFixed(0)}',
                                      Icons.attach_money,
                                      Colors.green,
                                      screenWidth: screenWidth,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(screenWidth * 0.04),
                    child: CustomSearchBar(
                      hintText: 'Search Invoices',
                      controller: invoiceController,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value.toLowerCase();
                        });
                      },
                      onClear: () {},
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.04,
                    ),
                    child: Text(
                      'Recent Invoices',
                      style: GoogleFonts.poppins(
                        fontSize: screenWidth * 0.04,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.04,
                      ),
                      itemCount: _filteredInvoices.length,
                      itemBuilder: (context, index) {
                        final invoice = _filteredInvoices[index];
                        return _buildInvoiceCard(context, invoice, screenWidth);
                      },
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildInvoiceCard(
    BuildContext context,
    InvoiceModel invoice,
    double screenWidth,
  ) {
    return Card(
      margin: EdgeInsets.only(bottom: screenWidth * 0.03),
      elevation: 2,
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
          padding: EdgeInsets.all(screenWidth * 0.04),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _dateFormatter.format(invoice.date),
                style: GoogleFonts.poppins(
                  color: Colors.grey[600],
                  fontSize: screenWidth * 0.03,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: screenWidth * 0.03),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.blue.withOpacity(0.1),
                    child: Icon(
                      Icons.person,
                      color: Colors.blue,
                      size: screenWidth * 0.05,
                    ),
                    radius: screenWidth * 0.035,
                  ),
                  SizedBox(width: screenWidth * 0.03),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          invoice.customerName,
                          style: GoogleFonts.poppins(
                            fontSize: screenWidth * 0.04,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        Text(
                          '${invoice.products.length} items',
                          style: GoogleFonts.poppins(
                            fontSize: screenWidth * 0.03,
                            color: Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.03,
                      vertical: screenWidth * 0.015,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '\£${invoice.totalAmount.toStringAsFixed(0)}',
                      style: GoogleFonts.poppins(
                        fontSize: screenWidth * 0.035,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: screenWidth * 0.03),
              Divider(height: 1, thickness: 1, color: Colors.grey[200]),
              SizedBox(height: screenWidth * 0.03),
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => InvoiceDetailScreen(invoice: invoice),
                      ),
                    );
                  },
                  icon: Icon(
                    Icons.visibility_outlined,
                    size: screenWidth * 0.05,
                  ),
                  label: Text(
                    'View',
                    style: GoogleFonts.poppins(
                      fontSize: screenWidth * 0.035,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: TextButton.styleFrom(foregroundColor: Colors.blue),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _calculateTotalRevenue(List<InvoiceModel> invoices) {
    return invoices.fold(0, (sum, invoice) => sum + invoice.totalAmount);
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    required double screenWidth,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(screenWidth * 0.02),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: screenWidth * 0.05),
          ),
          SizedBox(width: screenWidth * 0.03),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: screenWidth * 0.03,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: screenWidth * 0.04,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
