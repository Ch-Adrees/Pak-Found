import 'package:flutter/material.dart';
import 'package:pakfoundf/helpingMaterial/constant.dart';
import 'package:pakfoundf/helpingMaterial/suffixicons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'dart:ui'; // For blur effects

class ResetPasswordDialog extends StatefulWidget {
  final bool autofillEmail;
  const ResetPasswordDialog({this.autofillEmail = false});

  @override
  _ResetPasswordDialogState createState() => _ResetPasswordDialogState();
}

class _ResetPasswordDialogState extends State<ResetPasswordDialog> {
  final TextEditingController _emailController = TextEditingController();
  bool _emailSent = false;
  bool _loading = false;
  bool _showError = false;
  String _errorMessage = '';
  Timer? _resendCooldownTimer;
  int _cooldownDuration = 30;
  bool _isCooldownActive = false;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    if (widget.autofillEmail) {
      _currentUser = FirebaseAuth.instance.currentUser;
      if (_currentUser != null) {
        _emailController.text = _currentUser!.email ?? '';
      }
    }
  }

  void _startResendCooldown() {
    _resendCooldownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_cooldownDuration == 0) {
        _resendCooldownTimer?.cancel();
        setState(() {
          _isCooldownActive = false;
        });
      } else {
        setState(() {
          _cooldownDuration--;
        });
      }
    });
  }

  Future<void> _sendResetEmail() async {
    if (_emailController.text.isEmpty) {
      setState(() {
        _showError = true;
        _errorMessage = 'Email cannot be empty';
      });
      return;
    } else if (!_isValidEmail(_emailController.text)) {
      setState(() {
        _showError = true;
        _errorMessage = 'Invalid email format';
      });
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: _emailController.text);
      setState(() {
        _emailSent = true;
        _showError = false;
      });
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        setState(() {
          _showError = true;
          _errorMessage = 'Email is not registered';
        });
      } else if (e.code == 'network-request-failed') {
        setState(() {
          _showError = true;
          _errorMessage = 'No internet connection. Please check your connection and try again.';
        });
      } else {
        setState(() {
          _showError = true;
          _errorMessage = 'Failed to send reset email. Please try again later.';
        });
      }
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  bool _isValidEmail(String email) {
    final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegExp.hasMatch(email);
  }

  @override
  void dispose() {
    _resendCooldownTimer?.cancel();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop();
      },
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () {},
          child: Stack(
            children: [
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(
                  //color: Colors.black.withOpacity(0.5),
                ),
              ),
              Center(
                child: Container(
                  padding: EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!_emailSent)
                        Column(
                          children: [
                            Text(
                              "Forgot Password",
                              style: headingStyle,
                            ),
                            SizedBox(height: 20),
                             Text(
                  "We will send an email at your below entered account to reset your password",
                  textAlign: TextAlign.center,
                ),
                 SizedBox(height: 40),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                labelText: "Email",
                                hintText: "Enter your email",
                                errorText: _showError ? _errorMessage : null,
                                floatingLabelBehavior: FloatingLabelBehavior.always,
                                suffixIcon: CustomSuffixIcons(svgIcon: "assets/icons/Mail.svg"),
                              ),
                              enabled: !widget.autofillEmail,
                            ),
                            SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: _loading ? null : _sendResetEmail,
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                backgroundColor: kPrimaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(16)),
                                ),
                              ),
                              child: _loading
                                  ? CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    )
                                  : const Text("Send Reset Email"),
                            ),
                            if (_showError)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  _errorMessage,
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                          ],
                        ),
                      if (_emailSent)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Column(
                            children: [
                              Text(
                                "An email with a password reset link has been sent to your email address. Please check your inbox and follow the instructions to reset your password.",
                                textAlign: TextAlign.center,
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Didn't receive the email? ",
                                    style: TextStyle(color: Colors.black),
                                  ),
                                  InkWell(
                                    onTap: _isCooldownActive
                                        ? null
                                        : () {
                                            _sendResetEmail();
                                            setState(() {
                                              _cooldownDuration = 30;
                                              _isCooldownActive = true;
                                            });
                                            _startResendCooldown();
                                          },
                                    child: Text(
                                      "Resend",
                                      style: TextStyle(
                                        color: _isCooldownActive ? Colors.grey : Colors.green,
                                        decoration: _isCooldownActive ? TextDecoration.none : TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 5),
                              Text(
                                _isCooldownActive ? "Resend email in $_cooldownDuration seconds" : "",
                                style: TextStyle(color: Colors.grey),
                              ),
                              SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context); // Close dialog
                                },
                                style: ElevatedButton.styleFrom(
                                  elevation: 0,
                                  backgroundColor: kPrimaryColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(16)),
                                  ),
                                ),
                                child: Text("Back to Login"),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
