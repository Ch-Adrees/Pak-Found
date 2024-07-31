import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class UploadToMarketplaceScreen extends StatefulWidget {
  final String itemName;
  final String itemCategory;
  final String itemLocation;
  final String itemDescription;
  final List<dynamic> itemImagePathList; // Updated to handle a list of image paths
  final String documentId;

  const UploadToMarketplaceScreen({
    Key? key,
    required this.itemName,
    required this.itemCategory,
    required this.itemLocation,
    required this.itemDescription,
    required this.itemImagePathList, // Updated to handle a list of image paths
    required this.documentId,
  }) : super(key: key);

  @override
  _UploadToMarketplaceScreenState createState() => _UploadToMarketplaceScreenState();
}

class _UploadToMarketplaceScreenState extends State<UploadToMarketplaceScreen> {
  TextEditingController priceController = TextEditingController();
  bool faceToFaceShipment = false;
  bool tntCourierService = false;

  void _uploadToMarketplace() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    FirebaseFirestore.instance.collection('items').doc(widget.documentId).update({
      'itemType': 'marketplace',
      'itemPrice': double.tryParse(priceController.text) ?? 0.0,
      'shippingMethod': {
        'faceToFace': faceToFaceShipment,
        'tntCourier': tntCourierService,
      },
    }).then((_) {
      Navigator.pop(context);
    }).catchError((error) {
      print("Failed to update item: $error");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload to Marketplace', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              widget.itemImagePathList.isNotEmpty
                  ? Container(
                      height: 200,
                      child: PageView.builder(
                        itemCount: widget.itemImagePathList.length,
                        itemBuilder: (context, index) {
                          return kIsWeb
                              ? Image.network(
                                  widget.itemImagePathList[index],
                                  height: 200,
                                  width: 200,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  height: 180,
                                  width: 190,
                                  decoration: BoxDecoration(
                                    image: DecorationImage(
                                      image: FileImage(File(widget.itemImagePathList[index])),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                );
                        },
                      ),
                    )
                  : const Text('No Image'),
              Text('Name: ${widget.itemName}'),
              Text('Category: ${widget.itemCategory}'),
              Text('Location: ${widget.itemLocation}'),
              Text('Description: ${widget.itemDescription}'),
              const SizedBox(height: 20),
              const Text(
                'Price',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              TextFormField(
                controller: priceController,
                decoration: const InputDecoration(labelText: 'Enter Price'),
                keyboardType: TextInputType.number,
              ),
              const Text(
                'Shipment Methods',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              CheckboxListTile(
                title: const Text('Face to Face'),
                value: faceToFaceShipment,
                onChanged: (bool? value) {
                  setState(() {
                    faceToFaceShipment = value ?? false;
                  });
                },
              ),
              CheckboxListTile(
                title: const Text('TNT Courier Service'),
                value: tntCourierService,
                onChanged: (bool? value) {
                  setState(() {
                    tntCourierService = value ?? false;
                  });
                },
              ),
              ElevatedButton(
                onPressed: _uploadToMarketplace,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                child: const Text('Upload to Marketplace'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
