import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:pakfoundf/Marketplace/marketItemDetails.dart';
import 'package:pakfoundf/Profile/myItems.dart';
import 'package:pakfoundf/Upload/item_details.dart';
//import 'my_uploads_screen.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({Key? key}) : super(key: key);

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Marketplace',style: TextStyle(color: Colors.white),),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MyUploadsScreen(initialTabIndex: 1), // Open "Found" tab
                ),
              );
            },
          ),
        ],
      ),
      body: _buildMarketplaceItems(),
    );
  }

  Widget _buildMarketplaceItems() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('items')
          .where('itemType', isEqualTo: 'marketplace')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final items = snapshot.data?.docs ?? [];
        if (items.isEmpty) {
          return const Center(child: Text('No items found in the marketplace.'));
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16.0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16.0,
            crossAxisSpacing: 16.0,
            childAspectRatio: 0.75, // Adjust based on the desired card dimensions
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return _buildItemCard(
              item.id,
              item['name'],
              item['itemLocation'],
              item['dateTime'],
              item['itemImages']
            );
          },
        );
      },
    );
  }

  Widget _buildItemCard(String documentId, String itemName, String itemLocation, Timestamp itemDate, List<dynamic> imagePath) {
    final locationBeforeComma = itemLocation.split(',')[0];

    return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MarketplaceItemDetailsScreen(
                documentId: documentId,
              ),
            ),
          );
        },
        child:Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      elevation: 5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: imagePath.isNotEmpty
                  ? Image.network(
                      imagePath.first,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.image, size: 50),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  itemName,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  locationBeforeComma,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                Text(
                  DateFormat('yyyy-MM-dd – kk:mm').format(itemDate.toDate()),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    ),);
  }
}
