import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ItemsProvider with ChangeNotifier {
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _filteredItems = [];
  bool _isLoading = false;
  String _errorMessage = '';

  List<Map<String, dynamic>> get items => _filteredItems;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  ItemsProvider() {
    fetchItems();
  }

  Future<void> fetchItems() async {
    _isLoading = true;
    notifyListeners();

    try {
      final querySnapshot = await FirebaseFirestore.instance.collection('items').get();
      _items = querySnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
      _filteredItems = _items;
      _isLoading = false;
      notifyListeners();
    } catch (error) {
      _errorMessage = 'Failed to fetch items: $error';
      _isLoading = false;
      notifyListeners();
    }
  }

  void filterItems(String query) {
    if (query.isEmpty) {
      _filteredItems = _items;
    } else {
      _filteredItems = _items.where((item) {
        final itemName = item['name']?.toLowerCase() ?? '';
        final itemDescription = item['description']?.toLowerCase() ?? '';
        return itemName.contains(query.toLowerCase()) || itemDescription.contains(query.toLowerCase());
      }).toList();
    }
    notifyListeners();
  }

  void addItem(Map<String, dynamic> item) {
    _items.add(item);
    _filteredItems = _items;
    notifyListeners();
  }
}
