import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:fixoo_partner/services/supabase_service.dart';

class AppNotification {
  final String title;
  final String body;
  final String time;
  final IconData icon;
  bool isUnread;

  AppNotification({
    required this.title,
    required this.body,
    required this.time,
    required this.icon,
    this.isUnread = true,
  });
}

class NotificationProvider with ChangeNotifier {
  List<AppNotification> _notifications = [];
  bool _isLoading = false;

  List<AppNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;

  Future<void> fetchNotifications() async {
    if (SupabaseService.currentUser == null) return;
    _isLoading = true;
    notifyListeners();

    try {
      final response = await SupabaseService.client
          .from('notifications')
          .select()
          .eq('user_id', SupabaseService.currentUser!.id)
          .order('created_at', ascending: false);

      _notifications = (response as List).map((n) => AppNotification(
        title: n['title'],
        body: n['body'],
        time: _formatTime(DateTime.parse(n['created_at'])),
        icon: _getIconData(n['icon_name']),
        isUnread: !(n['is_read'] ?? false),
      )).toList();
    } catch (e) {
      print('DEBUG: Error fetching notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _formatTime(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  IconData _getIconData(String? name) {
    switch (name) {
      case 'zap': return LucideIcons.zap;
      case 'wallet': return LucideIcons.wallet;
      case 'check': return LucideIcons.circleCheck;
      default: return LucideIcons.bell;
    }
  }

  void addNotification(AppNotification notification) {
    _notifications.insert(0, notification);
    notifyListeners();
  }

  Future<void> clearAll() async {
    if (SupabaseService.currentUser == null) return;
    await SupabaseService.client
        .from('notifications')
        .delete()
        .eq('user_id', SupabaseService.currentUser!.id);
    _notifications.clear();
    notifyListeners();
  }

  Future<void> markAllAsRead() async {
    if (SupabaseService.currentUser == null) return;
    await SupabaseService.client
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', SupabaseService.currentUser!.id);
    for (var n in _notifications) {
      n.isUnread = false;
    }
    notifyListeners();
  }
}
