import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:fixoo_partner/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class PaymentService {
  static final Razorpay _razorpay = Razorpay();
  static Completer<bool>? _paymentCompleter;
  
  // Replace with your actual Razorpay Key ID
  // Actual Razorpay Key ID
  static const String _razorpayKey = 'rzp_test_SifkAZASCn3YXX';

  static void initialize(BuildContext context, {
    Function(PaymentSuccessResponse)? onSuccess,
    Function(PaymentFailureResponse)? onFailure,
    Function(ExternalWalletResponse)? onExternalWallet,
  }) {
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, (PaymentSuccessResponse response) {
      debugPrint('Payment Success: ${response.paymentId}');
      if (_paymentCompleter != null && !_paymentCompleter!.isCompleted) {
        _paymentCompleter!.complete(true);
      }
      if (onSuccess != null) onSuccess(response);
    });

    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, (PaymentFailureResponse response) {
      debugPrint('Payment Error: ${response.code} - ${response.message}');
      
      // Show error on screen for debugging
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Razorpay Error: ${response.message} (Code: ${response.code})'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );

      if (_paymentCompleter != null && !_paymentCompleter!.isCompleted) {
        _paymentCompleter!.complete(false);
      }
      if (onFailure != null) onFailure(response);
    });

    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, (ExternalWalletResponse response) {
      if (onExternalWallet != null) onExternalWallet(response);
    });
  }

  static void dispose() {
    _razorpay.clear();
  }

  static Future<bool> processPayment(BuildContext context, {
    required double amount,
    required String description,
  }) async {
    if (_razorpayKey == 'rzp_test_YOUR_KEY_HERE') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please update your Razorpay Key in PaymentService.dart'), backgroundColor: Colors.orange),
      );
      return false;
    }

    _paymentCompleter = Completer<bool>();
    
    final user = SupabaseService.currentUser;
    
    var options = {
      'key': _razorpayKey,
      'amount': (amount * 100).toInt(),
      'name': 'FixooIndia Services',
      'description': description,
      'prefill': {
        'contact': user?.phone ?? '9999999999',
        'email': user?.email ?? 'customer@fixoo.com',
      },
      'external': {
        'wallets': ['paytm']
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Error opening Razorpay: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exception: $e'), backgroundColor: Colors.red),
      );
      return false;
    }

    return _paymentCompleter!.future;
  }

  static void openCheckout({
    required BuildContext context, // Added context for error reporting
    required double amount,
    required String name,
    required String description,
    required String email,
    required String contact,
    Map<String, dynamic>? notes,
  }) {
    if (_razorpayKey == 'rzp_test_YOUR_KEY_HERE') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Razorpay Key is missing! Update line 11 in PaymentService.dart'), backgroundColor: Colors.orange),
      );
      return;
    }

    var options = {
      'key': _razorpayKey,
      'amount': (amount * 100).toInt(),
      'name': 'FixooIndia Services',
      'description': description,
      'prefill': {
        'contact': contact,
        'email': email,
      },
      'notes': notes ?? {},
      'external': {
        'wallets': ['paytm']
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Error opening Razorpay: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Checkout Exception: $e'), backgroundColor: Colors.red),
      );
    }
  }
}
