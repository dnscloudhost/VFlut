// lib/main.dart

import 'package:flutter/material.dart';

import 'controllers/settings_controller.dart';   // ← برای بارگذاری تنظیمات
import 'services/admob_service.dart';            // ← برای AdMob
import 'data/locations.dart';                    // ← allConfigs
import 'services/server_api.dart';               // ← loadAllServers
import 'screens/initializing_screen.dart';       // ← نقطهٔ شروع
import 'screens/home_screen.dart';
import 'screens/locations_screen.dart';
import 'screens/policy_screen.dart';              // ← صفحهٔ Privacy Policy
import 'screens/about_screen.dart';               // ← صفحهٔ About

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1️⃣ بارگذاری تنظیمات از API و کش
  await SettingsController.instance.load();

  // 2️⃣ مقداردهی اولیهٔ AdMob SDK
  await AdMobService.instance.init();

  // • نمایش یک اسپلش اد (اختیاری)
  // await AdMobService.instance.showSplashAd();

  // 3️⃣ بارگذاری اولیهٔ سرورها (تا در سراسر اپ کش شوند)
  allConfigs = await ServerApi.loadAllServers();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mahan VPN',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1B1B2F),
        primaryColor: Colors.blueAccent,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueAccent,
          brightness: Brightness.dark,
          background: const Color(0xFF1B1B2F),
        ),
      ),
      home: const InitializingScreen(),
      routes: {
        '/home':    (_) => const MainPage(),
        '/policy':  (_) => const PolicyScreen(),
        '/about':   (_) => const AboutScreen(),
      },
    );
  }
}

/// صفحهٔ اصلی ناوبری سه‌تبی
class MainPage extends StatefulWidget {
  const MainPage({super.key});
  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;
  final List<Widget> _pages = const [
    HomeScreen(),
    LocationsScreen(),
    Center(child: Text(
      'Settings Page Content',
      style: TextStyle(color: Colors.white, fontSize: 18),
    )),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF23233D),
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey[600],
        selectedFontSize: 12,
        unselectedFontSize: 12,
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.public), label: 'Locations'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: 'Settings'),
        ],
      ),
    );
  }
}
