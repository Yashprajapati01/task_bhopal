import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddProductScreen extends StatefulWidget {
  @override
  _AddProductScreenState createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  late var _categoryController = TextEditingController();
  File? _image;

  bool _isLoading = false;
  bool _isAddingNewCategory = false;

  List<Map<String, String>> _products = [];
  // Suggested categories
  List<String> _suggestedCategories = [
    'Headphones',
    'Speakers',
    'Earbuds',
    'Accessories',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    loadProducts();
    loadCategories(); // Load previously used categories
  }

  void loadProducts() async {
    var prefs = await SharedPreferences.getInstance();
    var productsString = prefs.getString('products') ?? '[]';
    _products =
        List<Map<String, String>>.from(json.decode(productsString) as List);
  }

  void loadCategories() async {
    var prefs = await SharedPreferences.getInstance();
    var categories = prefs.getStringList('categories');
    if (categories != null) {
      setState(() {
        // Merge suggested categories with saved categories, removing duplicates
        _suggestedCategories =
            {..._suggestedCategories, ...categories}.toList();
      });
    }
  }

  Future<void> saveCategory(String category) async {
    if (category.isNotEmpty) {
      var prefs = await SharedPreferences.getInstance();
      var categories = prefs.getStringList('categories') ?? [];
      if (!categories.contains(category)) {
        categories.add(category);
        await prefs.setStringList('categories', categories);
        setState(() {
          if (!_suggestedCategories.contains(category)) {
            _suggestedCategories.add(category);
          }
        });
      }
    }
  }

  Future<void> saveProduct() async {
    if (_formKey.currentState!.validate()) {
      if (_image == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please add a product image'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      setState(() => _isLoading = true);

      String name = _nameController.text.trim();
      String price = _priceController.text.trim();
      String category = _categoryController.text.trim();
      String? imagePath = _image?.path;

      // Save the new category if it's not in the list
      await saveCategory(category);

      var prefs = await SharedPreferences.getInstance();
      var productsString = prefs.getString('products') ?? '[]';
      List<Map<String, String>> products = List<Map<String, String>>.from(
        (json.decode(productsString) as List).map(
          (item) => Map<String, String>.from(item as Map),
        ),
      );

      bool isDuplicate = products.any(
          (product) => product['name']!.toLowerCase() == name.toLowerCase());
      if (isDuplicate) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Product with this name already exists'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      Map<String, String> newProduct = {
        'name': name,
        'price': price,
        'image': imagePath ?? '',
        'category': category,
      };
      products.add(newProduct);

      await prefs.setString('products', json.encode(products));

      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Product added successfully'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    }
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
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
          'Add Product',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image Picker Section
                      Center(
                        child: GestureDetector(
                          onTap: pickImage,
                          child: Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 5,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: _image == null
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        CupertinoIcons.camera,
                                        size: 40,
                                        color: Colors.grey[400],
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Add Product Image',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  )
                                : ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.file(
                                      _image!,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      SizedBox(height: 24),

                      // Form Fields
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 5,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Name Field
                            TextFormField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                labelText: 'Product Name',
                                prefixIcon: Icon(CupertinoIcons.tag),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter product name';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 16),

                            // Price Field
                            TextFormField(
                              controller: _priceController,
                              decoration: InputDecoration(
                                labelText: 'Product Price',
                                prefixIcon: Icon(CupertinoIcons.money_dollar),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter product price';
                                }
                                if (double.tryParse(value) == null) {
                                  return 'Enter a valid number';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 16),

                            // Category Field with Suggestions
                            Autocomplete<String>(
                              optionsBuilder:
                                  (TextEditingValue textEditingValue) {
                                if (textEditingValue.text == '') {
                                  return const Iterable<String>.empty();
                                }
                                return _suggestedCategories
                                    .where((String option) {
                                  return option.toLowerCase().contains(
                                        textEditingValue.text.toLowerCase(),
                                      );
                                });
                              },
                              onSelected: (String selection) {
                                _categoryController.text = selection;
                              },
                              fieldViewBuilder: (
                                BuildContext context,
                                TextEditingController controller,
                                FocusNode focusNode,
                                VoidCallback onFieldSubmitted,
                              ) {
                                _categoryController = controller;
                                return TextFormField(
                                  controller: controller,
                                  focusNode: focusNode,
                                  decoration: InputDecoration(
                                    labelText: 'Category',
                                    hintText: 'Enter or select a category',
                                    prefixIcon:
                                        Icon(CupertinoIcons.square_grid_2x2),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please enter a category';
                                    }
                                    return null;
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 24),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: saveProduct,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Add Product',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
