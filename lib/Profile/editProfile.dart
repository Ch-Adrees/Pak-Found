import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EditProfileScreen extends StatefulWidget {
  final String uid;

  EditProfileScreen({required this.uid});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late String _phoneNumber;
  late List<String> _location;
  late String _profilePic;
  bool _isLoading = true;
  File? _newProfilePicFile;

  final TextEditingController _regionController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(widget.uid).get();
      if (userDoc.exists) {
        var userData = userDoc.data() as Map<String, dynamic>;
        setState(() {
          _name = userData['name'] ?? '';
          _phoneNumber = userData['phoneNumber'] ?? '';
          _location = List<String>.from(userData['location'] ?? []);
          if (_location.length == 3) {
            _regionController.text = _location[0];
            _cityController.text = _location[1];
            _countryController.text = _location[2];
          }
          _profilePic = userData['profilePic'] ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to fetch user data')));
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      File? croppedFile = await ImageCropper().cropImage(
        sourcePath: image.path,
        aspectRatioPresets: [
          CropAspectRatioPreset.square,
        ],
        androidUiSettings: AndroidUiSettings(
          toolbarTitle: 'Crop Image',
          toolbarColor: Colors.green,
          toolbarWidgetColor: Colors.white,
          activeControlsWidgetColor: Colors.green,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: true,
        ),
        iosUiSettings: IOSUiSettings(
          minimumAspectRatio: 1.0,
        ),
      );
      if (croppedFile != null) {
        setState(() {
          _newProfilePicFile = croppedFile;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Image cropping failed')));
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location services are disabled.')),
      );
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location permissions are denied.')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location permissions are permanently denied, we cannot request permissions.')),
      );
      return;
    }

    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    String location = await _getReadableLocation(position.latitude, position.longitude);

    List<String> locationParts = location.split(', ');
    setState(() {
      if (locationParts.length >= 3) {
        _regionController.text = locationParts[0];
        _cityController.text = locationParts[1];
        _countryController.text = locationParts[2];
      }
    });
  }

  Future<String> _getReadableLocation(double latitude, double longitude) async {
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
      print('Error in _getReadableLocation: $e');
      return 'Failed to get location';
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() {
        _isLoading = true;
      });

      String? profilePicUrl = _profilePic;

      if (_newProfilePicFile != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('user_profile_pics')
            .child(widget.uid + '.jpg');
        await ref.putFile(_newProfilePicFile!);
        profilePicUrl = await ref.getDownloadURL();
      }

      _location = [
        _regionController.text.isNotEmpty ? _regionController.text : '',
        _cityController.text.isNotEmpty ? _cityController.text : '',
        _countryController.text.isNotEmpty ? _countryController.text : '',
      ];

      await FirebaseFirestore.instance.collection('users').doc(widget.uid).update({
        'name': _name,
        'phoneNumber': _phoneNumber,
        'location': _location,
        'profilePic': profilePicUrl,
      });

      setState(() {
        _isLoading = false;
      });

      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile',style: TextStyle(color: Colors.white),),
        backgroundColor: Colors.green,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: 20),
                    CircleAvatar(
                      radius: 70,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: _newProfilePicFile != null
                          ? FileImage(_newProfilePicFile!)
                          : _profilePic.isNotEmpty
                              ? NetworkImage(_profilePic)
                              : AssetImage('assets/petimg.png') as ImageProvider,
                    ),
                    SizedBox(height: 10),
                    TextButton(
                     
onPressed: _pickImage,
                      child: Text(
                        'Change Picture',
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                    SizedBox(height: 20),
                    TextFormField(
                      initialValue: _name,
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        border: OutlineInputBorder(),
                      ),
                      onSaved: (value) => _name = value!,
                    ),
                    SizedBox(height: 20),
                    TextFormField(
                      initialValue: _phoneNumber,
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                      onSaved: (value) => _phoneNumber = value!,
                    ),
                    SizedBox(height: 20),
                    TextFormField(
                      controller: _regionController,
                      decoration: InputDecoration(
                        labelText: 'Region',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 20),
                    TextFormField(
                      controller: _cityController,
                      decoration: InputDecoration(
                        labelText: 'Area',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 20),
                    TextFormField(
                      controller: _countryController,
                      decoration: InputDecoration(
                        labelText: 'City/Country',
                        border: OutlineInputBorder(),
                      ),
                    ),
                      SizedBox(height: 20),
                    TextButton(
                      onPressed: _getCurrentLocation,
                      child: Text(
                        'Use Current Location',
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _saveProfile,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white, backgroundColor: Colors.green, // foreground color
                      ),
                      child: Text('Save'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
