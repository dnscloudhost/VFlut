import 'package:flutter/material.dart';

class ConfigScreen extends StatelessWidget {
  const ConfigScreen({super.key});

  // لیست نمونهٔ کانفیگ‌ها
  final List<Map<String,String>> _configs = const [
    {
      'name': 'UAE',
      'link': 'vless://2387e86f-30ab-46f9-ae3b-ec9595da9309@emr.iranbuildings.com:1196?security=&type=tcp&path=/&headerType=http&host=speedtest.net&encryption=none#%F0%9F%87%A6%F0%9F%87%AA%20Emirates%20%7C%20Backup%20%F0%9F%94%B5'
    },
    {
      'name': 'Armenia',
      'link': 'vless://2387e86f-30ab-46f9-ae3b-ec9595da9309@armb.iranbuildings.com:8080?security=&type=ws&path=/?ed%3D2048&encryption=none#%F0%9F%87%A6%F0%9F%87%B2%20Armenia%20%7C%20Backup%20%F0%9F%94%B5'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurations'),
        centerTitle: true,
      ),
      body: ListView.separated(
        itemCount: _configs.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (ctx, i) {
          final cfg = _configs[i];
          return ListTile(
            title: Text(cfg['name']!, style: const TextStyle(color: Colors.white)),
            subtitle: Text(cfg['link']!, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            trailing: IconButton(
              icon: const Icon(Icons.play_arrow, color: Colors.blueAccent),
              onPressed: () {
                // اینجا می‌تونی لینک رو به HomeScreen یا
                // کلاس مدیریت‌کنندهٔ V2Ray ارسال کنی
                Navigator.of(context).pop(cfg['link']);
              },
            ),
          );
        },
      ),
    );
  }
}
