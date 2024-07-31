import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text('Terms & Conditions',style: TextStyle(color: Colors.white),),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // const Text(
            //   'Terms & Conditions',
            //   style: TextStyle(
            //     fontSize: 24.0,
            //     fontWeight: FontWeight.bold,
            //     color: Colors.green,
            //   ),
            // ),
            const SizedBox(height: 20.0),
            _buildStylishText(
              'PakFound is a humble attempt, online platform area, where people can go to report / retrieve lost articles that may have been found by others.',
            ),
            const SizedBox(height: 10.0),
            _buildStylishText(
              'You agree to use the PakFound mobile application only for lawful purposes and in a manner that does not infringe upon the rights of others.',
            ),
            const SizedBox(height: 10.0),
            _buildStylishText(
              'To the fullest extent permitted by law, PakFound shall not be liable for any direct, indirect, incidental, special, consequential, or punitive damages arising out of or related to your use of the App.',
            ),
            const SizedBox(height: 10.0),
            _buildStylishText(
              'PakFound reserves the right to modify or revise these Terms at any time without notice. By continuing to use the App after such changes, you agree to be bound by the modified Terms.',
            ),
            const SizedBox(height: 10.0),
            _buildStylishText(
              'PakFound may terminate or suspend your access to the App at any time, with or without cause, and without prior notice or liability.',
            ),
            const SizedBox(height: 10.0),
            _buildStylishText(
              'Some lost and found users will try to contact the owners of any lost items, if there are any personal identifiers available.',
            ),
            const SizedBox(height: 10.0),
            _buildStylishText(
              'If you have any questions about these Terms, please contact us at ',
            ),
            GestureDetector(
              onTap: () => _launchEmail(),
              child: const Text(
                '20011598-098@uog.edu.pk',
                style: TextStyle(
                  fontSize: 16.0,
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStylishText(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16.0,
        height: 1.5,
        color: Colors.black87,
      ),
    );
  }

  void _launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: '20011598-098@uog.edu.pk',
      query: 'subject=Query regarding Terms & Conditions',
    );

    if (await canLaunch(emailLaunchUri.toString())) {
      await launch(emailLaunchUri.toString());
    } else {
      print('Could not launch email client');
    }
  }
}
