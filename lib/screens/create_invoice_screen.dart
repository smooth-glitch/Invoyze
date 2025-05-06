import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_inventory_app/screens/qr_code_scanner.dart';
import 'package:smart_inventory_app/models/invoice_model.dart';

class CreateInvoiceScreen extends StatefulWidget {
  const CreateInvoiceScreen({super.key});

  @override
  State<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {
  final TextEditingController _nameController = TextEditingController();
  final List<Map<String, dynamic>> _products = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  void _scanQRCode() async {
    final String? scannedCode = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QRCodeScannerScreen()),
    );

    if (scannedCode != null) {
      try {
        final productSnapshot =
            await _firestore.collection('products').doc(scannedCode).get();

        if (productSnapshot.exists) {
          setState(() {
            _products.add({
              'id': scannedCode,
              'name': productSnapshot['name'],
              'price': productSnapshot['price'] ?? 0, // Fetch price
              'quantity': 1,
            });
          });
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Product added')));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product not found in database')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error fetching product: $e')));
      }
    }
  }

  void _updateQuantity(int index, int quantity) {
    setState(() {
      _products[index]['quantity'] = quantity;
    });
  }

  double _calculateTotal() {
    return _products.fold(
      0,
      (sum, product) => sum + (product['quantity'] * (product['price'] ?? 0)),
    );
  }

  void _saveInvoice() async {
    if (_formKey.currentState!.validate() && _products.isNotEmpty) {
      try {
        final invoice = InvoiceModel(
          id: '', // Firebase will generate the ID
          customerName: _nameController.text,
          totalAmount: _calculateTotal(), // Use the helper method
          date: DateTime.now(),
          products: _products,
        );

        await _firestore.collection('invoices').add(invoice.toMap());

        // Reduce product quantities in the products collection
        for (var product in _products) {
          final productRef = _firestore
              .collection('products')
              .doc(product['id']);
          await _firestore.runTransaction((transaction) async {
            final snapshot = await transaction.get(productRef);
            if (snapshot.exists) {
              final currentQuantity = snapshot['quantity'] ?? 0;
              final newQuantity = currentQuantity - product['quantity'];
              transaction.update(productRef, {'quantity': newQuantity});
            }
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invoice saved successfully')),
        );
        setState(() {
          _nameController.clear();
          _products.clear();
        });
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving invoice: $e')));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields and add products'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Create Invoice',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(color: Colors.white),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Customer Information',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TextFormField(
                        controller: _nameController,
                        style: GoogleFonts.poppins(),
                        decoration: InputDecoration(
                          labelText: 'Customer Name',
                          labelStyle: GoogleFonts.poppins(
                            color: Colors.grey.shade700,
                          ),
                          prefixIcon: const Icon(
                            Icons.person_outline,
                            color: Colors.blue,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Name is required';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Products',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _scanQRCode,
                        icon: const Icon(Icons.qr_code_scanner, size: 20),
                        label: Text(
                          'Scan Product',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _products.isEmpty
                      ? Container(
                        height: 200,
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.shopping_cart_outlined,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No products added yet',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Scan a product QR code to add items',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      )
                      : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _products.length,
                        itemBuilder: (context, index) {
                          final product = _products[index];
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.only(bottom: 12.0),
                            child: Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0),
                                side: BorderSide(color: Colors.grey.shade200),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            product['name'],
                                            style: GoogleFonts.poppins(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          '\$${product['price']?.toStringAsFixed(2) ?? '0.00'}',
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.blue,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            color: Colors.red,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _products.removeAt(index);
                                            });
                                          },
                                          tooltip: 'Remove item',
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Text(
                                          'Quantity:',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                        const Spacer(),
                                        Container(
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: Colors.grey.shade300,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              _QuantityButton(
                                                icon: Icons.remove,
                                                onPressed: () {
                                                  if (product['quantity'] > 1) {
                                                    _updateQuantity(
                                                      index,
                                                      product['quantity'] - 1,
                                                    );
                                                  }
                                                },
                                              ),
                                              Container(
                                                width: 40,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 8,
                                                    ),
                                                decoration: BoxDecoration(
                                                  border: Border(
                                                    left: BorderSide(
                                                      color:
                                                          Colors.grey.shade300,
                                                    ),
                                                    right: BorderSide(
                                                      color:
                                                          Colors.grey.shade300,
                                                    ),
                                                  ),
                                                ),
                                                child: Text(
                                                  product['quantity']
                                                      .toString(),
                                                  style: GoogleFonts.poppins(
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                              _QuantityButton(
                                                icon: Icons.add,
                                                onPressed: () {
                                                  _updateQuantity(
                                                    index,
                                                    product['quantity'] + 1,
                                                  );
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                  const SizedBox(height: 16),
                  if (_products.isNotEmpty)
                    Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Amount:',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '\$${_calculateTotal().toStringAsFixed(2)}',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveInvoice,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Create Invoice',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  // Add padding at bottom to avoid content being hidden behind software keyboard
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _QuantityButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Icon(icon, size: 16, color: Colors.grey[700]),
      ),
    );
  }
}
