import 'package:flutter/material.dart';

class AdPreparingOverlay extends StatelessWidget {
  final String message;
  const AdPreparingOverlay({super.key, this.message = 'Preparing ad…'});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.85),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 24),
            Text(message,
                style: const TextStyle(color: Colors.white70, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
