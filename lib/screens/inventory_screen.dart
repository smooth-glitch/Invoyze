import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_inventory_app/components/custom_search_bar.dart';
import 'package:smart_inventory_app/models/product_model.dart';
import 'package:smart_inventory_app/screens/product_screen.dart';

class InventoryScreen extends StatefulWidget {
  InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final List<ProductModel> _products = [];
  List<ProductModel> _filteredProducts = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isGridView = false;
  late StreamSubscription<QuerySnapshot> _productsSubscription;
  Timer? _debounce;
  bool _isSearching = false;

  // Add filter state variables
  String _activeSort = 'none';
  String _activeStockFilter = 'all';

  @override
  void initState() {
    super.initState();
    _initializeFirestore();
    _searchController.addListener(_onSearchChanged);
  }

  void _initializeFirestore() {
    _productsSubscription = FirebaseFirestore.instance
        .collection('products')
        .snapshots()
        .listen((snapshot) {
          final List<ProductModel> loadedProducts = [];
          for (final doc in snapshot.docs) {
            loadedProducts.add(ProductModel.fromJson(doc.data()));
          }
          setState(() {
            _products
              ..clear()
              ..addAll(loadedProducts);
            _filteredProducts = _products;
          });
        });
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    setState(() => _isSearching = _searchController.text.isNotEmpty);
    _debounce = Timer(const Duration(milliseconds: 300), _filterProducts);
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase().trim();
    List<ProductModel> results = List.from(_products);

    // Apply text search filter if query exists
    if (query.isNotEmpty) {
      results =
          results.where((product) {
            return product.name.toLowerCase().contains(query) ||
                product.description.toLowerCase().contains(query) ||
                product.id.toLowerCase().contains(query) ||
                ('SKU-${product.id}').toLowerCase().contains(query) ||
                product.price.toString().contains(query) ||
                product.quantity.toString() == query;
          }).toList();
    }

    // Apply stock filter
    if (_activeStockFilter != 'all') {
      switch (_activeStockFilter) {
        case 'low':
          results = results.where((product) => product.quantity <= 10).toList();
          break;
        case 'medium':
          results =
              results
                  .where(
                    (product) =>
                        product.quantity > 10 && product.quantity <= 30,
                  )
                  .toList();
          break;
        case 'high':
          results = results.where((product) => product.quantity > 30).toList();
          break;
      }
    }

    // Apply sorting
    switch (_activeSort) {
      case 'price_asc':
        results.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_desc':
        results.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'stock_asc':
        results.sort((a, b) => a.quantity.compareTo(b.quantity));
        break;
      case 'stock_desc':
        results.sort((a, b) => b.quantity.compareTo(a.quantity));
        break;
      case 'name_asc':
        results.sort((a, b) => a.name.compareTo(b.name));
        break;
    }

    setState(() {
      _filteredProducts = results;
    });
  }

  void _filterProducts() {
    _applyFilters();
  }

  void _toggleViewMode() {
    setState(() {
      _isGridView = !_isGridView;
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _productsSubscription.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          'Inventory',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: CustomSearchBar(
              controller: _searchController,
              hintText: 'Search by name, description, SKU, or price',
              onClear: () {
                _searchController.clear();
                _filterProducts();
              },
            ),
          ),
          _buildHeader(),
          _buildFilterButtons(),
          Expanded(
            child:
                _filteredProducts.isEmpty
                    ? _buildNoResultsFound()
                    : (_isGridView ? _buildGridView() : _buildListView()),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Products (${_filteredProducts.length})',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          _buildViewToggle(),
        ],
      ),
    );
  }

  Widget _buildViewToggle() {
    return GestureDetector(
      onTap: _toggleViewMode,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(
              _isGridView ? Icons.view_list : Icons.grid_view,
              color: Colors.blue,
              size: 16,
            ),
            SizedBox(width: 4),
            Text(
              _isGridView ? 'List' : 'Grid',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButtons() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          Container(
            margin: EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: PopupMenuButton<String>(
              onSelected: (value) {
                setState(() {
                  _activeSort = value;
                });
                _applyFilters();
              },
              itemBuilder:
                  (context) => [
                    PopupMenuItem(
                      value: 'name_asc',
                      child: Row(
                        children: [
                          Icon(
                            Icons.sort_by_alpha,
                            size: 18,
                            color:
                                _activeSort == 'name_asc'
                                    ? Colors.blue
                                    : Colors.grey,
                          ),
                          SizedBox(width: 8),
                          Text('Name (A-Z)'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'price_asc',
                      child: Row(
                        children: [
                          Icon(
                            Icons.arrow_upward,
                            size: 18,
                            color:
                                _activeSort == 'price_asc'
                                    ? Colors.blue
                                    : Colors.grey,
                          ),
                          SizedBox(width: 8),
                          Text('Price: Low to High'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'price_desc',
                      child: Row(
                        children: [
                          Icon(
                            Icons.arrow_downward,
                            size: 18,
                            color:
                                _activeSort == 'price_desc'
                                    ? Colors.blue
                                    : Colors.grey,
                          ),
                          SizedBox(width: 8),
                          Text('Price: High to Low'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'stock_asc',
                      child: Row(
                        children: [
                          Icon(
                            Icons.arrow_upward,
                            size: 18,
                            color:
                                _activeSort == 'stock_asc'
                                    ? Colors.blue
                                    : Colors.grey,
                          ),
                          SizedBox(width: 8),
                          Text('Stock: Low to High'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'stock_desc',
                      child: Row(
                        children: [
                          Icon(
                            Icons.arrow_downward,
                            size: 18,
                            color:
                                _activeSort == 'stock_desc'
                                    ? Colors.blue
                                    : Colors.grey,
                          ),
                          SizedBox(width: 8),
                          Text('Stock: High to Low'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'none',
                      child: Row(
                        children: [
                          Icon(
                            Icons.clear,
                            size: 18,
                            color:
                                _activeSort == 'none'
                                    ? Colors.blue
                                    : Colors.grey,
                          ),
                          SizedBox(width: 8),
                          Text('Clear Sorting'),
                        ],
                      ),
                    ),
                  ],
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.sort,
                      size: 16,
                      color: _activeSort != 'none' ? Colors.blue : Colors.grey,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Sort',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color:
                            _activeSort != 'none'
                                ? Colors.blue
                                : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          _buildFilterChip(
            label: 'All',
            isSelected: _activeStockFilter == 'all',
            onSelected: () {
              setState(() {
                _activeStockFilter = 'all';
              });
              _applyFilters();
            },
          ),
          _buildFilterChip(
            label: 'Low Stock',
            isSelected: _activeStockFilter == 'low',
            color: Colors.red,
            onSelected: () {
              setState(() {
                _activeStockFilter = 'low';
              });
              _applyFilters();
            },
          ),
          _buildFilterChip(
            label: 'High Stock',
            isSelected: _activeStockFilter == 'high',
            color: Colors.green,
            onSelected: () {
              setState(() {
                _activeStockFilter = 'high';
              });
              _applyFilters();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
    Color color = Colors.blue,
  }) {
    return Container(
      margin: EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(
          label,
          style: GoogleFonts.poppins(
            color: isSelected ? Colors.white : Colors.black87,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
        selected: isSelected,
        onSelected: (_) => onSelected(),
        backgroundColor: Colors.white,
        selectedColor: color,
        checkmarkColor: Colors.white,
        shape: StadiumBorder(
          side: BorderSide(color: isSelected ? color : Colors.grey.shade300),
        ),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        elevation: 0,
        pressElevation: 0,
      ),
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) {
        final product = _filteredProducts[index];
        return _buildListProductItem(product);
      },
    );
  }

  Widget _buildListProductItem(ProductModel product) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            product.imageUrl,
            width: 50,
            height: 50,
            fit: BoxFit.cover,
          ),
        ),
        title: Text(
          product.name.split(' ').take(10).join(' ') +
              (product.name.split(' ').length > 10 ? '...' : ''),
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          product.description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(fontSize: 12),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '£${product.price.toStringAsFixed(0)}',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            Text(
              'Qty: ${product.quantity}',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: _getQuantityColor(product.quantity),
              ),
            ),
          ],
        ),
        onTap: () => _navigateToProductDetail(product),
      ),
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      padding: EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) {
        final product = _filteredProducts[index];
        return _buildGridProductItem(product);
      },
    );
  }

  Widget _buildGridProductItem(ProductModel product) {
    return Card(
      child: InkWell(
        onTap: () => _navigateToProductDetail(product),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
                child: Image.network(product.imageUrl, fit: BoxFit.cover),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name.length < 5
                        ? '${product.name.substring(0, 5)}...'
                        : product.name,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    '£${product.price.toStringAsFixed(0)}',
                    style: GoogleFonts.poppins(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Qty: ${product.quantity}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: _getQuantityColor(product.quantity),
                        ),
                      ),
                      Icon(Icons.more_vert, size: 16),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsFound() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 64, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            _isSearching
                ? 'No products match your search'
                : 'No products in inventory yet',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          if (_isSearching) SizedBox(height: 8),
          if (_isSearching)
            TextButton.icon(
              onPressed: () {
                _searchController.clear();
                _filterProducts();
              },
              icon: Icon(Icons.clear),
              label: Text('Clear search'),
            ),
        ],
      ),
    );
  }

  Color _getQuantityColor(int quantity) {
    if (quantity <= 10) return Colors.red;
    if (quantity <= 30) return Colors.orange;
    return Colors.green;
  }

  void _navigateToProductDetail(ProductModel product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailScreen(product: product),
      ),
    );
  }
}
