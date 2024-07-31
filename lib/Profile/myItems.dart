import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:pakfoundf/Upload/item_details.dart';
//import 'item_details_screen.dart';

class MyUploadsScreen extends StatefulWidget {
  final int initialTabIndex;

  const MyUploadsScreen({Key? key, this.initialTabIndex = 0}) : super(key: key);

  @override
  _MyUploadsScreenState createState() => _MyUploadsScreenState();
}

class _MyUploadsScreenState extends State<MyUploadsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedItemType = 'lost';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: widget.initialTabIndex);
    _tabController.addListener(() {
      setState(() {
        switch (_tabController.index) {
          case 0:
            _selectedItemType = 'lost';
            break;
          case 1:
            _selectedItemType = 'found';
            break;
          case 2:
            _selectedItemType = 'marketplace';
            break;
        }
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Uploads',style: TextStyle(color: Colors.white),),
        backgroundColor: Colors.green,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Lost'),
            Tab(text: 'Found'),
            Tab(text: 'Marketplace'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUploadedItems('lost'),
          _buildUploadedItems('found'),
          _buildUploadedItems('marketplace'),
        ],
      ),
    );
  }

  Widget _buildUploadedItems(String itemType) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('No user logged in'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('items')
          .where('uploadedBy', isEqualTo: user.uid)
          .where('itemType', isEqualTo: itemType)
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
          return const Center(child: Text('No items found.'));
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16.0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16.0,
            crossAxisSpacing: 16.0,
            childAspectRatio: 0.75,
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
            builder: (context) => ItemDetailsScreen(documentId: documentId, isFavorited: false,),
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
                icon: const Icon(
                  Icons.delete,
                  color: Colors.red,
                  size: 22,
                ),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text('Delete Item'),
                        content: const Text('Are you sure you want to delete this item?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Delete'),
                          ),
                        ],
                      );
                    },
                  );

                  if (confirm == true) {
                    await FirebaseFirestore.instance.collection('items').doc(documentId).delete();
                    setState(() {});
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
