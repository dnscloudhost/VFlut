// lib/screens/initializing_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';

import '../data/locations.dart';                   // provides global allConfigs
import '../services/server_api.dart';             // ServerApi.loadAllServers, getSmartServers()
import '../controllers/settings_controller.dart'; // SettingsController
import '../services/smart_vpn_manager.dart';      // SmartVpnManager
import '../services/admob_service.dart';          // AdMobService
import '../main.dart';                            // MainPage

class InitializingScreen extends StatefulWidget {
  const InitializingScreen({Key? key}) : super(key: key);
  @override
  State<InitializingScreen> createState() => _InitializingScreenState();
}

class _InitializingScreenState extends State<InitializingScreen> {
  double _progressValue = 0.0;
  int _currentStepIndex = 0;

  // Keep this as dynamic so you can store both String and callback
  late final List<Map<String, dynamic>> _tasks;
  late final List<bool> _completed;

  @override
  void initState() {
    super.initState();

    _tasks = [
      {
        'text': 'Initializing security',
        'task': () => _simulateTask(durationMillis: 800),
      },
      {
        'text': 'Loading app settings',
        'task': () async {
          await SettingsController.instance.load();
        },
      },
      {
        'text': 'Checking connection',
        'task': () => _simulateTask(durationMillis: 700),
      },
      {
        'text': 'Preparing VPN servers',
        'task': () => _prepareVpnServers(),
      },
      {
        'text': 'Almost ready',
        'task': () => _simulateTask(durationMillis: 500),
      },
    ];

    _completed = List<bool>.filled(_tasks.length, false);
    _runSequence();
  }

  static Future<void> _simulateTask({int durationMillis = 500}) =>
      Future.delayed(Duration(milliseconds: durationMillis));

  Future<void> _prepareVpnServers() async {
    try {
      // 1️⃣ Load all servers
      allConfigs = await ServerApi.loadAllServers();
      if (allConfigs.isEmpty) {
        debugPrint('Warning: no VPN servers loaded');
      }

      // 2️⃣ Register smart servers
      final smartList = ServerApi.getSmartServers(allConfigs);
      SmartVpnManager.instance.setSmartServers(smartList);

      // 3️⃣ Detect user country
      final cc = (await SettingsController.instance.detectUserCountryCode())
          .toLowerCase();

      // 4️⃣ If it's a smart country, connect smart
      if (SettingsController.instance.isSmartCountry(cc)) {
        await SmartVpnManager.instance.connectSmart();
      }
    } catch (e) {
      debugPrint('Error preparing VPN servers: $e');
    }
  }

  Future<void> _runSequence() async {
    for (var i = 0; i < _tasks.length; i++) {
      if (!mounted) return;
      setState(() => _currentStepIndex = i);
      // Cast and invoke the stored callback
      await (_tasks[i]['task'] as Future<void> Function())();
      if (!mounted) return;
      setState(() {
        _completed[i] = true;
        _progressValue = (i + 1) / _tasks.length;
      });
    }

    // Show splash ad if enabled
    final settings = SettingsController.instance.settings;
    if (settings.showAds) {
      await AdMobService.instance.showSplashAd();
    }

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainPage()),
    );
  }

  Widget _buildStepItem(String text, bool done, bool active) {
    IconData icon;
    Color color;
    TextStyle style;

    if (done) {
      icon = Icons.check_circle_rounded;
      color = Colors.greenAccent.shade400;
      style = TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 15);
    } else if (active) {
      icon = Icons.more_horiz_rounded;
      color = Colors.blueAccent.shade100;
      style = const TextStyle(
          color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600);
    } else {
      icon = Icons.circle_outlined;
      color = Colors.grey.shade600;
      style = TextStyle(color: Colors.grey.shade500, fontSize: 15);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Text(text, style: style),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const vpnAppName = 'Mahan VPN';
    const vpnAppSlogan = 'Secure Connection • Fast Speed';

    return Scaffold(
      backgroundColor: const Color(0xFF1A2035),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shield_outlined,
                  size: 80, color: Colors.blueAccent.shade100),
              const SizedBox(height: 24),
              const Text(vpnAppName,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2)),
              const SizedBox(height: 8),
              Text(vpnAppSlogan,
                  style: TextStyle(
                      color: Colors.grey.shade400, fontSize: 16)),
              const SizedBox(height: 48),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _progressValue,
                  backgroundColor:
                  Colors.grey.shade700.withOpacity(0.5),
                  valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.blueAccent.shade200),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 32),
              for (var i = 0; i < _tasks.length; i++)
                _buildStepItem(
                  _tasks[i]['text'] as String,
                  _completed[i],
                  i == _currentStepIndex && !_completed[i],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
