import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pakfoundf/HelperMaterial/constant.dart';
import 'package:pakfoundf/HomePage/HomeScreen.dart';
import 'package:pakfoundf/Login/loginScreen.dart';
import 'package:google_sign_in/google_sign_in.dart';

class SignUpForm extends StatefulWidget {
  const SignUpForm({Key? key}) : super(key: key);

  @override
  _SignUpFormState createState() => _SignUpFormState();
}

class _SignUpFormState extends State<SignUpForm> {
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  bool agreedToTerms = false;
  bool passwordVisible = false;
  bool confirmPasswordVisible = false;
  bool termsError = false;
  bool _isLoading = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Full name is required';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    if (value.isNotEmpty && !_isValidEmail(value)) {
      return 'Invalid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Password is required';
    }
    if (value.isNotEmpty && !_isStrongPassword(value)) {
      return 'Weak password: Please use a stronger password';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value != passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  bool _isValidEmail(String value) {
    String emailPattern = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
    RegExp regex = RegExp(emailPattern);
    return regex.hasMatch(value);
  }

  bool _isStrongPassword(String value) {
    return value.length >= 6;
  }

  Future<void> _signUp() async {
    setState(() {
      termsError = !agreedToTerms;
      _isLoading = true;
    });

    if (fullNameController.text.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty ||
        !agreedToTerms) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );

      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'name': fullNameController.text.trim(),
        'email': emailController.text,
        'push_notifications': true,
        'profilePic': '',
      });

      await userCredential.user!.sendEmailVerification();

      _showDialog('Verification Email Sent', 'Please check your email to verify your account.', () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Login()),
        );
      });

      _clearFormFields();
    } catch (error) {
      if (error is FirebaseAuthException && error.code == 'email-already-in-use') {
        _showDialog('Error', 'This email is already in use by another account.');
      } else {
        _showDialog('Error', 'Failed to sign up. Please check your network connection and try again.');
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signUpWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      GoogleSignInAccount? googleUser = await _googleSignIn.signInSilently();
      if (googleUser != null) {
        await _googleSignIn.signOut();
      }

      googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);

      DocumentReference userDoc = FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid);
      DocumentSnapshot userSnapshot = await userDoc.get();

      if (!userSnapshot.exists) {
        await userDoc.set({
          'name': googleUser.displayName ?? '',
          'email': userCredential.user!.email,
          'push_notifications': true,
          'profilePic': '',
          'isLoggedIn': true,
        });
      } else {
        await userDoc.update({'isLoggedIn': true});
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } catch (error) {
      _showDialog('Error', 'Failed to sign in with Google. Please check your network connection and try again.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showDialog(String title, String message, [VoidCallback? onOkPressed]) {
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
                if (onOkPressed != null) {
                  onOkPressed();
                }
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _clearFormFields() {
    fullNameController.clear();
    emailController.clear();
    passwordController.clear();
    confirmPasswordController.clear();
    setState(() {
      agreedToTerms = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;
    final screenWidth = screenSize.width;

    return SizedBox(
       height: screenHeight,
          width: screenWidth,
      child: Scaffold(
        body: Stack(
          children: [
            SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: screenHeight * 0.1),
                    Center(
                      child: SvgPicture.asset(
                        'assets/icons/SVG.svg',
                        height: screenHeight * 0.1,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: fullNameController,
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        suffixIcon: const Icon(Icons.person),
                        errorText: _validateFullName(fullNameController.text),
                      ),
                      textCapitalization: TextCapitalization.words,
                      onChanged: (_) {
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        suffixIcon: const Icon(Icons.mail),
                        errorText: _validateEmail(emailController.text),
                      ),
                      onChanged: (_) {
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: passwordController,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              passwordVisible = !passwordVisible;
                            });
                          },
                          icon: Icon(passwordVisible ? Icons.visibility : Icons.visibility_off),
                        ),
                        errorText: _validatePassword(passwordController.text),
                      ),
                      obscureText: !passwordVisible,
                      onChanged: (_) {
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: confirmPasswordController,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              confirmPasswordVisible = !confirmPasswordVisible;
                            });
                          },
                          icon: Icon(confirmPasswordVisible ? Icons.visibility : Icons.visibility_off),
                        ),
                        errorText: _validateConfirmPassword(confirmPasswordController.text),
                      ),
                      obscureText: !confirmPasswordVisible,
                      onChanged: (_) {
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Checkbox(
                          value: agreedToTerms,
                          onChanged: (bool? value) {
                            setState(() {
                              agreedToTerms = value!;
                              termsError = false;
                            });
                          },
                        ),
                        TextButton(
                          onPressed: () {
                            // Show terms and conditions dialog
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text('Terms and Conditions'),
                                  content: const SingleChildScrollView(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'You agree to use the PakFound mobile application ("the App") only for lawful purposes and in a manner that does not infringe upon the rights of others.',
                                          style: TextStyle(fontSize: 16.0),
                                        ),
                                        SizedBox(height: 10.0),
                                        Text(
                                          'You will not engage in any activity that interferes with or disrupts the operation of the App.',
                                          style: TextStyle(fontSize: 16.0),
                                        ),
                                        SizedBox(height: 10.0),
                                        Text(
                                          'To the fullest extent permitted by law, PakFound shall not be liable for any direct, indirect, incidental, special, consequential, or punitive damages arising out of or related to your use of the App.',
                                          style: TextStyle(fontSize: 16.0),
                                        ),
                                        SizedBox(height: 10.0),
                                        Text(
                                          'PakFound reserves the right to modify or revise these Terms at any time without notice. By continuing to use the App after such changes, you agree to be bound by the modified Terms.',
                                          style: TextStyle(fontSize: 16.0),
                                        ),
                                        SizedBox(height: 10.0),
                                        Text(
                                          'PakFound may terminate or suspend your access to the App at any time, with or without cause, and without prior notice or liability.',
                                          style: TextStyle(fontSize: 16.0),
                                        ),
                                        SizedBox(height: 10.0),
                                        Text(
                                          'These Terms shall be governed by and construed in accordance with the laws of [insert jurisdiction], without regard to its conflict of law provisions.',
                                          style: TextStyle(fontSize: 16.0),
                                        ),
                                        SizedBox(height: 10.0),
                                        Text(
                                          'If you have any questions about these Terms, please contact us at [insert contact information].',
                                          style: TextStyle(fontSize: 16.0),
                                        ),
                                      ],
                                    ),
                                  ),
                                  actions: <Widget>[
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: const Text('Close'),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          child: const Text(
                            'I agree to the Terms and Conditions',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    if (termsError)
                      const Padding(
                        padding: EdgeInsets.only(left: 24.0),
                        child: Text(
                          'Please agree to the terms and conditions',
                          style: TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _signUp,
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.all<Color>(kPrimaryColor),
                        minimumSize: WidgetStateProperty.all<Size>(Size(screenWidth * 0.2, screenHeight * 0.06)),
                      ),
                      child: const Text('Sign Up', style: TextStyle(color: Colors.white)),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _signUpWithGoogle,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: const CircleBorder(),
                        padding: EdgeInsets.all(screenWidth * 0.03),
                      ),
                      child: SvgPicture.asset(
                        'assets/icons/google-icon.svg',
                        width: screenWidth * 0.045,
                        height: screenWidth * 0.045,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Already have an account?"),
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const Login()),
                            );
                          },
                          child: const Text("Sign In", style: TextStyle(fontSize: 16, color: kPrimaryColor)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
