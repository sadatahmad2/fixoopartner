import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:fixoo_partner/services/supabase_service.dart';
import 'package:fixoo_partner/utils/material_database.dart';
import 'dart:ui';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class JobTrackingScreen extends StatefulWidget {
  final Map<String, dynamic> booking;
  const JobTrackingScreen({super.key, required this.booking});

  @override
  State<JobTrackingScreen> createState() => _JobTrackingScreenState();
}

class _JobTrackingScreenState extends State<JobTrackingScreen> {
  late Map<String, dynamic> _booking;
  bool _isLoading = false;
  LatLng? _partnerLoc;
  LatLng? _customerLoc;
  double _distance = 0.0;
  String _duration = '';
  GoogleMapController? _mapController;
  StreamSubscription? _customerSub;
  StreamSubscription? _partnerLocSub;
  Timer? _pollingTimer;
  Set<Polyline> _polylines = {};

  final String googleApiKey = 'AIzaSyCM0Go-ytBf82bdg1WpjfYH4IZVm38c7p4';

  @override
  void dispose() {
    _customerSub?.cancel();
    _partnerLocSub?.cancel();
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _pickImage(Function(File) onPicked) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: const Color(0xFF0D1B2E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select Image Source', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(LucideIcons.camera, color: Color(0xFF0FF4C6)),
              title: const Text('Camera', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(LucideIcons.image, color: Color(0xFF00D1FF)),
              title: const Text('Gallery', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source != null) {
      final picker = ImagePicker();
      final img = await picker.pickImage(source: source);
      if (img != null) {
        onPicked(File(img.path));
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _booking = widget.booking;
    
    if (_booking['latitude'] != null && _booking['longitude'] != null) {
      _customerLoc = LatLng(_booking['latitude'], _booking['longitude']);
    }

    _startLocationUpdates();
    _startCustomerTracking();
    _startPolling();
    _fetchLatest();
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      if (mounted) _fetchLatest();
    });
  }

  void _startCustomerTracking() {
    final dynamic bookingId = _booking['id'];
    _customerSub?.cancel();
    _customerSub = SupabaseService.client
        .from('bookings')
        .stream(primaryKey: ['id'])
        .eq('id', bookingId)
        .listen((data) {
          if (data.isNotEmpty && mounted) {
            final b = Map<String, dynamic>.from(data.first);
            
            // Auto-show success dialog when payment is confirmed paid
            if (b['payment_status']?.toString().toLowerCase() == 'paid' && 
                _booking['payment_status']?.toString().toLowerCase() != 'paid' && 
                b['status']?.toString().toLowerCase() == 'completed') {
              if (mounted) _showPaymentDialog();
            }

            debugPrint('DEBUG: Realtime Sync - Status: ${b['status']}, Approval: ${b['approval_status']}, Advance: ${b['advance_status']}');
            setState(() {
              _booking = b;
              if (b['latitude'] != null && b['longitude'] != null) {
                _customerLoc = LatLng(b[ 'latitude'], b['longitude']);
              }
            });
            _getRoute();
          }
        });
  }

  void _startLocationUpdates() {
    _partnerLocSub?.cancel();
    _partnerLocSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10),
    ).listen((position) {
      if (!mounted) return;
      setState(() {
        _partnerLoc = LatLng(position.latitude, position.longitude);
        _mapController?.animateCamera(CameraUpdate.newLatLng(_partnerLoc!));
      });
      _getRoute();
    });
  }

  Future<void> _getRoute() async {
    if (_partnerLoc == null || _customerLoc == null) return;

    final url = 'https://maps.googleapis.com/maps/api/directions/json?'
        'origin=${_partnerLoc!.latitude},${_partnerLoc!.longitude}&'
        'destination=${_customerLoc!.latitude},${_customerLoc!.longitude}&'
        'key=$googleApiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'].isNotEmpty) {
          final points = data['routes'][0]['overview_polyline']['points'];
          final leg = data['routes'][0]['legs'][0];
          
          if (mounted) {
            setState(() {
              _distance = (leg['distance']['value'] as int) / 1000;
              _duration = leg['duration']['text'];
              _polylines = {
                Polyline(
                  polylineId: const PolylineId('route'),
                  points: _decodePolyline(points),
                  color: const Color(0xFF0FF4C6),
                  width: 5,
                  jointType: JointType.round,
                  startCap: Cap.roundCap,
                  endCap: Cap.roundCap,
                ),
              };
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching route: $e');
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  Future<void> _fetchLatest() async {
    try {
      final dynamic id = _booking['id'];
      final response = await SupabaseService.client.from('bookings').select().eq('id', id).limit(1);
      
      if (response.isNotEmpty && mounted) {
        final fresh = response.first;
        if (_booking['approval_status'] != fresh['approval_status'] || _booking['status'] != fresh['status']) {
          debugPrint('DEBUG: Polling Update: Approval=${fresh['approval_status']}, Status=${fresh['status']}');
        }
        setState(() {
          _booking = fresh;
        });
      }
    } catch (e) {
      debugPrint('DEBUG: Fetch error: $e');
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    try {
      setState(() => _isLoading = true);
      await SupabaseService.updateBookingStatus(_booking['id'].toString(), newStatus);
      await _fetchLatest();
      
      // Removed premature _showPaymentDialog call. 
      // It will now only show after payment is confirmed 'paid'.
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showPaymentDialog() {
    final double total = double.tryParse(_booking['price']?.toString() ?? '0') ?? 0.0;
    final double advance = double.tryParse(_booking['advance_amount']?.toString() ?? '0') ?? 0.0;
    final double remaining = total - advance;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: const Color(0xFF111827),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: const Color(0xFF0FF4C6).withOpacity(0.2))),
          title: const Column(
            children: [
              Icon(LucideIcons.circleCheck, color: Color(0xFF0FF4C6), size: 48),
              SizedBox(height: 16),
              Text('Job Completed!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 24)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Total Amount to Collect:', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14)),
              const SizedBox(height: 8),
              Text('₹$remaining', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(16)),
                child: const Row(
                  children: [
                    Icon(LucideIcons.wallet, color: Color(0xFF00D1FF), size: 20),
                    SizedBox(width: 12),
                    Expanded(child: Text('Collect cash or ask customer to pay via FixooIndia app.', style: TextStyle(color: Colors.white70, fontSize: 13))),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('BACK TO DASHBOARD', style: TextStyle(color: Color(0xFF00D1FF), fontWeight: FontWeight.w900, letterSpacing: 1)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = (_booking['status'] ?? 'Pending').toString();
    final isCancelled = status.toLowerCase() == 'cancelled' || status.toLowerCase() == 'rejected';
    final advanceStatus = (_booking['advance_status'] ?? '').toString().toLowerCase();
    final paymentStatus = (_booking['payment_status'] ?? '').toString().toLowerCase();
    final approvalStatus = (_booking['approval_status'] ?? '').toString().toLowerCase();

    return Scaffold(
      backgroundColor: const Color(0xFF030712),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
          child: IconButton(
            icon: const Icon(LucideIcons.chevronLeft, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: const Text('Job Tracking', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, color: Colors.white70, size: 20),
            onPressed: () => _fetchLatest(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // FULL SCREEN MAP
          GoogleMap(
            onMapCreated: (controller) => _mapController = controller,
            initialCameraPosition: CameraPosition(
              target: _partnerLoc ?? _customerLoc ?? const LatLng(26.8467, 80.9462),
              zoom: 15,
            ),
            polylines: _polylines,
            markers: {
              if (_partnerLoc != null)
                Marker(
                  markerId: const MarkerId('partner'),
                  position: _partnerLoc!,
                  infoWindow: const InfoWindow(title: 'Me'),
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
                ),
              if (_customerLoc != null)
                Marker(
                  markerId: const MarkerId('customer'),
                  position: _customerLoc!,
                  infoWindow: const InfoWindow(title: 'Customer'),
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                ),
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),

          // Distance Indicator
          if (_distance > 0)
            Positioned(
              top: 110,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1B2E),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.navigation, color: Color(0xFF0FF4C6), size: 14),
                    const SizedBox(width: 8),
                    Text(
                      '${_distance.toStringAsFixed(1)} km away${_duration.isNotEmpty ? " • $_duration" : ""}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)
                    ),
                  ],
                ),
              ),
            ),

          // Sliding Sheet
          DraggableScrollableSheet(
            initialChildSize: 0.35,
            minChildSize: 0.20,
            maxChildSize: 0.85,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1B2E),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 30)],
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
                      const SizedBox(height: 20),
                      _buildCustomerSection(),
                      const SizedBox(height: 24),
                      const Divider(color: Colors.white10, height: 1),
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('JOB PROGRESS', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                            const SizedBox(height: 8),
                            Text('ID: ${_booking['id']} | Status: ${_booking['status']} | Approval: ${_booking['approval_status']}', style: TextStyle(color: Colors.white.withOpacity(0.05), fontSize: 8)),
                            const SizedBox(height: 24),
                            _buildProgressSteps(status),
                            _buildPhotosSection(),
                          ],
                        ),
                      ),
                      
                      if (status.toLowerCase() == 'completed' && paymentStatus == 'paid') ...[
                        const SizedBox(height: 32),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0FF4C6),
                              foregroundColor: Colors.black,
                              minimumSize: const Size(double.infinity, 56),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: const Text('BACK TO HOME', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                          ),
                        ),
                      ],
                      
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              );
            },
          ),

          if (isCancelled) _buildCancelledOverlay(),
          if (_isLoading) Container(color: Colors.black45, child: const Center(child: CircularProgressIndicator(color: Color(0xFF0FF4C6)))),
        ],
      ),
    );
  }

  Widget _buildCustomerSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF00D1FF).withOpacity(0.1),
              border: Border.all(color: const Color(0xFF00D1FF), width: 2),
            ),
            child: const Icon(LucideIcons.user, color: Color(0xFF00D1FF), size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_booking['customer_name'] ?? 'Customer', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                Text(_booking['service_name'] ?? 'Service', style: const TextStyle(color: Colors.white54, fontSize: 14)),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(color: const Color(0xFF0FF4C6).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: IconButton(
              icon: const Icon(LucideIcons.phone, color: Color(0xFF0FF4C6), size: 24),
              onPressed: () => _makeCall(),
            ),
          ),
        ],
      ),
    );
  }

  void _makeCall() async {
    final phone = _booking['customer_phone'];
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Customer phone number not available')),
      );
      return;
    }
    final Uri launchUri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch phone dialer')),
      );
    }
  }

  Widget _buildProgressSteps(String status) {
    final s = status.toLowerCase();
    final isQuoteSent = (_booking['price'] as num?) != null && (_booking['price'] as num) > 0;
    
    final advanceStatus = (_booking['advance_status'] ?? '').toString().toLowerCase();
    final paymentStatus = (_booking['payment_status'] ?? '').toString().toLowerCase();
    final approvalStatus = (_booking['approval_status'] ?? '').toString().toLowerCase();
    
    // Status sequence mapping to ensure correct highlighting
    const statusOrder = {
      'pending': 0,
      'accepted': 1,
      'arrived': 2,
      'quoted': 3,
      'in progress': 4,
      'completed': 5,
    };
    
    int currentOrder = statusOrder[s] ?? 0;
    
    bool isStepCompleted(String stepStatus) {
      if (s == 'completed') return true;
      int stepOrder = statusOrder[stepStatus] ?? 0;
      return currentOrder >= stepOrder;
    }

    return Column(
      children: [
        _buildStepItem(
          title: 'Order Accepted',
          subtitle: 'Heading to customer location',
          icon: LucideIcons.circleCheck,
          isCompleted: true,
          isActive: s == 'accepted',
        ),
        _buildConnector(true),
        _buildStepItem(
          title: 'Reached Location',
          subtitle: 'Arrived at customer site',
          icon: LucideIcons.mapPin,
          isCompleted: isStepCompleted('arrived'),
          isActive: s == 'accepted',
          onAction: s == 'accepted' ? () => _updateStatus('Arrived') : null,
          actionLabel: 'I HAVE REACHED',
        ),
        _buildConnector(isStepCompleted('arrived')),
        _buildStepItem(
          title: 'Inspection & Quote',
          subtitle: isQuoteSent ? 'Quote sent to customer' : 'Add items and service cost',
          icon: LucideIcons.listTodo,
          isCompleted: isQuoteSent || isStepCompleted('quoted') || isStepCompleted('in progress'),
          isActive: (s == 'arrived' || s == 'quoted') && !isStepCompleted('in progress'),
          onAction: (s == 'arrived' || s == 'quoted') && !isStepCompleted('in progress') ? () => _showMaterialDialog() : null,
          actionLabel: isQuoteSent ? 'EDIT QUOTE' : 'ADD MATERIAL LIST',
        ),
        _buildConnector(isQuoteSent || isStepCompleted('quoted') || isStepCompleted('in progress')),
        _buildStepItem(
          title: 'Customer Approval',
          subtitle: (approvalStatus == 'approved' || isStepCompleted('in progress')) ? 'Quote Approved!' : (approvalStatus == 'rejected' ? 'Quote Rejected' : 'Waiting for customer...'),
          icon: LucideIcons.userCheck,
          isCompleted: approvalStatus == 'approved' || isStepCompleted('in progress'),
          isActive: isQuoteSent && (approvalStatus != 'approved' && !isStepCompleted('in progress')),
          onAction: null,
          actionLabel: '',
        ),
        _buildConnector(approvalStatus == 'approved' || isStepCompleted('in progress')),
        _buildStepItem(
          title: 'Advance Payment',
          subtitle: advanceStatus == 'paid' ? 'Payment Received! (₹${_booking['advance_amount']})' : (advanceStatus == 'cash_requested' ? 'VERIFY CASH OTP' : 'Waiting for customer payment...'),
          icon: LucideIcons.indianRupee,
          isCompleted: advanceStatus == 'paid' || isStepCompleted('in progress'),
          isActive: approvalStatus == 'approved' && advanceStatus != 'paid' && s != 'completed',
          onAction: (approvalStatus == 'approved' && advanceStatus != 'paid') ? () async {
            if (advanceStatus == 'cash_requested') {
              await _showOTPVerifyDialog('advance_status');
            } else {
              try {
                setState(() => _isLoading = true);
                await SupabaseService.markAdvancePaid(_booking['id'].toString());
                await _fetchLatest();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            }
          } : null,
          actionLabel: advanceStatus == 'cash_requested' ? 'VERIFY OTP' : 'RECEIVED CASH ADVANCE',
        ),
        _buildConnector(advanceStatus == 'paid' || isStepCompleted('in progress')),
        _buildStepItem(
          title: 'Work Started',
          subtitle: 'Service is in progress',
          icon: LucideIcons.zap,
          isCompleted: isStepCompleted('in progress'),
          isActive: (s == 'arrived' || s == 'accepted' || s == 'quoted') && approvalStatus == 'approved' && advanceStatus == 'paid',
          onAction: (s == 'arrived' || s == 'accepted' || s == 'quoted') && approvalStatus == 'approved' && advanceStatus == 'paid' ? () => _updateStatus('In Progress') : null,
          actionLabel: 'START WORK',
        ),
        _buildConnector(isStepCompleted('in progress')),
        _buildStepItem(
          title: 'Work Finished',
          subtitle: s == 'completed' 
            ? (paymentStatus == 'paid' ? 'Job finished and paid!' : 'Waiting for final payment...')
            : 'Collect payment and finish',
          icon: LucideIcons.flag,
          isCompleted: s == 'completed' && paymentStatus == 'paid',
          isActive: (s == 'in progress') || (s == 'completed' && paymentStatus != 'paid'),
          onAction: () async {
            if (s == 'in progress') {
              _showFinishDialog();
            } else if (s == 'completed' && paymentStatus == 'cash_requested') {
              await _showOTPVerifyDialog('payment_status');
              if (mounted) _showPaymentDialog();
            } else if (s == 'completed' && paymentStatus != 'paid') {
              try {
                setState(() => _isLoading = true);
                await SupabaseService.updatePaymentStatus(_booking['id'].toString(), 'paid', 'CASH_CONFIRMED');
                await _fetchLatest();
                if (mounted) _showPaymentDialog();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            }
          },
          actionLabel: s == 'in progress' ? 'FINISH JOB' : (paymentStatus == 'cash_requested' ? 'VERIFY FINAL OTP' : 'MARK PAID (CASH)'),
        ),
      ],
    );
  }

  void _showFinishDialog() {
    List<File> afterPhotos = [];
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF0D1B2E),
            title: const Text('Finish Job', style: TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Upload After-Work Photos', style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    ...afterPhotos.map((f) => Image.file(f, width: 60, height: 60, fit: BoxFit.cover)),
                    IconButton(
                      icon: const Icon(LucideIcons.camera, color: Color(0xFF00D1FF)),
                      onPressed: () => _pickImage((file) => setDialogState(() => afterPhotos.add(file))),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  setState(() => _isLoading = true);
                  try {
                    List<String> urls = await SupabaseService.uploadImages(_booking['id'].toString(), afterPhotos, 'after');
                    List<String> current = List<String>.from(_booking['after_images'] ?? []);
                    current.addAll(urls);
                    await SupabaseService.updateBookingFields(_booking['id'], {'after_images': current});
                    await _updateStatus('Completed');
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                  setState(() => _isLoading = false);
                },
                child: const Text('FINISH'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showOTPVerifyDialog(String columnToUpdate) async {
    final otpController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0D1B2E),
        title: const Text('Verify Cash Payment', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter the 4-digit OTP shown on customer\'s screen', style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 20),
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 8),
              decoration: InputDecoration(
                counterText: "",
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () async {
              final entered = otpController.text;
              final actual = _booking['payment_otp']?.toString() ?? '';
              
              if (entered == actual) {
                Navigator.pop(context);
                setState(() => _isLoading = true);
                try {
                  await SupabaseService.updateBookingFields(_booking['id'], {
                    columnToUpdate: 'paid',
                    'payment_otp': null, // Clear it
                  });
                  await _fetchLatest();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment Verified!'), backgroundColor: Colors.green));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                } finally {
                  if (mounted) setState(() => _isLoading = false);
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid OTP!'), backgroundColor: Colors.red));
              }
            },
            child: const Text('VERIFY'),
          ),
        ],
      ),
    );
  }

  void _showMaterialDialog() {
    List<Map<String, dynamic>> items = List<Map<String, dynamic>>.from(_booking['materials'] ?? []);
    final serviceCostController = TextEditingController(text: (_booking['service_cost'] ?? '0').toString());
    List<File> beforePhotos = [];
    
    String category = _booking['service_name'] ?? '';
    List<String> problems = List<String>.from(_booking['problems'] ?? []);
    List<MaterialItem> allParts = MaterialDatabase.getSuggestedMaterials(category, problems);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.9,
            decoration: const BoxDecoration(
              color: Color(0xFF0D1B2E),
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: _MaterialDialogContent(
              items: items,
              serviceCostController: serviceCostController,
              beforePhotos: beforePhotos,
              allParts: allParts,
              bookingId: _booking['id'].toString(),
              initialBeforeImages: List<String>.from(_booking['before_images'] ?? []),
              onPickImage: (onPicked) => _pickImage(onPicked),
              onUpdated: () => setModalState(() {}),
              onSuccess: () async {
                await _fetchLatest();
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Quote sent successfully!'), backgroundColor: Colors.green));
                }
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildPhotosSection() {
    final List<dynamic> beforeImages = _booking['before_images'] ?? [];
    final List<dynamic> afterImages = _booking['after_images'] ?? [];
    
    if (beforeImages.isEmpty && afterImages.isEmpty && _booking['status'] == 'Pending') return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 40),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('SERVICE PHOTOS', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
            if (_booking['status'] != 'Cancelled' && _booking['status'] != 'Rejected')
              GestureDetector(
                onTap: () => _pickImage((file) async {
                  setState(() => _isLoading = true);
                  try {
                    List<String> urls = await SupabaseService.uploadImages(_booking['id'].toString(), [file], 'after');
                    List<String> current = List<String>.from(_booking['after_images'] ?? []);
                    current.addAll(urls);
                    await SupabaseService.updateBookingFields(_booking['id'], {'after_images': current});
                    await _fetchLatest();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                  setState(() => _isLoading = false);
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00D1FF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF00D1FF).withOpacity(0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.camera, color: Color(0xFF00D1FF), size: 14),
                      SizedBox(width: 6),
                      Text('ADD PHOTO', style: TextStyle(color: Color(0xFF00D1FF), fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
          child: ListView(
            padding: EdgeInsets.zero,
            scrollDirection: Axis.horizontal,
            children: [
              ...beforeImages.map((url) => _buildPhotoItem(url.toString(), 'BEFORE')),
              ...afterImages.map((url) => _buildPhotoItem(url.toString(), 'AFTER')),
              if (beforeImages.isEmpty && afterImages.isEmpty)
                Center(
                  child: Text('No photos uploaded yet', style: TextStyle(color: Colors.white.withOpacity(0.1), fontSize: 13, fontStyle: FontStyle.italic)),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoItem(String url, String label) {
    return Container(
      margin: const EdgeInsets.only(right: 16),
      width: 100,
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(url, fit: BoxFit.cover),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: label == 'BEFORE' ? Colors.redAccent : const Color(0xFF0FF4C6), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
        ],
      ),
    );
  }

  Widget _buildStepItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isCompleted,
    required bool isActive,
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    final color = isCompleted ? const Color(0xFF0FF4C6) : (isActive ? const Color(0xFF00D1FF) : Colors.white10);
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.1),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Icon(isCompleted ? Icons.check : icon, color: color, size: 16),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: isCompleted || isActive ? Colors.white : Colors.white24, fontWeight: FontWeight.bold, fontSize: 16)),
              Text(subtitle, style: TextStyle(color: Colors.white38, fontSize: 12)),
              if (isActive && onAction != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onAction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0FF4C6),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(actionLabel!, style: const TextStyle(fontWeight: FontWeight.w900)),
                  ),
                ),
              ]
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConnector(bool isCompleted) {
    return Container(
      margin: const EdgeInsets.only(left: 15, top: 4, bottom: 4),
      width: 2, height: 30,
      color: isCompleted ? const Color(0xFF0FF4C6).withOpacity(0.3) : Colors.white10,
    );
  }

  Widget _buildCancelledOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.9),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.triangleAlert, color: Colors.redAccent, size: 64),
              const SizedBox(height: 24),
              const Text('JOB CANCELLED', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              const Text('The customer has cancelled this booking.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white60, fontSize: 16)),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16)),
                child: const Text('BACK TO DASHBOARD', style: TextStyle(fontWeight: FontWeight.w900)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MaterialDialogContent extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final TextEditingController serviceCostController;
  final List<File> beforePhotos;
  final List<MaterialItem> allParts;
  final String bookingId;
  final List<String> initialBeforeImages;
  final Function(Function(File)) onPickImage;
  final VoidCallback onUpdated;
  final VoidCallback onSuccess;

  const _MaterialDialogContent({
    required this.items,
    required this.serviceCostController,
    required this.beforePhotos,
    required this.allParts,
    required this.bookingId,
    required this.initialBeforeImages,
    required this.onPickImage,
    required this.onUpdated,
    required this.onSuccess,
  });

  @override
  State<_MaterialDialogContent> createState() => _MaterialDialogContentState();
}

class _MaterialDialogContentState extends State<_MaterialDialogContent> {
  String? tempSelectedPart;
  final partPriceController = TextEditingController();
  bool _isLoading = false;

  void _openPartPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111827),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text('SELECT PART', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: widget.allParts.length,
                itemBuilder: (context, idx) {
                  final p = widget.allParts[idx];
                  return ListTile(
                    title: Text(p.name, style: const TextStyle(color: Colors.white)),
                    onTap: () {
                      setState(() {
                        tempSelectedPart = p.name;
                        partPriceController.clear(); // Force manual entry
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double materialsTotal = widget.items.fold(0, (sum, item) => sum + ((item['price'] ?? 0) * (item['qty'] ?? 1)));
    double serviceCost = double.tryParse(widget.serviceCostController.text) ?? 0;
    double total = materialsTotal + serviceCost;

    return Column(
      children: [
        const SizedBox(height: 12),
        Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 20),
        const Text('Quote & Material List', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
        const SizedBox(height: 24),
        
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            children: [
              GestureDetector(
                onTap: _openPartPicker,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00D1FF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF00D1FF).withOpacity(0.3)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.plus, color: Color(0xFF00D1FF), size: 20),
                      SizedBox(width: 12),
                      Text('SELECT PARTS', style: TextStyle(color: Color(0xFF00D1FF), fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                    ],
                  ),
                ),
              ),

              if (tempSelectedPart != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Selected: $tempSelectedPart', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      TextField(
                        controller: partPriceController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Color(0xFF0FF4C6), fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          labelText: 'Add Price of Part',
                          labelStyle: const TextStyle(color: Colors.white38),
                          prefixText: '₹ ',
                          prefixStyle: const TextStyle(color: Color(0xFF0FF4C6)),
                          filled: true,
                          fillColor: Colors.black26,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              widget.items.add({
                                'name': tempSelectedPart,
                                'price': double.tryParse(partPriceController.text) ?? 0,
                                'qty': 1,
                              });
                              tempSelectedPart = null;
                            });
                            widget.onUpdated();
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0FF4C6), foregroundColor: Colors.black),
                          child: const Text('SAVE PART', style: TextStyle(fontWeight: FontWeight.w900)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),
              const Text('TECHNICIAN CHARGE', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1)),
              const SizedBox(height: 12),
              TextField(
                controller: widget.serviceCostController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                onChanged: (v) {
                  setState(() {});
                  widget.onUpdated();
                },
                decoration: InputDecoration(
                  hintText: 'Enter your service charge',
                  hintStyle: const TextStyle(color: Colors.white24),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  prefixIcon: const Icon(LucideIcons.wallet, color: Color(0xFF00D1FF), size: 18),
                ),
              ),

              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('SELECTED ITEMS', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1)),
                  if (widget.items.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        setState(() => widget.items.clear());
                        widget.onUpdated();
                      },
                      child: const Text('CLEAR ALL', style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (widget.items.isEmpty)
                const Center(child: Text('No parts selected yet', style: TextStyle(color: Colors.white10, fontSize: 12)))
              else
                ...widget.items.asMap().entries.map((entry) {
                  int idx = entry.key;
                  Map<String, dynamic> item = entry.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                              Text('₹${item['price']} × ${item['qty'] ?? 1}', style: const TextStyle(color: Color(0xFF00D1FF), fontSize: 12)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.trash2, color: Colors.redAccent, size: 18),
                          onPressed: () {
                            setState(() => widget.items.removeAt(idx));
                            widget.onUpdated();
                          },
                        ),
                      ],
                    ),
                  );
                }).toList(),
              
              const SizedBox(height: 32),
              const Text('BROKEN PARTS PHOTOS', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1)),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ...widget.beforePhotos.map((f) => Container(
                      margin: const EdgeInsets.only(right: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(f, width: 90, height: 90, fit: BoxFit.cover),
                      ),
                    )),
                    GestureDetector(
                      onTap: () {
                        widget.onPickImage((file) {
                          setState(() => widget.beforePhotos.add(file));
                          widget.onUpdated();
                        });
                      },
                      child: Container(
                        width: 90, height: 90,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white10, style: BorderStyle.solid),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.camera, color: Colors.white38, size: 24),
                            SizedBox(height: 4),
                            Text('ADD PHOTO', style: TextStyle(color: Colors.white24, fontSize: 8, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),

        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, -5))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Total Quote', style: TextStyle(color: Colors.white38, fontSize: 12)),
                  Text('₹$total', style: const TextStyle(color: Color(0xFF0FF4C6), fontSize: 28, fontWeight: FontWeight.w900)),
                ],
              ),
              ElevatedButton(
                onPressed: _isLoading ? null : () async {
                  if (total <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add at least one part or charge')));
                    return;
                  }
                  setState(() => _isLoading = true);
                  try {
                    List<String> imageUrls = List<String>.from(widget.initialBeforeImages);
                    if (widget.beforePhotos.isNotEmpty) {
                      final newUrls = await SupabaseService.uploadImages(widget.bookingId, widget.beforePhotos, 'before');
                      imageUrls.addAll(newUrls);
                    }
                    
                    debugPrint('DEBUG: Saving material list...');
                    await SupabaseService.updateMaterialList(
                      bookingId: widget.bookingId,
                      materials: widget.items,
                      serviceCost: serviceCost,
                      totalCost: total,
                      advanceAmount: materialsTotal,
                      beforeImages: imageUrls,
                    );
                    debugPrint('DEBUG: Material list saved successfully.');
                    widget.onSuccess();
                  } catch (e) {
                    debugPrint('DEBUG: Error saving material list: $e');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to save: $e'),
                          backgroundColor: Colors.red,
                          duration: const Duration(seconds: 5),
                          action: SnackBarAction(label: 'DETAILS', textColor: Colors.white, onPressed: () {
                             showDialog(context: context, builder: (ctx) => AlertDialog(
                               title: const Text('Save Error'),
                               content: Text(e.toString()),
                               actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
                             ));
                          }),
                        ),
                      );
                    }
                  } finally {
                    if (mounted) setState(() => _isLoading = false);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00D1FF),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 8,
                  shadowColor: const Color(0xFF00D1FF).withOpacity(0.5),
                ),
                child: _isLoading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : const Text('SAVE & SEND', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
