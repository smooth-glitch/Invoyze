import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();

  bool _isLoading = false;
  bool _isValidImageUrl = false;

  void _updateImageUrl() {
    if (!mounted) return;
    setState(() {
      _isValidImageUrl =
          _imageUrlController.text.isNotEmpty &&
          (Uri.tryParse(_imageUrlController.text)?.hasAbsolutePath ?? false);
    });
  }

  @override
  void initState() {
    super.initState();
    _imageUrlController.addListener(_updateImageUrl);
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Create a document reference with auto-generated ID
      final docRef = FirebaseFirestore.instance.collection('products').doc();

      final product = ProductModel(
        id: docRef.id, // Use the Firestore document ID
        name: _nameController.text,
        description: _descriptionController.text,
        price: double.parse(_priceController.text),
        quantity: int.parse(_quantityController.text),
        imageUrl: _imageUrlController.text,
      );

      // Save the product using the document reference
      await docRef.set(product.toJson());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product added successfully!')),
        );

        // Clear the form
        _nameController.clear();
        _descriptionController.clear();
        _priceController.clear();
        _quantityController.clear();
        _imageUrlController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error adding product: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _imageUrlController.removeListener(_updateImageUrl);
    _imageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Create a blue theme
    final theme = Theme.of(context).copyWith(
      primaryColor: Colors.blue,
      colorScheme: ColorScheme.fromSwatch(
        primarySwatch: Colors.blue,
        accentColor: Colors.blueAccent,
      ),
    );

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Add New Product'),
        centerTitle: true,
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 20.0,
                  ),
                  child: Card(
                    elevation: 2.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Header
                            Text(
                              'Product Information',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.primaryColor,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Image URL preview
                            Card(
                              elevation: 1.0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: Colors.grey.shade300),
                              ),
                              child: Container(
                                height: 220,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child:
                                    _isValidImageUrl
                                        ? ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          child: Image.network(
                                            _imageUrlController.text,
                                            fit: BoxFit.cover,
                                            errorBuilder: (
                                              context,
                                              error,
                                              stackTrace,
                                            ) {
                                              return Center(
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons.error_outline,
                                                      size: 40,
                                                      color: Colors.red[400],
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      'Invalid image URL',
                                                      style: TextStyle(
                                                        color: Colors.red[700],
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                        )
                                        : Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(16),
                                              decoration: BoxDecoration(
                                                color: Colors.grey[100],
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                Icons.image_outlined,
                                                size: 60,
                                                color: theme.primaryColor
                                                    .withOpacity(0.6),
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              'Product Image Preview',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w500,
                                                color: Colors.grey[700],
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Enter image URL below',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Image URL
                            TextFormField(
                              controller: _imageUrlController,
                              decoration: InputDecoration(
                                labelText: 'Image URL',
                                hintText: 'https://example.com/image.jpg',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: theme.primaryColor,
                                    width: 2,
                                  ),
                                ),
                                prefixIcon: Icon(
                                  Icons.link,
                                  color: theme.primaryColor,
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              keyboardType: TextInputType.url,
                              textInputAction: TextInputAction.next,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter an image URL';
                                }
                                if (!(Uri.tryParse(value)?.hasAbsolutePath ??
                                    false)) {
                                  return 'Please enter a valid URL';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),

                            // Product Details Section
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      left: 4,
                                      bottom: 12,
                                    ),
                                    child: Text(
                                      'Basic Details',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: theme.primaryColor,
                                      ),
                                    ),
                                  ),
                                  // Product Name
                                  TextFormField(
                                    controller: _nameController,
                                    decoration: InputDecoration(
                                      labelText: 'Product Name',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      prefixIcon: const Icon(Icons.inventory),
                                      filled: true,
                                      fillColor: Colors.white,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            vertical: 12,
                                            horizontal: 16,
                                          ),
                                    ),
                                    textCapitalization:
                                        TextCapitalization.words,
                                    textInputAction: TextInputAction.next,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter product name';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),

                                  // Description
                                  TextFormField(
                                    controller: _descriptionController,
                                    decoration: InputDecoration(
                                      labelText: 'Description',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      prefixIcon: const Icon(Icons.description),
                                      alignLabelWithHint: true,
                                      filled: true,
                                      fillColor: Colors.white,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            vertical: 16,
                                            horizontal: 16,
                                          ),
                                    ),
                                    maxLines: 3,
                                    textCapitalization:
                                        TextCapitalization.sentences,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter product description';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Price and Quantity Section
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      left: 4,
                                      bottom: 12,
                                    ),
                                    child: Text(
                                      'Inventory Information',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: theme.primaryColor,
                                      ),
                                    ),
                                  ),
                                  // Price and Quantity in a row
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          controller: _priceController,
                                          decoration: InputDecoration(
                                            labelText: 'Price',
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            prefixIcon: const Icon(
                                              Icons.attach_money,
                                            ),
                                            filled: true,
                                            fillColor: Colors.white,
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  vertical: 12,
                                                  horizontal: 16,
                                                ),
                                          ),
                                          keyboardType:
                                              const TextInputType.numberWithOptions(
                                                decimal: true,
                                              ),
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'Required';
                                            }
                                            if (double.tryParse(value) ==
                                                null) {
                                              return 'Invalid number';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: TextFormField(
                                          controller: _quantityController,
                                          decoration: InputDecoration(
                                            labelText: 'Quantity',
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            prefixIcon: const Icon(
                                              Icons.inventory_2,
                                            ),
                                            filled: true,
                                            fillColor: Colors.white,
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  vertical: 12,
                                                  horizontal: 16,
                                                ),
                                          ),
                                          keyboardType: TextInputType.number,
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'Required';
                                            }
                                            if (int.tryParse(value) == null) {
                                              return 'Invalid number';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Action Buttons
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () {
                                      // Clear form fields
                                      _nameController.clear();
                                      _descriptionController.clear();
                                      _priceController.clear();
                                      _quantityController.clear();
                                      _imageUrlController.clear();
                                    },
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(
                                        color: theme.primaryColor,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 15,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text('CLEAR'),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  flex: 2,
                                  child: ElevatedButton(
                                    onPressed: _saveProduct,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: theme.primaryColor,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 15,
                                      ),
                                      textStyle: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      elevation: 2,
                                    ),
                                    child: const Text('ADD PRODUCT'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
    );
  }
}
