import 'package:flutter/material.dart';

class ScanScreenPlaceholder extends StatelessWidget {
  const ScanScreenPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Start Scan")),
      body: const Center(child: Text("Scan Screen Area - Marker Placement + Camera")),
    );
  }
}