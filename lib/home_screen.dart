import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'allproductview.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, String>> _products = [];
  List<Map<String, String>> _filteredProducts = [];
  Map<String, List<Map<String, String>>> _categorizedProducts = {};
  List<String> _categories = [];
  TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  bool _isSearching = false;
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    loadProducts();
    _searchController.addListener(() {
      filterProducts(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void loadProducts() async {
    setState(() => _isLoading = true);
    var prefs = await SharedPreferences.getInstance();
    var productsString = prefs.getString('products') ?? '[]';
    var decodedProducts = json.decode(productsString) as List;

    setState(() {
      _products = decodedProducts
          .map((item) => Map<String, String>.from(item as Map))
          .toList();
      _filteredProducts = List.from(_products);

      // Extract unique categories
      _categories = ['All'] +
          _products
              .map((product) => product['category'] ?? 'Other')
              .toSet()
              .toList();

      // Organize products by category
      _categorizedProducts = {};
      for (var category in _categories) {
        if (category != 'All') {
          _categorizedProducts[category] = _products
              .where((product) => product['category'] == category)
              .toList();
        }
      }

      _isLoading = false;
    });
  }

  void filterProducts(String query) {
    setState(() {
      if (_selectedCategory == 'All') {
        _filteredProducts = _products
            .where((product) =>
                product['name']!.toLowerCase().contains(query.toLowerCase()))
            .toList();
      } else {
        _filteredProducts = _products
            .where((product) =>
                product['name']!.toLowerCase().contains(query.toLowerCase()) &&
                product['category'] == _selectedCategory)
            .toList();
      }

      // Update categorized products based on search
      _categorizedProducts = {};
      for (var category in _categories) {
        if (category != 'All') {
          _categorizedProducts[category] = _filteredProducts
              .where((product) => product['category'] == category)
              .toList();
        }
      }
    });
  }

  void signOut() async {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: Text('Sign Out'),
        content: Text('Are you sure you want to sign out?'),
        actions: [
          CupertinoDialogAction(
            child: Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            child: Text('Sign Out'),
            isDestructiveAction: true,
            onPressed: () async {
              var prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              setState(() {});
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
    );
  }

  void deleteProduct(String category, int index) async {
    // Find the product in the main list
    var productToDelete = _categorizedProducts[category]![index];
    int mainIndex = _products.indexWhere((p) =>
        p['name'] == productToDelete['name'] &&
        p['category'] == productToDelete['category']);

    setState(() {
      _products.removeAt(mainIndex);
      _categorizedProducts[category]!.removeAt(index);

      // Remove empty categories
      if (_categorizedProducts[category]!.isEmpty) {
        _categorizedProducts.remove(category);
        _categories.remove(category);
      }
    });

    var prefs = await SharedPreferences.getInstance();
    await prefs.setString('products', json.encode(_products));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Product deleted'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildProductCard(
      Map<String, String> product, String category, int index) {
    String? imagePath = product['image'];
    bool hasValidImage = imagePath != null &&
        imagePath.isNotEmpty &&
        File(imagePath).existsSync();

    return Container(
      width: 160,
      margin: EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Center(
                    child: hasValidImage
                        ? Image.file(
                            File(imagePath!),
                            fit: BoxFit.contain,
                          )
                        : Icon(
                            CupertinoIcons.headphones,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  product['name'] ?? 'Unknown Product',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '\$${product['price'] ?? '0'}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(
                  CupertinoIcons.delete,
                  size: 20,
                  color: Colors.red,
                ),
                onPressed: () => deleteProduct(category, index),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(
      String category, List<Map<String, String>> products) {
    if (products.isEmpty) return SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                category,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AllProductsView(
                        products: products,
                        onProductsUpdated: (updatedProducts) {
                          setState(() {
                            // Update the specific category products
                            _categorizedProducts[category] = updatedProducts;
                            loadProducts(); // Reload all products to sync
                          });
                        },
                      ),
                    ),
                  );
                },
                child: Text(
                  'Show All',
                  style: TextStyle(color: Colors.blue),
                ),
              ),
            ],
          ),
        ),
        Container(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16),
            itemCount: products.length,
            itemBuilder: (context, index) {
              return _buildProductCard(products[index], category, index);
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Search
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  GestureDetector(
                      onTap: signOut,
                      child: Icon(CupertinoIcons.back, size: 30)),
                  if (_isSearching)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search products...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: Center(
                        child: Text(
                          'Home Screen',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  IconButton(
                    icon: Icon(
                      _isSearching
                          ? CupertinoIcons.clear
                          : CupertinoIcons.search,
                    ),
                    onPressed: () {
                      setState(() {
                        _isSearching = !_isSearching;
                        if (!_isSearching) {
                          _searchController.clear();
                          loadProducts();
                        }
                      });
                    },
                  ),
                ],
              ),
            ),

            // Category Filter
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: _categories.map((category) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategory = category;
                        filterProducts(_searchController.text);
                      });
                    },
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      margin: EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: _selectedCategory == category
                            ? Colors.blue
                            : Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        category,
                        style: TextStyle(
                          color: _selectedCategory == category
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Category Sections
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : _filteredProducts.isEmpty
                      ? Center(child: Text('No Products Found'))
                      : ListView(
                          children: _categorizedProducts.entries.map((entry) {
                            return _buildCategorySection(
                                entry.key, entry.value);
                          }).toList(),
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.blue,
        ),
        child: FloatingActionButton(
          backgroundColor: Colors.transparent,
          elevation: 0,
          onPressed: () async {
            await Navigator.pushNamed(context, '/addProduct');
            loadProducts();
          },
          child: Icon(CupertinoIcons.add, size: 28),
        ),
      ),
    );
  }
}
