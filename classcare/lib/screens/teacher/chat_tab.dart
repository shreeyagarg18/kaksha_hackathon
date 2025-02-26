import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatTab extends StatefulWidget {
  final String classId;
  const ChatTab({super.key, required this.classId});

  @override
  State<ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<ChatTab> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      String senderId = _auth.currentUser!.uid;

      // Fetch sender's name from Firestore
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(senderId).get();
      String senderName = userDoc.exists ? userDoc['name'] : 'Unknown';
      await _firestore.collection('classes').doc(widget.classId).collection('chats').add({
        'senderId': _auth.currentUser!.uid,
        'senderName': senderName,
        'message': _messageController.text,
        'timestamp': FieldValue.serverTimestamp(),
      });
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Chat")),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('classes').doc(widget.classId).collection('chats')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }
                var messages = snapshot.data!.docs;
                return ListView.builder(
                  reverse: true, // Show latest message at the bottom
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    var message = messages[index];
                    String currentSenderId = message['senderId'] ?? '';
                    bool isMe = currentSenderId == _auth.currentUser!.uid;
                    
                    // Get sender name with fallback
                    String senderName = message['senderName'] ?? 'Unknown';
                    
                    // Check if this is the first message or a different sender than the previous message
                    bool showSenderName = true;
                    if (index < messages.length - 1) {
                      var previousMessage = messages[index + 1];
                      String previousSenderId = previousMessage['senderId'] ?? '';
                      // Only show name if this is a different sender from the previous message
                      // (Remember the list is in reverse order due to 'reverse: true')
                      if (currentSenderId == previousSenderId) {
                        showSenderName = false;
                      }
                    }
                    
                    return ChatBubble(
                      senderName: senderName,
                      message: message['message'],
                      isMe: isMe,
                      showSenderName: showSenderName,
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(hintText: "Enter message"),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isMe;
  final String senderName;
  final bool showSenderName;
  
  ChatBubble({
    required this.senderName,
    required this.message,
    required this.isMe,
    this.showSenderName = true,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Only show the sender name if showSenderName is true
          if (showSenderName)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                senderName,
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700]),
              ),
            ),
          Container(
            margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isMe ? Colors.blueAccent : Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              message,
              style: TextStyle(color: isMe ? Colors.white : Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}