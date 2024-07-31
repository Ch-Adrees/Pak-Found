import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pakfoundf/Chat/addChat.dart';
import 'package:pakfoundf/Chat/chatLi.dart';

class ChatListScreen extends StatefulWidget {
  @override
  _ChatListScreenState createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearchEnabled = true;

  AnimationController? _animationController;
  Animation<double>? _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController!,
      curve: Curves.easeIn,
    );
    _animationController?.forward();
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String? currentUserId = _auth.currentUser?.uid;

    if (currentUserId == null) {
      return Scaffold(
        body: Center(child: Text("User not logged in")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('User Chats', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              enabled: _isSearchEnabled,
              decoration: InputDecoration(
                labelText: 'Search',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onTap: () {
                setState(() {
                  _isSearchEnabled = true;
                });
              },
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('chats')
                  .where('participants', arrayContains: currentUserId)
                  .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> chatSnapshot) {
                if (chatSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!chatSnapshot.hasData || chatSnapshot.data!.docs.isEmpty) {
                  return Center(child: Text("No data available"));
                }

                var chats = chatSnapshot.data!.docs;

                if (_searchQuery.isNotEmpty) {
                  chats = chats.where((chat) {
                    var chatData = chat.data() as Map<String, dynamic>;
                    var receiverName = chatData['receiverName']?.toString().toLowerCase() ?? '';
                    var lastMessage = chatData['lastMessage']?.toString().toLowerCase() ?? '';
                    return receiverName.contains(_searchQuery) || lastMessage.contains(_searchQuery);
                  }).toList();
                }

                return ListView.separated(
                  itemCount: chats.length,
                  separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey),
                  itemBuilder: (context, index) {
                    var chat = chats[index];
                    var chatId = chat.id;
                    var chatData = chat.data() as Map<String, dynamic>;
                    var lastMessage = chatData['lastMessage'];
                    var timestamp = (chatData['lastMessageTime'] as Timestamp?)?.toDate();

                    Widget lastMessageWidget = Text(
                      lastMessage ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    );

                    return FadeTransition(
                      opacity: _animation!,
                      child: FutureBuilder<DocumentSnapshot>(
                        future: _firestore.collection('users').doc(currentUserId).collection('chats').doc(chatId).get(),
                        builder: (context, AsyncSnapshot<DocumentSnapshot> userChatSnapshot) {
                          if (userChatSnapshot.connectionState == ConnectionState.waiting) {
                            return ListTile(
                              title: Text("Loading..."),
                              subtitle: Text(""),
                              trailing: null,
                            );
                          }

                          if (!userChatSnapshot.hasData) {
                            return ListTile(
                              title: Text('No Receiver Name'),
                              subtitle: lastMessageWidget,
                              trailing: timestamp != null ? Text('${timestamp.hour}:${timestamp.minute}') : null,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatScreen(chatId: chatId),
                                  ),
                                );
                              },
                            );
                          }

                          var userChatData = userChatSnapshot.data?.data() as Map<String, dynamic>?;
                          var receiverName = userChatData?['receiverName'] ?? '';
                          var receiverProfilePic = userChatData?['receiverProfilePic'] ?? 'assets/userProfile.png';

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: receiverProfilePic != null
                                  ? NetworkImage(receiverProfilePic)
                                  : const AssetImage('assets/userProfile.png') as ImageProvider,
                            ),
                            title: Text(receiverName, style: TextStyle(color: Colors.black),),
                            subtitle: lastMessageWidget,
                            trailing: timestamp != null ? Text('${timestamp.hour}:${timestamp.minute}') : null,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatScreen(chatId: chatId),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddChatScreen(''),
            ),
          );
        },
      ),
    );
  }
}
