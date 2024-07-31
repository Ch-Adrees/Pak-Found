import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import 'package:pakfoundf/Chat/chatLi.dart';

class AddChatScreen extends StatefulWidget {
  final String email;
  const AddChatScreen(this.email, {super.key});

  @override
  _AddChatScreenState createState() => _AddChatScreenState();
}

class _AddChatScreenState extends State<AddChatScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  TextEditingController _emailController = TextEditingController();
  TextEditingController _messageController = TextEditingController();
  String emailError = "";
  String messageError = "";
  List<XFile> _selectedImages = [];
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.email;
  }

  Future<List<String>> _uploadImages(String chatId) async {
    List<String> imageUrls = [];
    for (var pickedFile in _selectedImages) {
      File file = File(pickedFile.path);
      String fileName = path.basename(file.path);
      Reference storageReference = FirebaseStorage.instance.ref().child('chats/$chatId/$fileName');
      UploadTask uploadTask = storageReference.putFile(file);
      TaskSnapshot taskSnapshot = await uploadTask;
      String downloadUrl = await taskSnapshot.ref.getDownloadURL();
      imageUrls.add(downloadUrl);
    }
    return imageUrls;
  }

  Future<void> _startChat() async {
    String email = _emailController.text.trim();
    var message = _messageController.text.trim();
    String currentUserId = _auth.currentUser?.uid ?? '';

    setState(() {
      emailError = "";
      messageError = "";
    });

    if (email.isEmpty) {
      setState(() {
        emailError = "Email cannot be empty";
      });
      return;
    }
    if (message.isEmpty && _selectedImages.isEmpty) {
      setState(() {
        messageError = "Message or image cannot be empty";
      });
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      var receiverSnapshot = await _firestore.collection('users').where('email', isEqualTo: email).get();
      if (receiverSnapshot.docs.isEmpty) {
        setState(() {
          emailError = "Email not registered";
          _isUploading = false;
        });
        return;
      }

      var receiverDoc = receiverSnapshot.docs.first;
      String receiverId = receiverDoc.id;
      String receiverName = receiverDoc['name'];
      String receiverProfilePic = receiverDoc['profilePic'] ?? 'assets/petimg.png';

      // Check if a chat already exists between the current user and the receiver
      var existingChatSnapshot = await _firestore
          .collection('chats')
          .where('participants', arrayContains: currentUserId)
          .get();

      String chatId='';
      bool chatExists = false;
      if (existingChatSnapshot.docs.isNotEmpty) {
        for (var doc in existingChatSnapshot.docs) {
          var data = doc.data() as Map<String, dynamic>;
          if ((data['participants'] as List<dynamic>).contains(receiverId)) {
            chatId = doc.id;
            chatExists = true;
            break;
          }
        }
      }

      if (!chatExists) {
        chatId = _firestore.collection('chats').doc().id;
      }

      String lastMessage = message.isNotEmpty ? message : 'Image';

      if (message.isNotEmpty) {
        await _firestore.collection('chats').doc(chatId).collection('messages').add({
          'imageUrls': [],
          'text': message,
          'senderId': currentUserId,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      // Upload images if selected
      List<String> imageUrls = await _uploadImages(chatId);
      if (imageUrls.isNotEmpty) {
        lastMessage = 'Image';
        await _firestore.collection('chats').doc(chatId).collection('messages').add({
          'imageUrls': imageUrls,
          'text': '',
          'senderId': currentUserId,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      // Update chat document with the last message and participants
      await _firestore.collection('chats').doc(chatId).set({
        'senderId': currentUserId,
        'receiverId': receiverId,
        'lastMessage': lastMessage,
        'timestamp': FieldValue.serverTimestamp(),
        'participants': [currentUserId, receiverId],
      });

      // Update current user's chat list
      await _firestore.collection('users').doc(currentUserId).collection('chats').doc(chatId).set({
        'receiverId': receiverId,
        'receiverName': receiverName,
        'receiverProfilePic': receiverProfilePic,
        'lastMessage': lastMessage,
        'timestamp': FieldValue.serverTimestamp(),
        'participants': [currentUserId, receiverId],
      });

      // Update receiver's chat list
      await _firestore.collection('users').doc(receiverId).collection('chats').doc(chatId).set({
        'senderId': currentUserId,
        'senderName': _auth.currentUser?.displayName ?? '',
        'senderProfilePic': _auth.currentUser?.photoURL ?? '',
        'lastMessage': lastMessage,
        'timestamp': FieldValue.serverTimestamp(),
        'participants': [currentUserId, receiverId],
      });

      // Navigate to the chat
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(chatId: chatId),
        ),
      );
    } catch (e) {
      print("Error starting chat: $e");
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _pickImages() async {
    final pickedFiles = await ImagePicker().pickMultiImage();
    if (pickedFiles != null) {
      setState(() {
        _selectedImages.addAll(pickedFiles);
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Chat',style: TextStyle(color: Colors.white),),
        backgroundColor: Colors.green,
      ),
      body: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.email),
                            hintText: 'Enter receiver email',
                            errorText: emailError.isEmpty ? null : emailError,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                        ),
                      ),
                      if (_selectedImages.isNotEmpty)
                        Container(
                          height: 100,
                          margin: const EdgeInsets.symmetric(vertical: 10.0),
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _selectedImages.length,
                            itemBuilder: (context, index) {
                              return Stack(
                                children: [
                                  Container(
                                    margin: EdgeInsets.all(8.0),
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8.0),
                                      image: DecorationImage(
                                        image: FileImage(File(_selectedImages[index].path)),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    right: 0,
                                    child: GestureDetector(
                                      onTap: () => _removeImage(index),
                                      child: CircleAvatar(
                                        radius: 12,
                                        backgroundColor: Colors.red,
                                        child: Icon(Icons.close, size: 16, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.add),
                              onPressed: _pickImages,
                            ),
                            Expanded(
                              child: TextField(
                                controller: _messageController,
                                maxLines: null,
                                decoration: InputDecoration(
                                  hintText: 'Enter your message',
                                  errorText: messageError.isEmpty ? null : messageError,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.send, color: Colors.green),
                              onPressed: _startChat,
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
          if (_isUploading)
            Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
