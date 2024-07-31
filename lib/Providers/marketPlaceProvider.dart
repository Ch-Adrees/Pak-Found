// ignore: file_names
import 'package:flutter/material.dart';

class MarketplaceProvider extends ChangeNotifier {
  final List<MarketplaceItem> _items = [];

  List<MarketplaceItem> get items => _items;

  void addItem({
    required String itemName,
    required String itemCategory,
    required String itemLocation,
    required String itemDescription,
    required String itemImagePath,
    required double price,
    required bool faceToFaceShipment,
    required bool tntCourierService,
  }) {
    _items.add(
      MarketplaceItem(
        itemName: itemName,
        itemCategory: itemCategory,
        itemLocation: itemLocation,
        itemDescription: itemDescription,
        itemImagePath: itemImagePath,
        price: price,
        faceToFaceShipment: faceToFaceShipment,
        tntCourierService: tntCourierService,
      ),
    );
    notifyListeners();
  }
}

class MarketplaceItem {
  final String itemName;
  final String itemCategory;
  final String itemLocation;
  final String itemDescription;
  final String itemImagePath;
  final double price;
  final bool faceToFaceShipment;
  final bool tntCourierService;
  bool isFavorite; // Add isFavorite field

  MarketplaceItem({
    required this.itemName,
    required this.itemCategory,
    required this.itemLocation,
    required this.itemDescription,
    required this.itemImagePath,
    required this.price,
    required this.faceToFaceShipment,
    required this.tntCourierService,
    this.isFavorite = false, // Initialize with false by default
  });
}
