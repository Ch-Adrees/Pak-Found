import 'package:flutter/material.dart';
import 'package:pakfoundf/loginAndSignup/signUpForm.dart';

class SignUpPage extends StatelessWidget {
  const SignUpPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   backgroundColor: Colors.green,
      // ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: SignUpForm(),
      ),
    );
  }
}
