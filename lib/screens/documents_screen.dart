import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'dart:ui';

import 'package:image_picker/image_picker.dart';
import 'package:fixoo_partner/services/supabase_service.dart';
import 'package:fixoo_partner/screens/digilocker_webview.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _docs = [];

  @override
  void initState() {
    super.initState();
    _fetchDocs();
  }

  Future<void> _fetchDocs() async {
    try {
      final data = await SupabaseService.getDocuments();
      if (mounted) setState(() { _docs = data; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUpload(String type) async {
    final picker = ImagePicker();
    // Show option for Camera or Gallery
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: const Color(0xFF111827),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Text('Choose Photo Source', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(LucideIcons.camera, color: Color(0xFF00D1FF)),
              title: const Text('Camera', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(LucideIcons.image, color: Color(0xFF00D1FF)),
              title: const Text('Gallery', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );

    if (source == null) return;

    final image = await picker.pickImage(source: source, imageQuality: 70);
    if (image == null) return;

    setState(() => _isLoading = true);
    try {
      final bytes = await image.readAsBytes();
      await SupabaseService.uploadDocument(type, image.path, fileBytes: bytes);
      _fetchDocs();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$type uploaded for verification!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          )
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030712),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Verification', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22)),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00D1FF)))
          : Stack(
        children: [
          Positioned(bottom: -100, right: -50, child: _glow(const Color(0xFF7B61FF), 0.03, 300)),
          ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text('My Status', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              if (_docs.isEmpty) ...[
                _buildNoDocsState(),
              ] else
                ..._docs.map((doc) => _buildDocumentItem(
                  doc['type'] ?? 'Document', 
                  doc['status'] ?? 'Pending', 
                  _getIconForType(doc['type']), 
                  _getStatusColor(doc['status'])
                )).toList(),
              
              const SizedBox(height: 32),
              const Text('Upload New Proof', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              
              _uploadCard('Aadhar Card (Front)', 'Required for identity verification', () => _pickAndUpload('Aadhar Front')),
              _uploadCard('Aadhar Card (Back)', 'Required for address verification', () => _pickAndUpload('Aadhar Back')),
              _uploadCard('PAN Card', 'Required for tax & payments', () => _pickAndUpload('PAN Card')),
              _uploadCard('Driving License', 'Optional but recommended', () => _pickAndUpload('Driving License')),
              
              const SizedBox(height: 40),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoDocsState() {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.02), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
      child: Column(
        children: [
          Icon(LucideIcons.shieldAlert, color: Colors.white.withValues(alpha: 0.2), size: 40),
          const SizedBox(height: 16),
          const Text('No documents uploaded', style: TextStyle(color: Colors.white38, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _uploadCard(String title, String sub, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFF00D1FF).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: const Icon(LucideIcons.plus, color: Color(0xFF00D1FF), size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                  Text(sub, style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 11)),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight, color: Colors.white.withValues(alpha: 0.1), size: 18),
          ],
        ),
      ),
    );
  }

  IconData _getIconForType(String? type) {
    if (type == null) return LucideIcons.fileText;
    if (type.contains('Aadhar')) return LucideIcons.userCheck;
    if (type.contains('PAN')) return LucideIcons.creditCard;
    return LucideIcons.fileText;
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'Verified': return const Color(0xFF0FF4C6);
      case 'In Review': return const Color(0xFFFFD700);
      case 'Rejected': return Colors.redAccent;
      default: return Colors.white38;
    }
  }

  Widget _buildDocumentItem(String title, String status, IconData icon, Color statusColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: Colors.white.withValues(alpha: 0.6), size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Text(status, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w800)),
                  ],
                ),
              ],
            ),
          ),
          Icon(LucideIcons.eye, color: Colors.white.withValues(alpha: 0.2), size: 20),
        ],
      ),
    );
  }

  Widget _buildUploadPlaceholder() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: const Color(0xFF00D1FF).withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF00D1FF).withValues(alpha: 0.2), style: BorderStyle.none), // Placeholder for dashed border
      ),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFF00D1FF).withValues(alpha: 0.1), shape: BoxShape.circle),
              child: const Icon(LucideIcons.cloudUpload, color: Color(0xFF00D1FF), size: 32),
            ),
            const SizedBox(height: 16),
            const Text('Upload Document', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('PDF, JPG or PNG (max 5MB)', style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 12)),
          ],
        ),
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
