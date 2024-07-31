// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:pakfoundf/helpingMaterial/constant.dart';
import 'package:pakfoundf/loginAndSignup/SignUp.dart';

class NoAccountText extends StatelessWidget {
  const NoAccountText({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          "Don’t have an account? ",
          style: TextStyle(fontSize: 16),
        ),
        SizedBox(width: 3,),
        GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => SignUpPage(),)),
          child: const Text(
            "Sign Up",
            style: TextStyle(fontSize: 16, color: kPrimaryColor),
          ),
        ),
      ],
    );
  }
}
