import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_inventory_app/models/product_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductDetailScreen extends StatefulWidget {
  final ProductModel product;

  const ProductDetailScreen({Key? key, required this.product})
    : super(key: key);

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late ProductModel product;

  @override
  void initState() {
    super.initState();
    product = widget.product;
  }

  String getFormattedDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.black87),
        title: Text(
          "Product Details",
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Image
            Container(
              height: 220,
              width: double.infinity,
              color: Colors.white,
              padding: EdgeInsets.all(20),
              child: Center(
                child:
                    product.imageUrl.isNotEmpty
                        ? Image.network(product.imageUrl, fit: BoxFit.contain)
                        : Icon(
                          Icons.image_not_supported_outlined,
                          size: 80,
                          color: Colors.grey[400],
                        ),
              ),
            ),

            // Details Card
            Container(
              margin: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    spreadRadius: 0,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header section with name and price
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                '£${product.price.toStringAsFixed(0)}',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _getQuantityColor(
                                  product.quantity,
                                ).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                'Stock: ${product.quantity}',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: _getQuantityColor(product.quantity),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  Divider(height: 1, thickness: 1, color: Colors.grey[200]),

                  // Description
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Description',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          product.description,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[600],
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Divider(height: 1, thickness: 1, color: Colors.grey[200]),

                  // Product Details
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Product Details',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 16),

                        _buildDetailRow(
                          Icons.inventory_2_outlined,
                          'SKU',
                          'SKU-${product.id}',
                        ),
                        SizedBox(height: 12),

                        _buildDetailRow(
                          Icons.history_outlined,
                          'Last Updated',
                          getFormattedDate(DateTime.now()),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              spreadRadius: 0,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  _showUpdateStockDialog(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Update Stock',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUpdateStockDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController();
    bool isAdd = true; // toggle state for adding/removing

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                'Update Stock Quantity',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Add/Remove toggle with improved styling
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: Text(
                              'Add Stock',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w500,
                                color: isAdd ? Colors.white : Colors.black87,
                              ),
                            ),
                            selected: isAdd,
                            selectedColor: Colors.blue,
                            onSelected:
                                (_) => dialogSetState(() => isAdd = true),
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: ChoiceChip(
                            label: Text(
                              'Remove Stock',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w500,
                                color: !isAdd ? Colors.white : Colors.black87,
                              ),
                            ),
                            selected: !isAdd,
                            selectedColor: Colors.blue,
                            onSelected:
                                (_) => dialogSetState(() => isAdd = false),
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: isAdd ? 'Units to add' : 'Units to remove',
                      hintText: 'Enter quantity',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.blue, width: 2),
                      ),
                      prefixIcon: Icon(
                        isAdd
                            ? Icons.add_circle_outline
                            : Icons.remove_circle_outline,
                        color: isAdd ? Colors.green : Colors.red,
                      ),
                      suffixText: 'units',
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Current stock: ',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '${product.quantity} units',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _getQuantityColor(product.quantity),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text('Cancel', style: GoogleFonts.poppins()),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () async {
                          final int? qty = int.tryParse(controller.text);
                          if (qty != null && qty > 0) {
                            try {
                              final docRef = FirebaseFirestore.instance
                                  .collection('products')
                                  .doc(product.id);
                              await docRef.update({
                                'quantity': FieldValue.increment(
                                  isAdd ? qty : -qty,
                                ),
                              });
                              final updated = await docRef.get();
                              if (updated.exists) {
                                setState(() {
                                  product = product.copyWith(
                                    quantity:
                                        updated.data()?['quantity'] ??
                                        product.quantity,
                                  );
                                });
                              }
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: Colors.green[700],
                                  content: Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: Colors.white,
                                      ),
                                      SizedBox(width: 12),
                                      Text(
                                        isAdd
                                            ? 'Stock added successfully!'
                                            : 'Stock removed successfully!',
                                        style: GoogleFonts.poppins(),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            } catch (e) {
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to update stock: $e'),
                                ),
                              );
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Enter a valid positive number'),
                              ),
                            );
                          }
                        },
                        child: Text('Apply', style: GoogleFonts.poppins()),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.blue, size: 20),
        ),
        SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
            ),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _getQuantityColor(int quantity) {
    if (quantity <= 10) {
      return Colors.red;
    } else if (quantity <= 30) {
      return Colors.orange;
    }
    return Colors.green;
  }
}
