// lib/screens/home_screen.dart
//
// تغییرات تازه:
//   •‌ استفاده از SettingsController برای:
//       ◦ تشخیص کشورهای smart و نمایش/عدم‌نمایش تبلیغ
//       ◦ پیاده‌سازی delay قبل از Connect / Disconnect
//       ◦ محدودیت زمانی اتصال (connection limit)
//   • همچنان منطق Smart-Server + AdMob موجود است
//   • هیچ بخشی از UI یا لاجیک قدیمی حذف نشده است
import 'package:flutter/services.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_v2ray/flutter_v2ray.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/locations.dart';
import '../services/server_api.dart';
import '../services/admob_service.dart';
import '../widgets/ad_preparing_overlay.dart';
import '../controllers/settings_controller.dart';   // ⬅️ NEW

import 'locations_screen.dart';
import 'split_tunnel_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /* ------------------------------------------------------------------ */
  late final FlutterV2ray flutterV2ray;
  final ValueNotifier<V2RayStatus> status = ValueNotifier(V2RayStatus());

  String? coreVersion;
  Timer? _ticker;
  Duration _duration = Duration.zero;

  Timer? _limitTimer;                         // ⬅️ NEW
  String _currentServer = 'Select Server';
  String _currentCity   = '';
  String? _currentLink;
  String _currentCode   = 'default';

  final String vpnAppName = "Mahan VPN";
  List<String> _bypassedAppPackages = [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _loadBypassedApps();

    if (allConfigs.isNotEmpty) {
      final first = allConfigs.first;
      _currentServer = first.country;
      _currentCity   = first.city;
      _currentLink   = first.link;
      _currentCode   = first.countryCode;
    }

    flutterV2ray = FlutterV2ray(onStatusChanged: (s) {
      if (!mounted) return;
      status.value = s;
      _handleTicker(s);
    });

    await flutterV2ray.initializeV2Ray(
      notificationIconResourceType: 'mipmap',
      notificationIconResourceName: 'ic_launcher',
    );
    if (!mounted) return;
    coreVersion = await flutterV2ray.getCoreVersion();
    setState(() {});
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _limitTimer?.cancel();
    status.dispose();
    super.dispose();
  }

  Future<void> _loadBypassedApps() async {
    final prefs = await SharedPreferences.getInstance();
    _bypassedAppPackages = prefs.getStringList('bypassed_packages') ?? [];
  }

  void _handleTicker(V2RayStatus s) {
    if (s.state == 'CONNECTED') {
      _ticker?.cancel();
      _duration = Duration.zero;
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) {
          setState(() => _duration += const Duration(seconds: 1));
        }
      });
    } else {
      _ticker?.cancel();
      _limitTimer?.cancel();
      setState(() => _duration = Duration.zero);
    }
  }

  String _applyV2RayConfigTweaks(String rawJson) {
    final decoded = jsonDecode(rawJson);
    final cfg = decoded is Map
        ? Map<String, dynamic>.from(decoded)
        : <String, dynamic>{};

    cfg['stats'] = cfg['stats'] ?? {};
    final policy = Map<String, dynamic>.from(cfg['policy'] ?? {});
    final levels = Map<String, dynamic>.from(policy['levels'] ?? {});
    final level0 = Map<String, dynamic>.from(levels['0'] ?? {});
    level0['statsUserUplink']   = true;
    level0['statsUserDownlink'] = true;
    levels['0'] = level0;
    policy['levels'] = levels;
    cfg['policy'] = policy;

    if (_bypassedAppPackages.isNotEmpty) {
      final routing = Map<String, dynamic>.from(cfg['routing'] ?? {});
      routing['domainStrategy'] = routing['domainStrategy'] ?? "IPIfNonMatch";
      final rules = List<dynamic>.from(routing['rules'] ?? []);
      rules.removeWhere((r) =>
      r is Map &&
          r['type'] == 'field' &&
          r['outboundTag'] == 'direct' &&
          r.containsKey('packageName')
      );
      rules.add({
        "type": "field",
        "outboundTag": "direct",
        "packageName": List<String>.from(_bypassedAppPackages),
      });
      routing['rules'] = rules;
      cfg['routing'] = routing;
    }

    return jsonEncode(cfg);
  }

  Future<void> _toggleConnection() async =>
      status.value.state == 'CONNECTED' ? _startDisconnectFlow() : _startConnectFlow();

  Future<void> _startConnectFlow() async {
    final settings = SettingsController.instance.settings;

    if (_currentLink == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a server first.')),
      );
      return;
    }

    String link   = _currentLink!;
    String remark = _currentServer;
    String code   = _currentCode;
    String city   = _currentCity;

    if (link == 'auto' && allConfigs.isNotEmpty) {
      final best = allConfigs.first;
      link   = best.link;
      remark = best.country;
      code   = best.countryCode;
      city   = best.city;
    }

    if (settings.delayBeforeConnect != null) {
      await Future.delayed(Duration(milliseconds: settings.delayBeforeConnect!));
    }

    final needSmart = SettingsController.instance.isSmartCountry(code);

    if (needSmart) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const AdPreparingOverlay(message: 'Connecting to smart…'),
      );
      final smart = (ServerApi.smart(allConfigs)..shuffle()).firstOrNull;
      if (smart != null) await _connectToConfig(smart, proxyOnly: true);
      Navigator.pop(context);
    }

    if (settings.showAds) {
      await AdMobService.instance.showConnectAd();
    }

    if (needSmart) {
      await Future.delayed(const Duration(minutes: 5));
    }

    await _connectToConfig(
      LocationConfig(
        id: -1,
        country: remark,
        city: city,
        link: link,
        countryCode: code,
        serverType: 'free',
      ),
    );
  }

  Future<void> _startDisconnectFlow() async {
    final settings = SettingsController.instance.settings;

    if (settings.delayBeforeDisconnect != null) {
      await Future.delayed(Duration(milliseconds: settings.delayBeforeDisconnect!));
    }

    final needSmart = SettingsController.instance.isSmartCountry(_currentCode);

    if (needSmart) {
      await flutterV2ray.stopV2Ray();
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const AdPreparingOverlay(message: 'Disconnecting smart…'),
      );
      final smart = ServerApi.smart(allConfigs).firstOrNull;
      if (smart != null) await _connectToConfig(smart, proxyOnly: true);
      Navigator.pop(context);
    }

    if (settings.showAds) {
      await AdMobService.instance.showDisconnectAd();
    }

    await flutterV2ray.stopV2Ray();
  }

  Future<bool> _connectToConfig(LocationConfig cfg, {bool proxyOnly = false}) async {
    final granted = await flutterV2ray.requestPermission();
    if (!granted) return false;

    final parsed = FlutterV2ray.parseFromURL(cfg.link);
    final config = _applyV2RayConfigTweaks(parsed.getFullConfiguration());

    try {
      await flutterV2ray.startV2Ray(
        remark: cfg.country,
        config: config,
        proxyOnly: proxyOnly,
      );
      setState(() {
        _currentServer = cfg.country;
        _currentCity   = cfg.city;
        _currentLink   = cfg.link;
        _currentCode   = cfg.countryCode;
      });

      _scheduleLimitTimer();              // ⬅️ NEW
      return true;
    } catch (e) {
      debugPrint('Failed to connect: $e');
      return false;
    }
  }

  void _scheduleLimitTimer() {
    _limitTimer?.cancel();
    final set = SettingsController.instance.settings;
    if (set.connectionLimitHours == null && set.connectionLimitMinutes == null) return;

    final dur = Duration(
      hours:   set.connectionLimitHours   ?? 0,
      minutes: set.connectionLimitMinutes ?? 0,
    );
    _limitTimer = Timer(dur, () {
      if (mounted && status.value.state == 'CONNECTED') {
        _startDisconnectFlow();
      }
    });
  }

  String _formatDuration(Duration d) =>
      '${d.inHours.toString().padLeft(2, '0')}:' +
          '${(d.inMinutes % 60).toString().padLeft(2, '0')}:' +
          '${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  String _formatBytes(int b, {int decimals = 0}) {
    if (b <= 0) return '0 B';
    const u = ['B', 'KB', 'MB', 'GB', 'TB'];
    int i = (math.log(b) / math.log(1024)).floor().clamp(0, u.length - 1);
    return i == 0
        ? '$b ${u[i]}'
        : '${(b / math.pow(1024, i)).toStringAsFixed(decimals)} ${u[i]}';
  }

  Widget _buildFlag() {
    final code = _currentCode.toLowerCase();
    if (code == 'globe') {
      return const Icon(Icons.language_rounded, size: 32, color: Colors.white70);
    }
    if (code == 'default' || code == 'error') {
      return const Icon(Icons.public_off_rounded, size: 32, color: Colors.white60);
    }
    final assetPath = 'assets/flags/$code.svg';
    return FutureBuilder<ByteData>(
      future: rootBundle.load(assetPath),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.done && snap.hasData) {
          return SvgPicture.asset(assetPath, width: 32, height: 32);
        }
        return const Icon(Icons.public_off_rounded, size: 32, color: Colors.white60);
      },
    );
  }

  Future<bool> assetExists(String assetPath) async {
    try {
      await rootBundle.load(assetPath);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    const gradientStart = Color(0xFF2A2A4E);
    const gradientEnd   = Color(0xFF1B1B2F);
    const cardColor     = Color(0xFF2E2E4D);
    const accent        = Color(0xFF6C55E0);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [gradientStart, gradientEnd],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0, 0.7],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(Icons.apps_rounded, color: Colors.white70, size: 28),
            onPressed: () {},
          ),
          title: Text(
            vpnAppName,
            style: const TextStyle(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.tune_rounded, color: Colors.white70, size: 28),
              tooltip: 'Split Tunnel',
              onPressed: () async {
                final r = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SplitTunnelScreen(flutterV2ray: flutterV2ray)),
                );
                await _loadBypassedApps();
                if (r == true && status.value.state == 'CONNECTED' && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Split-tunnel updated. Re-connect to apply.')),
                  );
                }
              },
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              /* ----------- بنر ارتقا ------------- */
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.workspace_premium, color: Colors.white, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Upgrade to Pro',
                                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                            Text('Unlock all servers & high speed.',
                                style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 11.5)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(flex: 1),

              /* ----------- Power & Status ----------- */
              ValueListenableBuilder<V2RayStatus>(
                valueListenable: status,
                builder: (_, st, __) {
                  final on = st.state == 'CONNECTED';
                  final dur = on ? _formatDuration(_duration) : '00:00:00';

                  return Column(
                    children: [
                      Text(dur,
                          style: const TextStyle(
                            fontFamily: 'Courier',
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 6,
                            color: Colors.white,
                          )),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              st.state.toUpperCase(),
                              style: TextStyle(
                                color: on ? const Color(0xFF4CAF50) : const Color(0xFFF44336),
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 25),
                      GestureDetector(
                        onTap: _toggleConnection,
                        child: Lottie.asset(
                          on ? 'assets/lottie/power_on.json' : 'assets/lottie/power_off.json',
                          width: 220,
                          height: 220,
                        ),
                      ),
                      if (on && _currentServer != 'Select Server' && _currentServer != 'Auto-Select')
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text('Connected to $_currentServer',
                              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
                        ),
                    ],
                  );
                },
              ),

              const Spacer(flex: 2),

              /* ----------- Stats ----------- */
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                child: ValueListenableBuilder<V2RayStatus>(
                  valueListenable: status,
                  builder: (_, st, __) {
                    final down = _formatBytes(st.download, decimals: 0);
                    final up   = _formatBytes(st.upload,   decimals: 0);
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _SvgStatItem(svgPath: 'assets/icons/download.svg', value: down, label: 'Download'),
                        _SvgStatItem(svgPath: 'assets/icons/upload.svg',   value: up,   label: 'Upload'),
                      ],
                    );
                  },
                ),
              ),

              /* ----------- Current server ----------- */
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
                    child: Container(
                      height: 70,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: cardColor.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Row(
                        children: [
                          ClipOval(child: _buildFlag()),

                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_currentServer,
                                    style: const TextStyle(color: Colors.white, fontSize: 15.5, fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis),
                                if (_currentCity.isNotEmpty)
                                  Text(_currentCity,
                                      style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                                      overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              final loc = await Navigator.push<LocationConfig>(
                                context,
                                MaterialPageRoute(builder: (_) => const LocationsScreen()),
                              );
                              if (loc == null || !mounted) return;

                              final changed = _currentLink != loc.link;
                              if (status.value.state == 'CONNECTED' && (changed || _currentLink == 'auto')) {
                                await flutterV2ray.stopV2Ray();
                              }

                              setState(() {
                                _currentServer = loc.country;
                                _currentCity   = loc.city;
                                _currentLink   = loc.link;
                                _currentCode   = loc.countryCode;
                              });

                              if (loc.link == 'auto') {
                                _toggleConnection();
                              }
                            },
                            child: const Text('Change',
                                style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 14)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ---------- ویجت کوچکِ آمار (آپ/دانلود) ---------- */
class _SvgStatItem extends StatelessWidget {
  final String svgPath;
  final String value;
  final String label;
  const _SvgStatItem({required this.svgPath, required this.value, required this.label, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(svgPath, width: 33.3, height: 33.3),
        const SizedBox(height: 5),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 11)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
