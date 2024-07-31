import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportScreen extends StatefulWidget {
  @override
  _SupportScreenState createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedReason;
  String _selectedReasonText = '';
  String _message = '';

  final List<String> _reasons = [
    'How can I see only items based on selected categories?',
    'Can I change my phone number?',
    'How to place a found item into the market place section?',
    'How to increase or reduce the reward price for the item?',
    'How to hand over the item to the owner of it?',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Text('Support', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              SvgPicture.asset(
                                'assets/icons/contact.svg', // Update with your image path
                                height: 150,
                                fit: BoxFit.cover,
                              ),
                              SizedBox(height: 20),
                              Container(
                                width: double.infinity,
                                child: DropdownButtonFormField<String>(
                                  value: _selectedReason,
                                  hint: Text('Choose Reason'),
                                  items: _reasons.map((String reason) {
                                    return DropdownMenuItem<String>(
                                      value: reason,
                                      child: Container(
                                        width: MediaQuery.of(context).size.width * 0.7, // Set width according to your needs
                                        child: Text(
                                          reason,
                                          maxLines: 3, // Set maximum lines
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (newValue) {
                                    setState(() {
                                      _selectedReason = newValue;
                                      _selectedReasonText = newValue!;
                                    });
                                  },
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Colors.green.withOpacity(0.1),
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (value) => value == null ? 'Please choose a reason' : null,
                                ),
                              ),
                              SizedBox(height: 20),
                              TextFormField(
                                decoration: InputDecoration(
                                  hintText: 'Message/Comments',
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (value) {
                                  _message = value;
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your message';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: () {
                                  if (_formKey.currentState!.validate()) {
                                    _sendEmail();
                                  } else {
                                    // Add an error message if the form is not valid
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green, // Change button color to green
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(horizontal: 100, vertical: 15),
                                  textStyle: TextStyle(fontSize: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text('Submit'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Text(
                        'You may also reach us through phone',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        _makePhoneCall('03270252165');
                      },
                      icon: Icon(Icons.phone),
                      color: Colors.blue,
                      iconSize: 40,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _sendEmail() async {
    if (_selectedReasonText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a reason first.'),
        ),
      );
      return;
    }

    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'alizayn865@gmail.com',
      queryParameters: {
        'subject': _selectedReasonText,
        'body': _message,
      },
    );

    final String emailUrl = emailLaunchUri.toString();

    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not launch email client.'),
        ),
      );
    }
  }

  void _makePhoneCall(String phoneNumber) async {
    final Uri phoneCallUri = Uri(scheme: 'tel', path: phoneNumber);

    if (await canLaunchUrl(phoneCallUri)) {
      await launchUrl(phoneCallUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not launch phone call.'),
        ),
      );
    }
  }
}
