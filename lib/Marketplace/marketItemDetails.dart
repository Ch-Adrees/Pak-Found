import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pakfoundf/Chat/addChat.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pakfoundf/Marketplace/uploadToMarketplace.dart';
//import 'package:pakfoundf/Chat/add_chat_screen.dart';  // Import AddChatScreen

class MarketplaceItemDetailsScreen extends StatelessWidget {
  final String documentId;

  const MarketplaceItemDetailsScreen({required this.documentId});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Item Details', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('items').doc(documentId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final itemData = snapshot.data?.data() as Map<String, dynamic>? ?? {};
          final uploadedBy = itemData['uploadedBy'] ?? '';
          final imagePathList = (itemData['itemImages'] as List<dynamic>?) ?? [];
          final itemName = itemData['name'] ?? '';
          final itemLocation = itemData['itemLocation'] ?? '';
          final itemDate = itemData['dateTime'] as Timestamp;
          final itemDescription = itemData['description'] ?? '';
          final itemCategory = itemData['itemCategory'] ?? '';
          final itemType = itemData['itemType'] ?? '';
          final itemPrice = itemData['itemPrice'] ?? 0.0;
          final shipmentMethods = itemData['shippingMethod'] ?? {};
          final faceToFaceShipment = shipmentMethods['faceToFace'] ?? false;
          final tntCourierService = shipmentMethods['tntCourier'] ?? false;
          final itemId = snapshot.data?.id;

          return SingleChildScrollView(
            child: Column(
              children: [
                FractionallySizedBox(
                  widthFactor: 0.9,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Stack(
                      children: [
                        Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15.0),
                          ),
                          elevation: 5,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  height: screenHeight * 0.3,
                                  child: PageView.builder(
                                    itemCount: imagePathList.length,
                                    itemBuilder: (context, index) {
                                      return ClipRRect(
                                        borderRadius: BorderRadius.circular(15.0),
                                        child: Image.network(
                                          imagePathList[index],
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 16.0),
                                Text(
                                  itemName,
                                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4.0),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on, color: Colors.green),
                                    const SizedBox(width: 8.0),
                                    Expanded(
                                      child: Text(
                                        itemLocation,
                                        style: const TextStyle(fontSize: 16),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4.0),
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today, color: Colors.green),
                                    const SizedBox(width: 8.0),
                                    Text(
                                      DateFormat('yyyy-MM-dd – kk:mm').format(itemDate.toDate()),
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4.0),
                                Row(
                                  children: [
                                    const Icon(Icons.category, color: Colors.green),
                                    const SizedBox(width: 8.0),
                                    Text(
                                      itemCategory,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4.0),
                                Row(
                                  children: [
                                    const Icon(Icons.list, color: Colors.green),
                                    const SizedBox(width: 8.0),
                                    Text(
                                      itemType,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4.0),
                               // const SizedBox(height: 8.0),
                                 Row(
                                  children: [
                                    const Icon(Icons.price_change, color: Colors.green),
                                    const SizedBox(width: 8.0),
                                    Text(
                                      itemPrice.toString(),
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    const Text(
                                      'Shipment Method: ',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                     if (faceToFaceShipment) const Text('Face to Face'),
                                if (tntCourierService) const Text('TNT Courier Service'),
                                  ],
                                ),
                                Text(
                                  itemDescription,
                                  style: const TextStyle(fontSize: 13),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance.collection('users').doc(uploadedBy).get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final userData = snapshot.data?.data() as Map<String, dynamic>? ?? {};
                    final userName = userData['name'] ?? 'Unknown';
                    final userProfilePic = userData['profilePic'] ?? '';
                    final userEmail = userData['email'] ?? '';
                    final userPhone = userData['phoneNumber'] ?? '';

                    return ListTile(
                      leading: userProfilePic.isNotEmpty
                          ? CircleAvatar(
                              backgroundImage: NetworkImage(userProfilePic),
                            )
                          : const CircleAvatar(
                              child: Icon(Icons.person),
                            ),
                      title: Text(
                        userName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(userEmail),
                          Text(userPhone),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.call, color: Colors.green),
                            onPressed: () async {
                              final Uri callUri = Uri(
                                scheme: 'tel',
                                path: userPhone,
                              );
                              if (await canLaunchUrl(callUri)) {
                                await launchUrl(callUri);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Could not launch call')),
                                );
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.message, color: Colors.green),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AddChatScreen(
                                     userEmail,
                                  ),
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.email, color: Colors.green),
                            onPressed: () async {
                              final Uri emailUri = Uri(
                                scheme: 'mailto',
                                path: userEmail,
                              );
                              if (await canLaunchUrl(emailUri)) {
                                await launchUrl(emailUri);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Could not launch email')),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
                if (user != null && user.uid == uploadedBy)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UploadToMarketplaceScreen(
                              itemName: itemName,
                              itemCategory: itemCategory,
                              itemLocation: itemLocation,
                              itemDescription: itemDescription,
                              itemImagePathList: imagePathList,
                              documentId: itemId.toString(),
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: const Text('Edit Item'),
                    ),
                  ),
                if (user != null && user.uid != uploadedBy)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              // Handle buy item action
                            },
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                            ),
                            child: const Text('Buy Item'),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
