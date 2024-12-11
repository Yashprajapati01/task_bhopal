import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AllProductsView extends StatefulWidget {
  final List<Map<String, String>> products;
  final Function(List<Map<String, String>>) onProductsUpdated;

  const AllProductsView({
    Key? key,
    required this.products,
    required this.onProductsUpdated,
  }) : super(key: key);

  @override
  State<AllProductsView> createState() => _AllProductsViewState();
}

class _AllProductsViewState extends State<AllProductsView> {
  late List<Map<String, String>> _products;

  @override
  void initState() {
    super.initState();
    _products =
        List.from(widget.products); // Create a local copy of the products
  }

  Future<void> deleteProduct(int index) async {
    setState(() {
      _products.removeAt(index);
    });

    var prefs = await SharedPreferences.getInstance();
    await prefs.setString('products', json.encode(_products));
    // Notify parent widget about the update
    widget.onProductsUpdated(_products);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Product deleted'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(CupertinoIcons.back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'All Products',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _products.isEmpty
          ? Center(child: Text('No products found'))
          : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: _products.length,
              itemBuilder: (context, index) {
                var product = _products[index];
                String? imagePath = product['image'];
                bool hasValidImage = imagePath != null &&
                    imagePath.isNotEmpty &&
                    File(imagePath).existsSync();

                return Container(
                  margin: EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(16),
                    leading: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: hasValidImage
                            ? Image.file(
                                File(imagePath!),
                                fit: BoxFit.contain,
                              )
                            : Icon(
                                CupertinoIcons.headphones,
                                size: 30,
                                color: Colors.grey[400],
                              ),
                      ),
                    ),
                    title: Text(
                      product['name'] ?? 'Unknown Product',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      '₹${product['price'] ?? '0'}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    trailing: IconButton(
                      icon: Icon(
                        CupertinoIcons.delete,
                        size: 20,
                        color: Colors.grey[600],
                      ),
                      onPressed: () => deleteProduct(index),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
