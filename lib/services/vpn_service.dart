
// lib/services/vpn_service.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_v2ray/flutter_v2ray.dart';

import '../data/locations.dart';    // your `allConfigs` + LocationConfig
import 'server_api.dart';          // ServerApi.getSmartServers(...)

/// Manages “smart” VPN connections via the flutter_v2ray plugin.
class VpnService {
  // Singleton
  VpnService._()
      : _v2ray = FlutterV2ray(
    onStatusChanged: (status) {
      debugPrint('V2Ray status: $status');
    },
  );
  static final VpnService instance = VpnService._();

  final FlutterV2ray _v2ray;
  LocationConfig? _activeServer;
  Timer? _autoDisconnectTimer;

  /// Connect to the first “smart” server and auto-disconnect after 5m.
  Future<void> connectSmart() async {
    // 1️⃣ pull the smart list
    final smartList = ServerApi.getSmartServers(allConfigs);
    if (smartList.isEmpty) {
      debugPrint('VpnService: no smart servers to connect');
      return;
    }

    // pick the first one
    final cfg = smartList.first;
    _activeServer = cfg;

    // 2️⃣ parse your share/link (vmess/vless) into a full V2Ray config
    final parser = FlutterV2ray.parseFromURL(cfg.link);

    // 3️⃣ ensure V2Ray is ready & permitted
    await _v2ray.initializeV2Ray();
    await _v2ray.requestPermission();

    // 4️⃣ start the tunnel
    await _v2ray.startV2Ray(
      remark: cfg.country,                      // optional, for the UI
      config: parser.getFullConfiguration(),    // JSON string
      blockedApps: null,                        // or list of package names
      bypassSubnets: null,                      // or list of CIDRs
      proxyOnly: false,                         // full-device tunnel
    );

    // 5️⃣ auto-disconnect in 5 minutes
    _autoDisconnectTimer?.cancel();
    _autoDisconnectTimer = Timer(
      const Duration(minutes: 5),
      disconnectSmart,
    );
  }

  /// Tear down the tunnel immediately.
  Future<void> disconnectSmart() async {
    await _v2ray.stopV2Ray();
    _activeServer = null;
    _autoDisconnectTimer?.cancel();
  }

  /// Is there currently an active “smart” connection?
  bool get isConnected => _activeServer != null;
}
