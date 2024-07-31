import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PrivacySettingsScreen extends StatefulWidget {
  @override
  _PrivacySettingsScreenState createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  bool _isTextChatEnabled = true;
  bool _isDisplayMobileEnabled = true;
  bool _isDisplayPhotoEnabled = true;
  bool _isDisplayAddressEnabled = true;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadPrivacySettings();
  }

  Future<void> _loadPrivacySettings() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        setState(() {
          _isTextChatEnabled = userDoc.get('isTextChatEnabled') ?? true;
          _isDisplayMobileEnabled = userDoc.get('isDisplayMobileEnabled') ?? true;
          _isDisplayPhotoEnabled = userDoc.get('isDisplayPhotoEnabled') ?? true;
          _isDisplayAddressEnabled = userDoc.get('isDisplayAddressEnabled') ?? true;
        });
      }
    }
  }

  Future<void> _updatePrivacySetting(String field, bool value) async {
    User? user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({
        field: value,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Text('Privacy Settings',style: TextStyle(color: Colors.white),),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Chat',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 10),
              buildSwitchListTile(
                'Text Chat',
                _isTextChatEnabled,
                (bool value) {
                  setState(() {
                    _isTextChatEnabled = value;
                  });
                  _updatePrivacySetting('isTextChatEnabled', value);
                },
              ),
              SizedBox(height: 20),
              buildSwitchListTile(
                'Display Mobile',
                _isDisplayMobileEnabled,
                (bool value) {
                  setState(() {
                    _isDisplayMobileEnabled = value;
                  });
                  _updatePrivacySetting('isDisplayMobileEnabled', value);
                },
              ),
              buildSwitchListTile(
                'Display Photo',
                _isDisplayPhotoEnabled,
                (bool value) {
                  setState(() {
                    _isDisplayPhotoEnabled = value;
                  });
                  _updatePrivacySetting('isDisplayPhotoEnabled', value);
                },
              ),
              buildSwitchListTile(
                'Display Address',
                _isDisplayAddressEnabled,
                (bool value) {
                  setState(() {
                    _isDisplayAddressEnabled = value;
                  });
                  _updatePrivacySetting('isDisplayAddressEnabled', value);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildSwitchListTile(String title, bool currentValue, Function(bool) updateValue) {
    return ListTile(
      title: Text(title),
      trailing: Switch(
        value: currentValue,
        onChanged: updateValue,
        activeColor: Colors.green,
      ),
    );
  }
}
