import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart'; // For loading spinner
import 'package:pakfoundf/Upload/item_details.dart';
import 'package:pakfoundf/Services/location_service.dart';

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String query = '';
  String? location;
  DateTime? fromDate;
  DateTime? toDate;
  String? _selectedCategory;
  String? _selectedItemType;
  bool _isLoading = false; // Add this variable


  TextEditingController _locationController = TextEditingController();
  TextEditingController _searchController = TextEditingController();

  bool _isFilterExpanded = false;
  bool _hasSearched = false;

  Future<List<QueryDocumentSnapshot>> _fetchItems() async {
    Query queryRef = FirebaseFirestore.instance.collection('items');

    if (query.isNotEmpty) {
      queryRef = queryRef
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: '$query\uf8ff');
    }

    if (location != null && location!.isNotEmpty) {
      queryRef = queryRef
          .where('itemLocation', isGreaterThanOrEqualTo: location)
          .where('itemLocation', isLessThanOrEqualTo: '$location\uf8ff');
    }

    if (fromDate != null && toDate != null) {
      queryRef = queryRef
          .where('dateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(fromDate!))
          .where('dateTime', isLessThanOrEqualTo: Timestamp.fromDate(toDate!));
    }

    if (_selectedCategory != null) {
      queryRef = queryRef.where('itemCategory', isEqualTo: _selectedCategory);
    }

    if (_selectedItemType != null) {
      queryRef = queryRef.where('itemType', isEqualTo: _selectedItemType);
    }

    final snapshot = await queryRef.get();
    return snapshot.docs;
  }

  Future<String> getReadableLocation(double latitude, double longitude) async {
    const apiKey = 'f60d0faffe564011a83ce605cd8e9c4a'; // Replace with your OpenCage API key
    final url = Uri.parse(
        'https://api.opencagedata.com/geocode/v1/json?q=$latitude+$longitude&key=$apiKey');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['results'].isNotEmpty) {
          final formattedAddress = data['results'][0]['formatted'];
          return formattedAddress ?? 'Unknown location';
        } else {
          return 'Unknown location';
        }
      } else {
        return 'Failed to get location';
      }
    } catch (e) {
      print('Error in getReadableLocation: $e');
      return 'Failed to get location';
    }
  }

  Future<void> _getCurrentLocation() async {
    bool permissionGranted = await LocationService.requestLocationPermission();
    if (!permissionGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permission is required')),
      );
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition();
      String displayLocation = await getReadableLocation(
          position.latitude, position.longitude);

      setState(() {
        _locationController.text = displayLocation;
        location = displayLocation;
      });
    } catch (e) {
      print('Error in _getCurrentLocation: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to get location: $e')),
      );
    }
  }

  Future<void> _selectDate(BuildContext context, bool isFrom) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (time != null) {
        DateTime selectedDateTime = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );
        if (selectedDateTime.isAfter(DateTime.now())) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You cannot pick a future date and time.')),
          );
        } else {
          setState(() {
            if (isFrom) {
              fromDate = selectedDateTime;
            } else {
              toDate = selectedDateTime;
            }
          });
        }
      }
    }
  }

  void _resetFilters() {
    setState(() {
      location = null;
      fromDate = null;
      toDate = null;
      _selectedCategory = null;
      _selectedItemType = null;
      _locationController.clear();
      _hasSearched = true;
      _isFilterExpanded = false;
    });
  }

  void _applyFilters() {
    setState(() {
      _hasSearched = true;
      _isFilterExpanded = false;
    });
  }

  Widget _buildItemList() {
    return FutureBuilder<List<QueryDocumentSnapshot>>(
      future: _fetchItems(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: SpinKitCircle(
            color: Colors.green,
            size: 50.0,
          ));
        }
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return  Column(
                    children: [
                      Center(
                      //  heightFactor: MediaQuery.sizeOf(context).height*0.01,
                        child: SvgPicture.asset(
                          height:MediaQuery.sizeOf(context).height*0.1,
                          width:MediaQuery.sizeOf(context).width*0.1,
                          'assets/icons/emptySearch.svg',
                          ),
                        ),
                        const Text('No item found',style: TextStyle(color: Colors.black),)]);
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
              item.id,
              item['itemType'],
              item['name'],
              item['itemLocation'],
              item['dateTime'],
              item['itemImages'],
            );
          },
        );
      },
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
                          color: Colors.grey,
                          child: Center(
                            child: Icon(
                              Icons.image_not_supported,
                              color: Colors.white,
                              size: 50.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Item details
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            itemName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            'Location: $locationBeforeComma',
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            'Date: ${DateFormat('dd/MM/yyyy').format(itemDate.toDate())}',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // Favourite icon
                Positioned(
                  top: 0,
                  right: 0,
                  child: IconButton(
                    icon: Icon(
                      isFavourite ? Icons.favorite : Icons.favorite_border,
                      color: isFavourite ? Colors.red : Colors.white,
                    ),
                    onPressed: () async {
                      setState(() {
                        if (isFavourite) {
                          myFavourites.remove(documentId);
                        } else {
                          myFavourites.add(documentId);
                        }
                      });

                      await FirebaseFirestore.instance.collection('users').doc(user?.uid).update({
                        'myFavourites': myFavourites,
                      });
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

  @override
  Widget build(BuildContext context) {
    final inputBorder = OutlineInputBorder(
      borderSide: Divider.createBorderSide(context),
    );

    final isFilterActive = location != null ||
        fromDate != null ||
        toDate != null ||
        _selectedCategory != null ||
        _selectedItemType != null;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text('Search Items',style: TextStyle(color: Colors.white),),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt,semanticLabel: 'Filters',),
            onPressed: () {
              setState(() {
                _isFilterExpanded = !_isFilterExpanded;
              });
            },
          ),
        ],
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 8,),
             Padding(
               padding: const EdgeInsets.fromLTRB(10,10,10,0),
               child: TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() {
                            query = value.trim();
                            query=value[0].toUpperCase();
                          // query = value.trim();
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Search...',
                         // filled: true,
                          border: const UnderlineInputBorder(),
                          enabledBorder: inputBorder,
                         // focusedBorder: inputBorder,
                          contentPadding: const EdgeInsets.all(8.0),
                          prefixIcon: const Icon(Icons.search,color: Colors.green,),
                           suffixIcon: IconButton(
                                      icon: Icon(Icons.clear),
                                      onPressed: () {
                                        setState(() {
                                          _searchController.clear();
                                          query = '';
                                        });
                                      },
                                    ),
               
                         // suffixIcon: IconButton(icon: const Icon(Icons.cancel),onPressed: (){setState(() {
                         //   query='';
                          //});})
                        ),
                      ),
             ),
            SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                    child: Column(
                      children: [
                        if (_isFilterExpanded)
                          Column(
                            children: [
                              const SizedBox(height: 8.0),
                              TextField(
                                controller: _locationController,
                                decoration: InputDecoration(
                                  hintText: 'Enter or choose location',
                                  filled: true,
                                  border: inputBorder,
                                  enabledBorder: inputBorder,
                                  focusedBorder: inputBorder,
                                  contentPadding: const EdgeInsets.all(8.0),
                                  prefixIcon: const Icon(Icons.location_on_outlined,color: Colors.green,),
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.my_location,color: Colors.green,),
                                    onPressed: _getCurrentLocation,
                                  ),
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    location = value.trim();
                                    location=value[0].toUpperCase();
                                    
                                  });
                                },
                              ),
                              const SizedBox(height: 8.0),
                              Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => _selectDate(context, true),
                                      child: AbsorbPointer(
                                        child: TextField(
                                          decoration: InputDecoration(
                                            hintText: fromDate != null
                                                ? 'From: ${DateFormat('dd/MM/yyyy').format(fromDate!)}'
                                                : 'From Date',
                                            filled: true,
                                            prefixIcon: Icon(Icons.date_range,color: Colors.green,),
                                            border: inputBorder,
                                            enabledBorder: inputBorder,
                                            focusedBorder: inputBorder,
                                            contentPadding: const EdgeInsets.all(8.0),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8.0),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => _selectDate(context, false),
                                      child: AbsorbPointer(
                                        child: TextField(
                                          decoration: InputDecoration(
                                            hintText: toDate != null
                                                ? 'To: ${DateFormat('dd/MM/yyyy').format(toDate!)}'
                                                : 'To Date',
                                            filled: true,
                                             prefixIcon: const Icon(Icons.date_range,color: Colors.green,),
                                            border: inputBorder,
                                            enabledBorder: inputBorder,
                                            focusedBorder: inputBorder,
                                            contentPadding: const EdgeInsets.all(8.0),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8.0),
                              DropdownButtonFormField<String>(
                                value: _selectedCategory,
                                decoration: InputDecoration(
                                  hintText: 'Category',
                                  filled: true,
                                   prefixIcon: const Icon(Icons.category,color: Colors.green,),
                                  border: inputBorder,
                                  enabledBorder: inputBorder,
                                  focusedBorder: inputBorder,
                                  contentPadding: const EdgeInsets.all(8.0),
                                ),
                                items: <String>[
                                  'Pet',
                                  'Documents',
                                  'Any Other Item'
                                ].map<DropdownMenuItem<String>>((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _selectedCategory = newValue;
                                  });
                                },
                              ),
                              const SizedBox(height: 8.0),
                              DropdownButtonFormField<String>(
                                value: _selectedItemType,
                                decoration: InputDecoration(
                                  hintText: 'Item Type',
                                  filled: true,
                                   prefixIcon: const Icon(Icons.list,color: Colors.green,),
                                  border: inputBorder,
                                  enabledBorder: inputBorder,
                                  focusedBorder: inputBorder,
                                  contentPadding: const EdgeInsets.all(8.0),
                                ),
                                items: <String>[
                                  'lost',
                                  'found',
                                ].map<DropdownMenuItem<String>>((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _selectedItemType = newValue;
                                  });
                                },
                              ),
                              const SizedBox(height: 8.0),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  ElevatedButton(
                                    style: ButtonStyle(backgroundColor: MaterialStateProperty.all<Color>(Colors.green)),
                                    onPressed: _resetFilters,
                                    child: const Text('Reset Filters',style: TextStyle(color: Colors.white)),
                                  ),
                                  // ElevatedButton(
                                  //   onPressed: _applyFilters,
                                  //   child: const Text('Apply Filters'),
                                  // ),
                                ],
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  if (query.isNotEmpty || isFilterActive)
                    _buildItemList(),
                  if (_hasSearched && query.isEmpty && !isFilterActive)
                    Column(
                      children: [
                        Center(
                        //  heightFactor: MediaQuery.sizeOf(context).height*0.01,
                          child: SvgPicture.asset(
                            height:MediaQuery.sizeOf(context).height*0.1,
                            width:MediaQuery.sizeOf(context).width*0.1,
                            'assets/icons/emptySearch.svg',
                            ),
                          ),
                          const Text('No item found',style: TextStyle(color: Colors.black),),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
