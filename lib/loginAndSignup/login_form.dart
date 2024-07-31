import 'dart:io'; // For InternetAddress
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pakfoundf/ForgetPassword/forget_pass_form.dart';
import 'package:pakfoundf/helpingMaterial/constant.dart';
import 'package:pakfoundf/helpingMaterial/no_account_text.dart';
import 'package:pakfoundf/homeScreen/HomeScreen.dart'; // Import the flutter_svg package

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
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;
    final screenWidth = screenSize.width;
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
                return const ResetPasswordDialog();
              },);},
              child: Text(
                "Forgot Password?",
                style: TextStyle(color: Theme.of(context).primaryColorDark),
              ),
            ),
          ),
          const SizedBox(height: 2),
          // Login Button
          SizedBox(
            width: MediaQuery.of(context).size.width * 2.5 / 3, // 2/3 of screen width
            child: ElevatedButton(
              onPressed: _signInWithEmailPassword,
              style: ElevatedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.onPrimary, backgroundColor: kPrimaryColor, // White text
                    shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),              
              ),
              
              child: const Text("Sign-In", style: TextStyle(fontSize: 16 ),),
            ),
          ),
          const SizedBox(height: 15),
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
              width: screenWidth * 0.045,
              height: screenWidth * 0.045,
            ),
          ),
          SizedBox(height: 10,),
          // No Account Text
          const NoAccountText(),
        ],
      ),
    );
  }

  Future<void> _signInWithEmailPassword() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Debugging: Print email and password values
      print('Email: $email');
      print('Password: $password');

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
        // Debugging: Print the error type and message
        print('Error: $error');
        if (error is FirebaseAuthException) {
          _handleAuthError(error);
        } else {
          _showDialog('Error', 'Failed to sign in. Please try again later.');
        }
      }
    }
  }

  void _handleAuthError(FirebaseAuthException error) {
    // Debugging: Print the error code
    print('FirebaseAuthException code: ${error.code}');
    
    switch (error.code) {
      case 'invalid-email':
        _showDialog('Error', 'The email address is not valid.');
        break;
      case 'user-not-found':
        _showDialog('Error', 'User not found. Please check your credentials.');
        break;
      case 'wrong-password':
        _showDialog('Error', 'Incorrect password. Please try again.');
        break;
      case 'user-disabled':
        _showDialog('Error', 'This account has been disabled. Please contact support.');
        break;
      case 'too-many-requests':
        _showDialog('Error', 'Too many attempts. Please try again later.');
        break;
      case 'operation-not-allowed':
        _showDialog('Error', 'This sign-in method is not allowed. Please contact support.');
        break;
      case 'weak-password':
        _showDialog('Error', 'The password is too weak. Please choose a stronger password.');
        break;
      case 'email-already-in-use':
        _showDialog('Error', 'This email is already in use. Please use a different email.');
        break;
      case 'account-exists-with-different-credential':
        _showDialog('Error', 'An account already exists with the same email address but different sign-in credentials. Please use a different sign-in method.');
        break;
      case 'invalid-credential':
        _showDialog('Error', 'The supplied auth credential is incorrect, malformed, or has expired.');
        break;
      case 'invalid-verification-code':
        _showDialog('Error', 'The verification code is invalid.');
        break;
      case 'invalid-verification-id':
        _showDialog('Error', 'The verification ID is invalid.');
        break;
      default:
        _showDialog('Error', 'An undefined error occurred. Please try again.');
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
      if (error is FirebaseAuthException) {
        _handleAuthError(error);
      } else {
        _showDialog('Error', 'Failed to sign in with Google. Please check your network connection and try again.');
      }
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
