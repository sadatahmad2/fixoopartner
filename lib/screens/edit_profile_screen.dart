import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:fixoo_partner/services/supabase_service.dart';
import 'dart:ui';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? currentProfile;
  const EditProfileScreen({super.key, this.currentProfile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  bool _isLoading = false;
  String? _avatarUrl;
  XFile? _imageFile;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentProfile?['full_name'] ?? widget.currentProfile?['name'] ?? '');
    _emailController = TextEditingController(text: widget.currentProfile?['email'] ?? '');
    _phoneController = TextEditingController(text: widget.currentProfile?['phone'] ?? '');
    _avatarUrl = widget.currentProfile?['avatar_url'];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      setState(() => _imageFile = image);
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    try {
      String? newAvatarUrl = _avatarUrl;
      
      if (_imageFile != null) {
          // Upload image if changed
          final fileName = 'avatar_${SupabaseService.currentUser!.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
          await SupabaseService.client.storage.from('avatars').upload(fileName, File(_imageFile!.path));
          newAvatarUrl = SupabaseService.client.storage.from('avatars').getPublicUrl(fileName);
      }

      await SupabaseService.updateProfile(
        name: _nameController.text,
        email: _emailController.text,
        phone: _phoneController.text,
        avatarUrl: newAvatarUrl,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile Updated!'), backgroundColor: Color(0xFF0FF4C6)));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent));
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
        title: const Text('Edit Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22)),
      ),
      body: Stack(
        children: [
          Positioned(top: -100, left: -50, child: _glow(const Color(0xFF00D1FF), 0.03, 300)),
          ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    children: [
                      Container(
                        width: 100, height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(colors: [Color(0xFF00D1FF), Color(0xFF7B61FF)]),
                          image: _imageFile != null 
                            ? DecorationImage(image: FileImage(File(_imageFile!.path)), fit: BoxFit.cover)
                            : (_avatarUrl != null ? DecorationImage(image: NetworkImage(_avatarUrl!), fit: BoxFit.cover) : null),
                        ),
                        child: _imageFile == null && _avatarUrl == null 
                          ? const Center(child: Icon(LucideIcons.user, color: Colors.white, size: 40))
                          : null,
                      ),
                      Positioned(
                        bottom: 0, right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(color: Color(0xFF00D1FF), shape: BoxShape.circle),
                          child: const Icon(LucideIcons.camera, color: Colors.black, size: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
              _buildTextField('Full Name', _nameController, LucideIcons.user),
              const SizedBox(height: 20),
              _buildTextField('Email Address', _emailController, LucideIcons.mail),
              const SizedBox(height: 20),
              _buildTextField('Phone Number', _phoneController, LucideIcons.phone, enabled: false),
              const SizedBox(height: 60),
              _buildSaveButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {bool enabled = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          enabled: enabled,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.03),
            prefixIcon: Icon(icon, color: const Color(0xFF00D1FF), size: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: Color(0xFF00D1FF))),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 62,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00D1FF),
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
        ),
        child: _isLoading 
          ? const CircularProgressIndicator(color: Colors.black)
          : const Text('SAVE CHANGES', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1)),
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
