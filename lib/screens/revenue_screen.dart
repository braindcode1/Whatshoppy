import 'package:flutter/material.dart';

class RevenueScreen extends StatelessWidget {
  const RevenueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Revenue")),
      body: const Center(
        child: Text(
          "Revenue Screen",
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
