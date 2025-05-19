import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../controllers/settings_controller.dart';

class PolicyScreen extends StatelessWidget {
  const PolicyScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final url = SettingsController.instance.settings.privacyPolicyLink;
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: WebViewWidget(controller: WebViewController()..loadRequest(Uri.parse(url))),
    );
  }
}
