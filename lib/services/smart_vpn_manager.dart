// lib/services/smart_vpn_manager.dart

import 'dart:async';
import 'package:flutter_v2ray/flutter_v2ray.dart';
import '../data/locations.dart';

/// مدیریت اتصال به سرورهای Smart پیش از نمایش تبلیغ
class SmartVpnManager {
  SmartVpnManager._() : _v2ray = FlutterV2ray(onStatusChanged: (_) {});
  static final SmartVpnManager instance = SmartVpnManager._();

  final FlutterV2ray _v2ray;
  List<LocationConfig> _smartServers = [];
  LocationConfig? _active;
  Timer? _autoDisconnectTimer;

  /// تعیین لیست سرورهای Smart
  void setSmartServers(List<LocationConfig> servers) {
    _smartServers = servers;
  }

  /// اتصال به اولین سرور Smart و زمان‌بندی قطع خودکار پس از ۵ دقیقه
  Future<void> connectSmart() async {
    if (_smartServers.isEmpty) return;
    final cfg = _smartServers.first;
    _active = cfg;
    final parsed = FlutterV2ray.parseFromURL(cfg.link);
    await _v2ray.startV2Ray(
      remark: cfg.country,
      config: parsed.getFullConfiguration(),
      proxyOnly: true,
    );
    _autoDisconnectTimer?.cancel();
    _autoDisconnectTimer = Timer(const Duration(minutes: 5), disconnectSmart);
  }

  /// قطع اتصال Smart
  Future<void> disconnectSmart() async {
    await _v2ray.stopV2Ray();
    _active = null;
  }

  /// آیا Smart در حال حاضر متصل است؟
  bool get isConnected => _active != null;
}
