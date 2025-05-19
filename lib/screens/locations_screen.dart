// lib/screens/locations_screen.dart

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_v2ray/flutter_v2ray.dart';
import '../controllers/settings_controller.dart';
import '../data/locations.dart';

class LocationsScreen extends StatefulWidget {
  const LocationsScreen({Key? key}) : super(key: key);

  @override
  State<LocationsScreen> createState() => _LocationsScreenState();
}

class _LocationsScreenState extends State<LocationsScreen> {
  late final FlutterV2ray _pingUtility;

  String _search = '';
  bool _autoConnect = false;
  String _filter = 'All';
  String? _selectedServerLink;

  final Map<String, int> _pingResults = {};
  final Map<String, bool> _isPinging = {};

  final List<String> _filterLabels = ['All', 'Free', 'Premium'];

  @override
  void initState() {
    super.initState();
    _pingUtility = FlutterV2ray(onStatusChanged: (status) {});
    // اگر سرور فعالی از HomeScreen پاس داده شده بود، اینجا _selectedServerLink را ست می‌کردیم
    // برای مثال: _selectedServerLink = widget.currentlySelectedServerLink; (اگر چنین پارامتری وجود داشت)
  }

  List<LocationConfig> get _filtered {
    final settings = SettingsController.instance.settings;
    return allConfigs.where((loc) {
      // ⬅️ این خط را اضافه کنید تا سرورهای smart اصلاً در لیست ظاهر نشوند
      if (loc.serverType == 'smart') return false;

      final searchLower = _search.toLowerCase();
      final m1 = loc.country.toLowerCase().contains(searchLower);
      final m2 = loc.city.toLowerCase().contains(searchLower);
      final matchesFilter = _filter == 'All'
          ? true
          : _filter.toLowerCase() == (loc.serverType?.toLowerCase() ?? 'free');
      return (m1 || m2) && matchesFilter;
    }).toList();
  }


  // تعداد سرورهای پیشنهادی را می‌توان به 3 یا بیشتر افزایش داد، به شرطی که UI اجازه دهد
  List<LocationConfig> get _recommended => _filtered.isNotEmpty ? _filtered.take(3).toList() : [];


  Map<String, List<LocationConfig>> get _grouped {
    final map = <String, List<LocationConfig>>{};
    for (var loc in _filtered) {
      map.putIfAbsent(loc.country, () => []).add(loc);
    }
    return map;
  }

  Color _pingColor(int? ping) {
    if (ping == null || ping < 0) return Colors.grey.shade500;
    return ping < 200
        ? Colors.greenAccent.shade400
        : (ping < 500 ? Colors.yellowAccent.shade400 : Colors.redAccent.shade400);
  }

  Future<void> _fetchPing(String link, String locationKey) async {
    if (!mounted || (_isPinging[locationKey] ?? false) || _pingResults.containsKey(locationKey)) return;
    if(!mounted) return; // بررسی مجدد
    setState(() {
      _isPinging[locationKey] = true;
    });

    final parser = FlutterV2ray.parseFromURL(link);
    try {
      final int ping = await _pingUtility.getServerDelay(config: parser.getFullConfiguration());
      if (mounted) {
        setState(() {
          _pingResults[locationKey] = ping;
          _isPinging[locationKey] = false;
        });
      }
    } catch (e) {
      debugPrint("Error getting ping for $link: $e");
      if (mounted) {
        setState(() {
          _pingResults[locationKey] = -1; // مقدار منفی برای نمایش خطا
          _isPinging[locationKey] = false;
        });
      }
    }
  }

  void _selectServer(LocationConfig loc) {
    setState(() {
      _selectedServerLink = loc.link;
      _autoConnect = false;
    });
    Navigator.pop(context, loc);
  }

  void _handleAutoConnectToggle() {
    setState(() {
      _autoConnect = !_autoConnect;
      if (_autoConnect) {
        _selectedServerLink = null;
        debugPrint("Auto-Connect Toggled. Returning 'auto' config to HomeScreen.");
        // یک LocationConfig خاص برای حالت Auto-Connect برمی‌گردانیم
        // HomeScreen باید این حالت خاص را تشخیص دهد و بهترین سرور را انتخاب کند.
        final autoSelectConfig = LocationConfig(
          id: -99, // یک ID خاص برای شناسایی
          country: "Auto-Select",
          city: "Fastest Server",
          link: "auto", // یک لینک خاص
          countryCode: "globe", // یک کد برای آیکون کره زمین یا مشابه
          serverType: "auto",
        );
        Navigator.pop(context, autoSelectConfig);
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    final Color scaffoldBackgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final Color cardColor = const Color(0xFF2E2E4D);
    final Color accentColor = const Color(0xFF6C55E0);

    // ✦ مقداردهی autoEnabled از تنظیمات
    final autoEnabled = SettingsController.instance.settings.autoConnectEnabled;

    // محاسبه عرض برای کارت‌های پیشنهادی
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPagePadding = 16.0 * 2;
    final spacingBetweenRecommendedCards = 8.0 * 2;
    final recommendedCardWidth = (screenWidth - horizontalPagePadding - spacingBetweenRecommendedCards) / 3;
    final double recommendedCardHeight = 75;

    if (allConfigs.isEmpty && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          // ...
        }
      });
      return Scaffold(
        backgroundColor: scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: scaffoldBackgroundColor,
          elevation: 0,
          title: const Text('Select Server', style: TextStyle(color: Colors.white)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: Text(
            'Loading server list or list is empty.',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: scaffoldBackgroundColor,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        title: const Text('Select Server', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            // --- کارت Auto-Select با رنگ بنفش و غیرفعال‌سازی بر اساس تنظیمات ---
            InkWell(
              onTap: autoEnabled ? _handleAutoConnectToggle : null,
              borderRadius: BorderRadius.circular(12),
              child: Opacity(
                opacity: autoEnabled ? 1.0 : 0.4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _autoConnect ? Colors.white.withOpacity(0.7) : Colors.transparent,
                      width: _autoConnect ? 2.0 : 0.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Image.asset('assets/auto_connect.png', width: 30, height: 30),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Auto Select',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold)),
                            SizedBox(height: 3),
                            Text('Connect to the fastest server',
                                style: TextStyle(color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                      ),
                      if (_autoConnect)
                        const Icon(Icons.power_settings_new_rounded, color: Colors.white, size: 24),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // --- فیلد جستجو (کوچک‌تر شده) ---
            TextField(
              style: const TextStyle(color: Colors.white, fontSize: 14, letterSpacing: 0.3), // فونت و فاصله حروف کمی تغییر کرد
              decoration: InputDecoration(
                hintText: 'Search country or city...', // متن مشابه نمونه
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14, letterSpacing: 0.3),
                prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.5), size: 20),
                filled: true,
                fillColor: cardColor.withOpacity(0.7), // کمی شفاف‌تر
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 15.0), // ارتفاع کمتر
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none),
              ),
              onChanged: (v) => setState(() {
                _search = v;
              }),
            ),
            const SizedBox(height: 20),

            // --- تب‌های فیلتر (نوار یکپارچه) ---
            Container(
              height: 40, // ارتفاع کمتر برای نوار فیلتر
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: _filterLabels.map((label) {
                  final bool isSelected = label == _filter;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _filter = label),
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 3), // فاصله کمتر
                        decoration: BoxDecoration(
                          color: isSelected ? accentColor : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            label,
                            style: TextStyle(
                                color: isSelected ? Colors.white : Colors.grey.shade400,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal, // کمی وزن کمتر برای حالت انتخاب شده
                                fontSize: 13
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),

            // --- سرورهای پیشنهادی (کارت‌های کوچک‌تر شده) ---
            if (_recommended.isNotEmpty && _search.isEmpty) ...[
              const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Recommended Servers',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))),
              const SizedBox(height: 12),
              SizedBox(
                height: recommendedCardHeight, // ارتفاع محاسبه شده یا ثابت
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _recommended.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (ctx, i) {
                    final loc = _recommended[i];
                    final bool isSelectedAsRecommended = _selectedServerLink == loc.link && !_autoConnect;
                    return GestureDetector(
                      onTap: () => _selectServer(loc),
                      child: Container(
                        width: recommendedCardWidth,
                        padding: const EdgeInsets.symmetric(horizontal:10, vertical: 8), // پدینگ داخلی کمتر
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(10), // گردی کمتر
                          border: isSelectedAsRecommended ? Border.all(color: accentColor, width: 1.5) : null,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center, // برای تراز عمودی بهتر
                          children: [
                            ClipOval(
                              child: SvgPicture.asset(
                                'assets/flags/${loc.countryCode.toLowerCase()}.svg',
                                width: 28, // اندازه کوچکتر پرچم
                                height: 28,
                                fit: BoxFit.cover,
                                placeholderBuilder: (BuildContext context) => const Icon(Icons.flag_circle_outlined, size: 28, color: Colors.white60),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    loc.country,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500, // وزن کمتر
                                        fontSize: 12.5), // فونت کوچکتر
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    loc.city.isNotEmpty ? loc.city : 'Fast Connect',
                                    style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 10), // فونت خیلی کوچکتر
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],

            const Align(
              alignment: Alignment.centerLeft,
              child: Text('All Servers',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 10),

            Expanded(
              child: _filtered.isEmpty && _search.isNotEmpty
                  ? Center(
                child: Text(
                  'No servers found matching "$_search"',
                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              )
                  : Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ListView(
                  children: _grouped.entries.map((entry) {
                    // ... (کد ExpansionTile و آیتم‌های داخلی آن - با UI اصلاح شده برای هر سرور) ...
                    final country = entry.key;
                    final items = entry.value;
                    if (items.isEmpty) return const SizedBox.shrink();

                    return Card(
                      elevation: 0,
                      color: cardColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ExpansionTile(
                        key: PageStorageKey<String>(country),
                        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        iconColor: Colors.white60,
                        collapsedIconColor: Colors.white60,
                        childrenPadding: EdgeInsets.zero,
                        shape: Border.all(color: Colors.transparent, width: 0),
                        collapsedShape: Border.all(color: Colors.transparent, width: 0),
                        title: Row(
                          children: [
                            ClipOval(
                              child: SvgPicture.asset(
                                'assets/flags/${items.first.countryCode.toLowerCase()}.svg',
                                width: 32, height: 32,
                                placeholderBuilder: (BuildContext context) => const Icon(Icons.flag_circle_outlined, size: 32, color: Colors.white70),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                                child: Text(country,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
                            Text('${items.length} Locations',
                                style: const TextStyle(color: Colors.white60, fontSize: 12)),
                          ],
                        ),
                        children: items.map((loc) {
                          final locationKey = '${loc.country}-${loc.city}-${loc.id}';
                          if (!_pingResults.containsKey(locationKey) && !(_isPinging[locationKey] ?? false)) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if(mounted) _fetchPing(loc.link, locationKey);
                            });
                          }
                          final currentPing = _pingResults[locationKey];
                          final bool isSelected = _selectedServerLink == loc.link && !_autoConnect;

                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _selectServer(loc),
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 15.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 7, // فضای بیشتر برای نام شهر
                                      child: Text(
                                        loc.city.isNotEmpty ? loc.city : loc.country,
                                        style: TextStyle(
                                          color: isSelected ? accentColor.withOpacity(0.95) : Colors.white.withOpacity(0.75),
                                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                          fontSize: 14.0,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 5,
                                      child: Container(
                                        alignment: Alignment.center,
                                        child: (_isPinging[locationKey] ?? false)
                                            ? const SizedBox( width: 16, height: 16, child: Center(child: CircularProgressIndicator(strokeWidth: 1.5, valueColor: AlwaysStoppedAnimation<Color>(Colors.white70))),)
                                            : (currentPing != null)
                                            ? Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon( Icons.signal_cellular_alt_sharp, size: 17, color: _pingColor(currentPing)),
                                            const SizedBox(width: 6),
                                            Text(
                                              currentPing < 0 ? 'N/A' : '$currentPing ms',
                                              style: TextStyle(color: _pingColor(currentPing), fontSize: 12, fontWeight: FontWeight.w500),
                                            ),
                                          ],
                                        )
                                            : const SizedBox(width: 16, height: 16),
                                      ),
                                    ),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: Icon(
                                        isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
                                        color: isSelected ? accentColor : Colors.grey.shade700,
                                        size: 22,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}