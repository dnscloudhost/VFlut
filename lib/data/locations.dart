/// مدل یک کانفیگ سرور
class LocationConfig {
  final int    id;
  final String country;     // اسم کشور یا گروه
  final String city;        // شهر (اختیاری)
  final String link;        // لینک VMess/VLESS
  final String countryCode; // دو حرفی ISO (برای بارگذاری پرچم)
  final String serverType;  // "free" یا "premium" یا "pro"
  final bool   fromApi;     // مشخص می‌کند که این کانفیگ از API آمده

  LocationConfig({
    required this.id,
    required this.country,
    required this.city,
    required this.link,
    required this.countryCode,
    this.serverType = 'free',
    this.fromApi    = false,
  });

  /// تعداد لوکیشن‌های این کشور در لیست کلی
  int get locationsCount =>
      allConfigs.where((c) => c.country == country).length;

  /// تبدیل JSON دریافتی از API به مدل
  factory LocationConfig.fromJson(Map<String, dynamic> json) {
    return LocationConfig(
      id:          json['id']          as int,
      // برای نمایش نام کشور فرض می‌کنیم فیلد "name" از API
      country:     json['name']        as String?
          ?? json['country'] as String,
      city:        json['city']        as String? ?? '',
      link:        json['link']        as String,
      countryCode: (json['country']    as String).toLowerCase(),
      serverType:  (json['server_type'] as String?)?.toLowerCase() ?? 'free',
      fromApi:     true,
    );
  }
}

/// کانفیگ‌های محلی (همیشه در دسترسند)
final List<LocationConfig> localConfigs = [
  LocationConfig(
    id:          1,
    country:     'Germany',
    city:        'Frankfurt',
    link:        'vless://2387e86f-30ab-46f9-ae3b-ec9595da9309@gra.iranbuildings.com:5412?encryption=none&security=none&type=tcp&headerType=http&host=speedtest.net#%F0%9F%87%A9%F0%9F%87%AA%20Germany%20%7C%20All%20Net%20%F0%9F%9F%A0',
    countryCode: 'de',
  ),
  LocationConfig(
    id:          2,
    country:     'United Arab Emirates',
    city:        'Dubai',
    link:        'vless://2387e86f-30ab-46f9-ae3b-ec9595da9309@emr.iranbuildings.com:1196?security=&type=tcp&path=/&headerType=http&host=speedtest.net&encryption=none#%F0%9F%87%A6%F0%9F%87%AA%20Emirates%20%7C%20Backup%20%F0%9F%94%B5',
    countryCode: 'ae',
  ),
  // … بقیهٔ سرورهای ثابت
  LocationConfig(
    id:          3,
    country:     'Finland',
    city:        'Helsinki',
    link:        'vless://2387e86f-30ab-46f9-ae3b-ec9595da9309@emr.iranbuildings.com:1196?security=&type=tcp&path=/&headerType=http&host=speedtest.net&encryption=none#%F0%9F%87%A6%F0%9F%87%AA%20Emirates%20%7C%20Backup%20%F0%9F%94%B5',
    countryCode: 'fi',
  ),
  LocationConfig(
    id:          4,
    country:     'France',
    city:        'Paris',
    link:        'vless://2387e86f-30ab-46f9-ae3b-ec9595da9309@emr.iranbuildings.com:1196?security=&type=tcp&path=/&headerType=http&host=speedtest.net&encryption=none#%F0%9F%87%A6%F0%9F%87%AA%20Emirates%20%7C%20Backup%20%F0%9F%94%B5',
    countryCode: 'fr',
  ),
];

/// این لیست در runtime با ترکیب local + API پر می‌شود
List<LocationConfig> allConfigs = [];
