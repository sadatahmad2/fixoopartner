import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fixoo_partner/config/supabase_config.dart';
import 'package:fixoo_partner/providers/notification_provider.dart';
import 'package:fixoo_partner/providers/theme_provider.dart';
import 'package:fixoo_partner/providers/partner_provider.dart';
import 'package:fixoo_partner/screens/splash_screen.dart';
import 'package:fixoo_partner/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
    );
  } catch (e) {
    debugPrint('Supabase Initialization Error: $e');
  }

  // Initialize Background Notification Service Safely
  try {
    NotificationService.initialize();
  } catch (e) {
    debugPrint('Notification Service Init Error: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => PartnerProvider()),
      ],
      child: const FixooIndiaPartnerApp(),
    ),
  );
}

class FixooIndiaPartnerApp extends StatefulWidget {
  const FixooIndiaPartnerApp({super.key});

  @override
  State<FixooIndiaPartnerApp> createState() => _FixooIndiaPartnerAppState();
}

class _FixooIndiaPartnerAppState extends State<FixooIndiaPartnerApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      title: 'FixooIndia Partner',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: const Color(0xFF00D1FF),
        fontFamily: 'Inter',
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF030712),
        primaryColor: const Color(0xFF00D1FF),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00D1FF),
          secondary: Color(0xFF00D1FF),
          surface: Color(0xFF030712),
        ),
        fontFamily: 'Inter',
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
