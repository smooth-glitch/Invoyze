import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_file/open_file.dart';
import 'package:smart_inventory_app/models/invoice_model.dart';

class InvoiceDetailScreen extends StatelessWidget {
  final InvoiceModel invoice;

  const InvoiceDetailScreen({Key? key, required this.invoice})
    : super(key: key);

  String getFormattedDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  Future<void> _downloadPdf(BuildContext context) async {
    try {
      final pdf = await generatePdf();
      final directory = await getExternalStorageDirectory();
      final downloadsPath = '${directory?.path}/Download';
      final downloadsDirectory = Directory(downloadsPath);

      if (!await downloadsDirectory.exists()) {
        await downloadsDirectory.create(recursive: true);
      }

      final file = File('$downloadsPath/invoice_${invoice.id}.pdf');
      await file.writeAsBytes(await pdf.save());

      // Open the downloaded file
      await OpenFile.open(file.path);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF downloaded successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to download PDF: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<pw.Document> generatePdf() async {
    final pdf = pw.Document();
    final fontData = await rootBundle.load("assets/fonts/Poppins-Regular.ttf");
    final ttf = pw.Font.ttf(fontData);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildPdfHeader(ttf),
              pw.SizedBox(height: 20),
              _buildInvoiceInfo(ttf),
              pw.SizedBox(height: 20),
              _buildCustomerInfo(ttf),
              pw.SizedBox(height: 20),
              _buildProductTable(ttf),
              pw.SizedBox(height: 20),
              _buildTotalSection(ttf),
              pw.SizedBox(height: 20),
              _buildNotesSection(ttf),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  pw.Widget _buildPdfHeader(pw.Font font) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          "INVOICE",
          style: pw.TextStyle(
            font: font,
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.Text(
          getFormattedDate(invoice.date),
          style: pw.TextStyle(font: font, fontSize: 12),
        ),
      ],
    );
  }

  pw.Widget _buildInvoiceInfo(pw.Font font) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              "Invoice #${invoice.id}",
              style: pw.TextStyle(
                font: font,
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.Text(
              "Status: PAID",
              style: pw.TextStyle(
                font: font,
                fontSize: 12,
                color: PdfColors.green,
              ),
            ),
          ],
        ),
        pw.Text(
          "Smart Inventory App",
          style: pw.TextStyle(
            font: font,
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildCustomerInfo(pw.Font font) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          "BILL TO",
          style: pw.TextStyle(
            font: font,
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          invoice.customerName,
          style: pw.TextStyle(font: font, fontSize: 12),
        ),
      ],
    );
  }

  pw.Widget _buildProductTable(pw.Font font) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 1),
      columnWidths: {
        0: const pw.FlexColumnWidth(4),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(3),
        3: const pw.FlexColumnWidth(3),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _buildTableHeader("ITEM", font),
            _buildTableHeader("QTY", font),
            _buildTableHeader("PRICE", font),
            _buildTableHeader("TOTAL", font),
          ],
        ),
        ...invoice.products.map((product) {
          final total = product["price"] * product["quantity"];
          return pw.TableRow(
            children: [
              _buildTableCell(product["name"], font),
              _buildTableCell(product["quantity"].toString(), font),
              _buildTableCell("£${product["price"].toStringAsFixed(2)}", font),
              _buildTableCell("£${total.toStringAsFixed(2)}", font),
            ],
          );
        }).toList(),
      ],
    );
  }

  pw.Widget _buildTotalSection(pw.Font font) {
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Container(
        width: 200,
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300),
          borderRadius: pw.BorderRadius.circular(5),
        ),
        child: pw.Column(
          children: [
            _buildTotalRow("Subtotal", _calculateSubtotal(), font),
            _buildTotalRow("Tax (8%)", _calculateTax(), font),
            pw.Divider(),
            _buildTotalRow("TOTAL", _calculateTotal(), font, isTotal: true),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildNotesSection(pw.Font font) {
    return pw.Text(
      "Thank you for your business! Payment is due within 30 days.",
      style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey600),
    );
  }

  pw.Widget _buildTableHeader(String text, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: font,
          fontWeight: pw.FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  pw.Widget _buildTableCell(String text, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: pw.Text(text, style: pw.TextStyle(font: font, fontSize: 10)),
    );
  }

  pw.Widget _buildTotalRow(
    String label,
    double amount,
    pw.Font font, {
    bool isTotal = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              font: font,
              fontSize: isTotal ? 12 : 10,
              fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            "£${amount.toStringAsFixed(2)}",
            style: pw.TextStyle(
              font: font,
              fontSize: isTotal ? 12 : 10,
              fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: isTotal ? PdfColors.blue : PdfColors.black,
            ),
          ),
        ],
      ),
    );
  }

  double _calculateSubtotal() {
    return invoice.products.fold(
      0,
      (sum, product) => sum + (product["price"] * product["quantity"]),
    );
  }

  double _calculateTax() {
    return _calculateSubtotal() * 0.08;
  }

  double _calculateTotal() {
    return _calculateSubtotal() + _calculateTax();
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(width: 8),
        Text(value, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            fontSize: isBold ? 16 : 14,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            fontSize: isBold ? 16 : 14,
            color: isBold ? Colors.blue : Colors.black87,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          "Invoice Details",
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "Invoice #${invoice.id.toString().length > 5 ? invoice.id.toString().substring(0, 5) : invoice.id}",
                            overflow: TextOverflow.clip,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                        Text(
                          "PAID",
                          style: GoogleFonts.poppins(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    _buildInfoRow(
                      "Issue Date:",
                      getFormattedDate(invoice.date),
                    ),
                    SizedBox(height: 8),
                    _buildInfoRow("Payment Method:", "Credit Card"),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Customer Information",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.blue,
                          child: Icon(
                            Icons.person,
                            size: 24,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              invoice.customerName,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Products",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 12),
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.grey[300]!,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 4,
                            child: Text(
                              "ITEM",
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              "QTY",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              "PRICE",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              "TOTAL",
                              textAlign: TextAlign.end,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: invoice.products.length,
                      itemBuilder: (context, index) {
                        final product = invoice.products[index];
                        final double itemTotal =
                            product["price"] * product["quantity"];

                        return Container(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey[200]!,
                                width: 1,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 4,
                                child: Text(
                                  product["name"],
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  "${product["quantity"]}",
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  "£${product["price"].toStringAsFixed(2)}",
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  "£${itemTotal.toStringAsFixed(2)}",
                                  textAlign: TextAlign.end,
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 16),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          _buildSummaryRow(
                            "Subtotal",
                            "£${_calculateSubtotal().toStringAsFixed(2)}",
                          ),
                          SizedBox(height: 8),
                          _buildSummaryRow(
                            "Tax (8%)",
                            "£${_calculateTax().toStringAsFixed(2)}",
                          ),
                          SizedBox(height: 8),
                          Divider(),
                          SizedBox(height: 8),
                          _buildSummaryRow(
                            "Total",
                            "£${_calculateTotal().toStringAsFixed(2)}",
                            isBold: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Notes",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Thank you for your business! Payment is due within 30 days.",
                      style: GoogleFonts.poppins(color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),
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
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () => _downloadPdf(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            padding: EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(
            'Download PDF',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
