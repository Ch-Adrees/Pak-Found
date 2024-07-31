import 'package:flutter/material.dart';
import 'lostItemForm.dart';
import 'foundItemForm.dart';

class UploadItemScreen extends StatelessWidget {
  const UploadItemScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green, // Match the app bar color of HomeScreen
        title: const Text('Upload Item',style: TextStyle(color: Colors.white),),
      ),
      body: Container(
        width: double.infinity, // Ensure the Container takes full width
        height: double.infinity, // Ensure the Container takes full height
        child: Stack(
          children: [
            // Background image
            Positioned.fill(
              child: Opacity(
                opacity: 0.3,
                child: Image.asset(
                  'assets/uploadItem(helpingHand).png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // SizedBox(height: MediaQuery.of(context).size.height * 0.05), // Add some space at the top
                // Text(
                //   'What happened?',
                //   style: TextStyle(
                //     fontSize: 24,
                //     fontWeight: FontWeight.bold,
                //     color: Colors.black87, // Custom text color
                //     fontFamily: 'Roboto', // Custom font family
                //   ),
                //   textAlign: TextAlign.center,
                // ),
                // SizedBox(height: MediaQuery.of(context).size.height * 0.05), // Space between text and buttons
              ],
            ),
            Positioned(
              top: 60, // Positioning "found" button
              left: 40, // Positioning relative to screen width
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const FoundItemForm()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25), // Custom border radius to resemble chat icon
                  ),
                  padding: const EdgeInsets.all(24),
                  backgroundColor: const Color.fromARGB(255, 40, 78, 182), // Custom color for 'found' category button
                  elevation: 8, // Increase elevation
                ),
                child: const Text(
                  'Hey, I found\nSomething', // Multiline text
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14, // Responsive font size
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Positioned(
              bottom: 60, // Positioning "lost" button
              right: 40, // Positioning relative to screen width
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LostItemForm()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25), // Custom border radius to resemble chat icon
                  ),
                  padding: const EdgeInsets.all(24),
                  backgroundColor: Colors.red[300], // Custom color for 'lost' category button
                  elevation: 8, // Increase elevation
                ),
                child: const Text(
                  'Ohh, I lost\nSomething', // Multiline text
                  style: TextStyle(
                    color: Colors.white,
                    //fontSize: 14, // Responsive font size
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
