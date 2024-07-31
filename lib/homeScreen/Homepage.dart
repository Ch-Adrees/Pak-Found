import 'package:flutter/material.dart';
import 'package:pakfoundf/loginAndSignup/loginScreen.dart';
import 'package:pakfoundf/Search/Searchpage.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:pakfoundf/Providers/itemProvider.dart';
import 'package:double_back_to_close_app/double_back_to_close_app.dart';
import 'package:pakfoundf/Upload/item_details.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart'; // For loading spinner

class Homepage extends StatefulWidget {
  const Homepage({Key? key}) : super(key: key);

  @override
  _HomepageState createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  String _selectedItemType = 'lost'; // Default selection

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Home Page', style: TextStyle(color: Colors.white),),
          backgroundColor: Colors.green,
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SearchScreen()),
                );
              },
              icon: const Icon(Icons.search),
            ),
          ],
        ),
        body: DefaultTabController(
          length: 3,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: DropdownButtonFormField<String>(
                  value: _selectedItemType,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedItemType = newValue!;
                    });
                  },
                  items: const [
                    DropdownMenuItem(value: 'lost', child: Text('Lost Items')),
                    DropdownMenuItem(value: 'found', child: Text('Found Items')),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Select Item Type',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                ),
              ),
              Container(
                constraints: const BoxConstraints.expand(height: 50),
                child: const TabBar(
                  tabs: [
                    Tab(text: 'Pets'),
                    Tab(text: 'Documents'),
                    Tab(text: 'Any Other Item'),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildLostAndFoundTab(context, 'Pet'),
                    _buildLostAndFoundTab(context, 'Documents'),
                    _buildLostAndFoundTab(context, 'Any Other Item'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLostAndFoundTab(BuildContext context, String category) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('items')
              .where('itemCategory', isEqualTo: category)
              .where('itemType', isEqualTo: _selectedItemType)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: SpinKitCircle(
                color: Colors.green,
                size: 50.0,
              ));
            }
            final items = snapshot.data?.docs ?? [];
            if (items.isEmpty) {
              return const Center(child: Text('No items found.'));
            }
            return GridView.builder(
              physics: const NeverScrollableScrollPhysics(), // Prevent scrolling inside the grid
              shrinkWrap: true, // Make the grid take only the required space
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16.0,
                crossAxisSpacing: 16.0,
                childAspectRatio: 0.75, // Adjust based on the desired card dimensions
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return _buildLostFoundItemCard(
                  item.id, // Document ID
                  item['itemType'],
                  item['name'],
                  item['itemLocation'],
                  item['dateTime'],
                  item['itemImages'],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildLostFoundItemCard(String documentId, String itemType, String itemName, String itemLocation, Timestamp itemDate, List<dynamic> imagePath) {
    final user = FirebaseAuth.instance.currentUser;

    // Modify itemLocation to include only the string before the comma
    final locationBeforeComma = itemLocation.split(',')[0];

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(user?.uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: SpinKitCircle(
            color: Colors.green,
            size: 50.0,
          ));
        }

        final userData = snapshot.data?.data() as Map<String, dynamic>? ?? {};
        final myFavourites = userData['myFavourites'] as List<dynamic>? ?? [];
        bool isFavourite = myFavourites.contains(documentId);

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ItemDetailsScreen(
                  documentId: documentId, isFavorited: isFavourite,
                ),
              ),
            );
          },
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            elevation: 5,
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Image of the item
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: imagePath.first.isNotEmpty
                            ? Image.network(
                          imagePath.first,
                          fit: BoxFit.cover,
                       loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          }, )
                            : Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.image_not_supported, size: 50),
                        ),
                      ),
                    ),

                    // Item details
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8,0,8,8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            itemName,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            locationBeforeComma, // Use modified location string
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
                Positioned(
                  top: 8.0,
                  right: 8.0,
                  child: IconButton(
                    icon: Icon(
                      isFavourite ? Icons.favorite : Icons.favorite_border,
                      color: isFavourite ? Colors.red : Colors.grey,
                      size: 22, // Increase the size of the heart icon
                    ),
                    onPressed: () async {
                      final userDocRef = FirebaseFirestore.instance.collection('users').doc(user?.uid);
                      final userDoc = await userDocRef.get();
                      final userData = userDoc.data() as Map<String, dynamic>? ?? {};
                      final myFavourites = List<String>.from(userData['myFavourites'] ?? []);

                      if (isFavourite) {
                        myFavourites.remove(documentId);
                      } else {
                        myFavourites.add(documentId);
                      }

                      await userDocRef.update({
                        'myFavourites': myFavourites,
                      });

                      setState(() {});
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
