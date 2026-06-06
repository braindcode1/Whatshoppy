import 'package:flutter/material.dart';
import 'bottom.dart';

class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("inbox")),
      body: const Center(
        child: Text(
          "Inbox Screen",
          style: TextStyle(fontSize: 24),
        ),
      ),
      bottomNavigationBar: const Bottom(currentIndex: 4),

    );
  }
}