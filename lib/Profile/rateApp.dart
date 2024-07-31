import 'package:flutter/material.dart';

class RateAppScreen extends StatelessWidget {
  const RateAppScreen();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Text('Rate App',style: TextStyle(color: Colors.white),),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text('This button will navigate to App Store rating screen for that app in future ( after the app launches on App Store)',style: TextStyle(fontStyle: FontStyle.italic,fontSize: 20),),
      ),
    );
  }
}
