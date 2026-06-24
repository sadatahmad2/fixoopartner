import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:fixoo_partner/providers/theme_provider.dart';
import 'dart:ui';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotifications = true;
  bool _emailNotifications = false;
  String _language = 'English';

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.chevronLeft, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Settings', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black, fontWeight: FontWeight.w900, fontSize: 22)),
      ),
      body: Stack(
        children: [
          if (Theme.of(context).brightness == Brightness.dark)
            Positioned(top: -50, right: -50, child: _glow(const Color(0xFF7B61FF), 0.03, 250)),
          ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildSectionHeader('Preferences'),
              _buildDropdownSetting('Language', _language, ['English', 'Hindi', 'Bengali'], (val) => setState(() => _language = val!)),
              _buildDropdownSetting('Theme', themeProvider.currentThemeName, ['Dark', 'Light', 'System'], (val) {
                themeProvider.setThemeMode(val!);
              }),
              
              const SizedBox(height: 32),
              _buildSectionHeader('Notifications'),
              _buildSwitchSetting('Push Notifications', 'Receive alerts for new jobs', _pushNotifications, (val) => setState(() => _pushNotifications = val)),
              _buildSwitchSetting('Email Updates', 'Receive weekly performance reports', _emailNotifications, (val) => setState(() => _emailNotifications = val)),
              
              const SizedBox(height: 32),
              _buildSectionHeader('Security'),
              _buildActionSetting('Change Password', LucideIcons.lock),
              _buildActionSetting('Two-Factor Authentication', LucideIcons.shieldCheck),
              
              const SizedBox(height: 40),
              _buildDeleteAccount(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(title, style: TextStyle(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.4), fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1)),
    );
  }

  Widget _buildDropdownSetting(String label, String value, List<String> options, ValueChanged<String?> onChanged) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.03), borderRadius: BorderRadius.circular(18), border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 15, fontWeight: FontWeight.w600)),
          DropdownButton<String>(
            value: value,
            dropdownColor: isDark ? const Color(0xFF1F2937) : Colors.white,
            underline: const SizedBox(),
            icon: Icon(LucideIcons.chevronDown, color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.4), size: 16),
            style: const TextStyle(color: Color(0xFF00D1FF), fontSize: 14, fontWeight: FontWeight.w700),
            items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchSetting(String label, String sub, bool value, ValueChanged<bool> onChanged) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.03), borderRadius: BorderRadius.circular(18), border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05))),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(sub, style: TextStyle(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.3), fontSize: 12)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF00D1FF),
            activeTrackColor: const Color(0xFF00D1FF).withValues(alpha: 0.2),
          ),
        ],
      ),
    );
  }

  Widget _buildActionSetting(String label, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.03), borderRadius: BorderRadius.circular(18), border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.3), size: 18),
              const SizedBox(width: 14),
              Text(label, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 15, fontWeight: FontWeight.w600)),
            ],
          ),
          Icon(LucideIcons.chevronRight, color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.2), size: 18),
        ],
      ),
    );
  }

  Widget _buildDeleteAccount() {
    return Center(
      child: TextButton(
        onPressed: () {},
        child: const Text('Delete Account', style: TextStyle(color: Colors.redAccent, fontSize: 14, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _glow(Color color, double opacity, double size) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: opacity)),
      child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80), child: const SizedBox.expand()),
    );
  }
}
