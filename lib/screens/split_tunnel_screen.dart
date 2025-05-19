// lib/screens/split_tunnel_screen.dart

import 'dart:typed_data'; // برای Uint8List
import 'package:flutter/foundation.dart'; // برای compute
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // برای RootIsolateToken
import 'package:flutter_v2ray/flutter_v2ray.dart'; // این پارامتر به ویجت پاس داده می‌شود
import 'package:device_apps/device_apps.dart';
import 'package:shared_preferences/shared_preferences.dart';

// مدل برای نگهداری اطلاعات اپلیکیشن به همراه وضعیت bypass
class AppInfo {
  final String packageName;
  final String appName;
  final Uint8List? appIcon; // آیکون اپ به صورت Uint8List
  bool isBypassed;
  final bool isSystemApp;

  AppInfo({
    required this.packageName,
    required this.appName,
    this.appIcon,
    this.isBypassed = false,
    required this.isSystemApp,
  });
}

// --- تابع Top-level یا Static برای اجرا در Isolate ---
// این تابع مسئول دریافت لیست اپلیکیشن‌ها در یک ترد جداگانه است.
Future<List<Application>> _fetchInstalledAppsInBackground(Map<String, dynamic> params) async {
  // مقداردهی اولیه Platform Channels برای این Isolate
  final RootIsolateToken? token = params['token'] as RootIsolateToken?;
  if (token != null) {
    BackgroundIsolateBinaryMessenger.ensureInitialized(token);
  } else {
    // اگر توکن نال باشد، به این معنی است که در محیطی هستیم که Isolate Token در دسترس نیست (مثلاً تست)
    // یا خطایی در ارسال آن رخ داده. در این حالت، DeviceApps ممکن است کار نکند.
    debugPrint("_fetchInstalledAppsInBackground: RootIsolateToken is null. Plugin calls might fail.");
  }

  final bool includeSysApps = params['includeSystemApps'] as bool? ?? true;
  final bool includeAppIcons = params['includeAppIcons'] as bool? ?? true;
  final bool onlyAppsWithLaunchIntent = params['onlyAppsWithLaunchIntent'] as bool? ?? false;

  try {
    return await DeviceApps.getInstalledApplications(
      includeAppIcons: includeAppIcons,
      includeSystemApps: includeSysApps,
      onlyAppsWithLaunchIntent: onlyAppsWithLaunchIntent,
    );
  } catch (e) {
    // اگر خطایی در Isolate رخ دهد، آن را لاگ می‌گیریم یا به شکل دیگری مدیریت می‌کنیم.
    debugPrint("Error fetching apps in background isolate: $e");
    return []; // برگرداندن لیست خالی در صورت خطا
  }
}
// --- پایان تابع برای Isolate ---


class SplitTunnelScreen extends StatefulWidget {
  final FlutterV2ray flutterV2ray; // این پارامتر فعلاً استفاده مستقیمی در این صفحه ندارد

  const SplitTunnelScreen({super.key, required this.flutterV2ray});

  @override
  State<SplitTunnelScreen> createState() => _SplitTunnelScreenState();
}

class _SplitTunnelScreenState extends State<SplitTunnelScreen> {
  List<AppInfo> _allAppsMasterList = []; // لیست اصلی برای نگهداری همه اپ‌ها یک بار
  List<AppInfo> _appsToDisplay = [];   // لیستی که در UI نمایش داده می‌شود (پس از فیلتر و جستجو)
  bool _isLoading = true;
  String _searchTerm = '';
  bool _showSystemApps = false; // برای کنترل نمایش اپ‌های سیستمی

  static const String bypassedPackagesPrefKey = 'bypassed_packages';

  @override
  void initState() {
    super.initState();
    _loadAppsAndPreferences();
  }

  Future<void> _loadAppsAndPreferences() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> bypassedPackages = prefs.getStringList(bypassedPackagesPrefKey) ?? [];

      final RootIsolateToken? token = RootIsolateToken.instance;
      if (token == null && kDebugMode) { // kDebugMode برای اینکه این لاگ فقط در حالت دیباگ نمایش داده شود
        debugPrint("RootIsolateToken is null in main isolate. Background isolate might not initialize plugins correctly.");
      }

      final Map<String, dynamic> fetchParams = {
        'includeSystemApps': true,        // همیشه همه اپ‌ها را از Isolate می‌گیریم
        'includeAppIcons': true,          // آیکون‌ها را هم می‌گیریم
        'onlyAppsWithLaunchIntent': false,
        'token': token,                   // ارسال توکن برای Isolate
      };

      List<Application> appsFromIsolate = await compute(_fetchInstalledAppsInBackground, fetchParams);

      if (!mounted) return; // بررسی مجدد mounted بودن پس از عملیات async

      _allAppsMasterList = appsFromIsolate.map((app) {
        return AppInfo(
          packageName: app.packageName,
          appName: app.appName,
          appIcon: (app is ApplicationWithIcon) ? app.icon : null,
          isBypassed: bypassedPackages.contains(app.packageName),
          isSystemApp: app.systemApp,
        );
      }).toList();

      _allAppsMasterList.sort((a, b) => a.appName.toLowerCase().compareTo(b.appName.toLowerCase()));
      _filterAndSortAppsToDisplay(); // برای اعمال فیلترهای اولیه (نمایش اپ‌های کاربر یا همه)

    } catch (e) {
      debugPrint("Error in _loadAppsAndPreferences (calling compute or processing results): $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load applications list: $e.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _filterAndSortAppsToDisplay() {
    List<AppInfo> filteredResult;

    if (!_showSystemApps) {
      filteredResult = _allAppsMasterList.where((app) => !app.isSystemApp).toList();
    } else {
      filteredResult = List.from(_allAppsMasterList); // ایجاد یک کپی جدید
    }

    if (_searchTerm.isNotEmpty) {
      final searchTermLower = _searchTerm.toLowerCase();
      filteredResult = filteredResult
          .where((app) =>
      app.appName.toLowerCase().contains(searchTermLower) ||
          app.packageName.toLowerCase().contains(searchTermLower))
          .toList();
    }
    // لیست _allAppsMasterList از قبل مرتب شده است، پس filteredResult هم مرتب خواهد بود.
    if (mounted) {
      setState(() {
        _appsToDisplay = filteredResult;
      });
    }
  }


  Future<void> _applyAndSaveChanges() async {
    final prefs = await SharedPreferences.getInstance();
    // لیست پکیج‌های انتخاب شده از لیست اصلی (master list) گرفته می‌شود
    final List<String> currentBypassedPackages = _allAppsMasterList
        .where((app) => app.isBypassed)
        .map((app) => app.packageName)
        .toList();

    await prefs.setStringList(bypassedPackagesPrefKey, currentBypassedPackages);
    debugPrint("Bypassed apps saved to SharedPreferences: $currentBypassedPackages");

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Split tunnel settings saved. Please reconnect VPN to apply changes.')),
      );
      Navigator.pop(context, true); // مقدار true نشان می‌دهد که تغییراتی ذخیره شده و نیاز به به‌روزرسانی در HomeScreen است
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color scaffoldBackgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final Color cardColor = const Color(0xFF2E2E4D); // رنگ کارت‌ها مشابه HomeScreen
    final Color hintColor = Colors.white.withOpacity(0.7);

    return Scaffold(
      backgroundColor: scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Split Tunnel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          Tooltip(
            message: _showSystemApps ? "Hide system apps" : "Show system apps",
            child: IconButton(
              icon: Icon(
                _showSystemApps ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: Colors.white70,
              ),
              onPressed: () {
                setState(() {
                  _showSystemApps = !_showSystemApps;
                  _filterAndSortAppsToDisplay(); // به‌روزرسانی لیست نمایشی
                });
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.save_alt_outlined, color: Colors.white), // آیکون بهتر برای ذخیره
            tooltip: "Save Changes",
            onPressed: _applyAndSaveChanges,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: TextField(
              onChanged: (value) {
                // تاخیر کوچک برای جلوگیری از فراخوانی مکرر فیلتر هنگام تایپ سریع (debounce)
                // این بخش اختیاری است اما می‌تواند تجربه کاربری را بهتر کند.
                // فعلاً بدون debounce:
                setState(() {
                  _searchTerm = value;
                  _filterAndSortAppsToDisplay();
                });
              },
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search apps...',
                hintStyle: TextStyle(color: hintColor),
                prefixIcon: Icon(Icons.search, color: hintColor),
                filled: true,
                fillColor: cardColor.withOpacity(0.8), // کمی شفاف‌تر
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16), // تنظیم ارتفاع فیلد
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : _appsToDisplay.isEmpty
                ? Center(
              child: Padding( // برای فاصله از اطراف
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  _searchTerm.isNotEmpty
                      ? 'No apps found matching "$_searchTerm"'
                      : (_showSystemApps ? 'No applications found on device' : 'No user-installed applications found.\nTap the 👁️ icon above to show system apps.'),
                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16, height: 1.5),
                  textAlign: TextAlign.center,
                ),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
              itemCount: _appsToDisplay.length,
              itemBuilder: (context, index) {
                final app = _appsToDisplay[index];
                return Card(
                  elevation: 2,
                  shadowColor: Colors.black.withOpacity(0.3),
                  color: cardColor,
                  margin: const EdgeInsets.symmetric(vertical: 5.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: app.appIcon != null && app.appIcon!.isNotEmpty
                        ? CircleAvatar(
                      backgroundImage: MemoryImage(app.appIcon!),
                      backgroundColor: Colors.transparent, // یا یک رنگ fallback
                      radius: 22, // کمی بزرگتر
                    )
                        : CircleAvatar(
                      backgroundColor: Colors.grey.shade800, // رنگ تیره‌تر برای fallback
                      radius: 22,
                      child: Text(
                        app.appName.isNotEmpty ? app.appName[0].toUpperCase() : "?",
                        style: const TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(
                      app.appName,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      app.packageName,
                      style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Switch(
                      value: app.isBypassed,
                      onChanged: (bool value) {
                        setState(() {
                          app.isBypassed = value;
                          // به‌روزرسانی وضعیت در لیست اصلی
                          final masterAppIndex = _allAppsMasterList.indexWhere((masterApp) => masterApp.packageName == app.packageName);
                          if (masterAppIndex != -1) {
                            _allAppsMasterList[masterAppIndex].isBypassed = value;
                          }
                        });
                      },
                      activeColor: Colors.blueAccent.shade200,
                      activeTrackColor: Colors.blueAccent.withOpacity(0.5),
                      inactiveThumbColor: Colors.grey.shade400,
                      inactiveTrackColor: Colors.grey.shade800.withOpacity(0.7),
                    ),
                    onTap: () { // برای راحتی کاربر، با تپ روی آیتم هم سوییچ تغییر کند
                      setState(() {
                        app.isBypassed = !app.isBypassed;
                        final masterAppIndex = _allAppsMasterList.indexWhere((masterApp) => masterApp.packageName == app.packageName);
                        if (masterAppIndex != -1) {
                          _allAppsMasterList[masterAppIndex].isBypassed = app.isBypassed;
                        }
                      });
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}