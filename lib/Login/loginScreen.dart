import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_svg/flutter_svg.dart'; // Add this import
import 'package:pakfoundf/Login/login_form.dart'; // Update this path

class Login extends StatelessWidget {
  const Login({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;
    final screenWidth = screenSize.width;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              // Branding Element: App Logo
              Container(
                height: screenHeight * 0.4,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/backgr.png'),
                    fit: BoxFit.fill,
                  ),
                ),
                child: Stack(
                  children: <Widget>[
                    Positioned(
                      child: FadeInUp(
                        duration: const Duration(milliseconds: 1600),
                        child: Container(
                          margin: EdgeInsets.only(top: screenHeight * 0.05),
                          child: Center(
                            child: SvgPicture.asset(
                              'assets/icons/SVG.svg', // Updated to use SVG
                              height: screenHeight * 0.15,
                              width: screenHeight * 0.15,
                            ),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
              // Login Form
              Padding(
                padding: EdgeInsets.all(screenWidth * 0.075),
                child: Column(
                  children: <Widget>[
                    FadeInUp(
                      duration: const Duration(milliseconds: 1800),
                      child: const SigninForm(),
                    ),
                    SizedBox(height: screenHeight * 0.01),
                    // Forgot Password
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
