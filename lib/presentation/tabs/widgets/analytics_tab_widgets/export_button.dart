import 'package:flutter/material.dart';

class ExportButton extends StatelessWidget {
  final VoidCallback onPressed;

  const ExportButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.download),
        label: const Text('Export Products'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF97316),
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}
