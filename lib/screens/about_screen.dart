import 'package:flutter/material.dart';
import '../controllers/settings_controller.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final v = SettingsController.instance.settings.appVersion;
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: Center(
        child: Text('Mahan VPN\nVersion $v', textAlign: TextAlign.center, style: const TextStyle(fontSize: 18)),
      ),
    );
  }
}
