import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class MyFavouritesScreen extends StatefulWidget {
  const MyFavouritesScreen({Key? key}) : super(key: key);

  @override
  _MyFavouritesScreenState createState() => _MyFavouritesScreenState();
}

class _MyFavouritesScreenState extends State<MyFavouritesScreen> {
  String _selectedItemType = 'lost'; // Default selection

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Favourites',style: TextStyle(color: Colors.white),),
          backgroundColor: Colors.green,
          bottom: TabBar(
            onTap: (index) {
              setState(() {
                if (index == 0) {
                  _selectedItemType = 'lost';
                } else if (index == 1) {
                  _selectedItemType = 'found';
                } else if (index == 2) {
                  _selectedItemType = 'marketplace';
                }
              });
            },
            tabs: const [
              Tab(text: 'Lost'),
              Tab(text: 'Found'),
              Tab(text: 'Marketplace'),
            ],
          ),
        ),
        body: _buildFavouritesItems(),
      ),
    );
  }

  Widget _buildFavouritesItems() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('No user logged in'));
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (userSnapshot.hasError) {
          return Center(child: Text('Error: ${userSnapshot.error}'));
        }
        if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
          return const Center(child: Text('No user data found'));
        }

        final userData = userSnapshot.data!.data() as Map<String, dynamic>;
        final myFavourites = userData['myFavourites'] as List<dynamic>? ?? [];

        // Handle the case where the myFavourites list is empty
        if (myFavourites.isEmpty) {
          return const Center(child: Text('No favourite items.'));
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('items')
              .where(FieldPath.documentId, whereIn: myFavourites)
              .where('itemType', isEqualTo: _selectedItemType)
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
              return const Center(child: Text('No favourite items'));
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
                  item['itemImages'],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildItemCard(String documentId, String itemName, String itemLocation, Timestamp itemDate, List<dynamic> imagePath) {
    final user = FirebaseAuth.instance.currentUser;
    final locationBeforeComma = itemLocation.split(',')[0];

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(user?.uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        final userData = snapshot.data?.data() as Map<String, dynamic>? ?? {};
        final myFavourites = userData['myFavourites'] as List<dynamic>? ?? [];
        bool isFavourite = myFavourites.contains(documentId);

        return Card(
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
              Positioned(
                top: 8.0,
                right: 8.0,
                child: IconButton(
                  icon: Icon(
                    isFavourite ? Icons.favorite : Icons.favorite_border,
                    color: isFavourite ? Colors.red : Colors.grey,
                    size: 22,
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
        );
      },
    );
  }
}
