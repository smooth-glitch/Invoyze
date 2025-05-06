import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_inventory_app/models/product_model.dart';

class CsvUploadScreen extends StatefulWidget {
  const CsvUploadScreen({super.key});

  @override
  State<CsvUploadScreen> createState() => _CsvUploadScreenState();
}

class _CsvUploadScreenState extends State<CsvUploadScreen> {
  bool _isUploading = false;
  String _statusMessage = "No file selected.";

  Future<File?> _pickCsvFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (result != null && result.files.single.path != null) {
      return File(result.files.single.path!);
    }
    return null;
  }

  Future<List<ProductModel>> _parseCsv(File file) async {
    final csvString = await file.readAsString();
    final List<List<dynamic>> csvData = const CsvToListConverter().convert(
      csvString,
      eol: '\n',
    );
    List<ProductModel> products = [];

    for (int i = 1; i < csvData.length; i++) {
      final row = csvData[i];
      products.add(
        ProductModel(
          id: row[0].toString(),
          name: row[1].toString(),
          description: row[2].toString(),
          price: double.tryParse(row[3].toString()) ?? 0.0,
          quantity: int.tryParse(row[4].toString()) ?? 0,
          imageUrl: row[5].toString(),
        ),
      );
    }
    return products;
  }

  Future<void> _uploadProducts(List<ProductModel> products) async {
    final collection = FirebaseFirestore.instance.collection('products');
    for (var product in products) {
      await collection.doc(product.id).set(product.toJson());
    }
  }

  Future<void> _handleCsvUpload() async {
    setState(() {
      _isUploading = true;
      _statusMessage = "Uploading products...";
    });

    try {
      final file = await _pickCsvFile();
      if (file == null) {
        setState(() {
          _statusMessage = "No file selected.";
          _isUploading = false;
        });
        return;
      }

      final products = await _parseCsv(file);
      await _uploadProducts(products);

      setState(() {
        _statusMessage =
            "Upload successful! ${products.length} products added.";
        _isUploading = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = "Error: ${e.toString()}";
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Card(
              elevation: 10,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Upload Product CSV",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade900,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _statusMessage,
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.upload_file),
                        label: Text(
                          _isUploading ? "Uploading..." : "Select & Upload CSV",
                        ),
                        onPressed: _isUploading ? null : _handleCsvUpload,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                        ),
                      ),
                    ),
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
