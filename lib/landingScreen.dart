import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pakfoundf/l10n/localeProvider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'loginAndSignup/loginScreen.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:ui';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the screen size
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;
    final screenWidth = screenSize.width;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: MediaQuery.sizeOf(context).height*0.1,),
              Text(
                AppLocalizations.of(context)!.welcome,
                style: TextStyle(
                  fontSize: screenHeight * 0.035,
                  fontWeight: FontWeight.bold,
                  color: Colors.green, // Set welcome text color to green
                ),
              ),
              SizedBox(height: screenHeight * 0.02),
              SvgPicture.asset(
                'assets/icons/SVG.svg',
                height: screenHeight * 0.15,
                width: screenHeight * 0.15,
              ),
              SizedBox(height: screenHeight * 0.02),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                child: Text(
                  AppLocalizations.of(context)!.description,
                  style: TextStyle(
                    fontSize: screenHeight * 0.02,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: screenHeight * 0.02),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                child: Column(
                  children: [
                    FeatureTile(
                      icon: Icons.report,
                      title: AppLocalizations.of(context)!.reportLostItem,
                      iconSize: screenHeight * 0.05,
                      fontSize: screenHeight * 0.02,
                    ),
                    FeatureTile(
                      icon: Icons.manage_search,
                      title: AppLocalizations.of(context)!.manageFoundItems,
                      iconSize: screenHeight * 0.05,
                      fontSize: screenHeight * 0.02,
                    ),
                    FeatureTile(
                      icon: Icons.store,
                      title: AppLocalizations.of(context)!.marketplace,
                      iconSize: screenHeight * 0.05,
                      fontSize: screenHeight * 0.02,
                    ),
                    FeatureTile(
                      icon: Icons.chat,
                      title: AppLocalizations.of(context)!.secureChat,
                      iconSize: screenHeight * 0.05,
                      fontSize: screenHeight * 0.02,
                    ),
                  ],
                ),
              ),
              SizedBox(height: screenHeight * 0.02),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const Login()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.2,
                    vertical: screenHeight * 0.02,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  AppLocalizations.of(context)!.getStarted,
                  style: TextStyle(fontSize: screenHeight * 0.02),
                ),
              ),
              SizedBox(height: screenHeight * 0.02),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () {
                      context
                          .read<LocaleProvider>()
                          .setLocale(const Locale('en'));
                    },
                    child: Text(
                      'English',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: screenHeight * 0.02,
                      ),
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.03),
                  TextButton(
                    onPressed: () {
                      context
                          .read<LocaleProvider>()
                          .setLocale(const Locale('ur'));
                    },
                    child: Text(
                      'اردو',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: screenHeight * 0.02,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: screenHeight * 0.02),
            ],
          ),
        ),
      ),
    );
  }
}

class FeatureTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final double iconSize;
  final double fontSize;

  const FeatureTile({
    required this.icon,
    required this.title,
    required this.iconSize,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.green, size: iconSize),
      title: Text(
        title,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
