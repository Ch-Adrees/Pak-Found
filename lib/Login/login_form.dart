import 'dart:io'; // For InternetAddress
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pakfoundf/ForgetPassword/forget_pass_form.dart';
import 'package:pakfoundf/HelperMaterial/constant.dart';
import 'package:pakfoundf/HelperMaterial/no_account_text.dart';
import 'package:pakfoundf/HomePage/HomeScreen.dart'; // Import the flutter_svg package

class SigninForm extends StatefulWidget {
  const SigninForm({Key? key}) : super(key: key);

  @override
  State<SigninForm> createState() => _SigninFormState();
}

class _SigninFormState extends State<SigninForm> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  String? email;
  String? password;
  bool _isObscure = true;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Login Fields
          TextFormField(
            keyboardType: TextInputType.emailAddress,
            onSaved: (newValue) => email = newValue,
            onChanged: (value) {
              setState(() {
                email = value.trim();
              });
            },
            validator: (value) {
              if (value!.isEmpty) {
                return 'Please enter your email';
              }
              return null;
            },
            decoration: const InputDecoration(
              labelText: "Email",
              hintText: "Enter your email",
              floatingLabelBehavior: FloatingLabelBehavior.always,
              suffixIcon: Icon(Icons.email),
            ),
          ),
          const SizedBox(height: 10),
          TextFormField(
            obscureText: _isObscure,
            onSaved: (newValue) => password = newValue,
            onChanged: (value) {
              setState(() {
                password = value.trim();
              });
            },
            validator: (value) {
              if (value!.isEmpty) {
                return 'Please enter your password';
              } else if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
            decoration: InputDecoration(
              labelText: "Password",
              hintText: "Enter your password",
              floatingLabelBehavior: FloatingLabelBehavior.always,
              suffixIcon: IconButton(
                icon: Icon(
                  _isObscure ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _isObscure = !_isObscure;
                  });
                },
              ),
            ),
          ),
          // Forgot Password
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed:  () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return ResetPasswordDialog();
              },);},
              child: Text(
                "Forgot Password?",
                style: TextStyle(color: Theme.of(context).primaryColorDark),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Login Button
          SizedBox(
            width: MediaQuery.of(context).size.width * 2 / 3, // 2/3 of screen width
            child: ElevatedButton(
              onPressed: _signInWithEmailPassword,
              style: ElevatedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.onPrimary, backgroundColor: kPrimaryColor, // White text
              ),
              child: const Text("Sign In"),
            ),
          ),
          const SizedBox(height: 10),
          // Social Login Button
          ElevatedButton(
            onPressed: _signInWithGoogle,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white, // White button
              shape: CircleBorder(), // Circular button
              padding: EdgeInsets.all(12), // Button padding
            ),
            child: SvgPicture.asset(
              'assets/icons/google-icon.svg', // Path to your Google icon SVG file
              width: 24,
              height: 24,
            ),
          ),
          // No Account Text
          const NoAccountText(),
        ],
      ),
    );
  }

  Future<void> _signInWithEmailPassword() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      try {
        // Check for internet connection
        final result = await InternetAddress.lookup('google.com');
        if (result.isEmpty || result[0].rawAddress.isEmpty) {
          _showDialog('Error', 'Internet connection is unstable or unavailable.');
          return;
        }
      } on SocketException catch (_) {
        _showDialog('Error', 'Internet connection is unstable or unavailable.');
        return;
      }

      try {
        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: email!,
          password: password!,
        );
        User? user = userCredential.user;

        if (user != null) {
          DocumentReference userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
          DocumentSnapshot userSnapshot = await userDoc.get();
          if (!userSnapshot.exists) {
            await userDoc.set({
              'email': user.email ?? '',
            });
          }

          // Update or create the "isLoggedIn" field
          await userDoc.update({'isLoggedIn': true});

          if (!user.emailVerified) {
            _showDialog('Email Not Verified', 'Please verify your email.');
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          }
        }
      } catch (error) {
        if (error is FirebaseAuthException) {
          if (error.code == 'user-not-found') {
            _showDialog('Error', 'User not found. Please check your credentials.');
          } else if (error.code == 'wrong-password') {
            _showDialog('Error', 'Incorrect password. Please try again.');
          } else {
            _showDialog('Error', 'Failed to sign in. Please try again later.');
          }
        } else {
          _showDialog('Error', 'Failed to sign in. Please try again later.');
        }
      }
    }
  }


 Future<void> _signInWithGoogle() async {
  try {
    GoogleSignInAccount? googleUser = await _googleSignIn.signInSilently();
    if (googleUser != null) {
      await _googleSignIn.signOut();
    }

    googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      return;
    }

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    UserCredential userCredential = await _auth.signInWithCredential(credential);

    // Check if the user document already exists
      DocumentReference userDoc = FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid);
      DocumentSnapshot userSnapshot = await userDoc.get();

      if (!userSnapshot.exists) {
        // Only set the document fields if it does not exist
        await userDoc.set({
          'name': googleUser.displayName ?? '',
          'email': userCredential.user!.email,
          'push_notifications': true,
          'profilePic': '',
          'isLoggedIn': true, // Set "isLoggedIn" field
        });
      } else {
        // Update "isLoggedIn" field if the document exists
        await userDoc.update({'isLoggedIn': true});
      }


    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  } catch (error) {
    _showDialog('Error', 'Failed to sign in with Google. Please check your network connection and try again.');
  }
}


  void _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK', style: TextStyle(color: Theme.of(context).primaryColorDark)),
            ),
          ],
        );
      },
    );
  }
}
