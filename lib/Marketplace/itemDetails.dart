import 'package:flutter/material.dart';

import 'package:pakfoundf/Marketplace/buyItem.dart';
import 'package:pakfoundf/marketPlaceProvider.dart'; // Import the MarketplaceItem

class ItemDetailsScreen extends StatelessWidget {
  final MarketplaceItem item;

  const ItemDetailsScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Item Details'),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Item Photo
              Center(
                child: Image.asset(
                  item.itemImagePath,
                  height: 200,
                  width: 200,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 16),
              // Item Name
              Text(
                'Item Name: ${item.itemName}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              // Item Category
              Text(
                'Category: ${item.itemCategory}',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              // Item Location
              Text(
                'Location: ${item.itemLocation}',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              // Item Description
              Text(
                'Description: ${item.itemDescription}',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              // Item Price
              Text(
                'Price: \$${item.price}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              // Shipment Methods
              const Text(
                'Shipment Methods:',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              if (item.faceToFaceShipment)
                const Text('Face to Face'),
              if (item.tntCourierService)
                const Text('TNT Courier Service'),

              const SizedBox(height: 16),

              // Chat Button
              ElevatedButton(
                onPressed: () {
                  // Navigate to the chat screen with the imaginary user
                  // Navigator.push(
                  //   context,
                  //   MaterialPageRoute(
                  //     builder: (context) => NewChatScreen(),
                  //   ),
                  // );
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white, backgroundColor: Colors.blue, // Text color
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                child: const Text('Chat with Seller'),
              ),

              // Buy Item Details Button
              ElevatedButton(
                onPressed: () {
                  // Navigate to the buy item details screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BuyItemScreen(
                        itemName: item.itemName,
                        itemPrice: item.price.toString(),
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white, backgroundColor: Colors.green, // Text color
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                child: const Text('Buy Item Details'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
