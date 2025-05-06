import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_inventory_app/screens/add_product_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_inventory_app/screens/csv_upload_screen.dart';
import 'package:smart_inventory_app/screens/create_invoice_screen.dart';
import 'package:fl_chart/fl_chart.dart'; // Add fl_chart import
import 'package:intl/intl.dart'; // Add intl import for currency formatting

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Dashboard",
          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),

            // Statistics Cards
            StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('products').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final products = snapshot.data!.docs;
                int totalProducts = products.length;
                double totalInventory = products.fold(
                  0.0,
                  (sum, product) =>
                      sum + (product['price'] * product['quantity']),
                );
                int lowStock =
                    products.where((product) => product['quantity'] < 5).length;

                return StreamBuilder<QuerySnapshot>(
                  stream:
                      FirebaseFirestore.instance
                          .collection('sales')
                          .snapshots(),
                  builder: (context, salesSnapshot) {
                    if (!salesSnapshot.hasData) {
                      return Center(child: CircularProgressIndicator());
                    }

                    return Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatCard(
                              "Total Inventory",
                              "£${totalInventory.toStringAsFixed(0)}",
                              Colors.blue,
                              context,
                            ),
                            _buildStatCard(
                              "Total Products",
                              "$totalProducts",
                              Colors.green,
                              context,
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatCard(
                              "Low Stock",
                              "$lowStock Items",
                              Colors.orange,
                              context,
                            ),
                            _buildStatCard(
                              "Avg Price",
                              "£${(products.fold(0.0, (sum, product) => sum + product['price']) / (totalProducts > 0 ? totalProducts : 1)).toStringAsFixed(0)}",
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
            SizedBox(height: 30),

            // Inventory Chart
            Text(
              "Inventory Value Distribution",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 10),

            Container(
              height: 250,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: _buildInventoryValueChart(),
            ),

            SizedBox(height: 30),

            // Quick Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildQuickAction(Icons.add_box, "Create Product", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AddProductScreen()),
                  );
                }),
                _buildQuickAction(Icons.upload_file, "Upload CSV", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CsvUploadScreen(),
                    ),
                  );
                }),
                _buildQuickAction(Icons.receipt_long, "Create Invoice", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreateInvoiceScreen(),
                    ),
                  );
                }),
              ],
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryValueChart() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('products').snapshots(),
      builder: (context, snapshot) {
        final Size screenSize = MediaQuery.of(context).size;
        final bool isSmallScreen = screenSize.width < 360;

        // Define accent color for loader
        final Color _accentColor = Theme.of(context).colorScheme.primary;

        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(_accentColor),
            ),
          );
        }

        final products = snapshot.data!.docs;

        // Define price ranges
        final Map<String, List<double>> priceRanges = {
          '0-50': [0, 50],
          '51-100': [51, 100],
          '101-200': [101, 200],
          '>200': [201, double.infinity],
        };

        // Calculate inventory value by price range
        Map<String, double> inventoryByPriceRange = {};
        for (var range in priceRanges.keys) {
          inventoryByPriceRange[range] = 0;
        }

        for (var product in products) {
          double price = product['price'].toDouble();
          int quantity = product['quantity'];
          double value = price * quantity;

          for (var range in priceRanges.keys) {
            List<double> limits = priceRanges[range]!;
            if (price >= limits[0] &&
                (limits[1] == double.infinity || price <= limits[1])) {
              inventoryByPriceRange[range] =
                  (inventoryByPriceRange[range] ?? 0) + value;
              break;
            }
          }
        }

        // Find max value for scaling
        double maxValue = inventoryByPriceRange.values.fold(
          0.0,
          (prev, value) => value > prev ? value : prev,
        );
        if (maxValue == 0) maxValue = 100; // Default if no products

        // Updated professional color scheme
        final List<List<Color>> gradientColors = [
          [const Color(0xFF4B79A1), const Color(0xFF283E51)], // Cool blue
          [const Color(0xFF4CA1AF), const Color(0xFF2C3E50)], // Teal
          [const Color(0xFFE684AE), const Color(0xFF9061A9)], // Pink/purple
          [const Color(0xFFF09819), const Color(0xFFEDDE5D)], // Gold
        ];

        // Style constants
        final double barWidth = isSmallScreen ? 18 : 24;
        final double groupSpace = isSmallScreen ? 20 : 28;
        final double fontSize = isSmallScreen ? 10 : 12;
        const Color textColor = Color(0xFF5A5A5A);
        const Color gridColor = Color(0xFFEAEAEA);

        return LayoutBuilder(
          builder: (context, constraints) {
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: AspectRatio(
                aspectRatio: constraints.maxWidth > 500 ? 1.8 : 1.4,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxValue * 1.15, // Add 15% headroom
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          return BarTooltipItem(
                            '£${rod.toY.toStringAsFixed(0)}',
                            TextStyle(
                              color: Colors.white,
                              fontSize: fontSize + 2,
                              fontWeight: FontWeight.w600,
                            ),
                            children: [
                              TextSpan(
                                text:
                                    '\n${priceRanges.keys.elementAt(group.x.toInt())}',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: fontSize,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          getTitlesWidget: (value, meta) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(
                                priceRanges.keys.elementAt(value.toInt()),
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: fontSize,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            // Use a compact currency formatter for professional look
                            final formatter = NumberFormat.compactCurrency(
                              symbol: '£',
                              decimalDigits: 0,
                              locale: 'en_GB',
                            );
                            return Text(
                              formatter.format(value),
                              style: TextStyle(
                                color: textColor,
                                fontSize: fontSize,
                                fontWeight: FontWeight.w500,
                                overflow: TextOverflow.clip,
                              ),
                            );
                          },
                        ),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      horizontalInterval: _calculateGridInterval(maxValue),
                      drawVerticalLine: false,
                      getDrawingHorizontalLine:
                          (value) => FlLine(color: gridColor, strokeWidth: 1),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border(
                        bottom: BorderSide(color: gridColor, width: 1),
                        left: BorderSide(color: gridColor, width: 1),
                      ),
                    ),
                    barGroups: List.generate(priceRanges.length, (index) {
                      String range = priceRanges.keys.elementAt(index);
                      return BarChartGroupData(
                        x: index,
                        barsSpace: 4,
                        barRods: [
                          BarChartRodData(
                            toY: inventoryByPriceRange[range] ?? 0,
                            width: barWidth,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                            gradient: LinearGradient(
                              colors:
                                  gradientColors[index % gradientColors.length],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                            backDrawRodData: BackgroundBarChartRodData(
                              show: true,
                              toY: maxValue * 1.15,
                              color: gridColor.withOpacity(0.15),
                            ),
                          ),
                        ],
                      );
                    }),
                    groupsSpace: groupSpace,
                  ),
                  swapAnimationDuration: const Duration(milliseconds: 600),
                  swapAnimationCurve: Curves.fastOutSlowIn,
                ),
              ),
            );
          },
        );
      },
    );
  }

  double _calculateGridInterval(double maxValue) {
    if (maxValue <= 100) return 20;
    if (maxValue <= 500) return 50;
    if (maxValue <= 1000) return 100;
    return 200;
  }

  // Function to create Statistics Cards
  Widget _buildStatCard(
    String title,
    String value,
    Color color,
    BuildContext context,
  ) {
    return Container(
      height: 100,
      width: MediaQuery.of(context).size.width * 0.45,
      padding: EdgeInsets.all(12),
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
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Spacer(),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // Function to create Quick Actions
  Widget _buildQuickAction(IconData icon, String label, Function() onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.blue.withOpacity(0.2),
            child: Icon(icon, color: Colors.blue, size: 28),
          ),
          SizedBox(height: 8),
          Text(label, style: GoogleFonts.poppins(fontSize: 14)),
        ],
      ),
    );
  }
}
