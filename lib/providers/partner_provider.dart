import 'package:flutter/material.dart';
import 'package:fixoo_partner/services/supabase_service.dart';

class PartnerProvider with ChangeNotifier {
  bool _isOnline = false;
  Map<String, dynamic>? _profile;
  List<String> _skills = [];

  bool get isOnline => _isOnline;
  Map<String, dynamic>? get profile => _profile;
  List<String> get skills => _skills;

  Future<void> fetchStatus() async {
    final profileData = await SupabaseService.getProfile();
    if (profileData != null) {
      _profile = profileData;
      _isOnline = profileData['is_online'] ?? false;
      _skills = List<String>.from(profileData['skills'] ?? []);
      notifyListeners();
    }
  }

  Future<void> updateStatus(bool status) async {
    _isOnline = status;
    notifyListeners();
    await SupabaseService.updateOnlineStatus(status);
  }

  void updateLocalProfile(Map<String, dynamic> newProfile) {
    _profile = newProfile;
    _skills = List<String>.from(newProfile['skills'] ?? []);
    notifyListeners();
  }
}
