import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

class ChatScreen extends StatefulWidget {
  final String chatId;

  ChatScreen({required this.chatId});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? receiverName;
  String? receiverProfilePic;
  Map<String, bool> _selectedMessages = {};
  List<XFile> _selectedImages = [];
  bool _isEmptyErrorVisible = false;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _getReceiverInfo();
  }

  void _getReceiverInfo() async {
    String currentUserId = _auth.currentUser?.uid ?? '';
    var chatDoc = await _firestore.collection('chats').doc(widget.chatId).get();
    String receiverId = chatDoc['senderId'] == currentUserId ? chatDoc['receiverId'] : chatDoc['senderId'];
    var receiverDoc = await _firestore.collection('users').doc(receiverId).get();
    setState(() {
      receiverName = receiverDoc['name'];
      receiverProfilePic = receiverDoc['profilePic'];
    });
  }

  Future<void> _sendMessage() async {
    if (_controller.text.isNotEmpty || _selectedImages.isNotEmpty) {
      setState(() {
        _isEmptyErrorVisible = false;
        _isSending = true;
      });

      String currentUserId = _auth.currentUser?.uid ?? '';
      String message = _controller.text.trim();
      List<String> imageUrls = await _uploadImages();

      await _firestore.collection('chats').doc(widget.chatId).collection('messages').add({
        'text': message,
        'senderId': currentUserId,
        'timestamp': Timestamp.now(),
        'imageUrls': imageUrls,
      });

      await _firestore.collection('chats').doc(widget.chatId).update({
        'lastMessage': message.isNotEmpty ? message : 'Image',
      });

      _controller.clear();
      _selectedImages.clear();
      setState(() {
        _isSending = false;
      });
    } else {
      setState(() {
        _isEmptyErrorVisible = true;
      });
    }
  }

  Future<List<String>> _uploadImages() async {
    List<String> imageUrls = [];
    for (var pickedFile in _selectedImages) {
      File file = File(pickedFile.path);
      String fileName = path.basename(file.path);
      Reference storageReference = FirebaseStorage.instance.ref().child('chats/${widget.chatId}/$fileName');
      UploadTask uploadTask = storageReference.putFile(file);
      TaskSnapshot taskSnapshot = await uploadTask;
      String downloadUrl = await taskSnapshot.ref.getDownloadURL();
      imageUrls.add(downloadUrl);
    }
    return imageUrls;
  }

  Future<void> _pickImages() async {
    final pickedFiles = await ImagePicker().pickMultiImage();
    setState(() {
      _selectedImages.addAll(pickedFiles ?? []);
    });
  }

  void _onMessageLongPress(String messageId) {
    setState(() {
      if (_selectedMessages.containsKey(messageId)) {
        _selectedMessages[messageId] = !_selectedMessages[messageId]!;
      } else {
        _selectedMessages[messageId] = true;
      }
    });
  }

  int _getSelectedMessagesCount() {
    return _selectedMessages.values.where((isSelected) => isSelected).length;
  }

  void _deleteSelectedMessages() async {
    for (String messageId in _selectedMessages.keys) {
      if (_selectedMessages[messageId] == true) {
        await _firestore.collection('chats').doc(widget.chatId).collection('messages').doc(messageId).delete();
      }
    }
    setState(() {
      _selectedMessages.clear();
    });
  }

  String _formatDate(Timestamp timestamp) {
    DateTime date = timestamp.toDate();
    return "${date.day}/${date.month}/${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Row(
          children: [
            if (receiverProfilePic != null)
              CircleAvatar(
                backgroundImage: NetworkImage(receiverProfilePic!),
              ),
            SizedBox(width: 10.0),
            Text(receiverName?? '',style: TextStyle(color: Colors.white,fontSize: 16),),
          ],
        ),
        actions: [
          if (_getSelectedMessagesCount() > 0)
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: _deleteSelectedMessages,
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('chats')
                  .doc(widget.chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!.docs;
                Map<String, List<DocumentSnapshot>> groupedMessages = {};

                for (var message in messages) {
                  String date = _formatDate(message['timestamp']);
                  if (!groupedMessages.containsKey(date)) {
                    groupedMessages[date] = [];
                  }
                  groupedMessages[date]!.add(message);
                }

                return ListView.builder(
                  itemCount: groupedMessages.length,
                  itemBuilder: (context, index) {
                    String date = groupedMessages.keys.toList()[index];
                    List<DocumentSnapshot> dailyMessages = groupedMessages[date]!;

                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(date, style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                        ),
                        ...dailyMessages.map((message) {
                          final String messageId = message.id;
                          final bool isSender = message['senderId'] == _auth.currentUser?.uid;
                          final String text = message['text'];
                          final List<String> imageUrls = List<String>.from(message['imageUrls']);
                          final Timestamp timestamp = message['timestamp'];

                          return Container(
                            margin: EdgeInsets.symmetric(vertical: 4.0, horizontal: 10.0),
                            child: Row(
                              mainAxisAlignment: isSender ? MainAxisAlignment.end : MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (!isSender)
                                  CircleAvatar(
                                    backgroundImage: NetworkImage(receiverProfilePic ?? 'assets/userProfile.png'),
                                  ),
                                SizedBox(width: 10.0),
                                ConstrainedBox(
                                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.67),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10.0),
                                      color: isSender ? const Color.fromARGB(255, 88, 169, 236) : Colors.grey[300],
                                    ),
                                    child: Stack(
                                      children: [
                                        Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onLongPress: () => _onMessageLongPress(messageId),
                                            child: Padding(
                                              padding: EdgeInsets.all(10.0),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  if (imageUrls.isNotEmpty)
                                                    for (String imageUrl in imageUrls)
                                                      Image.network(
                                                        imageUrl,
                                                        width: double.infinity,
                                                        height: 200.0,
                                                        fit: BoxFit.cover,
                                                      ),
                                                       if (text.isNotEmpty)
                                                    Text(text, style: TextStyle(color: Colors.black)),
                                                  SizedBox(height: 5.0),
                                                  Text(
                                                    textAlign: TextAlign.end,
                                                    timestamp.toDate().toString().substring(11, 16), // Extract hours and minutes
                                                    style: TextStyle(color: Colors.black, fontSize: 12.0),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        if (_selectedMessages[messageId] == true)
                                          Positioned.fill(
                                            child: Container(
                                              color: Colors.black.withOpacity(0.3),
                                            ),
                                          ),
                                        if (_isSending && isSender && messageId == messages.last.id)
                                          Positioned(
                                            top: 10,
                                            right: 10,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (isSender)
                                  SizedBox(width: 10.0),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          if (_isEmptyErrorVisible)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Please enter a message or select an image to send.',
                style: TextStyle(color: Colors.red, fontSize: 12.0),
              ),
            ),
          Container(
            color: Colors.grey[200],
            padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 5.0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.image, color: Colors.green,),
                  onPressed: _pickImages,
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send,color: Colors.green,),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
          if (_selectedImages.isNotEmpty)
            Container(
              height: 100,
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
                          onTap: () {
                            setState(() {
                              _selectedImages.removeAt(index);
                            });
                          },
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
        ],
      ),
    );
  }
}
