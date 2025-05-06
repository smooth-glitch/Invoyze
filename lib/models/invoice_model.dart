class InvoiceModel {
  final String id;
  final String customerName;
  final double totalAmount;
  final DateTime date;
  final List<Map<String, dynamic>> products; // List of products in the invoice

  InvoiceModel({
    required this.id,
    required this.customerName,
    required this.totalAmount,
    required this.date,
    required this.products,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerName': customerName,
      'totalAmount': totalAmount,
      'date': date.toIso8601String(),
      'products': products,
    };
  }
}
