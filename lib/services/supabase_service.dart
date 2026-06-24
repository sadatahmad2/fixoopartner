import 'dart:io';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;
  static final Set<String> acceptedIds = {};

  static User? get currentUser {
    try {
      return client.auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  // Service Category Mapping
  static final Map<String, List<String>> categoryKeywords = {
    'AC Service': ['AC', 'Air Conditioner', 'Cooling'],
    'Geyser Service': ['Geyser', 'Water Heater', 'Heating'],
    'Washing Machine': ['Washing Machine', 'Laundry', 'Dryer'],
    'Refrigerator': ['Fridge', 'Refrigerator', 'Cooling'],
    'RO Service': ['RO', 'Water Purifier', 'Purifier'],
    'Chimney': ['Chimney', 'Kitchen'],
    'Microwave': ['Microwave', 'Oven'],
    'Television': ['TV', 'Television', 'LED'],
  };

  static String getCategoryForService(String serviceName) {
    for (var entry in categoryKeywords.entries) {
      if (entry.value.any((k) => serviceName.contains(k))) return entry.key;
    }
    return serviceName;
  }

  static bool isEligibleForBooking({
    required Map<String, dynamic> booking,
    required List<String> technicianSkills,
    double? distanceInKm,
    bool isCurrentlyBusy = false,
  }) {
    if (isCurrentlyBusy) return false;
    final bookingCategory = getCategoryForService(booking['service_name'] ?? '');
    if (!technicianSkills.contains(bookingCategory)) return false;
    if (distanceInKm != null && distanceInKm > 15) return false;
    return true;
  }

  // ============ HELPERS ============

  static double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  static Future<void> _ensureProfileAndWallet(User user) async {
    try {
      final profile = await client.from('profiles').select().eq('id', user.id).maybeSingle();
      if (profile == null) {
        await client.from('profiles').insert({
          'id': user.id,
          'name': user.userMetadata?['full_name'] ?? user.userMetadata?['name'] ?? 'FixooIndia Partner',
          'full_name': user.userMetadata?['full_name'] ?? user.userMetadata?['name'] ?? 'FixooIndia Partner',
          'email': user.email,
          'phone': user.phone ?? '',
          'avatar_url': user.userMetadata?['avatar_url'],
          'created_at': DateTime.now().toIso8601String(),
          'is_profile_complete': false,
        });
      }

      final wallet = await client.from('wallet').select().eq('user_id', user.id).maybeSingle();
      if (wallet == null) {
        await client.from('wallet').insert({
          'user_id': user.id,
          'balance': 0,
        });
      }
    } catch (e) {
      print('DEBUG: Profile Sync Error: $e');
    }
  }

  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  static Future<Map<String, dynamic>?> getProfile() async {
    if (currentUser == null) return null;
    var data = await client.from('profiles').select().eq('id', currentUser!.id).maybeSingle();
    if (data == null) {
      await _ensureProfileAndWallet(currentUser!);
      data = await client.from('profiles').select().eq('id', currentUser!.id).maybeSingle();
    }
    return data;
  }

  static Future<void> updateProfile({required String name, required String email, required String phone, String? avatarUrl}) async {
    if (currentUser == null) return;
    await client.from('profiles').upsert({
      'id': currentUser!.id,
      'name': name,
      'full_name': name,
      'email': email,
      'phone': phone,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  static Future<Map<String, dynamic>?> getWallet() async {
    if (currentUser == null) return null;
    try {
      final wallet = await client.from('wallet').select().eq('user_id', currentUser!.id).maybeSingle();
      final transactions = await getTransactions();
      return {
        'balance': (wallet?['balance'] as num?)?.toDouble() ?? 0.0,
        'transactions': transactions,
      };
    } catch (e) {
      return null;
    }
  }

  // ============ BOOKINGS ============

  static Future<Map<String, dynamic>?> getBookingById(dynamic id) async {
    final response = await client.from('bookings').select().eq('id', id).limit(1);
    return response.isNotEmpty ? response.first : null;
  }

  static Future<void> updateBookingFields(dynamic bookingId, Map<String, dynamic> fields) async {
    await client.from('bookings').update(fields).eq('id', bookingId);
  }

  static Future<List<Map<String, dynamic>>> getBookings() async {
    if (currentUser == null) return [];
    final data = await client.from('bookings').select().eq('partner_id', currentUser!.id).order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  static Stream<List<Map<String, dynamic>>> getBookingsStream() {
    return client.from('bookings').stream(primaryKey: ['id']).order('created_at', ascending: false);
  }

  static Future<void> acceptBooking(dynamic bookingId) async {
    if (currentUser == null) return;
    await client.from('bookings').update({
      'partner_id': currentUser!.id,
      'status': 'Accepted',
    }).eq('id', bookingId);
  }

  static Future<void> rejectBooking(dynamic bookingId) async {
    await client.from('bookings').update({'status': 'Rejected', 'partner_id': null}).eq('id', bookingId);
  }

  static Future<void> markArrived(dynamic bookingId) async {
    await client.from('bookings').update({'status': 'Arrived'}).eq('id', bookingId);
  }

  static Future<void> markWorkStarted(dynamic bookingId) async {
    await client.from('bookings').update({'status': 'In Progress'}).eq('id', bookingId);
  }

  static Future<void> markWorkFinished(dynamic bookingId, double price) async {
    await client.from('bookings').update({
      'status': 'Completed',
      'price': price,
      'completed_at': DateTime.now().toIso8601String(),
    }).eq('id', bookingId);
  }

  static Future<void> completeBooking(dynamic bookingId) async {
    await client.from('bookings').update({
      'status': 'Completed',
      'completed_at': DateTime.now().toIso8601String(),
    }).eq('id', bookingId);
  }

  static Future<void> updateMaterialList({
    required dynamic bookingId,
    required List<Map<String, dynamic>> materials,
    required double serviceCost,
    required double totalCost,
    required double advanceAmount,
    List<String>? beforeImages,
  }) async {
    final cleanId = bookingId.toString().trim();
    debugPrint('DEBUG: Updating Material List for ID: $cleanId');
    debugPrint('DEBUG: Total Cost: $totalCost, Status: Quoted, Approval: pending');

    final response = await client.from('bookings').update({
      'materials': materials,
      'service_cost': serviceCost,
      'price': totalCost,
      'advance_amount': advanceAmount,
      'status': 'Quoted',
      'approval_status': 'pending',
      'advance_status': 'pending',
      if (beforeImages != null) 'before_images': beforeImages,
    }).eq('id', cleanId).select();

    if (response.isEmpty) {
      debugPrint('DEBUG: WARNING! No rows updated for ID: $cleanId');
      throw 'No booking found with ID: $cleanId. Update failed.';
    }
  }

  static Future<void> updateServiceCost(dynamic bookingId, double cost) async {
    await client.from('bookings').update({'service_cost': cost}).eq('id', bookingId);
  }

  static Future<void> sendQuote(dynamic bookingId, double amount) async {
    await client.from('bookings').update({
      'quote_amount': amount,
      'status': 'Quoted',
    }).eq('id', bookingId);
  }

  static Future<void> updateBookingStatus(dynamic bookingId, String status) async {
    await client.from('bookings').update({'status': status}).eq('id', bookingId);
  }

  static Future<void> markQuoteApproved(dynamic bookingId) async {
    await client.from('bookings').update({'approval_status': 'approved'}).eq('id', bookingId);
  }

  static Future<void> markAdvancePaid(dynamic bookingId) async {
    await client.from('bookings').update({'advance_status': 'paid'}).eq('id', bookingId);
  }

  static Future<void> updatePaymentStatus(dynamic bookingId, String status, String method) async {
    await client.from('bookings').update({
      'payment_status': status,
      'payment_method': method,
    }).eq('id', bookingId);
  }

  static Future<void> sendOTP(String phone) async {
    final fullPhone = phone.startsWith('+') ? phone : '+91$phone';
    await client.auth.signInWithOtp(phone: fullPhone);
  }

  static Future<dynamic> verifyOTP(String phone, String otp) async {
    final fullPhone = phone.startsWith('+') ? phone : '+91$phone';
    final response = await client.auth.verifyOTP(phone: fullPhone, token: otp, type: OtpType.sms);
    if (response.user != null) {
      await _ensureProfileAndWallet(response.user!);
    }
    return response;
  }

  static Future<AuthResponse?> signInWithGoogle() async {
    if (kIsWeb) {
      await client.auth.signInWithOAuth(OAuthProvider.google);
      return null;
    } else {
      const webClientId = '745187823839-t30vs2iekdeqvbamegh9ra5gigs3jiep.apps.googleusercontent.com';
      const iosClientId = '745187823839-at8pcnj43sqq07655lh3d6jp8kgiu10e.apps.googleusercontent.com';
      final GoogleSignIn googleSignIn = GoogleSignIn(clientId: iosClientId, serverClientId: webClientId);
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) return null;
      final googleAuth = await googleUser.authentication;
      final response = await client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken,
      );
      if (response.user != null) await _ensureProfileAndWallet(response.user!);
      return response;
    }
  }

  static Future<Map<String, dynamic>> getEarningsDetails() async {
    final user = currentUser;
    if (user == null) return {'total': 0.0, 'pending': 0.0, 'paid_out': 0.0, 'weekly': List.filled(7, 0.0), 'history': []};
    try {
      final bookingsRes = await client.from('bookings').select('price, created_at').eq('partner_id', user.id).eq('status', 'Completed');
      double total = 0;
      List<double> weekly = List.filled(7, 0.0);
      final now = DateTime.now();
      for (var b in bookingsRes) {
        final price = (b['price'] ?? 0).toDouble();
        total += price;
        final date = DateTime.tryParse(b['created_at'] ?? '');
        if (date != null) {
          final dayDiff = now.difference(date).inDays;
          if (dayDiff < 7) {
            int dayIndex = date.weekday - 1;
            weekly[dayIndex] += price;
          }
        }
      }
      final payoutRes = await client.from('payout_requests').select().eq('user_id', user.id).order('created_at', ascending: false);
      final history = List<Map<String, dynamic>>.from(payoutRes).map((p) => {
        'method': 'Bank Transfer',
        'amount': (p['amount'] ?? 0).toDouble(),
        'date': p['created_at'],
        'status': p['status'],
      }).toList();
      double paidOut = history.where((h) => h['status'] == 'processed').fold(0.0, (sum, h) => sum + h['amount']);
      return {'total': total, 'pending': total - paidOut, 'paid_out': paidOut, 'weekly': weekly, 'history': history};
    } catch (e) {
      return {'total': 0.0, 'pending': 0.0, 'paid_out': 0.0, 'weekly': List.filled(7, 0.0), 'history': []};
    }
  }

  static Future<void> requestPayout(double amount) async {
    if (currentUser == null) return;
    final bankDetails = await getBankDetails();
    if (bankDetails == null) throw 'Please set bank details first.';
    await client.from('payout_requests').insert({
      'user_id': currentUser!.id,
      'amount': amount,
      'status': 'pending',
      'bank_details_snapshot': bankDetails,
    });
  }

  static StreamSubscription<Position>? _locationSubscription;
  static Future<void> updateOnlineStatus(bool isOnline) async {
    if (currentUser == null) return;
    await client.from('profiles').update({'is_online': isOnline}).eq('id', currentUser!.id);
    if (isOnline) _startLocationTracking(); else _stopLocationTracking();
  }

  static void _startLocationTracking() async {
    _locationSubscription?.cancel();
    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10),
    ).listen((Position position) async {
      if (currentUser != null) {
        await client.from('profiles').update({'latitude': position.latitude, 'longitude': position.longitude}).eq('id', currentUser!.id);
      }
    });
  }

  static void _stopLocationTracking() {
    _locationSubscription?.cancel();
    _locationSubscription = null;
  }

  static Future<void> updateSkills(List<String> skills) async {
    if (currentUser == null) return;
    await client.from('profiles').update({'skills': skills}).eq('id', currentUser!.id);
  }

  static Future<Map<String, dynamic>> getPartnerStats() async {
    if (currentUser == null) return {'today_jobs': '0', 'completed': '0', 'rating': '0.0', 'earnings_today': '0'};
    try {
      final allBookings = await client.from('bookings').select('status, created_at, price').eq('partner_id', currentUser!.id);
      final today = DateTime.now().toIso8601String().split('T')[0];
      final todayBookings = allBookings.where((b) => (b['created_at'] as String).startsWith(today)).toList();
      final completedTotal = allBookings.where((b) => b['status'] == 'Completed').length;
      final todayCompleted = todayBookings.where((b) => b['status'] == 'Completed').toList();
      double earningsToday = 0;
      for (var b in todayCompleted) earningsToday += (b['price'] as num?)?.toDouble() ?? 0;
      final reviews = await client.from('reviews').select('rating').eq('partner_id', currentUser!.id);
      double avgRating = 0.0;
      if (reviews.isNotEmpty) {
        double sum = 0;
        for (var r in reviews) sum += (r['rating'] as num?)?.toDouble() ?? 0;
        avgRating = sum / reviews.length;
      }
      return {'today_jobs': todayBookings.length.toString(), 'completed': completedTotal.toString(), 'rating': avgRating.toStringAsFixed(1), 'earnings_today': earningsToday.toStringAsFixed(0)};
    } catch (e) {
      return {'today_jobs': '0', 'completed': '0', 'rating': '0.0', 'earnings_today': '0'};
    }
  }

  static Future<List<Map<String, dynamic>>> getRecentActivity() async {
    if (currentUser == null) return [];
    try {
      final data = await client.from('bookings').select().eq('partner_id', currentUser!.id).order('created_at', ascending: false).limit(5);
      return List<Map<String, dynamic>>.from(data).map((b) {
        final createdAt = DateTime.parse(b['created_at']);
        final diff = DateTime.now().difference(createdAt);
        String timeStr = diff.inMinutes < 60 ? '${diff.inMinutes}m ago' : (diff.inHours < 24 ? '${diff.inHours}h ago' : '${diff.inDays}d ago');
        return {'title': '${b['service_name']} - ${b['brand']}', 'status': b['status'], 'amount': '₹${b['price'] ?? 0}', 'time': timeStr, 'type': 'service', ...b};
      }).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<bool> isTechnicianBusy() async {
    if (currentUser == null) return false;
    final data = await client.from('bookings').select('id').eq('partner_id', currentUser!.id).inFilter('status', ['Accepted', 'Arrived', 'In Progress']).maybeSingle();
    return data != null;
  }

  static Future<Map<String, dynamic>?> getBankDetails() async {
    if (currentUser == null) return null;
    return await client.from('bank_details').select().eq('partner_id', currentUser!.id).maybeSingle();
  }

  static Future<void> updateBankDetails(Map<String, dynamic> details) async {
    if (currentUser == null) return;
    await client.from('bank_details').upsert({'partner_id': currentUser!.id, ...details});
  }

  static Future<List<Map<String, dynamic>>> getDocuments() async {
    if (currentUser == null) return [];
    return await client.from('documents').select().eq('partner_id', currentUser!.id);
  }

  static Future<void> uploadDocument(String type, String filePath, {Uint8List? fileBytes}) async {
    if (currentUser == null) return;
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${type.replaceAll(' ', '_').toLowerCase()}.jpg';
    final storagePath = '${currentUser!.id}/$fileName';
    if (fileBytes != null) await client.storage.from('documents').uploadBinary(storagePath, fileBytes); else await client.storage.from('documents').upload(storagePath, File(filePath));
    final publicUrl = client.storage.from('documents').getPublicUrl(storagePath);
    await client.from('documents').upsert({'partner_id': currentUser!.id, 'type': type, 'file_url': publicUrl, 'status': 'In Review', 'created_at': DateTime.now().toIso8601String()});
  }

  static Future<double> getWalletBalance() async {
    if (currentUser == null) return 0.0;
    final data = await client.from('wallet').select('balance').eq('user_id', currentUser!.id).maybeSingle();
    return (data?['balance'] as num?)?.toDouble() ?? 0.0;
  }

  static Future<List<Map<String, dynamic>>> getTransactions() async {
    if (currentUser == null) return [];
    final data = await client.from('transactions').select().eq('user_id', currentUser!.id).order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  static Future<void> addMoney(double amount) async {
    if (currentUser == null) return;
    final balance = await getWalletBalance();
    await client.from('wallet').upsert({'user_id': currentUser!.id, 'balance': balance + amount});
    await client.from('transactions').insert({'user_id': currentUser!.id, 'amount': amount, 'type': 'credit', 'description': 'Added to wallet', 'created_at': DateTime.now().toIso8601String()});
  }

  static Future<bool> isProfileComplete() async {
    if (currentUser == null) return false;
    final p = await client.from('profiles').select('is_profile_complete, skills, work_video_url').eq('id', currentUser!.id).maybeSingle();
    if (p == null || p['is_profile_complete'] == true) return p?['is_profile_complete'] ?? false;
    final skills = List.from(p['skills'] ?? []);
    if (skills.isEmpty || p['work_video_url'] == null) return false;
    final docs = await client.from('documents').select('type').eq('partner_id', currentUser!.id);
    final types = docs.map((d) => d['type'].toString().toLowerCase()).toList();
    final complete = types.contains('aadhar front') && types.contains('aadhar back') && types.contains('pan card');
    if (complete) await client.from('profiles').update({'is_profile_complete': true}).eq('id', currentUser!.id);
    return complete;
  }

  static Future<Map<String, dynamic>> getProfileStatus() async {
    if (currentUser == null) return {};
    final p = await client.from('profiles').select('skills, work_video_url').eq('id', currentUser!.id).maybeSingle();
    final docs = await client.from('documents').select('type, file_url').eq('partner_id', currentUser!.id);
    final docMap = {for (var d in docs) d['type'].toString().toLowerCase(): d['file_url']};
    return {
      'skills': (p?['skills'] as List?)?.isNotEmpty ?? false,
      'video': (p?['work_video_url'] as String?)?.isNotEmpty ?? false,
      'aadhar_front': docMap.containsKey('aadhar front'),
      'aadhar_back': docMap.containsKey('aadhar back'),
      'pan': docMap.containsKey('pan card'),
    };
  }

  static Future<void> uploadWorkVideo(String filePath, {Uint8List? fileBytes}) async {
    if (currentUser == null) return;
    final name = '${DateTime.now().millisecondsSinceEpoch}_work_video.mp4';
    final path = '${currentUser!.id}/$name';
    if (fileBytes != null) await client.storage.from('documents').uploadBinary(path, fileBytes); else await client.storage.from('documents').upload(path, File(filePath));
    final url = client.storage.from('documents').getPublicUrl(path);
    await client.from('profiles').update({'work_video_url': url}).eq('id', currentUser!.id);
  }

  static Future<List<Map<String, dynamic>>> getPartnerBookings({String? status}) async {
    if (currentUser == null) return [];
    var q = client.from('bookings').select().eq('partner_id', currentUser!.id);
    if (status != null) q = q.eq('status', status);
    return List<Map<String, dynamic>>.from(await q.order('created_at', ascending: false));
  }

  static Future<List<String>> uploadImages(dynamic bookingId, List<File> photos, String type) async {
    if (currentUser == null) return [];
    final List<String> urls = [];
    for (var photo in photos) {
      final name = '${DateTime.now().millisecondsSinceEpoch}_${photo.path.split('/').last}';
      final path = 'job-photos/$bookingId/$name';
      await client.storage.from('job-photos').upload(path, photo);
      urls.add(client.storage.from('job-photos').getPublicUrl(path));
    }
    final column = type == 'before' ? 'before_images' : 'after_images';
    final booking = await client.from('bookings').select(column).eq('id', bookingId).single();
    final existing = List<String>.from(booking[column] ?? []);
    await client.from('bookings').update({column: [...existing, ...urls]}).eq('id', bookingId);
    return urls;
  }
}
