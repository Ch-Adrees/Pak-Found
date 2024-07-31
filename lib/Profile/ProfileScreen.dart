import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pakfoundf/Profile/editProfile.dart';
import 'package:pakfoundf/Profile/Settingscreen.dart';
import 'package:pakfoundf/Profile/myFvourites.dart';
import 'package:pakfoundf/Profile/myItems.dart';

class ProfileScreen extends StatelessWidget {
  ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User?>(
      future: FirebaseAuth.instance.authStateChanges().first,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(
              title: Text('Profile',style: TextStyle(color: Colors.white),),
              backgroundColor: Colors.green,
            ),
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(title: Text('Profile',style: TextStyle(color: Colors.white),)),
            body: Center(child: Text("User not authenticated")),
          );
        }

        final user = snapshot.data;
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(user!.uid).snapshots(),
          builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
            if (snapshot.hasError) {
              return Scaffold(
                appBar: AppBar(title: Text('Profile',style: TextStyle(color: Colors.white),)),
                body: Center(child: Text('Error: ${snapshot.error}')),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return Scaffold(
                appBar: AppBar(title: Text('Profile',style: TextStyle(color: Colors.white),)),
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return Scaffold(
                appBar: AppBar(title: Text('Profile',style: TextStyle(color: Colors.white),)),
                body: Center(child: Text('User data not found')),
              );
            }

            var userData = snapshot.data!.data() as Map<String, dynamic>;
            return Scaffold(
              appBar: AppBar(title: Text('Profile',style: TextStyle(color: Colors.white),), backgroundColor: Colors.green),
              body: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    IconButton(
                      alignment: Alignment.topRight,
                      icon: Icon(Icons.edit),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditProfileScreen(uid: user.uid),
                          ),
                        );
                      },
                    ),
                    ProfileHeader(userData: userData, userEmail: user.email!),
                    SizedBox(height: 20),
                    buildMenuButton(context, Icons.shopping_bag, 'My Items', MyUploadsScreen()),
                    SizedBox(height: 10),
                    buildMenuButton(context, Icons.favorite, 'Favorites', MyFavouritesScreen()),
                    SizedBox(height: 10),
                    buildMenuButton(context, Icons.settings, 'Settings', SettingsScreen()),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget buildMenuButton(BuildContext context, IconData icon, String label, Widget screen) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        margin: EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 2,
              blurRadius: 5,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: icon == Icons.favorite ? Colors.red : Colors.black),
            SizedBox(width: 20),
            Text(label),
            Spacer(),
            Icon(Icons.arrow_forward),
          ],
        ),
      ),
    );
  }
}

class ProfileHeader extends StatelessWidget {
  final Map<String, dynamic> userData;
  final String userEmail;

  ProfileHeader({required this.userData, required this.userEmail});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 70,
            backgroundColor: Colors.grey[300],
            backgroundImage: userData['profilePic'] != null && userData['profilePic'] != ''
                ? NetworkImage(userData['profilePic'])
                : AssetImage('assets/petimg.png') as ImageProvider,
          ),
          SizedBox(height: 20),
          Text(
            userData['name'] ?? 'Name not available',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),
          Text(
            userEmail,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 10),
          Text(
            userData['phoneNumber'] ?? 'Phone number not available',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 10),
          Text(
            _buildLocation(userData['location']),
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  String _buildLocation(dynamic locationData) {
    if (locationData is List && locationData.length == 3) {
      return '${locationData[0]}, ${locationData[1]}, ${locationData[2]}';
    }
    else if(locationData is List && locationData.length == 2){
      return '${locationData[0]}, ${locationData[1]}';
      }
    else if(locationData is List && locationData.length == 1){
      return '${locationData[0]}';
      }
    return 'Location not available';
  }
}
