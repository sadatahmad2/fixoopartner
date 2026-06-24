import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fixoo_partner/config/supabase_config.dart';
import 'package:fixoo_partner/services/supabase_service.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    if (kIsWeb) return;
    if (!Platform.isAndroid && !Platform.isIOS) return;

    final service = FlutterBackgroundService();

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'fixoo_requests',
      'Service Requests',
      description: 'Notifications for new service requests nearby',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
      macOS: initializationSettingsDarwin,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        isForegroundMode: true,
        notificationChannelId: 'fixoo_requests',
        initialNotificationTitle: 'FixooIndia Partner is Active',
        initialNotificationContent: 'Waiting for new service requests...',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    return true;
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();

    try {
      await Supabase.initialize(
        url: SupabaseConfig.supabaseUrl,
        anonKey: SupabaseConfig.supabaseAnonKey,
      );
    } catch (e) {
      debugPrint('Background Supabase Init Error: $e');
    }

    final supabase = Supabase.instance.client;

    Timer.periodic(const Duration(seconds: 30), (timer) async {
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) return;

      if (service is AndroidServiceInstance) {
        service.setAsForegroundService();
        
        try {
          final profile = await supabase
              .from('profiles')
              .select('id, is_online, latitude, longitude, skills')
              .eq('id', currentUser.id)
              .maybeSingle();

          if (profile == null || profile['is_online'] != true) return;

          // 1. Check if technician is busy
          final activeStatuses = ['Accepted', 'Arrived', 'In Progress'];
          final activeJob = await supabase
              .from('bookings')
              .select('id')
              .eq('partner_id', currentUser.id)
              .inFilter('status', activeStatuses)
              .maybeSingle();
          if (activeJob != null) return;

          final bookings = await supabase
              .from('bookings')
              .select()
              .eq('status', 'Pending');

          if (bookings == null || bookings.isEmpty) return;

          final skills = List<String>.from(profile['skills'] ?? []);

          for (var booking in bookings) {
            final bId = booking['id'].toString();
            if (booking['latitude'] == null || booking['longitude'] == null) continue;

            double distanceInKm = Geolocator.distanceBetween(
              profile['latitude'] ?? 0.0,
              profile['longitude'] ?? 0.0,
              booking['latitude'],
              booking['longitude'],
            ) / 1000;

            // 2. Skill/Category Matching + Smart Radius
            final serviceName = (booking['service_name'] ?? '').toString().toLowerCase();
            
            bool hasMatchingSkill = false;
            for (var skill in skills) {
              final keywords = SupabaseService.categoryKeywords[skill] ?? [skill.toLowerCase()];

              for (var kw in keywords) {
                if (serviceName.contains(kw.toLowerCase())) {
                  hasMatchingSkill = true;
                  break;
                }
              }
              if (hasMatchingSkill) break;
            }
            if (!hasMatchingSkill) continue;

            // 3. Smart Radius
            double allowedRadius = 10.0;
            if (serviceName.contains('fan') || serviceName.contains('motor')) allowedRadius = 5.0;
            else if (serviceName.contains('ac') || serviceName.contains('tv')) allowedRadius = 15.0;

            if (distanceInKm > allowedRadius) continue;

            // 4. Distance Priority (15s delay if > 3km)
            if (distanceInKm > 3.0) {
              await Future.delayed(const Duration(seconds: 15));
              final check = await supabase.from('bookings').select('status').eq('id', bId).maybeSingle();
              if (check == null || check['status'] != 'Pending') continue;
            }

            _showNotification(
              id: booking['id'].hashCode,
              title: 'New Service Request! 🛠️',
              body: 'New ${booking['service_name']} request nearby.',
            );
          }
        } catch (e) {
          debugPrint('Background Service Loop Error: $e');
        }
      }
    });

    service.on('stopService').listen((event) {
      service.stopSelf();
    });
  }

  static void _showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'fixoo_requests',
      'Service Requests',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformDetails,
    );
  }
}
