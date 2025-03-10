import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

class AssistantPage extends StatefulWidget {
  const AssistantPage({Key? key}) : super(key: key);

  @override
  State<AssistantPage> createState() => _AssistantPageState();
}

class _AssistantPageState extends State<AssistantPage> {
  // Chat messages. Each message has a sender, message text, and a timestamp.
  final List<Map<String, String>> _messages = [];
  final TextEditingController _controller = TextEditingController();

  // Predefined questions for the chat.
  final List<String> _predefinedQuestions = [
    "How do I find a charging station?",
    "What is the cost of charging?",
    "How can I schedule a charging session?",
    "What are the charging station ratings?",
    "How do I update my EV software?",
    "What promotions are available?"
  ];

  // URL of your FastAPI backend
  final String _backendUrl = "http://10.0.2.2:8000/chat";

  /// Sends a message and calls the FastAPI backend for the bot's reply.
  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty) return;
    String currentTime = DateFormat('h:mm a').format(DateTime.now());
    setState(() {
      _messages.add({
        "sender": "user",
        "message": message,
        "timestamp": currentTime,
      });
    });
    _controller.clear();

    try {
      final response = await http.post(
        Uri.parse(_backendUrl),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"message": message}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        String reply = data['reply'];
        String botTime = DateFormat('h:mm a').format(DateTime.now());
        setState(() {
          _messages.add({
            "sender": "bot",
            "message": reply,
            "timestamp": botTime,
          });
        });
      } else {
        String botTime = DateFormat('h:mm a').format(DateTime.now());
        setState(() {
          _messages.add({
            "sender": "bot",
            "message": "Error: ${response.body}",
            "timestamp": botTime,
          });
        });
      }
    } catch (error) {
      String botTime = DateFormat('h:mm a').format(DateTime.now());
      setState(() {
        _messages.add({
          "sender": "bot",
          "message": "Failed to connect: $error",
          "timestamp": botTime,
        });
      });
    }
  }

  /// Shows a modal bottom sheet with the remaining predefined questions.
  void _showMorePredefinedQuestions() {
    List<String> remainingQuestions = _predefinedQuestions.skip(3).toList();
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          color: Colors.white,
          child: ListView(
            shrinkWrap: true,
            children: remainingQuestions.map((q) {
              return ListTile(
                title: Text(q),
                onTap: () {
                  Navigator.pop(context);
                  _sendMessage(q);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  /// Builds the predefined questions section as uniform buttons.
  Widget _buildPredefinedQuestions() {
    List<String> initialQuestions = _predefinedQuestions.take(3).toList();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var q in initialQuestions)
          SizedBox(
            width: double.infinity,
            height: 45,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.8),
                foregroundColor: const Color(0xFF388E3C),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
              ),
              onPressed: () => _sendMessage(q),
              child: Text(
                q,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        if (_predefinedQuestions.length > 3)
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onPressed: _showMorePredefinedQuestions,
            ),
          ),
      ],
    );
  }

  /// Builds an individual chat message bubble with an avatar and timestamp.
  Widget _buildMessageItem(Map<String, String> message) {
    bool isUser = message["sender"] == "user";
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isUser)
                CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.smart_toy, color: const Color(0xFF388E3C)),
                ),
              if (!isUser) const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(12),
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.7,
                ),
                decoration: BoxDecoration(
                  color: isUser ? Colors.green[100] : Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  message["message"] ?? "",
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              if (isUser) const SizedBox(width: 8),
              if (isUser)
                CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, color: const Color(0xFF388E3C)),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            message["timestamp"] ?? "",
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Green-themed AppBar.
      appBar: AppBar(
        title: const Text('Assistant Chat'),
        centerTitle: true,
        backgroundColor: const Color(0xFF388E3C),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF388E3C), Color(0xFF81C784)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Greeting text.
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16),
                child: Text(
                  "Hello, I'm your EV Assistant. How can I help you today?",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
              // Predefined questions section.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildPredefinedQuestions(),
              ),
              const SizedBox(height: 8),
              const Divider(color: Colors.white70, thickness: 1),
              // Date header.
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  "February 20, 2025",
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                ),
              ),
              // Chat messages list.
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) =>
                      _buildMessageItem(_messages[index]),
                ),
              ),
              // Chat input area.
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.white,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: const InputDecoration(
                          hintText: 'Type your message...',
                          border: InputBorder.none,
                        ),
                        onSubmitted: _sendMessage,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send, color: Color(0xFF388E3C)),
                      onPressed: () => _sendMessage(_controller.text),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
