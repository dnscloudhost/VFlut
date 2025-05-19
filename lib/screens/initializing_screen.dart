// lib/screens/initializing_screen.dart
//
// تغییرات جدید:
//  • تعریف تسک‌ها در initState برای جلوگیری از ارور دسترسی به متدهای نمونه
//  • دریافت و کش‌کردن تنظیمات اپ و سرورها در این صفحه
//  • نمایش تبلیغ Splash در صورت فعال بودن تنظیمات

import 'dart:async';
import 'package:flutter/material.dart';

import '../main.dart';
import '../services/server_api.dart';
import '../data/locations.dart';
import '../controllers/settings_controller.dart';
import '../services/admob_service.dart';
import '../services/server_api.dart';

class InitializingScreen extends StatefulWidget {
  const InitializingScreen({super.key});

  @override
  State<InitializingScreen> createState() => _InitializingScreenState();
}

class _InitializingScreenState extends State<InitializingScreen> {
  double _progressValue = 0.0;
  int _currentStepIndex = 0;

  late final List<Map<String, dynamic>> _initializationTasks;
  late final List<bool> _stepCompleted;

  @override
  void initState() {
    super.initState();

    _initializationTasks = [
      {
        'text': "Initializing security",
        'task': () => _simulateTask(durationMillis: 800),
      },
      {
        'text': "Loading app settings",
        'task': () async {
          await SettingsController.instance.load();
        },
      },
      {
        'text': "Checking connection",
        'task': () => _simulateTask(durationMillis: 700),
      },
      {
        'text': "Preparing VPN servers",
        'task': () => _loadServerConfigs(),
      },
      {
        'text': "Almost ready",
        'task': () => _simulateTask(durationMillis: 500),
      },
    ];

    _stepCompleted = List<bool>.filled(_initializationTasks.length, false);
    _startInitializationSequence();
  }

  static Future<void> _simulateTask({int durationMillis = 500}) =>
      Future.delayed(Duration(milliseconds: durationMillis));

  Future<void> _loadServerConfigs() async {
    try {
      // ← متد صحیح:
      allConfigs = await ServerApi.loadAllServers();
      if (allConfigs.isEmpty) {
        debugPrint("Warning: Server config list is empty after loading.");
      }
    } catch (e) {
      debugPrint("Error loading server configs: $e");
    }
  }

  Future<void> _startInitializationSequence() async {
    for (var i = 0; i < _initializationTasks.length; i++) {
      if (!mounted) return;

      setState(() {
        _currentStepIndex = i;
      });

      final task = _initializationTasks[i]['task'] as Future<void> Function();
      await task();

      if (!mounted) return;
      setState(() {
        _stepCompleted[i] = true;
        _progressValue = (i + 1) / _initializationTasks.length;
      });
    }

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

  Widget _buildStepItem(String text, bool completed, bool isActive) {
    IconData icon;
    Color color;
    TextStyle style;

    if (completed) {
      icon = Icons.check_circle_rounded;
      color = Colors.greenAccent.shade400;
      style = TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 15);
    } else if (isActive) {
      icon = Icons.more_horiz_rounded;
      color = Colors.blueAccent.shade100;
      style = const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600);
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
    const vpnAppName   = "Mahan VPN";
    const vpnAppSlogan = "Secure Connection • Fast Speed";

    return Scaffold(
      backgroundColor: const Color(0xFF1A2035),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shield_outlined, size: 80, color: Colors.blueAccent.shade100),
              const SizedBox(height: 24),
              const Text(vpnAppName,
                  style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              const SizedBox(height: 8),
              Text(vpnAppSlogan, style: TextStyle(color: Colors.grey.shade400, fontSize: 16)),
              const SizedBox(height: 48),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _progressValue,
                  backgroundColor: Colors.grey.shade700.withOpacity(0.5),
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent.shade200),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 32),
              if (_initializationTasks.isNotEmpty)
                for (var i = 0; i < _initializationTasks.length; i++)
                  _buildStepItem(
                    _initializationTasks[i]['text'] as String,
                    _stepCompleted[i],
                    i == _currentStepIndex && !_stepCompleted[i],
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
