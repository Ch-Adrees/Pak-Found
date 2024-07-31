import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:pakfoundf/Services/location_service.dart';
import 'package:http/http.dart' as http;

class FoundItemForm extends StatefulWidget {
  const FoundItemForm({super.key});

  @override
  _FoundItemFormState createState() => _FoundItemFormState();
}

class _FoundItemFormState extends State<FoundItemForm> with SingleTickerProviderStateMixin {
  bool rewardEnabled = false;
  bool _isUploading = false;  // New state variable for loading
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  String? selectedCategory;
  List<String> selectedImagePaths = [];

  final TextEditingController itemNameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController rewardController = TextEditingController();

  late AnimationController _animationController;
  late Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = Tween<Offset>(begin: const Offset(0, 1), end: const Offset(0, 0))
        .animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    itemNameController.dispose();
    descriptionController.dispose();
    locationController.dispose();
    rewardController.dispose();
    super.dispose();
  }

  Future<void> _getImage() async {
    final picker = ImagePicker();
    final pickedFile = await showDialog<File?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose an image source'),
        actions: [
          TextButton(
            onPressed: () async {
              final picked = await picker.pickImage(source: ImageSource.camera);
              Navigator.of(context).pop(picked != null ? File(picked.path) : null);
            },
            child: const Text('Camera'),
          ),
          TextButton(
            onPressed: () async {
              final picked = await picker.pickImage(source: ImageSource.gallery);
              Navigator.of(context).pop(picked != null ? File(picked.path) : null);
            },
            child: const Text('Gallery'),
          ),
        ],
      ),
    );

    if (pickedFile != null) {
      setState(() {
        selectedImagePaths.add(pickedFile.path);
      });
    }
  }


  Future<String> getReadableLocation(double latitude, double longitude) async {
    const apiKey = 'f60d0faffe564011a83ce605cd8e9c4a'; // Replace with your OpenCage API key
    final url = Uri.parse('https://api.opencagedata.com/geocode/v1/json?q=$latitude+$longitude&key=$apiKey');

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
      Position? position = await LocationService.getCurrentLocation();
      if (position == null) {
        throw Exception('Position is null');
      }

      print('Position retrieved: ${position.latitude}, ${position.longitude}');
      String displayLocation = await getReadableLocation(position.latitude, position.longitude);

      print('Display location: $displayLocation');

      setState(() {
        locationController.text = displayLocation;
      });
    } catch (e) {
      print('Error in _getCurrentLocation: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to get location: $e')),
      );
    }
  }

  Future<void> _submitForm() async {
    if (itemNameController.text.isEmpty || selectedDate == null || selectedTime == null || selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    if (rewardEnabled && (rewardController.text.isEmpty || double.tryParse(rewardController.text) == null || double.parse(rewardController.text) == 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reward should be a non-zero number')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be signed in to report an item')),
      );
      return;
    }
    final founder = user.uid;

    final dateTime = DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      selectedTime!.hour,
      selectedTime!.minute,
    );

    final itemData = {
      'uploadedBy': founder,
      'name': itemNameController.text,
      'dateTime': Timestamp.fromDate(dateTime),
      'itemCategory': selectedCategory,
      'description': descriptionController.text,
      'rewardAmount': rewardEnabled ? double.parse(rewardController.text) : null,
      'itemLocation': locationController.text,
      'itemType': 'found',
    };

    try {
      setState(() {
        _isUploading = true;  // Start loading
      });

      List<String> imageUrls = [];

      for (String path in selectedImagePaths) {
        final file = File(path);
        final storageRef = FirebaseStorage.instance.ref().child('item_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
        final uploadTask = storageRef.putFile(file);
        final snapshot = await uploadTask;
        final downloadUrl = await snapshot.ref.getDownloadURL();
        imageUrls.add(downloadUrl);
      }

      // Add the image URLs to the item data
      itemData['itemImages'] = imageUrls;

      await FirebaseFirestore.instance.collection('items').add(itemData);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item reported successfully')),
      );

      setState(() {
        itemNameController.clear();
        descriptionController.clear();
        locationController.clear();
        rewardController.clear();
        selectedDate = null;
        selectedTime = null;
        selectedCategory = null;
        selectedImagePaths.clear();
        rewardEnabled = false;
      });

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to report item: $e')),
      );
    } finally {
      setState(() {
        _isUploading = false;  // Stop loading
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      selectedImagePaths.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Found Item', style: TextStyle(color: Colors.white),),
        backgroundColor: Colors.green,
      ),
      body: Stack(  // Use Stack to overlay the loader
        children: [
          SlideTransition(
            position: _animation,
            child: Center(
              child: Container(
                width: screenWidth * 0.9,
                height: screenHeight * 0.9,
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: itemNameController,
                        decoration: InputDecoration(
                          labelText: 'Name Of Item*',
                          labelStyle: TextStyle(color: Colors.green),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.green),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.green),
                          ),
                        ),
                        maxLength: 15,
                        onChanged: (value) {
                          if (value.isNotEmpty) {
                            final firstLetter = value[0].toUpperCase();
                            final restOfString = value.substring(1);
                            itemNameController.value = TextEditingValue(
                              text: '$firstLetter$restOfString',
                              selection: TextSelection.fromPosition(
                                TextPosition(offset: itemNameController.text.length),
                              ),
                            );
                          }
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Name of item is required';
                          }
                          return null;
                        },
                      ),
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Category*',
                          labelStyle: TextStyle(color: Colors.green),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.green),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.green),
                          ),
                        ),
                        value: selectedCategory,
                        onChanged: (newValue) {
                          setState(() {
                            selectedCategory = newValue;
                          });
                        },
                        items: <String>['Pet', 'Documents', 'Any Other Item']
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Category is required';
                          }
                          return null;
                        },
                      ),
                      _buildElevatedContainer(
                        title: 'When',
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                selectedDate != null && selectedTime != null
                                    ? 'Found on: ${DateFormat.yMMMd().format(selectedDate!)} ${selectedTime!.format(context)}'
                                    : 'Select Date & Time*',
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.calendar_today, color: Colors.green),
                              onPressed: () async {
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
                                    setState(() {
                                      selectedDate = date;
                                      selectedTime = time;
                                    });
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      _buildElevatedContainer(
                        title: 'Where',
                        child: Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: locationController,
                                decoration: const InputDecoration(
                                  labelText: 'Enter or choose current location*',
                                  labelStyle: TextStyle(color: Colors.green),
                                  enabledBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(color: Colors.green),
                                  ),
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(color: Colors.green),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Location is required';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.my_location, color: Colors.green),
                              onPressed: _getCurrentLocation,
                            ),
                          ],
                        ),
                      ),
                      _buildElevatedContainer(
                        title: 'Item images',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              height: 100,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: 3,
                                itemBuilder: (context, index) {
                                  return Container(
                                    width: 100,
                                    margin: EdgeInsets.symmetric(horizontal: 4.0),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Stack(
                                      children: [
                                        if (index < selectedImagePaths.length)
                                          Image.file(
                                            File(selectedImagePaths[index]),
                                            fit: BoxFit.cover,
                                            width: 100,
                                            height: 100,
                                          )
                                        else
                                          Center(
                                            child: IconButton(
                                              icon: Icon(Icons.add, color: Colors.grey, size: 40),
                                              onPressed: _getImage,
                                            ),
                                          ),
                                        if (index < selectedImagePaths.length)
                                          Positioned(
                                            right: 0,
                                            child: GestureDetector(
                                              onTap: () => _removeImage(index),
                                              child: Container(
                                                color: Colors.black54,
                                                child: Icon(Icons.close, color: Colors.white),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextFormField(
                        controller: descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Description*',
                          labelStyle: TextStyle(color: Colors.green),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.green),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.green),
                          ),
                        ),
                        maxLength: 100,
                        onChanged: (value) {
                          if (value.isNotEmpty) {
                            final firstLetter = value[0].toUpperCase();
                            final restOfString = value.substring(1);
                            descriptionController.value = TextEditingValue(
                              text: '$firstLetter$restOfString',
                              selection: TextSelection.fromPosition(
                                TextPosition(offset: descriptionController.text.length),
                              ),
                            );
                          }
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Description is required';
                          }
                          return null;
                        },
                      ),
                      // Row(
                      //   children: [
                      //     const Text('Reward'),
                      //     Checkbox(
                      //       value: rewardEnabled,
                      //       onChanged: (bool? value) {
                      //         setState(() {
                      //           rewardEnabled = value ?? false;
                      //         });
                      //       },
                      //     ),
                      //     if (rewardEnabled)
                      //       Expanded(
                      //         child: TextFormField(
                      //           controller: rewardController,
                      //           decoration: const InputDecoration(
                      //             labelText: 'Reward Amount',
                      //             labelStyle: TextStyle(color: Colors.green),
                      //             enabledBorder: UnderlineInputBorder(
                      //               borderSide: BorderSide(color: Colors.green),
                      //             ),
                      //             focusedBorder: UnderlineInputBorder(
                      //               borderSide: BorderSide(color: Colors.green),
                      //             ),
                      //           ),
                      //           keyboardType: TextInputType.number,
                      //         ),
                      //       ),
                      //   ],
                      // ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _isUploading ? null : _submitForm,  // Disable button when uploading
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        child: const Text('Submit', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_isUploading)  // Show loader when uploading
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildElevatedContainer({required String title, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
