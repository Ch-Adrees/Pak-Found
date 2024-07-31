import 'package:flutter/material.dart';

class EmergencyAlertScreen extends StatefulWidget {
  const EmergencyAlertScreen({super.key});

  @override
  _EmergencyAlertScreenState createState() => _EmergencyAlertScreenState();
}

class _EmergencyAlertScreenState extends State<EmergencyAlertScreen> {
   DateTime? _selectedDate; // Variable to hold selected date

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 10),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        // Assign the selected date to your expiry date field controller
      });
    }
  }
  bool useSavedLocation = true; // Initially using saved location

  void toggleLocationOption(bool? value) {
    setState(() {
      useSavedLocation = value ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text('Emergency Alert'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Payment',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green, // Title color
              ),
            ),
            // Debit Card Payment
            _buildPaymentOption(
              icon: Icons.credit_card, // Add an appropriate icon for debit card
              title: 'Debit Card',
              content: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Cardholder Name',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Card Number',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                   const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => _selectDate(context), // Show date picker on tap
                  child: AbsorbPointer(
                    // Disables text field editing
                    child: TextFormField(
                      controller: TextEditingController(
                          text: _selectedDate != null
                              ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                              : ''),
                      decoration: const InputDecoration(
                        labelText: 'Expiry Date',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Payment through EasyPaisa
            _buildPaymentOption(
              icon: Icons.monetization_on, // Add an appropriate icon for EasyPaisa
              title: 'EasyPaisa',
              content: Row(
                children: [
                  DropdownButton<String>(
                    value: '+92', // Default country code for Pakistan
                    onChanged: (String? newValue) {
                      // Update country code selection
                    },
                    items: <String>[
                      '+92',
                      // Add more country codes as needed
                    ].map<DropdownMenuItem<String>>(
                      (String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      },
                    ).toList(),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Mobile Number',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Payment through Mobile Number
            _buildPaymentOption(
              icon: Icons.phone, // Add an appropriate icon for payment through number
              title: 'Mobile Payment',
              content: Row(
                children: [
                  DropdownButton<String>(
                    value: '+92', // Default country code for Pakistan
                    onChanged: (String? newValue) {
                      // Update country code selection
                    },
                    items: <String>[
                      '+92',
                      // Add more country codes as needed
                    ].map<DropdownMenuItem<String>>(
                      (String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      },
                    ).toList(),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Mobile Number',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Location',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green, // Title color
              ),
            ),
            const SizedBox(height: 10),
            Column(
              children: [
                Checkbox(
                  value: useSavedLocation,
                  onChanged: toggleLocationOption,
                ),
                const Text('Use saved location from Lost Item form'),
              ],
            ),
            if (!useSavedLocation) ...[
              const SizedBox(height: 10),
              // Location entry form widgets here...
               const TextField(
              decoration: InputDecoration(
                labelText: 'Search Place',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Divider(),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text('or'),
                ),
                Expanded(
                  child: Divider(),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () {
                // Implement current location functionality
              },
              icon: const Icon(Icons.my_location),
              label: const Text('Use Current Location'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green, // Match app theme
              ),
            ),
            const SizedBox(height: 10),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Divider(),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text('or'),
                ),
                Expanded(
                  child: Divider(),
                ),
              ],
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Enter Address'),
            ),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Implement actions for submitting the emergency alert and payment
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green, // Button color
              ),
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption({
    required IconData icon,
    required String title,
    required Widget content,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 30,
                color: Colors.green, // Icon color
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          content,
        ],
      ),
    );
  }
}
