import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pakfoundf/ForgetPassword/forget_pass_form.dart';
import 'package:pakfoundf/loginAndSignup/loginScreen.dart';
import 'package:pakfoundf/Profile/changeLang.dart';
import 'package:pakfoundf/Profile/privacySettings.dart';
import 'package:pakfoundf/Profile/rateApp.dart';
import 'package:pakfoundf/Profile/support.dart';
import 'package:pakfoundf/Profile/termsConditions.dart';
import 'package:pakfoundf/api/firebase_api.dart';
//import 'package:pakfoundf/firebase_api.dart'; // Import FirebaseAPI

class SettingsScreen extends StatelessWidget {
  const SettingsScreen();

  @override
  Widget build(BuildContext context) {
    FirebaseAPI firebaseAPI = FirebaseAPI(); // Create an instance of FirebaseAPI

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        backgroundColor: Colors.green,
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text('Push Notification'),
            trailing: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(FirebaseAuth.instance.currentUser?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return CircularProgressIndicator();
                }
                bool isEnabled = snapshot.data?['push_notifications'] ?? false;
                return Switch(
                  value: isEnabled,
                  onChanged: (bool value) async {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(FirebaseAuth.instance.currentUser?.uid)
                        .update({'push_notifications': value})
                        .then((_) async {
                      // Successfully updated value
                      if (value) {
                        await firebaseAPI.enablePushNotifications();
                      } else {
                        await firebaseAPI.disablePushNotifications();
                      }
                    }).catchError((error) {
                      // Handle error
                      print("Failed to update push notifications: $error");
                    });
                  },
                );
              },
            ),
          ),
          Divider(),
          ListTile(
            title: Text('Change Password'),
            trailing: Icon(Icons.arrow_forward),
            onTap: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return ResetPasswordDialog(autofillEmail: true);
                },
              );
            },
          ),
          Divider(),
          ListTile(
            title: Text('Privacy Settings'),
            trailing: Icon(Icons.arrow_forward),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PrivacySettingsScreen()),
              );
            },
          ),
          Divider(),
          ListTile(
            title: Text('Terms & Conditions'),
            trailing: Icon(Icons.arrow_forward),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => TermsConditionsScreen()),
              );
            },
          ),
          Divider(),
          ListTile(
            title: Text('Change Language'),
            trailing: Icon(Icons.arrow_forward),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChangeLanguageScreen(),
                ),
              );
            },
          ),
          Divider(),
          ListTile(
            title: Text('Biometric'),
            trailing: Switch(
              value: false,
              onChanged: (bool value) {
                // Handle switch state change
              },
            ),
          ),
          Divider(),
          ListTile(
            title: Text('Support'),
            trailing: Icon(Icons.arrow_forward),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SupportScreen()),
              );
            },
          ),
          Divider(),
          ListTile(
            title: Text('Rate App'),
            trailing: Icon(Icons.arrow_forward),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => RateAppScreen()),
              );
            },
          ),
          Divider(),
          ListTile(
            title: Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () async {
              try {
                // Update the isLoggedIn field to false
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(FirebaseAuth.instance.currentUser?.uid)
                    .update({'isLoggedIn': false,
                              'isDisplayAddressEnabled':false,
                              'isDisplayMobileEnabled':false,
                              'isDisplayPhotoEnabled':false,
                              'push_notifications': false});
                    
                    // await FirebaseFirestore.instance
                    //     .collection('users')
                    //     .doc(FirebaseAuth.instance.currentUser?.uid)
                    //     .update({'push_notifications': false});

                // Sign out the user
                await FirebaseAuth.instance.signOut();

                // Navigate back to login screen
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Login()),
                ); // Replace with your login screen route
              } catch (e) {
                // Show error dialog if any error occurs
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('Error'),
                      content: Text('Failed to logout: $e'),
                      actions: [
                        TextButton(
                          child: Text('OK'),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    );
                  },
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
